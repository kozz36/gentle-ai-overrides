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
  grep -Fq 'Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric' "$file" || fail "$label allows active rubric in strict mode" || return 1
  grep -Fq 'Answer `rubric`: persist `strict_tdd: false` plus the active authoritative rubric' "$file" || fail "$label lacks rubric-mode activation" || return 1
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
    BEGIN { expected["list-item"] = expected["prose"] = expected["cache-sentence"] = expected["pi-workflow"] = 1 }
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

test_deterministic_fallback_contract() (
  local shape file reason
  for shape in skill details pi; do
    file="$TMP_ROOT/$shape-fallback.md"
    extract_init_shape "$shape" "$file" || exit 1
    grep -Fq 'eligible only before any rubric state has been declared or observed' "$file" || fail "$shape permits fallback after state declaration or observation" || exit 1
    for reason in provider-unconfigured provider-unavailable provider-timeout primary-output-malformed primary-output-structurally-invalid; do
      grep -Fq "\`$reason\`" "$file" || fail "$shape omits fallback reason: $reason" || exit 1
    done
    grep -Fq 'every other condition fails closed' "$file" || fail "$shape permits an untyped fallback reason" || exit 1
    grep -Fq 'A valid active rubric is reused' "$file" || fail "$shape may replace valid active state" || exit 1
    grep -Fq 'Declared-but-invalid, duplicate, staging, recovery-required, conflicted, unreadable, unavailable, or mismatched state blocks fallback' "$file" || fail "$shape permits fallback around observed invalid state" || exit 1
    grep -Fq 'fixed Task-Intent Baseline v1 rows in this canonical order' "$file" || fail "$shape lacks deterministic baseline rows" || exit 1
    grep -Fq 'baseline_version: task-intent-policy-baseline/v1' "$file" || fail "$shape lacks baseline provenance" || exit 1
    grep -Fq 'producer: deterministic-baseline-fallback' "$file" || fail "$shape lacks fallback producer provenance" || exit 1
    grep -Fq 'one admitted `fallback_reason` in candidate provenance' "$file" || fail "$shape lacks fallback reason provenance" || exit 1
    grep -Fq 'structural validation, canonical compilation, serialization, activation, and independent readback before `ResolutionV1` publication' "$file" || fail "$shape bypasses the canonical activation path" || exit 1
  done
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
run test_pi_policy_defined_forwarding_contract
run test_delta_shape_grammar
run test_deterministic_fallback_contract

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
