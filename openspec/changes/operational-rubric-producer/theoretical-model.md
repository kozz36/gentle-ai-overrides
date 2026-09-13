# Operational Rubric Producer: Theoretical Model

**Status:** selected shipping baseline of source-faithful theory for the stock
canonical producer contract and retained parent gates; neither an OpenSpec approval nor activation claim.
Deferred prototype-only proposal, supplied-C publication, diagnostic assembly, private fixtures, and the 109-operation Pi unit are excluded.

## Answer and quick path

A satisfactory project rubric is produced semantically by the existing
`sdd-init` subagent through its prompt. It is then preserved by a deterministic
canonical conversion and published only through existing confirmation and
readback gates. The overlay augments the existing parent-to-child flow; it does
not make a child the policy resolver or create a new policy engine.

```text
existing sdd-init subagent
  -> proposed semantic candidate (not active)
  -> source-fidelity validation + normalized preview / candidate identity
  -> human selection + exact candidate confirmation
  -> deterministic final canonical compilation
  -> existing publication gate
  -> independent canonical readback
  -> canonical sdd-init policy
  -> parent slice resolution
  -> existing apply/verify child prompt
  -> phase evidence
```

Candidate normalization, preview, and identity precede confirmation. Final
canonical compilation may consume `ConfirmationV1` only after that pending
candidate exists. Approval is distinct from activation: publication may occur
only after the selected, confirmed candidate has passed its existing
backend-specific write and independent readback gate. A `proposal-only` request
instead returns `rubric-proposal-diagnostic/v2` and
exits with `active: false` and `authoritative: false`; it cannot activate,
publish, or forward a rubric.

## Boundary map

| Boundary | Owner | Input | Output / fail-closed rule |
| --- | --- | --- | --- |
| Semantic generation | Existing `sdd-init` subagent | Bounded, cited project facts and human decisions | A proposed semantic candidate. Prompt judgment is not serialization or policy selection. Missing/ambiguous input produces questions or abstention. |
| Fidelity validation and preview | Canonical conversion path | Candidate plus cited source material | Establishes exact source-to-pending-model equivalence and the existing normalized candidate identity. Unsupported, ambiguous, duplicate, or unbound semantics are rejected with a source-linked diagnostic. |
| Deterministic final compilation | Existing declared canonical compiler path | Confirmed normalized candidate, including `ConfirmationV1` | Serializes one sorted `CanonicalPolicyModelV1` from existing `EvidenceV1` and `CandidateV1` names. It must not invent a command, default, mode, or combination rule. |
| Policy choice and confirmation | Human maintainer | Exact pending candidate digest and blocking questions | `strict` or `rubric` representation choice, then the required exact `ConfirmationV1`. Neither conversational agreement nor parse validity proves representation capability or activation. |
| Publication | Existing producer/publisher gate | Confirmed canonical model and configured backend | Active policy only after the declared atomic publication and independent readback. The supplied-C OpenSpec exception is deferred prototype-only material and is not included in this release. |
| Slice resolution | Parent orchestrator | Active canonical policy and one declared apply/verify slice | Resolved mode and phase-applicable obligations. The parent is read-only for policy authorship. |
| Execution | Existing `sdd-apply` or `sdd-verify` child | Plain parent prompt plus its ordinary artifacts | Phase evidence. A child may read configuration, but may not silently redetermine an opposite mode; a detected conflict fails or escalates. |
| Review | Human reviewers / native RDD provider | Provider-owned review material | Review is not semantic generation, canonical conversion, or policy resolution. `sdd-verify` is also not a generic reviewer. |

No normal path needs a new generator, matcher, parser, trace wrapper, consumer
wrapper, JSON API, or artifact store. “Deterministic converter” names the
required behavior of the declared canonical compilation path, not permission to
add an independent engine.

## One canonical policy source

The session preflight selects the backend; YAML `artifact_store` metadata does
not select it. For that selected backend, there is one canonical policy source:

