"""Read-only observations of package-managed asset claims.

A manifest record is evidence of a package claim, never permission to modify an
agent home. This module reads only the supplied ``gentle-ai`` manifest.
"""
from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
import hashlib
import re

from .bundle import BundleError, _pin, decode_json, require_keys
from .planner import OWNERS
from .profiles import ComposerProfile, ProfileError, V1_PROFILE, V1_SCHEMA, profile_for_schema
from .storage import PathError, Root, _parts

MANIFEST_PATH = "gentle-ai/managed-assets.json"
MANIFEST_SCHEMA_VERSION = 1
PACKAGE_VERSION = "2.7.0"

CURRENT_CLAIM = "current_claim"
DESIRED_HASH_REATTACHMENT = "desired_hash_reattachment"
STALE_CLAIM = "stale_claim"
OWNERSHIP_CONTRADICTION = "ownership_contradiction"
SUPPORTED_PACKAGE_VERSIONS = frozenset({PACKAGE_VERSION})
_CONFLICT_REASONS = frozenset({
    CURRENT_CLAIM,
    DESIRED_HASH_REATTACHMENT,
    STALE_CLAIM,
    OWNERSHIP_CONTRADICTION,
})


class PackageClaimError(ValueError):
    """An ownership declaration or managed-assets manifest is unsupported."""


@dataclass(frozen=True)
class PackageClaim:
    """One target's supplied hashes and the manifest hash, if any."""

    target: str
    declared_ownership: str
    current_sha256: str | None
    desired_sha256: str | None
    manifest_sha256: str | None


@dataclass(frozen=True)
class PackageClaimConflict:
    """A canonical reason why the manifest cannot silently establish authority."""

    target: str
    reason: str
    declared_ownership: str
    current_sha256: str | None
    desired_sha256: str | None
    manifest_sha256: str | None


@dataclass(frozen=True)
class PackageClaimObservation:
    """Immutable package-claim evidence; it neither grants authority nor writes."""

    package_version: str
    manifest_schema_version: int
    manifest_sha256: str | None
    claims: tuple[PackageClaim, ...]
    conflicts: tuple[PackageClaimConflict, ...]
    profile_schema: str = V1_SCHEMA


def _profile(profile):
    if type(profile) is not ComposerProfile:
        raise PackageClaimError("require a supported ComposerProfile")
    try:
        supported = profile_for_schema(profile.schema)
    except ProfileError as exc:
        raise PackageClaimError("unsupported composer profile") from exc
    if profile != supported:
        raise PackageClaimError("profile inventory differs from its supported schema")
    return supported


def _profile_schema(schema):
    if type(schema) is not str:
        raise PackageClaimError("unsupported composer profile")
    try:
        return profile_for_schema(schema)
    except ProfileError as exc:
        raise PackageClaimError("unsupported composer profile") from exc


def _mapping(value, name, profile):
    if not isinstance(value, Mapping):
        raise PackageClaimError(f"require an explicit {name} mapping")
    result = dict(value)
    try:
        require_keys(result, profile.targets)
    except BundleError as exc:
        raise PackageClaimError(f"require exactly the selected {name} targets") from exc
    return result


def _ownership(value, profile):
    result = _mapping(value, "ownership", profile)
    if any(not isinstance(owner, str) or owner not in OWNERS for owner in result.values()):
        raise PackageClaimError("unsupported declared ownership")
    return result


def _hashes(value, name, profile, *, allow_absent):
    result = _mapping(value, name, profile)
    for target, digest in result.items():
        if digest is None and (allow_absent or target in profile.optional_targets):
            continue
        try:
            _pin(digest)
        except BundleError as exc:
            raise PackageClaimError(f"{target}: require a lowercase SHA-256") from exc
    return result


