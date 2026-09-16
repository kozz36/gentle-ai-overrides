<!-- shape:skill -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Producer

- `sdd-init` is the single writer of project TDD policy. The orchestrator is read-only: it may relay a blocking envelope but must not select, generate, modify, or persist policy/rubric rows.
- Detect testing capabilities and the CLOSED set of satisfiable evidence methods: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, and `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command.
- Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.
- Presentation and persistence are separate. Deliver a two-level view of one candidate. Reader view FIRST in the user's conversation language (use neutral/professional Spanish for Spanish unless the user explicitly overrides it): concise Markdown overview with a compact `work-type | MODE | key obligation` table, material differences, actionable gaps/risks, the named canonical destination, and the exact full-candidate identity/checksum. Do not dump YAML or a wide command/tool-proof ledger by default. Brevity must not hide meaningful exceptions, blocking evidence gaps, destructive differences, or approval scope.

  Complete technical artifacts are English unless an explicit user/project artifact-language convention says otherwise: full policy Markdown with every row, exact commands, bindings, independent tool proofs, precedence, exceptions, defaults, mixed-resolution rationale, and test-only rationale, plus full serialized YAML when applicable. Technical identifiers and executable commands are never translated. Complete technical artifacts must be clearly accessible through verified artifact paths/references or on request before approval. Both levels faithfully represent the SAME candidate. The overview is not a second policy or a canonical source. If technical detail is unavailable, the identity is stale, or the reader view is misleading, block.

  The full-candidate identity/checksum and named destinations bind approval: explicit approval covers the complete candidate identified by that checksum, not merely the reader overview. A checksum identifies the approved bytes and destinations; it does not prove semantic equivalence. The producer-owned source is authoritative; a parent may relay/render but not author policy. OpenSpec persists YAML only; Engram persists canonical topic full Markdown only; hybrid persists equivalent content in both only when selected; and none has no active persistence. No implicit Engram write follows from the Markdown reader view. `none` returns the full content without activation and keeps complete detail inspectable on request or an appropriate surface rather than silently discarding it. No new artifact store or Engram capability is required for user preview. Readback and final delivery present the concise localized reader view plus full canonical references, not a wall of YAML.
- Generate a visible general work-type catalog, never a fallback policy engine. It always includes `new-observable-behavior`, `bugfix`, `data-schema-migration`, `mechanical-behavior-preserving-change`, `refactor`, `docs-only`, `ci`, `configuration`, `executable-scripts`, `dependencies`, and `tests-only-maintenance`, with an explicit applicability/disposition even when no current path matches. Current project facts supply scopes, real evidence bindings, risks, and justified modes; defaults are proposals requiring approval, not immutable universal mandates. Recommended starts are strict-tdd with real test-first evidence for new observable behavior and bugfix; test-first when feasible plus integrity/compatibility obligations and explicit unavailable handling for data/schema migrations; standard equivalence/regression evidence for mechanical changes and refactors; skip with accuracy review and declared validators only for docs-only; and standard declared checks with risk elevation for CI, configuration, and dependencies. Classify executable scripts by declared behavior/bugfix versus mechanical intent, never by extension alone or blanket skip/strict. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Security, state, or permissions sensitivity is an explicit exception/elevation, never an accidental global strict rule. Missing essential evidence is visible and requires clarification or a decision; a catalog never permits a provider fallback to fabricate bindings.
- Retain the existing signature/rule representation and use explicit intent-qualified rows, not a new schema/parser or runtime adapter. Declared work intent selects MODE; project scope selects only applicable command bindings. Do not create an unconditional path-only strict row that makes a mechanical or refactor intent strict under all-rows. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence. strict-tdd requires RED, GREEN, TRIANGULATE, and REFACTOR evidence; that obligation is distinct from a final green CI run. Hosted CI proof distinguishes an explicit install from a cited image guarantee; neither requires arbitrary version pinning.
- Preserve the existing `strict_tdd` resolution when one binary policy is provably sufficient; otherwise generate a project-derived rubric candidate and block for `strict|rubric`. Before a valid answer, return the candidate but persist no selected policy or active rubric. `strict|rubric` selects only the representation; after the selected candidate is displayed and exactly approved, strict persists `strict_tdd: true` with no consumer-visible active rubric and rubric persists `strict_tdd: false` with the active authoritative rubric. Do not choose or continue downstream while blocked.
- Rubric signatures are open and project-derived. Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs); test paths may supplement but cannot be the only production classification. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union evidence/discipline requirements.
- In rubric mode, serialize exactly one active rubric in `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` with `Status: active/authoritative.`, mechanical matching, and `| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |`; Source is `generated` or `manual`. Mirror active/provenance semantics under OpenSpec `testing:`.
- Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric persists `strict_tdd: false` plus exactly one active rubric. Hybrid writes both only when selected; `none` returns full content without activation and keeps complete detail inspectable.
- OpenSpec: testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. Strict uses `rubric: absent (not active:false, not candidate, no rows)`. The canonical rubric fields are `mode_order: [skip, standard, strict-tdd]`, `matching: all-rows`, `bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof`, and `rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual`.
- Prompt procedure, not an external compiler: Present the reader view first and make the complete project-derived rubric candidate, its capability ledger, and its checksum accessible through verified artifact paths/references or on request before asking `strict|rubric`. A `strict|rubric` answer selects only the representation; it neither approves nor activates any candidate.
- After selection, render the reader view first and make the complete selected-policy candidate and checksum accessible through verified artifact paths/references or on request. Require the maintainer to explicitly approve the complete candidate identified by that checksum, not merely the reader overview, before any write. Any candidate change or source drift invalidates approval; regenerate, redisplay, and obtain a new exact approval.
- Use only ordinary available read/write/bash capabilities to retain or compare candidate bytes and checksum; that comparison is not CAS, a transaction, an opaque authority, or a compiler. Preserve the target preimage and its checksum before writing. Write once only after exact approval, immediately independently read back the same canonical source, and compare the persisted selected-policy content to the approved candidate.
- On a write or readback failure, block and report the preimage, attempted target, and observed content; do not automatically rollback, compensate, or claim atomic/cross-backend transaction guarantees. If a selected backend lacks the required read, write, or independent readback operation, block; do not switch stores or declare a cross-backend result.
- OpenSpec uses only `openspec/config.yaml` `testing.rubric.active`; its readback must show the approved rubric content as active/authoritative. Engram uses only the declared `sdd-init/{project}` topic/header; re-read that exact artifact before reporting active. Hybrid requires independent successful readback of both configured stores; a partial result is blocked and reported, never treated as a fallback or cross-backend atomic success. `none` returns the full candidate without activation, keeps complete detail inspectable on request or an appropriate surface, and never claims an active consumer policy.
- On re-init, preserve manual rows byte-for-byte in the displayed candidate and regenerate only generated rows from current scoped facts. Selecting strict after an existing rubric displays the destructive resulting candidate and its diff; it still requires exact approval before writing.
- A generic provider fallback may draft a candidate only from the same project facts; it never bypasses display, exact approval, preimage capture, write, or readback and does not imply an implemented compiler.
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:skill -->

<!-- shape:details -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Details

### Detection And Resolution

Build a capability record containing the detected command for each satisfiable method in this closed vocabulary: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command. Do not emit an unavailable method, invent a command, or substitute a different method.

Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.

### Two-level Candidate Delivery, Catalog, And Matching

Presentation and persistence are separate. Deliver a two-level view of one candidate. Reader view FIRST in the user's conversation language (use neutral/professional Spanish for Spanish unless the user explicitly overrides it): concise Markdown overview with a compact `work-type | MODE | key obligation` table, material differences, actionable gaps/risks, the named canonical destination, and the exact full-candidate identity/checksum. Do not dump YAML or a wide command/tool-proof ledger by default. Brevity must not hide meaningful exceptions, blocking evidence gaps, destructive differences, or approval scope.

Complete technical artifacts are English unless an explicit user/project artifact-language convention says otherwise: full policy Markdown with every row, exact commands, bindings, independent tool proofs, precedence, exceptions, defaults, mixed-resolution rationale, and test-only rationale, plus full serialized YAML when applicable. Technical identifiers and executable commands are never translated. Complete technical artifacts must be clearly accessible through verified artifact paths/references or on request before approval. Both levels faithfully represent the SAME candidate. The overview is not a second policy or a canonical source. If technical detail is unavailable, the identity is stale, or the reader view is misleading, block.

The full-candidate identity/checksum and named destinations bind approval: explicit approval covers the complete candidate identified by that checksum, not merely the reader overview. A checksum identifies the approved bytes and destinations; it does not prove semantic equivalence. The producer-owned source is authoritative; a parent may relay/render but not author policy. OpenSpec persists YAML only; Engram persists canonical topic full Markdown only; hybrid persists equivalent content in both only when selected; and none has no active persistence. No implicit Engram write follows from the Markdown reader view. `none` returns the full content without activation and keeps complete detail inspectable on request or an appropriate surface rather than silently discarding it. No new artifact store or Engram capability is required for user preview. Readback and final delivery present the concise localized reader view plus full canonical references, not a wall of YAML.

Generate a visible general work-type catalog, never a fallback policy engine. It always includes `new-observable-behavior`, `bugfix`, `data-schema-migration`, `mechanical-behavior-preserving-change`, `refactor`, `docs-only`, `ci`, `configuration`, `executable-scripts`, `dependencies`, and `tests-only-maintenance`, with an explicit applicability/disposition even when no current path matches. Current project facts supply scopes, real evidence bindings, risks, and justified modes; defaults are proposals requiring approval, not immutable universal mandates. Recommended starts are strict-tdd with real test-first evidence for new observable behavior and bugfix; test-first when feasible plus integrity/compatibility obligations and explicit unavailable handling for data/schema migrations; standard equivalence/regression evidence for mechanical changes and refactors; skip with accuracy review and declared validators only for docs-only; and standard declared checks with risk elevation for CI, configuration, and dependencies. Classify executable scripts by declared behavior/bugfix versus mechanical intent, never by extension alone or blanket skip/strict. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Security, state, or permissions sensitivity is an explicit exception/elevation, never an accidental global strict rule. Missing essential evidence is visible and requires clarification or a decision; a catalog never permits a provider fallback to fabricate bindings.

Retain the existing signature/rule representation and use explicit intent-qualified rows, not a new schema/parser or runtime adapter. Declared work intent selects MODE; project scope selects only applicable command bindings. Do not create an unconditional path-only strict row that makes a mechanical or refactor intent strict under all-rows. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence. strict-tdd requires RED, GREEN, TRIANGULATE, and REFACTOR evidence; that obligation is distinct from a final green CI run. Hosted CI proof distinguishes an explicit install from a cited image guarantee; neither requires arbitrary version pinning.

Generate a rubric candidate only when multiple distinct satisfiable evidence methods or scope-dependent gates make `strict_tdd` lossy. Before a valid answer, return the candidate but persist no selected policy or active rubric. `strict|rubric` selects only the representation; after the selected candidate is displayed and exactly approved, strict persists `strict_tdd: true` with no consumer-visible active rubric and rubric persists `strict_tdd: false` with the active authoritative rubric. A discarded candidate may be diagnostic only, never consumer-visible as an active rubric.

Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs) derived from the project; test paths may supplement but cannot be the only production classification. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union their `discipline` and `evidence_methods`.

### Blocking Selection Envelope

When a candidate rubric is needed, return this complete blocking envelope and stop:

```yaml
headline: "Choose project TDD policy"
reason: "Detected capabilities make binary strict_tdd lossy; choose the policy representation before SDD can continue."
selection_mode: single
options:
  strict:
    description: "Use the existing binary strict_tdd policy and its default evidence requirements."
  rubric:
    description: "Use the generated project-specific rubric with strictest-wins matching and satisfiable evidence methods."
