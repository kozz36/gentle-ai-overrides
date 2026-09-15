"""Exercise the actual module CLI against complete disposable snapshots."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from composer.bundle import compose_bundle
from composer.storage import PathError, Root
from test_composer_bundle import fixture, save_manifest


def snapshot(path, candidates, ownership="user-owned"):
    path.mkdir()
    entries = {}
    for target, candidate in candidates.items():
        file = path / target
        file.parent.mkdir(exist_ok=True)
        file.write_bytes(candidate["content"])
        entries[target] = {"sha256": candidate["sha256"], "tools": candidate["tools"], "ownership": ownership}
    # Deliberately noncanonical: its raw digest is distinct from capture evidence.
    (path / "state.json").write_text(json.dumps({"schema": "asset-snapshot/v1", "entries": entries}, indent=2))


class CliTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.bundle, manifest = fixture(self.base)
        self.pin = save_manifest(self.bundle, manifest)
        with Root(self.bundle) as root:
            _, self.candidates = compose_bundle(root, self.pin)
        self.installed, self.baseline, self.claims = (
            self.base / "installed", self.base / "baseline", self.base / "claims"
        )
        snapshot(self.installed, self.candidates)
        snapshot(self.baseline, self.candidates)
        snapshot(self.claims, self.candidates)

    def run_cli(self, output, baseline=True, **flags):
        options = {"input": str(self.bundle), "manifest-sha256": self.pin,
                   "installed": str(self.installed), "claims-home": str(self.claims),
                   "output": str(output)}
        if baseline:
            options["baseline"] = str(self.baseline)
        options.update(flags)
        command = [sys.executable] + (["-O"] if sys.flags.optimize else []) + ["-m", "composer"]
        for key, value in options.items():
            command.extend(["--" + key, value])
        return subprocess.run(command, cwd=Path(__file__).resolve().parents[1],
                              env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"),
                              capture_output=True, timeout=10)

    def test_cli_writes_fourteen_candidates_and_a_noop_plan(self):
        output = self.base / "output"
        result = self.run_cli(output)
        self.assertEqual(result.returncode, 0, result.stderr)
        plan = json.loads((output / "plan.json").read_bytes())
        self.assertFalse(plan["blocked"])
        self.assertEqual(len(plan["rows"]), 14)
        self.assertTrue(all(row["action"] == "noop" for row in plan["rows"]))
        for target, candidate in self.candidates.items():
            self.assertEqual((output / target).read_bytes(), candidate["content"])

    def test_claims_home_is_required(self):
        output = self.base / "output"
        command = [sys.executable, "-m", "composer", "--input", str(self.bundle),
                   "--manifest-sha256", self.pin, "--installed", str(self.installed),
                   "--output", str(output)]
        result = subprocess.run(command, cwd=Path(__file__).resolve().parents[1],
                                capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 2)
        self.assertFalse(output.exists())

    def test_module_help_starts_and_advertises_claims_home(self):
        command = [sys.executable] + (["-O"] if sys.flags.optimize else []) + ["-m", "composer", "--help"]
        result = subprocess.run(command, cwd=Path(__file__).resolve().parents[1],
                                env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"),
                                capture_output=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b"--claims-home", result.stdout)

    def change_snapshot(self, root, target, content):
        path = root / "state.json"
        state = json.loads(path.read_bytes())
        if content is None:
            (root / target).unlink()
            state["entries"][target] = None
        else:
            (root / target).write_bytes(content)
            state["entries"][target]["sha256"] = hashlib.sha256(content).hexdigest()
        path.write_text(json.dumps(state, sort_keys=True))

    def write_claim_manifest(self, assets):
        manifest = self.claims / "gentle-ai" / "managed-assets.json"
        manifest.parent.mkdir(exist_ok=True)
        manifest.write_bytes(json.dumps({"schemaVersion": 1, "assets": assets}).encode())
        return manifest

    def test_package_claim_evidence_uses_a_distinct_canonical_snapshot_pin(self):
        output = self.base / "output"
        self.assertEqual(self.run_cli(output).returncode, 0)
        plan = json.loads((output / "plan.json").read_bytes())
        expected_entries = {
            target: {"sha256": candidate["sha256"], "tools": candidate["tools"],
                     "ownership": "user-owned"}
            for target, candidate in self.candidates.items()
        }
        expected_payload = json.dumps(
            {"schema": "asset-snapshot/v1", "entries": expected_entries}, sort_keys=True,
            separators=(",", ":"), allow_nan=False
        ).encode()
        self.assertEqual(plan["installed_snapshot_sha256"],
                         hashlib.sha256((self.installed / "state.json").read_bytes()).hexdigest())
        self.assertEqual(plan["package_claim_snapshot_sha256"],
                         hashlib.sha256(expected_payload).hexdigest())
        self.assertNotEqual(plan["installed_snapshot_sha256"], plan["package_claim_snapshot_sha256"])
        self.assertIsNone(plan["package_claims"]["manifestSha256"])
        self.assertTrue(all(claim["manifestSha256"] is None
                            for claim in plan["package_claims"]["claims"]))

    def test_missing_and_empty_claim_manifests_are_distinct_evidence(self):
        absent, empty = self.base / "absent", self.base / "empty"
        self.assertEqual(self.run_cli(absent).returncode, 0)
        absent_plan = json.loads((absent / "plan.json").read_bytes())
        manifest = self.write_claim_manifest({})
        self.assertEqual(self.run_cli(empty).returncode, 0)
        empty_plan = json.loads((empty / "plan.json").read_bytes())
        self.assertIsNone(absent_plan["package_claims"]["manifestSha256"])
        self.assertEqual(empty_plan["package_claims"]["manifestSha256"],
                         hashlib.sha256(manifest.read_bytes()).hexdigest())
        self.assertNotEqual(empty_plan["package_claims"]["manifestSha256"], None)
        self.assertTrue(all(claim["manifestSha256"] is None
                            for claim in empty_plan["package_claims"]["claims"]))
        self.assertFalse(empty_plan["package_claims"]["conflicts"])

    def test_package_claim_conflicts_block_otherwise_unblocked_rows(self):
        target = "agents/sdd-apply.md"
        current = self.candidates[target]["content"]
        desired_hash = self.candidates[target]["sha256"]
        stale_hash = hashlib.sha256(b"stale claim").hexdigest()
        for name, manifest_hash, old in (
            ("current", desired_hash, None),
            ("stale", stale_hash, None),
            ("desired", desired_hash, current + b"Previous body.\n"),
            ("ownership", desired_hash, None),
        ):
            with self.subTest(name=name):
                for root in (self.installed, self.baseline, self.claims):
                    self.change_snapshot(root, target, old if old is not None else current)
                self.write_claim_manifest({target: manifest_hash})
                output = self.base / ("conflict-" + name)
                result = self.run_cli(output)
                self.assertEqual(result.returncode, 2, result.stderr)
                plan = json.loads((output / "plan.json").read_bytes())
                self.assertTrue(plan["blocked"])
                self.assertFalse(any(row["action"] == "blocked" for row in plan["rows"]))
                reasons = {conflict["reason"] for conflict in plan["package_claims"]["conflicts"]}
                self.assertIn({"current": "current_claim", "stale": "stale_claim",
                               "desired": "desired_hash_reattachment",
                               "ownership": "ownership_contradiction"}[name], reasons)

    def test_claim_snapshot_mismatch_and_claim_evidence_errors_leave_no_output(self):
        target = "agents/sdd-apply.md"
        self.change_snapshot(self.claims, target, self.candidates[target]["content"] + b"Different root.\n")
        mismatch = self.base / "mismatch"
        self.assertEqual(self.run_cli(mismatch).returncode, 3)
        self.assertFalse(mismatch.exists())
        self.change_snapshot(self.claims, target, self.candidates[target]["content"])
        for name, data in (
            ("malformed", b'{"schemaVersion":1,'),
            ("unsafe", json.dumps({"schemaVersion": 1, "assets": {
                "../escape": hashlib.sha256(b"unsafe").hexdigest()}}).encode()),
        ):
            with self.subTest(name=name):
                manifest = self.claims / "gentle-ai" / "managed-assets.json"
                manifest.parent.mkdir(exist_ok=True)
                manifest.write_bytes(data)
                output = self.base / name
                self.assertEqual(self.run_cli(output).returncode, 3)
                self.assertFalse(output.exists())
        missing_root = self.base / "missing-claims-root"
        output = self.base / "bad-root"
        self.assertEqual(self.run_cli(output, **{"claims-home": str(missing_root)}).returncode, 3)
        self.assertFalse(output.exists())

    def test_repeated_outputs_are_identical_and_inputs_unchanged(self):
        roots = (self.bundle, self.installed, self.baseline, self.claims)
        before = {str(p): p.read_bytes() for root in roots for p in root.rglob("*") if p.is_file()}
        first, second = self.base / "one", self.base / "two"
        self.assertEqual(self.run_cli(first).returncode, 0)
        self.assertEqual(self.run_cli(second).returncode, 0)
        for file in first.rglob("*"):
            if file.is_file():
                self.assertEqual(file.read_bytes(), (second / file.relative_to(first)).read_bytes())
        self.assertEqual(before, {str(p): p.read_bytes() for root in roots for p in root.rglob("*") if p.is_file()})

    def test_local_drift_and_missing_baseline_produce_blocked_plans(self):
        target = "agents/sdd-apply.md"
        self.change_snapshot(self.installed, target, self.candidates[target]["content"] + b"Manual edit.\n")
        self.change_snapshot(self.claims, target, self.candidates[target]["content"] + b"Manual edit.\n")
        for baseline, reason in ((True, "local_drift"), (False, "baseline_required")):
            output = self.base / ("with-base" if baseline else "without-base")
            result = self.run_cli(output, baseline=baseline)
            self.assertEqual(result.returncode, 2, result.stderr)
            row = json.loads((output / "plan.json").read_bytes())["rows"][0]
            self.assertEqual(row["reason"], reason)

    def test_baseline_match_proposes_but_never_changes_installed_bytes(self):
        target = "agents/sdd-apply.md"
        old = self.candidates[target]["content"] + b"Previous body.\n"
        for root in (self.installed, self.baseline, self.claims):
            self.change_snapshot(root, target, old)
        output = self.base / "output"
        self.assertEqual(self.run_cli(output).returncode, 0)
        row = json.loads((output / "plan.json").read_bytes())["rows"][0]
        self.assertEqual(row["action"], "propose")
        self.assertIn("-Previous body.", row["diff"])
        self.assertEqual((self.installed / target).read_bytes(), old)

    def test_missing_installed_file_stays_missing_and_is_unknown_claim_evidence(self):
        target = "agents/sdd-apply.md"
        self.change_snapshot(self.installed, target, None)
        self.change_snapshot(self.claims, target, None)
        output = self.base / "output"
        self.assertEqual(self.run_cli(output).returncode, 2)
        plan = json.loads((output / "plan.json").read_bytes())
        claim = next(claim for claim in plan["package_claims"]["claims"]
                     if claim["target"] == target)
        self.assertEqual(claim["declaredOwnership"], "unknown")
        self.assertFalse((self.installed / target).exists())

    def test_output_cannot_be_inside_any_input_root(self):
        for root in (self.bundle, self.installed, self.baseline, self.claims):
            output = root / "candidate"
            with self.subTest(root=root):
                self.assertEqual(self.run_cli(output).returncode, 3)
                self.assertFalse(output.exists())

    def test_corrupt_snapshot_and_wrong_pin_leave_no_output(self):
        target = "agents/sdd-apply.md"
        (self.installed / target).write_bytes(b"Changed without snapshot metadata.\n")
        output = self.base / "output"
        self.assertEqual(self.run_cli(output).returncode, 3)
        self.assertFalse(output.exists())
        self.assertEqual(self.run_cli(output, **{"manifest-sha256": "0" * 64}).returncode, 3)
        self.assertFalse(output.exists())

    def test_ownership_is_reported_not_repaired(self):
        path = self.installed / "state.json"
        state = json.loads(path.read_bytes())
        state["entries"]["agents/sdd-apply.md"]["ownership"] = "managed"
        path.write_text(json.dumps(state, sort_keys=True))
        output = self.base / "output"
        self.assertEqual(self.run_cli(output).returncode, 2)
        plan = json.loads((output / "plan.json").read_bytes())
        self.assertEqual(plan["rows"][0]["reason"], "unsupported_ownership")
        self.assertIn("ownership_contradiction",
                      {conflict["reason"] for conflict in plan["package_claims"]["conflicts"]})
        self.assertEqual(json.loads(path.read_bytes()), state)

    def test_overlap_guard_uses_descriptor_identity_not_root_spelling(self):
        with Root(self.bundle) as protected:
            protected.path = str(self.base / "different-spelling")
            with self.assertRaises(PathError):
                Root.create_output(self.bundle / "inside", protected=[protected])
        self.assertFalse((self.bundle / "inside").exists())

    def test_write_failure_preserves_partial_candidates_without_plan(self):
        import argparse
        from unittest.mock import patch
        from composer.__main__ import compose
        output = self.base / "partial"
        args = argparse.Namespace(input=str(self.bundle), manifest_sha256=self.pin,
                                  installed=str(self.installed), claims_home=str(self.claims),
                                  baseline=str(self.baseline), output=str(output))
        original_write = Root.write
        def fail_second(root, relative, data):
            if relative == "agents/sdd-archive.md":
                raise OSError("injected output failure")
            return original_write(root, relative, data)
        with patch.object(Root, "write", fail_second), self.assertRaises(OSError):
            compose(args)
        self.assertTrue((output / "agents/sdd-apply.md").is_file())
        self.assertFalse((output / "plan.json").exists())

    def test_existing_output_is_preserved(self):
        output = self.base / "output"
        output.mkdir()
        (output / "keep").write_bytes(b"Existing\n")
        self.assertEqual(self.run_cli(output).returncode, 3)
        self.assertEqual((output / "keep").read_bytes(), b"Existing\n")
        self.assertEqual(len(list(output.iterdir())), 1)


if __name__ == "__main__":

    unittest.main()
