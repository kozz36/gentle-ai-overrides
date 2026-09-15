"""Read-only package-claim evidence preparation, never application authority."""
from collections.abc import Mapping
from dataclasses import dataclass

from .bundle import TARGETS
from .package_claims import (
    PackageClaimError,
    PackageClaimObservation,
    observe_package_claims,
)
from .snapshot import CapturedSnapshot, capture_snapshot
from .storage import Root


@dataclass(frozen=True)
class PackageClaimPreparation:
    """Immutable snapshot and package-claim observation from one supplied Root."""

    snapshot: CapturedSnapshot
    observation: PackageClaimObservation


def prepare_package_claim_evidence(
        agent_home: Root, *, declared_ownership: Mapping[str, str],
        desired_sha256: Mapping[str, str]) -> PackageClaimPreparation:
    """Capture fourteen targets, then observe package claims without writing.

    The supplied Root is mandatory; this function neither discovers a home nor
    infers ownership. Valid mappings are shallow-copied before I/O, so later read
    callbacks cannot split their evidence; copying itself is not atomic against
    concurrent caller mutation. ``capture_snapshot`` validates ownership before
    target reads. Its sequential reads finish before current hashes are derived
    and passed to ``observe_package_claims``, which validates desired hashes before
    reading the manifest. The two read phases are not an atomic cross-file
    snapshot or a freshness/trust/install authority. A future apply must recheck.
    """
    if not isinstance(agent_home, Root):
        raise PackageClaimError("require an explicit Root agent home")
    if not isinstance(declared_ownership, Mapping):
        capture_snapshot(agent_home, declared_ownership=declared_ownership)
    if not isinstance(desired_sha256, Mapping):
        raise PackageClaimError("require an explicit desired hashes mapping")
    ownership = dict(declared_ownership)
    desired = dict(desired_sha256)
    snapshot = capture_snapshot(agent_home, declared_ownership=ownership)
    entries = snapshot.entries
    current_sha256 = {
        target: entries[target]["sha256"] if entries[target] is not None else None
        for target in TARGETS
    }
    observation = observe_package_claims(
        agent_home,
        declared_ownership=ownership,
        current_sha256=current_sha256,
        desired_sha256=desired,
    )
    return PackageClaimPreparation(snapshot=snapshot, observation=observation)