allowed_answers: strict|rubric
instruction: "STOP: do not continue to downstream phases. Do not choose on the user's behalf."
```

The orchestrator may relay this envelope unchanged, but remains read-only. Do not start downstream phases, persist a selected policy, or present a reduced prompt until the user answers exactly `strict` or `rubric`.

### Prompt Procedure And Publication

Prompt procedure, not an external compiler: first read the session-selected canonical source and capture its preimage. OpenSpec reads only `openspec/config.yaml` `testing.rubric.active`; Engram reads only the declared `sdd-init/{project}` topic/header. An unreadable, malformed, duplicate, or conflicting active source blocks; the parent may relay that read-only finding but cannot repair, select, or write policy.

1. Detect the closed evidence vocabulary from project facts and discard unsatisfied bindings. Build the complete project-derived rubric candidate from those facts, including scoped bindings, detected-but-unsatisfied entries, generated/manual provenance, and the current manual rows exactly as read.
2. Present the reader view first and make the complete project-derived rubric candidate, its capability ledger, and its checksum accessible through verified artifact paths/references or on request before asking `strict|rubric`. Include the current source/preimage summary and the proposed diff in the full technical artifacts. A `strict|rubric` answer selects only the representation; it neither approves nor activates any candidate.
3. After selection, render the reader view first and make the complete selected-policy candidate and checksum accessible through verified artifact paths/references or on request. Require the maintainer to explicitly approve the complete candidate identified by that checksum, not merely the reader overview, before any write. The strict candidate visibly removes any active rubric; the rubric candidate contains exactly one proposed active rubric. A response that only says `strict` or `rubric` is never approval.
4. Any candidate change or source drift invalidates approval; regenerate, redisplay, and obtain a new exact approval. Source drift includes changed project facts, commands, proofs, manual rows, selected backend, or canonical preimage. Do not infer a command, a mode, a default, or missing manual content while regenerating.
5. Use only ordinary available read/write/bash capabilities to retain or compare candidate bytes and checksum; that comparison is not CAS, a transaction, an opaque authority, or a compiler. Preserve the target preimage and its checksum before writing. Write once only after exact approval, immediately independently read back the same canonical source, and compare the persisted selected-policy content to the approved candidate.
6. For OpenSpec, readback must find only `testing.rubric.active` for rubric mode and the approved active/authoritative content; strict mode must read `strict_tdd: true` with no rubric. For Engram, independently re-read exactly `sdd-init/{project}` and verify the approved section/header and content. Do not report active until the selected backend's readback matches the approved candidate.
7. Hybrid requires the same displayed candidate for both configured stores and an independent successful readback of each. It has no cross-backend atomicity: if either side fails, report which side wrote, both preserved preimages, and the observed contents, then block. Do not choose one store as a fallback or call a partial result active.
8. On a write or readback failure, block and report the preimage, attempted target, and observed content; do not automatically rollback, compensate, or claim atomic/cross-backend transaction guarantees. If a selected backend lacks the required read, write, or independent readback operation, block; do not switch stores or declare a cross-backend result. `none` returns the full candidate without activation, keeps complete detail inspectable on request or an appropriate surface, and never claims an active consumer policy.

A generic provider fallback may draft a candidate only from the same project facts; it never bypasses display, exact approval, preimage capture, write, or readback and does not imply an implemented compiler. If its facts or candidate are incomplete, it asks a blocking question or abstains; it never supplies a fixed baseline, fabricated command, or active policy.

### Persistence And Re-init

- `engram`: persist the selected policy and capability ledger as canonical topic full Markdown only in `sdd-init/{project}`. In rubric mode, include this authoritative consumer contract:

```markdown
## TDD RUBRIC (per-work-type — AUTHORITATIVE)

