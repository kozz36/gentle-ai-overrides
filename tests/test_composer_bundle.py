"""A complete fourteen-target bundle made solely from public synthetic data."""
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from composer.bundle import (BundleError, SCHEMA, TARGETS, V2_PROVENANCE_VERSIONS,
                             compose_bundle, decode_json)
from composer.profiles import V1_PROFILE, V2_PROFILE
from composer.neutral_policy import (GENTLE_INIT_RULE_VERSION,
                                    LEGACY_SDD_INIT_RETIRE_RULE_VERSION)
from composer.neutral_routing import (WORKFLOW_FORWARDING_RULE_VERSION,
                                      DELEGATION_FORWARDING_RULE_VERSION)
from composer.agents import ROLES, MCP_ROLES, RULE_VERSION as AGENT_RULE
from composer.overlay import RULE_VERSION as INIT_RULE
from composer.storage import Root


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fixture(base):
    root = Path(base) / "bundle"
    root.mkdir()
    manifest = {"schema": "deterministic-assets/v1", "versions": {
        "gentle_ai": "2.8.2", "gentle_pi": "2.6.2", "overlay": "v2.6.0-overlay.3"},
        "overlay_revision": "a" * 40, "rules": {"init": INIT_RULE, "agent": AGENT_RULE},
        "blocks": {}, "assets": {}}
    blocks = {
        "init": b"<!-- gentle-ai:sdd-init-rubric -->\nSynthetic init.\n<!-- /gentle-ai:sdd-init-rubric -->\n",
        "codegraph": b"<!-- gentle-ai:pi-codegraph-guidance -->\nSynthetic CG.\n<!-- /gentle-ai:pi-codegraph -->\n",
        "mcp": b"<!-- gentle-ai:pi-codegraph-tool -->\nSynthetic MCP.\n<!-- /gentle-ai:pi-codegraph -->\n",
    }
    (root / "blocks").mkdir()
    for name, data in blocks.items():
        (root / "blocks" / (name + ".md")).write_bytes(data)
        manifest["blocks"][name] = digest(data)
    for role in sorted(ROLES):
        target = "agents/sdd-" + role + ".md"
        data = ("---\nname: sdd-" + role + "\ndescription: Synthetic agent.\ntools:\n  - read\n---\n\nBody.\n").encode()
        if role == "init":
            data += b"\n## Memory Contract\nPreserve memory.\n"
        path = root / "sources" / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        manifest["assets"][target] = {"source_sha256": digest(data), "preferences": {
            "expected_source_tools": ["read"], "mcp": role in MCP_ROLES,
            "model": None if role == "research" else "provider/model",
            "thinking": None if role == "research" else "high"}}
    target = "chains/sdd-verify.chain.md"
    path = root / "sources" / target
    path.parent.mkdir()
    path.write_bytes(b"Synthetic official chain; copied unchanged.\n")
    manifest["assets"][target] = {"source_sha256": digest(path.read_bytes()), "preferences": None}
    return root, manifest


def save_manifest(root, manifest):
    data = (json.dumps(manifest, sort_keys=True, indent=2) + "\n").encode()
    (root / "bundle.json").write_bytes(data)
    return digest(data)


def compose_manifest(path, manifest):
    pin = save_manifest(path, manifest)
    with Root(path) as root:
        return compose_bundle(root, pin)


GENTLE_BLOCK = (b"<!-- gentle-ai:gentle-init-rubric -->\nGentle contract.\n"
                b"<!-- /gentle-ai:gentle-init-rubric -->")
LEGACY_BLOCK = (b"<!-- gentle-ai:sdd-init-rubric -->\nLegacy contract.\n"
                b"<!-- /gentle-ai:sdd-init-rubric -->")
WORKFLOW_CURRENT = (b"<!-- gentle-ai:pi-rubric-forwarding -->\nCurrent workflow.\n"
                    b"<!-- /gentle-ai:pi-rubric-forwarding -->")
WORKFLOW_PREDECESSOR = (b"<!-- gentle-ai:pi-rubric-forwarding -->\nPrevious workflow.\n"
                        b"<!-- /gentle-ai:pi-rubric-forwarding -->")
DELEGATION_CURRENT = (b"<!-- gentle-ai:pi-odd-forwarding -->\nCurrent delegation.\n"
                      b"<!-- /gentle-ai:pi-odd-forwarding -->")
DELEGATION_PREDECESSOR = (b"<!-- gentle-ai:pi-odd-forwarding -->\nPrevious delegation.\n"
                          b"<!-- /gentle-ai:pi-odd-forwarding -->")
