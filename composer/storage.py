"""Descriptor-anchored, no-link I/O for explicit POSIX candidate roots.

Roots must use absolute paths with no symlink components. Reads are bounded;
only a freshly created private output root permits writes, always exclusive.
This is not a sandbox against a hostile same-UID process or an atomic snapshot.
"""
import hashlib
import os
import re
import stat

MAX_BYTES = 1024 * 1024


class PathError(ValueError):
    """A path, node type, or hash violates the candidate I/O contract."""


def _parts(relative):
    if not isinstance(relative, str) or "\\" in relative or "\x00" in relative:
        raise PathError("require a relative POSIX path")
    parts = relative.split("/")
    if any(part in {"", ".", ".."} for part in parts):
        raise PathError("empty, absolute, and dot path components are forbidden")
    return parts


def _absolute(path):
    path = os.fspath(path)
    if not isinstance(path, str) or not path.startswith("/"):
        raise PathError("require an explicit absolute root")
    _parts(path[1:])
    return path


def _directory():
    if os.name != "posix" or not hasattr(os, "O_NOFOLLOW") or not hasattr(os, "O_DIRECTORY"):
        raise PathError("descriptor-relative no-follow POSIX I/O is required")
    return os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW


def _open_root(path, forbidden=()):
    flags = _directory()
    fd = os.open("/", flags)
    try:
        for part in path[1:].split("/") if path != "/" else ():
            child = os.open(part, flags, dir_fd=fd)
            try:
                info = os.fstat(child)
                if (info.st_dev, info.st_ino) in forbidden:
                    raise PathError("output must not be inside an input root")
            except BaseException:
                os.close(child)
                raise
            os.close(fd)
            fd = child
        return fd
    except BaseException:
        os.close(fd)
        raise


class Root:
    def __init__(self, path):
        self.path = _absolute(path)
        self.fd = _open_root(self.path)
        self._writable = False

    @classmethod
    def create_output(cls, path, *, protected=()):
        path = _absolute(path)
        parent, name = path.rsplit("/", 1)
        identities = [os.fstat(root.fd) for root in protected]
        forbidden = {(info.st_dev, info.st_ino) for info in identities}
        parent_fd = _open_root(parent or "/", forbidden)
        try:
            os.mkdir(name, 0o700, dir_fd=parent_fd)
            fd = os.open(name, _directory(), dir_fd=parent_fd)
        finally:
            os.close(parent_fd)
        root = cls.__new__(cls)
        root.path, root.fd, root._writable = path, fd, True
        try:
            os.fchmod(fd, 0o700)
        except BaseException:
            root.close()
            raise
        return root

    def __enter__(self):
        return self

    def __exit__(self, *unused):
        self.close()

    def close(self):
        if self.fd >= 0:
            os.close(self.fd)
            self.fd = -1

    def _parent(self, relative, *, create=False):
        parts = _parts(relative)
        fd = os.dup(self.fd)
        try:
            for part in parts[:-1]:
                if create:
                    try:
                        os.mkdir(part, 0o700, dir_fd=fd)
                    except FileExistsError:
                        pass
                child = os.open(part, _directory(), dir_fd=fd)
                os.close(fd)
                fd = child
            return fd, parts[-1]
        except BaseException:
            os.close(fd)
            raise

    def read(self, relative, expected_sha256=None):
        if expected_sha256 is not None and (
            not isinstance(expected_sha256, str) or not re.fullmatch(r"[0-9a-f]{64}", expected_sha256)
        ):
            raise PathError("require a lowercase SHA-256")
        parent, name = self._parent(relative)
        try:
            fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=parent)
        finally:
            os.close(parent)
        try:
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_size > MAX_BYTES:
                raise PathError("require a bounded, single-link regular file")
            with os.fdopen(fd, "rb", closefd=False) as stream:
                data = stream.read(MAX_BYTES + 1)
        finally:
            os.close(fd)
        if len(data) > MAX_BYTES:
            raise PathError("input exceeds the byte limit")
        if expected_sha256 is not None and hashlib.sha256(data).hexdigest() != expected_sha256:
            raise PathError("input hash mismatch")
        return data

    def write(self, relative, data):
        if not self._writable:
            raise PathError("input roots are read-only")
        if not isinstance(data, bytes) or len(data) > MAX_BYTES:
            raise PathError("require bounded byte content")
        parent, name = self._parent(relative, create=True)
        try:
            fd = os.open(name, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW,
                         0o600, dir_fd=parent)
        finally:
            os.close(parent)
        try:
            with os.fdopen(fd, "wb", closefd=False) as stream:
                os.fchmod(fd, 0o600)
                stream.write(data)
                stream.flush()
                os.fsync(fd)
        finally:
            os.close(fd)
