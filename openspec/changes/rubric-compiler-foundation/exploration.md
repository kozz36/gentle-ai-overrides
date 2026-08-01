## Exploration: rubric-compiler-foundation

### Current State

The project is a Bash 3.2+/POSIX anchor-based overlay. `apply.sh` owns fail-closed, idempotent transforms across multiple host surfaces, with structural anchors, backups, atomic same-directory replacement, symlink refusal, target-drift checks, and `--check` preflight. `tests/run.sh` provides hermetic fixture regression tests outside `$HOME`; `tests/init-rubric-contract.sh` covers the static rubric-producer contract. `openspec/config.yaml` currently contains one active authoritative rubric: all matching non-default rows apply, strictest mode wins, and evidence is unioned. The existing producer contract in `deltas/sdd-init-rubric.md` already separates command declaration from independent tool proof and requires generated/manual provenance, but it is a policy producer rather than a general repository-to-rubric compiler.

The measured benchmark evidence rejects one-pass generation as a production foundation:

- CNSIC v1: 6/16 signature recall, 2/16 exact policy, and 1/7 canonical bindings.
- CNSIC v2: 5/16 signature recall, 1/16 exact policy, and 1/7 canonical bindings.
- Gentle AI v2: 12/12 mechanical triggers, but 0/12 row provenance and only 1/7 specialized high-risk scopes fully covered.
- One-pass generation emitted false self-checks claiming manifests were absent.
- CodeGraph improves boundary discovery, call paths, and fan-out analysis, but does not establish policy mode or command runnability.

CNSIC's canonical rubric is an oracle for evaluation only. It MUST NOT be supplied as generator input. Repository-only candidate quality is the quality achievable from project evidence before confirmation; post-confirmation 1:1 parity with CNSIC is a separate oracle comparison and is not evidence that the repository-only compiler inferred hidden policy.

### Affected Areas

- `deltas/sdd-init-rubric.md` — existing producer contract and policy ownership boundary; likely extension point for compiler-facing contracts, not a place to let the consumer generate policy.
- `openspec/config.yaml` — current authoritative persisted rubric schema and concrete shell bindings; future compiler output must preserve this single active path and provenance semantics.
- `apply.sh` — existing anchor-based overlay and host/surface map; affected only if the foundation later changes the injected producer contract or adds compiler assets.
- `tests/init-rubric-contract.sh` — static contract coverage for policy production, selection blocking, schema, and provenance.
- `tests/run.sh` — hermetic integration coverage for fail-closed transforms, idempotence, backups, and host resolution; likely home for compiler boundary fixtures only if they remain shell-level.
- `README.md` — declares runnable commands, CI proof, supported stack, and scope; evidence extractor must treat these declarations as evidence, not as executable policy by themselves.
- `.github/workflows/test.yml` — independent tool proof and command declarations for the current shell bindings.
- `persona/` and existing `deltas/` — managed overlay inputs whose structure and ownership must not be confused with project-policy evidence.
- Likely new assets: a versioned compiler contract/schema, normalized-fact fixtures, policy-question/manual-row fixtures, validator fixtures, and isolated CNSIC/Gentle AI benchmark harness data outside the active overlay path.

### Approaches

1. **One-pass enriched prompt** — provide repository text, CodeGraph context, benchmark guidance, and a strict output schema to one LLM call.
   - Pros: smallest apparent implementation; low orchestration overhead; useful for exploratory candidate drafts.
   - Cons: reproduces the measured failures; conflates extraction, inference, policy selection, validation, and self-assessment; cannot reliably distinguish absent evidence from unobserved evidence; false self-checks and missing row provenance remain likely; hard to make command runnability and strictest-wins semantics deterministic.
   - Effort: Low initially, High to harden.

2. **Staged LLM compiler with normalized intermediate facts and deterministic validator** — extract repository/CodeGraph evidence, normalize commands/triggers/scopes/provenance, ask the LLM only to propose candidate rows and blocking questions, then deterministically validate and activate.
   - Pros: directly addresses benchmark failures; preserves evidence lineage; supports uncertainty and manual rows; deterministic checks can reject invented commands, circular tool proof, malformed modes, ambiguous signatures, missing scope, and invalid activation; CodeGraph is used for discovery without granting it policy authority.
   - Cons: more artifacts and orchestration; normalization schema must evolve; LLM candidate quality still needs benchmark coverage and explicit confirmation for repository-silent rules.
   - Effort: Medium.

