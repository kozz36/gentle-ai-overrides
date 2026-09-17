#!/usr/bin/env bash
# Hermetic semantic and ownership checks for workflow-neutral rubric consumers.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-consumer.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT
PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
extract_shape() {
  awk -v shape="$2" '
    $0 == "<!-- shape:" shape " -->" { inside = 1; next }
    $0 == "<!-- /shape:" shape " -->" { inside = 0; exit }
    inside { print }
  ' "$1"
}

load_overlay() {
  HOME="$TMP_ROOT/home"
  GENTLE_AI_BACKUP_ROOT="$TMP_ROOT/backups"
  APPLY_SH_LIB=1
  export HOME GENTLE_AI_BACKUP_ROOT APPLY_SH_LIB
  # shellcheck source=../apply.sh
  source "$ROOT/apply.sh"
}

assert_generic_consumer() {
  local file="$1" label="$2" text
  text="$(tr '\n' ' ' < "$file" | tr -s ' ')"
  for required in \
    'approved workflow-neutral project-policy authority' \
    'caches the approved policy ONCE per session' \
    'resolves every distinct apply/verify work slice AFRESH' \
    '`default` ONLY when no non-default row matches' \
    '`strictest-wins` and evidence union apply only when the policy declares them' \
    "Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths" \
    'Consumers are read-only.' \
    'MUST stop apply/verify for human clarification' \
    'Binary `strict_tdd` fallback is permitted ONLY when no approved rubric exists.' \
    'Generic non-Pi hosts retain their legacy `sdd-init` producer ownership' \
    'do not require a `gentle-init/{project}` locator'; do
    printf '%s\n' "$text" | grep -Fq "$required" || fail "$label lacks $required" || return 1
  done
  for forbidden in 'RubricConsumerEnvelopeV1' 'RubricConsumerBlockedV1' 'recovery_action=run ' 'canonical `sdd-init` authoritative policy'; do
    ! printf '%s\n' "$text" | grep -Fq "$forbidden" || fail "$label retains obsolete $forbidden" || return 1
  done
}

assert_pi_consumer() {
  local file="$1" label="$2"
  for required in \
    '`gentle-init/{project}` first' \
    'legacy `sdd-init/{project}` authority' \
    'Once `gentle-init/{project}` exists, never' \
    'Select `default` ONLY when no non-default row matches and the policy actually declares a default.' \
    '`strictest-wins`, and evidence union only when the policy declares them.' \
    'Forward only phase-applicable commands under declared bindings' \
    'do not reuse an apply command for verify unless the policy declares it shared.' \
    'unknown needed phase binding requires clarification, never an invented command.' \
    'Do not inline all artifact contents; executors read their declared artifacts normally.' \
    'The Pi parent owns producer and activation handling; `gentle-init` is a candidate author only.' \
    'Runtime preflight or native-status injection does not resolve MODE; prompt delivery does not prove child enforcement.' \
    'Declared work intent selects MODE; project scope selects only applicable command bindings.' \
    'Test-only evidence may bind mapped production-scope evidence but never infers production intent.' \
    'Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence.' \
    'A manual old-path rule conflict with intent policy requires clarification; never rewrite the manual row.' \
    'Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence.' \
    'read-only'; do
    grep -Fq "$required" "$file" || fail "$label lacks $required" || return 1
  done
  for forbidden in \
    'Always choose the highest MODE.' \
    'all matching rows always apply' \
    'strictest-wins and evidence union always apply'; do
    ! grep -Fqi "$forbidden" "$file" || fail "$label contradicts declared policy resolution: $forbidden" || return 1
  done
  if grep -Fq '### Approved Rubric Forwarding for ODD' "$file"; then
    for required in \
      '`strict-tdd` requires observed RED, GREEN, TRIANGULATE, and REFACTOR and enables native test-first activation.' \
      '`standard` requires declared evidence without mandatory test-first ordering and disables native test-first activation while preserving applicable evidence and ordinary validation.' \
      '`skip` has no automated test gate unless applicable rows declare unioned evidence; it disables native test-first activation while preserving applicable evidence and ordinary validation.' \
      'Binary test-first activation represents sequencing only and never replaces the resolved MODE or evidence obligation.'; do
      grep -Fq "$required" "$file" || fail "$label lacks ODD binary activation invariant: $required" || return 1
    done
  fi
}

test_all_five_shapes_are_neutral() (
  local shape file
  for shape in list-item prose cache-sentence; do
    file="$TMP_ROOT/$shape.md"
    extract_shape "$ROOT/deltas/rubric-tdd.md" "$shape" > "$file"
    assert_generic_consumer "$file" "$shape" || exit 1
  done
  for shape in pi-workflow pi-odd-forwarding; do
    file="$TMP_ROOT/$shape.md"
    extract_shape "$ROOT/deltas/rubric-tdd.md" "$shape" > "$file"
    assert_pi_consumer "$file" "$shape" || exit 1
  done
)

