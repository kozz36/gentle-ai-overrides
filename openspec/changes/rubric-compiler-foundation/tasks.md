# Tasks: Rubric Compiler Foundation

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | 430–620 total; each Unit2C slice 190–310 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | 3c.1 → 3c.2 |
| Delivery strategy | auto-chain |
| Chain strategy | feature-branch-chain |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

| Unit (base; estimate) | Focused test | Runtime harness | Rollback boundary |
|---|---|---|---|
| 3c.1 (tracker; 190–310) | `bash tests/rubric-consumer-gate.sh` | invoke apply/verify gate fixtures for each mode and blocked/recovered state | `tests/rubric-consumer-gate.sh` and state-gate block in `deltas/sdd-init-rubric.md` |
| 3c.2 (3c.1; 190–310) | `bash tests/init-rubric-contract.sh` | `bash tests/run.sh` validates managed-host list/prose/JSON goldens | `deltas/rubric-tdd.md`, `tests/init-rubric-contract.sh`, and `tests/run.sh` wiring |

## Phase 1: Unit 1A (accepted)
- [x] 1.1–1.5 RED/GREEN structural validation, mode, confinement, root-workdir, and scalar safety.

## Phase 2: Unit 1B (accepted)
- [x] 2a.1–2e.2 detached canonical records, replay, reconstruction, and publication foundations.

## Phase 3: Unit 2A (accepted)
- [x] 3a.1–3a.5 canonical model, integrated validation, OpenSpec transaction, and serializer.

## Phase 4: Unit 2B — Engram / Hybrid Recovery (accepted)
- [x] 3b.1–3b.4b Engram canonical CAS, hybrid forward journal, compensation/replay, and terminal recovery.

## Phase 5: Unit 2C — Consumer State Gate
- [x] 3c.1a RED: create `tests/rubric-consumer-gate.sh` fixtures for OpenSpec, Engram, hybrid, none, and legacy; assert exact blocked envelope for absent, malformed, duplicate, staging, recovery-required, conflict, outage, transaction/model/backend/read-back mismatch; assert equivalent active success, no fallback, and one resolution owner.
- [x] 3c.1b GREEN: add the fail-closed pre-resolution gate to `deltas/sdd-init-rubric.md`; emit only `RubricConsumerEnvelopeV1` or the specified redacted error, preserve legacy only when rubric was never observed, and prove recovery resumes consumption.
- [x] 3c.2a RED: extend `tests/init-rubric-contract.sh` with exact list, prose, and OpenCode JSON goldens for every managed host, including Claude lazy prose and Pi; assert consumer-envelope wording and forbidden fallback text; assert Kimi is explicitly current-scope unmanaged.
- [x] 3c.2b GREEN: update `deltas/rubric-tdd.md` canonical managed-host wording and `tests/run.sh` to execute both focused suites; make every golden and top-level run green without expanding Kimi scope.

## Phase 6: Unit 3 — Benchmarks and Regression (pending)
- [x] 4.1–4.2 isolated benchmarks, regression wiring, and ShellCheck.
