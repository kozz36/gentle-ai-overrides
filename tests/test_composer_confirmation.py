"""Confirmation preparation over synthetic data; never installation authority."""
import argparse
import copy
from dataclasses import replace
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

from composer.__main__ import compose
from composer.bundle import TARGETS, V2_PROVENANCE_VERSIONS, compose_bundle
from composer.confirmation import ConfirmationError, prepare_confirmation
from composer.package_claims import (MANIFEST_SCHEMA_VERSION, V2_PACKAGE_VERSION, PackageClaim,
                                     PackageClaimObservation, observe_package_claims,
                                     serialize_package_claim_evidence)
from composer.preparation import PackageClaimPreparation, prepare_package_claim_evidence
from composer.planner import PLAN_VERSION, plan_asset
from composer.profiles import V1_SCHEMA, V2_PROFILE
from composer.snapshot import CapturedSnapshot
from composer.storage import Root
from test_composer_bundle import fixture, save_manifest, v2_fixture


class ConfirmationTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        path, manifest = fixture(Path(temp.name).resolve())
        self.base, self.bundle = path.parent, path
        self.pin = save_manifest(path, manifest)
        with Root(path) as root:
            metadata, candidates = compose_bundle(root, self.pin)
        entries = {target: {"sha256": row["sha256"], "tools": row["tools"],
                            "ownership": "user-owned"} for target, row in candidates.items()}
        self.claims_home = path / "claims-home"
        self.claims_home.mkdir()
        for target, candidate in candidates.items():
            claim_path = self.claims_home / target
            claim_path.parent.mkdir(exist_ok=True)
            claim_path.write_bytes(candidate["content"])
        with Root(self.claims_home) as root:
            self.preparation = prepare_package_claim_evidence(
                root, declared_ownership={target: "user-owned" for target in TARGETS},
                desired_sha256={target: candidate["sha256"] for target, candidate in candidates.items()},
            )
        self.args = dict(provenance=metadata, candidates=candidates, installed_entries=entries,
                         installed_snapshot_sha256="a" * 64, baseline_entries=copy.deepcopy(entries),
                         baseline_snapshot_sha256="b" * 64,
                         package_claim_preparation=self.preparation)
        self.rebuild()

    def synthetic_preparation(self, entries):
        payload = json.dumps({"schema": "asset-snapshot/v1", "entries": entries}, sort_keys=True,
                             separators=(",", ":"), allow_nan=False).encode()
        ownership = {target: entry["ownership"] if entry is not None else "unknown"
                     for target, entry in entries.items()}
        current = {target: entry["sha256"] if entry is not None else None
                   for target, entry in entries.items()}
        with Root(self.claims_home) as root:
            observation = observe_package_claims(
                root, declared_ownership=ownership, current_sha256=current,
                desired_sha256={target: candidate["sha256"]
                                for target, candidate in self.args["candidates"].items()},
            )
        return PackageClaimPreparation(
            CapturedSnapshot(payload, hashlib.sha256(payload).hexdigest()), observation)

    def bind_package_plan(self, args, preparation):
        claims = serialize_package_claim_evidence(preparation.observation)
        args["package_claim_preparation"] = preparation
        args["proposed_plan"].update(
            package_claim_snapshot_sha256=preparation.snapshot.digest,
            package_claims=claims,
            blocked=(any(row["action"] == "blocked" for row in args["proposed_plan"]["rows"])
                     or bool(claims["conflicts"])),
        )

    def rebuild(self):
        self.rebuild_args(self.args)

    def rebuild_args(self, args):
        rows = []
        for target in TARGETS:
            candidate = args["candidates"][target]
            baseline = args["baseline_entries"]
            row = plan_asset(target, baseline[target] if baseline is not None else None,
                             args["installed_entries"][target],
                             {key: candidate[key] for key in ("sha256", "tools")})
            row.update(source_sha256=candidate["source_sha256"], diff="")
            rows.append(row)
        claims = serialize_package_claim_evidence(args["package_claim_preparation"].observation)
        args["proposed_plan"] = dict(
            schema=PLAN_VERSION, provenance=copy.deepcopy(args["provenance"]), rows=rows,
            blocked=(any(row["action"] == "blocked" for row in rows) or bool(claims["conflicts"])),
            installed_snapshot_sha256=args["installed_snapshot_sha256"],
            baseline_snapshot_sha256=args["baseline_snapshot_sha256"],
            package_claim_snapshot_sha256=args["package_claim_preparation"].snapshot.digest,
            package_claims=claims,
        )

    def test_required_package_claim_preparation_binds_canonical_evidence(self):
        args = copy.deepcopy(self.args)
        with mock.patch.object(Root, "read") as read, mock.patch.object(Root, "write") as write:
            result = prepare_confirmation(**args)
        read.assert_not_called()
        write.assert_not_called()
        plan = json.loads(result.payload)["plan"]
        self.assertEqual(plan["package_claim_snapshot_sha256"], self.preparation.snapshot.digest)
        self.assertNotEqual(plan["package_claim_snapshot_sha256"], plan["installed_snapshot_sha256"])
        self.assertEqual(plan["package_claims"], serialize_package_claim_evidence(self.preparation.observation))

    def test_package_claim_preparation_is_mandatory_and_typed(self):
        missing = copy.deepcopy(self.args)
        missing.pop("package_claim_preparation")
        with self.assertRaises(TypeError):
            prepare_confirmation(**missing)
        for value in (None, object()):
            with self.subTest(value_type=type(value).__name__):
                args = copy.deepcopy(self.args)
                args["package_claim_preparation"] = value
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_snapshot_evidence_is_canonical_matched_and_separately_pinned(self):
        entries = self.preparation.snapshot.entries
        noncanonical = json.dumps({"schema": "asset-snapshot/v1", "entries": entries}, indent=2).encode()
        mismatched = copy.deepcopy(entries)
        mismatched[TARGETS[0]]["ownership"] = "unknown"
        mismatch_payload = json.dumps({"schema": "asset-snapshot/v1", "entries": mismatched},
                                      sort_keys=True, separators=(",", ":")).encode()
        preparations = {
            "wrong snapshot type": PackageClaimPreparation(object(), self.preparation.observation),
            "wrong snapshot digest": PackageClaimPreparation(
                CapturedSnapshot(self.preparation.snapshot.payload, "c" * 64), self.preparation.observation),
            "noncanonical snapshot": PackageClaimPreparation(
                CapturedSnapshot(noncanonical, hashlib.sha256(noncanonical).hexdigest()),
                self.preparation.observation),
            "snapshot entry mismatch": PackageClaimPreparation(
                CapturedSnapshot(mismatch_payload, hashlib.sha256(mismatch_payload).hexdigest()),
                self.preparation.observation),
        }
        for name, preparation in preparations.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                args["package_claim_preparation"] = preparation
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)
        args = copy.deepcopy(self.args)
        args["proposed_plan"]["package_claim_snapshot_sha256"] = args["installed_snapshot_sha256"]
        with self.assertRaises(ConfirmationError):
            prepare_confirmation(**args)

    def test_package_claim_plan_evidence_requires_exact_serialized_types_and_order(self):
        mutations = {
            "missing claims": lambda claims: claims.pop("claims"),
            "altered current": lambda claims: claims["claims"][0].update(currentSha256="c" * 64),
            "reordered claims": lambda claims: claims["claims"].reverse(),
            "boolean metadata": lambda claims: claims.update(manifestSchemaVersion=True),
            "floating metadata": lambda claims: claims.update(manifestSchemaVersion=1.0),
        }
        for name, mutate in mutations.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                mutate(args["proposed_plan"]["package_claims"])
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_local_claim_cardinality_guard_rejects_serializer_bypass(self):
        for name, mutate in {
            "shortened": lambda claims: claims.pop(),
            "extra": lambda claims: claims.append(dict(claims[-1])),
        }.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                evidence = copy.deepcopy(args["proposed_plan"]["package_claims"])
                mutate(evidence["claims"])
                args["proposed_plan"]["package_claims"] = evidence
                with mock.patch("composer.confirmation.serialize_package_claim_evidence",
                                return_value=evidence) as serializer:
                    with self.assertRaises(ConfirmationError):
                        prepare_confirmation(**args)
                serializer.assert_called_once_with(args["package_claim_preparation"].observation)

    def test_claims_bind_current_desired_and_ownership_to_supplied_evidence(self):
        fields = (("current_sha256", "c" * 64), ("desired_sha256", "c" * 64),
                  ("declared_ownership", "unknown"))
        for field, value in fields:
            with self.subTest(field=field):
                claim = replace(self.preparation.observation.claims[0], **{field: value})
                observation = replace(self.preparation.observation,
                                      claims=(claim,) + self.preparation.observation.claims[1:])
                preparation = PackageClaimPreparation(self.preparation.snapshot, observation)
                args = copy.deepcopy(self.args)
                self.bind_package_plan(args, preparation)
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)
        target = TARGETS[0]
        (self.claims_home / target).unlink()
        entries = copy.deepcopy(self.args["installed_entries"])
        entries[target] = None
        ownership = {name: "unknown" if name == target else "user-owned" for name in TARGETS}
        with Root(self.claims_home) as root:
            preparation = prepare_package_claim_evidence(
                root, declared_ownership=ownership,
                desired_sha256={name: candidate["sha256"]
                                for name, candidate in self.args["candidates"].items()},
            )
        claim = replace(preparation.observation.claims[0], declared_ownership="user-owned")
        forged = PackageClaimPreparation(preparation.snapshot, replace(
            preparation.observation, claims=(claim,) + preparation.observation.claims[1:]))
        args = copy.deepcopy(self.args)
        args.update(installed_entries=entries, baseline_entries=copy.deepcopy(entries),
                    package_claim_preparation=forged)
        self.rebuild_args(args)
        with self.assertRaises(ConfirmationError):
            prepare_confirmation(**args)

    def test_package_claim_conflicts_block_otherwise_noop_rows(self):
        manifest = self.claims_home / "gentle-ai" / "managed-assets.json"
        manifest.parent.mkdir()
        manifest.write_bytes(json.dumps({"schemaVersion": 1, "assets": {
            target: self.args["candidates"][target]["sha256"] for target in TARGETS[:2]
        }}).encode())
        with Root(self.claims_home) as root:
            preparation = prepare_package_claim_evidence(
                root, declared_ownership={target: "user-owned" for target in TARGETS},
                desired_sha256={target: candidate["sha256"]
                                for target, candidate in self.args["candidates"].items()},
            )
        args = copy.deepcopy(self.args)
        self.bind_package_plan(args, preparation)
        self.assertTrue(args["proposed_plan"]["blocked"])
        self.assertTrue(all(row["action"] == "noop" for row in args["proposed_plan"]["rows"]))
        for name, mutate in {
            "canonical conflict": lambda plan: None,
            "forged unblocked": lambda plan: plan.update(blocked=False),
            "omitted conflicts": lambda plan: plan["package_claims"].update(conflicts=[]),
            "reordered conflicts": lambda plan: plan["package_claims"]["conflicts"].reverse(),
        }.items():
            with self.subTest(name=name):
                forged = copy.deepcopy(args)
                mutate(forged["proposed_plan"])
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**forged)

    def test_absent_and_empty_manifests_remain_distinct_evidence(self):
        absent = json.loads(prepare_confirmation(**self.args).payload)["plan"]["package_claims"]
        manifest = self.claims_home / "gentle-ai" / "managed-assets.json"
        manifest.parent.mkdir()
        manifest.write_bytes(b'{"schemaVersion":1,"assets":{}}')
        with Root(self.claims_home) as root:
            preparation = prepare_package_claim_evidence(
                root, declared_ownership={target: "user-owned" for target in TARGETS},
                desired_sha256={target: candidate["sha256"]
                                for target, candidate in self.args["candidates"].items()},
            )
        args = copy.deepcopy(self.args)
        self.bind_package_plan(args, preparation)
        empty = json.loads(prepare_confirmation(**args).payload)["plan"]["package_claims"]
        self.assertIsNone(absent["manifestSha256"])
        self.assertIsNotNone(empty["manifestSha256"])
        self.assertNotEqual(absent, empty)

    def test_noop_is_stable_and_does_not_mutate_inputs(self):
        before = copy.deepcopy(self.args)
        result = prepare_confirmation(**self.args)
        self.assertEqual(result, prepare_confirmation(**copy.deepcopy(self.args)))
        self.assertEqual(self.args, before)
        self.assertEqual(result.digest, hashlib.sha256(result.payload).hexdigest())
        payload = json.loads(result.payload)
        self.assertEqual(payload["kind"], "composer-only-preview")
        self.assertEqual(payload["actions"], {"noop": list(TARGETS), "propose": []})

    def test_v1_payload_shape_and_digest_regression(self):
        result = prepare_confirmation(**self.args)
        payload = json.loads(result.payload)
        self.assertEqual(payload["schema"], "asset-confirmation-plan/v1")
        self.assertEqual(payload["plan"]["schema"], "asset-change-plan/v1")
        self.assertEqual(payload["plan"]["provenance"]["schema"], V1_SCHEMA)
        self.assertEqual(list(payload["desired_entries"]), list(TARGETS))
        self.assertEqual(result.digest, "02a721713fa06b112f51b5293d619cf84f8fd37c6980e95c110dd6dbdbbb9558")

    def test_proposals_are_sorted_and_baseline_is_explicit(self):
        for entries in (self.args["installed_entries"], self.args["baseline_entries"]):
            for entry in entries.values():
                entry["sha256"] = "c" * 64
        self.args["package_claim_preparation"] = self.synthetic_preparation(self.args["installed_entries"])
        self.rebuild()
        result = prepare_confirmation(**self.args)
        self.assertEqual(json.loads(result.payload)["actions"], {"noop": [], "propose": list(TARGETS)})
        self.args.update(baseline_entries=None, baseline_snapshot_sha256=None)
        self.rebuild()
        with self.assertRaises(ConfirmationError):
            prepare_confirmation(**self.args)

    def test_absent_baseline_allows_only_existing_noops(self):
        self.args.update(baseline_entries=None, baseline_snapshot_sha256=None)
        self.rebuild()
        self.assertEqual(json.loads(prepare_confirmation(**self.args).payload)["actions"]["noop"], list(TARGETS))
        self.args["baseline_snapshot_sha256"] = "b" * 64
        with self.assertRaises(ConfirmationError):
            prepare_confirmation(**self.args)

    def test_authority_and_tool_conflicts_cannot_be_hidden(self):
        for field, value in (("ownership", "managed"), ("tools", ["bash"]), ("sha256", "c" * 64)):
            for hidden in (False, True):
                with self.subTest(field=field, hidden=hidden):
                    saved = copy.deepcopy(self.args)
                    self.args["installed_entries"][TARGETS[0]][field] = value
                    self.rebuild()
                    if hidden:
                        self.args["proposed_plan"]["blocked"] = False
                        self.args["proposed_plan"]["rows"][0].update(action="noop", reason="already_matches")
                    with self.assertRaises(ConfirmationError):
                        prepare_confirmation(**self.args)
                    self.args = saved

    def test_plan_edits_are_not_authorization(self):
        for field, value in (("action", "propose"), ("reason", "baseline_matches"),
                             ("source_sha256", "c" * 64), ("installed_ownership", "managed")):
            with self.subTest(field=field):
                args = copy.deepcopy(self.args)
                args["proposed_plan"]["rows"][0][field] = value
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_inventory_and_row_shapes_fail_closed(self):
        mutations = {
            "missing candidate": lambda a: a["candidates"].pop(TARGETS[0]),
            "extra observation": lambda a: a["installed_entries"].update(extra=None),
            "missing row": lambda a: a["proposed_plan"]["rows"].pop(),
            "duplicate row": lambda a: a["proposed_plan"]["rows"].__setitem__(1, a["proposed_plan"]["rows"][0]),
            "reversed rows": lambda a: a["proposed_plan"]["rows"].reverse(),
            "unknown row field": lambda a: a["proposed_plan"]["rows"][0].update(unknown=True),
            "missing row field": lambda a: a["proposed_plan"]["rows"][0].pop("diff"),
            "unknown plan field": lambda a: a["proposed_plan"].update(approved=True),
            "missing package snapshot pin": lambda a: a["proposed_plan"].pop("package_claim_snapshot_sha256"),
            "missing package claims": lambda a: a["proposed_plan"].pop("package_claims"),
            "invalid blocked": lambda a: a["proposed_plan"].update(blocked=0),
            "wrong blocked": lambda a: a["proposed_plan"].update(blocked=True),
            "invalid pin": lambda a: a.update(installed_snapshot_sha256="invalid"),
        }
        for name, mutate in mutations.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                mutate(args)
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_candidate_bytes_and_tools_are_verified(self):
        for field, value in (("content", b"tampered\n"), ("tools", ["bash"]), ("sha256", "c" * 64)):
            with self.subTest(field=field):
                args = copy.deepcopy(self.args)
                args["candidates"][TARGETS[0]][field] = value
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_supplied_metadata_must_match_the_display_plan(self):
        for key in ("installed_snapshot_sha256", "baseline_snapshot_sha256"):
            args = copy.deepcopy(self.args)
            args["proposed_plan"][key] = "c" * 64
            with self.subTest(key=key), self.assertRaises(ConfirmationError):
                prepare_confirmation(**args)
        self.args["proposed_plan"]["provenance"]["manifest_sha256"] = "c" * 64
        with self.assertRaises(ConfirmationError):
            prepare_confirmation(**self.args)

    def test_matching_but_malformed_provenance_is_rejected(self):
        for key, value in (("versions", []), ("overlay_revision", "short"), ("rules", {})):
            with self.subTest(key=key):
                saved = copy.deepcopy(self.args)
                self.args["provenance"][key] = value
                self.rebuild()
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**self.args)
                self.args = saved

    def test_missing_or_unknown_provenance_schema_fails_closed(self):
        for name, mutate in {
            "missing": lambda provenance: provenance.pop("schema"),
            "unknown": lambda provenance: provenance.update(schema="deterministic-assets/v99"),
        }.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                mutate(args["provenance"])
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_all_observation_pins_sources_and_display_are_bound(self):
        before = prepare_confirmation(**self.args).digest
        self.args["installed_snapshot_sha256"] = "c" * 64
        self.rebuild()
        changed = prepare_confirmation(**self.args).digest
        self.assertNotEqual(before, changed)
        self.args["candidates"][TARGETS[0]]["source_sha256"] = "d" * 64
        self.rebuild()
        source_changed = prepare_confirmation(**self.args).digest
        self.assertNotEqual(changed, source_changed)
        self.args["proposed_plan"]["rows"][0]["diff"] = "display-only text\n"
        self.assertNotEqual(source_changed, prepare_confirmation(**self.args).digest)

    def test_cli_producer_plan_binds_independent_preparation(self):
        installed, baseline = self.base / "installed", self.base / "baseline"
        entries = self.args["installed_entries"]
        for root in (installed, baseline):
            root.mkdir()
            for target, candidate in self.args["candidates"].items():
                path = root / target
                path.parent.mkdir(exist_ok=True)
                path.write_bytes(candidate["content"])
            (root / "state.json").write_bytes(json.dumps(
                {"schema": "asset-snapshot/v1", "entries": entries}, indent=2).encode())
        output = self.base / "producer-output"
        self.assertFalse(compose(argparse.Namespace(
            input=str(self.bundle), manifest_sha256=self.pin, installed=str(installed),
            claims_home=str(self.claims_home), baseline=str(baseline), output=str(output),
        )))
        plan = json.loads((output / "plan.json").read_bytes())
        with Root(self.claims_home) as root:
            preparation = prepare_package_claim_evidence(
                root, declared_ownership={target: "user-owned" for target in TARGETS},
                desired_sha256={target: candidate["sha256"]
                                for target, candidate in self.args["candidates"].items()},
            )
        result = prepare_confirmation(
            provenance=self.args["provenance"], candidates=self.args["candidates"],
            installed_entries=entries, installed_snapshot_sha256=plan["installed_snapshot_sha256"],
            baseline_entries=self.args["baseline_entries"],
            baseline_snapshot_sha256=plan["baseline_snapshot_sha256"], proposed_plan=plan,
            package_claim_preparation=preparation,
        )
        self.assertEqual(json.loads(result.payload)["plan"], plan)

    def test_output_is_immutable_and_detached_from_callers(self):
        from dataclasses import FrozenInstanceError
        result = prepare_confirmation(**self.args)
        payload = result.payload
        self.args["provenance"]["versions"]["gentle_ai"] = "changed"
        self.args["installed_entries"][TARGETS[0]]["tools"].append("new-tool")
        self.args["proposed_plan"]["package_claims"]["claims"][0]["target"] = "tampered"
        self.assertEqual(result.payload, payload)
        with self.assertRaises(FrozenInstanceError):
            result.digest = "changed"

    def test_total_size_and_display_encoding_are_bounded(self):
        for text in (None, "\ud800", "x" * 80000):
            with self.subTest(text_type=type(text).__name__):
                args = copy.deepcopy(self.args)
                for row in args["proposed_plan"]["rows"]:
                    row["diff"] = text
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)


