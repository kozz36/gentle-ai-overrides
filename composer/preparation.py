"""Read-only package-claim evidence preparation, never application authority."""
from collections.abc import Mapping
from dataclasses import dataclass

from .bundle import BundleError, require_keys
from .package_claims import (
    PackageClaimError,
    PackageClaimObservation,
    observe_package_claims,
)
from .profiles import ComposerProfile, ProfileError, V1_PROFILE, profile_for_schema
from .snapshot import CapturedSnapshot, capture_snapshot
from .storage import Root


@dataclass(frozen=True)
class PackageClaimPreparation:
    """Immutable snapshot and package-claim observation from one supplied Root."""

    snapshot: CapturedSnapshot
    observation: PackageClaimObservation


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


def _mapping(value, name, profile):
    if not isinstance(value, Mapping):
        raise PackageClaimError(f"require an explicit {name} mapping")
    result = dict(value)
    try:
        require_keys(result, profile.targets)
    except BundleError as exc:
        raise PackageClaimError(f"require exactly the selected {name} targets") from exc
    return result


def prepare_package_claim_evidence(
        agent_home: Root, *, declared_ownership: Mapping[str, str],
        desired_sha256: Mapping[str, str | None], profile: ComposerProfile = V1_PROFILE,
) -> PackageClaimPreparation:
    """Capture one selected profile's targets, then observe package claims without writing.

    The supplied Root is mandatory; this function neither discovers a home nor
    infers ownership. Valid mappings are shallow-copied before I/O, so later read
    callbacks cannot split their evidence; copying itself is not atomic against
    concurrent caller mutation. Profile-selected mapping keys are validated before
    I/O; ``capture_snapshot`` validates ownership before target reads. Its
    sequential reads finish before current hashes are derived
    and passed to ``observe_package_claims``, which validates desired hashes before
    reading the manifest. The two read phases are not an atomic cross-file
    snapshot or a freshness/trust/install authority. A future apply must recheck.
    """
    if not isinstance(agent_home, Root):
        raise PackageClaimError("require an explicit Root agent home")
    profile = _profile(profile)
    if not isinstance(declared_ownership, Mapping):
        capture_snapshot(agent_home, declared_ownership=declared_ownership, profile=profile)
    ownership = _mapping(declared_ownership, "ownership", profile)
    desired = _mapping(desired_sha256, "desired hashes", profile)
    snapshot = capture_snapshot(agent_home, declared_ownership=ownership, profile=profile)
    entries = snapshot.entries
    current_sha256 = {
        target: entries[target]["sha256"] if entries[target] is not None else None
        for target in profile.targets
    }
    observation = observe_package_claims(
        agent_home,
        declared_ownership=ownership,
        current_sha256=current_sha256,
        desired_sha256=desired,
        profile=profile,
    )
    return PackageClaimPreparation(snapshot=snapshot, observation=observation)