Status: active/authoritative.

Match mechanically: `default` is selected ONLY when no non-default signature matches. Otherwise all matching non-default rows apply, strictest-wins, and evidence/discipline requirements union.

| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |
| --- | --- | --- | --- |
| `default` | project-derived fallback | only obligations applicable to every unmatched diff | generated |
```

- `openspec`: mirror selected policy, scoped capability facts, and generated/manual provenance under `openspec/config.yaml` `testing:`. In rubric mode, `strict_tdd: false` and exactly one `rubric.active: true` carry the same rows/resolution; strict mode has `strict_tdd: true` and no active `rubric`.
- `hybrid`: write semantically equivalent data to both backends only when selected.
- `none`: return the full content without activation; keep complete policy, rubric, and capability facts inspectable on request or an appropriate surface rather than silently discarding them.

OpenSpec writes this canonical active schema exactly; testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. The consumer stays path-agnostic and consumes active/authoritative data only.

Use the prompt procedure above before every activation attempt. The exact displayed candidate is the only approval subject: its closed methods, scoped bindings, rows, provenance, and manual content must be complete enough for the selected source, or the procedure blocks before writing. A checksum supports comparison of visible bytes only; it does not add a compiler, authority envelope, transaction, or publication guarantee.

On re-init, copy manual rows unchanged from the current canonical source into the displayed candidate and regenerate only generated rows from current facts. Selecting strict after an active rubric shows the destructive candidate and diff before the separate exact approval; unchanged inputs return the existing policy only after readback confirms that content.

```yaml
strict_tdd: false
testing:
  policy: rubric
  rubric:
    active: true
    authoritative: true
    mode_order: [skip, standard, strict-tdd]
    resolution:
      matching: all-rows
      mode: strictest-wins
      evidence: union
    bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof
    rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual
    default: {...}   # selective, exact enum, source
  detected_but_unsatisfied: [...]
