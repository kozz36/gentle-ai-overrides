# gentle-init overlay migration

## Objective

Make the overlay transition Pi from the legacy `sdd-init` policy producer to the future package-owned `gentle-init` asset without creating unowned agents, deleting customized content, or moving neutral consumer wording ahead of producer availability.

## Problem

The current overlay injects project-policy production into `sdd-init`, while the approved upstream design assigns candidate authorship to read-only `gentle-init` and exact publication to the parent. Published npm `gentle-pi@3.1.1` does not yet contain `assets/agents/gentle-init.md`.

## Scope

- Pi-first migration only; retain explicitly documented legacy non-Pi `sdd-init` producers until those hosts expose official neutral surfaces.
- Capability-gate all Pi migration on an existing regular upstream `assets/agents/gentle-init.md` with expected anchors.
- Never create a global/package agent or fall back to another target.
- Add only the overlay-specific rubric semantics missing upstream.
- Retire the exact historical Pi-owned `sdd-init` marker only when the future neutral target is valid and the legacy block is byte-recognized; unknown/partial/duplicate/custom blocks fail closed.
- Keep current npm 3.1.1 untouched and operational.
- Defer composer target-schema migration.

## Constraints

- Preserve the upstream boundary: `gentle-init` authors exact candidate bytes with read-only tools; parent materializes/checksums/presents/publishes exact bytes after approval.
- Do not duplicate approval, persistence, readback, or legacy migration rules inside the overlay payload.
- Preserve the approved project rubric semantics: satisfiable evidence proof, intent-qualified catalog, scoped bindings, MODE ordering, selective default, strictest-wins, and manual-row preservation.
- Consumer wording becomes neutral only when the Pi producer migration is reachable; no all-host claim.
- `APPEND_SYSTEM.md` remains outside direct overlay handling.
- No global apply/install/sync in this work unit.

## Testing policy

- MODE: `standard`.
- Canonical source: project Engram rubric `sdd/gentle-ai-overrides/testing-capabilities` (active/authoritative).
- Exact unit command: `bash tests/run.sh`.
- Exact lint command: `shellcheck --severity=warning apply.sh tests/run.sh`.
- Test-first ordering is not mandatory; regression evidence and lint are mandatory.

## Tasks

- [x] GIO-001 Map upstream neutral contract and current overlay contradiction.
- [x] GIO-002 Implement capability-gated Pi target resolution and transactional migration.
- [x] GIO-003 Extract Pi-specific neutral rubric payload and update consumer shapes.
- [x] GIO-004 Add hermetic compatibility, refusal, idempotence, selected-root, and ownership tests.
  - [x] GIO-004 Pi capability/transaction sub-slice: current-package apply/check unsupported no-op; future insertion; exact legacy retirement; anchor/marker refusals; selected-root and unsafe-target coverage; injected paired failure/rollback recovery and no-final-newline byte-preservation coverage.
- [x] GIO-005 Update README with Pi-first/legacy-host matrix and release gate.
- [x] GIO-006 Run unit, static-contract, lint, and diff checks; obtain independent verification.
- [ ] GIO-007 Native-review the overlay candidate.
- [ ] GIO-008 Apply globally only after an official package release ships `gentle-init`; until then check-only must report safe unsupported/no-op behavior.

## Acceptance criteria

1. Current npm 3.1.1 fixture without `gentle-init` causes no Pi write, no legacy removal, and no created agent.
2. Future clean package inserts exactly one `gentle-ai:gentle-init-rubric` block before the upstream publication boundary.
3. Future package with the exact historical Pi block migrates transactionally: neutral block inserted and exact old block removed; second apply is byte-idempotent.
4. Unknown, partial, duplicate, customized legacy block or changed neutral anchor modifies neither target.
5. Upstream candidate-author/parent-publisher instructions remain byte-identical outside the overlay-owned marker.
6. All consumer shapes refer to the neutral project-policy authority without claiming unsupported non-Pi migration.
7. Overlay payload contains rubric semantics only and grants no publication/approval authority.
8. Composer remains unchanged and documented as deferred.
9. Required tests and lint pass with zero candidate-introduced diagnostics.

## Checks

- `bash tests/init-rubric-contract.sh`
- `bash tests/rubric-consumer-gate.sh`
- `bash tests/run.sh`
- `shellcheck --severity=warning apply.sh tests/run.sh`
- `git diff --check`

## Progress

