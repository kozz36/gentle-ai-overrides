# CNSIC Enriched Blind Experiment Table Comparison

This comparison evaluates behavioral compatibility, not serialized equality.
The enriched experiment is a new blind run; the first primary experiment remains
rejected and immutable evidence.

## Source Bindings

| Source | Binding |
| --- | --- |
| Canonical behavioral reference | Engram #3351, supersedes #305; `cnsic-canonical-reference.md`; `sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e` |
| Experiment reference block | `.experiment-evidence/manifest.txt`; `reference_body_sha256:06eb642b8f5d1a2789426ca19e96060881793b1d4e401bf5ff542ba622c45313` |
| Enriched blind output | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab`; `/home/kozz36/cnsic-agent-init-primary-experiment-v2-20260731/openspec/config.yaml`; `sha256:a072e4e8a7e817b099db9c6b186c6baf6bb6d12126c58f75abf38e6e05cb7b68`; `fresh-source-bound` |
| Enriched manifest | `/home/kozz36/cnsic-agent-init-primary-experiment-v2-20260731/.experiment-evidence/manifest.txt`; `sha256:16bd112257f1a330c281d2860c29422a352d112317a61f4804c0db422bbfa83a`; 10 rows; 8 bindings |
| Rejected first primary experiment | `cnsic-primary-experiment-decision.md`; `decision: reject`; output `sha256:6411df4b4b4ecb51f39319e58752da8bb9f5ff03937281f16baeec7eb0d7456b` |

## Canonical Rubric Table

| Signature (detectable trigger in the diff) | MODE | Disciplines / notes |
| --- | --- | --- |
| New endpoint or new domain function in services/agent/llm implementing behavior | Strict TDD | add smoke for adapters/api or main.py. |
| Bug fix | Strict TDD | with reproducing test first. |
| db/schema/migrations/** | Strict TDD | Migration Twin + smoke --build; ordering inversion or completeness; Judgment Day for non-append. |
| db/rbac_catalog_v50.py or require_capability | Strict TDD | backend/frontend 200/403 + Twin; frozen-set no-access; update telecom-rbac-matrix. |
| New cross-bounded-context SELECT/JOIN in services or db/queries | Strict TDD | real dataclasses; Judgment Day on first new sanctioned read. |
| agent/tools/** | Strict TDD | real-SQL boundary; Judgment Day mandatory. |
| Egress chokepoint semantic change | Strict TDD | Judgment Day mandatory, excluding parameter tuning. |
| LLM/Runner/transport wired to existing port | acceptance test | self-regression and resolution; Judgment Day mandatory. |
| frontend/src/** | Playwright SA-5, not unit TDD | npm test + committed spec + FINDINGS PASS; partial until evidence. |
| Behavior-preserving refactor | regression + test migration/approval tests, not test-first | build first if unmounted. |
| prompt or work_phases.py | telecom-field-ops validation | characterization only for logic branches. |
| config.py | smoke --build | no new test. |
| Infra Docker/env files | smoke --build | no pytest. |
| scripts/** | no pytest unless dedicated tests | |
| docs/CHANGELOG/runbooks | skip test gate | |
| Dependency bump | full suite | no new test. |

## Enriched Generated Rubric Table

This is an exact normalization of the ten generated rows. Modes remain separate
from validation disciplines; the active binding identifiers are assessed below.

| signature | implementation mode | disciplines | source |
| --- | --- | --- | --- |
| db/schema/migrations/** or db/schema.py migration registry | strict-tdd | unit, integration, build | generated |
| adapters/**, services/**, agent/**, llm/**, db/** Python behavior or API boundary changes | strict-tdd | unit, build | generated |
| authentication, authorization, secrets, state transitions, persistence, or audit behavior | strict-tdd | unit, integration, build | generated |
| frontend/** user-visible behavior, accessibility, client state, or UI | strict-tdd | unit, lint, build, e2e | generated |
| cross-layer assistant, transport, or integration boundary | strict-tdd | unit, integration, e2e, build | generated |
| behavior-preserving refactor of executable code | strict-tdd | unit, build | generated |
| docs/**, *.md, CHANGELOG.md, LICENSE | skip | none | generated |
| scripts/** utility/wrapper changes without dedicated tests | skip | none | generated |
| dependency-only, configuration-only, Docker/operations-only, prompt-only, or project-skill-only diffs | skip | none | generated, maintainer-selected |
| unmatched-only default | skip | none | generated, maintainer-selected |

## Semantic Alignment Matrix

`strict-tdd` is an implementation/test-authoring workflow. Playwright, unit,
integration, lint, and build are validation evidence, not modes. Grouped and
default skips are explicit maintainer policy inputs, not inferred omissions.

| canonical trigger | canonical implementation mode | canonical evidence | enriched matching row(s) | enriched implementation mode | enriched evidence | assessment | behavioral impact |
| --- | --- | --- | --- | --- | --- | --- | --- |
| New endpoint or new domain function in services/agent/llm implementing behavior | strict-tdd | smoke for adapters/api or main.py | behavior/API; cross-layer | strict-tdd; strict-tdd | unit/build; unit/integration/e2e/build | partially-aligned | Correct strict workflow; no path-specific `main.py`/adapter smoke --build selection and unresolved binding identities prevent executable activation. |
| Bug fix | strict-tdd | reproducing test first | behavior/API | strict-tdd | unit/build | partially-aligned | Strict workflow improves v1, but no explicit bug-fix/reproducer trigger remains. |
| db/schema/migrations/** | strict-tdd | Twin; smoke --build; ordering/completeness; Judgment Day | migrations | strict-tdd | unit/integration/build | partially-aligned | Mode and broad evidence improve, but Twin, build-before-smoke, ordering/completeness, and non-append Judgment Day are absent. |
| db/rbac_catalog_v50.py or require_capability | strict-tdd | 200/403, Twin, frozen-set, matrix | security/state | strict-tdd | unit/integration/build | partially-aligned | Security category exists, but no RBAC trigger or required security-specific evidence. |
| New cross-bounded-context SELECT/JOIN in services or db/queries | strict-tdd | real dataclasses; Judgment Day | behavior/API; cross-layer | strict-tdd; strict-tdd | unit/build; unit/integration/e2e/build | partially-aligned | Broader coverage is real improvement; real-dataclass and first-read Judgment Day rules are absent. |
| agent/tools/** | strict-tdd | real-SQL boundary; Judgment Day | behavior/API; cross-layer | strict-tdd; strict-tdd | unit/build; unit/integration/e2e/build | partially-aligned | Strict categories replace v1 defaulting, but tool-specific real-SQL and Judgment Day evidence are absent. |
| Egress chokepoint semantic change | strict-tdd | Judgment Day; tuning exception | behavior/API; security/state | strict-tdd; strict-tdd | unit/build; unit/integration/build | partially-aligned | No egress chokepoint trigger or semantic-change/tuning distinction exists. |
| LLM/Runner/transport wired to existing port | standard (inferred-for-evaluation) | acceptance/self-regression/resolution; Judgment Day | cross-layer | strict-tdd | unit/integration/e2e/build | partially-aligned | Cross-layer category and evidence improve, but strict mode overstates canonical order and port-wiring/Judgment Day constraints are absent. |
| frontend/src/** | standard (inferred-for-evaluation) | Playwright SA-5; Vitest; committed spec/FINDINGS | frontend | strict-tdd | unit/lint/build/e2e | conflict | No v1 cwd contradiction, but frontend mode conflicts with canonical non-unit-TDD policy; commands omit `frontend` workdir and required committed evidence remains absent. |
| Behavior-preserving refactor | standard (inferred-for-evaluation) | regression/migration approval; build if unmounted | refactor | strict-tdd | unit/build | conflict | Strict mode conflicts with canonical non-test-first refactor policy; approval/migration tests and stale-image rule are absent. |
| prompt or work_phases.py | standard (inferred-for-evaluation) | telecom-field-ops; characterization | grouped maintainer skip | skip | none | conflict | Explicit maintainer selection is recorded, but it conflicts with canonical prompt validation. |
| config.py | standard (inferred-for-evaluation) | smoke --build; no new test | grouped maintainer skip | skip | none | conflict | Explicit maintainer selection conflicts with canonical smoke --build. |
| Infra Docker/env files | standard (inferred-for-evaluation) | smoke --build; no pytest | grouped maintainer skip | skip | none | conflict | Explicit maintainer selection conflicts with canonical smoke --build/no-pytest policy. |
| scripts/** | standard (inferred-for-evaluation) | no pytest unless dedicated tests | scripts | skip | none | aligned | The generated signature correctly limits skip to utility/wrapper changes without dedicated tests. |
| docs/CHANGELOG/runbooks | skip | no automated test gate | docs | skip | none | aligned | Both select skip with no own automated validation gate. |
| Dependency bump | standard (inferred-for-evaluation) | full suite | grouped maintainer skip | skip | none | conflict | Explicit maintainer selection conflicts with the canonical full-suite requirement. |

## Improvement Delta From Rejected First Experiment

| Area | Rejected first experiment | Enriched experiment | Delta |
| --- | --- | --- | --- |
| Semantic coverage | 6 broad rows; 7 missing canonical categories | 10 rows, including security/state, cross-layer, refactor, scripts, and explicit grouped/default policy | Material producer richness improvement |
| Executable modes | all implementation rows `standard` | strict workflow for migrations, behavior/API, security/state, frontend, cross-layer, and refactor | Correctly avoids v1 all-standard collapse, but frontend/refactor strictness conflicts with canonical policy |
| Frontend command | `npm test` executed in Playwright cwd | no contradictory cwd is asserted | Improvement; commands still lack an explicit `frontend` workdir in the output |
| Uncertainty | incomplete fail-closed handling | grouped and unmatched default selections explicitly recorded | Improvement in decision provenance; selected skips still conflict with canonical rules |
| Activation shape | no consumer-bound authority | claims active/authoritative | No activation improvement: the output still lacks `ResolutionV1`, readback, transaction, authority, canonical-model digest, and declared binding identities |

## Summary

| Assessment | Count |
| --- | --- |
| aligned | 2 |
| partially-aligned | 8 |
| missing | 0 |
| conflict | 6 |

## Material Blockers

- `unit-backend`, `unit-frontend`, and the other active binding IDs are referenced but no `id` fields declare those identities in `testing.methods`; the rubric cannot resolve its own bindings.
- `npm test`, `npm run lint`, and `npm run build` have no `workdir: frontend`; `npx playwright test` has no `workdir: tests/e2e/playwright`. CI defaults prove those contexts externally but the reusable bindings omit them.
- Direct backend pytest commands reproduce CI's `-n 12`, but do not express the root wrapper's mutex, environment guards, platform behavior, mount scope, or stale-image rebuild constraints. The CI command is valid in its declared runner, not a portable active binding.
- The active rubric is not the overlay consumer/compiler contract: it lacks a `ResolutionV1` schema, `state: active`, transaction/readback/authority fields, canonical-model digest, and complete declared binding records.

## Acceptable Differences

- A fresh blind producer need not reproduce canonical prose byte-for-byte. Strict workflow forwarding can remain centralized when a compatible row selects it.
- The maintainer's grouped and unmatched-default `skip` choices are valid policy inputs; their canonical conflicts are reported as policy divergence, not producer inference failures.
- Playwright remains evidence for visible behavior and does not itself select implementation mode.

## Maintainer Decision

decision: pending
decision_authority: maintainer
allowed_maintainer_actions: [approve, revise, reject]
