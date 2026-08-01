# CNSIC Rubric Table Comparison

This comparison is for maintainer review. It preserves the canonical table's
legacy MODE cells, then separates implementation mode from validation evidence
in the alignment matrix. It does not activate policy or record a decision.

## Source Bindings

| Source | Binding |
| --- | --- |
| Canonical behavioral reference | Engram #3351, supersedes #305; `cnsic-canonical-reference.md`; `sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e` |
| Observed generator output | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab`; `/home/kozz36/cnsic-agent-init-validation/openspec/config.yaml`; `sha256:5f510a8f37d388e08c73f95cac2f2d2d3a9067e42e4e1afefa1283efad566c13`; `artifact_freshness: stale-unbound` |

## Canonical Rubric Table

This is a faithful transcription of the #3351 rubric rows into its authoritative
columns. Legacy MODE cells are preserved here without normalization.

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

This table is mechanically normalized from the six `rows` in the source-bound
observed YAML. Its columns intentionally keep implementation mode separate from
validation disciplines and bindings.

| signature | implementation mode | disciplines | evidence bindings | source |
| --- | --- | --- | --- | --- |
| backend-source | standard | unit | backend-unit | generated |
| boundary-api | strict-tdd | unit, integration | backend-unit, backend-integration | generated |
| ui-visible | strict-tdd | unit, lint, build, e2e | frontend-unit, frontend-lint, frontend-build, frontend-e2e | generated |
| migration | strict-tdd | unit, integration, build | backend-unit, backend-integration, container-build | generated |
| docs | skip |  |  | generated |
| default | standard |  |  | generated |

## Semantic Alignment Matrix

`strict-tdd` means full test-first workflow through orchestrator forwarding.
`standard` requires selected evidence without mandatory test-first ordering.
`skip` has no own automated gate. Playwright/E2E, smoke, build, unit, and
integration are validation evidence, not modes. Every
`inferred-for-evaluation` mode below is a transparent interpretation of a
legacy canonical cell, not a change to #3351.

| canonical trigger | canonical implementation mode | canonical validation disciplines/evidence | generated matching row(s) | generated implementation mode | generated validation disciplines/evidence | assessment | behavioral impact |
| --- | --- | --- | --- | --- | --- | --- |
| New endpoint or new domain function in services/agent/llm implementing behavior | strict-tdd | smoke for adapters/api or main.py | backend-source; boundary-api | standard; strict-tdd | unit; unit/integration | partially-aligned | Boundary API gets strict workflow, but generic services/agent/llm behavior and required smoke lack explicit coverage. |
| Bug fix | strict-tdd | reproducing test first | default | standard | none | missing | No bug-fix trigger, strict workflow, or reproducing-test evidence is selected. |
| db/schema/migrations/** | strict-tdd | Migration Twin; smoke --build; ordering inversion or completeness; Judgment Day for non-append | migration | strict-tdd | unit/integration/build | partially-aligned | Mode and broad test/build evidence exist; Migration Twin, smoke --build, ordering/completeness, and non-append Judgment Day are absent. |
| db/rbac_catalog_v50.py or require_capability | strict-tdd | backend/frontend 200/403 + Twin; frozen-set no-access; telecom-rbac-matrix | default | standard | none | missing | No RBAC trigger, strict workflow, or required security validation is selected. |
| New cross-bounded-context SELECT/JOIN in services or db/queries | strict-tdd | real dataclasses; Judgment Day on first new sanctioned read | backend-source | standard | unit | missing | Broad backend coverage omits the cross-context trigger, real-dataclass evidence, and Judgment Day. |
| agent/tools/** | strict-tdd | real-SQL boundary; Judgment Day mandatory | backend-source | standard | unit | missing | Broad backend row does not provide tool-specific strict workflow, real-SQL evidence, or Judgment Day. |
| Egress chokepoint semantic change | strict-tdd | Judgment Day mandatory, excluding parameter tuning | backend-source | standard | unit | missing | No chokepoint trigger or semantic-change/Judgment Day distinction is selected. |
| LLM/Runner/transport wired to existing port | standard (inferred-for-evaluation) | acceptance test with self-regression and resolution; Judgment Day mandatory | backend-source | standard | unit | missing | Inference: acceptance-test wording has no test-first order. Mode is broadly compatible, but port-wiring evidence and Judgment Day are absent; uncertainty: the legacy cell did not state a MODE token. |
| frontend/src/** | standard (inferred-for-evaluation) | Playwright SA-5; npm test; committed spec; FINDINGS PASS | ui-visible | strict-tdd | unit/lint/build/e2e | conflict | Inference: the legacy cell explicitly rejects unit TDD and requires visual evidence. Generated E2E is relevant validation, but committed spec/FINDINGS are absent and strict workflow needs maintainer policy resolution. |
| Behavior-preserving refactor | standard (inferred-for-evaluation) | regression + test migration/approval tests; build first if unmounted | backend-source | standard | unit | partially-aligned | Inference: canonical wording rejects test-first ordering. Broad standard mode partially fits, but required regression/migration-approval tests and unmounted build rule are absent. |
| prompt or work_phases.py | standard (inferred-for-evaluation) | telecom-field-ops validation; characterization only for logic branches | default | standard | none | missing | Inference: validation-only legacy cell gives no ordering. Default mode has no project-specific evidence. |
| config.py | standard (inferred-for-evaluation) | smoke --build; no new test | default | standard | none | partially-aligned | Inference: smoke is evidence, not a mode. Standard mode is compatible, but smoke --build is absent. |
| Infra Docker/env files | standard (inferred-for-evaluation) | smoke --build; no pytest | default | standard | none | partially-aligned | Inference: smoke is evidence, not a mode. Standard mode is compatible, but smoke --build is absent. |
| scripts/** | standard (inferred-for-evaluation) | no pytest unless dedicated tests | default | standard | none | partially-aligned | Inference: legacy wording provides validation only. Default standard avoids a forced test-first workflow but does not encode the dedicated-test condition. |
| docs/CHANGELOG/runbooks | skip | no automated test gate | docs | skip | none | aligned | Both select skip with no own automated validation evidence. |
| Dependency bump | standard (inferred-for-evaluation) | full suite; no new test | default | standard | none | partially-aligned | Inference: full-suite evidence has no test-first ordering. Standard mode is compatible, but the full suite is absent. |

## Summary

| Assessment | Count |
| --- | --- |
| aligned | 1 |
| partially-aligned | 7 |
| missing | 7 |
| conflict | 1 |

Material blockers:

- Direct pytest replaces the required mutex wrapper, and the observed rows omit required build-before-test constraints.
- RBAC, cross-context, agent-tool, egress, port-wiring, bug-fix, and related project-specific triggers have no selected mode or evidence.
- Migration lacks project-specific twin/smoke/Judgment Day obligations; the UI row has unresolved strict-workflow versus visual-evidence policy.
- The artifact is `stale-unbound` and has no activation envelope for consumer forwarding.

Acceptable differences:

- The generated strict-tdd rows do not repeat cycle prose. The orchestrator contract supplies full test-first workflow when it forwards a valid strict-tdd row.
- A generated row may use evidence-binding identifiers rather than canonical prose when the binding is source-proven and selected for the same trigger.
- Legacy canonical cells that name acceptance tests, smoke, Playwright, or full suite are normalized only in the matrix; they are not silently treated as modes.

## Maintainer Decision

decision: pending
decision_authority: maintainer
allowed_maintainer_actions: [approve, revise, reject]