| Configured backend | Canonical active source | Consistency requirement |
| --- | --- | --- |
| OpenSpec | `openspec/config.yaml` with `testing.rubric.active: true` | Read only the declared active rubric and its resolution. |
| Engram | `sdd-init/{project}` carrying the authoritative rubric | Read only the canonical topic and its declared validity evidence. |
| Hybrid | Both configured stores | Require semantic equivalence; OpenSpec remains `ResolutionV1` authority. |
| None | Inline producer result only | It is not an active consumer policy or a transcript-backed substitute. |

There is no hidden foreign file, automatic backend switch, or fallback to a
second store after an invalid active policy. Missing, conflicting, unreadable,
or ambiguous active policy stops apply/verify for human clarification. Binary
`strict_tdd` is fallback-only when there is genuinely no rubric, not when a
rubric is invalid. Policy words describe concepts; they do not introduce new
machine enums or a new intermediate representation.

## Source-faithful conversion

Historical fixture and evidence files are out-of-release and not distributed with this export.
The historical source is context-only and non-active; its `source.md` reference identifies out-of-release evidence, not a release path.
It contains sixteen signature rows and historical resolution, commands, skill references, and evidence obligations. A future converter must preserve those
facts as source-linked semantics, including:

- all sixteen rows and their stated conditions, obligations, commands, skills,
  and evidence;
- the source's unmatched default absence, rather than supplying a default;
- its conditional resolution: pure `frontend/src/**` is a Playwright exception;
  test-first wins when a stated test-first row matches; otherwise the source
  says to use the lowest-rigor matched row;
- scope and combination conditions such as “pure frontend” rather than a
  flattened path-only category; and
- source-qualified historical counts and snapshot claims as historical facts,
  never as current project truth.

The declared generic canonical schema uses all-rows, strictest-wins, and
evidence union. That conflicts with source-specific exceptions and
lowest-rigor behavior. This is a compatibility gap, not license to rewrite the
policy. Technical source-to-model equivalence is the first obligation: only
proof that every condition is represented exactly permits a candidate to reach
confirmation. Unsupported semantics produce a bounded, source-linked diagnostic
and no activation; they must not be flattened to generic strictest-wins, inferred
as a universal rule, supplied with a default, or given invented modes.

When technical analysis identifies unsupported semantics, a human may choose a
separately scoped representation extension, an explicit policy change, or continued
non-activation. Any resulting candidate still requires equivalence proof against
its explicitly selected source before confirmation or activation. Approval cannot
create representational capability; unsupported semantics remain rejected.

An existing schema being able to parse YAML is not evidence that it represents
all legacy semantics. “CanonicalPolicyModelV1 capable” may be claimed only
when source-to-model fidelity and canonical readback are demonstrated for the
selected source. Unresolved phase bindings remain unresolved: `rules.apply.test_command`
and `rules.verify.test_command` are phase-specific only as declared; a declared
legacy flat binding stays flat. Do not invent `testing.test_command`, a
universal phase binding, or commands for unknown TS/SA/SD definitions.

## Parent handoff and child boundary

For each distinct actual apply or verify slice, the parent reads the canonical
policy once per session and resolves that slice afresh from its declared intent
and the policy's own matching rules. Its existing plain prompt handoff contains:

- canonical source reference and current slice;
- matching policy references and the resolved method/MODE;
- exact phase-applicable commands, disciplines, evidence, and skill paths; and
- declared blocking conditions or source limits relevant to the slice.

This is prompt content, not a mandatory audit format or tool protocol. Parent
raw decision capture before launch can become future evidence, but is not
another consumer wrapper. The runtime extension may inject preflight and native
SDD status; it does not resolve MODE. The normal installed parent baseline is
binary-forwarding and the child also reads secondary configuration, so prose
alone does not prove native pipeline invocation or child enforcement.

## Reliability evidence required before activation

