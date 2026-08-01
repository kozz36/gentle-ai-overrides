---
schema: human-semantic-evaluation/v1
subject: "CNSIC primary blind sdd-init experiment"
status: needs-human-approval
recommendation: reject
confidence: high
artifact_freshness: fresh-source-bound
---

# CNSIC Primary Blind Experiment Evaluation

This is an advisory semantic evaluation of a fresh blind experiment. Manifest
integrity and semantic adequacy are separate: matching hashes and blindness do
not make the generated policy authoritative or correct.

## Source Bindings

| Role | Read-only source | Binding |
| --- | --- | --- |
| Experiment clone | `/home/kozz36/cnsic-agent-init-primary-experiment-20260730` | `HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab` |
| Generated output | `openspec/config.yaml` | `sha256:6411df4b4b4ecb51f39319e58752da8bb9f5ff03937281f16baeec7eb0d7456b` |
| Experiment manifest | `.experiment-evidence/manifest.yaml` | `sha256:c114ee522da87d2eb43f2efa981c30d2066828d5e4389c179480988ca1aaa222` |
| Blindness evidence | `.experiment-evidence/forbidden-sources.txt` | generated run reports no Engram, #3351, or previous-evaluation access |
| Root project policy | `AGENTS.md` | `sha256:90c1131f19208737262a5283dd316d564809809a2717b242811e4dfc673782c6` |
| Development commands | `README.md`, `scripts/run_tests.sh` | `sha256:bfb96e94d28fe4a60428e129f2190a0c0fb29c5cab0e187d5861cbbc22492283`; `sha256:157318f9e958a436f7fe575fcb8379776cf06b3cd5a0161ecc219004b615ea12` |
| Frontend and E2E manifests | `frontend/package.json`, `tests/e2e/playwright/package.json` | `sha256:01b3e4cfc5f646b25acd368ccc8bff550e1576a00b6b64ad63e45db71f7ee719`; `sha256:5f5a242c896457cb77aacc2ce9327d10cb5a839c3221687d763263258e837a3d` |

## Evaluation Dimensions

| Dimension | Evidence-based assessment | Uncertainty |
| --- | --- | --- |
| Stack/capability detection | Correctly identifies Python/FastAPI, Vue, Docker, pytest, Vitest, ESLint, build, and Playwright capability classes. | The manifest does not cite root `AGENTS.md`, despite its mandatory scope gates. |
| Implementation mode fidelity | All generated implementation rows are `standard`; docs is `skip`. | README/CI prove commands, not an all-standard implementation policy. Canonical #3351 provides contrary strict workflow for behavior, bug, and migration categories. |
| Test-authoring discipline/forwarding fidelity | The producer/orchestrator contract can supply full workflow only when a valid row forwards `strict-tdd`; no repeated prose is required. | This experiment emits no strict rows, so its output does not invoke that workflow for categories where canonical policy selects it. |
| Functional validation evidence | Source, boundary/api, and migration select unit, integration, and build bindings; boundary/api adds E2E. | Direct pytest omits required mutex wrapper and environment/build constraints. Migration/RBAC/tool/egress-specific evidence is not selected. |
| Visual/E2E validation evidence | UI and boundary/api select the Playwright binding, which the E2E package supports. | The UI Vitest binding has contradictory cwd and declaration/proof sources; generated evidence does not require canonical committed spec/FINDINGS artifacts. |
| Command/harness fidelity | Dockerfile/Compose support the container-build binding; CI supports frontend test/build commands in `frontend`. | `frontend-vitest` runs from `tests/e2e/playwright`, where `npm test` is Playwright, not frontend Vitest. Root AGENTS requires `scripts/run_tests.sh` or PowerShell mutex wrapper for Docker pytest. |
| Work-type coverage | Covers source, boundary/api, UI, migration, docs, and default. | It lacks explicit bug-fix, RBAC, cross-context, agent-tool, egress, port-wiring, prompt, config, infra, scripts, and dependency triggers. |
| Multi-match resolution | Declares all-row matching and a closed mode order. | Broad signatures lack concrete path/symbol triggers necessary for project-specific selection. |
| Coverage and other evidence | Correctly marks missing backend lint, frontend typecheck, and formatter commands as unsupported from cited tracked evidence. | It marks coverage unsupported; this is plausible from the cited manifest, but differs from the canonical project capability record and needs maintainer review. |
| Fail-closed uncertainty | Raises questions about docs, smoke binding, and Playwright scope. | It does not fail closed on internally inconsistent `frontend-vitest`, omitted mandatory root policy, or all-standard deviation. |
| Orchestrator forwarding behavior | Fresh output is marked active/authoritative in its own shape and reports a blind run. | It is not `ResolutionV1` activation authority for the overlay consumer and cannot authorize downstream forwarding. |
| Project-specific policy gaps | Explicit questions identify some uncertainty. | The result omits canonical manual rules and the manifest does not demonstrate consideration of root AGENTS gates. |

## Similarities

- The blind generator discovers the principal stack, unit/integration/build/E2E capability classes, docs skip behavior, and all-row resolution model.
- It uses source declarations and dependency proofs rather than host-installed tools.
- It records uncertainty instead of inventing backend lint, formatter, or frontend typecheck commands.
- UI validation includes a real Playwright package binding; Playwright remains validation evidence rather than implementation mode.

## Differences

- Canonical #3351 selects strict workflow for new behavior, bug fixes, and migrations; the blind output assigns `standard` to every implementation row and provides no tracked policy evidence for that deviation.
- Root `AGENTS.md` requires the mutex test wrapper and stale-image build handling, but generated backend commands use direct pytest and the manifest omits AGENTS from its cited evidence.
- The `frontend-vitest` command runs from the Playwright package but cites frontend Vitest sources. This is a binding contradiction, not a formatting difference.
- The output lacks canonical project-specific triggers and validation for RBAC, cross-context reads, agent tools, egress, port wiring, migration twins, smoke, and Judgment Day.

## Behavioral Impact

If activated, the policy could run the wrong frontend test tool under the
frontend-unit binding, bypass the required test mutex, miss stale-image rebuild
conditions, and under-select strict workflow or project-specific validation for
high-risk changes. The manifest's integrity is useful evidence about the blind
experiment, but it cannot compensate for these behaviorally material gaps.

## Unsupported Or Missing Claims

- Do not claim the seven bindings are all semantically valid: `frontend-vitest` is contradicted by its own cwd and the Playwright package script.
- Do not claim all-standard implementation mode is justified by README/CI command evidence alone; those sources do not establish test-authoring order.
- Do not claim the fresh artifact is activation authority; it lacks the overlay consumer's bound `ResolutionV1` envelope.
- Do not treat the absence of duplicated strict-cycle prose as a defect; it becomes relevant only when strict mode is selected and forwarded.

## Recommendation

`reject` with high confidence. Keep the experiment as useful blind-inference
evidence, but do not activate or revise it in place. Correct the frontend
Vitest binding, ingest or explicitly reconcile root AGENTS policy, model
project-specific triggers/evidence, and justify any all-standard mode policy in
a new fresh source-bound experiment.

## Maintainer Decision

decision: pending
recorded_by:
recorded_at:
decision_authority: maintainer
