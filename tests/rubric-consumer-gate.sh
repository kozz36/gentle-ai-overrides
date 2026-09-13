#!/usr/bin/env bash
# Hermetic state-gate and host-forwarding checks for rubric consumers.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-consumer.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT
PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
digest() { cksum "$1" | awk '{print $1 ":" $2}'; }
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

assert_forwarding() {
  local file="$1" label="$2" content text
  content="$(tr '\n' ' ' < "$file" | tr -s ' ')"
  for text in \
    'read the canonical `sdd-init` authoritative policy directly for the active artifact store' \
    'caches the canonical policy ONCE per session' \
    'resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules' \
    '`default` ONLY when no non-default row matches' \
    'Forward the effective MODE and the policy'"'"'s exact declared commands, disciplines/evidence, and skill paths' \
    'without substituting downstream matching rules or policy rewriting.' \
    'Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy.' \
    'Producer and activation semantics remain owned by `sdd-init`.' \
    'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' \
    'do not fabricate runtime recovery dispatch.' \
    'Binary `strict_tdd` fallback is permitted ONLY when no rubric exists.'; do
    printf '%s\n' "$content" | grep -Fq "$text" || fail "$label lacks $text" || return 1
  done
  for text in RubricConsumerEnvelopeV1 RubricConsumerBlockedV1 'canonical-model digest' 'state gate' 'Resolve it ONCE per session' 'then caches that resolution' 'recovery_action=run '; do
    ! printf '%s\n' "$content" | grep -Fq "$text" || fail "$label retains obsolete $text" || return 1
  done
}

generic_resolution_matches() {
  grep -Fq 'otherwise apply strictest MODE precedence and union only applicable non-default rows' "$1"
}

pi_forwarding_matches() {
  local file="$1" text
  for text in \
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
    grep -Fq "$text" "$file" || return 1
  done
  # Bounded regression guards; this is not general prose-contradiction parsing.
  ! grep -Fq 'Always choose the highest MODE.' "$file" &&
    ! grep -Fq 'otherwise apply strictest MODE precedence and union only applicable non-default rows' "$file"
}

assert_pi_forwarding() {
  pi_forwarding_matches "$1" || fail "$2 lacks the policy-defined Pi forwarding contract"
}

test_consumer_wording_uses_canonical_policy() (
  local shape output
  for shape in list-item prose cache-sentence pi-workflow; do
    output="$TMP_ROOT/$shape.md"
    extract_shape "$ROOT/deltas/rubric-tdd.md" "$shape" > "$output"
    grep -Fq 'canonical `sdd-init` authoritative policy directly' "$output" || fail "$shape does not read canonical policy directly" || exit 1
    ! grep -Fq 'RubricConsumerEnvelopeV1' "$output" || fail "$shape retains the consumer envelope" || exit 1
    ! grep -Fq 'RubricConsumerBlockedV1' "$output" || fail "$shape retains the consumer blocked envelope" || exit 1
    grep -Fq 'resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules' "$output" || fail "$shape can reuse a first-slice resolution session-wide" || exit 1
    ! grep -Fq 'Resolve it ONCE per session' "$output" || fail "$shape resolves a first slice only once per session" || exit 1
    ! grep -Fq 'recovery_action=run ' "$output" || fail "$shape fabricates runtime recovery dispatch" || exit 1
  done
  output="$TMP_ROOT/pi-workflow.md"
  extract_shape "$ROOT/deltas/rubric-tdd.md" pi-workflow > "$output"
  assert_pi_forwarding "$output" 'Pi workflow' || exit 1
  grep -Fq 'It may mechanically match existing policy rows using only those declared rules and must never invent commands or evidence.' "$output" || fail 'Pi workflow does not permit mechanical matching of existing rows' || exit 1
  ! grep -Fq 'never author, generate, mutate, broaden, infer, select' "$output" || fail 'Pi workflow forbids selecting existing rows' || exit 1
)

