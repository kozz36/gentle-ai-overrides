"""Read-only package-ownership conflict observations."""
from dataclasses import FrozenInstanceError, replace
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
    OWNERSHIP_CONTRADICTION,
    PACKAGE_VERSION,
    STALE_CLAIM,
    PackageClaim,
    PackageClaimConflict,
    PackageClaimError,
    PackageClaimObservation,
    observe_package_claims,
    serialize_package_claim_evidence,
)
from composer.storage import MAX_BYTES, Root


class PackageClaimTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve()
        self.manifest = self.home / "gentle-ai" / "managed-assets.json"
        self.ownership = dict.fromkeys(TARGETS, "unknown")
        self.current = {target: self.digest(target) for target in TARGETS}
        self.desired = {target: self.digest(target + " desired") for target in TARGETS}

    @staticmethod
    def digest(value):
        return hashlib.sha256(value.encode()).hexdigest()

    def write_manifest(self, assets):
        self.manifest.parent.mkdir(exist_ok=True)
        self.manifest.write_text(json.dumps({"schemaVersion": 1, "assets": assets}))

    def observe(self, **changes):
        values = {
            "declared_ownership": self.ownership,
            "current_sha256": self.current,
            "desired_sha256": self.desired,
        }
        values.update(changes)
        with Root(self.home) as root:
            return observe_package_claims(root, **values)

    def test_optional_annotations_remain_postponed_strings(self):
        self.assertEqual(PackageClaim.__annotations__["current_sha256"], "str | None")
        self.assertEqual(PackageClaimConflict.__annotations__["manifest_sha256"], "str | None")
        self.assertEqual(PackageClaimObservation.__annotations__["manifest_sha256"], "str | None")
        self.assertEqual(observe_package_claims.__annotations__["current_sha256"],
                         "Mapping[str, str | None]")

    def test_missing_manifest_never_grants_ownership(self):
        result = self.observe()
        self.assertIsNone(result.manifest_sha256)
        self.assertEqual(result.conflicts, ())
        self.assertEqual(result.package_version, PACKAGE_VERSION)

    def test_empty_manifest_is_observed_without_fixture_writes(self):
        self.write_manifest({})
        before = {path.relative_to(self.home): path.read_bytes() for path in self.home.rglob("*") if path.is_file()}
        result = self.observe()
        after = {path.relative_to(self.home): path.read_bytes() for path in self.home.rglob("*") if path.is_file()}
        self.assertIsNotNone(result.manifest_sha256)
        self.assertEqual(result.conflicts, ())
        self.assertEqual(before, after)

    def test_current_claim_is_canonical_conflict(self):
        target = TARGETS[0]
        self.write_manifest({target: self.current[target]})
        result = self.observe()
        self.assertEqual([item.reason for item in result.conflicts], [CURRENT_CLAIM])
        self.assertEqual(result.conflicts[0].target, target)

    def test_desired_hash_reattachment_is_canonical_conflict(self):
        target = TARGETS[0]
        self.write_manifest({target: self.desired[target]})
        result = self.observe()
        self.assertEqual([item.reason for item in result.conflicts], [DESIRED_HASH_REATTACHMENT])

    def test_stale_claim_is_canonical_conflict(self):
        target = TARGETS[0]
        self.write_manifest({target: self.digest("stale")})
        result = self.observe()
        self.assertEqual([item.reason for item in result.conflicts], [STALE_CLAIM])

    def test_ownership_contradictions_include_missing_and_claimed_entries(self):
        target = TARGETS[0]
        ownership = dict(self.ownership, **{target: "managed"})
        self.assertEqual([item.reason for item in self.observe(declared_ownership=ownership).conflicts],
                         [OWNERSHIP_CONTRADICTION])
        ownership[target] = "user-owned"
        self.write_manifest({target: self.current[target]})
        self.assertEqual([item.reason for item in self.observe(declared_ownership=ownership).conflicts],
                         [CURRENT_CLAIM, OWNERSHIP_CONTRADICTION])

    def test_unrelated_legitimate_entry_is_validated_but_never_read(self):
        unrelated = "agents/gentle-ai-worker.md"
        self.write_manifest({unrelated: self.digest("unrelated")})
        self.assertEqual(self.observe().conflicts, ())
        self.assertFalse((self.home / unrelated).exists())

    def test_invalid_inputs_fail_before_manifest_read(self):
        invalid = [
            {"declared_ownership": {}},
            {"declared_ownership": dict(self.ownership, **{TARGETS[0]: "invalid"})},
            {"current_sha256": dict(self.current, **{TARGETS[0]: "A" * 64})},
            {"desired_sha256": dict(self.desired, **{TARGETS[0]: None})},
        ]
        with Root(self.home) as root, mock.patch.object(root, "read") as read:
            for changes in invalid:
                with self.subTest(changes=changes), self.assertRaises(PackageClaimError):
                    observe_package_claims(root, **{
                        "declared_ownership": self.ownership,
                        "current_sha256": self.current,
                        "desired_sha256": self.desired,
                        **changes,
                    })
            read.assert_not_called()
        with self.assertRaises(PackageClaimError):
            observe_package_claims(object(), declared_ownership=self.ownership,
                                   current_sha256=self.current, desired_sha256=self.desired)

    def test_malformed_duplicate_and_unsupported_manifests_are_rejected(self):
        self.manifest.parent.mkdir(exist_ok=True)
        for data in (
            b'{"schemaVersion":1,"schemaVersion":1,"assets":{}}',
            b'{"schemaVersion":2,"assets":{}}',
            b'{"schemaVersion":true,"assets":{}}',
            b'{"schemaVersion":1,"assets":[]}',
        ):
            with self.subTest(data=data):
                self.manifest.write_bytes(data)
                with self.assertRaises(PackageClaimError):
                    self.observe()

    def test_unsafe_manifest_entries_and_files_are_rejected(self):
        for assets in (
            {"../escape": self.digest("safe")},
            {"agents/valid.md": "A" * 64},
        ):
            with self.subTest(assets=assets):
                self.write_manifest(assets)
                with self.assertRaises(PackageClaimError):
                    self.observe()
        self.manifest.unlink()
        outside = self.home / "outside"
        outside.write_text("manifest")
        self.manifest.symlink_to(outside)
        with self.assertRaises(OSError):
            self.observe()

    def test_oversize_manifest_is_rejected_by_root_bounds(self):
        self.manifest.parent.mkdir(exist_ok=True)
        self.manifest.write_bytes(b" " * (MAX_BYTES + 1))
        with self.assertRaises(ValueError):
            self.observe()

    def test_serializer_returns_canonical_observed_evidence(self):
        target = TARGETS[0]
        self.write_manifest({target: self.current[target]})
        observation = self.observe()

        evidence = serialize_package_claim_evidence(observation)

        self.assertEqual(list(evidence), [
            "packageVersion", "manifestSchemaVersion", "manifestSha256", "claims", "conflicts",
        ])
        self.assertEqual(evidence["packageVersion"], PACKAGE_VERSION)
        self.assertEqual(evidence["manifestSchemaVersion"], 1)
        self.assertEqual(evidence["manifestSha256"], observation.manifest_sha256)
        self.assertEqual(len(evidence["claims"]), 14)
        self.assertEqual([claim["target"] for claim in evidence["claims"]], list(TARGETS))
        self.assertEqual(evidence["claims"][0], {
            "target": target,
            "declaredOwnership": "unknown",
            "currentSha256": self.current[target],
            "desiredSha256": self.desired[target],
            "manifestSha256": self.current[target],
        })
        self.assertEqual(evidence["conflicts"], [{
            "target": target,
            "reason": CURRENT_CLAIM,
            "declaredOwnership": "unknown",
            "currentSha256": self.current[target],
            "desiredSha256": self.desired[target],
            "manifestSha256": self.current[target],
        }])
        json.dumps(evidence, sort_keys=True, allow_nan=False)

    def test_serializer_preserves_missing_empty_and_absent_current_evidence(self):
        target = TARGETS[0]
        current = dict(self.current, **{target: None})
        missing = serialize_package_claim_evidence(self.observe(current_sha256=current))
        self.write_manifest({})
        empty = serialize_package_claim_evidence(self.observe(current_sha256=current))

        self.assertIsNone(missing["manifestSha256"])
        self.assertIsNotNone(empty["manifestSha256"])
        self.assertEqual([claim["manifestSha256"] for claim in missing["claims"]], [None] * 14)
        self.assertEqual([claim["manifestSha256"] for claim in empty["claims"]], [None] * 14)
        self.assertIsNone(missing["claims"][0]["currentSha256"])
        self.assertIsNone(empty["claims"][0]["currentSha256"])
        self.assertEqual(missing["conflicts"], [])
        self.assertEqual(empty["conflicts"], [])

    def test_serializer_returns_fresh_detached_nested_containers(self):
        target = TARGETS[0]
        self.write_manifest({target: self.current[target]})
        observation = self.observe()
        first = serialize_package_claim_evidence(observation)
        first["claims"][0]["target"] = "tampered"
        first["conflicts"][0]["reason"] = "tampered"

        second = serialize_package_claim_evidence(observation)

        self.assertEqual(observation.claims[0].target, target)
        self.assertEqual(observation.conflicts[0].reason, CURRENT_CLAIM)
        self.assertEqual(second["claims"][0]["target"], target)
        self.assertEqual(second["conflicts"][0]["reason"], CURRENT_CLAIM)
        self.assertIsNot(first["claims"], second["claims"])
        self.assertIsNot(first["claims"][0], second["claims"][0])

    def test_serializer_rejects_omitted_forged_duplicated_and_reordered_conflicts(self):
        first, second = TARGETS[:2]
        self.write_manifest({first: self.current[first], second: self.desired[second]})
        observation = self.observe()
        conflicts = observation.conflicts
        tampered = (
            (),
            conflicts + (conflicts[0],),
            tuple(reversed(conflicts)),
            (replace(conflicts[0], reason=STALE_CLAIM),) + conflicts[1:],
        )

        for supplied in tampered:
            with self.subTest(conflicts=supplied):
                with self.assertRaises(PackageClaimError):
                    serialize_package_claim_evidence(replace(observation, conflicts=supplied))

    def test_serializer_rejects_forged_dataclass_boundaries(self):
        target = TARGETS[0]
        self.write_manifest({target: self.current[target]})
        observation = self.observe()
        first_claim = observation.claims[0]
        first_conflict = observation.conflicts[0]
        forged = (
            object(),
            replace(observation, package_version="2.9.1"),
            replace(observation, manifest_schema_version=True),
            replace(observation, claims=list(observation.claims)),
            replace(observation, claims=tuple(reversed(observation.claims))),
            replace(observation, claims=(replace(first_claim, desired_sha256=None),) + observation.claims[1:]),
            replace(observation, manifest_sha256=None),
            replace(observation, conflicts=(replace(first_conflict, current_sha256=1),)),
        )

        for supplied in forged:
            with self.subTest(observation=supplied):
                with self.assertRaises(PackageClaimError):
                    serialize_package_claim_evidence(supplied)

    def test_observation_evidence_is_immutable(self):
        target = TARGETS[0]
        self.write_manifest({target: self.current[target]})
        result = self.observe()
        with self.assertRaises(FrozenInstanceError):
            result.manifest_sha256 = "changed"
        with self.assertRaises(FrozenInstanceError):
            result.claims[0].manifest_sha256 = "changed"
        with self.assertRaises(TypeError):
            result.conflicts[0] = None


if __name__ == "__main__":
    unittest.main()
