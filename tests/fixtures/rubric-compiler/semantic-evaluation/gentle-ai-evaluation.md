---
schema: human-semantic-evaluation/v1
subject: "Gentle AI observed rubric generator output"
status: needs-human-approval
recommendation: revise
confidence: medium
artifact_freshness: stale-unbound
---

# Gentle AI Semantic Evaluation

This evaluates the observed candidate against repository evidence. There is no
canonical reference init for Gentle AI. The candidate is treated as an unbound
observed artifact, not as a freshly executed generator result.

## Source Bindings

| Role | Read-only source | Binding |
| --- | --- | --- |
| Repository | `/home/kozz36/gentle-ai-upstream-986-review` | `HEAD: ffbcc12fad5594a7c5186614341d490f0440c110` |
| Observed generator artifact | `.rubric-eval/candidate-v2.yaml` | `sha256:d2cc840d1b2946beb40836c01f79196a35e9bae3a342675a7fbdd05d98ea4564` |
| Existing policy | `openspec/config.yaml` | `sha256:7e49a1730230123aef1b82f463b67c3843e77c3b94d13aeecf1ddd1065c7e0bf` |
| Contributor test policy | `CONTRIBUTING.md` | `sha256:ec2b66b63920d501a635061643090c5571aec2a4ba2bbb7f9de542a1bd9f84b2` |
| Orchestration policy | `docs/trigger-rules.md` | `sha256:faf3251302298af32b4370b9587a05943cc2ad5a4e6aa7f55b0f30a66a839b44` |
| Authority safety policy | `docs/review-authority-threat-model.md` | `sha256:ea6d4c08ac6a4ef25f86b946cb7336adcaa9c76ff7464a174dfc643fa0a9b2f1` |

## Evaluation Dimensions

| Dimension | Evidence-based assessment | Uncertainty |
| --- | --- | --- |
| Stack/capability detection | Correctly identifies Go unit, build, Docker E2E, format, CI typecheck, platform, release, and generated-asset areas. | Candidate provenance does not show a reproducible generation invocation. |
| Implementation mode fidelity | Every candidate row selects `standard` or `skip`. | Existing `openspec/config.yaml` declares `strict_tdd: true`; a maintainer must resolve whether the candidate intentionally replaces that implementation workflow or is only advisory. |
| Test-authoring discipline/forwarding fidelity | The overlay contract supplies the strict test-first workflow when a valid active row forwards `strict-tdd`; a row would not need to duplicate that prose. | This candidate selects no `strict-tdd` rows and has no activation envelope, so it cannot establish whether the existing strict policy should be forwarded. |
| Functional validation evidence | Production, tests, E2E, release, dependency, platform, and generated-asset rows select unit/build/E2E evidence. The `go-vet-ci` binding exists and is selected by the release row. | `go-vet-ci` is not selected for general Go production, test, dependency, or generated-asset rows despite existing OpenSpec verification declaring `go vet ./...`. |
| Visual/E2E validation evidence | Docker and organic-runtime E2E bindings are scoped validation evidence. | The repository evidence in scope does not establish a separate observable-UI policy. E2E evidence does not determine implementation mode. |
| Command/harness fidelity | `go test ./...` and Docker E2E align with `CONTRIBUTING.md`; CI-only commands remain labelled as CI bindings. | The output should distinguish local commands from policy-only CI expectations at orchestration time. |
| Work-type coverage | Includes production Go, tests, E2E variants, scripts, release, docs, dependencies, platforms, and generated assets. | It does not create a dedicated row for review-authority/state safety despite the threat model's fail-closed and live-Git requirements. |
| Multi-match resolution | States all matching non-default rows, strictest-wins, evidence union, and default-only semantics. | No activated canonical model proves that an orchestrator can consume this candidate directly. |
| Coverage and other evidence | The candidate lists coverage as unsupported and provides CI format/typecheck bindings. | Existing OpenSpec declares `go test -cover ./...` and `go vet ./...`; coverage remains a direct conflict, while `go-vet-ci` exists but is not broadly selected. |
| Fail-closed uncertainty | Lists unsatisfied methods and policy questions. | It classifies coverage/typecheck as unsatisfied despite the existing declarations; this needs maintainer adjudication. |
| Orchestrator forwarding behavior | The source contract forwards a producer-resolved row without downstream reclassification. | As an unbound candidate, it has no active `ResolutionV1` state and must not be forwarded as authoritative policy. |
| Project-specific policy gaps | Captures installer, platform, and release scope. | It needs explicit mapping for native authority, immutable receipts, live-Git re-derivation, and the user-owned disabled review boundary. |

## Similarities

- The candidate and repository evidence agree on Go unit testing, Docker E2E, platform-specific work, generated assets, scripts, dependencies, and documentation being distinct work types.
- The candidate preserves CI provenance rather than relabeling CI-only commands as universal local commands.
- The candidate records uncertainty instead of silently inventing lint capability.
- The candidate's multi-match/default semantics are coherent with a rubric-oriented orchestrator.

## Differences

- `openspec/config.yaml:13,42-80` currently declares `strict_tdd: true`, coverage, and `go vet`; the candidate uses standard modes, marks coverage unsupported, and limits its existing `go-vet-ci` binding to release work.
- The candidate does not turn `docs/review-authority-threat-model.md` fail-closed state validation, atomic replacement, CAS, exact retry, and live-Git re-derivation into explicit work-type disciplines.
- `docs/trigger-rules.md:74-82` requires disabled review mode to remain disabled and ordinary policy to avoid fabricated approval. The candidate does not state this forwarding boundary.
- The candidate does not prove its rows were produced from the recorded repository revision or that they are active consumer input.

## Behavioral Impact

If treated as authoritative, the candidate could change existing strict-TDD
workflow coverage to standard mode and omit review-authority safeguards for
stateful changes. It must remain advisory until a maintainer resolves the
implementation-mode conflict, the coverage and `go vet` selection differences,
and how native authority/review-mode rules enter a project-specific rubric.

## Unsupported Or Missing Claims

- Do not claim the candidate supersedes the existing `strict_tdd: true` configuration.
- Do not claim coverage is unavailable without reconciling the existing declared command; do not claim `go-vet-ci` is absent, because it exists but is scoped to release work.
- Do not claim consumer readiness: no activation envelope, canonical model digest, or generation receipt binds this candidate.
- Missing state/authority and review-mode rules require explicit policy design, not automatic inference from a threat-model document.

## Recommendation

`revise` with medium confidence. Preserve the useful scoped rows and
uncertainty reporting, then ask the maintainer to resolve the conflict with
existing strict-TDD/coverage/typecheck configuration and to define authoritative
state/review-mode disciplines. Regenerate with a source-bound receipt before
activation.

## Maintainer Decision

decision: pending
recorded_by:
recorded_at:
decision_authority: maintainer
