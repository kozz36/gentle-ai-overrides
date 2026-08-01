# Design: Rubric Compiler Foundation — Unit2C Consumer State Gate

## Technical Approach

Add a **fail-closed pre-resolution gate** to the shared apply/verify orchestration contract. Preserve accepted Units 1, 2A, and 2B serialization/activation behavior. The orchestrator reads canonical state, validates activation identity and independent read-back, then resolves once and forwards exactly one combined row plus its canonical model digest. Apply/verify consumers never classify or resolve independently.

    canonical surfaces → state gate → single rubric resolver → apply/verify
                              └── blocked error envelope

## Architecture Decisions

| Decision | Choice and rationale |
|---|---|
| Fail-closed authority | Gate before resolution. Missing, malformed, duplicate, `staging`, `recovery-required`, conflict, outage, or identity/read-back mismatch blocks; no fallback can hide an incomplete activation. |
| Mode contract | OpenSpec is its own authority; Engram uses only the exact canonical topic; hybrid requires both with OpenSpec authoritative; none accepts only an explicit current-session confirmed/verified envelope. This matches accepted activation ownership. |
| Legacy boundary | Binary `strict_tdd` applies only when neither `testing.policy: rubric` nor rubric canonical state has ever been declared/observed. Once observed, missing schema cannot fall back to root `strict_tdd` or rubric `default`. |
| Resolution ownership | One orchestrator resolver emits one effective row using existing all-row/strictest-wins/union semantics. Downstream consumers receive the resolved row and digest only, preventing host-specific drift. |
| Unit3 benchmark isolation | Fixed CNSIC/Gentle clone inputs are read-only. Repository-only checks prove provenance/safety without parity or oracle access. Post-confirmation CNSIC alone requires 16/16 identity rows and exact fixture bindings; snapshots enforce immutability. |

## Interfaces / Contracts

**OpenSpec**: when `testing.policy: rubric`, require exactly one managed, active/authoritative `testing.rubric` and its accepted `ResolutionV1 mode=openspec` receipt. Normalize these together as `state=active`, nonempty `txn_id`, `authority=openspec`, and `canonical_model_digest`; `backend_config_digest` must equal an independent digest of the live config. This preserves the accepted Unit2A serializer rather than inventing a second metadata shape.

**Engram**: look up exactly `sdd-init/{project}`. Require one `ActivationStateV1`, `state=active`, `authority=engram`, exact canonical-model digest/payload, and independent content read-back where lookup revision equals `committed_revision` and `backend_revision`. Version topics never substitute.

**Hybrid**: validate the OpenSpec contract plus exact `sdd-init/{project}` `ActivationStateV1` with `authority=openspec`. Both surfaces must be active, independently readable, and equal on `txn_id` and `canonical_model_digest`; every missing surface, outage, conflict, revision/content mismatch, or read-back failure blocks. No fallback.

**none**: no persistent active policy exists. Forward only an explicit in-session envelope binding confirmed rows to an `IntegratedValidationV1 state=verified` receipt and exact canonical model digest; otherwise block.

Successful forwarding uses one `RubricConsumerEnvelopeV1`: phase, txn ID, canonical model digest, and one resolved combined row (mode, disciplines, evidence-binding refs). Failure is exactly:

```yaml
schema: RubricConsumerGateErrorV1
status: blocked
phase: apply|verify
mode: openspec|engram|hybrid|none
backend: openspec|engram|both|session
reason: absent|malformed|duplicate|staging|recovery-required|conflict|outage|state-mismatch|txn-mismatch|model-mismatch|backend-mismatch|readback-invalid
observed: {state: scalar-or-none, txn_id: scalar-or-none, canonical_model_digest: digest-or-none, backend_revision: revision-or-none}
recovery_action: run sdd-init recovery
```

No secrets, canonical-model bytes, backend payload, or preimage bytes are included.

## Host and File Changes

| File | Action | Description |
|---|---|---|
| `deltas/rubric-tdd.md` | Modify | Canonical list/prose/cache wording for the gate and one resolved envelope. |
| `tests/rubric-consumer-gate.sh` | Create | Golden mode/state/error matrix and no-fallback assertions. |
| `tests/init-rubric-contract.sh` | Modify | Exact contract and shape parity checks. |
| `tests/rubric-compiler-benchmark.sh` | Create | Isolated read-only scorer and clone snapshots. |
| `tests/fixtures/rubric-compiler/benchmark/cnsic-oracle.tsv` | Create | Scorer-only 16-row oracle. |
| `tests/fixtures/rubric-compiler/benchmark/cnsic-confirmed.tsv` | Create | Confirmed identity input. |
| `tests/run.sh` | Modify | Wire focused suites, host goldens, and Unit3 scorer. |

Delivered surfaces are Claude Code’s lazy prose workflow; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity list prompts; and OpenCode JSON. Codex remains `rubric-none`. Kimi is not managed by this overlay and receives no scope expansion.

## Testing Strategy / Task Replan

Golden tests cover host semantics and the full state/error matrix. `tests/run.sh` also executes Unit3. Accepted proof: focused benchmark 5/5, regression 24/24, Bash syntax, ShellCheck including the scorer, diff checks, and equal clone snapshots.

Accepted Unit2C 3c.1/3c.2 rollback boundaries remain unchanged; Unit3 4.1–4.2 is complete.

## Threat Matrix

| Boundary | Applicability |
|---|---|
| Documentation-like paths | N/A — Unit2C does not classify paths; Unit3 reads fixed data and executes nothing from clones. |
| Git repository selection | Applicable — fixed clone roots are read-only. Missing baseline snapshots fail before scoring; existing 4.1–4.2 RED/proof compares pre/post HEAD, porcelain, and content snapshots. No new task is needed. |
| Commit state | N/A — no index/worktree operation. |
| Push state | N/A — no push operation. |
| PR commands | N/A — no PR automation. |

## Migration / Open Questions

No data migration. Previously observed rubric state lacking the required schema blocks until `run sdd-init recovery`. Unit3 4.1–4.2 is final scope only: external clones remain read-only, and pre-existing untracked `.rubric-eval`/`.codegraph` surfaces must remain unchanged with pre/post evidence. Work-unit/#262 enforcement, HOME apply, upstream integration, commits, PRs, and releases remain out of scope. Open questions: none.
