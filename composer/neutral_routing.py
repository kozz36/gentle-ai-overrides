"""Pure candidate transforms for Pi workflow and optional ODD forwarding."""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum

WORKFLOW_FORWARDING_RULE_VERSION = "workflow-forwarding/v1"
DELEGATION_FORWARDING_RULE_VERSION = "odd-delegation-forwarding/v1"

_WF_HEADING = b"## Strict TDD Forwarding"
_WF_ARCHIVE = b"## Archive Final-State Handoff"
_WF_BINARY = (b"For `sdd-apply` and `sdd-verify`, read `openspec/config.yaml` when present.\n\n"
              b"If it declares strict TDD and a test command, include a non-negotiable instruction in the phase prompt:\n\n"
              b"```text\nSTRICT TDD MODE IS ACTIVE. Test runner: <command>. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.\n```\n\n"
              b"Do not rely on the child agent to discover this independently.")
_WF_OPEN = b"<!-- gentle-ai:pi-rubric-forwarding -->"
_WF_CLOSE = b"<!-- /gentle-ai:pi-rubric-forwarding -->"
_ODD_HEADING = b"### Organic Driven Development (ODD)"
_ODD_CHECKS = b"#### Checks and candidate consent"
_ODD_DELEGATION = b"### Delegation Rules"
_ODD_OPEN = b"<!-- gentle-ai:pi-odd-forwarding -->"
_ODD_CLOSE = b"<!-- /gentle-ai:pi-odd-forwarding -->"


class NeutralRoutingError(ValueError):
    """The candidate source or explicit managed payload is unsupported."""


class DelegationState(Enum):
    ABSENT = "absent"
    NOT_APPLICABLE = "not-applicable"
    APPLICABLE = "applicable"


@dataclass(frozen=True)
class OptionalDelegationCandidate:
    state: DelegationState
    candidate: bytes | None


def _lines(value, label):
    if type(value) is not bytes:
        raise NeutralRoutingError(f"{label}: require immutable bytes")
    return value.splitlines(keepends=True)


def _bare(line):
    if line.endswith(b"\r\n"):
        return line[:-2]
    return line[:-1] if line.endswith(b"\n") else line


def _ending(line):
    return b"\r\n" if line.endswith(b"\r\n") else b"\n"


def _render(block, ending):
    return ending.join(block.split(b"\n")) + ending


def _region(lines, marker, opening, closing):
    malformed = any(marker in _bare(line) and _bare(line) not in (opening, closing) for line in lines)
    opens = [i for i, line in enumerate(lines) if _bare(line) == opening]
    closes = [i for i, line in enumerate(lines) if _bare(line) == closing]
    if malformed or len(opens) != len(closes) or len(opens) > 1:
        raise NeutralRoutingError("source: malformed managed region")
    return (opens[0], closes[0]) if opens else None


def _payload(value, marker, opening, closing, label):
    if type(value) is not bytes or value.endswith(b"\n") or b"\r" in value:
        raise NeutralRoutingError(f"{label}: require a non-terminated LF byte block")
    lines = _lines(value, label)
    region = _region(lines, marker, opening, closing)
    if region != (0, len(lines) - 1):
        raise NeutralRoutingError(f"{label}: require one complete managed region")
    return value


def _replace(lines, *, marker, opening, closing, current, predecessor, start, end, blank_gap):
    region = _region(lines, marker, opening, closing)
    if blank_gap:
        for i in range(start + 1, end):
            if region is not None and region[0] <= i <= region[1]:
                continue
            if _bare(lines[i]).strip(b" \t"):
                raise NeutralRoutingError("source: upstream gap must be blank")
    ending = _ending(lines[end])
    if region is None:
        lines[end:end] = [_render(current, ending), ending]
        return b"".join(lines)
    first, last = region
    if not (start < first < last < end):
        raise NeutralRoutingError("source: managed region is outside its allowed gap")
    managed = b"".join(lines[first:last + 1])
    if managed not in (_render(current, ending), _render(predecessor, ending)):
        raise NeutralRoutingError("source: managed region is not recognized")
    lines[first:last + 1] = [_render(current, ending)]
    return b"".join(lines)


def render_workflow_forwarding(source: bytes, current: bytes, predecessor: bytes) -> bytes:
    """Render a workflow candidate while preserving its verified upstream gap."""
    current = _payload(current, b"gentle-ai:pi-rubric-forwarding", _WF_OPEN, _WF_CLOSE, "current")
    predecessor = _payload(predecessor, b"gentle-ai:pi-rubric-forwarding", _WF_OPEN, _WF_CLOSE, "predecessor")
    lines = _lines(source, "source")
    headings = [i for i, line in enumerate(lines) if _bare(line) == _WF_HEADING]
    archives = [i for i, line in enumerate(lines) if _bare(line) == _WF_ARCHIVE]
    binary = _WF_BINARY.split(b"\n")
    matches = [i for i in range(len(lines) - len(binary) + 1)
               if [_bare(line) for line in lines[i:i + len(binary)]] == binary]
    if len(headings) != 1 or len(archives) != 1 or len(matches) != 1:
        raise NeutralRoutingError("source: require unique workflow anchors")
    start, end = matches[0] + len(binary) - 1, archives[0]
    if not (headings[0] < matches[0] and start < end):
        raise NeutralRoutingError("source: workflow anchors are out of order")
    return _replace(lines, marker=b"gentle-ai:pi-rubric-forwarding", opening=_WF_OPEN,
                    closing=_WF_CLOSE, current=current, predecessor=predecessor,
                    start=start, end=end, blank_gap=True)


def render_optional_odd_delegation(source: bytes | None, current: bytes,
                                    predecessor: bytes) -> OptionalDelegationCandidate:
    """Render optional delegation without manufacturing an absent target."""
    if source is None:
        return OptionalDelegationCandidate(DelegationState.ABSENT, None)
    current = _payload(current, b"gentle-ai:pi-odd-forwarding", _ODD_OPEN, _ODD_CLOSE, "current")
    predecessor = _payload(predecessor, b"gentle-ai:pi-odd-forwarding", _ODD_OPEN, _ODD_CLOSE, "predecessor")
    lines = _lines(source, "source")
    region = _region(lines, b"gentle-ai:pi-odd-forwarding", _ODD_OPEN, _ODD_CLOSE)
    headings = [i for i, line in enumerate(lines) if _bare(line) == _ODD_HEADING]
    if not headings and region is None:
        return OptionalDelegationCandidate(DelegationState.NOT_APPLICABLE, source)
    checks = [i for i, line in enumerate(lines) if _bare(line) == _ODD_CHECKS]
    delegations = [i for i, line in enumerate(lines) if _bare(line) == _ODD_DELEGATION]
    if len(headings) != 1 or len(checks) != 1 or len(delegations) != 1 or not (headings[0] < checks[0] < delegations[0]):
        raise NeutralRoutingError("source: require ordered ODD anchors")
    candidate = _replace(lines, marker=b"gentle-ai:pi-odd-forwarding", opening=_ODD_OPEN,
                         closing=_ODD_CLOSE, current=current, predecessor=predecessor,
                         start=checks[0], end=delegations[0], blank_gap=False)
    return OptionalDelegationCandidate(DelegationState.APPLICABLE, candidate)
