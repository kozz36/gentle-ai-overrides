"""Synthetic contract cases plus the pinned public differential oracle."""
import hashlib
import os
from pathlib import Path
import subprocess
import unittest

from composer.overlay import RenderError, render_pi_init

OPEN = b"<!-- gentle-ai:sdd-init-rubric -->"
CLOSE = b"<!-- /gentle-ai:sdd-init-rubric -->"
ANCHOR = b"## Memory Contract"
PAYLOAD = OPEN + b"\nSynthetic policy fixture.\n" + CLOSE + b"\n"
FIXTURE = Path(__file__).parent / "fixtures/deterministic-asset-composer/pi-init-transform-v1.sh"
FIXTURE_SHA = "9cde962f9ddfe073b7176258f103bdd57b6086c2fbdf083a340ec4bb60a4915d"


def oracle(source):
    env = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "LC_ALL": "C",
        "INIT_RUBRIC_PI": PAYLOAD.decode().rstrip("\n"),
        "INIT_RUBRIC_OPEN": OPEN.decode(),
        "INIT_RUBRIC_CLOSE": CLOSE.decode(),
    }
    return subprocess.run(
        ["bash", "-c", 'source "$1"; init_rubric_transform pi', "oracle", str(FIXTURE)],
        input=source, capture_output=True, env=env, timeout=5,
    )


class PiInitRendererTests(unittest.TestCase):
    def test_inserts_payload_before_memory_without_changing_other_bytes(self):
        source = b"Header\n\n" + ANCHOR + b"\nKeep this body.\n"
        expected = b"Header\n\n" + PAYLOAD + b"\n" + ANCHOR + b"\nKeep this body.\n"
        self.assertEqual(render_pi_init(source, PAYLOAD), expected)

    def test_public_oracle_is_pinned(self):
        self.assertEqual(hashlib.sha256(FIXTURE.read_bytes()).hexdigest(), FIXTURE_SHA)

    def test_public_oracle_parity_for_valid_layouts(self):
        old = OPEN + b"\nOld policy.\n" + CLOSE + b"\n"
        cases = [
            ANCHOR + b"\n",
            b"Header\n\n" + ANCHOR + b"\nTail\n\n",
            old + b"\n" + ANCHOR + b"\nTail\n",
            old + b" \t\n" + ANCHOR + b"\n",
            old + b"\n\n" + ANCHOR + b"\n",
            old + b"\nUnrelated\n\n" + ANCHOR + b"\n",
            ANCHOR + b"\nTail\n" + old + b"\nKeep\n",
            "é\u2028separator\n".encode() + ANCHOR + b"\n",
        ]
        for source in cases:
            with self.subTest(source=source):
                expected = oracle(source)
                self.assertEqual(expected.returncode, 0, expected.stderr)
                self.assertEqual(render_pi_init(source, PAYLOAD), expected.stdout)

    def test_rerender_is_byte_identical_for_canonical_position(self):
        source = b"Header\n\n" + ANCHOR + b"\nTail\n"
        once = render_pi_init(source, PAYLOAD)
        self.assertEqual(render_pi_init(once, PAYLOAD), once)

    def test_replaces_payload_without_accumulation(self):
        source = render_pi_init(ANCHOR + b"\n", PAYLOAD)
        replacement = PAYLOAD.replace(b"Synthetic", b"Replacement")
        result = render_pi_init(source, replacement)
        self.assertEqual(result, replacement + b"\n" + ANCHOR + b"\n")
        self.assertEqual(result.count(OPEN), 1)

    def test_does_not_remove_unowned_blank_lines(self):
        source = PAYLOAD + b"\n\n" + ANCHOR + b"\n"
        self.assertEqual(render_pi_init(source, PAYLOAD), b"\n\n" + PAYLOAD + b"\n" + ANCHOR + b"\n")

    def test_bad_source_structure_matches_oracle_rejections(self):
        cases = [
            b"No anchor\n",
            ANCHOR + b"\n" + ANCHOR + b"\n",
            OPEN + b"\n" + ANCHOR + b"\n",
            CLOSE + b"\n" + ANCHOR + b"\n",
            CLOSE + b"\n" + OPEN + b"\n" + ANCHOR + b"\n",
            PAYLOAD + PAYLOAD + ANCHOR + b"\n",
            OPEN + b"\n" + ANCHOR + b"\n" + CLOSE + b"\n",
        ]
        for source in cases:
            with self.subTest(source=source):
                self.assertNotEqual(oracle(source).returncode, 0)
                with self.assertRaises(RenderError):
                    render_pi_init(source, PAYLOAD)

    def test_rejects_partial_or_non_line_markers(self):
        for marker in (OPEN[:-3], b"prefix " + OPEN, CLOSE + b" suffix"):
            with self.subTest(marker=marker), self.assertRaises(RenderError):
                render_pi_init(marker + b"\n" + ANCHOR + b"\n", PAYLOAD)

    def test_rejects_unsupported_payloads(self):
        cases = [b"", b"Unmanaged\n", PAYLOAD + PAYLOAD, b"prefix\n" + PAYLOAD,
                 PAYLOAD + b"tail\n", OPEN + b"\n" + ANCHOR + b"\n" + CLOSE + b"\n"]
        for payload in cases:
            with self.subTest(payload=payload), self.assertRaises(RenderError):
                render_pi_init(ANCHOR + b"\n", payload)

    def test_rejects_unsupported_text_in_either_input(self):
        for bad in (b"\xff\n", b"x\r\n", b"unterminated", b"x\x00\n"):
            with self.subTest(bad=bad):
                with self.assertRaises(RenderError):
                    render_pi_init(bad + ANCHOR + b"\n" if bad.endswith(b"\n") else bad, PAYLOAD)
                with self.assertRaises(RenderError):
                    render_pi_init(ANCHOR + b"\n", OPEN + b"\n" + bad + CLOSE + b"\n")


if __name__ == "__main__":
    unittest.main()
