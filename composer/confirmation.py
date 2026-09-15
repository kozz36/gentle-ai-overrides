"""Pure preparation of a composer component preview, never write authority."""
from dataclasses import dataclass
import hashlib
import json
import re

from .agents import _header, _text
from .bundle import AGENT_RULE, INIT_RULE, SCHEMA, TARGETS, _pin, require_keys
from .package_claims import serialize_package_claim_evidence
from .planner import PLAN_VERSION, _validate, plan_asset
from .preparation import PackageClaimPreparation
from .snapshot import CapturedSnapshot
from .storage import MAX_BYTES


class ConfirmationError(ValueError):
    """The supplied display plan does not match its supplied evidence."""


def _canonical_json(value, *, ensure_ascii=False):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=ensure_ascii,
                      allow_nan=False).encode("utf-8")


def _validated_package_claim_evidence(preparation, installed_entries):
    if type(preparation) is not PackageClaimPreparation:
        raise ConfirmationError("require explicit PackageClaimPreparation evidence")
    snapshot = preparation.snapshot
    if type(snapshot) is not CapturedSnapshot:
        raise ConfirmationError("require an explicit CapturedSnapshot")
    if type(snapshot.payload) is not bytes or len(snapshot.payload) > MAX_BYTES:
        raise ConfirmationError("require bounded serialized package-claim snapshot bytes")
    _pin(snapshot.digest)
    if hashlib.sha256(snapshot.payload).hexdigest() != snapshot.digest:
        raise ConfirmationError("package-claim snapshot bytes do not match their hash")
    entries = snapshot.entries
    require_keys(entries, TARGETS)
    for entry in entries.values():
        if entry is not None:
            _validate(entry, observed=True)
    canonical = _canonical_json({"schema": "asset-snapshot/v1", "entries": entries}, ensure_ascii=True)
    if snapshot.payload != canonical:
        raise ConfirmationError("require canonical supported package-claim snapshot evidence")
    for entry in installed_entries.values():
        if entry is not None:
            _validate(entry, observed=True)
    if _canonical_json(entries, ensure_ascii=True) != _canonical_json(installed_entries, ensure_ascii=True):
        raise ConfirmationError("package-claim snapshot differs from installed evidence")
    return snapshot.digest, serialize_package_claim_evidence(preparation.observation)


@dataclass(frozen=True)
class ConfirmationPreview:
    """Immutable serialized data, not consent or a native receipt."""

    payload: bytes
    digest: str


