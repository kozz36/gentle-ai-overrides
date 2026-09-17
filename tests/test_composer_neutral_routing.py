"""Behavior contracts for pure workflow and optional ODD forwarding candidates."""
import builtins
import hashlib
import unittest
from unittest.mock import patch

from composer.neutral_routing import (
    DELEGATION_FORWARDING_RULE_VERSION,
    WORKFLOW_FORWARDING_RULE_VERSION,
    DelegationState,
    NeutralRoutingError,
    render_optional_odd_delegation,
    render_workflow_forwarding,
)

WF_HEADING = b"## Strict TDD Forwarding"
WF_ARCHIVE = b"## Archive Final-State Handoff"
WF_OPEN = b"<!-- gentle-ai:pi-rubric-forwarding -->"
WF_CLOSE = b"<!-- /gentle-ai:pi-rubric-forwarding -->"
BINARY = (b"For `sdd-apply` and `sdd-verify`, read `openspec/config.yaml` when present.\n\n"
          b"If it declares strict TDD and a test command, include a non-negotiable instruction in the phase prompt:\n\n"
          b"```text\nSTRICT TDD MODE IS ACTIVE. Test runner: <command>. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.\n```\n\n"
          b"Do not rely on the child agent to discover this independently.")
ODD_HEADING = b"### Organic Driven Development (ODD)"
ODD_CHECKS = b"#### Checks and candidate consent"
ODD_DELEGATION = b"### Delegation Rules"
ODD_OPEN = b"<!-- gentle-ai:pi-odd-forwarding -->"
ODD_CLOSE = b"<!-- /gentle-ai:pi-odd-forwarding -->"
CURRENT_WF = WF_OPEN + b"\nCurrent workflow.\n" + WF_CLOSE
PREVIOUS_WF = WF_OPEN + b"\nPrevious workflow.\n" + WF_CLOSE
CURRENT_ODD = ODD_OPEN + b"\nCurrent delegation.\n" + ODD_CLOSE
PREVIOUS_ODD = ODD_OPEN + b"\nPrevious delegation.\n" + ODD_CLOSE


def ended(block, ending=b"\n"):
    return ending.join(block.split(b"\n")) + ending


def workflow(gap=b"", ending=b"\n"):
    return b"Header" + ending + WF_HEADING + ending + ended(BINARY, ending) + gap + WF_ARCHIVE + ending + b"Tail" + ending


def unterminated_workflow_archive(ending=b"\n"):
    return b"Header" + ending + WF_HEADING + ending + ended(BINARY, ending) + WF_ARCHIVE


def delegation(gap=b"", ending=b"\n"):
    return b"Header" + ending + ODD_HEADING + ending + ODD_CHECKS + ending + gap + ODD_DELEGATION + ending + b"Tail" + ending