- 2026-09-17: Upstream `gentle-init` candidate approved under native review lineage `review-85271c84f6784bcc`.
- 2026-09-17: User selected Pi-first migration; non-Pi integrations retain legacy producers until official neutral surfaces exist.
- 2026-09-17: Dedicated worktree `feat/gentle-init-overlay` created from overlay commit `9ec8d50`.
- 2026-09-17: GIO-002 and the Pi capability/transaction sub-slice of GIO-004 passed `bash -n apply.sh`, `bash tests/init-rubric-contract.sh`, and `bash tests/run.sh`.
- 2026-09-17: Independent-verification correction added injected pair backup/rename/rollback failure coverage, byte-preserving no-final-newline transforms, current-package apply no-op coverage, and a zero-diagnostic ShellCheck pass.
- 2026-09-17: Final hardening distinguishes backup-only recovery allocation failure from a verified retained recovery artifact, gates fault injection behind explicit test mode, and reports missing/unusable Python byte-transform capability without mutation.
- 2026-09-17: GIO-003 through GIO-005 added the distinct neutral Pi candidate payload, capability-gated coherent consumer migration, semantic/ownership regressions, and the Pi-first release-gate documentation; 74 run-suite checks, 10 static-contract checks, and 5 consumer-gate checks passed.
- 2026-09-17: GIO-008 HIGH-blocker correction: future Pi migration is now one selected-root four-surface transaction (`gentle-init`, historic `sdd-init`, SDD workflow, ODD delegation). Complete preflight builds all candidates before any backup; check reports pending/no-op/refusal without writes; apply backs up every changing target before the first rename and compensates all replaced targets on handled operational failure. Regression evidence: 65 run-suite checks, 10 static-contract checks, and 6 consumer-gate checks passed; ShellCheck and diff checks were clean. GIO-006 remains unchecked pending independent verification.
- 2026-09-17: GIO-008 follow-up: root confinement now rejects symlinked asset parents, optional ODD absence remains n/a, all present snapshots are revalidated through replacement, and consumer predecessor sentinels fail closed. GIO-006 remains unchecked pending the required verification receipt.
- 2026-09-17: Final bounded GI-008 correction: workflow/delegation transforms preserve terminal-newline state; advisory package-asset traversal is confined before inventory/hash; early and final drift cleanup removes invalid artifacts and reports only verified recovery paths or backup-only subsets. Restored forwarding invariants and mutation rejection passed. GIO-006 remains unchecked pending the required verification receipt.
- 2026-09-17: Fresh-verifier correction: package metadata, registry directories/leaves, and advisory assets are confined before parser/hash access; Pi workflow/ODD marker blocks require exact current or stored HEAD bytes; grouped expected outputs use an independent oracle; recovery reports list only verified paths and distinguish untouched concurrent drift. Corpus skips are counted separately. GIO-006 remains unchecked pending the required verification receipt.
- 2026-09-17: Final minimal GI-008 correction: the workflow managed gap now rejects unmarked nonblank bytes before either insertion or recognized-block replacement while preserving valid blank/tab gaps; handled rc5 final drift now reports verified backups plus the untouched-participant category without inventing artifacts; local-source documentation distinguishes lexical HOME selection from canonical-root confinement. `bash tests/run.sh` passed 78 scenarios and 8 aggregate commands (84 passed, 0 failed, 2 corpus skips); static-contract 10/0, consumer-gate 7/0, ShellCheck, syntax, and diff checks passed.
- 2026-09-17: Independent final verification returned unconditional PASS with the same totals, stable candidate hashes, unchanged composer/historical Pi payload, and no remaining HIGH findings. GIO-006 is complete.

## Review strategy

The forecast is 515–715 authored lines. Keep implementation as reviewable work units and do not combine it with the upstream package candidate or the later global 3.1.1 installation.

## Rollback boundary

Remove the future-asset resolver/transform, neutral payload, consumer wording, tests, and documentation added by this branch. Preserve the existing legacy non-Pi producers and the prior ODD forwarding commit.

## Key Learnings — closed

- Capability gating alone did not establish coherence: the selected package's four sibling assets need one candidate-build, backup, replacement, and compensation boundary.
- Exact immediate-HEAD list, prose, and cache forms must be recognized as complete payloads; loose deletion can duplicate or overwrite custom consumer content.
- Covered transaction states are current-package no-op, future pending/apply/idempotence, anchor/marker/custom refusal before backup, workflow/delegation backup and rename compensation, early staged-snapshot cleanup, unchanged-participant final drift, recovery-copy failure with only existing byte-matched backups reported, and only byte-verified mixed-target recovery artifacts. Crash/power-loss during replacement, filesystem loss after backup, journal-based recovery, and the residual compare-to-rename TOCTOU window remain intentionally unsupported.
- Read confinement is enforced before package JSON parsing, registry enumeration/leaf parsing, and advisory hashing; symlinks inside the resolved selected root are unsafe, while canonical selection may traverse a parent symlink above that root.
- Consumer refresh is intentionally exact-byte recognition, not marker detection: current and stored predecessor blocks upgrade; custom, partial, duplicate, and truncated marker regions refuse without a backup or write.
- The workflow's managed structural gap is validated identically before marker insertion and recognized-marker replacement: blank/tab padding is preserved, while unmarked nonblank content refuses before output, backups, or staging.
