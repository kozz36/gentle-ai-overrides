"""Synthetic checks for confirmed preferences and supplied official blocks."""
import unittest

from composer.agents import AgentError, compose_agent

CLOSE = b"<!-- /gentle-ai:pi-codegraph -->\n"
CG = b"<!-- gentle-ai:pi-codegraph-guidance -->\n## CodeGraph\nFixture guidance.\n" + CLOSE
MCP = b"<!-- gentle-ai:pi-codegraph-tool -->\nFixture MCP instructions.\n" + CLOSE
SOURCE = b"---\nname: sdd-apply\ndescription: Fixture agent.\ntools:\n  - read\n  - write\n---\n\nKeep body.\n"


def compose(source=SOURCE, **changes):
    options = dict(role="sdd-apply", expected_source_tools=("read", "write"),
                   guidance=CG, mcp=False, mcp_block=None, model=None, thinking=None)
    options.update(changes)
    return compose_agent(source, **options)


class AgentComposerTests(unittest.TestCase):
    def test_no_inferred_preferences_and_exact_body_suffix(self):
        self.assertEqual(compose(), SOURCE + b"\n" + CG)

    def test_confirmed_pair_and_mcp_are_inserted_in_canonical_order(self):
        result = compose(model="provider/model", thinking="high", mcp=True, mcp_block=MCP)
        expected = SOURCE.replace(b"tools:\n", b"model: provider/model\nthinking: high\ntools:\n  - mcp\n")
        self.assertEqual(result, expected + b"\n" + MCP + b"\n" + CG)

    def test_source_model_alone_is_preserved_without_an_override(self):
        source = SOURCE.replace(b"tools:\n", b"model: upstream/model\ntools:\n")
        self.assertEqual(compose(source), source + b"\n" + CG)

    def test_unpaired_explicit_preferences_are_rejected(self):
        for options in ({"model": "provider/model"}, {"thinking": "high"}):
            with self.subTest(options=options), self.assertRaises(AgentError):
                compose(**options)

    def test_tool_contract_drift_is_not_reconciled(self):
        with self.assertRaises(AgentError):
            compose(expected_source_tools=("read",))

    def test_mcp_requires_a_supported_role_and_explicit_matching_block(self):
        source = SOURCE.replace(b"sdd-apply", b"sdd-design")
        for options in ({"mcp": True}, {"mcp_block": MCP}, {"mcp": "yes"}):
            with self.subTest(options=options), self.assertRaises(AgentError):
                compose(**options)
        with self.assertRaises(AgentError):
            compose(source, role="sdd-design", mcp=True, mcp_block=MCP)

    def test_replaces_existing_pair_without_duplicates(self):
        source = SOURCE.replace(b"tools:\n", b"model: old/model\nthinking: low\ntools:\n")
        result = compose(source, model="new/model", thinking="xhigh")
        self.assertNotIn(b"old/model", result)
        self.assertEqual(result.count(b"model:"), 1)
        self.assertEqual(result.count(b"thinking:"), 1)

    def test_all_supported_roles_preserve_explicit_tool_choice(self):
        roles = "apply archive design explore init onboard proposal research spec status sync tasks verify".split()
        allowed = set("apply archive init onboard status sync verify".split())
        for role in roles:
            with self.subTest(role=role):
                source = SOURCE.replace(b"sdd-apply", ("sdd-" + role).encode())
                result = compose(source, role="sdd-" + role, mcp=role in allowed,
                                 mcp_block=MCP if role in allowed else None)
                self.assertEqual(b"  - mcp\n" in result, role in allowed)
                self.assertEqual(result.count(CG), 1)

    def test_duplicate_source_tools_are_not_a_valid_contract(self):
        source = SOURCE.replace(b"  - write\n", b"  - read\n")
        with self.assertRaises(AgentError):
            compose(source, expected_source_tools=("read", "read"))

    def test_unsupported_headers_and_identity_are_rejected(self):
        cases = [SOURCE.replace(b"name: sdd-apply\n", b"name: sdd-apply\nname: sdd-apply\n"),
                 SOURCE.replace(b"Fixture agent.", b">\n  folded"),
                 SOURCE.replace(b"Fixture agent.", b'"quoted"'),
                 SOURCE.replace(b"Fixture agent.", b"nested: mapping"),
                 SOURCE.replace(b"Fixture agent.", b"Fixture # comment"),
                 SOURCE.replace(b"tools:\n", b"tools: [read, write]\n"),
                 SOURCE.replace(b"  - read", b"    - read"),
                 SOURCE.replace(b"sdd-apply", b"sdd-future"),
                 SOURCE.replace(b"sdd-apply", b"sdd-status"),
                 SOURCE.replace(b"description:", b"unknown:"),
                 SOURCE.replace(b"  - read", b"  - mcp"),
                 SOURCE.replace(b"---\n", b"", 1)]
        for source in cases:
            with self.subTest(source=source), self.assertRaises(AgentError):
                compose(source)

    def test_existing_or_malformed_managed_blocks_are_rejected(self):
        for source in (SOURCE + CG, SOURCE + MCP):
            with self.subTest(source=source), self.assertRaises(AgentError):
                compose(source)
        for block in (CG + CG, MCP, CG.replace(CLOSE, b""), b"prefix\n" + CG,
                      CG.replace(b"Fixture guidance.", MCP.rstrip(b"\n")), CG[:-1]):
            with self.subTest(block=block), self.assertRaises(AgentError):
                compose(guidance=block)

    def test_malformed_explicit_preferences_fail_with_agent_error(self):
        for options in ({"model": "x\ny", "thinking": "high"},
                        {"model": "x", "thinking": []},
                        {"model": "x", "thinking": "invented"},
                        {"role": None}, {"expected_source_tools": None}):
            with self.subTest(options=options), self.assertRaises(AgentError):
                compose(**options)

    def test_ambiguous_plain_scalars_are_rejected(self):
        for value in (b"- item", b"? key", b"Fixture\t# comment",
                      b"Fixture:\tvalue", b"Fixture:", b"@reserved"):
            with self.subTest(value=value), self.assertRaises(AgentError):
                compose(SOURCE.replace(b"Fixture agent.", value))
        with self.assertRaises(AgentError):
            compose(model="test:", thinking="high")

    def test_body_bytes_and_horizontal_rules_are_not_parsed_as_frontmatter(self):
        source = SOURCE + "\n---\nA Unicode separator: \u2028.\n\n".encode()
        self.assertEqual(compose(source), source + b"\n" + CG)

    def test_text_domain_is_checked_for_sources_and_blocks(self):
        for source in (SOURCE[:-1], SOURCE + b"\x00\n", SOURCE.replace(b"\n", b"\r\n"), b"\xff\n"):
            with self.subTest(source=source), self.assertRaises(AgentError):
                compose(source)
        with self.assertRaises(AgentError):
            compose(mcp=True, mcp_block=MCP + b"\x00\n")


if __name__ == "__main__":
    unittest.main()
