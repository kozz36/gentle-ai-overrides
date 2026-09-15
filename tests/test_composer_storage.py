"""Filesystem checks use only freshly created, disposable fixture roots."""
import hashlib
import os
from unittest.mock import patch
from pathlib import Path
import tempfile
import unittest

from composer.storage import PathError, Root


class StorageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.source = self.base / "input"
        self.source.mkdir()
        (self.source / "file.md").write_bytes(b"Source\n")

    def test_explicit_root_reads_verified_bytes(self):
        with Root(self.source) as root:
            self.assertEqual(root.read("file.md", hashlib.sha256(b"Source\n").hexdigest()), b"Source\n")

    def test_new_output_is_private_and_never_overwrites(self):
        output = self.base / "output"
        with Root.create_output(output) as root:
            root.write("agents/result.md", b"Candidate\n")
            self.assertEqual(root.read("agents/result.md"), b"Candidate\n")
            with self.assertRaises(FileExistsError):
                root.write("agents/result.md", b"Overwrite\n")
        self.assertEqual(output.stat().st_mode & 0o777, 0o700)
        self.assertEqual((output / "agents/result.md").stat().st_mode & 0o777, 0o600)
        with self.assertRaises(FileExistsError):
            Root.create_output(output)

    def test_input_root_has_no_write_authority(self):
        with Root(self.source) as root, self.assertRaises(PathError):
            root.write("new.md", b"No\n")
        self.assertFalse((self.source / "new.md").exists())

    def test_relative_path_rejections_do_not_escape_or_create_directories(self):
        output = self.base / "output"
        with Root(self.source) as source, Root.create_output(output) as dest:
            for name in ("../file.md", "/file.md", "a/../file", "a//file", "./file", "a\\file", "a/", ""):
                with self.subTest(name=name):
                    with self.assertRaises(PathError):
                        source.read(name)
                    with self.assertRaises(PathError):
                        dest.write(name, b"No\n")
        self.assertEqual(list(output.iterdir()), [])

    def test_symlinked_root_or_ancestor_is_rejected(self):
        link = self.base / "link"
        link.symlink_to(self.source, target_is_directory=True)
        for path in (link, link / "subdir"):
            with self.subTest(path=path), self.assertRaises(OSError):
                Root(path)
        with self.assertRaises(OSError):
            Root.create_output(link / "output")
        self.assertFalse((self.source / "output").exists())

    def test_symlinked_file_and_child_directory_are_rejected(self):
        (self.source / "link").symlink_to(self.source / "file.md")
        (self.source / "dirlink").symlink_to(self.source, target_is_directory=True)
        with Root(self.source) as root:
            for name in ("link", "dirlink/file.md"):
                with self.subTest(name=name), self.assertRaises(OSError):
                    root.read(name)
        with Root.create_output(self.base / "output") as root:
            (Path(root.path) / "link").symlink_to(self.source, target_is_directory=True)
            with self.assertRaises(OSError):
                root.write("link/new.md", b"No\n")
        self.assertFalse((self.source / "new.md").exists())

    def test_hash_mismatch_and_invalid_digest_are_rejected(self):
        with Root(self.source) as root:
            for digest in ("a" * 64, "A" * 64, "not-a-hash", 1):
                with self.subTest(digest=digest), self.assertRaises(PathError):
                    root.read("file.md", digest)

    def test_hardlinks_fifos_and_oversize_inputs_are_rejected(self):
        os.link(self.source / "file.md", self.source / "hardlink")
        os.mkfifo(self.source / "fifo")
        with (self.source / "large").open("wb") as stream:
            stream.truncate(1024 * 1024 + 1)
        with Root(self.source) as root:
            for name in ("hardlink", "fifo", "large"):
                with self.subTest(name=name), self.assertRaises(PathError):
                    root.read(name)

    def test_nonregular_directories_are_rejected_before_stream_creation(self):
        (self.source / "directory").mkdir()
        with Root(self.source) as root, self.assertRaises(PathError):
            root.read("directory")

    def test_file_descriptor_is_closed_when_stream_construction_fails(self):
        real_open = os.open
        opened = []
        def tracking_open(*args, **kwargs):
            fd = real_open(*args, **kwargs)
            opened.append(fd)
            return fd
        with Root(self.source) as root:
            with patch("composer.storage.os.open", side_effect=tracking_open):
                with patch("composer.storage.os.fdopen", side_effect=RuntimeError("injected")):
                    with self.assertRaises(RuntimeError):
                        root.read("file.md")
            for fd in opened:
                with self.assertRaises(OSError):
                    os.fstat(fd)

    def test_failed_output_stream_closes_descriptor_and_keeps_partial_evidence(self):
        real_open, opened = os.open, []
        def tracking_open(*args, **kwargs):
            fd = real_open(*args, **kwargs)
            opened.append(fd)
            return fd
        with Root.create_output(self.base / "output") as root:
            with patch("composer.storage.os.open", side_effect=tracking_open):
                with patch("composer.storage.os.fdopen", side_effect=RuntimeError("injected")):
                    with self.assertRaises(RuntimeError):
                        root.write("partial.md", b"Candidate\n")
            for fd in opened:
                with self.assertRaises(OSError):
                    os.fstat(fd)
            self.assertEqual(root.read("partial.md"), b"")

    def test_growth_after_initial_stat_is_still_bounded(self):
        from types import SimpleNamespace
        (self.source / "large").write_bytes(b"x" * (1024 * 1024 + 1))
        with Root(self.source) as root:
            before_growth = SimpleNamespace(st_mode=0o100600, st_nlink=1, st_size=0)
            with patch("composer.storage.os.fstat", return_value=before_growth):
                with self.assertRaises(PathError):
                    root.read("large")

    def test_read_root_stays_bound_after_its_path_is_replaced(self):
        with Root(self.source) as root:
            original = self.base / "original"
            self.source.rename(original)
            self.source.symlink_to(self.base, target_is_directory=True)
            self.assertEqual(root.read("file.md"), b"Source\n")

    def test_closed_roots_and_unsupported_absolute_roots_do_not_reopen(self):
        root = Root(self.source)
        root.close()
        with self.assertRaises(OSError):
            root.read("file.md")
        for path in ("relative", "/", str(self.source) + "/../input"):
            with self.subTest(path=path), self.assertRaises(PathError):
                Root(path)


if __name__ == "__main__":

    unittest.main()
