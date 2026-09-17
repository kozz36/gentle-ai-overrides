"""Immutable schema-versioned composer target inventories.

Profiles describe target identities and optionality only.  They neither read source
bytes nor authorize composition, so future propagation can select an inventory
without changing current v1 callers.
"""
from dataclasses import dataclass
from pathlib import PurePosixPath

from .agents import ROLES


V1_SCHEMA = "deterministic-assets/v1"
V2_SCHEMA = "deterministic-assets/v2"

HISTORICAL_V1_TARGETS = tuple(sorted(
    [f"agents/sdd-{role}.md" for role in ROLES] + ["chains/sdd-verify.chain.md"]
))
V2_OPTIONAL_TARGETS = ("assets/orchestrator-delegation.md",)
V2_REQUIRED_TARGETS = tuple(sorted(HISTORICAL_V1_TARGETS + (
    "assets/agents/gentle-init.md",
    "assets/agents/sdd-init.md",
    "assets/sdd-orchestrator-workflow.md",
)))
_EXPECTED_CLASSIFICATIONS = {
    V1_SCHEMA: (HISTORICAL_V1_TARGETS, ()),
    V2_SCHEMA: (V2_REQUIRED_TARGETS, V2_OPTIONAL_TARGETS),
}


class ProfileError(ValueError):
    """A composer schema or its declared target inventory is unsupported."""


def _safe_target(target):
    if (type(target) is not str or not target or target.startswith("/")
            or "\\" in target or "\x00" in target):
        return False
    path = PurePosixPath(target)
    return (str(path) == target and bool(path.parts)
            and all(part not in {"", ".", ".."} for part in path.parts))


def _validate_targets(required_targets, optional_targets):
    if type(required_targets) is not tuple or type(optional_targets) is not tuple:
        raise ProfileError("profile target classifications must be immutable tuples")
    for targets in (required_targets, optional_targets):
        if targets != tuple(sorted(targets)) or len(targets) != len(set(targets)):
            raise ProfileError("profile target classifications must be unique and sorted")
        if not all(_safe_target(target) for target in targets):
            raise ProfileError("profile target must be a safe relative POSIX path")
    if set(required_targets) & set(optional_targets):
        raise ProfileError("profile target classifications must not overlap")
    targets = tuple(sorted(required_targets + optional_targets))
    if len(targets) != len(set(targets)):
        raise ProfileError("profile target inventory must be unique")
    return targets


@dataclass(frozen=True)
class ComposerProfile:
    """One supported schema's explicit required and optional target identities."""

    schema: str
    required_targets: tuple[str, ...]
    optional_targets: tuple[str, ...]

    def __post_init__(self):
        if type(self.schema) is not str or self.schema not in _EXPECTED_CLASSIFICATIONS:
            raise ProfileError("unsupported composer schema")
        _validate_targets(self.required_targets, self.optional_targets)
        if ((self.required_targets, self.optional_targets)
                != _EXPECTED_CLASSIFICATIONS[self.schema]):
            raise ProfileError("profile inventory differs from the supported schema")

    @property
    def targets(self):
        """Return the immutable complete inventory in canonical target order."""
        return tuple(sorted(self.required_targets + self.optional_targets))


V1_PROFILE = ComposerProfile(V1_SCHEMA, HISTORICAL_V1_TARGETS, ())
V2_PROFILE = ComposerProfile(V2_SCHEMA, V2_REQUIRED_TARGETS, V2_OPTIONAL_TARGETS)
_PROFILES = {profile.schema: profile for profile in (V1_PROFILE, V2_PROFILE)}


def profile_for_schema(schema):
    """Return one known profile; unknown schemas never receive a fallback."""
    try:
        return _PROFILES[schema]
    except (KeyError, TypeError) as exc:
        raise ProfileError("unsupported composer schema") from exc
