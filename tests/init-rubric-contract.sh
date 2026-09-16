#!/usr/bin/env bash
# Static contract checks for the sdd-init rubric delta. This intentionally does
# not source apply.sh; transform and host coverage live in tests/run.sh.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-overrides-contract.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }

assert_project_declared_satisfiability() {
  local file="$1" label="$2"
  grep -Fq 'project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool' "$file" || fail "$label lacks project-declared satisfiability" || return 1
  grep -Fq 'MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell' "$file" || fail "$label permits host-shell-only detection" || return 1
  grep -Fq 'A config section naming a framework without a declared dependency/environment/command is insufficient' "$file" || fail "$label accepts framework-only configuration" || return 1
  grep -Fq 'Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof' "$file" || fail "$label lacks scoped capability bindings" || return 1
  grep -Fq 'A method satisfiable in one scope is not satisfiable globally' "$file" || fail "$label permits cross-scope satisfiability" || return 1
  grep -Fq 'A generated row may require a method only when its bound command applies to that row' "$file" || fail "$label permits unbound row requirements" || return 1
  grep -Fq 'When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one' "$file" || fail "$label lacks scoped command persistence" || return 1
  grep -Fq 'If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope' "$file" || fail "$label permits cross-scope command borrowing" || return 1
  grep -Fq 'Every candidate capability binding records separate command_declaration and tool_proof fields' "$file" || fail "$label lacks separate command/proof fields" || return 1
  grep -Fq 'command_declaration identifies where the exact command is declared' "$file" || fail "$label lacks command declaration provenance" || return 1
  grep -Fq 'tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable' "$file" || fail "$label lacks independent tool proof" || return 1
  grep -Fq 'The command/script text itself can NEVER satisfy tool_proof' "$file" || fail "$label permits self-proving commands" || return 1
  grep -Fq 'An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted' "$file" || fail "$label lacks eslint unsatisfied example" || return 1
  grep -Fq 'Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied' "$file" || fail "$label lacks binding audit gate" || return 1
}

assert_policy_contract() {
  local file="$1" label="$2"
  grep -Fq 'Before a valid answer, return the candidate but persist no selected policy or active rubric' "$file" || fail "$label persists policy before selection" || return 1
  grep -Fq 'strict persists `strict_tdd: true` with no consumer-visible active rubric' "$file" || fail "$label allows active rubric in strict mode" || return 1
  grep -Fq 'rubric persists `strict_tdd: false` with the active authoritative rubric' "$file" || fail "$label lacks rubric-mode activation" || return 1
  grep -Fq 'Never populate `default` by unioning all detected methods' "$file" || fail "$label permits non-selective default rows" || return 1
  grep -Fq '## TDD RUBRIC (per-work-type — AUTHORITATIVE)' "$file" || fail "$label lacks authoritative rubric heading" || return 1
  grep -Fq '| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence |' "$file" || fail "$label lacks consumer-compatible rubric table" || return 1
  grep -Fq 'Signatures classify production implementation/work-type diffs' "$file" || fail "$label permits test-only production classification" || return 1
  grep -Fq '`default` is selected ONLY when no non-default signature matches' "$file" || fail "$label lets default join specific matches" || return 1
  grep -Fq 'When any non-default row matches, default does not join the union' "$file" || fail "$label unions default with specific rows" || return 1
  grep -Fq 'MODE enum: `skip < standard < strict-tdd`' "$file" || fail "$label lacks closed MODE order" || return 1
  grep -Fq '`strict-tdd` means a full test-first cycle' "$file" || fail "$label lacks strict-tdd meaning" || return 1
  grep -Fq '`standard` requires evidence without mandatory test-first ordering' "$file" || fail "$label lacks standard meaning" || return 1
  grep -Fq '`skip` has no automated test gate unless another matching row unions evidence' "$file" || fail "$label lacks skip meaning" || return 1
  grep -Fq 'Status: active/authoritative.' "$file" || fail "$label lacks active rubric status" || return 1
  grep -Fq '| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |' "$file" || fail "$label lacks provenance column" || return 1
  grep -Fq 'Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically' "$file" || fail "$label lacks deterministic provenance maintenance" || return 1
  grep -Fq 'Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric' "$file" || fail "$label permits duplicate policy artifacts" || return 1
  grep -Fq 'Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation' "$file" || fail "$label lacks strict destructive confirmation" || return 1
  grep -Fq 'Selecting rubric persists `strict_tdd: false` plus exactly one active rubric' "$file" || fail "$label lacks single active rubric rule" || return 1
  grep -Fq 'testing.rubric.active is the only active OpenSpec path' "$file" || fail "$label lacks canonical active path" || return 1
  grep -Fq 'Reject alternate active keys such as `rubric_status`' "$file" || fail "$label permits alternate active keys" || return 1
  grep -Fq 'Re-init reads only `testing.rubric.active`' "$file" || fail "$label reads noncanonical rubric paths" || return 1
  grep -Fq 'rubric: absent (not active:false, not candidate, no rows)' "$file" || fail "$label lacks strict rubric absence semantics" || return 1
  grep -Fq 'mode_order: [skip, standard, strict-tdd]' "$file" || fail "$label lacks canonical mode order serialization" || return 1
  grep -Fq 'matching: all-rows' "$file" || fail "$label lacks canonical matching serialization" || return 1
  grep -Fq 'bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof' "$file" || fail "$label lacks canonical binding schema" || return 1
  grep -Fq 'rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual' "$file" || fail "$label lacks canonical row schema" || return 1
}

