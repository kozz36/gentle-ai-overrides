---
schema: human-semantic-evaluation/v1
subject: "CNSIC third compiler-bound blind sdd-init experiment"
status: needs-human-approval
recommendation: reject
confidence: high
artifact_freshness: fresh-source-bound
---

# CNSIC Compiler-Bound Blind Experiment Evaluation

Recommendation applies to the candidate as policy, not to the fail-closed
handoff mechanism.

## Source Bindings

| Role | Source | Binding |
| --- | --- | --- |
| Clone | `/home/kozz36/cnsic-agent-init-primary-experiment-v3-20260731` | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab` |
| Candidate | `.experiment-evidence/candidate/ir.json` | `sha256:f36ddae7745fc3afae9c9d4e4d5458875b07305eea500b0926d7867931310d9f` |
| Manifest | `.experiment-evidence/manifest.txt` | `sha256:0e59e8fdd1bd4e02a6a1874e43229ed290539918fefa2b41299df484c117e470` |
| Root policy | `AGENTS.md` | `sha256:90c1131f19208737262a5283dd316d564809809a2717b242811e4dfc673782c6` |

## Evaluation Dimensions

| Dimension | Evidence-based assessment | Uncertainty |
| --- | --- | --- |
| Implementation mode fidelity | No generated implementation rows exist. | Manual skips are policy inputs only. |
| Test-authoring discipline/forwarding fidelity | No strict rows to forward. | Canonical strict categories are unrepresented. |
| Functional validation evidence | Four binding contexts have stable IDs and frontend workdirs. | No candidate row selects any binding. |
| Visual/E2E validation evidence | No false frontend command context is emitted. | No Playwright binding or UI row exists. |
| Command/harness fidelity | Backend context is explicit. | Direct pytest omits wrapper mutex/env, worker cap and stale-image/build safeguards. |
| Work-type coverage | Six manual skip inputs are closed. | Ten canonical work types default to skip. |
| Multi-match resolution | `all-rows` and unmatched default are explicit. | All effective outcomes are skips. |
| Coverage and other evidence | Candidate references facts/attestations. | No selected validation evidence exists. |
| Fail-closed uncertainty | Compiler unavailable yields pending IR, not ad hoc active YAML. | End-to-end compiler behavior is unproven. |
| Orchestrator forwarding behavior | No `ResolutionV1` is claimed. | Cannot activate until compiler exists. |
| Project-specific policy gaps | No generated RBAC, migration, tool, egress, or port rules. | Manual selection intentionally withheld broader policy. |

## Similarities

- V3 correctly keeps candidate and activation authority separate.
- Stable IDs, contexts, and frontend workdirs improve on V2 binding representation.

## Differences

- V3 is safer than V1/V2 because it emits no ad hoc active YAML or parallel methods authority.
- V3 is semantically less complete than V2: no generated implementation rows select its bindings.

## Behavioral Impact

Safety verdict: pass. The typed pending/compiler-unavailable handoff fails closed.
Semantic verdict: reject. The candidate defaults most production work to skip and
conflicts with canonical prompt/config/infra/dependency policy. Usability verdict:
not activatable. Compiler unavailability is intentional and not a producer defect,
but end-to-end init cannot be proven until a compiler produces `ResolutionV1`.

## Unsupported Or Missing Claims

- Do not claim backend-unit is portable: direct pytest omits root harness semantics.
- Do not claim candidate closure proves canonical policy coverage.
- Do not claim compiler unavailable is semantic failure; it is a usability limit.

## Recommendation

`reject` with high confidence for the candidate as policy. Preserve the
fail-closed handoff, then run a new compiler-bound experiment with generated
implementation rows and canonical policy reconciliation.

## Maintainer Decision

decision: pending
decision_authority: maintainer
