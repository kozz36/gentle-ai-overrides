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
  grep -Fq 'RubricConsumerEnvelopeV1' "$consumer" || fail 'consumer lacks the state-gate envelope' || exit 1
  grep -Fq 'sole resolution owner' "$consumer" || fail 'consumer permits downstream resolution' || exit 1
  grep -Fq 'RubricConsumerBlockedV1' "$consumer" || fail 'consumer lacks the blocked state-gate envelope' || exit 1
  grep -Fq 'never fall back to rubric `default` or binary `strict_tdd`' "$consumer" || fail 'consumer permits fallback after rubric observation' || exit 1
  grep -Fq 'only when no rubric state has ever been declared or observed' "$consumer" || fail 'consumer lacks the legacy boundary' || exit 1
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
run test_delta_shape_grammar
run test_deterministic_fallback_contract

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