validate_delta_shape() {
  awk '
    BEGIN { expected["skill"] = expected["details"] = expected["pi"] = 1 }
    /^<!-- shape:[a-z][a-z0-9-]* -->$/ {
      name = $0; sub(/^<!-- shape:/, "", name); sub(/ -->$/, "", name)
      if (!(name in expected) || opened[name] || inside) bad = 1
      else { opened[name] = 1; inside = name }
      next
    }
    /^<!-- \/shape:[a-z][a-z0-9-]* -->$/ {
      name = $0; sub(/^<!-- \/shape:/, "", name); sub(/ -->$/, "", name)
      if (!(name in expected) || !inside || name != inside || closed[name]) bad = 1
      else { closed[name] = 1; inside = "" }
      next
    }
    /<!--[ ]*\/?shape:/ { bad = 1; next }
    { if (inside) body[inside] = body[inside] (body[inside] == "" ? "" : "\n") $0 }
    END {
      for (name in expected) if (opened[name] != 1 || closed[name] != 1 || body[name] == "") bad = 1
      exit bad
    }
  ' "$1"
}

extract_init_shape() {
  local shape="$1" out="$2"
  awk -v shape="$shape" '
    $0 == "<!-- shape:" shape " -->" { inside = 1; next }
    $0 == "<!-- /shape:" shape " -->" { inside = 0; exit }
    inside { print }
  ' "$ROOT/deltas/sdd-init-rubric.md" > "$out"
  [ -s "$out" ] || fail "missing $shape fallback contract"
}

