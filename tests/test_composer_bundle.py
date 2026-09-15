"""A complete fourteen-target bundle made solely from public synthetic data."""
import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from composer.bundle import BundleError, compose_bundle, decode_json
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


class BundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path, self.manifest = fixture(Path(self.temp.name).resolve())

    def compose(self):
        pin = save_manifest(self.path, self.manifest)
        with Root(self.path) as root:
            return compose_bundle(root, pin)

    def test_full_bundle_is_repeatable_without_writing_inputs(self):
        first = self.compose()
        self.assertEqual(first, self.compose())
        metadata, candidates = first
        self.assertEqual(len(candidates), 14)
        self.assertEqual(metadata["versions"], self.manifest["versions"])
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


if __name__ == "__main__":

    unittest.main()
