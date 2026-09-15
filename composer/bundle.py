"""Versioned local input bundle: pinned bytes and explicit preferences only.

Hashes check local integrity, not upstream authenticity or human approval.
The caller supplies trustworthy provenance and a separately pinned manifest.
No installed files, native ownership, output directories, or HOME are accessed.
"""
import hashlib
import json
import re

from .agents import ROLES, RULE_VERSION as AGENT_RULE, compose_agent
from .overlay import RULE_VERSION as INIT_RULE, render_pi_init
from .storage import MAX_BYTES

SCHEMA = "deterministic-assets/v1"
TARGETS = tuple(sorted([f"agents/sdd-{role}.md" for role in ROLES] + ["chains/sdd-verify.chain.md"]))


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


def compose_bundle(root, manifest_sha256):
    """Return provenance and fourteen in-memory candidates; never publish them.

    Layout: bundle.json, blocks/{init,codegraph,mcp}.md, sources/<target>.
    Source-tool contracts and twelve routing pairs are explicit approved inputs;
    they are not regenerated from whichever upstream version happens to exist.
    """
    manifest = decode_json(root.read("bundle.json", _pin(manifest_sha256)))
    require_keys(manifest, {"schema", "versions", "overlay_revision", "rules", "blocks", "assets"})
    if manifest["schema"] != SCHEMA:
        raise BundleError("unsupported bundle schema")
    require_keys(manifest["versions"], {"gentle_ai", "gentle_pi", "overlay"})
    if any(not isinstance(value, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.+_-]*", value)
           for value in manifest["versions"].values()):
        raise BundleError("require explicit version identifiers")
    revision = manifest["overlay_revision"]
    if not isinstance(revision, str) or not re.fullmatch(r"(?:[0-9a-f]{40}|[0-9a-f]{64})", revision):
        raise BundleError("require a full overlay revision identifier")
    if manifest["rules"] != {"init": INIT_RULE, "agent": AGENT_RULE}:
        raise BundleError("unsupported rendering or serialization rule")
    require_keys(manifest["assets"], TARGETS)
    require_keys(manifest["blocks"], {"init", "codegraph", "mcp"})
    blocks = {name: root.read(f"blocks/{name}.md", _pin(pin)) for name, pin in manifest["blocks"].items()}
    candidates = {}
    for target in TARGETS:
        entry = manifest["assets"][target]
        require_keys(entry, {"source_sha256", "preferences"})
        source = root.read("sources/" + target, _pin(entry["source_sha256"]))
        preferences = entry["preferences"]
        tools = None
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
        elif preferences is not None:
            raise BundleError("chain bytes have no frontmatter preference transform")
        if len(source) > MAX_BYTES:
            raise BundleError("composed candidate exceeds the output byte limit")
        candidates[target] = {"content": source, "sha256": hashlib.sha256(source).hexdigest(),
                              "source_sha256": entry["source_sha256"], "tools": tools}
    metadata = {key: manifest[key] for key in ("schema", "versions", "overlay_revision", "rules")}
    metadata["manifest_sha256"] = manifest_sha256
    metadata["block_sha256"] = manifest["blocks"].copy()
    return metadata, candidates