test_policy_contract() (
  local init="$ROOT/deltas/sdd-init-rubric.md" consumer="$ROOT/deltas/rubric-tdd.md"
  assert_project_declared_satisfiability "$init" 'sdd-init delta' || exit 1
  assert_policy_contract "$init" 'sdd-init delta' || exit 1
  grep -Fq 'canonical `sdd-init` authoritative policy directly for the active artifact store' "$consumer" || fail 'consumer does not read canonical policy directly' || exit 1
  grep -Fq 'resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules' "$consumer" || fail 'consumer can reuse a first-slice resolution session-wide' || exit 1
  grep -Fq 'caches the canonical policy ONCE per session' "$consumer" || fail 'consumer does not cache only canonical policy' || exit 1
  grep -Fq '`default` ONLY when no non-default row matches' "$consumer" || fail 'consumer does not reserve default for unmatched slices' || exit 1
  grep -Fq 'union only applicable non-default rows' "$consumer" || fail 'consumer unions inapplicable or default rows' || exit 1
  grep -Fq "Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths" "$consumer" || fail 'consumer does not forward effective mode and exact declared policy' || exit 1
  grep -Fq 'Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy' "$consumer" || fail 'consumer diagnostics can supersede canonical policy' || exit 1
  grep -Fq 'Binary `strict_tdd` fallback is permitted ONLY when no rubric exists' "$consumer" || fail 'consumer lacks the no-rubric fallback boundary' || exit 1
  ! grep -Fq 'Resolve it ONCE per session' "$consumer" || fail 'consumer resolves a first slice only once per session' || exit 1
  ! grep -Fq 'then caches that resolution' "$consumer" || fail 'consumer caches a slice resolution' || exit 1
  ! grep -Fq 'recovery_action=run ' "$consumer" || fail 'consumer fabricates runtime recovery dispatch' || exit 1
  ! grep -Fq 'RubricConsumerEnvelopeV1' "$consumer" || fail 'consumer retains the experimental envelope' || exit 1
  ! grep -Fq 'RubricConsumerBlockedV1' "$consumer" || fail 'consumer retains the experimental blocked envelope' || exit 1
)

validate_rubric_tdd_shape() {
  awk '
    BEGIN { expected["list-item"] = expected["prose"] = expected["cache-sentence"] = expected["pi-workflow"] = expected["pi-odd-forwarding"] = 1 }
    /^<!-- shape:[a-z][a-z0-9-]* -->$/ {
      name = $0; sub(/^<!-- shape:/, "", name); sub(/ -->$/, "", name)
      if (!(name in expected) || opened[name] || inside) bad = 1
      else { opened[name] = 1; inside = name }
      next
    }
    /^<!-- \/shape:[a-z][a-z0-9-]* -->$/ {
      name = $0; sub(/^<!-- \/shape:/, "", name); sub(/ -->$/, "", name)
      if (!(name in expected) || !inside || name != inside || closed[name]) bad = 1
      else { closed[name] = 1; inside = "" }
      next
    }
    /<!--[ ]*\/?shape:/ { bad = 1; next }
    { if (inside) body[inside] = body[inside] (body[inside] == "" ? "" : "\n") $0 }
    END {
      for (name in expected) if (opened[name] != 1 || closed[name] != 1 || body[name] == "") bad = 1
      exit bad
    }
  ' "$1"
}

extract_rubric_tdd_shape() {
  local shape="$1" out="$2"
  awk -v shape="$shape" '
    $0 == "<!-- shape:" shape " -->" { inside = 1; next }
    $0 == "<!-- /shape:" shape " -->" { inside = 0; exit }
    inside { print }
  ' "$ROOT/deltas/rubric-tdd.md" > "$out"
  [ -s "$out" ] || fail "missing rubric TDD $shape contract"
}

test_human_clarification_contract() (
  local list="$TMP_ROOT/clarification-list.md" prose="$TMP_ROOT/clarification-prose.md" pi="$TMP_ROOT/clarification-pi.md" file
  extract_rubric_tdd_shape list-item "$list" || exit 1
  extract_rubric_tdd_shape prose "$prose" || exit 1
  extract_rubric_tdd_shape pi-workflow "$pi" || exit 1

  for file in "$list" "$prose" "$pi"; do
    grep -Fq 'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' "$file" || fail "$(basename -- "$file") does not require human clarification" || exit 1
    grep -Fq 'do not fabricate runtime recovery dispatch.' "$file" || fail "$(basename -- "$file") permits fabricated recovery dispatch" || exit 1
    ! grep -Fq 'recovery_action=run ' "$file" || fail "$(basename -- "$file") retains runtime recovery dispatch" || exit 1
  done
)

