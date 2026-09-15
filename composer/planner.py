"""Pure B/I/N planning over explicit observations, not native authority.

An observation supplies a lowercase SHA-256, declared observed ownership, and
an explicit tool list (None for chains). Collecting/validating snapshot evidence
belongs to the input layer. No result authorizes installation or adoption.
"""
import re

PLAN_VERSION = "asset-change-plan/v1"
DIGEST = re.compile(r"[0-9a-f]{64}\Z")
OWNERS = {"user-owned", "managed", "unknown"}


class PlanError(ValueError):
    """An observation is incomplete or structurally unsupported."""


def _validate(value, *, observed):
    required = {"sha256", "tools"} | ({"ownership"} if observed else set())
    if not isinstance(value, dict) or set(value) != required:
        raise PlanError("unsupported observation fields")
    digest = value["sha256"]
    if not isinstance(digest, str) or not DIGEST.fullmatch(digest):
        raise PlanError("require a lowercase SHA-256")
    tools = value["tools"]
    if tools is not None and (not isinstance(tools, list) or not tools
                             or any(not isinstance(tool, str) or not tool for tool in tools)
                             or len(tools) != len(set(tools))):
        raise PlanError("require a unique nonempty tool list or explicit None")
    if observed and (not isinstance(value["ownership"], str) or value["ownership"] not in OWNERS):
        raise PlanError("unsupported observed ownership")


def plan_asset(target: str, baseline, installed, desired) -> dict:
    """Return noop/propose/blocked, preserving the hashes behind the decision.

    Hash equality never repairs ownership. Ownership/tool-contract conflicts
    take precedence over byte equality, so already-matching bytes cannot hide
    a known authority change. Missing observations are represented by None.
    """
    if not isinstance(target, str) or not target:
        raise PlanError("require a target identifier")
    _validate(desired, observed=False)
    for observed in (baseline, installed):
        if observed is not None:
            _validate(observed, observed=True)
    row = {
        "target": target,
        "baseline_sha256": baseline["sha256"] if baseline else None,
        "installed_sha256": installed["sha256"] if installed else None,
        "desired_sha256": desired["sha256"],
        "baseline_ownership": baseline["ownership"] if baseline else None,
        "installed_ownership": installed["ownership"] if installed else None,
    }
    action, reason = "blocked", "local_drift"
    if installed is None:
        reason = "missing_installed_target"
    elif installed["ownership"] != "user-owned":
        reason = "unsupported_ownership"
    elif baseline is not None and baseline["ownership"] != installed["ownership"]:
        reason = "ownership_changed"
    elif installed["tools"] != desired["tools"] or (
        baseline is not None and baseline["tools"] != desired["tools"]
    ):
        reason = "tool_contract_changed"
    elif installed["sha256"] == desired["sha256"]:
        action, reason = "noop", "already_matches"
    elif baseline is None:
        reason = "baseline_required"
    elif installed["sha256"] == baseline["sha256"]:
        action, reason = "propose", "baseline_matches"
    row.update(action=action, reason=reason)
    return row
