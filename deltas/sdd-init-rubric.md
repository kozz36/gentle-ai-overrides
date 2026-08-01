<!-- shape:skill -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Producer

- `sdd-init` is the single writer of project TDD policy. The orchestrator is read-only: it may relay a blocking envelope but must not select, generate, modify, or persist policy/rubric rows.
- Detect testing capabilities and the CLOSED set of satisfiable evidence methods: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, and `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command.
- Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.
- Preserve the existing `strict_tdd` resolution when one binary policy is provably sufficient; otherwise generate a project-derived rubric candidate and block for `strict|rubric`. Before a valid answer, return the candidate but persist no selected policy or active rubric. Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric. Answer `rubric`: persist `strict_tdd: false` plus the active authoritative rubric. Do not choose or continue downstream while blocked.
- Rubric signatures are open and project-derived. Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs); test paths may supplement but cannot be the only production classification. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union evidence/discipline requirements.
- In rubric mode, serialize exactly one active rubric in `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` with `Status: active/authoritative.`, mechanical matching, and `| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |`; Source is `generated` or `manual`. Mirror active/provenance semantics under OpenSpec `testing:`.
- Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric persists `strict_tdd: false` plus exactly one active rubric. Hybrid writes both; none returns inline.
- OpenSpec: testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. Strict uses `rubric: absent (not active:false, not candidate, no rows)`. The canonical rubric fields are `mode_order: [skip, standard, strict-tdd]`, `matching: all-rows`, `bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof`, and `rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual`.
- The canonical compiler is the only producer that may activate a rubric. It extracts project-declared testing evidence into normalized `EvidenceV1` records (`id`, `scope`, `method`, `command`, `command_declaration`, `tool_proof`), derives `CandidateV1` rows and `QuestionV1` blocking questions, and fails closed on missing, duplicate, ambiguous, or unbound fields. Candidate rows remain pending and OpenSpec remains unchanged until a maintainer supplies `ConfirmationV1` for the exact candidate digest and answers every blocking question.
- On confirmed `rubric`, serialize one deterministic `CanonicalPolicyModelV1`: length-frame and sort evidence, bindings, rows, questions, and confirmations by stable id; bind its `cksum` digest into both the OpenSpec transaction and `ResolutionV1`. Do not activate directly from conversational prose or an unnormalized candidate.
- OpenSpec activation is one transaction: validate exactly one `testing:` mapping and zero or one complete managed marker pair; render a same-directory temporary replacement; validate it; atomically rename it; then independently re-open and parse the installed file. Publish `ResolutionV1` only after readback confirms `state=active`, `authority=openspec`, one matching transaction id, and matching canonical-model and backend-config digests.
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:skill -->

<!-- shape:details -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Details

### Detection And Resolution

Build a capability record containing the detected command for each satisfiable method in this closed vocabulary: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command. Do not emit an unavailable method, invent a command, or substitute a different method.

Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.

Generate a rubric candidate only when multiple distinct satisfiable evidence methods or scope-dependent gates make `strict_tdd` lossy. Before a valid answer, return the candidate but persist no selected policy or active rubric. Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric. Answer `rubric`: persist `strict_tdd: false` plus the active authoritative rubric. A discarded candidate may be diagnostic only, never consumer-visible as an active rubric.

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

### Canonical Compiler And OpenSpec Activation

The compiler accepts only normalized records with this closed schema:

```text
EvidenceV1: id, scope, method, command, command_declaration, tool_proof
CandidateV1: evidence[], bindings[], rows[], questions[]
QuestionV1: id, row_ref, prompt, allowed_answers, blocking=true
ConfirmationV1: candidate_digest, maintainer, answers[]
```

Each id and required field occurs exactly once. `method` uses the closed evidence vocabulary, every row binding resolves to evidence in the same scope, and each blocking question has one unambiguous answer. Reject malformed, duplicate, unresolved, or ambiguous records before writing any backend. Candidate rows are diagnostic and pending; only a maintainer confirmation bound to the exact `CandidateV1` digest may activate them. The answer selecting the policy remains exactly `strict|rubric`; `rubric` is not activation without that confirmation.

For a confirmed rubric, construct exactly one `CanonicalPolicyModelV1` by length-framing all scalar fields and sorting evidence, bindings, rows, questions, and confirmations by stable id. Persist its `cksum` digest; a change to any policy-relevant normalized record changes the model digest. No prose, filesystem enumeration order, or backend-local representation may contribute to the model.

OpenSpec activation is an atomic, fail-closed transaction. Preflight one `testing:` mapping and either zero managed markers or one complete `# gentle-ai:managed-testing:start` / `# gentle-ai:managed-testing:end` pair; reject duplicate mappings, partial markers, YAML directives, anchors, aliases, merge keys, tags, tabs, or block scalars. Render the full managed testing block and `ResolutionV1` metadata into a temporary file in the target directory, validate the temporary shape, and rename it only after validation. Re-open the renamed file independently and verify exactly one active OpenSpec authority, transaction id, canonical model digest, and backend config digest before emitting:

```text
schema=ResolutionV1
state=active
authority=openspec
readback=verified
```

If any preflight, write, rename, or readback step fails, report no active resolution and leave the original OpenSpec file unchanged.

### Persistence And Re-init

- `engram`: persist selected policy in `sdd-init/{project}` and testing capabilities in `sdd/{project}/testing-capabilities`. In rubric mode, include this authoritative consumer contract:

```markdown
## TDD RUBRIC (per-work-type — AUTHORITATIVE)

Status: active/authoritative.

Match mechanically: `default` is selected ONLY when no non-default signature matches. Otherwise all matching non-default rows apply, strictest-wins, and evidence/discipline requirements union.

| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |
| --- | --- | --- | --- |
| `default` | project-derived fallback | only obligations applicable to every unmatched diff | generated |
```

- `openspec`: mirror selected policy, scoped capability facts, and generated/manual provenance under `openspec/config.yaml` `testing:`. In rubric mode, `strict_tdd: false` and exactly one `rubric.active: true` carry the same rows/resolution; strict mode has `strict_tdd: true` and no active `rubric`.
- `hybrid`: write semantically equivalent data to both backends.
- `none`: return the complete policy, rubric, and capability facts inline without persistence.

OpenSpec writes this canonical active schema exactly; testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. The consumer stays path-agnostic and consumes active/authoritative data only.

Use the canonical compiler before activation. Normalize project testing evidence as `EvidenceV1` records with exactly `id`, `scope`, `method`, `command`, `command_declaration`, and `tool_proof`; derive `CandidateV1` rows and `QuestionV1` blocking questions. Reject missing, duplicate, ambiguous, unresolved, or cross-scope records. Candidates remain pending and OpenSpec remains unchanged until a maintainer supplies `ConfirmationV1` for the exact candidate digest and answers every blocking question; `rubric` alone is not activation.

The confirmed compiler output is exactly one deterministic `CanonicalPolicyModelV1`: length-frame and stable-id sort evidence, bindings, rows, questions, and confirmations, then bind its `cksum` digest to the activation transaction. OpenSpec activation validates one `testing:` mapping and zero or one complete managed marker pair, writes and validates a same-directory temporary replacement, atomically renames it, and independently re-reads the installed file. Emit `ResolutionV1` only when readback proves `state=active`, `authority=openspec`, and matching transaction, canonical-model, and backend-config digests.

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

STOP: do not continue to downstream phases. Before a valid answer, return the candidate but persist no selected policy or active rubric. Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric. Answer `rubric`: persist `strict_tdd: false` plus the active authoritative rubric.

Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs); test paths only supplement. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union evidence/discipline requirements. Persist exactly one rubric-mode Engram section `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` with `Status: active/authoritative.` and table `| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |`; Source is `generated` or `manual`. OpenSpec `testing:` mirrors active/provenance semantics. Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric persists `strict_tdd: false` plus exactly one active rubric; hybrid writes both and none returns inline.

OpenSpec writes this canonical active schema exactly; testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. The consumer stays path-agnostic and consumes active/authoritative data only.

Use the canonical compiler before activation. Normalize evidence as `EvidenceV1`; derive `CandidateV1` rows and `QuestionV1` blocking questions; and reject missing, duplicate, ambiguous, unresolved, or cross-scope records. Candidates remain pending and OpenSpec remains unchanged until a maintainer supplies `ConfirmationV1` for the exact candidate digest and answers every blocking question. Serialize one stable-id, length-framed `CanonicalPolicyModelV1`, bind its `cksum` digest to the transaction, then perform OpenSpec activation through a same-directory temporary replacement, atomic rename, and independent readback. Emit `ResolutionV1` only when readback proves the active OpenSpec authority and matching transaction, canonical-model, and backend-config digests.

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