| Check | What it must establish | What it must not claim |
| --- | --- | --- |
| Semantic coverage | Every supplied rule, condition, command, skill, and absence has a cited representation or cited rejection. | That an LLM-generated rubric is complete merely because it parses. |
| Canonical round trip | Deterministic model serialization and independent canonical readback preserve the approved semantics and digest. | That a diagnostic assembler is a canonical converter. |
| Approval guards | Preview, exact-candidate confirmation, publication approval where applicable, and stale/drift rejection work. | That representation selection alone activates policy. |
| Source identity | Fixture text and provenance remain intact, including all sixteen historical rows. | That historical numeric facts or commands are current or executable. |
| Parent/child behavior | Actual parent prompt forwarding and child decision behavior agree with an active canonical source. | That text injection guarantees runtime enforcement. |

The matrix must independently derive expected outcomes for strict bug fixes,
docs-only work, pure frontend work, behavior-preserving refactors, mixed work,
and unmatched work from the selected source—not from a prompt answer. It must
separate canonical verification admission from read-through behavior. Any
executed future validation captures full stdout, stderr, exit status, and
artifact hash before a validator decides PASS. This document authorizes none of
those executions: a read-only fixture or docs-only case cannot discriminate an
active runtime path from an inactive one.

## Current state and remaining work

**Stock baseline:** The stock base supplies the canonical producer contract and
its existing confirmation, publication, and readback gates. This release
records source-faithful theory only; it claims no new producer, wiring, activation, or compatibility proof.

**Release parent boundary:** The selected Pi forwarding text contains only the
reviewed policy-defined parent contract: session-store selection, read-once
canonical policy, fresh per-slice resolution, policy-defined matching, plain
phase-prompt forwarding, phase command rules, and no-rubric fallback. Existing
parent gates remain unchanged; the current dirty supplied-C publication override
is excluded.

**Historical review context:** The latest reviewed 109-operation Pi unit and
its recorded controls are historical observations, not a PASS for this release
candidate. Private fixture evidence and the prototype proposal-only,
supplied-C-publication, and diagnostic-assembler paths are deferred and
out-of-release.

**Selected release projection:** This selected four-file release candidate is
pending its own parent-owned combined integration tests, one version decision,
and combined Judgment Day. No prior PASS is reused as a result for this
candidate; this export performs no runtime, installation, publication,
activation, or integration work.

**Known gaps:** produce technical source-to-model equivalence evidence, confirm
actual producer-to-compiler-to-publication wiring, and test actual parent prompt
and child behavior against an active policy. If technical analysis identifies a
gap requiring a product change, that change needs the explicit separately scoped
decision stated above. The lost August source is unavailable and cannot establish current policy.
No automatic retry, reset, or new-objective evasion is allowed.

## Delivery order and review boundary

1. Close this model, then coordinate both worktrees. The parent freezes one
   immutable combined candidate identity before Judgment Day launches.
2. Run Judgment Day with two blind judges before any PR or merge.
3. Every correction requires corroborated severe findings and must stay within
   its explicitly authorized narrow scope. Obtain approval before the first
   correction round; new scope requires new approval. Warnings remain
   informational; contradictions escalate.
4. Use at most two bounded correction/re-judgment rounds under the installed
   contract, never an endless fix loop; then verify the resulting candidate,
   whether corrections were required or not.
5. Make the separate human decisions for PR and merge, then deliver one combined
   overlay version. A single version does not automatically require one oversized
   PR; choose review slices honestly during coordination.

Do not add an ordinary four-review adversarial pass to the same Judgment Day
target. This document neither grants delivery gates nor authorizes a PR, merge,
activation, implementation, test run, or runtime experiment.

## Reading checklist for the next unit

- [ ] Treat `theoretical-model.md` as a model and source map, not active policy.
- [ ] Preserve historical approved design/spec/tasks and the protected fixture.
- [ ] Stop on unsupported legacy semantics instead of silently normalizing them.
- [ ] Keep semantic judgment, deterministic conversion, publication, and
      runtime forwarding as separately evidenced boundaries.
- [ ] Prove exact source-to-model equivalence, or retain the source inactive.
- [ ] Treat any later policy or representation change as a separately scoped
      product decision, not as validation of technical facts.