def _manifest(agent_home):
    try:
        data = agent_home.read(MANIFEST_PATH)
    except FileNotFoundError:
        return None, {}
    try:
        manifest = decode_json(data)
        require_keys(manifest, {"schemaVersion", "assets"})
    except BundleError as exc:
        raise PackageClaimError("invalid managed-assets manifest") from exc
    if type(manifest["schemaVersion"]) is not int or manifest["schemaVersion"] != MANIFEST_SCHEMA_VERSION:
        raise PackageClaimError("unsupported managed-assets manifest schema")
    assets = manifest["assets"]
    if not isinstance(assets, dict):
        raise PackageClaimError("managed-assets assets must be an object")
    for target, digest in assets.items():
        try:
            _parts(target)
            _pin(digest)
        except (BundleError, PathError) as exc:
            raise PackageClaimError("unsafe managed-assets entry") from exc
    return hashlib.sha256(data).hexdigest(), assets


def _conflict(target, reason, ownership, current, desired, manifest):
    return PackageClaimConflict(
        target=target,
        reason=reason,
        declared_ownership=ownership,
        current_sha256=current,
        desired_sha256=desired,
        manifest_sha256=manifest,
    )


def _canonical_conflicts(claims):
    conflicts = []
    for claim in claims:
        if claim.manifest_sha256 is not None:
            if claim.desired_sha256 is None:
                reason = STALE_CLAIM
            elif claim.manifest_sha256 == claim.current_sha256:
                reason = CURRENT_CLAIM
            elif claim.manifest_sha256 == claim.desired_sha256:
                reason = DESIRED_HASH_REATTACHMENT
            else:
                reason = STALE_CLAIM
            conflicts.append(_conflict(claim.target, reason, claim.declared_ownership,
                                       claim.current_sha256, claim.desired_sha256,
                                       claim.manifest_sha256))
        current_claim = (claim.manifest_sha256 is not None and
                         claim.desired_sha256 is not None and
                         claim.manifest_sha256 == claim.current_sha256)
        if ((claim.declared_ownership == "managed" and not current_claim) or
                (claim.declared_ownership == "user-owned" and claim.manifest_sha256 is not None)):
            conflicts.append(_conflict(claim.target, OWNERSHIP_CONTRADICTION,
                                       claim.declared_ownership, claim.current_sha256,
                                       claim.desired_sha256, claim.manifest_sha256))
    return tuple(conflicts)


def _sha256(value, name, *, allow_none):
    if value is None and allow_none:
        return
    if type(value) is not str:
        raise PackageClaimError(f"{name}: require a lowercase SHA-256")
    try:
        _pin(value)
    except BundleError as exc:
        raise PackageClaimError(f"{name}: require a lowercase SHA-256") from exc


def _validate_claim(claim, profile):
    if type(claim) is not PackageClaim:
        raise PackageClaimError("require PackageClaim entries")
    if type(claim.target) is not str:
        raise PackageClaimError("claim target must be a string")
    if type(claim.declared_ownership) is not str or claim.declared_ownership not in OWNERS:
        raise PackageClaimError("unsupported claim ownership")
    _sha256(claim.current_sha256, "claim current hash", allow_none=True)
    _sha256(claim.desired_sha256, "claim desired hash",
            allow_none=claim.target in profile.optional_targets)
    _sha256(claim.manifest_sha256, "claim manifest hash", allow_none=True)


def _validate_conflict(conflict, profile):
    if type(conflict) is not PackageClaimConflict:
        raise PackageClaimError("require PackageClaimConflict entries")
    if type(conflict.target) is not str or type(conflict.reason) is not str:
        raise PackageClaimError("conflict target and reason must be strings")
    if conflict.reason not in _CONFLICT_REASONS:
        raise PackageClaimError("unsupported conflict reason")
    if type(conflict.declared_ownership) is not str or conflict.declared_ownership not in OWNERS:
        raise PackageClaimError("unsupported conflict ownership")
    _sha256(conflict.current_sha256, "conflict current hash", allow_none=True)
    _sha256(conflict.desired_sha256, "conflict desired hash",
            allow_none=conflict.target in profile.optional_targets)
    _sha256(conflict.manifest_sha256, "conflict manifest hash", allow_none=True)