test_opencode_final_sdd_init_contract() (
  local apply="$ROOT/apply.sh"
  for invariant in \
    "OpenCode supports exactly four hidden sdd-init shapes: the final 2.6.0" \
    "You are an SDD executor for the init phase, not the orchestrator. Do this phase's work yourself. Do NOT delegate, Do NOT call task, and Do NOT launch sub-agents. Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly." \
    "<!-- gentle-ai:codegraph-guidance -->" \
    "<!-- /gentle-ai:codegraph-guidance -->" \
    "<!-- gentle-ai:agent-language-contract -->" \
    "<!-- /gentle-ai:agent-language-contract -->" \
    'and $codegraph_opens == []' \
    'and $codegraph_closes == []' \
    'and $language_contract_opens == [2]' \
    'and ($codegraph_closes | length == 1)' \
    'and $language_contract_opens == [($codegraph_close_line + 2)]' \
    'and ($unknown_markers | length == 0)' \
    'elif $agent.prompt == $rc3_inline then "inline"' \
    'elif $agent.prompt == $external then "external"'; do
    grep -Fq "$invariant" "$apply" || fail "OpenCode final sdd-init contract lacks invariant: $invariant" || exit 1
  done
  ! grep -Fq 'gentle-ai:artifact-language' "$apply" || fail 'OpenCode final sdd-init contract allowlists the invented artifact-language marker' || exit 1
)

test_pi_workflow_consumer_contract() (
  local consumer="$ROOT/deltas/rubric-tdd.md" apply="$ROOT/apply.sh"
  validate_rubric_tdd_shape "$consumer" || fail 'rubric TDD delta has invalid shape markers' || exit 1
  for invariant in \
    '<!-- gentle-ai:pi-rubric-forwarding -->' \
    '<!-- /gentle-ai:pi-rubric-forwarding -->' \
    'canonical `sdd-init` authoritative policy directly for the active artifact store' \
    'active/authoritative' \
    'caches the canonical policy ONCE per session' \
    'resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules' \
    '`default` ONLY when no non-default row matches' \
    'union only applicable non-default rows' \
    "Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths" \
    'without substituting downstream matching rules or policy rewriting' \
    'Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy' \
    'Producer and activation semantics remain owned by `sdd-init`' \
    'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' \
    'Binary `strict_tdd` fallback is permitted ONLY when no rubric exists.' \
    'effective MODE is `strict-tdd`' \
    'Gentle AI 2.6.0 with `gentle-pi@2.4.0`' \
    'APPEND_SYSTEM.md remains installer-managed and untouched.' \
    'The orchestrator is read-only: never author, generate, mutate, broaden, infer, alter, or rewrite the authoritative policy' \
    'It may mechanically match existing policy rows using only those declared rules and must never invent commands or evidence.'; do
    grep -Fq "$invariant" "$consumer" || fail "Pi workflow consumer lacks invariant: $invariant" || exit 1
  done
  grep -Fqx 'pi|pi-rubric-workflow|@pi-gentle-pi-workflow@' "$apply" || fail 'Pi workflow host row is not resolver-backed' || exit 1
  grep -Fqx 'pi|sdd-init-pi|@pi-gentle-pi-sdd-init@' "$apply" || fail 'Pi sdd-init host row is not resolver-backed' || exit 1
  if grep -Fqx 'pi|pi-rubric-workflow|.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md' "$apply"; then
    fail 'Pi workflow host row retains the retired static npm-only path' || exit 1
  fi
  if grep -Fqx 'pi|sdd-init-pi|.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md' "$apply"; then
    fail 'Pi sdd-init host row retains the retired static npm-only path' || exit 1
  fi
  grep -Fq 'resolve_pi_gentle_package_root_rel()' "$apply" || fail 'Pi shared package-root resolver is missing' || exit 1
  grep -Fq "resolve_pi_gentle_asset_rel 'assets/sdd-orchestrator-workflow.md'" "$apply" || fail 'Pi workflow does not use the shared package resolver' || exit 1
  grep -Fq "resolve_pi_gentle_asset_rel 'assets/agents/sdd-init.md'" "$apply" || fail 'Pi sdd-init does not use the shared package resolver' || exit 1
  grep -Fq "PI_WORKFLOW_BINARY='For \`sdd-apply\` and \`sdd-verify\`, read \`openspec/config.yaml\` when present." "$apply" || fail 'Pi workflow binary anchor is missing' || exit 1
  grep -Fq 'pi_rubric_workflow_transform()' "$apply" || fail 'Pi workflow transform is missing' || exit 1
  grep -Fq 'opens != closes || opens > 1 || (opens == 1 && open_line >= close_line)' "$apply" || fail 'Pi workflow marker cardinality guard is missing' || exit 1
  grep -Fq 'headings != 1 || archives != 1 || binaries != 1' "$apply" || fail 'Pi workflow structural-anchor guard is missing' || exit 1
)

