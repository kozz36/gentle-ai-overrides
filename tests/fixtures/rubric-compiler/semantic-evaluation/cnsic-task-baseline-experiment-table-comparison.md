# CNSIC Task-Intent Baseline Comparison

## Source Bindings

Candidate `sha256:af00ca093c2e49c6ec05c3fea20a0efffcfbc294dcb59d3e1a4c1527c`; result `sha256:a8ee263b7cd85548c82462d8979786f6cf61ddb940c790d4d18db77bd662269c`; manifest companion `sha256:2ba5520823981fbf24665453d889c30434cef611bd9fa71c1b0eb4368bca5ff3`; baseline `sha256:bdde1d2d2c3d8e264946af2e5cc2f0635e16a9aa3de461f95ab9d68a6074f152`.

## Canonical Versus V4 Matrix

| Canonical class | V4 row | Assessment |
| --- | --- | --- |
| behavior, bug, migration, RBAC/security | strict task-intent rows | partially-aligned |
| cross-context, tools, egress | no specific row | missing |
| port wiring | standard port row | partially-aligned |
| frontend behavior | strict UI row | conflict |
| refactor | standard refactor row | aligned |
| prompt | standard prompt row | partially-aligned |
| config/infra | standard config row | partially-aligned |
| scripts | standard script row | partially-aligned |
| docs | one docs skip row | aligned |
| dependency | standard dependency row | partially-aligned |

## Orchestrator Simulation

All 14 projected cases were independently accepted as intent-first: new endpoint, bug, refactor, UI layout, UI behavioral bug, migration, config, Docker, prompt, script, docs, dependency, unmatched, and overlapping security/API. Broad paths alone do not select strict; overlap is strictest-wins only for compatible intent.

## V1 To V2 To V3 To V4 Delta

| Version | Progress |
| --- | --- |
| V1 | rejected all-standard broad policy |
| V2 | richer rows but invalid active YAML |
| V3 | safe pending IR but six manual skips only |
| V4 | safe pending compiler handoff plus 13 selective task-intent rows and separate standard default; policy remains incomplete |

## Summary

| Assessment | Count |
| --- | --- |
| aligned | 2 |
| partially-aligned | 6 |
| missing | 3 |
| conflict | 1 |

## Maintainer Decision

decision: pending
decision_authority: maintainer
allowed_maintainer_actions: [approve, revise, reject]