test_generic_shapes_transform_without_pi_locator() (
  local prose="$TMP_ROOT/prose.md" list="$TMP_ROOT/list.md" json="$TMP_ROOT/opencode.json"
  load_overlay
  printf '%s\n' "$ANCHOR_PROSE" | rubric_transform_prose > "$prose" || fail 'prose transform refused anchor' || exit 1
  printf '%s\n' "$ANCHOR_ITEM3" "$CACHE_OLD" | rubric_transform_list > "$list" || fail 'list transform refused anchor' || exit 1
  jq -n --arg prompt "$ANCHOR_ITEM3" '{agent: {"gentle-orchestrator": {prompt: $prompt}}}' > "$json"
  rubric_apply_json "$json" || fail 'OpenCode transform refused anchor' || exit 1
  assert_generic_consumer "$prose" 'prose transform' || exit 1
  assert_generic_consumer "$list" 'list transform' || exit 1
  jq -r '.agent["gentle-orchestrator"].prompt' "$json" > "$TMP_ROOT/json.md"
  assert_generic_consumer "$TMP_ROOT/json.md" 'OpenCode transform' || exit 1
)

test_pi_transforms_forward_new_authority() (
  local workflow_input="$TMP_ROOT/workflow-input.md" workflow="$TMP_ROOT/workflow.md" odd_input="$TMP_ROOT/odd-input.md" odd="$TMP_ROOT/odd.md"
  load_overlay
  printf '%s\n\n%s\n\n%s\n' "$PI_WORKFLOW_HEADING" "$PI_WORKFLOW_BINARY" "$PI_WORKFLOW_ARCHIVE" > "$workflow_input"
  pi_rubric_workflow_transform < "$workflow_input" > "$workflow" || fail 'Pi workflow transform refused fixture' || exit 1
  assert_pi_consumer "$workflow" 'Pi workflow transform' || exit 1
  cat > "$odd_input" <<EOF
$PI_ODD_HEADING

$PI_ODD_CHECKS

$PI_ODD_DELEGATION
EOF
  pi_odd_forwarding_transform < "$odd_input" > "$odd" || fail 'Pi ODD transform refused fixture' || exit 1
  assert_pi_consumer "$odd" 'Pi ODD transform' || exit 1
)

test_pi_consumer_application_is_capability_gated() (
  local apply="$ROOT/apply.sh"
  grep -Fq 'pi_gentle_init_transaction_apply()' "$apply" || fail 'Pi grouped capability gate is missing' || exit 1
  grep -Fq 'selected package lacks gentle-init; all four Pi surfaces retained' "$apply" || fail 'Pi absent-capability four-surface no-op is missing' || exit 1
  grep -Fq 'pi|pi-gentle-init-transaction|@pi-gentle-pi-gentle-init@' "$apply" || fail 'Pi grouped transaction target is not gentle-init-rooted' || exit 1
  ! grep -Fqx 'pi|pi-rubric-workflow|@pi-gentle-pi-workflow@' "$apply" || fail 'Pi workflow remains independently mapped' || exit 1
  ! grep -Fqx 'pi|pi-odd-forwarding|@pi-gentle-pi-delegation@' "$apply" || fail 'Pi ODD remains independently mapped' || exit 1
)

test_declared_resolution_and_fallback_boundaries() (
  local pi="$TMP_ROOT/pi.md" odd="$TMP_ROOT/odd.md"
  extract_shape "$ROOT/deltas/rubric-tdd.md" pi-workflow > "$pi"
  extract_shape "$ROOT/deltas/rubric-tdd.md" pi-odd-forwarding > "$odd"
  grep -Fq 'Apply only declared matching, precedence, exceptions, and evidence-union rules' "$pi" || fail 'Pi workflow invents resolution' || exit 1
  grep -Fq 'Binary `strict_tdd` fallback is permitted ONLY when no approved rubric exists.' "$pi" || fail 'Pi workflow weakens binary fallback boundary' || exit 1
  grep -Fq 'This forwarding applies only to `sdd-apply` and `sdd-verify`, not to RDD reviewers.' "$pi" || fail 'Pi workflow crossed the RDD reviewer boundary' || exit 1
  grep -Fq 'not an absent rubric and MUST stop apply/verify for human clarification' "$pi" || fail 'Pi workflow treats invalid policy as absent' || exit 1
  grep -Fq 'If no approved rubric exists, use the existing configured or user-selected ODD mode, source, and exact runner.' "$odd" || fail 'Pi ODD lacks absent-rubric fallback' || exit 1
  grep -Fq 'An unknown, conflicting, ambiguous, or invalid source' "$odd" || fail 'Pi ODD lacks clarification boundary' || exit 1
  grep -Fq 'exact runner is the declared test-first command for `strict-tdd`, and `not-applicable` for `standard` or `skip`' "$odd" || fail 'Pi ODD lacks exact-runner phase binding' || exit 1
  grep -Fq 'Do not invoke `sdd-init` to determine ODD TDD' "$odd" || fail 'Pi ODD reintroduced init dispatch' || exit 1
  grep -Fq 'Do not alter native ODD tracking, the full project Engram mirror, resume reconciliation, generic workers, or the RDD sequence.' "$odd" || fail 'Pi ODD changed native ownership boundaries' || exit 1
)

