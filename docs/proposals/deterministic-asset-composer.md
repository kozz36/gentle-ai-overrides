# Deterministic asset composition

**Status:** Candidate-only implementation available. See the [CLI and input contracts](../../composer/README.md). Installation and native approval remain separate.

Generate reviewable Pi asset candidates from pinned official sources, the published overlay, and confirmed preferences. The normal path is deterministic and uses no LLM. Conflicts stop composition for review; they do not trigger automatic generation or installation.

## Scope

The first version targets the fourteen user-owned Pi definitions reconciled during maintenance: thirteen `sdd-*` agent definitions and `sdd-verify.chain.md`. The exact target inventory is an explicit input, not an unrestricted filename glob.

It complements the existing global overlay, which serves eight integrations. It does not replace its installer, manage unrelated assets, or reconcile project-local definitions.

The maintenance baseline was Gentle AI 2.8.2, gentle-pi 2.6.2, Pi 0.85.1, and overlay `v2.6.0-overlay.3`. These are historical inputs, not permanently hardcoded supported versions.

## Why mechanical composition is sufficient

| Selected adaptation | Authoritative input | Operation |
| --- | --- | --- |
| Agent bodies and verify chain | Pinned official package assets | Copy the selected bodies; preserve their contracts |
| Init overlay | Published overlay payload | Replace the defined region with the selected published block |
| Model and thinking fields | Twelve confirmed per-role pairs | Compose only the declared structured fields |
| MCP allowances | Seven confirmed role allowances | Preserve the explicit selections without expanding permissions |
| CodeGraph guidance | Pinned current official guidance | Copy the official blocks without synthesizing local restrictions |

In the completed update, twelve of thirteen CodeGraph blocks already matched the official guidance; only apply needed refreshing. The old 537-line init prototype was replaced with the selected published 63-line block.

These operations can change behavior substantially, but they do not require invented prose. Previous work principally selected sources, preserved preferences, checked ownership, and verified results.

The additional local CodeGraph capability boundary was explicitly rejected. It must not appear as an inferred improvement.

## Inputs and reproducibility

Composition requires an explicit, bounded input bundle:

- Official source versions, provenance, and content hashes, including the selected CodeGraph guidance.
- Overlay revision and payload hashes.
- Composer and serialization-rule version.
- Exact target inventory and confirmed model, thinking, and tool preferences.

Equal composition inputs must produce byte-identical candidates. Version labels alone are insufficient; input bytes must match their recorded hashes. Serialization and newline rules must be explicit and versioned.

Do not include timestamps, random temporary paths, or machine-specific absolute paths in generated asset content. Keep observation times and other operational metadata separate from reproducible outputs.

Installed files and the last approved baseline are comparison inputs, not sources from which to reconstruct official bodies. Keep host-specific preferences, snapshots, and provenance private; do not commit raw HOME configuration or secrets.

## Composition flow

1. Verify pinned pristine official inputs and the explicit target inventory.
2. Apply the existing versioned overlay transformations in an isolated candidate environment.
3. Compose confirmed structured preferences and selected official CodeGraph blocks.
4. Verify candidate structure, defined replacement boundaries, and preservation of unrelated content.
5. Compare candidates with installed files and the last approved baseline; emit a plan and diff.

Starting from pristine inputs prevents cumulative patching of previously generated output. Running after an overlay update does not make a patched installation sufficient provenance on its own.

The installer has no public isolated rendering API. The implemented adapter is a small, versioned Python implementation of the published Pi-init transformation, checked against its pinned public shell function. It consumes the supplied payload without sourcing the installer or its globals. Future transformation-contract changes require an explicit adapter review; this is not a second policy engine.

## Comparison and conflict contract

For each inventoried target, let:

- **B** be its last verified, approved postimage.
- **I** be its currently installed content.
- **N** be its newly composed desired content.

| Condition | Plan result |
| --- | --- |
| `I == N` | No write needed; byte equality does not confer ownership |
| `I == B` and `N != B` | Propose the bounded update |
| `I != B` and `I != N` | Report local drift or conflict; do not overwrite |
| Baseline absent | Require explicit baseline bootstrap before an update; matching `I == N` still needs no write |
| Target missing, added, or retired | Report an inventory change; do not create or delete installed targets |
| Ownership or a supported contract changed | Report the change and stop automatic reconciliation |