test_temporary_home_host_goldens() (
  local prose="$TMP_ROOT/prose" list="$TMP_ROOT/list" json="$TMP_ROOT/opencode.json" pi_input="$TMP_ROOT/pi-input" pi_workflow="$TMP_ROOT/pi-workflow" host
  load_overlay
  printf '%s\n' "$ANCHOR_PROSE" > "$TMP_ROOT/prose-input"
  rubric_transform_prose < "$TMP_ROOT/prose-input" > "$prose" || fail 'Claude prose golden did not render' || exit 1
  printf '%s\n' "$ANCHOR_ITEM3" "$CACHE_OLD" > "$TMP_ROOT/list-input"
  rubric_transform_list < "$TMP_ROOT/list-input" > "$list" || fail 'list golden did not render' || exit 1
  printf '%s\n\n%s\n\n%s\n' "$PI_WORKFLOW_HEADING" "$PI_WORKFLOW_BINARY" "$PI_WORKFLOW_ARCHIVE" > "$pi_input"
  pi_rubric_workflow_transform < "$pi_input" > "$pi_workflow" || fail 'Pi workflow golden did not render' || exit 1
  jq -n --arg prompt "$ANCHOR_ITEM3"$'\n'"$CACHE_OLD" '{agent: {"gentle-orchestrator": {prompt: $prompt}}}' > "$json"
  rubric_apply_json "$json" || fail 'OpenCode JSON golden did not render' || exit 1
  assert_forwarding "$prose" 'Claude lazy prose' || exit 1
  generic_resolution_matches "$prose" || fail 'Claude lazy prose lost its declared all-rows resolution' || exit 1
  for host in Cursor 'VS Code Copilot' 'Gemini CLI' Antigravity; do
    assert_forwarding "$list" "$host list" || exit 1
    generic_resolution_matches "$list" || fail "$host list lost its declared all-rows resolution" || exit 1
  done
  assert_pi_forwarding "$pi_workflow" 'Pi workflow' || exit 1
  grep -Fqx 'The orchestrator reads the canonical `sdd-init` authoritative policy directly from the active artifact store and caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; producer and activation semantics remain owned by `sdd-init`.' "$list" || fail 'list transform did not install canonical cache forwarding' || exit 1
  grep -Fq 'Gentle AI 2.6.0 with `gentle-pi@2.4.0`' "$pi_workflow" || fail 'Pi workflow lacks the 2.6.0/2.4.0 compatibility contract' || exit 1
  grep -Fq 'APPEND_SYSTEM.md remains installer-managed and untouched.' "$pi_workflow" || fail 'Pi workflow lacks the APPEND preservation boundary' || exit 1
  jq -r '.agent["gentle-orchestrator"].prompt' "$json" > "$TMP_ROOT/opencode-prompt"
  assert_forwarding "$TMP_ROOT/opencode-prompt" 'OpenCode JSON' || exit 1
  generic_resolution_matches "$TMP_ROOT/opencode-prompt" || fail 'OpenCode JSON lost its declared all-rows resolution' || exit 1
  jq -e --arg cache "$CACHE_NEW" '.agent["gentle-orchestrator"].prompt | contains($cache)' "$json" >/dev/null || fail 'OpenCode JSON did not preserve escaped canonical cache forwarding' || exit 1
  host_rows | grep -Fqx 'codex|rubric-none|.codex/AGENTS.md' || fail 'Codex is not rubric-none' || exit 1
  host_rows | grep -Fq 'kimi|' && fail 'Kimi must remain unmanaged' && exit 1
  grep -Fq 'Kimi is explicitly current-scope unmanaged' "$ROOT/deltas/rubric-tdd.md" || fail 'Kimi scope is undocumented' || exit 1
)

test_pi_policy_regression_is_rejected() (
  local pi_input="$TMP_ROOT/pi-regression-input" pi_workflow="$TMP_ROOT/pi-regression-workflow" regression="$TMP_ROOT/pi-regression-mutated" contradiction="$TMP_ROOT/pi-regression-contradiction"
  load_overlay
  printf '%s\n\n%s\n\n%s\n' "$PI_WORKFLOW_HEADING" "$PI_WORKFLOW_BINARY" "$PI_WORKFLOW_ARCHIVE" > "$pi_input"
  pi_rubric_workflow_transform < "$pi_input" > "$pi_workflow" || fail 'Pi regression fixture did not render' || exit 1
  assert_pi_forwarding "$pi_workflow" 'Pi regression fixture' || exit 1
  sed 's/Policy-defined matching, precedence, and exceptions govern each slice\./Generic strictest matching governs each slice./' "$pi_workflow" > "$regression"
  if pi_forwarding_matches "$regression"; then
    fail 'Pi forwarding test accepts a generic-resolution regression' || exit 1
  fi
  sed 's|<!-- /gentle-ai:pi-rubric-forwarding -->|Always choose the highest MODE.\n<!-- /gentle-ai:pi-rubric-forwarding -->|' "$pi_workflow" > "$contradiction"
  if pi_forwarding_matches "$contradiction"; then
    fail 'Pi forwarding test accepts a positive-preserving MODE contradiction' || exit 1
  fi
)


run() { if "$1"; then pass "${1#test_}"; else FAIL=$((FAIL + 1)); fi; }
run test_consumer_wording_uses_canonical_policy
run test_temporary_home_host_goldens
run test_pi_policy_regression_is_rejected
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
