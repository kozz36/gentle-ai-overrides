# CNSIC Compiler-Bound Blind Experiment Comparison

This compares behavior, not bytes. V3 is a pending compiler input; v1 remains
rejected and v2 remains activation-invalid evidence.

## Source Bindings

| Source | Binding |
| --- | --- |
| Canonical reference | Engram #3351, supersedes #305; `sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e` |
| V3 consumed reference | manifest `reference_body_sha256:12dcd0d071ced00134613b09aafd23b1d2c7faa64d234e69ee26b93d5c4f7d15` |
| V3 candidate | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab`; `.experiment-evidence/candidate/ir.json`; `sha256:f36ddae7745fc3afae9c9d4e4d5458875b07305eea500b0926d7867931310d9f` |
| V3 manifest | `.experiment-evidence/manifest.txt`; `sha256:0e59e8fdd1bd4e02a6a1874e43229ed290539918fefa2b41299df484c117e470`; 6 rows; 4 bindings |

## Canonical Rubric Table

| Trigger | Mode / evidence |
| --- | --- |
| New endpoint/domain behavior | strict-tdd; adapter/main smoke |
| Bug fix | strict-tdd; reproducing test |
| migrations | strict-tdd; Twin, smoke --build, Judgment Day |
| RBAC | strict-tdd; 200/403, Twin |
| cross-context | strict-tdd; real dataclass, Judgment Day |
| agent tools | strict-tdd; real SQL, Judgment Day |
| egress | strict-tdd; Judgment Day |
| LLM/Runner/port | acceptance, Judgment Day |
| frontend | Playwright SA-5, not unit TDD |
| refactor | regression, not test-first |
| prompt | field-ops validation |
| config | smoke --build |
| infra | smoke --build, no pytest |
| scripts | no pytest unless dedicated tests |
| docs | skip |
| dependency | full suite |

## Compiler-Bound Candidate Table

| signature | mode | binding refs | source |
| --- | --- | --- | --- |
| dependency-only | skip | none | manual |
| configuration-only | skip | none | manual |
| docker-operations-only | skip | none | manual |
| prompt-only | skip | none | manual |
| project-skill-only | skip | none | manual |
| default (unmatched-only) | skip | none | manual |

## Semantic Alignment Matrix

| canonical trigger | candidate row | assessment | impact |
| --- | --- | --- | --- |
| New endpoint/domain behavior | default | missing | No generated implementation policy. |
| Bug fix | default | missing | No reproducing-test rule. |
| migrations | default | missing | No strict/Twin/smoke/Judgment Day rule. |
| RBAC | default | missing | No security policy. |
| cross-context | default | missing | No context rule. |
| agent tools | default | missing | No real-SQL/Judgment Day rule. |
| egress | default | missing | No egress rule. |
| LLM/Runner/port | default | missing | No acceptance policy. |
| frontend | default | missing | Bindings exist but no row selects them. |
| refactor | default | missing | No executable refactor policy. |
| prompt | prompt-only | conflict | Explicit manual skip conflicts with canonical validation. |
| config | configuration-only | conflict | Explicit manual skip conflicts with smoke --build. |
| infra | docker-operations-only | conflict | Explicit manual skip conflicts with smoke --build. |
| scripts | default | partially-aligned | Skip is compatible, but no dedicated-test condition. |
| docs | default | aligned | Skip is compatible. |
| dependency | dependency-only | conflict | Explicit manual skip conflicts with full suite. |

## V1 To V2 To V3 Delta

| Version | Safety handoff | Semantic policy | Activation usability |
| --- | --- | --- | --- |
| V1 | unsafe active ad hoc output | 6 broad all-standard rows | rejected |
| V2 | unsafe active ad hoc YAML with unresolved IDs | 10 richer rows | activation-invalid |
| V3 | fail-closed pending IR; no YAML/ResolutionV1; compiler unavailable typed block | only six manual skips; four unused bindings | not activatable until compiler executes |

## Summary

| Assessment | Count |
| --- | --- |
| aligned | 1 |
| partially-aligned | 1 |
| missing | 10 |
| conflict | 4 |

## Maintainer Decision

decision: pending
decision_authority: maintainer
allowed_maintainer_actions: [approve, revise, reject]
