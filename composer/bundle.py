"""Versioned local input bundle: pinned bytes and explicit preferences only.

Hashes check local integrity, not upstream authenticity or human approval.
The caller supplies trustworthy provenance and a separately pinned manifest.
No installed files, native ownership, output directories, or HOME are accessed.
"""
import hashlib
import json
import re
from types import MappingProxyType

from .agents import AgentError, RULE_VERSION as AGENT_RULE, compose_agent
from .neutral_policy import (GENTLE_INIT_RULE_VERSION,
                             LEGACY_SDD_INIT_RETIRE_RULE_VERSION, NeutralPolicyError,
                             render_gentle_init_rubric, retire_legacy_sdd_init_rubric)
from .neutral_routing import (DELEGATION_FORWARDING_RULE_VERSION,
                              WORKFLOW_FORWARDING_RULE_VERSION, NeutralRoutingError,
                              render_optional_odd_delegation, render_workflow_forwarding)
from .overlay import RULE_VERSION as INIT_RULE
from .overlay import RenderError, render_pi_init
from .profiles import ProfileError, V1_PROFILE, profile_for_schema
from .storage import MAX_BYTES

SCHEMA = V1_PROFILE.schema
# Public compatibility alias for the historical deterministic-assets/v1 inventory.
TARGETS = V1_PROFILE.targets


class BundleError(ValueError):
    """A supplied bundle does not satisfy the selected versioned contract."""


