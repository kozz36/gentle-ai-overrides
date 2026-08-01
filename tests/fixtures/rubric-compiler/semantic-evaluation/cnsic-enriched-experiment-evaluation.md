---
schema: human-semantic-evaluation/v1
subject: "CNSIC enriched second blind sdd-init experiment"
status: needs-human-approval
recommendation: reject
confidence: high
artifact_freshness: fresh-source-bound
---

# CNSIC Enriched Blind Experiment Evaluation

This is an advisory evaluation of a fresh enriched blind experiment. It credits
producer improvement independently from activation validity.

## Source Bindings

| Role | Read-only source | Binding |
| --- | --- | --- |
| Experiment clone | `/home/kozz36/cnsic-agent-init-primary-experiment-v2-20260731` | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab` |
| Generated output | `openspec/config.yaml` | `sha256:a072e4e8a7e817b099db9c6b186c6baf6bb6d12126c58f75abf38e6e05cb7b68` |
| Experiment manifest | `.experiment-evidence/manifest.txt` | `sha256:16bd112257f1a330c281d2860c29422a352d112317a61f4804c0db422bbfa83a` |
| Consumed reference block | `.experiment-evidence/manifest.txt` | `sha256:06eb642b8f5d1a2789426ca19e96060881793b1d4e401bf5ff542ba622c45313` |
| Root command policy | `AGENTS.md`, `scripts/run_tests.sh` | `sha256:90c1131f19208737262a5283dd316d564809809a2717b242811e4dfc673782c6`; source-bound wrapper semantics |
| Frontend/E2E commands | `frontend/package.json`, `tests/e2e/playwright/package.json`, frontend CI | `sha256:01b3e4cfc5f646b25acd368ccc8bff550e1576a00b6b64ad63e45db71f7ee719`; `sha256:5f5a242c896457cb77aacc2ce9327d10cb5a839c3221687d763263258e837a3d`; CI sets `working-directory: frontend` |
| Rejected comparator | `cnsic-primary-experiment-decision.md` | `decision: reject`; prior evaluation remains immutable |

## Evaluation Dimensions

| Dimension | Evidence-based assessment | Uncertainty |
| --- | --- | --- |
| Stack/capability detection | Detects backend unit/integration/smoke, frontend unit/lint/build, and browser E2E capabilities with declarations and tool proof. | Active IDs do not resolve to method identities. |
| Implementation mode fidelity | Strict modes correctly replace v1 all-standard behavior for migrations, backend, security, and cross-layer work. | Frontend and behavior-preserving refactor strict modes conflict with canonical non-test-first policy. |
| Test-authoring discipline/forwarding fidelity | Strict rows can forward full test-first workflow without duplicating prose. | Bug, RBAC, tool, egress, port, and migration-specific obligations are not encoded. |
| Functional validation evidence | Adds integration and smoke capability classes and separates docs/scripts skips. | Direct pytest bindings omit reusable mutex/env/mount/build-before-test semantics. |
| Visual/E2E validation evidence | Frontend and cross-layer rows select E2E, without v1's false Playwright cwd for Vitest. | Commands omit frontend/E2E workdirs and committed spec/FINDINGS requirements. |
| Command/harness fidelity | CI declarations support `-n 12`, Python 3.13, Node 22.22.3, and CI workdirs. | A CI declaration does not make command strings portable active bindings without those contexts. |
| Work-type coverage | Ten rows materially improve coverage and preserve documented docs/scripts exceptions. | Grouped skip conflicts with canonical dependency, config/infra, and prompt requirements. |
| Multi-match resolution | Declares all-row matching, strictest-wins intent, and unmatched-only default. | The emitted shape only says `all-rows`; it does not carry a consumer-valid resolution model. |
| Coverage and other evidence | Avoids inventing unsupported formatter/typecheck commands. | No complete binding-to-row mapping or evidence artifact requirements exist. |
| Fail-closed uncertainty | Manifest records maintainer inputs and no unsatisfied items. | The output marks active despite unresolved identities and incompatible activation shape. |
| Orchestrator forwarding behavior | The output attempts an active rubric. | It lacks the required `ResolutionV1` state, transaction, authority, digest, and readback contract. |
| Project-specific policy gaps | Security/state, cross-layer, and scripts categories are added. | RBAC Twin, real SQL/dataclass, egress, port wiring, smoke --build, and Judgment Day triggers remain absent. |

## Similarities

- The enriched experiment is a genuine source-bound 10-row/8-binding blind run.
- It records explicit maintainer resolution for grouped and unmatched skips.
- It correctly treats Playwright as validation evidence, and no longer asserts the v1 Vitest-in-Playwright-cwd contradiction.

## Differences

- The producer is substantially richer than the rejected first primary experiment, but its `active/authoritative` claim is not compatible with the consumer/compiler activation schema.
- Frontend npm and Playwright commands lack explicit workdirs; backend direct pytest lacks reusable wrapper constraints.
- Maintainer-selected skips are intentional, but differ materially from #3351 for dependencies, config/infra, and prompts.

## Behavioral Impact

If activated, binding resolution is ambiguous and commands can execute from the
wrong directory or outside required harness constraints. The grouped/default
policy can suppress canonical validation for dependency, configuration,
operations, and prompt changes. These blockers concern activation; they do not
erase the demonstrated improvement in producer inference.

## Unsupported Or Missing Claims

- Do not claim active binding IDs resolve: no matching method `id` declarations exist.
- Do not claim frontend/E2E commands are self-contained: their correct workdirs and prerequisites are external to the command strings.
- Do not claim CI's fixed `-n 12` command supplies the root wrapper's portable mutex, environment, mount, or stale-image protections.
- Do not claim `active/authoritative` activates the overlay: it is not a bound `ResolutionV1` record.

## Recommendation

`reject` with high confidence for activation. Retain the enriched experiment as
improved source-bound producer evidence. A correction requires a new fresh
blind run with declared binding identities, executable contexts/harnesses, a
consumer-compatible activation record, and an explicit policy reconciliation
for the selected skip groups.

## Maintainer Decision

decision: pending
recorded_by:
recorded_at:
decision_authority: maintainer
