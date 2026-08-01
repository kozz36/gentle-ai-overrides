# Proposal: Rubric Compiler Foundation

## Intent

`sdd-init` needs a fail-closed repository-to-rubric path. One-pass conflates evidence/policy, causing unsupported claims; staged inference, validation, and activation separate them.

## Scope

### In Scope
- Versioned evidence-extraction contract/normalized-facts schema covering sources, commands/methods, signatures/scopes, environment/dependencies, tool proof, provenance, unknown/unsatisfied states.
- Fact-linked candidate rows/questions for repository-silent policy.
- Deterministic validator: schema, bindings, runnability, provenance, conflicts, defaults, resolution.
- Row/question confirmation precedes atomic activation; re-init preserves unchanged manual rows, reconfirming only stale/conflicting evidence.
- `staging|recovery-required` MUST block apply/verify until `sdd-init` restores/commits; activation safety only—not work-unit resolution or #262 evidence enforcement.
- Isolated CNSIC/Gentle AI benchmark scoring.

### Out of Scope
- Universal ecosystem parsing; work-unit resolution; issue #262 enforcement; upstream integration; gentle-pi; installer/state changes; public CLI; active-HOME changes; benchmark-clone mutation.

## Capabilities

### New Capabilities
- `rubric-compiler`: Evidence/facts, candidates/questions, validation, confirmation/re-init, mode-specific activation, isolated scoring.

### Modified Capabilities
- None.

## Approach

Pipeline: extract→normalize→propose→validate→confirm→revalidate→activate. `sdd-init` is the first consumer. Missing repository-silent policy or invalid/unresolved rows yield candidate/questions without active writes. Modes: `openspec` atomically activates the policy file; `engram` activates/revises canonical `sdd-init/{project}` with revision recovery; `hybrid` uses compensated OpenSpec-authoritative activation, mirrors that canonical topic, and applies the state gate; `none` returns inline candidates/questions without activation. Version observations MAY aid rollback but MUST NOT replace the canonical topic. CNSIC policy is scorer-only and never generator input.

## Affected Areas

| Area | Impact | Description |
|---|---|---|
| `deltas/sdd-init-rubric.md` | Modified | Internal contract; no public CLI. |
| `deltas/rubric-tdd.md` | Modified | Consumer activation-state gate only. |
| Design-selected compiler/test assets | New | Contracts, fixtures, isolated benchmarks. |
| `openspec/config.yaml` / `sdd-init/{project}` | Modified | Authority, canonical mirror, atomic versions. |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Evidence absence becomes policy | High | Preserve unknowns; block activation. |
| Oracle leakage | Medium | Scorer-only isolation. |
| Row drift | Medium | Stable IDs/versions; selective reconfirmation. |

## Rollback Plan

Discard foundation assets/candidates. Restore prior OpenSpec policy atomically; hybrid remirrors to `sdd-init/{project}`.

## Dependencies

- Exploration, rubric semantics, read-only benchmark fixtures.

## Success Criteria

- [ ] Repository-only CNSIC/Gentle AI: zero unsupported claims, 100% claim provenance, and recall/exact-policy reported without threshold.
- [ ] Validator fixtures are deterministic, reject all seeded invalid/unresolved rubrics, and prove the state gate; no partial activation.
- [ ] Gentle AI establishes a deterministic safety/provenance baseline without artificial parity.
- [ ] After confirmation/manual answers, CNSIC reaches semantic 1:1: 16/16 signatures, 16/16 policies, and exact set equality against all canonical binding identities explicitly enumerated by the scorer-only oracle fixture; no denominator applies before fixture definition.
- [ ] Every mode satisfies its activation contract; activation preserves manual rows and equivalent hybrid stores.