def _unique(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise BundleError("duplicate JSON key")
        result[key] = value
    return result


def _nonfinite(value):
    raise BundleError("non-finite JSON values are unsupported")


def decode_json(data):
    try:
        return json.loads(data.decode("utf-8"), object_pairs_hook=_unique, parse_constant=_nonfinite)
    except (UnicodeDecodeError, RecursionError, json.JSONDecodeError) as exc:
        raise BundleError("invalid or excessively nested UTF-8 JSON") from exc


def require_keys(value, keys):
    if not isinstance(value, dict) or set(value) != set(keys):
        raise BundleError("missing, extra, or unsupported object fields")


def _pin(value):
    if not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{64}", value):
        raise BundleError("every input requires an explicit SHA-256 pin")
    return value


V2_RULES = {
    "init": INIT_RULE, "agent": AGENT_RULE,
    "gentle_init": GENTLE_INIT_RULE_VERSION,
    "legacy_sdd_init": LEGACY_SDD_INIT_RETIRE_RULE_VERSION,
    "workflow_forwarding": WORKFLOW_FORWARDING_RULE_VERSION,
    "delegation_forwarding": DELEGATION_FORWARDING_RULE_VERSION,
}
V2_BLOCKS = ("init", "codegraph", "mcp", "gentle_init", "legacy_sdd_init",
             "workflow_current", "workflow_predecessor", "delegation_current",
             "delegation_predecessor")
V2_PROVENANCE_VERSIONS = MappingProxyType({
    "gentle_ai": "3.1.0",
    "gentle_pi": "3.2.0",
    "overlay": "3.2.0-overlay.1",
})


def compose_bundle(root, manifest_sha256):
    """Return schema-selected in-memory candidates; never publish them."""
    manifest = decode_json(root.read("bundle.json", _pin(manifest_sha256)))
    require_keys(manifest, {"schema", "versions", "overlay_revision", "rules", "blocks", "assets"})
    try:
        profile = profile_for_schema(manifest["schema"])
    except ProfileError as exc:
        raise BundleError("unsupported bundle schema") from exc
    require_keys(manifest["versions"], {"gentle_ai", "gentle_pi", "overlay"})
    if any(not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.+_-]*", value)
           for value in manifest["versions"].values()):
        raise BundleError("require explicit version identifiers")
    if profile is not V1_PROFILE and manifest["versions"] != V2_PROVENANCE_VERSIONS:
        raise BundleError("require exact v2 release provenance versions")
    revision = manifest["overlay_revision"]
    if not isinstance(revision, str) or not re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", revision):
        raise BundleError("require a full overlay revision identifier")
    is_v1 = profile is V1_PROFILE
    expected_rules = {"init": INIT_RULE, "agent": AGENT_RULE} if is_v1 else V2_RULES
    block_names = ("init", "codegraph", "mcp") if is_v1 else V2_BLOCKS
    if manifest["rules"] != expected_rules:
        raise BundleError("unsupported rendering or serialization rule")
    require_keys(manifest["assets"], profile.targets)
    require_keys(manifest["blocks"], block_names)
    blocks = {name: root.read(f"blocks/{name}.md", _pin(manifest["blocks"][name]))
              for name in block_names}
    candidates, optional_absent = {}, []
    for target in profile.targets:
        entry = manifest["assets"][target]
        if entry is None:
            if target not in profile.optional_targets:
                raise BundleError("required asset cannot be absent")
            optional_absent.append(target)
            continue
        require_keys(entry, {"source_sha256", "preferences"})
        source = root.read("sources/" + target, _pin(entry["source_sha256"]))
        preferences, tools = entry["preferences"], None
        try:
            if target.startswith("agents/"):
                require_keys(preferences, {"expected_source_tools", "model", "thinking", "mcp"})
                role = target.removeprefix("agents/").removesuffix(".md")
                if role == "sdd-research":
                    if preferences["model"] is not None or preferences["thinking"] is not None:
                        raise BundleError("this inventory has no confirmed research routing override")
                elif preferences["model"] is None or preferences["thinking"] is None:
                    raise BundleError("this inventory requires twelve explicit routing pairs")
                if role == "sdd-init":
                    if b"gentle-ai:sdd-init-rubric" in source:
                        raise BundleError("init bundle source is already patched, not pristine")
                    source = render_pi_init(source, blocks["init"])
                source = compose_agent(source, role=role, guidance=blocks["codegraph"],
                                       mcp_block=blocks["mcp"] if preferences["mcp"] else None,
                                       **preferences)
                tools = (["mcp"] if preferences["mcp"] else []) + list(preferences["expected_source_tools"])
            elif target == "assets/agents/gentle-init.md":
                if preferences is not None:
                    raise BundleError("package bytes have no preference transform")
                source = render_gentle_init_rubric(source, blocks["gentle_init"])
            elif target == "assets/agents/sdd-init.md":
                if preferences is not None:
                    raise BundleError("package bytes have no preference transform")
                source = retire_legacy_sdd_init_rubric(source, blocks["legacy_sdd_init"])
            elif target == "assets/sdd-orchestrator-workflow.md":
                if preferences is not None:
                    raise BundleError("package bytes have no preference transform")
                source = render_workflow_forwarding(source, blocks["workflow_current"],
                                                    blocks["workflow_predecessor"])
            elif target == "assets/orchestrator-delegation.md":
                if preferences is not None:
                    raise BundleError("package bytes have no preference transform")
                source = render_optional_odd_delegation(source, blocks["delegation_current"],
                                                        blocks["delegation_predecessor"]).candidate
            elif preferences is not None:
                raise BundleError("chain bytes have no frontmatter preference transform")
        except (AgentError, RenderError, NeutralPolicyError, NeutralRoutingError) as exc:
            raise BundleError("unsupported candidate transform") from exc
        if source is None or len(source) > MAX_BYTES:
            raise BundleError("composed candidate exceeds the output byte limit")
        candidates[target] = {"content": source, "sha256": hashlib.sha256(source).hexdigest(),
                              "source_sha256": entry["source_sha256"], "tools": tools}
    metadata = {key: manifest[key] for key in ("schema", "versions", "overlay_revision", "rules")}
    metadata["manifest_sha256"] = manifest_sha256
    metadata["block_sha256"] = manifest["blocks"].copy()
    if not is_v1:
        metadata["optional_absent"] = sorted(optional_absent)
    return metadata, candidates