class WorkflowForwardingTests(unittest.TestCase):
    def test_inserts_at_archive_without_rewriting_blank_upstream_gap(self):
        source = workflow(b" \t\n\n")
        expected = source.replace(WF_ARCHIVE, ended(CURRENT_WF) + b"\n" + WF_ARCHIVE, 1)
        self.assertEqual(render_workflow_forwarding(source, CURRENT_WF, PREVIOUS_WF), expected)

    def test_crlf_terminated_archive_renders_and_refreshes_every_managed_line_as_crlf(self):
        source = workflow(b" \t\r\n", b"\r\n")
        expected = source.replace(WF_ARCHIVE, ended(CURRENT_WF, b"\r\n") + b"\r\n" + WF_ARCHIVE, 1)
        once = render_workflow_forwarding(source, CURRENT_WF, PREVIOUS_WF)
        self.assertEqual(once, expected)
        upgraded = workflow(ended(PREVIOUS_WF, b"\r\n") + b"\r\n", b"\r\n")
        self.assertEqual(render_workflow_forwarding(upgraded, CURRENT_WF, PREVIOUS_WF),
                         workflow(ended(CURRENT_WF, b"\r\n") + b"\r\n", b"\r\n"))
        self.assertEqual(render_workflow_forwarding(once, CURRENT_WF, PREVIOUS_WF), once)

    def test_lf_predecessor_refreshes_and_current_is_idempotent(self):
        source = workflow(ended(PREVIOUS_WF) + b"\n")
        expected = workflow(ended(CURRENT_WF) + b"\n")
        once = render_workflow_forwarding(source, CURRENT_WF, PREVIOUS_WF)
        self.assertEqual(once, expected)
        self.assertEqual(render_workflow_forwarding(once, CURRENT_WF, PREVIOUS_WF), expected)

    def test_unterminated_archive_uses_reviewed_lf_fallback(self):
        source = unterminated_workflow_archive(b"\r\n")
        expected = source.replace(WF_ARCHIVE, ended(CURRENT_WF) + b"\n" + WF_ARCHIVE)
        self.assertEqual(render_workflow_forwarding(source, CURRENT_WF, PREVIOUS_WF), expected)

    def test_refuses_missing_duplicate_reordered_gap_and_managed_drift(self):
        good = workflow()
        cases = (
            good.replace(WF_HEADING, b"## Other", 1), good + WF_HEADING + b"\n",
            good.replace(BINARY, b"Missing", 1), good.replace(BINARY, BINARY + b"\n" + BINARY, 1),
            good.replace(WF_ARCHIVE, b"## Other", 1), good.replace(WF_ARCHIVE, WF_ARCHIVE + b"\n" + WF_ARCHIVE, 1),
            WF_ARCHIVE + b"\n" + WF_HEADING + b"\n" + BINARY,
            workflow(b"upstream bytes\n"), workflow(ended(CURRENT_WF) + b"\n" + ended(CURRENT_WF) + b"\n"),
            workflow(ended(CURRENT_WF.replace(b"Current", b"Custom")) + b"\n"),
            workflow(b"prefix " + WF_OPEN + b"\n"), workflow(WF_CLOSE + b"\n"),
            workflow(WF_CLOSE + b"\n" + WF_OPEN + b"\n"),
            workflow(WF_OPEN + b"\r\nCurrent workflow.\n" + WF_CLOSE + b"\r\n\n"),
        )
        for source in cases:
            with self.subTest(source=source), self.assertRaises(NeutralRoutingError):
                render_workflow_forwarding(source, CURRENT_WF, PREVIOUS_WF)


class OptionalDelegationForwardingTests(unittest.TestCase):
    def test_absent_and_not_applicable_are_explicit_no_file_states(self):
        absent = render_optional_odd_delegation(None, CURRENT_ODD, PREVIOUS_ODD)
        self.assertEqual((absent.state, absent.candidate), (DelegationState.ABSENT, None))
        source = b"Old package\n" + ODD_CHECKS + b"\n" + ODD_DELEGATION + b"\n"
        result = render_optional_odd_delegation(source, CURRENT_ODD, PREVIOUS_ODD)
        self.assertEqual((result.state, result.candidate), (DelegationState.NOT_APPLICABLE, source))

    def test_lf_and_crlf_insert_refresh_idempotence_and_separator_preservation(self):
        for ending in (b"\n", b"\r\n"):
            with self.subTest(ending=ending):
                source = delegation(b"Native paragraph." + ending, ending)
                expected = delegation(b"Native paragraph." + ending + ended(CURRENT_ODD, ending) + ending, ending)
                result = render_optional_odd_delegation(source, CURRENT_ODD, PREVIOUS_ODD)
                self.assertEqual((result.state, result.candidate), (DelegationState.APPLICABLE, expected))
                self.assertEqual(render_optional_odd_delegation(result.candidate, CURRENT_ODD, PREVIOUS_ODD).candidate, expected)
                upgraded = delegation(ended(PREVIOUS_ODD, ending) + ending, ending)
                self.assertEqual(render_optional_odd_delegation(upgraded, CURRENT_ODD, PREVIOUS_ODD).candidate,
                                 delegation(ended(CURRENT_ODD, ending) + ending, ending))

    def test_unterminated_delegation_anchor_uses_lf_fallback_without_rewriting_anchor(self):
        source = b"Header\r\n" + ODD_HEADING + b"\r\n" + ODD_CHECKS + b"\r\n" + ODD_DELEGATION
        expected = source.replace(ODD_DELEGATION, ended(CURRENT_ODD) + b"\n" + ODD_DELEGATION)
        result = render_optional_odd_delegation(source, CURRENT_ODD, PREVIOUS_ODD)
        self.assertEqual((result.state, result.candidate), (DelegationState.APPLICABLE, expected))

    def test_refuses_missing_duplicate_reordered_and_malformed_odd_shapes(self):
        good = delegation()
        cases = (
            good + ODD_HEADING + b"\n",
            good.replace(ODD_CHECKS, b"#### Other", 1), good.replace(ODD_DELEGATION, b"### Other", 1),
            good + ODD_CHECKS + b"\n", good + ODD_DELEGATION + b"\n",
            good.replace(ODD_DELEGATION, ODD_CHECKS, 1),
            ODD_HEADING + b"\n" + ODD_DELEGATION + b"\n" + ODD_CHECKS + b"\n",
            delegation(ODD_OPEN + b"\n"), delegation(ODD_CLOSE + b"\n"),
            delegation(ODD_CLOSE + b"\n" + ODD_OPEN + b"\n"),
            delegation(ended(CURRENT_ODD) + b"\n" + ended(CURRENT_ODD) + b"\n"),
            delegation(ended(CURRENT_ODD.replace(b"Current", b"Custom")) + b"\n"),
            ODD_HEADING + b"\n" + ODD_CHECKS + b"\n" + ODD_DELEGATION + b"\n" + ended(CURRENT_ODD),
            delegation(b"prefix " + ODD_OPEN + b"\n"),
            delegation(ODD_OPEN + b"\r\nCurrent delegation.\n" + ODD_CLOSE + b"\r\n\n"),
        )
        for source in cases:
            with self.subTest(source=source), self.assertRaises(NeutralRoutingError):
                render_optional_odd_delegation(source, CURRENT_ODD, PREVIOUS_ODD)