WORKFLOW_SOURCE = (
    b"## Strict TDD Forwarding\n"
    b"For `sdd-apply` and `sdd-verify`, read `openspec/config.yaml` when present.\n\n"
    b"If it declares strict TDD and a test command, include a non-negotiable instruction in the phase prompt:\n\n"
    b"```text\nSTRICT TDD MODE IS ACTIVE. Test runner: <command>. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.\n```\n\n"
    b"Do not rely on the child agent to discover this independently.\n"
    + WORKFLOW_PREDECESSOR + b"\n\n## Archive Final-State Handoff\nTail\n")
PACKAGE_SOURCES = {
    "assets/agents/gentle-init.md": b"Header\n## Publication boundary\nTail\n",
    "assets/agents/sdd-init.md": b"Header\n" + LEGACY_BLOCK + b"\n\n## Memory Contract\nTail\n",
    "assets/sdd-orchestrator-workflow.md": WORKFLOW_SOURCE,
    "assets/orchestrator-delegation.md": (
        b"Header\n### Organic Driven Development (ODD)\n"
        b"#### Checks and candidate consent\n" + DELEGATION_PREDECESSOR
        + b"\n\n### Delegation Rules\nTail\n"),
}
PACKAGE_BLOCKS = {
    "gentle_init": GENTLE_BLOCK,
    "legacy_sdd_init": LEGACY_BLOCK,
    "workflow_current": WORKFLOW_CURRENT,
    "workflow_predecessor": WORKFLOW_PREDECESSOR,
    "delegation_current": DELEGATION_CURRENT,
    "delegation_predecessor": DELEGATION_PREDECESSOR,
}
PACKAGE_EXPECTED = {
    "assets/agents/gentle-init.md": b"Header\n" + GENTLE_BLOCK + b"\n## Publication boundary\nTail\n",
    "assets/agents/sdd-init.md": b"Header\n## Memory Contract\nTail\n",
    "assets/sdd-orchestrator-workflow.md": (
        b"## Strict TDD Forwarding\n"
        b"For `sdd-apply` and `sdd-verify`, read `openspec/config.yaml` when present.\n\n"
        b"If it declares strict TDD and a test command, include a non-negotiable instruction in the phase prompt:\n\n"
        b"```text\nSTRICT TDD MODE IS ACTIVE. Test runner: <command>. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.\n```\n\n"
        b"Do not rely on the child agent to discover this independently.\n"
        + WORKFLOW_CURRENT + b"\n\n## Archive Final-State Handoff\nTail\n"),
    "assets/orchestrator-delegation.md": (
        b"Header\n### Organic Driven Development (ODD)\n"
        b"#### Checks and candidate consent\n" + DELEGATION_CURRENT
        + b"\n\n### Delegation Rules\nTail\n"),
}


def v2_rules():
    return {"init": INIT_RULE, "agent": AGENT_RULE,
            "gentle_init": GENTLE_INIT_RULE_VERSION,
            "legacy_sdd_init": LEGACY_SDD_INIT_RETIRE_RULE_VERSION,
            "workflow_forwarding": WORKFLOW_FORWARDING_RULE_VERSION,
            "delegation_forwarding": DELEGATION_FORWARDING_RULE_VERSION}


def v2_fixture(base, delegation=True):
    root, manifest = fixture(base)
    manifest["schema"] = V2_PROFILE.schema
    manifest["versions"] = dict(V2_PROVENANCE_VERSIONS)
    manifest["rules"] = v2_rules()
    for name, data in PACKAGE_BLOCKS.items():
        (root / "blocks" / (name + ".md")).write_bytes(data)
        manifest["blocks"][name] = digest(data)
    for target, source in PACKAGE_SOURCES.items():
        if target == "assets/orchestrator-delegation.md" and delegation is None:
            manifest["assets"][target] = None
            continue
        path = root / "sources" / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(source)
        manifest["assets"][target] = {"source_sha256": digest(source), "preferences": None}
    return root, manifest, PACKAGE_EXPECTED


class BundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path, self.manifest = fixture(Path(self.temp.name).resolve())

    def compose(self):
        pin = save_manifest(self.path, self.manifest)
        with Root(self.path) as root:
            return compose_bundle(root, pin)

    def test_v1_public_aliases_match_the_historical_profile(self):
        self.assertEqual(SCHEMA, "deterministic-assets/v1")
        self.assertEqual(TARGETS, V1_PROFILE.targets)
        self.assertEqual(len(TARGETS), 14)

    def test_full_bundle_is_repeatable_without_writing_inputs(self):
        first = self.compose()
        self.assertEqual(first, self.compose())
        metadata, candidates = first
        self.assertEqual(len(candidates), 14)
        self.assertEqual(tuple(candidates), TARGETS)
        self.assertEqual(set(metadata), {"schema", "versions", "overlay_revision", "rules",
                                         "manifest_sha256", "block_sha256"})
        self.assertEqual(metadata["versions"], self.manifest["versions"])
        self.assertEqual(metadata["rules"], self.manifest["rules"])
        self.assertEqual(candidates["chains/sdd-verify.chain.md"]["content"], b"Synthetic official chain; copied unchanged.\n")
        self.assertEqual(candidates["agents/sdd-apply.md"]["tools"], ["mcp", "read"])
        self.assertIn(b"Synthetic init.", candidates["agents/sdd-init.md"]["content"])

    def test_every_pin_is_mandatory_including_the_manifest(self):
        pin = save_manifest(self.path, self.manifest)
        with Root(self.path) as root, self.assertRaises(ValueError):
            compose_bundle(root, None)
        for location in ("block", "source"):
            original = copy.deepcopy(self.manifest)
            if location == "block":
                self.manifest["blocks"]["init"] = None
            else:
                self.manifest["assets"]["agents/sdd-apply.md"]["source_sha256"] = None
            with self.subTest(location=location), self.assertRaises(ValueError):
                self.compose()
            self.manifest = original
        self.assertEqual(len(self.compose()[1]), 14)

    def test_inventory_changes_are_not_silently_accepted(self):
        original = copy.deepcopy(self.manifest)
        for operation in ("missing", "extra"):
            self.manifest = copy.deepcopy(original)
            if operation == "missing":
                del self.manifest["assets"]["agents/sdd-init.md"]
            else:
                self.manifest["assets"]["agents/sdd-future.md"] = {}
            with self.subTest(operation=operation), self.assertRaises(BundleError):
                self.compose()

    def test_unknown_versions_rules_fields_and_preferences_stop(self):
        original = copy.deepcopy(self.manifest)
        changes = [lambda m: m.update(schema="unknown"), lambda m: m.update(extra=True),
                   lambda m: m.update(overlay_revision="short"),
                   lambda m: m["rules"].update(init="future"),
                   lambda m: m["versions"].update(gentle_pi=""),
                   lambda m: m["assets"]["agents/sdd-apply.md"]["preferences"].update(model=None),
                   lambda m: m["assets"]["agents/sdd-research.md"]["preferences"].update(model="x", thinking="high"),
                   lambda m: m["assets"]["agents/sdd-apply.md"]["preferences"].update(expected_source_tools=["invented"]),
                   lambda m: m["assets"]["chains/sdd-verify.chain.md"].update(preferences={})]
        for change in changes:
            self.manifest = copy.deepcopy(original)
            change(self.manifest)
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.compose()

    def test_modified_source_or_payload_cannot_pass_its_pin(self):
        for relative in ("sources/agents/sdd-apply.md", "blocks/codegraph.md"):
            path = self.path / relative
            original = path.read_bytes()
            path.write_bytes(original + b"Changed\n")
            with self.subTest(relative=relative), self.assertRaises(ValueError):
                self.compose()
            path.write_bytes(original)

    def test_previously_patched_init_is_not_a_pristine_bundle_source(self):
        path = self.path / "sources/agents/sdd-init.md"
        changed = path.read_bytes() + (self.path / "blocks/init.md").read_bytes()
        path.write_bytes(changed)
        self.manifest["assets"]["agents/sdd-init.md"]["source_sha256"] = digest(changed)
        with self.assertRaises(ValueError):
            self.compose()

    def test_duplicate_and_nonfinite_json_are_rejected(self):
        valid = json.dumps(self.manifest).encode()
        cases = (b'{"schema":"ignored",' + valid[1:],
                 valid.replace(b'"mcp": true', b'"mcp": NaN', 1))
        for data in cases:
            with self.subTest(data=data), self.assertRaises(BundleError):
                decode_json(data)


    def test_v2_composes_exact_package_candidates_in_profile_order(self):
        with tempfile.TemporaryDirectory() as base:
            root, manifest, expected = v2_fixture(Path(base))
            pin = save_manifest(root, manifest)
            before = {path.relative_to(root): digest(path.read_bytes()) for path in root.rglob("*")
                      if path.is_file()}
            with Root(root) as bundle:
                first = compose_bundle(bundle, pin)
            with Root(root) as bundle:
                self.assertEqual(first, compose_bundle(bundle, pin))
            self.assertEqual(before, {path.relative_to(root): digest(path.read_bytes())
                                      for path in root.rglob("*") if path.is_file()})
        metadata, candidates = first
        self.assertEqual(tuple(candidates), V2_PROFILE.targets)
        self.assertEqual(len(candidates), 18)
        self.assertEqual(metadata["schema"], V2_PROFILE.schema)
        self.assertEqual(metadata["versions"], dict(V2_PROVENANCE_VERSIONS))
        self.assertEqual(metadata["rules"], v2_rules())
        self.assertEqual(metadata["optional_absent"], [])
        for target, content in expected.items():
            self.assertEqual(candidates[target]["content"], content)

    def test_v2_explicit_null_optional_target_is_absent_without_source_read(self):
        with tempfile.TemporaryDirectory() as base:
            root, manifest, _ = v2_fixture(Path(base), delegation=None)
            metadata, candidates = compose_manifest(root, manifest)
        optional = "assets/orchestrator-delegation.md"
        self.assertNotIn(optional, candidates)
        self.assertEqual(tuple(candidates), tuple(target for target in V2_PROFILE.targets
                                                   if target != optional))
        self.assertEqual(len(candidates), 17)
        self.assertEqual(metadata["optional_absent"], [optional])

    def test_v2_delegation_not_applicable_preserves_pinned_source(self):
        with tempfile.TemporaryDirectory() as base:
            root, manifest, _ = v2_fixture(Path(base))
            target = "assets/orchestrator-delegation.md"
            source = b"Header\nNo ODD anchors.\nTail\n"
            path = root / "sources" / target
            path.write_bytes(source)
            manifest["assets"][target]["source_sha256"] = digest(source)
            _, candidates = compose_manifest(root, manifest)
        self.assertEqual(candidates[target]["content"], source)

    def test_v2_requires_exact_release_provenance_versions(self):
        with tempfile.TemporaryDirectory() as base:
            root, manifest, _ = v2_fixture(Path(base))
            original = copy.deepcopy(manifest)
            changes = {
                "missing": lambda versions: versions.pop("overlay"),
                "extra": lambda versions: versions.update(extra="3.2.0"),
                "wrong": lambda versions: versions.update(gentle_ai="3.1.1"),
                "cross-profile": lambda versions: versions.update(gentle_pi="3.1.0"),
            }
            for name, change in changes.items():
                manifest = copy.deepcopy(original)
                change(manifest["versions"])
                with self.subTest(name=name), self.assertRaises(BundleError):
                    compose_manifest(root, manifest)

    def test_v2_rejects_unrecognized_profiles_and_inventory_declarations(self):
        with tempfile.TemporaryDirectory() as base:
            root, manifest, _ = v2_fixture(Path(base))
            original = copy.deepcopy(manifest)
            changes = (
                lambda m: m.update(schema="unknown"),
                lambda m: m["assets"].pop("assets/agents/gentle-init.md"),
                lambda m: m["assets"].update({"assets/extra.md": None}),
                lambda m: m["assets"].update({"assets/agents/gentle-init.md": None}),
                lambda m: m["assets"].update({"assets/orchestrator-delegation.md": {}}),
                lambda m: m["blocks"].update(gentle_init=None),
                lambda m: m["assets"]["assets/sdd-orchestrator-workflow.md"].update(source_sha256=None),
                lambda m: m["rules"].update(gentle_init="future"),
                lambda m: m["blocks"].pop("workflow_predecessor"),
                lambda m: m.pop("rules"),
                lambda m: m["blocks"].update(extra="0" * 64),
            )
            for change in changes:
                manifest = copy.deepcopy(original)
                change(manifest)
                with self.subTest(change=change), self.assertRaises(BundleError):
                    compose_manifest(root, manifest)

    def test_v2_normalizes_customized_and_partial_package_markers(self):
        with tempfile.TemporaryDirectory() as base:
            root, manifest, _ = v2_fixture(Path(base))
            original = copy.deepcopy(manifest)
            sources = {
                "assets/agents/gentle-init.md": (
                    b"Header\n<!-- gentle-ai:gentle-init-rubric -->\nCustomized.\n"
                    b"<!-- /gentle-ai:gentle-init-rubric -->\n## Publication boundary\nTail\n"),
                "assets/sdd-orchestrator-workflow.md": (
                    WORKFLOW_SOURCE.replace(WORKFLOW_PREDECESSOR,
                                            b"prefix <!-- gentle-ai:pi-rubric-forwarding -->")),
            }
            for target, source in sources.items():
                manifest = copy.deepcopy(original)
                path = root / "sources" / target
                path.write_bytes(source)
                manifest["assets"][target]["source_sha256"] = digest(source)
                with self.subTest(target=target), self.assertRaises(BundleError):
                    compose_manifest(root, manifest)
                path.write_bytes(PACKAGE_SOURCES[target])


if __name__ == "__main__":

    unittest.main()