class V2ConfirmationTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        path, manifest, _ = v2_fixture(Path(temp.name).resolve())
        self.pin = save_manifest(path, manifest)
        with Root(path) as root:
            provenance, candidates = compose_bundle(root, self.pin)
        self.optional = V2_PROFILE.optional_targets[0]
        self.optional_candidate = candidates.pop(self.optional)
        provenance["optional_absent"] = [self.optional]
        self.candidates = candidates
        self.entries = {
            target: None if target == self.optional else {
                "sha256": candidates[target]["sha256"], "tools": candidates[target]["tools"],
                "ownership": "user-owned",
            }
            for target in V2_PROFILE.targets
        }
        self.args = dict(
            provenance=provenance, candidates=candidates, installed_entries=self.entries,
            installed_snapshot_sha256="a" * 64, baseline_entries=copy.deepcopy(self.entries),
            baseline_snapshot_sha256="b" * 64,
            package_claim_preparation=self.literal_preparation(),
        )
        self.rebuild(self.args)

    def literal_preparation(self, observation=None, entries=None):
        entries = self.entries if entries is None else entries
        document = {"schema": "asset-snapshot/v2", "profileSchema": V2_PROFILE.schema,
                    "entries": entries}
        payload = json.dumps(document, sort_keys=True, separators=(",", ":"),
                             allow_nan=False).encode()
        if observation is None:
            claims = tuple(PackageClaim(
                target, "unknown" if entries[target] is None else "user-owned",
                None if entries[target] is None else entries[target]["sha256"],
                self.candidates.get(target, {}).get("sha256"), None,
            ) for target in V2_PROFILE.targets)
            observation = PackageClaimObservation(
                V2_PACKAGE_VERSION, MANIFEST_SCHEMA_VERSION, None, claims, (), V2_PROFILE.schema)
        return PackageClaimPreparation(
            CapturedSnapshot(payload, hashlib.sha256(payload).hexdigest()), observation)

    def rebuild(self, args):
        rows = []
        for target in V2_PROFILE.targets:
            if target not in args["candidates"]:
                continue
            candidate = args["candidates"][target]
            row = plan_asset(target, args["baseline_entries"][target],
                             args["installed_entries"][target],
                             {key: candidate[key] for key in ("sha256", "tools")})
            row.update(source_sha256=candidate["source_sha256"], diff="")
            rows.append(row)
        claims = serialize_package_claim_evidence(args["package_claim_preparation"].observation)
        args["proposed_plan"] = {
            "schema": PLAN_VERSION, "provenance": copy.deepcopy(args["provenance"]), "rows": rows,
            "blocked": bool(claims["conflicts"]),
            "installed_snapshot_sha256": args["installed_snapshot_sha256"],
            "baseline_snapshot_sha256": args["baseline_snapshot_sha256"],
            "package_claim_snapshot_sha256": args["package_claim_preparation"].snapshot.digest,
            "package_claims": claims,
        }

    def bind(self, args, preparation):
        args["package_claim_preparation"] = preparation
        args["proposed_plan"].update(
            package_claim_snapshot_sha256=preparation.snapshot.digest,
            package_claims=serialize_package_claim_evidence(preparation.observation),
        )

    def test_literal_v2_absence_binds_full_evidence_without_a_row_or_desired_entry(self):
        payload = json.loads(prepare_confirmation(**self.args).payload)
        self.assertEqual(payload["plan"]["provenance"]["optional_absent"], [self.optional])
        self.assertEqual(payload["plan"]["provenance"]["versions"], dict(V2_PROVENANCE_VERSIONS))
        self.assertEqual(payload["plan"]["package_claims"]["packageVersion"], V2_PACKAGE_VERSION)
        self.assertEqual(payload["plan"]["package_claims"]["profileSchema"], V2_PROFILE.schema)
        self.assertEqual(list(payload["installed_entries"]), list(V2_PROFILE.targets))
        self.assertEqual(list(payload["baseline_entries"]), list(V2_PROFILE.targets))
        self.assertNotIn(self.optional, payload["desired_entries"])
        self.assertNotIn(self.optional, payload["actions"]["noop"])
        self.assertNotIn(self.optional, payload["actions"]["propose"])
        self.assertEqual([row["target"] for row in payload["plan"]["rows"]],
                         [target for target in V2_PROFILE.targets if target != self.optional])

    def test_present_optional_candidate_is_bound_in_canonical_order(self):
        args = copy.deepcopy(self.args)
        args["candidates"][self.optional] = copy.deepcopy(self.optional_candidate)
        args["provenance"]["optional_absent"] = []
        entries = copy.deepcopy(self.entries)
        entries[self.optional] = {"sha256": self.optional_candidate["sha256"],
                                  "tools": self.optional_candidate["tools"],
                                  "ownership": "user-owned"}
        args.update(installed_entries=entries, baseline_entries=copy.deepcopy(entries))
        claims = list(args["package_claim_preparation"].observation.claims)
        index = V2_PROFILE.targets.index(self.optional)
        claims[index] = replace(claims[index], declared_ownership="user-owned",
                                current_sha256=self.optional_candidate["sha256"],
                                desired_sha256=self.optional_candidate["sha256"])
        preparation = self.literal_preparation(replace(
            args["package_claim_preparation"].observation, claims=tuple(claims)), entries)
        args["package_claim_preparation"] = preparation
        self.rebuild(args)
        payload = json.loads(prepare_confirmation(**args).payload)
        self.assertEqual([row["target"] for row in payload["plan"]["rows"]],
                         list(V2_PROFILE.targets))
        self.assertEqual(payload["desired_entries"][self.optional]["sha256"],
                         self.optional_candidate["sha256"])

    def test_v2_requires_exact_release_provenance_versions(self):
        mutations = {
            "missing": lambda versions: versions.pop("overlay"),
            "extra": lambda versions: versions.update(extra="3.2.0"),
            "wrong": lambda versions: versions.update(gentle_ai="3.1.1"),
            "cross-profile": lambda versions: versions.update(gentle_pi="3.1.0"),
        }
        for name, mutate in mutations.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                mutate(args["provenance"]["versions"])
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_v2_cross_profile_provenance_snapshot_claim_candidate_and_row_fail_closed(self):
        def wrong_provenance(args):
            args["provenance"]["schema"] = V1_SCHEMA

        def wrong_snapshot(args):
            snapshot = args["package_claim_preparation"].snapshot
            payload = json.dumps({"schema": "asset-snapshot/v1", "entries": self.entries},
                                 sort_keys=True, separators=(",", ":")).encode()
            args["package_claim_preparation"] = PackageClaimPreparation(
                CapturedSnapshot(payload, hashlib.sha256(payload).hexdigest()),
                args["package_claim_preparation"].observation)

        def wrong_claim(args):
            observation = replace(args["package_claim_preparation"].observation,
                                  profile_schema=V1_SCHEMA)
            args["package_claim_preparation"] = self.literal_preparation(observation)

        def wrong_candidates(args):
            args["candidates"] = {target: candidate for target, candidate in args["candidates"].items()
                                  if target in TARGETS}

        def wrong_rows(args):
            args["proposed_plan"]["rows"].reverse()

        for name, mutate in {
            "provenance": wrong_provenance, "snapshot": wrong_snapshot, "claim": wrong_claim,
            "candidate": wrong_candidates, "row": wrong_rows,
        }.items():
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                mutate(args)
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_forged_optional_absence_and_claim_none_present_mismatches_fail_closed(self):
        args = copy.deepcopy(self.args)
        args["provenance"]["optional_absent"] = []
        with self.assertRaises(ConfirmationError):
            prepare_confirmation(**args)
        for name, claim in {
            "absent desired present": replace(
                self.args["package_claim_preparation"].observation.claims[-1],
                desired_sha256=self.args["candidates"][V2_PROFILE.targets[0]]["sha256"]),
            "present current absent": replace(
                self.args["package_claim_preparation"].observation.claims[0], current_sha256=None),
        }.items():
            with self.subTest(name=name):
                observation = replace(self.args["package_claim_preparation"].observation,
                                      claims=self.args["package_claim_preparation"].observation.claims[:-1]
                                      + (claim,) if name.startswith("absent") else (claim,)
                                      + self.args["package_claim_preparation"].observation.claims[1:])
                args = copy.deepcopy(self.args)
                self.bind(args, self.literal_preparation(observation))
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)

    def test_v2_baseline_and_installed_key_drift_fail_closed(self):
        for name, mapping in (("installed", "installed_entries"), ("baseline", "baseline_entries")):
            with self.subTest(name=name):
                args = copy.deepcopy(self.args)
                args[mapping].pop(self.optional)
                with self.assertRaises(ConfirmationError):
                    prepare_confirmation(**args)


if __name__ == "__main__":
    unittest.main()
