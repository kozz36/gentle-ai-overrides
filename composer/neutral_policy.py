"""Pure, candidate-only transforms for the two neutral Pi agent surfaces.

The caller supplies every byte used for recognition or rendering.  These rules read
no package state and grant no authority to apply their candidates.
"""

GENTLE_INIT_RULE_VERSION = "neutral-gentle-init-rubric/v1"
LEGACY_SDD_INIT_RETIRE_RULE_VERSION = "retire-sdd-init-rubric/v1"

_GENTLE_OPEN = b"<!-- gentle-ai:gentle-init-rubric -->"
_GENTLE_CLOSE = b"<!-- /gentle-ai:gentle-init-rubric -->"
_LEGACY_OPEN = b"<!-- gentle-ai:sdd-init-rubric -->"
_LEGACY_CLOSE = b"<!-- /gentle-ai:sdd-init-rubric -->"
_GENTLE_MARKER = b"gentle-ai:gentle-init-rubric"
_LEGACY_MARKER = b"gentle-ai:sdd-init-rubric"
_PUBLICATION_BOUNDARY = b"## Publication boundary"
_MEMORY_CONTRACT = b"## Memory Contract"


class NeutralPolicyError(ValueError):
    """The explicit source or rule payload is unsupported."""


def _lines(value, label):
    if type(value) is not bytes:
        raise NeutralPolicyError(f"{label}: require immutable bytes")
    try:
        value.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise NeutralPolicyError(f"{label}: invalid UTF-8") from exc
    if b"\x00" in value or b"\r" in value.replace(b"\r\n", b""):
        raise NeutralPolicyError(f"{label}: bare CR and NUL are unsupported")
    return value.splitlines(keepends=True)


def _bare(line):
    if line.endswith(b"\r\n"):
        return line[:-2]
    return line[:-1] if line.endswith(b"\n") else line


def _ending(line):
    return b"\r\n" if line.endswith(b"\r\n") else b"\n"


def _render(block, ending):
    return ending.join(block.split(b"\n")) + ending


def _region(lines, *, marker, opening, closing, label):
    for line in lines:
        bare = _bare(line)
        if marker in bare and bare not in (opening, closing):
            raise NeutralPolicyError(f"{label}: malformed managed marker")
    opens = [index for index, line in enumerate(lines) if _bare(line) == opening]
    closes = [index for index, line in enumerate(lines) if _bare(line) == closing]
    if len(opens) != len(closes) or len(opens) > 1:
        raise NeutralPolicyError(f"{label}: require zero or one complete region")
    if not opens:
        return None
    if opens[0] >= closes[0]:
        raise NeutralPolicyError(f"{label}: managed markers are out of order")
    return opens[0], closes[0]


def _payload(value, *, marker, opening, closing, label, forbidden_anchor=None):
    if type(value) is not bytes or value.endswith(b"\n") or b"\r" in value:
        raise NeutralPolicyError(f"{label}: require a non-terminated LF byte block")
    lines = _lines(value, label)
    if _region(lines, marker=marker, opening=opening, closing=closing, label=label) != (0, len(lines) - 1):
        raise NeutralPolicyError(f"{label}: require exactly one complete managed region")
    if forbidden_anchor is not None and any(_bare(line) == forbidden_anchor for line in lines):
        raise NeutralPolicyError(f"{label}: managed block must not contain boundary")
    return value


def render_gentle_init_rubric(source: bytes, payload: bytes) -> bytes:
    """Insert or recognize one exact neutral block before Publication boundary.

    This is ``pi_byte_transform gentle`` expressed without environment or file
    access.  A pre-existing complete block must be byte-exact for the supplied
    payload and immediately precede the unique anchor.
    """
    block = _payload(payload, marker=_GENTLE_MARKER, opening=_GENTLE_OPEN,
                     closing=_GENTLE_CLOSE, label="payload",
                     forbidden_anchor=_PUBLICATION_BOUNDARY)
    lines = _lines(source, "source")
    anchors = [index for index, line in enumerate(lines) if _bare(line) == _PUBLICATION_BOUNDARY]
    if len(anchors) != 1:
        raise NeutralPolicyError("source: require one publication boundary")
    legacy = _region(lines, marker=_LEGACY_MARKER, opening=_LEGACY_OPEN,
                     closing=_LEGACY_CLOSE, label="source")
    if legacy is not None:
        raise NeutralPolicyError("source: legacy markers are unsupported")
    region = _region(lines, marker=_GENTLE_MARKER, opening=_GENTLE_OPEN,
                     closing=_GENTLE_CLOSE, label="source")
    anchor = anchors[0]
    ending = _ending(lines[anchor])
    if region is None:
        result = list(lines)
        result[anchor:anchor] = [block + ending]
        return b"".join(result)
    start, end = region
    if start >= anchor or end + 1 != anchor:
        raise NeutralPolicyError("source: managed region is not immediately before boundary")
    if b"".join(lines[start:end + 1]) != block + ending:
        raise NeutralPolicyError("source: managed region does not match payload")
    return source


def retire_legacy_sdd_init_rubric(source: bytes, predecessor: bytes) -> bytes:
    """Remove only one exact legacy block and its one owned LF separator.

    A marker-free source is already retired and is returned byte-identically.  A
    legacy region must equal the supplied predecessor and immediately precede the
    exact owned separator plus Memory Contract anchor.
    """
    block = _payload(predecessor, marker=_LEGACY_MARKER, opening=_LEGACY_OPEN,
                     closing=_LEGACY_CLOSE, label="predecessor")
    lines = _lines(source, "source")
    region = _region(lines, marker=_LEGACY_MARKER, opening=_LEGACY_OPEN,
                     closing=_LEGACY_CLOSE, label="source")
    if region is None:
        return source
    start, end = region
    ending = _ending(lines[start])
    if b"".join(lines[start:end + 1]) != _render(block, ending):
        raise NeutralPolicyError("source: legacy region does not match predecessor")
    separator = end + 1
    if (separator + 1 >= len(lines) or lines[separator] != ending
            or _bare(lines[separator + 1]) != _MEMORY_CONTRACT):
        raise NeutralPolicyError("source: legacy separator is not exclusively owned")
    result = list(lines)
    del result[start:separator + 1]
    return b"".join(result)
