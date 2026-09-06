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
    'union only applicable non-default rows' \
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
  for host in Cursor 'VS Code Copilot' 'Gemini CLI' Antigravity; do assert_forwarding "$list" "$host list" || exit 1; done
  assert_forwarding "$pi_workflow" 'Pi workflow' || exit 1
  grep -Fqx 'The orchestrator reads the canonical `sdd-init` authoritative policy directly from the active artifact store and caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; producer and activation semantics remain owned by `sdd-init`.' "$list" || fail 'list transform did not install canonical cache forwarding' || exit 1
  grep -Fq 'Gentle AI 2.6.0 with `gentle-pi@2.4.0`' "$pi_workflow" || fail 'Pi workflow lacks the 2.6.0/2.4.0 compatibility contract' || exit 1
  grep -Fq 'APPEND_SYSTEM.md remains installer-managed and untouched.' "$pi_workflow" || fail 'Pi workflow lacks the APPEND preservation boundary' || exit 1
  jq -r '.agent["gentle-orchestrator"].prompt' "$json" > "$TMP_ROOT/opencode-prompt"
  assert_forwarding "$TMP_ROOT/opencode-prompt" 'OpenCode JSON' || exit 1
  jq -e --arg cache "$CACHE_NEW" '.agent["gentle-orchestrator"].prompt | contains($cache)' "$json" >/dev/null || fail 'OpenCode JSON did not preserve escaped canonical cache forwarding' || exit 1
  host_rows | grep -Fqx 'codex|rubric-none|.codex/AGENTS.md' || fail 'Codex is not rubric-none' || exit 1
  host_rows | grep -Fq 'kimi|' && fail 'Kimi must remain unmanaged' && exit 1
  grep -Fq 'Kimi is explicitly current-scope unmanaged' "$ROOT/deltas/rubric-tdd.md" || fail 'Kimi scope is undocumented' || exit 1
)

run() { if "$1"; then pass "${1#test_}"; else FAIL=$((FAIL + 1)); fi; }
run test_consumer_wording_uses_canonical_policy
run test_temporary_home_host_goldens
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