```

Strict selection writes this exact shape, with no `rubric` key:

```yaml
strict_tdd: true
testing:
  policy: strict
  # rubric: absent (not active:false, not candidate, no rows)
```

On re-init, compare current facts against generated rows. Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric persists `strict_tdd: false` plus exactly one active rubric. With unchanged inputs, return the persisted policy unchanged.
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:details -->

<!-- shape:pi -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Producer

You are the single writer of project TDD policy; the parent/orchestrator is read-only and may only relay this blocking envelope. Detect runnable testing capabilities and use only this closed evidence-method vocabulary: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command.

Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.

Presentation and persistence are separate. Deliver a two-level view of one candidate. Reader view FIRST in the user's conversation language (use neutral/professional Spanish for Spanish unless the user explicitly overrides it): concise Markdown overview with a compact `work-type | MODE | key obligation` table, material differences, actionable gaps/risks, the named canonical destination, and the exact full-candidate identity/checksum. Do not dump YAML or a wide command/tool-proof ledger by default. Brevity must not hide meaningful exceptions, blocking evidence gaps, destructive differences, or approval scope.

Complete technical artifacts are English unless an explicit user/project artifact-language convention says otherwise: full policy Markdown with every row, exact commands, bindings, independent tool proofs, precedence, exceptions, defaults, mixed-resolution rationale, and test-only rationale, plus full serialized YAML when applicable. Technical identifiers and executable commands are never translated. Complete technical artifacts must be clearly accessible through verified artifact paths/references or on request before approval. Both levels faithfully represent the SAME candidate. The overview is not a second policy or a canonical source. If technical detail is unavailable, the identity is stale, or the reader view is misleading, block.

The full-candidate identity/checksum and named destinations bind approval: explicit approval covers the complete candidate identified by that checksum, not merely the reader overview. A checksum identifies the approved bytes and destinations; it does not prove semantic equivalence. The producer-owned source is authoritative; a parent may relay/render but not author policy. OpenSpec persists YAML only; Engram persists canonical topic full Markdown only; hybrid persists equivalent content in both only when selected; and none has no active persistence. No implicit Engram write follows from the Markdown reader view. `none` returns the full content without activation and keeps complete detail inspectable on request or an appropriate surface rather than silently discarding it. No new artifact store or Engram capability is required for user preview. Readback and final delivery present the concise localized reader view plus full canonical references, not a wall of YAML.

Generate a visible general work-type catalog, never a fallback policy engine. It always includes `new-observable-behavior`, `bugfix`, `data-schema-migration`, `mechanical-behavior-preserving-change`, `refactor`, `docs-only`, `ci`, `configuration`, `executable-scripts`, `dependencies`, and `tests-only-maintenance`, with an explicit applicability/disposition even when no current path matches. Current project facts supply scopes, real evidence bindings, risks, and justified modes; defaults are proposals requiring approval, not immutable universal mandates. Recommended starts are strict-tdd with real test-first evidence for new observable behavior and bugfix; test-first when feasible plus integrity/compatibility obligations and explicit unavailable handling for data/schema migrations; standard equivalence/regression evidence for mechanical changes and refactors; skip with accuracy review and declared validators only for docs-only; and standard declared checks with risk elevation for CI, configuration, and dependencies. Classify executable scripts by declared behavior/bugfix versus mechanical intent, never by extension alone or blanket skip/strict. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Security, state, or permissions sensitivity is an explicit exception/elevation, never an accidental global strict rule. Missing essential evidence is visible and requires clarification or a decision; a catalog never permits a provider fallback to fabricate bindings.

Retain the existing signature/rule representation and use explicit intent-qualified rows, not a new schema/parser or runtime adapter. Declared work intent selects MODE; project scope selects only applicable command bindings. Do not create an unconditional path-only strict row that makes a mechanical or refactor intent strict under all-rows. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence. strict-tdd requires RED, GREEN, TRIANGULATE, and REFACTOR evidence; that obligation is distinct from a final green CI run. Hosted CI proof distinguishes an explicit install from a cited image guarantee; neither requires arbitrary version pinning.

Keep the existing `strict_tdd` result if one binary policy is provably sufficient. If multiple distinct satisfiable methods or scope-dependent gates make that binary lossy, derive open project-specific signatures, generate a rubric candidate, and return exactly this blocking envelope:

```yaml
headline: "Choose project TDD policy"
reason: "Detected capabilities make binary strict_tdd lossy; choose the policy representation before SDD can continue."
selection_mode: single
options:
  strict:
    description: "Use the existing binary strict_tdd policy and its default evidence requirements."
  rubric:
    description: "Use the generated project-specific rubric with strictest-wins matching and satisfiable evidence methods."
