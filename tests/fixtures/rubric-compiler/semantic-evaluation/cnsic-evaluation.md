---
schema: human-semantic-evaluation/v1
subject: "CNSIC observed OpenSpec rubric generator output"
status: needs-human-approval
recommendation: revise
confidence: high
artifact_freshness: stale-unbound
---

# CNSIC Semantic Evaluation

This evaluates the current observed six-row OpenSpec rubric. It was not
regenerated during this evaluation, and no generation receipt binds it to the
current clone. The recommendation is advisory only.

## Source Bindings

| Role | Read-only source | Binding |
| --- | --- | --- |
| Repository | `/home/kozz36/cnsic-agent-init-validation` | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab` |
| Observed generator artifact | `openspec/config.yaml` | `sha256:5f510a8f37d388e08c73f95cac2f2d2d3a9067e42e4e1afefa1283efad566c13` |
| Project policy evidence | `AGENTS.md` | `sha256:90c1131f19208737262a5283dd316d564809809a2717b242811e4dfc673782c6` |
| Required test harness | `scripts/run_tests.sh` | `sha256:157318f9e958a436f7fe575fcb8379776cf06b3cd5a0161ecc219004b615ea12` |
| Canonical behavioral reference | `cnsic-canonical-reference.md` | `Engram #3351; supersedes #305; sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e` |

The separately stored `.rubric-eval/candidate-v2.yaml` is a benchmark input and
is not used as proof that this observed OpenSpec output was freshly generated.

## Evaluation Dimensions

| Dimension | Evidence-based assessment | Uncertainty |
| --- | --- | --- |
| Stack/capability detection | Detects Python/FastAPI, frontend, unit, integration, lint, build, and E2E capability categories. | It does not encode the complete Docker/runtime constraints of the project policy. |
| Implementation mode fidelity | API and migration rows select `strict-tdd`; docs select `skip`; backend/default select `standard`. | Bug fixes, new behavior, RBAC, cross-context, agent-tool, egress, LLM/transport, config, infra, scripts, and dependency work types have no specific mode selection. The UI `strict-tdd` selection needs maintainer review against the project policy's frontend workflow. |
| Test-authoring discipline/forwarding fidelity | The producer contract defines `strict-tdd` as the full test-first cycle and directs the orchestrator to forward the resolved row. The generated rows need not duplicate that cycle prose. | This observed artifact lacks a valid activation envelope, so this evaluation cannot prove an active runtime forwarded its strict tokens. |
| Functional validation evidence | API and migration rows select unit/integration evidence; migration also selects build. | Missing rows omit required real-SQL, RBAC, Migration Twin, smoke, and other project-specific functional evidence. |
| Visual/E2E validation evidence | The UI row selects a frontend E2E binding, which is relevant evidence for observable behavior. | The artifact does not require the canonical committed Playwright spec and FINDINGS PASS evidence. E2E evidence does not itself set the UI implementation mode. |
| Command/harness fidelity | The artifact binds unit, integration, frontend, E2E, and build commands. | `openspec/config.yaml` uses direct pytest, while `AGENTS.md:75-85` requires the mutex wrapper; unmounted-path changes also require a build before testing. |
| Work-type coverage | Has backend, API, UI, migration, docs, and default rows. | It omits explicit RBAC, cross-context read, agent-tool, egress, LLM/transport, prompt, config, infra, scripts, and dependency rows. |
| Multi-match resolution | Declares `all-rows`, strictest-wins, and evidence union. | The rows expose labels rather than concrete trigger paths, so an independent orchestrator cannot mechanically classify every required CNSIC case from this artifact alone. |
| Coverage and other evidence | It records coverage, typecheck, and format as unsatisfied. | The canonical reference identifies pytest-cov capability; that discrepancy needs a source-bound coverage binding or an explicit project-policy exception. |
| Fail-closed uncertainty | Lists some unsatisfied methods. | It does not identify the omitted manual policy as a blocking seed/policy gap. |
| Orchestrator forwarding behavior | The source contract makes the orchestrator forward the producer-resolved row and canonical model without reclassification. | The observed artifact has no `ResolutionV1` activation record, transaction, or canonical model binding for the overlay consumer gate. |
| Project-specific policy gaps | The reference requires project-local manual rules and a Docker-aware harness. | A maintained seed/manual policy is still needed; a generic generator cannot infer these safely from broad capability discovery. |

## Similarities

- Both sources select rubric-oriented, multi-row policy instead of one universal test command.
- Both distinguish docs-only work from implementation work and represent a default path.
- Both recognize that API and migration work need stronger evidence than documentation.
- Both intend multi-row resolution rather than one arbitrary matching row.

## Differences

- The reference requires `bash scripts/run_tests.sh tests/unit/ -q`, Docker mutex semantics, controlled worker count, and an explicit Windows twin. The observed artifact records direct pytest instead.
- The reference makes bug fixes, new behavior, RBAC, migrations, cross-context reads, agent tools, egress semantics, and port wiring conditional mode and evidence rules. The observed artifact does not preserve those categories.
- The reference requires Playwright SA-5 with a committed spec and findings evidence for `frontend/src/**`. The observed artifact selects an E2E binding but does not preserve those artifacts; its UI `strict-tdd` mode needs a separate policy judgment.
- The reference requires `smoke --build` for config and infrastructure and distinguishes unmounted paths. The observed artifact does not express this build-before-test constraint.

## Behavioral Impact

An orchestrator following only the observed artifact could invoke an unsafe
direct pytest path, omit required Docker rebuilding, and fail to request the
project's mandatory RBAC, migration, cross-context, egress, or Playwright
evidence. It could also select a UI test-first workflow where the project policy
instead requires a dedicated visual-validation path. The overlay consumer would
block rather than forward this artifact until it has a valid activation envelope.

## Unsupported Or Missing Claims

- Do not claim this artifact is fresh: no invocation, receipt, or source-bound generation record was found.
- Do not treat the absence of repeated strict-TDD cycle prose as a gap: the producer/orchestrator contract supplies that workflow when a valid active row forwards `strict-tdd`.
- Do not claim coverage, Playwright, or frontend evidence is runnable solely from the declared row labels.
- Missing policy must remain a human-maintained project seed/manual policy, not inferred from this report.

## Recommendation

`revise` with high confidence. Keep the artifact `stale-unbound` until a
reproducible generator run binds it to the repository revision. Add a
versioned CNSIC seed/manual-policy layer that preserves the canonical harness,
work-type rules, and required disciplines while allowing generic capability
detection to contribute only supported bindings.

## Maintainer Decision

decision: pending
recorded_by:
recorded_at:
decision_authority: maintainer