test_rubric_tdd_shape_grammar() (
  local file fixture
  for fixture in duplicate missing unknown malformed; do
    file="$TMP_ROOT/rubric-tdd-$fixture.md"
    case "$fixture" in
      duplicate)
        cp -- "$ROOT/deltas/rubric-tdd.md" "$file"
        printf '%s\n' '<!-- shape:pi-odd-forwarding -->' 'duplicate' '<!-- /shape:pi-odd-forwarding -->' >> "$file"
        ;;
      missing)
        awk '$0 != "<!-- shape:pi-odd-forwarding -->" && $0 != "<!-- /shape:pi-odd-forwarding -->"' \
          "$ROOT/deltas/rubric-tdd.md" > "$file"
        ;;
      unknown)
        cp -- "$ROOT/deltas/rubric-tdd.md" "$file"
        printf '%s\n' '<!-- shape:unexpected -->' 'unknown' '<!-- /shape:unexpected -->' >> "$file"
        ;;
      malformed)
        cp -- "$ROOT/deltas/rubric-tdd.md" "$file"
        printf '%s\n' '<!-- shape:pi-odd-forwarding -->' 'partial' >> "$file"
        ;;
    esac
    if validate_rubric_tdd_shape "$file"; then
      fail "rubric TDD $fixture fifth-shape defect was accepted" || exit 1
    fi
  done
)

test_pi_policy_defined_forwarding_contract() (
  local pi="$TMP_ROOT/pi-policy-defined.md" invariant
  extract_rubric_tdd_shape pi-workflow "$pi" || exit 1
  for invariant in \
    'session-selected artifact store; do not switch stores merely because `openspec/config.yaml` exists.' \
    'A valid rubric and its resolved slice instruction govern this forwarding.' \
    'The preserved binary Strict TDD clause above is fallback-only when there is genuinely no rubric.' \
    'Missing required canonical policy, or invalid, ambiguous, or conflicting policy, is not no rubric' \
    'Policy-defined matching, precedence, and exceptions govern each slice.' \
    'Do not replace declared exceptions or precedence with generic all-matches, strictest-wins, or union behavior.' \
    'If the canonical policy explicitly declares `all-rows` with `strictest-wins` and evidence union, use that declared resolution; otherwise use its declared resolution.' \
    'Only use `default` when no non-default match exists and that policy actually declares a default.' \
    'Forward only commands applicable to the current phase under declared bindings.' \
    'Do not reuse an apply command for verify, or a verify command for apply, unless the policy explicitly declares it shared.' \
    'A legacy flat command with no phase binding remains applicable as declared' \
    'Before launch, add plain prompt content to the existing parent phase prompt: the canonical source reference, slice, resolved MODE, phase-applicable exact commands, disciplines/evidence, and skill paths; then send it to the child.' \
    "A child agent's own configuration or gate can still conflict; do not claim this prompt guarantees child enforcement or change the child without separate scope." \
    'Preflight or native-status injection by a runtime extension does not resolve MODE; the parent orchestrator remains responsible for MODE resolution.' \
    'This is parent LLM instruction, not a new parser, runtime adapter, schema, trace protocol, or capture protocol.' \
    'Do not inline all artifact contents; executors read their artifacts normally.' \
    'This forwarding applies only to `sdd-apply` and `sdd-verify`, not to RDD reviewers.'; do
    grep -Fq "$invariant" "$pi" || fail "Pi workflow lacks policy-defined forwarding: $invariant" || exit 1
  done
  ! grep -Fq 'otherwise apply strictest MODE precedence and union only applicable non-default rows' "$pi" || fail 'Pi workflow retains an unconditional all-rows resolution' || exit 1
)

