# Composer 3.2 overlay release tasks

## Goal

Prepare a local `v3.2.0-overlay.1` release candidate whose deterministic composer can model the workflow-neutral `gentle-init` migration without changing the historical v1 composer contract or acquiring install, approval, publication, or HOME-discovery authority.

## User decisions

- Migrate the composer now rather than shipping it as deferred.
- Prepare and tag the release locally only. Do not push or create a GitHub Release.
- Keep the Gentle Shell PR chain as a follow-up until issue #59 is approved.

## Scope

- Preserve `deterministic-assets/v1` and its fourteen historical candidates byte-for-byte.
- Add an explicit v2 profile/inventory for the four package-owned Pi transaction surfaces:
  - `assets/agents/gentle-init.md`
  - `assets/agents/sdd-init.md`
  - `assets/sdd-orchestrator-workflow.md`
  - optional `assets/orchestrator-delegation.md`
- Keep `orchestrator-memory.md` out of the migration unless implementation evidence proves that `apply.sh` modifies it; it is not one of the current four transaction surfaces.
- Distinguish upstream `gentle-pi` version `3.2.0` from overlay release `3.2.0-overlay.1` in provenance.
- Keep the composer candidate-only and rooted only in explicit pinned inputs/outputs.

## Non-goals

- No live HOME synchronization or `gentle-ai sync`.
- No ownership inference or automatic managed-assets repair.
- No package installation or mutation by the composer.
- No push, GitHub Release, npm publication, or upstream PR publication.
- No rewrite of historical SDD agent routing/tool preferences.

## Tasks

- [x] C32-001 Define a schema-versioned target/profile contract that preserves v1 exactly and represents the four package assets explicitly, including optional delegation without fabricated bytes.
- [x] C32-002 Implement pure fail-closed candidate transforms for `gentle-init`, legacy `sdd-init` retirement, workflow forwarding, and optional delegation forwarding, with behavior-first tests.
- [ ] C32-003 Propagate the selected inventory through snapshot, package-claim preparation, confirmation, and CLI evidence without granting application authority.
- [ ] C32-004 Update composer documentation and release provenance; remove statements that incorrectly call the composer migration deferred for this release.
- [ ] C32-005 Run focused tests under normal Python and `python3 -O`, full overlay verification, independent verification, native review, then create local annotated tag `v3.2.0-overlay.1` only if every gate passes.

## Acceptance criteria

- V1 reproduces the existing fourteen-candidate contract and fixtures unchanged.
- V2 accepts only its exact declared target profile and rejects missing, extra, ambiguous, partially marked, or unpinned assets.
- The four Pi surfaces align with the current `apply.sh` transaction; no fifth surface is claimed without evidence.
- Optional delegation absence is explicit and does not create a file.
- Evidence and confirmation bind the same schema-selected inventory throughout.
- Provenance identifies `gentle-pi` as `3.2.0` and the overlay as `3.2.0-overlay.1`.
- Composer output remains candidate-only; application and approval stay external.
- Active overlay behavior remains `./apply.sh --check` exit 0 against the isolated local package.
- No tag is created before verification and native review close.

## Evidence

- Exploration found current v1 inventory in `composer.bundle.TARGETS`, package claim source version `2.7.0`, and fixed fourteen-target assumptions across bundle, snapshot, preparation, confirmation, CLI, and tests.
- Current `apply.sh` transaction resolves exactly `gentle-init`, `sdd-init`, workflow, and optional delegation under one selected package root.
- Active package is `gentle-pi 3.2.0` with embedded Gentle AI `3.1.0`.
- C32-001 added immutable v1/v2 profile inventories while leaving v2 composition inactive. Independent verification passed 13/13 tests under normal Python and 13/13 under `python3 -O`; `git diff --check` passed. The exact v1 inventory remains 14 targets, v2 is 18 targets with only delegation optional, and `orchestrator-memory.md` is absent. Commit: `c700546`.
- C32-002 added explicit byte-only candidate transforms for all four reviewed transaction surfaces while keeping optional delegation absence/non-applicability explicit. Agent transforms passed 16/16 tests under normal and optimized Python and closed native review `review-9fc5fca85b168746`; commit `5f19fba`. Routing transforms passed 10/10 tests under both modes and closed native review `review-dd42d1b1d97ea982`; commit `e23263b`. Both slices preserve current/predecessor recognition, fail closed on unrecognized managed content, and keep filesystem/HOME/application authority outside the composer.
