"""Byte snapshots with explicit declared ownership, never native authority."""
from collections.abc import Mapping
from dataclasses import dataclass
import hashlib
import json

from .agents import _header, _text
from .bundle import TARGETS, require_keys
from .planner import OWNERS
from .storage import MAX_BYTES, Root


class SnapshotError(ValueError):
    """Declarations or the serialized snapshot exceed the supported contract."""


@dataclass(frozen=True)
class CapturedSnapshot:
    """Detached serialized observations, not a baseline approval or file lease."""

    payload: bytes
    digest: str

    @property
    def entries(self):
        """Return a fresh mapping; mutations cannot affect the captured bytes."""
        return json.loads(self.payload)["entries"]


def capture_snapshot(root: Root, *, declared_ownership: Mapping[str, str]) -> CapturedSnapshot:
    """Read fourteen targets without writing or inferring ownership.

    Ownership is supplied metadata, not native discovery. Missing files stay
    absent. Other IO/parser failures propagate without returning partial evidence.
    Reads are sequential: this is not an atomic snapshot, a filesystem identity,
    or a freshness guarantee. Before application, the caller must validate native
    ownership/conflicts, bind the destination, and recheck all confirmed preimages.
    No baseline is approved and no installed write is authorized by this result.
    """
    if not isinstance(declared_ownership, Mapping):
        raise SnapshotError("require an explicit ownership mapping")
    owners = dict(declared_ownership)
    require_keys(owners, TARGETS)
    if any(not isinstance(owner, str) or owner not in OWNERS for owner in owners.values()):
        raise SnapshotError("unsupported declared ownership")
    entries = {}
    for target in TARGETS:
        try:
            content = root.read(target)
        except FileNotFoundError:
            entries[target] = None
            continue
        tools = _header(_text(content))[2] if target.startswith("agents/") else None
        entries[target] = {"sha256": hashlib.sha256(content).hexdigest(),
                           "tools": tools, "ownership": owners[target]}
    payload = json.dumps({"schema": "asset-snapshot/v1", "entries": entries}, sort_keys=True,
                         separators=(",", ":"), allow_nan=False).encode("utf-8")
    if len(payload) > MAX_BYTES:
        raise SnapshotError("snapshot exceeds the byte limit")
    return CapturedSnapshot(payload, hashlib.sha256(payload).hexdigest())
