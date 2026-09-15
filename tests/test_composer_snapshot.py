"""Read-only capture from explicit roots containing only synthetic assets."""
import hashlib
import json
import os
from dataclasses import FrozenInstanceError
from types import MappingProxyType
from unittest import mock
from pathlib import Path
import tempfile
import unittest

from composer.bundle import TARGETS
from composer.snapshot import SnapshotError, capture_snapshot
from composer.storage import MAX_BYTES, Root


class SnapshotTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.path = Path(temporary.name).resolve()
        self.owners = dict.fromkeys(TARGETS, "user-owned")
        self.data = {}
        for target in TARGETS:
            data = b"Synthetic chain.\n"
            if target.startswith("agents/"):
                data = ("---\nname: " + Path(target).stem +
                        "\ndescription: Synthetic agent.\ntools:\n  - read\n---\nBody.\n").encode()
            path = self.path / target
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(data)
            self.data[target] = data

    def capture(self):
        with Root(self.path) as root:
            return capture_snapshot(root, declared_ownership=self.owners)

    def test_complete_capture_is_canonical_and_preserves_inputs(self):
        result = self.capture()
        self.assertEqual(result, self.capture())
        state = json.loads(result.payload)
        self.assertEqual(state["schema"], "asset-snapshot/v1")
        self.assertEqual(list(state["entries"]), list(TARGETS))
        self.assertEqual(result.digest, hashlib.sha256(result.payload).hexdigest())
        for target, observation in result.entries.items():
            self.assertEqual(observation["sha256"], hashlib.sha256(self.data[target]).hexdigest())
            self.assertEqual(observation["ownership"], "user-owned")
            self.assertEqual(observation["tools"], ["read"] if target.startswith("agents/") else None)
            self.assertEqual((self.path / target).read_bytes(), self.data[target])
        self.assertFalse((self.path / "state.json").exists())

    def test_missing_targets_and_directories_remain_absent(self):
        for target in TARGETS:
            with self.subTest(target=target):
                path = self.path / target
                path.unlink()
                self.assertIsNone(self.capture().entries[target])
                self.assertFalse(path.exists())
                path.write_bytes(self.data[target])
        empty = self.path / "empty"
        empty.mkdir()
        with Root(empty) as root:
            result = capture_snapshot(root, declared_ownership=self.owners)
        self.assertEqual(result.entries, dict.fromkeys(TARGETS))
        self.assertEqual(list(empty.iterdir()), [])

    def test_ownership_is_preserved_not_discovered(self):
        before = self.capture()
        self.owners[TARGETS[0]] = "managed"
        self.owners[TARGETS[1]] = "unknown"
        result = self.capture()
        self.assertEqual(result.entries[TARGETS[0]]["ownership"], "managed")
        self.assertEqual(result.entries[TARGETS[1]]["ownership"], "unknown")
        self.assertNotEqual(before.digest, result.digest)
        with Root(self.path) as root:
            self.assertEqual(result, capture_snapshot(root, declared_ownership=MappingProxyType(self.owners)))

    def test_bad_declarations_fail_before_any_read(self):
        invalid = [None, list(self.owners), {}, dict(self.owners, extra="user-owned")]
        for value in (None, False, [], "adopted"):
            owner = dict(self.owners)
            owner[TARGETS[0]] = value
            invalid.append(owner)
        with Root(self.path) as root, mock.patch.object(root, "read") as read:
            for owners in invalid:
                with self.subTest(owners=repr(owners)[:60]), self.assertRaises(ValueError):
                    capture_snapshot(root, declared_ownership=owners)
            read.assert_not_called()

    def test_malformed_agent_data_fails_closed(self):
        path = self.path / TARGETS[0]
        for content in (b"no frontmatter\n", b"\xff\n",
                        self.data[TARGETS[0]].replace(b"  - read\n", b"  - read\n  - read\n")):
            with self.subTest(content=content):
                path.write_bytes(content)
                with self.assertRaises(ValueError):
                    self.capture()

    def test_unsafe_nodes_and_oversize_files_are_not_absence(self):
        path = self.path / TARGETS[0]
        safe = self.path / "safe-source"
        safe.write_bytes(self.data[TARGETS[0]])
        for kind in ("symlink", "hardlink", "directory", "fifo", "oversize"):
            with self.subTest(kind=kind):
                path.unlink()
                if kind == "symlink":
                    path.symlink_to(safe)
                elif kind == "hardlink":
                    os.link(safe, path)
                elif kind == "directory":
                    path.mkdir()
                elif kind == "fifo":
                    os.mkfifo(path)
                else:
                    path.write_bytes(b"x" * (MAX_BYTES + 1))
                with self.assertRaises((OSError, ValueError)):
                    self.capture()
                if kind == "directory":
                    path.rmdir()
                else:
                    path.unlink()
                path.write_bytes(self.data[TARGETS[0]])

    def test_late_io_error_propagates_without_a_partial_result_or_writes(self):
        with Root(self.path) as root:
            original_read = root.read
            def read(target):
                if target == TARGETS[-1]:
                    raise PermissionError("synthetic failure")
                return original_read(target)
            with mock.patch.object(root, "read", side_effect=read) as reader:
                with mock.patch.object(root, "write") as writer:
                    with self.assertRaises(PermissionError):
                        capture_snapshot(root, declared_ownership=self.owners)
                    writer.assert_not_called()
                self.assertEqual(reader.call_count, len(TARGETS))
        self.assertFalse((self.path / "state.json").exists())

    def test_output_and_nested_entries_are_detached(self):
        result = self.capture()
        original = result.payload
        entries = result.entries
        entries[TARGETS[0]]["tools"].append("bash")
        self.owners[TARGETS[0]] = "unknown"
        self.assertEqual(result.payload, original)
        self.assertEqual(result.entries[TARGETS[0]]["tools"], ["read"])
        self.assertEqual(result.entries[TARGETS[0]]["ownership"], "user-owned")
        with self.assertRaises(FrozenInstanceError):
            result.payload = b"changed"

    def test_existing_snapshot_reader_accepts_captured_schema(self):
        from composer.__main__ import _snapshot
        result = self.capture()
        # Only the test persists evidence in its owned fixture, never capture_snapshot.
        (self.path / "state.json").write_bytes(result.payload)
        with Root(self.path) as root:
            entries, contents, digest = _snapshot(root)
        self.assertEqual(entries, result.entries)
        self.assertEqual(contents, self.data)
        self.assertEqual(digest, result.digest)

    def test_serialized_metadata_has_an_aggregate_limit(self):
        for target in TARGETS:
            if target.startswith("agents/"):
                large = self.data[target].replace(b"  - read\n", b"  - " + b"t" * 90000 + b"\n")
                self.assertLess(len(large), MAX_BYTES)
                (self.path / target).write_bytes(large)
        with self.assertRaises(SnapshotError):
            self.capture()


if __name__ == "__main__":
    unittest.main()
