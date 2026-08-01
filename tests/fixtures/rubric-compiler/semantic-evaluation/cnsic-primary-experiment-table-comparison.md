# CNSIC Primary Blind Experiment Table Comparison

This comparison evaluates semantic behavior, not serialized equality. The blind
experiment had no Engram, #3351, or prior-evaluation access. Its fresh manifest
is integrity evidence; the matrix below separately assesses generator inference
quality against the canonical project policy.

## Source Bindings

| Source | Binding |
| --- | --- |
| Canonical behavioral reference | Engram #3351, supersedes #305; `cnsic-canonical-reference.md`; `sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e` |
| Primary blind output | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab`; `/home/kozz36/cnsic-agent-init-primary-experiment-20260730/openspec/config.yaml`; `sha256:6411df4b4b4ecb51f39319e58752da8bb9f5ff03937281f16baeec7eb0d7456b`; `fresh-source-bound` |
| Experiment manifest | `/home/kozz36/cnsic-agent-init-primary-experiment-20260730/.experiment-evidence/manifest.yaml`; `sha256:c114ee522da87d2eb43f2efa981c30d2066828d5e4389c179480988ca1aaa222`; 6 rows; 7 bindings |

## Canonical Rubric Table

This is a faithful transcription of the #3351 rubric rows. Legacy MODE cells
remain unnormalized in this table.

| Signature (detectable trigger in the diff) | MODE | Disciplines / notes |
| --- | --- | --- |
| New endpoint or new domain function in services/agent/llm implementing behavior | Strict TDD | add smoke for adapters/api or main.py. |
| Bug fix | Strict TDD | with reproducing test first. |
| db/schema/migrations/** | Strict TDD | Migration Twin + smoke --build; ordering inversion or completeness; Judgment Day for non-append. |
| db/rbac_catalog_v50.py or require_capability | Strict TDD | backend/frontend 200/403 + Twin; frozen-set no-access; update telecom-rbac-matrix. |
| New cross-bounded-context SELECT/JOIN in services or db/queries | Strict TDD | with real dataclasses; Judgment Day on first new sanctioned read. |
| agent/tools/** | Strict TDD | with real-SQL boundary; Judgment Day mandatory. |
| Egress chokepoint semantic change | Strict TDD | Judgment Day mandatory, excluding parameter tuning. |
| LLM/Runner/transport wired to existing port | acceptance test | with self-regression and resolution; Judgment Day mandatory. |
| frontend/src/** | Playwright SA-5, not unit TDD | npm test + committed spec + FINDINGS PASS; partial until evidence. |
| Behavior-preserving refactor | regression + test migration/approval tests, not test-first | build first if unmounted. |
| prompt or work_phases.py | telecom-field-ops validation | characterization only for logic branches. |
| config.py | smoke --build | no new test. |
| Infra Docker/env files | smoke --build | no pytest. |
| scripts/** | no pytest unless dedicated tests |  |
| docs/CHANGELOG/runbooks | skip test gate |  |
| Dependency bump | full suite | no new test. |

## Generated Rubric Table

This is the exact six-row policy normalized from the fresh output. Implementation
mode is distinct from the generated `disciplines` binding list and `evidence`
method list.

| signature | implementation mode | disciplines | evidence |
| --- | --- | --- | --- |
| source | standard | backend-pytest, backend-integration-pytest, backend-container-build | unit, integration, build |
| boundary/api | standard | backend-pytest, backend-integration-pytest, e2e-playwright, backend-container-build | unit, integration, e2e, build |
| ui | standard | frontend-vitest, frontend-eslint, frontend-build, e2e-playwright | unit, lint, build, e2e |
| migration | standard | backend-pytest, backend-integration-pytest, backend-container-build | unit, integration, build |
| docs | skip |  |  |
| default | standard | backend-pytest | unit |

## Semantic Alignment Matrix

`strict-tdd` means full test-first workflow through orchestrator forwarding.
`standard` can require evidence without test-first ordering. `skip` has no own
automated gate. Playwright/E2E, smoke, build, unit, and integration are
validation evidence, not implementation modes. Every `inferred-for-evaluation`
mode is an explicit interpretation of a legacy canonical cell and carries its
rationale and uncertainty in the behavioral impact column.

| canonical trigger | canonical implementation mode | canonical validation disciplines/evidence | generated matching row(s) | generated implementation mode | generated validation disciplines/evidence | assessment | behavioral impact |
| --- | --- | --- | --- | --- | --- | --- |
| New endpoint or new domain function in services/agent/llm implementing behavior | strict-tdd | smoke for adapters/api or main.py | source; boundary/api | standard; standard | unit/integration/build; unit/integration/e2e/build | conflict | Tracked AGENTS policy requires stronger boundary behavior and canonical strict workflow. The manifest offers no order-of-implementation evidence justifying all-standard deviation; smoke is absent. |
| Bug fix | strict-tdd | reproducing test first | default | standard | unit | missing | No bug-fix trigger or reproducing-test-first rule is selected. |
| db/schema/migrations/** | strict-tdd | Migration Twin; smoke --build; ordering inversion or completeness; Judgment Day for non-append | migration | standard | unit/integration/build | conflict | Test/build evidence exists, but the all-standard mode lacks evidence for departing from canonical strict workflow; Twin, smoke --build, ordering/completeness, and Judgment Day are absent. |
| db/rbac_catalog_v50.py or require_capability | strict-tdd | backend/frontend 200/403 + Twin; frozen-set no-access; telecom-rbac-matrix | default | standard | unit | missing | No RBAC trigger, strict workflow, or required security validation is selected. |
| New cross-bounded-context SELECT/JOIN in services or db/queries | strict-tdd | real dataclasses; Judgment Day on first new sanctioned read | source | standard | unit/integration/build | missing | Broad source evidence lacks a cross-context trigger, real-dataclass evidence, and Judgment Day. |
| agent/tools/** | strict-tdd | real-SQL boundary; Judgment Day mandatory | source | standard | unit/integration/build | missing | Broad source evidence does not encode tool-boundary real-SQL validation or Judgment Day. |
| Egress chokepoint semantic change | strict-tdd | Judgment Day mandatory, excluding parameter tuning | source | standard | unit/integration/build | missing | No chokepoint or parameter-tuning distinction is selected. |
| LLM/Runner/transport wired to existing port | standard (inferred-for-evaluation) | acceptance test with self-regression and resolution; Judgment Day mandatory | source | standard | unit/integration/build | missing | Inference: acceptance-test wording has no test-first order. Mode is broadly compatible, but port-wiring acceptance evidence and Judgment Day are absent; uncertainty: legacy cell had no MODE token. |
| frontend/src/** | standard (inferred-for-evaluation) | Playwright SA-5; npm test; committed spec; FINDINGS PASS | ui | standard | unit/lint/build/e2e | partially-aligned | Inference: the legacy cell rejects unit TDD and names visual evidence. E2E is relevant, but committed spec/FINDINGS are absent and `frontend-vitest` is internally inconsistent: its cwd selects the Playwright package, not the cited frontend Vitest script. |
| Behavior-preserving refactor | standard (inferred-for-evaluation) | regression + test migration/approval tests; build first if unmounted | source | standard | unit/integration/build | partially-aligned | Inference: canonical wording rejects test-first ordering. Standard mode is compatible, but required regression/migration-approval tests and unmounted build rule are absent. |
| prompt or work_phases.py | standard (inferred-for-evaluation) | telecom-field-ops validation; characterization only for logic branches | default | standard | unit | missing | Inference: legacy cell provides validation only. Default unit evidence lacks the project-specific validation. |
| config.py | standard (inferred-for-evaluation) | smoke --build; no new test | default | standard | unit | partially-aligned | Inference: smoke is evidence, not mode. Standard mode is compatible, but generated unit testing does not select smoke --build. |
| Infra Docker/env files | standard (inferred-for-evaluation) | smoke --build; no pytest | default | standard | unit | partially-aligned | Inference: smoke is evidence, not mode. Generated default unit testing conflicts with the no-pytest expectation and omits smoke --build. |
| scripts/** | standard (inferred-for-evaluation) | no pytest unless dedicated tests | default | standard | unit | partially-aligned | Inference: legacy wording supplies validation only. Default unit evidence may over-apply pytest and lacks a dedicated-test condition. |
| docs/CHANGELOG/runbooks | skip | no automated test gate | docs | skip | none | aligned | Both select skip with no own automated validation evidence. |
| Dependency bump | standard (inferred-for-evaluation) | full suite; no new test | default | standard | unit | partially-aligned | Inference: full-suite evidence has no test-first order. Standard mode is compatible, but one unit binding is not the full suite. |

## Summary

| Assessment | Count |
| --- | --- |
| aligned | 1 |
| partially-aligned | 6 |
| missing | 7 |
| conflict | 2 |

Material blockers:

- `frontend-vitest` declares frontend Vitest sources but executes `npm test` in `tests/e2e/playwright`, where that command runs Playwright. The binding cannot prove the claimed frontend unit method.
- Root `AGENTS.md` requires the Docker mutex wrapper and build-before-test constraints. The manifest did not cite it, and generated direct pytest commands do not preserve those requirements.
- All-standard modes for source, boundary/api, and migration have no tracked policy evidence justifying deviation from canonical strict workflow.
- Project-specific RBAC, cross-context, agent-tool, egress, port-wiring, migration, smoke, and Judgment Day triggers/evidence remain absent.

Acceptable differences:

- Strict workflow prose need not be repeated in generated rows when valid active mode forwarding supplies it; this experiment emits no strict rows, so that allowance does not resolve its mode conflicts.
- The manifest and output hashes, row count, binding count, and blindness statement support experiment integrity. They do not prove semantic adequacy or activation authority.

## Maintainer Decision

decision: pending
decision_authority: maintainer
allowed_maintainer_actions: [approve, revise, reject]