test_forwarding_invariant_mutations_are_rejected() (
  local input="$TMP_ROOT/pi-forwarding-input.md" pi="$TMP_ROOT/pi-forwarding.md" odd_input="$TMP_ROOT/odd-forwarding-input.md" odd="$TMP_ROOT/odd-forwarding.md" mutation="$TMP_ROOT/forwarding-mutation.md"
  load_overlay
  printf '%s\n\n%s\n\n%s\n' "$PI_WORKFLOW_HEADING" "$PI_WORKFLOW_BINARY" "$PI_WORKFLOW_ARCHIVE" > "$input"
  pi_rubric_workflow_transform < "$input" > "$pi" || fail 'workflow forwarding fixture did not render' || exit 1
  sed 's/Runtime preflight or native-status injection does not resolve MODE; prompt delivery does not prove child enforcement\./runtime injection resolves MODE./' "$pi" > "$mutation"
  if assert_pi_consumer "$mutation" 'runtime-resolution mutation' 2>/dev/null; then fail 'consumer validator accepted runtime MODE-resolution mutation' || exit 1; fi
  sed 's/Test-only evidence may bind mapped production-scope evidence but never infers production intent\./tests infer production intent./' "$pi" > "$mutation"
  if assert_pi_consumer "$mutation" 'intent-scope mutation' 2>/dev/null; then fail 'consumer validator accepted intent/scope mutation' || exit 1; fi
  cat > "$odd_input" <<EOF
$PI_ODD_HEADING

$PI_ODD_CHECKS

$PI_ODD_DELEGATION
EOF
  pi_odd_forwarding_transform < "$odd_input" > "$odd" || fail 'ODD forwarding fixture did not render' || exit 1
  sed 's/disables native test-first activation while preserving applicable evidence and ordinary validation/enables native test-first activation/' "$odd" > "$mutation"
  if assert_pi_consumer "$mutation" 'ODD activation mutation' 2>/dev/null; then fail 'consumer validator accepted standard/skip binary activation mutation' || exit 1; fi
)

test_mode_contradiction_is_rejected() (
  local input="$TMP_ROOT/pi-mode-input.md" canonical="$TMP_ROOT/pi-mode-canonical.md" contradiction="$TMP_ROOT/pi-mode-contradiction.md"
  load_overlay
  printf '%s\n\n%s\n\n%s\n' "$PI_WORKFLOW_HEADING" "$PI_WORKFLOW_BINARY" "$PI_WORKFLOW_ARCHIVE" > "$input"
  pi_rubric_workflow_transform < "$input" > "$canonical" || fail 'Pi workflow fixture did not render' || exit 1
  sed 's|<!-- /gentle-ai:pi-rubric-forwarding -->|Always choose the highest MODE.\n<!-- /gentle-ai:pi-rubric-forwarding -->|' "$canonical" > "$contradiction"
  grep -Fq 'Always choose the highest MODE.' "$contradiction" || fail 'contradiction fixture was not created' || exit 1
  ! grep -Fq 'Always choose the highest MODE.' "$canonical" || fail 'canonical Pi workflow contains unconditional MODE selection' || exit 1
  if assert_pi_consumer "$contradiction" 'contradictory Pi workflow' 2>/dev/null; then
    fail 'real Pi consumer validator accepted unconditional MODE selection' || exit 1
  fi
)

run() { if "$1"; then pass "${1#test_}"; else FAIL=$((FAIL + 1)); fi; }
run test_all_five_shapes_are_neutral
run test_generic_shapes_transform_without_pi_locator
run test_pi_transforms_forward_new_authority
run test_pi_consumer_application_is_capability_gated
run test_declared_resolution_and_fallback_boundaries
run test_forwarding_invariant_mutations_are_rejected
run test_mode_contradiction_is_rejected
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
