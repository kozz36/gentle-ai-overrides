"""Candidate-only CLI. Run `python3 -m composer --help` from the repository.

Snapshots are supplied evidence, not native ownership/approval discovery.
All inputs and plans are validated before creating a fresh output directory.
"""
import argparse
from contextlib import ExitStack
import difflib
import hashlib
import json
import sys

from .agents import _header, _text
from .bundle import BundleError, compose_bundle, decode_json, require_keys
from .package_claims import serialize_package_claim_evidence
from .profiles import ProfileError, V1_PROFILE, profile_for_schema
from .planner import PLAN_VERSION, _validate, plan_asset
from .preparation import prepare_package_claim_evidence
from .storage import MAX_BYTES, Root


def _snapshot(root, profile=V1_PROFILE):
    raw = root.read("state.json")
    state = decode_json(raw)
    if profile is V1_PROFILE:
        require_keys(state, {"schema", "entries"})
        if state["schema"] != "asset-snapshot/v1":
            raise BundleError("unsupported snapshot schema")
    else:
        require_keys(state, {"schema", "profileSchema", "entries"})
        if (state["schema"] != "asset-snapshot/v2"
                or state["profileSchema"] != profile.schema):
            raise BundleError("unsupported snapshot schema")
    require_keys(state["entries"], profile.targets)
    contents = {}
    for target in profile.targets:
        observation = state["entries"][target]
        if observation is None:
            try:
                root.read(target)
            except FileNotFoundError:
                contents[target] = b""
                continue
            raise BundleError(f"{target}: snapshot declares absent but file exists")
        _validate(observation, observed=True)
        data = root.read(target, observation["sha256"])
        tools = _header(_text(data))[2] if target.startswith("agents/") else None
        if tools != observation["tools"]:
            raise BundleError(f"{target}: snapshot tool metadata disagrees with bytes")
        contents[target] = data
    return state["entries"], contents, hashlib.sha256(raw).hexdigest()


def _compose(args):
    with ExitStack() as stack:
        roots = [stack.enter_context(Root(args.input)), stack.enter_context(Root(args.installed)),
                 stack.enter_context(Root(args.claims_home))]
        metadata, candidates = compose_bundle(roots[0], args.manifest_sha256)
        try:
            profile = profile_for_schema(metadata.get("schema"))
        except ProfileError as exc:
            raise BundleError("unsupported bundle profile metadata") from exc
        provenance_keys = {"schema", "versions", "overlay_revision", "rules", "manifest_sha256",
                           "block_sha256"}
        if profile is not V1_PROFILE:
            provenance_keys.add("optional_absent")
        require_keys(metadata, provenance_keys)
        optional_absent = [] if profile is V1_PROFILE else metadata["optional_absent"]
        if type(optional_absent) is not list:
            raise BundleError("optional absence differs from selected candidate inventory")
        present = tuple(target for target in profile.targets if target not in optional_absent)
        if optional_absent != [target for target in profile.optional_targets
                              if target not in candidates]:
            raise BundleError("optional absence differs from selected candidate inventory")
        require_keys(candidates, present)
        for target in present:
            candidate = candidates[target]
            require_keys(candidate, {"content", "sha256", "source_sha256", "tools"})
            if (not isinstance(candidate["content"], bytes)
                    or hashlib.sha256(candidate["content"]).hexdigest() != candidate["sha256"]):
                raise BundleError("candidate desired hash does not match bytes")
        installed, contents, installed_pin = _snapshot(roots[1], profile)
        baseline, baseline_pin = dict.fromkeys(profile.targets), None
        if args.baseline is not None:
            roots.append(stack.enter_context(Root(args.baseline)))
            baseline, _, baseline_pin = _snapshot(roots[-1], profile)
        ownership = {target: entry["ownership"] if entry is not None else "unknown"
                     for target, entry in installed.items()}
        desired_sha256 = {target: (candidates[target]["sha256"] if target in candidates else None)
                          for target in profile.targets}
        preparation = prepare_package_claim_evidence(
            roots[2], declared_ownership=ownership, desired_sha256=desired_sha256, profile=profile)
        if preparation.snapshot.entries != installed:
            raise BundleError("package-claim snapshot disagrees with installed snapshot; no files written")
        package_claims = serialize_package_claim_evidence(preparation.observation)
        rows = []
        for target in present:
            candidate = candidates[target]
            desired = {key: candidate[key] for key in ("sha256", "tools")}
            row = plan_asset(target, baseline[target], installed[target], desired)
            row["source_sha256"] = candidate["source_sha256"]
            row["diff"] = "".join(difflib.unified_diff(
                contents[target].decode("utf-8").splitlines(keepends=True),
                candidate["content"].decode("utf-8").splitlines(keepends=True),
                fromfile="installed/" + target, tofile="candidate/" + target))
            rows.append(row)
        plan = {"schema": PLAN_VERSION, "provenance": metadata, "rows": rows,
                "installed_snapshot_sha256": installed_pin, "baseline_snapshot_sha256": baseline_pin,
                "package_claim_snapshot_sha256": preparation.snapshot.digest,
                "package_claims": package_claims,
                "blocked": (any(row["action"] == "blocked" for row in rows)
                            or bool(package_claims["conflicts"]))}
        encoded = (json.dumps(plan, sort_keys=True, indent=2) + "\n").encode()
        if len(encoded) > MAX_BYTES:
            raise BundleError("plan exceeds the output byte limit; no files written")
        with Root.create_output(args.output, protected=roots) as output:
            for target in present:
                candidate = candidates[target]
                output.write(target, candidate["content"])
                output.read(target, candidate["sha256"])
            # Presence of this file is not approval; process success/readback still matters.
            output.write("plan.json", encoded)
            output.read("plan.json", hashlib.sha256(encoded).hexdigest())
        return plan["blocked"], len(present)


def compose(args):
    """Compose candidates while retaining the historical boolean API."""
    return _compose(args)[0]


def main(argv=None):
    parser = argparse.ArgumentParser(description="Compose private candidates; never install or adopt assets.")
    for name in ("input", "manifest-sha256", "installed", "claims-home", "output"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--baseline", help="Optional previously verified snapshot root; never bootstrapped here")
    args = parser.parse_args(argv)
    try:
        blocked, assets = _compose(args)
    except (ValueError, OSError) as exc:
        print(f"composer: {exc}", file=sys.stderr)
        return 3
    print(json.dumps({"output": args.output, "assets": assets, "blocked": blocked}))
    return 2 if blocked else 0


if __name__ == "__main__":
    raise SystemExit(main())