allowed_answers: strict|rubric
instruction: "STOP: do not continue to downstream phases. Do not choose on the user's behalf."
```

STOP: do not continue to downstream phases. Before a valid answer, return the candidate but persist no selected policy or active rubric. `strict|rubric` selects only the representation; after the selected candidate is displayed and exactly approved, strict persists `strict_tdd: true` with no consumer-visible active rubric and rubric persists `strict_tdd: false` with the active authoritative rubric.

Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs); test paths only supplement. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union evidence/discipline requirements. Persist exactly one rubric-mode Engram section `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` with `Status: active/authoritative.` and table `| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |`; Source is `generated` or `manual`. OpenSpec `testing:` mirrors active/provenance semantics. Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric persists `strict_tdd: false` plus exactly one active rubric; hybrid writes both only when selected, and `none` returns full content without activation while keeping complete detail inspectable.

OpenSpec writes this canonical active schema exactly; testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. The consumer stays path-agnostic and consumes active/authoritative data only.

Prompt procedure, not an external compiler: read the session-selected canonical source and preserve its preimage before building a candidate. Present the reader view first and make the complete project-derived rubric candidate, its capability ledger, and its checksum accessible through verified artifact paths/references or on request before asking `strict|rubric`. A `strict|rubric` answer selects only the representation; it neither approves nor activates any candidate.

After selection, render the reader view first and make the complete selected-policy candidate and checksum accessible through verified artifact paths/references or on request. Require the maintainer to explicitly approve the complete candidate identified by that checksum, not merely the reader overview, before any write. Any candidate change or source drift invalidates approval; regenerate, redisplay, and obtain a new exact approval. Preserve manual rows unchanged in the candidate and regenerate only generated rows; strict after a rubric must display the destructive diff.

Use only ordinary available read/write/bash capabilities to retain or compare candidate bytes and checksum; that comparison is not CAS, a transaction, an opaque authority, or a compiler. Preserve the target preimage and its checksum before writing. Write once only after exact approval, immediately independently read back the same canonical source, and compare the persisted selected-policy content to the approved candidate.

For OpenSpec, use only `openspec/config.yaml` `testing.rubric.active` and verify its approved active/authoritative content on readback. For Engram, use only the declared `sdd-init/{project}` topic/header and independently re-read it. Hybrid needs independent matching readback from both configured stores and has no cross-backend atomicity. On a write or readback failure, block and report the preimage, attempted target, and observed content; do not automatically rollback, compensate, or claim atomic/cross-backend transaction guarantees. If a selected backend lacks the required read, write, or independent readback operation, block; do not switch stores or declare a cross-backend result. `none` returns the full candidate without activation, keeps complete detail inspectable on request or an appropriate surface, and never claims an active consumer policy.

A generic provider fallback may draft a candidate only from the same project facts; it never bypasses display, exact approval, preimage capture, write, or readback and does not imply an implemented compiler. It may ask or abstain when facts are incomplete, but never invents commands, fixed baseline rows, or active state.

```yaml
strict_tdd: false
testing:
  policy: rubric
  rubric:
    active: true
    authoritative: true
    mode_order: [skip, standard, strict-tdd]
    resolution:
      matching: all-rows
      mode: strictest-wins
      evidence: union
    bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof
    rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual
    default: {...}   # selective, exact enum, source
  detected_but_unsatisfied: [...]
```

```yaml
strict_tdd: true
testing:
  policy: strict
  # rubric: absent (not active:false, not candidate, no rows)
```
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:pi -->
