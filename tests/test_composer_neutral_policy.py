"""Behavior contracts for v1 candidate-only neutral policy transforms."""
import builtins
import hashlib
import unittest
from unittest.mock import patch

from composer.neutral_policy import (
    GENTLE_INIT_RULE_VERSION,
    LEGACY_SDD_INIT_RETIRE_RULE_VERSION,
    NeutralPolicyError,
    render_gentle_init_rubric,
    retire_legacy_sdd_init_rubric,
)

GENTLE_OPEN = b"<!-- gentle-ai:gentle-init-rubric -->"
GENTLE_CLOSE = b"<!-- /gentle-ai:gentle-init-rubric -->"
LEGACY_OPEN = b"<!-- gentle-ai:sdd-init-rubric -->"
LEGACY_CLOSE = b"<!-- /gentle-ai:sdd-init-rubric -->"
PUBLICATION = b"## Publication boundary"
MEMORY = b"## Memory Contract"
GENTLE_PAYLOAD = GENTLE_OPEN + b"\nNeutral contract.\n" + GENTLE_CLOSE
LEGACY_PAYLOAD = LEGACY_OPEN + b"\nLegacy contract.\n" + LEGACY_CLOSE


class GentleInitTransformTests(unittest.TestCase):
    def test_inserts_exact_payload_immediately_before_unique_publication_boundary(self):
        source = b"Header\n\n" + PUBLICATION + b"\nTail\n"
        expected = b"Header\n\n" + GENTLE_PAYLOAD + b"\n" + PUBLICATION + b"\nTail\n"
        self.assertEqual(render_gentle_init_rubric(source, GENTLE_PAYLOAD), expected)

    def test_rejects_a_different_complete_region(self):
        source = GENTLE_PAYLOAD + b"\n" + PUBLICATION + b"\nTail"
        replacement = GENTLE_PAYLOAD.replace(b"Neutral", b"Updated")
        with self.assertRaises(NeutralPolicyError):
            render_gentle_init_rubric(source, replacement)

    def test_crlf_anchor_appends_its_ending_to_the_explicit_lf_payload(self):
        source = b"Header\r\n" + PUBLICATION + b"\r\nTail\r\n"
        expected = (b"Header\r\n<!-- gentle-ai:gentle-init-rubric -->\n"
                    b"Neutral contract.\n<!-- /gentle-ai:gentle-init-rubric -->\r\n"
                    b"## Publication boundary\r\nTail\r\n")
        once = render_gentle_init_rubric(source, GENTLE_PAYLOAD)
        self.assertEqual(once, expected)
        self.assertEqual(render_gentle_init_rubric(once, GENTLE_PAYLOAD), expected)

    def test_similar_non_rubric_text_is_preserved(self):
        source = b"Header\ngentle-ai:gentle-init-other\n" + PUBLICATION
        expected = b"Header\ngentle-ai:gentle-init-other\n" + GENTLE_PAYLOAD + b"\n" + PUBLICATION
        self.assertEqual(render_gentle_init_rubric(source, GENTLE_PAYLOAD), expected)

    def test_current_payload_is_idempotent_and_preserves_no_terminal_lf(self):
        source = b"Header\n" + PUBLICATION
        once = render_gentle_init_rubric(source, GENTLE_PAYLOAD)
        self.assertEqual(once, b"Header\n" + GENTLE_PAYLOAD + b"\n" + PUBLICATION)
        self.assertEqual(render_gentle_init_rubric(once, GENTLE_PAYLOAD), once)

    def test_rejects_invalid_or_ambiguous_gentle_sources(self):
        customized = GENTLE_OPEN + b"\nCustomized.\n" + GENTLE_CLOSE + b"\n" + PUBLICATION
        cases = (
            b"\xff\n" + PUBLICATION,
            b"Header\r" + PUBLICATION,
            b"Header\x00\n" + PUBLICATION,
            b"No publication boundary\n",
            PUBLICATION + b"\n" + PUBLICATION,
            GENTLE_OPEN + b"\n" + PUBLICATION,
            GENTLE_CLOSE + b"\n" + PUBLICATION,
            GENTLE_CLOSE + b"\n" + GENTLE_OPEN + b"\n" + PUBLICATION,
            GENTLE_PAYLOAD + b"\n" + GENTLE_PAYLOAD + b"\n" + PUBLICATION,
            GENTLE_PAYLOAD + b"\nUnowned\n" + PUBLICATION,
            customized,
            LEGACY_OPEN + b"\nLegacy.\n" + LEGACY_CLOSE + b"\n" + PUBLICATION,
            b"prefix " + GENTLE_OPEN + b"\n" + PUBLICATION,
        )
        for source in cases:
            with self.subTest(source=source), self.assertRaises(NeutralPolicyError):
                render_gentle_init_rubric(source, GENTLE_PAYLOAD)

    def test_rejects_malformed_or_noncanonical_payload(self):
        cases = (
            b"",
            GENTLE_PAYLOAD + b"\n",
            b"Prefix\n" + GENTLE_PAYLOAD,
            GENTLE_PAYLOAD + b"\nTail",
            GENTLE_OPEN + b"\n" + PUBLICATION + b"\n" + GENTLE_CLOSE,
            LEGACY_PAYLOAD,
            b"\xff",
        )
        for payload in cases:
            with self.subTest(payload=payload), self.assertRaises(NeutralPolicyError):
                render_gentle_init_rubric(PUBLICATION, payload)