test_delta_shape_grammar() (
  local dir="$TMP_ROOT/source-shapes" fixture
  mkdir -p "$dir"
  validate_delta_shape "$ROOT/deltas/sdd-init-rubric.md" || fail 'canonical delta has invalid shape markers' || exit 1
  for fixture in duplicate missing unpaired nested reordered; do
    case "$fixture" in
      duplicate) printf '%s\n' '<!-- shape:skill -->' 'one' '<!-- /shape:skill -->' '<!-- shape:skill -->' 'two' '<!-- /shape:skill -->' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      missing) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      unpaired) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      nested) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      reordered) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- /shape:details -->' '<!-- shape:details -->' 'details' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
    esac
    if validate_delta_shape "$dir/$fixture.md"; then
      fail "$fixture malformed source shape was accepted" || exit 1
    fi
  done
)

test_prompt_procedure_contract() (
  local shape file
  for shape in skill details pi; do
    file="$TMP_ROOT/$shape-prompt-procedure.md"
    extract_init_shape "$shape" "$file" || exit 1
    grep -Fq 'Prompt procedure, not an external compiler:' "$file" || fail "$shape claims an external compiler" || exit 1
    grep -Fq 'Present the reader view first and make the complete project-derived rubric candidate, its capability ledger, and its checksum accessible through verified artifact paths/references or on request before asking `strict|rubric`.' "$file" || fail "$shape does not make the full candidate accessible before representation choice" || exit 1
    grep -Fq 'A `strict|rubric` answer selects only the representation; it neither approves nor activates any candidate.' "$file" || fail "$shape treats representation choice as approval" || exit 1
    grep -Fq 'After selection, render the reader view first and make the complete selected-policy candidate and checksum accessible through verified artifact paths/references or on request. Require the maintainer to explicitly approve the complete candidate identified by that checksum, not merely the reader overview, before any write.' "$file" || fail "$shape lacks complete-candidate approval" || exit 1
    grep -Fq 'Any candidate change or source drift invalidates approval; regenerate, redisplay, and obtain a new exact approval.' "$file" || fail "$shape permits stale approval" || exit 1
    grep -Fq 'Use only ordinary available read/write/bash capabilities to retain or compare candidate bytes and checksum; that comparison is not CAS, a transaction, an opaque authority, or a compiler.' "$file" || fail "$shape overclaims candidate identity" || exit 1
    grep -Fq 'Preserve the target preimage and its checksum before writing. Write once only after exact approval, immediately independently read back the same canonical source, and compare the persisted selected-policy content to the approved candidate.' "$file" || fail "$shape lacks preimage/write/readback procedure" || exit 1
    grep -Fq 'On a write or readback failure, block and report the preimage, attempted target, and observed content; do not automatically rollback, compensate, or claim atomic/cross-backend transaction guarantees.' "$file" || fail "$shape overclaims failure recovery" || exit 1
    grep -Fq 'If a selected backend lacks the required read, write, or independent readback operation, block; do not switch stores or declare a cross-backend result.' "$file" || fail "$shape switches or overclaims backend support" || exit 1
    grep -Fq 'A generic provider fallback may draft a candidate only from the same project facts; it never bypasses display, exact approval, preimage capture, write, or readback and does not imply an implemented compiler.' "$file" || fail "$shape lets generic fallback bypass the procedure" || exit 1
    ! grep -Fq 'CandidateV1' "$file" || fail "$shape retains an imaginary candidate compiler model" || exit 1
    ! grep -Fq 'CanonicalPolicyModelV1' "$file" || fail "$shape retains an imaginary canonical compiler model" || exit 1
    ! grep -Fq 'ResolutionV1' "$file" || fail "$shape retains an imaginary resolution envelope" || exit 1
  done
)