def prepare_confirmation(*, provenance, candidates, installed_entries,
                         installed_snapshot_sha256, baseline_entries,
                         baseline_snapshot_sha256, proposed_plan,
                         package_claim_preparation: PackageClaimPreparation):
    """Rebuild decisions and bind evidence into a composer-only preview.

    Inputs must come from trusted preparation; this function does not authenticate
    provenance or independently observe ownership. It performs no IO and proves
    neither freshness nor display-diff accuracy. Later application must bind the
    destination and legacy operations, obtain consent, and revalidate live bytes.
    """
    try:
        require_keys(provenance, {"schema", "versions", "overlay_revision", "rules",
                                  "manifest_sha256", "block_sha256"})
        if provenance["schema"] != SCHEMA:
            raise ConfirmationError("unsupported provenance schema")
        require_keys(provenance["versions"], {"gentle_ai", "gentle_pi", "overlay"})
        if any(not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.+_-]*", value)
               for value in provenance["versions"].values()):
            raise ConfirmationError("require explicit version identifiers")
        revision = provenance["overlay_revision"]
        if not isinstance(revision, str) or not re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", revision):
            raise ConfirmationError("require a full overlay revision identifier")
        if provenance["rules"] != {"init": INIT_RULE, "agent": AGENT_RULE}:
            raise ConfirmationError("unsupported rendering or serialization rule")
        _pin(provenance["manifest_sha256"])
        require_keys(provenance["block_sha256"], {"init", "codegraph", "mcp"})
        for pin in provenance["block_sha256"].values():
            _pin(pin)
        require_keys(candidates, TARGETS)
        require_keys(installed_entries, TARGETS)
        _pin(installed_snapshot_sha256)
        if baseline_entries is None:
            if baseline_snapshot_sha256 is not None:
                raise ConfirmationError("absent baseline must have no snapshot pin")
        else:
            require_keys(baseline_entries, TARGETS)
            _pin(baseline_snapshot_sha256)
        package_snapshot_sha256, package_claims = _validated_package_claim_evidence(
            package_claim_preparation, installed_entries)
        require_keys(proposed_plan, {"schema", "provenance", "rows", "blocked",
                                     "installed_snapshot_sha256", "baseline_snapshot_sha256",
                                     "package_claim_snapshot_sha256", "package_claims"})
        _pin(proposed_plan["package_claim_snapshot_sha256"])
        if (proposed_plan["schema"] != PLAN_VERSION or type(proposed_plan["blocked"]) is not bool
                or proposed_plan["provenance"] != provenance
                or proposed_plan["installed_snapshot_sha256"] != installed_snapshot_sha256
                or proposed_plan["baseline_snapshot_sha256"] != baseline_snapshot_sha256
                or proposed_plan["package_claim_snapshot_sha256"] != package_snapshot_sha256
                or _canonical_json(proposed_plan["package_claims"]) != _canonical_json(package_claims)):
            raise ConfirmationError("plan metadata differs from supplied evidence")
        rows = proposed_plan["rows"]
        if not isinstance(rows, list) or len(rows) != len(TARGETS):
            raise ConfirmationError("require fourteen canonical plan rows")
        desired_entries, rebuilt = {}, []
        actions = {"noop": [], "propose": []}
        row_blocked = False
        for target, row, claim in zip(TARGETS, rows, package_claims["claims"]):
            candidate = candidates[target]
            require_keys(candidate, {"content", "sha256", "source_sha256", "tools"})
            content = candidate["content"]
            _pin(candidate["sha256"])
            _pin(candidate["source_sha256"])
            if (not isinstance(content, bytes) or len(content) > MAX_BYTES
                    or hashlib.sha256(content).hexdigest() != candidate["sha256"]):
                raise ConfirmationError("candidate bytes do not match their bounded hash")
            tools = _header(_text(content))[2] if target.startswith("agents/") else None
            content.decode("utf-8")
            if candidate["tools"] != tools:
                raise ConfirmationError("candidate tools differ from its bytes")
            installed = installed_entries[target]
            ownership = "unknown" if installed is None else installed["ownership"]
            current = None if installed is None else installed["sha256"]
            if (claim["target"] != target or claim["declaredOwnership"] != ownership
                    or claim["currentSha256"] != current
                    or claim["desiredSha256"] != candidate["sha256"]):
                raise ConfirmationError("package claim differs from supplied candidate or installed evidence")
            desired = {key: candidate[key] for key in ("sha256", "tools")}
            expected = plan_asset(target, baseline_entries[target] if baseline_entries is not None else None,
                                  installed, desired)
            require_keys(row, set(expected) | {"source_sha256", "diff"})
            if not isinstance(row["diff"], str) or len(row["diff"].encode("utf-8")) > MAX_BYTES:
                raise ConfirmationError("require bounded display diff text")
            expected.update(source_sha256=candidate["source_sha256"], diff=row["diff"])
            if row != expected:
                raise ConfirmationError("plan row differs from recomputed decision")
            row_blocked = row_blocked or expected["action"] == "blocked"
            if expected["action"] != "blocked":
                actions[expected["action"]].append(target)
            desired_entries[target] = dict(desired, source_sha256=candidate["source_sha256"])
            rebuilt.append(expected)
        blocked = row_blocked or bool(package_claims["conflicts"])
        if proposed_plan["blocked"] != blocked:
            raise ConfirmationError("blocked flag differs from recomputed decisions")
        if blocked:
            raise ConfirmationError("blocked plans cannot produce a confirmation preview")
        bound_plan = dict(proposed_plan, rows=rebuilt, package_claims=package_claims,
                          package_claim_snapshot_sha256=package_snapshot_sha256)
        payload = _canonical_json({"schema": "asset-confirmation-plan/v1", "kind": "composer-only-preview",
                                   "plan": bound_plan, "actions": actions,
                                   "installed_entries": installed_entries, "baseline_entries": baseline_entries,
                                   "desired_entries": desired_entries})
        if len(payload) > MAX_BYTES:
            raise ConfirmationError("confirmation preview exceeds the byte limit")
        return ConfirmationPreview(payload, hashlib.sha256(payload).hexdigest())
    except (ValueError, TypeError, RecursionError) as exc:
        raise ConfirmationError(str(exc)) from exc