def _validate_observation(observation):
    if type(observation) is not PackageClaimObservation:
        raise PackageClaimError("require a PackageClaimObservation")
    if type(observation.package_version) is not str or observation.package_version not in SUPPORTED_PACKAGE_VERSIONS:
        raise PackageClaimError("unsupported package metadata")
    if (type(observation.manifest_schema_version) is not int or
            observation.manifest_schema_version != MANIFEST_SCHEMA_VERSION):
        raise PackageClaimError("unsupported managed-assets manifest schema")
    _sha256(observation.manifest_sha256, "manifest hash", allow_none=True)
    profile = _profile_schema(observation.profile_schema)
    if type(observation.claims) is not tuple:
        raise PackageClaimError("require immutable claim tuple")
    for claim in observation.claims:
        _validate_claim(claim, profile)
    if tuple(claim.target for claim in observation.claims) != profile.targets:
        raise PackageClaimError("require exactly the selected claims in canonical order")
    if observation.manifest_sha256 is None and any(claim.manifest_sha256 is not None
                                                   for claim in observation.claims):
        raise PackageClaimError("per-target manifest claims require a manifest hash")
    if type(observation.conflicts) is not tuple:
        raise PackageClaimError("require immutable conflict tuple")
    for conflict in observation.conflicts:
        _validate_conflict(conflict, profile)
    if observation.conflicts != _canonical_conflicts(observation.claims):
        raise PackageClaimError("supplied conflicts are not canonical")


def serialize_package_claim_evidence(observation: PackageClaimObservation) -> dict[str, object]:
    """Validate and detach canonical package-claim evidence for JSON serialization.

    This pure serializer proves neither current/desired binding nor freshness,
    authenticity, ownership authority, consent, or permission to modify anything.
    """
    _validate_observation(observation)
    evidence = {
        "packageVersion": observation.package_version,
        "manifestSchemaVersion": observation.manifest_schema_version,
        "manifestSha256": observation.manifest_sha256,
        "claims": [{
            "target": claim.target,
            "declaredOwnership": claim.declared_ownership,
            "currentSha256": claim.current_sha256,
            "desiredSha256": claim.desired_sha256,
            "manifestSha256": claim.manifest_sha256,
        } for claim in observation.claims],
        "conflicts": [{
            "target": conflict.target,
            "reason": conflict.reason,
            "declaredOwnership": conflict.declared_ownership,
            "currentSha256": conflict.current_sha256,
            "desiredSha256": conflict.desired_sha256,
            "manifestSha256": conflict.manifest_sha256,
        } for conflict in observation.conflicts],
    }
    if observation.profile_schema != V1_SCHEMA:
        evidence["profileSchema"] = observation.profile_schema
    return evidence


def observe_package_claims(
    agent_home: Root,
    *,
    declared_ownership: Mapping[str, str],
    current_sha256: Mapping[str, str | None],
    desired_sha256: Mapping[str, str | None],
    profile: ComposerProfile = V1_PROFILE,
) -> PackageClaimObservation:
    """Observe manifest claims against an explicit selected-profile inventory.

    ``current_sha256`` may use ``None`` only to represent a target known absent.
    ``desired_sha256`` may use ``None`` only for selected optional targets. The
    observer validates every manifest entry but reads no managed asset file.
    """
    if not isinstance(agent_home, Root):
        raise PackageClaimError("require an explicit Root agent home")
    profile = _profile(profile)
    ownership = _ownership(declared_ownership, profile)
    current = _hashes(current_sha256, "current hashes", profile, allow_absent=True)
    desired = _hashes(desired_sha256, "desired hashes", profile, allow_absent=False)
    manifest_sha256, assets = _manifest(agent_home)
    claims = tuple(
        PackageClaim(target, ownership[target], current[target], desired[target], assets.get(target))
        for target in profile.targets
    )
    return PackageClaimObservation(
        package_version=PACKAGE_VERSION,
        manifest_schema_version=MANIFEST_SCHEMA_VERSION,
        manifest_sha256=manifest_sha256,
        claims=claims,
        conflicts=_canonical_conflicts(claims),
        profile_schema=profile.schema,
    )