class PureRoutingTests(unittest.TestCase):
    def test_rules_inputs_payload_validation_and_filesystem_boundary_are_explicit(self):
        self.assertEqual(WORKFLOW_FORWARDING_RULE_VERSION, "workflow-forwarding/v1")
        self.assertEqual(DELEGATION_FORWARDING_RULE_VERSION, "odd-delegation-forwarding/v1")
        source, odd_source = workflow(), delegation()
        inputs = (source, odd_source, CURRENT_WF, PREVIOUS_WF, CURRENT_ODD, PREVIOUS_ODD)
        before = tuple(hashlib.sha256(value).digest() for value in inputs)
        with patch.object(builtins, "open", side_effect=AssertionError("filesystem access")):
            render_workflow_forwarding(source, CURRENT_WF, PREVIOUS_WF)
            render_optional_odd_delegation(odd_source, CURRENT_ODD, PREVIOUS_ODD)
        self.assertEqual(tuple(hashlib.sha256(value).digest() for value in inputs), before)
        invalid_sources = (bytearray(source),)
        invalid_payloads = (bytearray(CURRENT_WF), CURRENT_WF + b"\n", WF_OPEN + b"\n",
                            WF_OPEN + b"\nBody\n<!-- /gentle-ai:pi-rubric-forwarding:custom -->")
        for candidate in invalid_sources:
            with self.subTest(source=candidate), self.assertRaises(NeutralRoutingError):
                render_workflow_forwarding(candidate, CURRENT_WF, PREVIOUS_WF)
        for candidate in invalid_payloads:
            with self.subTest(payload=candidate), self.assertRaises(NeutralRoutingError):
                render_workflow_forwarding(source, candidate, PREVIOUS_WF)
        with self.assertRaises(NeutralRoutingError):
            render_workflow_forwarding(source, CURRENT_WF, bytearray(PREVIOUS_WF))
        odd_invalid = (bytearray(CURRENT_ODD), CURRENT_ODD + b"\n", ODD_OPEN + b"\n",
                       ODD_OPEN + b"\nBody\n<!-- /gentle-ai:pi-odd-forwarding:custom -->")
        for candidate in odd_invalid:
            with self.subTest(odd_payload=candidate), self.assertRaises(NeutralRoutingError):
                render_optional_odd_delegation(odd_source, candidate, PREVIOUS_ODD)
        for candidate in (bytearray(PREVIOUS_ODD), PREVIOUS_ODD + b"\n"):
            with self.subTest(odd_predecessor=candidate), self.assertRaises(NeutralRoutingError):
                render_optional_odd_delegation(odd_source, CURRENT_ODD, candidate)


if __name__ == "__main__":
    unittest.main()
