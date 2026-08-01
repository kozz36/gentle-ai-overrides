---
schema: human-semantic-evaluation/v1
subject: "CNSIC fourth task-intent-baseline blind sdd-init experiment"
status: needs-human-approval
recommendation: revise
confidence: high
artifact_freshness: fresh-source-bound
---

# CNSIC Task-Intent Baseline Evaluation

## Source Bindings

| Role | Binding |
| --- | --- |
| Candidate | `sha256:af00ca093c2e49c6ec05c3fea20a0efffcfbc294dcb59d3e1a4c1527c8691a6f` |
| Result | `sha256:a8ee263b7cd85548c82462d8979786f6cf61ddb940c790d4d18db77bd662269c` |
| Manifest companion | `sha256:2ba5520823981fbf24665453d889c30434cef611bd9fa71c1b0eb4368bca5ff3` |
| Root policy | `sha256:90c1131f19208737262a5283dd316d564809809a2717b242811e4dfc673782c6` |

## Evaluation Dimensions

| Dimension | Assessment | Uncertainty |
| --- | --- | --- |
| Implementation mode fidelity | Selective intent rows avoid broad strict matching. | UI strict mode conflicts with canonical non-unit-TDD. |
| Test-authoring discipline/forwarding fidelity | Behavior, bug, security, migration use strict workflow. | RBAC/cross-context/tool/egress special rules absent. |
| Functional validation evidence | Scoped IDs and workdirs are explicit. | `b-unit` is CI pytest, not reusable wrapper harness. |
| Visual/E2E validation evidence | No false Playwright claim. | Tracked Playwright proof is omitted; UI visible validation is conditional only. |
| Command/harness fidelity | Frontend workdirs and CI platforms are explicit. | `b-smoke` lacks Docker `--build`; `b-unit` lacks mutex/env/mount semantics. |
| Work-type coverage | 13 visible rows and separate default improve V3. | No integration binding; omission is not justified for all API/security/migration cases. |
| Multi-match resolution | Simulation covers overlap and rejects incompatible intent. | Runtime simulation is projection, not executed compiler behavior. |
| Coverage and other evidence | No unrelated bindings are borrowed. | Schema closure does not prove canonical completeness. |
| Fail-closed uncertainty | Pending compiler block prevents activation. | Destination has no `.git`; hashes bind evidence but cannot prove clone immutability. |
| Orchestrator forwarding behavior | No active YAML/ResolutionV1 claim. | End-to-end compiler/activation remains unproven. |
| Project-specific policy gaps | Generic baseline is selective. | Canonical project-specific triggers remain incomplete. |

## Similarities

- One visible docs skip row and a separate unmatched standard default are correct.
- Intent-first selectivity avoids making all work strict.

## Differences

- V4 improves V3 semantic richness and binding context while retaining V3 fail-closed handoff.
- It omits Playwright and integration bindings despite relevant tracked evidence and lacks canonical special-case policies.

## Behavioral Impact

Safety verdict: pass. Selectivity verdict: pass. Semantic richness verdict:
revise. Binding executability verdict: revise. Usability verdict: not activatable
until the compiler produces and verifies `ResolutionV1`.

## Unsupported Or Missing Claims

- Do not claim CI `b-unit` satisfies local wrapper/mutex/env/cap/build rules.
- Do not claim `b-smoke` is Docker smoke --build.
- Do not claim the non-git destination is immutable.

## Recommendation

`revise` with high confidence for candidate policy. Preserve the safety handoff;
add project-specific canonical triggers, executable harness semantics, and justified
integration/Playwright coverage before seeking activation.

## Maintainer Decision

decision: pending
decision_authority: maintainer
