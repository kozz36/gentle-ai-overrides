# Deterministic asset candidates

**Candidate-only implementation:** Python 3.9+ standard library on POSIX. No LLM,
network, installer, native ownership discovery, or live application is invoked.
An actual CLI replay reproduced all fourteen approved maintenance outputs from
pinned sources and private snapshots. This does not certify future upstream
versions, fresh native ownership, or an installed SDD runtime.

## Run

From the repository root, supply existing **absolute, symlink-free** input paths
and a **nonexistent** output path outside every input root:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m composer \
  --input "$BUNDLE" --manifest-sha256 "$REVIEWED_MANIFEST_SHA256" \
  --installed "$INSTALLED_SNAPSHOT" --claims-home "$CLAIMS_HOME" \
  --baseline "$APPROVED_BASELINE" --output "$NEW_PRIVATE_OUTPUT"
```

Set those variables explicitly. `--claims-home` is required: it is a supplied,
read-only evidence root, never fallback discovery of an installed or home path.
Its fourteen captured entries must exactly match `--installed`'s validated
`state.json` entries before any output exists. On systems where `/tmp` is a
symlink, use its physical path. `--baseline` is optional: without it, matching
content needs no write, but any proposed update is blocked. No baseline is
created automatically.

| Exit | Meaning |
| --- | --- |
| 0 | Candidates and plan written; rows are no-op or proposed, **not approved** |
| 2 | Candidates and plan written with blocking conflicts; do not apply |
| 3 | Invalid input or I/O failure; any partial output is retained, not resumed |

An existing output is never overwritten. Candidate files are private (`0600`)
inside a private root (`0700`). Hash readbacks precede writing `plan.json` last.
Its presence alone is not approval or proof of a successful process exit.

## Explicit input contracts

The complete synthetic example is `tests/test_composer_bundle.py:fixture`.
It is test data, not an approved production profile. Production bundles and
snapshots must remain private; do not commit raw HOME configuration or secrets.

- `bundle.json`: schema `deterministic-assets/v1`; `versions` names `gentle_ai`,
  `gentle_pi`, and `overlay`; `overlay_revision` is a full commit identifier;
  `rules` selects `pi-init-before-memory/v1` and `pi-agent-preferences/v1`.
- `blocks`: maps `init`, `codegraph`, and `mcp` to SHA-256 pins for
  `blocks/<name>.md`. Supply complete, individually wrapped managed blocks.
- `assets`: exactly the fourteen keys listed by `composer.bundle.TARGETS`.
  Each entry has `source_sha256` for `sources/<target>` and `preferences`.
- Agent preferences contain `expected_source_tools`, `model`, `thinking`, `mcp`.
  Supply twelve confirmed routing pairs; research has null model/thinking.
  `expected_source_tools` is the previously confirmed contract, not a list to
  blindly regenerate from changed upstream permissions. Chain preferences are null.
- Source bodies must be pristine official inputs. Previously patched init or
  managed CodeGraph source blocks are rejected. Hashes prove local integrity,
  not upstream authenticity; version labels do not establish provenance alone.

The installed and optional baseline roots use `state.json`, schema
`asset-snapshot/v1`, with `entries` covering the same fourteen targets. An entry
is null only when its file is absent; otherwise it contains `sha256`, `ownership`,
and `tools`, with bytes at `<target>`. Ownership is `user-owned`, `managed`, or
`unknown`; tools are an exact list for agents and null for the chain. Content
hashes and tool metadata are checked. Ownership labels and prior approval are
supplied observations, not independently discovered native authority. Use a
genuinely verified prior snapshot as baseline.

## Package-claim evidence

`--claims-home` is a required explicit descriptor-anchored `Root`. The CLI takes
its declared ownership from each installed entry; an absent installed target is
explicitly `unknown`, never `managed`. It sequentially captures the same fourteen
targets, then reads `gentle-ai/managed-assets.json`. This root is evidence only:
it does not need a live installation and grants neither ownership nor authority.

The plan preserves two different pins. `installed_snapshot_sha256` hashes the
raw supplied `state.json`; `package_claim_snapshot_sha256` hashes the canonical
sequential capture from `--claims-home`. They have different meanings and must
not be equated, even if their text happened to match. The serialized
`package_claims` observation is from that same capture. A missing manifest is a
valid required observation; an empty manifest has its own non-null manifest hash.
Neither form grants a claim or ownership.

A current, stale, desired-hash reattachment, or ownership contradiction in the
manifest makes `package_claims.conflicts` nonempty. The CLI still emits diagnostic
candidates and `plan.json`, sets `blocked: true`, and returns exit 2 even when all
per-target rows are otherwise no-op or proposed.

## Confirmation preview

`prepare_confirmation` requires an explicit `PackageClaimPreparation`. Its canonical
captured entries must exactly match the supplied installed entries; the plan must carry
the matching canonical `package_claims` evidence and its `package_claim_snapshot_sha256`.
That pin remains separate from the raw `installed_snapshot_sha256`; missing, malformed,
mismatched, or conflicting evidence rejects the preview.

A preview is not consent or apply authority. It performs no live freshness, authenticity,
ownership, destination, or approval checks; a future operation must establish those checks.

## Review and limitations

The plan records provenance, both snapshot pins, package claims, per-target B/I/N
hashes, ownership, actions, and diffs. Ownership/tool conflicts precede byte
equality; manual drift is never overwritten. It is candidate-only preview, not
consent or an apply authorization; applying remains a separate approved operation.

No automatic rollback, source repair, capability inference, semantic merging, or
authentication exists. I/O rejects links and oversized files; reads are sequential,
nonfresh, and non-atomic, and this is not a hostile same-UID sandbox. Unsupported
YAML/frontmatter stops rather than being approximated. A semantic conflict may
receive a separately reviewed assisted proposal, never an automatic LLM fallback.
See the [proposal](../docs/proposals/deterministic-asset-composer.md).