class LegacySddInitRetirementTests(unittest.TestCase):
    def test_retires_only_exact_payload_and_owned_separator(self):
        source = b"Header\n" + LEGACY_PAYLOAD + b"\n\n" + MEMORY + b"\nTail"
        expected = b"Header\n" + MEMORY + b"\nTail"
        self.assertEqual(retire_legacy_sdd_init_rubric(source, LEGACY_PAYLOAD), expected)

    def test_clean_legacy_source_is_idempotent(self):
        source = b"Header\n\n" + MEMORY
        self.assertEqual(retire_legacy_sdd_init_rubric(source, LEGACY_PAYLOAD), source)

    def test_crlf_retirement_preserves_the_remaining_bytes(self):
        source = (b"Header\r\n<!-- gentle-ai:sdd-init-rubric -->\r\nLegacy contract.\r\n"
                  b"<!-- /gentle-ai:sdd-init-rubric -->\r\n\r\n## Memory Contract\r\nTail")
        expected = b"Header\r\n## Memory Contract\r\nTail"
        self.assertEqual(retire_legacy_sdd_init_rubric(source, LEGACY_PAYLOAD), expected)

    def test_similar_non_rubric_text_is_preserved(self):
        source = b"Header\ngentle-ai:sdd-init-other\n" + MEMORY
        self.assertEqual(retire_legacy_sdd_init_rubric(source, LEGACY_PAYLOAD), source)

    def test_rejects_legacy_regions_that_are_not_exactly_owned(self):
        cases = (
            LEGACY_OPEN + b"\nCustomized.\n" + LEGACY_CLOSE + b"\n\n" + MEMORY,
            LEGACY_PAYLOAD + b"\n \n" + MEMORY,
            LEGACY_PAYLOAD + b"\n\n" + b"## Other boundary",
            LEGACY_PAYLOAD + b"\n\n" + MEMORY + b"\n" + LEGACY_PAYLOAD + b"\n\n" + MEMORY,
            LEGACY_OPEN + b"\n" + MEMORY,
            LEGACY_CLOSE + b"\n" + MEMORY,
            b"prefix " + LEGACY_OPEN + b"\n" + MEMORY,
            LEGACY_CLOSE + b"\n" + LEGACY_OPEN + b"\n\n" + MEMORY,
            b"\xff\n" + MEMORY,
            b"Header\r" + MEMORY,
            b"Header\x00\n" + MEMORY,
        )
        for source in cases:
            with self.subTest(source=source), self.assertRaises(NeutralPolicyError):
                retire_legacy_sdd_init_rubric(source, LEGACY_PAYLOAD)

    def test_rejects_noncanonical_predecessors(self):
        for predecessor in (b"", LEGACY_PAYLOAD + b"\n", b"Prefix\n" + LEGACY_PAYLOAD,
                            GENTLE_PAYLOAD, b"\xff"):
            with self.subTest(predecessor=predecessor), self.assertRaises(NeutralPolicyError):
                retire_legacy_sdd_init_rubric(MEMORY, predecessor)


class PureTransformTests(unittest.TestCase):
    def test_rules_are_explicit_versioned_constants(self):
        self.assertEqual(GENTLE_INIT_RULE_VERSION, "neutral-gentle-init-rubric/v1")
        self.assertEqual(LEGACY_SDD_INIT_RETIRE_RULE_VERSION, "retire-sdd-init-rubric/v1")

    def test_inputs_are_not_mutated_and_no_filesystem_is_accessed(self):
        source = b"Header\n" + PUBLICATION
        payload = GENTLE_PAYLOAD
        legacy_source = LEGACY_PAYLOAD + b"\n\n" + MEMORY
        before = tuple(hashlib.sha256(value).digest() for value in (source, payload, legacy_source))
        with patch.object(builtins, "open", side_effect=AssertionError("filesystem access")):
            result = render_gentle_init_rubric(source, payload)
            retired = retire_legacy_sdd_init_rubric(legacy_source, LEGACY_PAYLOAD)
        self.assertEqual(tuple(hashlib.sha256(value).digest() for value in (source, payload, legacy_source)), before)
        self.assertEqual(result, b"Header\n" + payload + b"\n" + PUBLICATION)
        self.assertEqual(retired, MEMORY)

    def test_requires_explicit_immutable_byte_inputs(self):
        with self.assertRaises(NeutralPolicyError):
            render_gentle_init_rubric(bytearray(PUBLICATION), GENTLE_PAYLOAD)
        with self.assertRaises(NeutralPolicyError):
            retire_legacy_sdd_init_rubric(MEMORY, bytearray(LEGACY_PAYLOAD))


if __name__ == "__main__":
    unittest.main()
