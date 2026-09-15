"""Read-only composition of snapshot and package-claim evidence."""
from dataclasses import FrozenInstanceError
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from composer.bundle import TARGETS
from composer.package_claims import (
    CURRENT_CLAIM,
    DESIRED_HASH_REATTACHMENT,
    MANIFEST_PATH,
    PackageClaimError,
    observe_package_claims,
)
from composer.preparation import PackageClaimPreparation, prepare_package_claim_evidence
from composer.snapshot import SnapshotError
from composer.storage import Root


class PackageClaimPreparationTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name).resolve()
        self.ownership = dict.fromkeys(TARGETS, "unknown")
        self.contents = {}
        for target in TARGETS:
            content = b"Synthetic chain.\n"
            if target.startswith("agents/"):
                content = ("---\nname: " + Path(target).stem +
                           "\ndescription: Synthetic agent.\ntools:\n  - read\n---\nBody.\n").encode()
            path = self.home / target
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(content)
            self.contents[target] = content
        self.desired = {target: self.digest(("desired:" + target).encode()) for target in TARGETS}
        self.manifest = self.home / MANIFEST_PATH

    @staticmethod
    def digest(content):
        return hashlib.sha256(content).hexdigest()

    def write_manifest(self, assets):
        self.manifest.parent.mkdir(exist_ok=True)
        self.manifest.write_bytes(json.dumps({"schemaVersion": 1, "assets": assets}).encode())

    def prepare(self, root, **changes):
        values = {"declared_ownership": self.ownership, "desired_sha256": self.desired}
        values.update(changes)
        return prepare_package_claim_evidence(root, **values)

    def tracked_prepare(self, **changes):
        reads = []
        with Root(self.home) as root:
            original_read = root.read

            def read(relative):
                reads.append((root.path, relative))
                return original_read(relative)

            with mock.patch.object(root, "read", side_effect=read) as reader:
                with mock.patch.object(root, "write") as writer:
                    result = self.prepare(root, **changes)
                writer.assert_not_called()
            self.assertEqual(reader.call_count, len(reads))
        return result, reads

    def test_complete_preparation_reads_targets_then_manifest_inside_explicit_root(self):
        before = {target: (self.home / target).read_bytes() for target in TARGETS}
        result, reads = self.tracked_prepare()
        self.assertIsInstance(result, PackageClaimPreparation)
        self.assertEqual(len(result.snapshot.entries), 14)
        self.assertEqual(len(result.observation.claims), 14)
        self.assertEqual(result.snapshot.digest, self.digest(result.snapshot.payload))
        self.assertEqual(
            [relative for _, relative in reads], list(TARGETS) + [MANIFEST_PATH]
        )
        self.assertTrue(all(path == str(self.home) for path, _ in reads))
        self.assertEqual(before, {target: (self.home / target).read_bytes() for target in TARGETS})
        self.assertFalse(self.manifest.exists())

    def test_current_hashes_are_derived_from_snapshot_and_missing_is_none(self):
        target = TARGETS[0]
        (self.home / target).unlink()
        result, reads = self.tracked_prepare()
        entries = result.snapshot.entries
        self.assertIsNone(entries[target])
        claims = {claim.target: claim for claim in result.observation.claims}
        self.assertIsNone(claims[target].current_sha256)
        for other in TARGETS[1:]:
            self.assertEqual(claims[other].current_sha256, entries[other]["sha256"])
        self.assertEqual([relative for _, relative in reads], list(TARGETS) + [MANIFEST_PATH])

    def test_current_and_desired_conflicts_are_observer_output_unchanged(self):
        target = TARGETS[0]
        current = self.digest(self.contents[target])
        for pin, reason in ((current, CURRENT_CLAIM),
                            (self.desired[target], DESIRED_HASH_REATTACHMENT)):
            with self.subTest(reason=reason):
                self.write_manifest({target: pin})
                result, _ = self.tracked_prepare()
                current_hashes = {
                    name: entry["sha256"] if entry is not None else None
                    for name, entry in result.snapshot.entries.items()
                }
                with Root(self.home) as root:
                    expected = observe_package_claims(
                        root, declared_ownership=self.ownership,
                        current_sha256=current_hashes, desired_sha256=self.desired,
                    )
                self.assertEqual(result.observation, expected)
                self.assertEqual([item.reason for item in result.observation.conflicts], [reason])

    def test_missing_manifest_grants_nothing_and_unrelated_assets_are_not_read(self):
        result, reads = self.tracked_prepare()
        self.assertIsNone(result.observation.manifest_sha256)
        self.assertEqual(result.observation.conflicts, ())
        unrelated = "agents/not-a-composer-target.md"
        self.write_manifest({unrelated: self.digest(b"unrelated")})
        result, reads = self.tracked_prepare()
        self.assertIsNotNone(result.observation.manifest_sha256)
        self.assertEqual(result.observation.conflicts, ())
        self.assertEqual([relative for _, relative in reads], list(TARGETS) + [MANIFEST_PATH])
        self.assertFalse((self.home / unrelated).exists())

    def test_unsafe_and_malformed_manifests_fail_closed_after_snapshot(self):
        for data in (
            b'{"schemaVersion":1,"schemaVersion":1,"assets":{}}',
            json.dumps({"schemaVersion": 1, "assets": {"../escape": self.digest(b"x")}}).encode(),
        ):
            with self.subTest(data=data):
                self.manifest.parent.mkdir(exist_ok=True)
                self.manifest.write_bytes(data)
                with Root(self.home) as root:
                    with mock.patch.object(root, "write") as writer:
                        with self.assertRaises(PackageClaimError):
                            self.prepare(root)
                    writer.assert_not_called()

    def test_invalid_root_and_ownership_fail_before_target_reads(self):
        with self.assertRaises(PackageClaimError):
            self.prepare(object())
        invalid = dict(self.ownership, **{TARGETS[0]: "invalid"})
        with Root(self.home) as root:
            with mock.patch.object(root, "read") as read:
                with self.assertRaises(SnapshotError):
                    self.prepare(root, declared_ownership=invalid)
            read.assert_not_called()

    def test_invalid_desired_hash_fails_before_manifest_read(self):
        invalid = dict(self.desired, **{TARGETS[0]: "A" * 64})
        with Root(self.home) as root:
            original_read = root.read
            reads = []

            def read(relative):
                reads.append(relative)
                return original_read(relative)

            with mock.patch.object(root, "read", side_effect=read):
                with self.assertRaises(PackageClaimError):
                    self.prepare(root, desired_sha256=invalid)
        self.assertEqual(reads, list(TARGETS))

    def test_declared_ownership_is_detached_before_first_root_read(self):
        target = TARGETS[0]
        ownership = dict(self.ownership)
        with Root(self.home) as root:
            original_read = root.read
            changed = False

            def read(relative):
                nonlocal changed
                if not changed:
                    ownership[target] = "managed"
                    changed = True
                return original_read(relative)

            with mock.patch.object(root, "read", side_effect=read):
                result = self.prepare(root, declared_ownership=ownership)
        claim = next(item for item in result.observation.claims if item.target == target)
        self.assertEqual(result.snapshot.entries[target]["ownership"], "unknown")
        self.assertEqual(claim.declared_ownership, "unknown")

    def test_desired_hashes_are_detached_before_first_root_read(self):
        target = TARGETS[0]
        desired = dict(self.desired)
        original_desired = desired[target]
        self.write_manifest({target: original_desired})
        with Root(self.home) as root:
            original_read = root.read
            changed = False

            def read(relative):
                nonlocal changed
                if not changed:
                    desired[target] = self.digest(b"changed desired")
                    changed = True
                return original_read(relative)

            with mock.patch.object(root, "read", side_effect=read):
                result = self.prepare(root, desired_sha256=desired)
        claim = next(item for item in result.observation.claims if item.target == target)
        self.assertEqual(claim.desired_sha256, original_desired)
        self.assertEqual(
            [item.reason for item in result.observation.conflicts],
            [DESIRED_HASH_REATTACHMENT],
        )

    def test_root_precedes_and_mapping_type_errors_make_no_root_reads(self):
        with self.assertRaises(PackageClaimError) as error:
            prepare_package_claim_evidence(object(), declared_ownership=[], desired_sha256=[])
        self.assertEqual(str(error.exception), "require an explicit Root agent home")
        with Root(self.home) as root:
            with mock.patch.object(root, "read") as read:
                with self.assertRaises(SnapshotError):
                    self.prepare(root, declared_ownership=list(self.ownership.items()))
                with self.assertRaises(PackageClaimError):
                    self.prepare(root, desired_sha256=list(self.desired.items()))
            read.assert_not_called()

    def test_ordinary_preparation_does_not_mutate_input_mappings(self):
        ownership = dict(self.ownership)
        desired = dict(self.desired)
        self.tracked_prepare(declared_ownership=ownership, desired_sha256=desired)
        self.assertEqual(ownership, self.ownership)
        self.assertEqual(desired, self.desired)

    def test_result_and_nested_evidence_cannot_be_mutated_through_callers(self):
        result, _ = self.tracked_prepare()
        target = TARGETS[0]
        original = result.snapshot.entries[target]
        with self.assertRaises(FrozenInstanceError):
            result.snapshot = None
        with self.assertRaises(FrozenInstanceError):
            result.observation.claims[0].desired_sha256 = "changed"
        entries = result.snapshot.entries
        if entries[target]["tools"] is not None:
            entries[target]["tools"].append("bash")
        self.ownership[target] = "managed"
        self.desired[target] = self.digest(b"changed")
        self.assertEqual(result.snapshot.entries[target], original)
        self.assertEqual(result.observation.claims[0].declared_ownership, "unknown")
        self.assertNotEqual(result.observation.claims[0].desired_sha256, self.desired[target])


if __name__ == "__main__":
    unittest.main()