test_two_level_delivery_catalog_contract() (
  local shape file category text readme="$ROOT/README.md"
  for shape in skill details pi; do
    file="$TMP_ROOT/$shape-two-level-delivery.md"
    extract_init_shape "$shape" "$file" || exit 1
    for text in \
      'Deliver a two-level view of one candidate' \
      "Reader view FIRST in the user's conversation language" \
      'compact `work-type | MODE | key obligation` table' \
      'Do not dump YAML or a wide command/tool-proof ledger by default' \
      'Brevity must not hide meaningful exceptions, blocking evidence gaps, destructive differences, or approval scope' \
      'Complete technical artifacts are English unless an explicit user/project artifact-language convention says otherwise' \
      'full policy Markdown with every row, exact commands, bindings, independent tool proofs, precedence, exceptions, defaults, mixed-resolution rationale, and test-only rationale' \
      'Technical identifiers and executable commands are never translated' \
      'plus full serialized YAML when applicable' \
      'clearly accessible through verified artifact paths/references or on request before approval' \
      'The overview is not a second policy or a canonical source' \
      'If technical detail is unavailable, the identity is stale, or the reader view is misleading, block' \
      'The full-candidate identity/checksum and named destinations bind approval' \
      'explicit approval covers the complete candidate identified by that checksum, not merely the reader overview' \
      'A checksum identifies the approved bytes and destinations; it does not prove semantic equivalence' \
      'OpenSpec persists YAML only; Engram persists canonical topic full Markdown only' \
      'hybrid persists equivalent content in both only when selected' \
      'No implicit Engram write follows from the Markdown reader view' \
      '`none` returns the full content without activation and keeps complete detail inspectable on request or an appropriate surface rather than silently discarding it' \
      'Readback and final delivery present the concise localized reader view plus full canonical references, not a wall of YAML' \
      'Declared work intent selects MODE; project scope selects only applicable command bindings' \
      'Test-only maintenance may bind mapped production-scope evidence but never infers production work intent' \
      'Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence' \
      'Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence' \
      'A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row' \
      'strict-tdd requires RED, GREEN, TRIANGULATE, and REFACTOR evidence' \
      'Hosted CI proof distinguishes an explicit install from a cited image guarantee; neither requires arbitrary version pinning'; do
      grep -Fq "$text" "$file" || fail "$shape lacks two-level delivery contract: $text" || exit 1
    done
    ! grep -Fq 'Present the complete reader-friendly Markdown projection FIRST' "$file" || fail "$shape retains the contradictory complete-projection-first wording" || exit 1
    for category in new-observable-behavior bugfix data-schema-migration mechanical-behavior-preserving-change refactor docs-only ci configuration executable-scripts dependencies tests-only-maintenance; do
      grep -Fq "\`$category\`" "$file" || fail "$shape omits catalog category: $category" || exit 1
    done
  done
  for text in \
    "reader view first in the user's conversation language" \
    'complete technical artifacts in English' \
    'not a second policy or canonical source' \
    'full candidate identified by its checksum, not merely the reader overview' \
    'verified artifact paths/references or on request before approval' \
    'does not dump YAML or a wide command/tool-proof ledger by default' \
    'none returns the full content without activation' \
    'concise localized reader view plus full canonical references, not a wall of YAML'; do
    grep -Fqi "$text" "$readme" || fail "README lacks two-level delivery guidance: $text" || exit 1
  done
  ! grep -Fqi 'complete reader-friendly Markdown projection before the selected YAML' "$readme" || fail 'README retains the contradictory complete-projection-first wording' || exit 1
)

run() {
  local name="$1"
  if "$name"; then
    printf 'PASS: %s\n' "${name#test_}"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "${name#test_}" >&2
    FAIL=$((FAIL + 1))
  fi
}

run test_policy_contract
run test_human_clarification_contract
run test_opencode_final_sdd_init_contract
run test_pi_workflow_consumer_contract
run test_rubric_tdd_shape_grammar
run test_pi_policy_defined_forwarding_contract
run test_delta_shape_grammar
run test_prompt_procedure_contract
run test_two_level_delivery_catalog_contract

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