3. **Code-first deterministic extractor/compiler with LLM only for candidate policy/questions** — parse manifests, CI, scripts, docs, and diff-signature patterns deterministically; use the LLM for suggestions or questions over normalized facts; validate and serialize entirely deterministically.
   - Pros: strongest reproducibility, provenance, runnability checks, and auditability; minimizes hallucination; easiest to compare repository-only output across versions.
   - Cons: high initial scope for cross-ecosystem command and trigger parsing; deterministic extraction can miss semantic conventions and specialized high-risk scopes; policy questions still require human confirmation.
   - Effort: High.

### Recommendation

Build the smallest production-ready foundation as Approach 2, constrained toward deterministic extraction and validation from Approach 3. The first slice should not attempt a universal parser or automatic activation. It should define a versioned normalized-facts model, collect evidence with explicit source locations and confidence/unknown states, generate candidate rows plus blocking questions, run a deterministic validator, and activate only confirmed valid policy. Deterministic extraction should cover the current project and benchmark fixture shapes first; later ecosystems can add extractors without changing the policy schema.

Boundaries:

1. **Evidence extraction** reads repository files, manifests, CI, scripts, docs, and CodeGraph results. It records observations and source locations; it does not choose mode, infer hidden policy, or treat CodeGraph as proof of runnability.
2. **Normalization** converts observations into stable facts: command, method, scope/signature coverage, workdir, shell/platform/environment, dependencies, `requires`, `kind`, declaration location, independent tool proof, and explicit unknowns. It rejects or preserves ambiguity rather than silently filling fields.
3. **Policy questions/manual rows** represent repository-silent decisions, specialized high-risk rules, and conflicts. They are versioned and user-confirmed; canonical oracle rows are never copied into this input path.
4. **Candidate generation** proposes generated rows and questions from normalized facts. It may use an LLM, but every claim must point to facts or be marked unresolved; it cannot persist an active rubric.
5. **Validation** is deterministic and fail-closed: schema/mode checks, signature production coverage, binding completeness, independent tool proof, scope compatibility, default-row semantics, all-rows/strictest-wins resolution, duplicate/conflicting rows, and runnable-command checks.
6. **Activation** persists exactly one active authoritative rubric only after confirmation and validation, preserving manual rows and deterministically replacing generated rows. It must maintain equivalent Engram/OpenSpec semantics and a blocking envelope when selection is unresolved.
7. **Benchmark harness** runs isolated repository fixtures and scores repository-only recall, exact policy, binding completeness, row provenance, specialized scope coverage, validator correctness, and post-confirmation oracle parity separately. CNSIC's canonical rubric is loaded only by the scorer as an oracle.
8. **Later work-unit resolution/#262 enforcement** consumes the activated rubric to classify diffs and enforce selected obligations. It is downstream of compilation and must not become an implicit policy generator or bypass activation/confirmation.

The initial foundation should target the current shell project plus benchmark fixtures, with explicit outputs for `unknown`, `detected-but-unsatisfied`, and `needs-confirmation`. It should support the existing `strict` versus `rubric` blocking decision, but leave broad automatic policy synthesis and #262 work-unit enforcement to later changes.

### Risks

- Repository evidence can be incomplete; treating absence as absence-of-policy will recreate the false self-check failure. Preserve unknowns and ask questions.
- A binding can have a plausible command but no independent reproducible tool proof; such bindings must remain detected-but-unsatisfied.
- Generated rows and manual rows can drift during re-init; stable row identity and deterministic replacement are required to preserve manual rows exactly.
- CNSIC oracle parity can contaminate development if canonical rows enter prompts or fixtures used for generation; isolate oracle data in scoring-only assets.
- Adding compiler behavior directly to `apply.sh` would expand the overlay's blast radius and violate its narrow transformation responsibility; keep compiler contracts/assets separate until a later, explicit integration change.

### Ready for Proposal

Yes. The proposal should scope a staged compiler foundation around normalized evidence, candidate/questions output, deterministic validation, confirmation-gated activation, and isolated benchmark scoring. It should explicitly defer universal ecosystem extraction, automatic inference of repository-silent policy, and work-unit/#262 enforcement.

**Status**: success
**Summary**: Explored three rubric compiler architectures against current overlay boundaries and measured CNSIC/Gentle AI evidence. Recommended a staged compiler with deterministic normalization/validation and confirmation-gated activation.
**Artifacts**: `openspec/changes/rubric-compiler-foundation/exploration.md` | Engram `sdd/rubric-compiler-foundation/explore`
**Next**: sdd-propose or sdd-design
**Risks**: Oracle contamination, false absence claims, unproven commands, and generated/manual row drift.
**Skill Resolution**: fallback-path — `/home/kozz36/.config/opencode/skills/sdd-explore/SKILL.md` plus shared SDD references.
