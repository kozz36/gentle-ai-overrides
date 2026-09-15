"""Pure, candidate-only Pi init renderer; no installer or filesystem access.

Rule pi-init-before-memory/v1 follows overlay v2.6.0-overlay.3's
init_rubric_transform. Accepted documents are UTF-8, LF-terminated, without
CR or NUL characters; managed markers occupy complete lines. Unsupported inputs
fail rather than being normalized. The payload includes its managed markers.
"""

RULE_VERSION = "pi-init-before-memory/v1"
OPEN = "<!-- gentle-ai:sdd-init-rubric -->"
CLOSE = "<!-- /gentle-ai:sdd-init-rubric -->"
ANCHOR = "## Memory Contract"


class RenderError(ValueError):
    """The supplied bytes do not satisfy this versioned rendering rule."""


def _lines(data, label):
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise RenderError(f"{label}: invalid UTF-8") from exc
    if not text.endswith("\n") or "\r" in text or "\x00" in text:
        raise RenderError(f"{label}: require LF-terminated text without CR or NUL")
    return text[:-1].split("\n")


def _region(lines):
    for line in lines:
        if any(token in line for token in (
            "<!-- gentle-ai:sdd-init-rubric", "<!-- /gentle-ai:sdd-init-rubric"
        )) and line not in (OPEN, CLOSE):
            raise RenderError("managed markers must occupy complete lines")
    opens = [i for i, line in enumerate(lines) if line == OPEN]
    closes = [i for i, line in enumerate(lines) if line == CLOSE]
    if len(opens) != len(closes) or len(opens) > 1:
        raise RenderError("require zero or one complete managed region")
    if not opens:
        return None
    if opens[0] >= closes[0]:
        raise RenderError("managed markers are out of order")
    return opens[0], closes[0]


def render_pi_init(source: bytes, payload: bytes) -> bytes:
    """Render the supplied block, preserving other bytes in accepted sources.

    Hash/provenance verification belongs to the future input-bundle layer.
    This function performs structural validation only and grants no authority.
    """
    lines = _lines(source, "source")
    block = _lines(payload, "payload")
    if _region(block) != (0, len(block) - 1) or ANCHOR in block:
        raise RenderError("payload must be exactly one block without the anchor")
    anchors = [i for i, line in enumerate(lines) if line == ANCHOR]
    if len(anchors) != 1:
        raise RenderError("require exactly one memory anchor")
    region = _region(lines)
    if region and region[0] < anchors[0] < region[1]:
        raise RenderError("memory anchor is inside the managed region")
    result = []
    for i, line in enumerate(lines):
        if line == ANCHOR:
            result.extend(block + [""])
        if region:
            start, end = region
            if start <= i <= end:
                continue
            # Only this separator belongs to the old generated block.
            if (i == end + 1 and not line.strip(" \t")
                    and i + 1 < len(lines) and lines[i + 1] == ANCHOR):
                continue
        result.append(line)
    return ("\n".join(result) + "\n").encode("utf-8")
