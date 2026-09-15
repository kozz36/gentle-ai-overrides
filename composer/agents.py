"""Pure agent composition for a deliberately restricted frontmatter subset.

Sources use plain, single-line scalars and a final tools sequence indented by
exactly two spaces. Unsupported YAML is rejected, never approximated. Supplied
block hashes and preference approval must be checked by the input-bundle layer.
"""
import re

RULE_VERSION = "pi-agent-preferences/v1"
ROLES = frozenset("apply archive design explore init onboard proposal research spec status sync tasks verify".split())
MCP_ROLES = frozenset("apply archive init onboard status sync verify".split())
THINKING = frozenset("off minimal low medium high xhigh".split())
CG_OPEN = "<!-- gentle-ai:pi-codegraph-guidance -->"
TOOL_OPEN = "<!-- gentle-ai:pi-codegraph-tool -->"
CLOSE = "<!-- /gentle-ai:pi-codegraph -->"
TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_./:+-]*\Z")


class AgentError(ValueError):
    """A source, explicit preference, or supplied block is unsupported."""


def _text(data):
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise AgentError("require UTF-8") from exc
    if not text.endswith("\n") or "\r" in text or "\x00" in text:
        raise AgentError("require LF-terminated text without CR or NUL")
    return text


def _block(data, opening):
    text = _text(data)
    lines = text[:-1].split("\n")
    if lines[0] != opening or lines[-1] != CLOSE:
        raise AgentError("block boundaries do not match the selected kind")
    for i, line in enumerate(lines):
        if "gentle-ai:pi-codegraph" in line and not (
            (i == 0 and line == opening) or (i == len(lines) - 1 and line == CLOSE)
        ):
            raise AgentError("nested, duplicate, or partial CodeGraph markers")


def _plain(value):
    """Reject syntax indicators, not merely spaces in otherwise plain values."""
    return bool(value and value == value.strip()
                and value[0] not in "[]{}>|&*!'\"#%@`,"
                and not re.search(r":(?:[ \t]|$)|[ \t]#|^[-?](?:[ \t]|$)", value))


def _header(text):
    lines = text.split("\n")
    if lines[0] != "---" or "---" not in lines[1:]:
        raise AgentError("require a complete initial frontmatter block")
    end = lines.index("---", 1)
    header = lines[1:end]
    values, tools = {}, []
    in_tools = False
    for line in header:
        if in_tools:
            if not re.fullmatch(r"  - [A-Za-z][A-Za-z0-9_-]*", line):
                raise AgentError("tools must be the final two-space block sequence")
            tools.append(line[4:])
            continue
        match = re.fullmatch(r"([a-z]+):(?: (.+))?", line)
        if not match:
            raise AgentError("unsupported frontmatter syntax")
        key, value = match.groups()
        if key not in {"name", "description", "model", "thinking", "tools"} or key in values:
            raise AgentError("unknown or duplicate frontmatter key")
        values[key] = value
        if key == "tools":
            if value is not None:
                raise AgentError("flow tools are unsupported")
            in_tools = True
        elif not _plain(value):
            raise AgentError("only unambiguous plain scalar fields are supported")
    if not {"name", "description", "tools"} <= values.keys() or not tools:
        raise AgentError("name, description and explicit nonempty tools are required")
    if len(tools) != len(set(tools)):
        raise AgentError("duplicate source tools are unsupported")
    return header, values, tools, "\n".join(lines[end + 1:])


def compose_agent(source: bytes, *, role: str, expected_source_tools,
                  guidance: bytes, mcp: bool, mcp_block=None,
                  model=None, thinking=None) -> bytes:
    """Compose only explicit preferences; keep the original body as a prefix.

    expected_source_tools is a previously confirmed contract, not a list to
    regenerate blindly from new upstream bytes. No new role or tool is inferred.
    """
    text = _text(source)
    if "gentle-ai:pi-codegraph" in text:
        raise AgentError("source already contains managed CodeGraph content")
    header, values, tools, body = _header(text)
    if not isinstance(role, str) or not isinstance(expected_source_tools, (list, tuple)):
        raise AgentError("require an explicit role string and tool contract list")
    short_role = role.removeprefix("sdd-")
    if role != "sdd-" + short_role or short_role not in ROLES or values["name"] != role:
        raise AgentError("unknown role or source/inventory mismatch")
    if tools != list(expected_source_tools) or "mcp" in tools:
        raise AgentError("source tool contract changed or already includes MCP")
    if type(mcp) is not bool or mcp != (mcp_block is not None):
        raise AgentError("MCP choice must be explicit and match its supplied block")
    if mcp and short_role not in MCP_ROLES:
        raise AgentError("MCP is not a supported preservation choice for this role")
    if (model is None) != (thinking is None):
        raise AgentError("explicit model and thinking must be supplied together")
    if model is not None and (not isinstance(model, str) or not TOKEN.fullmatch(model)
                              or not _plain(model) or not isinstance(thinking, str)
                              or thinking not in THINKING):
        raise AgentError("unsupported explicit model/thinking value")
    _block(guidance, CG_OPEN)
    if mcp:
        _block(mcp_block, TOOL_OPEN)
    rendered = []
    for line in header:
        key = line.split(":", 1)[0]
        if model is not None and key in {"model", "thinking"}:
            continue
        if line == "tools:":
            if model is not None:
                rendered.extend([f"model: {model}", f"thinking: {thinking}"])
            rendered.append(line)
            if mcp:
                rendered.append("  - mcp")
        else:
            rendered.append(line)
    result = ("---\n" + "\n".join(rendered) + "\n---\n" + body).encode("utf-8")
    return result + b"\n" + (mcp_block + b"\n" if mcp else b"") + guidance