Inspect installed content even when `N == B`: a source-unchanged update must not hide manual drift. Conversely, unchanged official source bytes do not imply a no-op when preferences or the overlay change.

Bootstrap must use verified evidence, not relabel arbitrary installed content as a previously generated result. Ownership is observed separately. Neither a baseline nor byte equality authorizes package adoption or changes to the native ownership registry.

## Boundaries and inference

Require valid hashes, supported schemas, unique replacement anchors, and unambiguous confirmed preferences. Preserve content outside declared regions and fields. Do not resolve changed tool contracts by unioning permissions or selecting an inferred stricter policy.

Missing or ambiguous anchors, incompatible schemas, upstream absorption of an overlay, and conflicting preferences are review conditions. A blocked plan may retain diagnostic candidates, but must not describe them as ready for application.

An operator may separately request a bounded, LLM-assisted proposal for a specific unresolved fragment. That is outside the composer, not an automatic fallback. An accepted adaptation must become an explicit, versioned input or rule and pass fresh verification.

Never infer ownership, permission or research-capability grants, model selections with conflicting evidence, project policies, or new local restrictions. Preserve already confirmed choices without repeatedly asking for approval unless a concrete conflict changes their meaning.

## Outputs and deployment boundary

The implementation produces only a private candidate bundle and a narrow change plan. Each plan row records the target, source provenance, available `B`/`I`/`N` hashes, observed ownership, action, diff, and any blocking reason. The CLI and versioned JSON contracts are documented separately; there is no application command.

Candidate generation writes only to its explicit output location. Reject unsupported path types and do not follow symlinks or project references outside the approved input scope. It must not scan project-specific asset overrides; effective project selection remains a separate check.

Applying a reviewed plan is a separate, explicitly approved maintenance operation. It requires fresh preimage checks, scoped backups, bounded writes, and postimage readback. Reload only affected clients under their own coordination. Rollback is explicit and checks for intervening changes; it is not an automatic response to partial failure.

The current fourteen files remain user-owned. Under the installer behavior verified during maintenance, future force installation preserves them. This proposal does not fabricate adoption or assume that future upstream ownership behavior cannot change.

Source validity, installed hashes, a client reload, functional behavior, and native approval are distinct evidence. None is substituted for another.

## Acceptance criteria

The checklist retains the design requirements; execution evidence is summarized below rather than treating every future workflow as tested.

- [ ] Identical pinned inputs produce identical candidate bytes across fresh isolated runs.
- [ ] Repeated composition starts from clean sources and does not accumulate overlay blocks.
- [ ] Only declared regions and structured fields change; official body and chain contracts remain attributable to pinned sources.
- [ ] `I == N` produces a no-write plan; `N == B` with installed drift still reports a conflict.
- [ ] Missing baselines cannot authorize overwrites; missing anchors, invalid hashes, and unsupported schemas block readiness.
- [ ] Permission and ownership changes are surfaced rather than inferred or silently merged.
- [ ] New, missing, and retired targets are visible without automatic installation or deletion.
- [ ] Writes stay inside the selected candidate output; path handling cannot traverse unrelated projects.
- [ ] An accepted assisted adaptation requires updated explicit inputs or rules and fresh verification.
- [ ] A fixture using the approved maintenance inputs reproduces the fourteen selected postimages.

## Current verification

- Seventy local tests pass normally and with Python optimization enabled; bounded units received independent review.
- An actual private CLI replay from pinned upstream inputs reproduced all fourteen approved postimages byte-for-byte, with fourteen no-op rows and unchanged inputs.
- This is not native approval, fresh ownership discovery, an end-to-end SDD run, or certification of future versions. An externally assisted adaptation workflow has not been exercised.

## Non-goals and next step

Do not build a generic semantic updater, recurring LLM regeneration, native ownership manager, policy compiler, automatic installer hook, full native sync, or process-control mechanism. Do not activate project policies or certify an end-to-end SDD flow through this document.

Use the candidate-only CLI with explicitly prepared, verified input bundles and snapshots. Review conflicts before any separate deployment decision. Live application, automatic input collection, and broader host coverage remain outside this implementation.
