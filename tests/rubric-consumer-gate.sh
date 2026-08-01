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
field() { awk -F= -v key="$2" '$1 == key { count++; value = substr($0, length(key) + 2) } END { if (count == 1) print value; else exit 1 }' "$1"; }
safe() { case "$1" in ''|*[!A-Za-z0-9._:-]*) return 1 ;; esac; }

blocked() {
  printf 'schema=RubricConsumerBlockedV1\nbackend=openspec\nobserved_state=%s\nmismatch=%s\nrecovery_action=run sdd-init recovery\n' "$1" "$2"
  return 1
}

consume() {
  local state="$1" intent="$2" schema status authority txn model revision readback identity envelope
  [ -f "$state" ] || { blocked none outage; return 1; }
  schema="$(field "$state" schema)" || { blocked none malformed; return 1; }
  status="$(field "$state" state)" || { blocked none malformed; return 1; }
  case "$status" in staging|'recovery-required'|conflict) blocked "$status" "$status"; return 1 ;; active) ;; *) blocked "$status" state-mismatch; return 1 ;; esac
  authority="$(field "$state" authority)" || { blocked "$status" malformed; return 1; }
  txn="$(field "$state" txn_id)" || { blocked "$status" malformed; return 1; }
  model="$(field "$state" canonical_model_digest)" || { blocked "$status" malformed; return 1; }
  revision="$(field "$state" backend_revision)" || { blocked "$status" malformed; return 1; }
  readback="$(field "$state" readback)" || { blocked "$status" malformed; return 1; }
  identity="$(field "$state" identity)" || { blocked "$status" malformed; return 1; }
  [ "$schema:$authority:$readback" = ResolutionV1:openspec:verified ] || { blocked "$status" readback-mismatch; return 1; }
  safe "$txn" && safe "$model" && case "$revision" in *[!0-9]*|'') false ;; *) true ;; esac || { blocked "$status" malformed; return 1; }
  [ "$identity" = "$txn:$model:$revision" ] || { blocked "$status" identity-mismatch; return 1; }
  envelope="$TMP_ROOT/envelope"
  printf 'intent=%s\ntxn=%s\nmodel=%s\n' "$intent" "$txn" "$model" > "$envelope"
  printf 'schema=RubricConsumerEnvelopeV1\nbackend=openspec\nstate=active\nresolution_owner=orchestrator\ncombined_row=%s\ncanonical_model_digest=%s\nresolved_envelope_digest=%s\ndownstream_reclassification=forbidden\n' \
    "$intent" "$model" "$(digest "$envelope")"
}

write_state() {
  local file="$1" status="${2-active}" txn="${3-txn-1}" model="${4-model-1}" revision="${5-4}"
  printf 'schema=ResolutionV1\nstate=%s\nauthority=openspec\ntxn_id=%s\ncanonical_model_digest=%s\nbackend_revision=%s\nreadback=verified\nidentity=%s:%s:%s\n' \
    "$status" "$txn" "$model" "$revision" "$txn" "$model" "$revision" > "$file"
}

assert_blocked() {
  local name="$1" state="$2" expected="$3" output
  output="$TMP_ROOT/$name.out"
  if consume "$state" source > "$output" 2>/dev/null; then
    fail "$name was consumed" || return 1
  fi
  grep -Fqx 'schema=RubricConsumerBlockedV1' "$output" && grep -Fqx "mismatch=$expected" "$output" && \
    grep -Fqx 'recovery_action=run sdd-init recovery' "$output" && ! grep -Fq 'model-1' "$output" || fail "$name did not redact a valid blocked envelope"
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
  local file="$1" label="$2" content
  content="$(tr '\n' ' ' < "$file" | tr -s ' ')"
  for text in RubricConsumerEnvelopeV1 'sole resolution owner' 'without downstream re-classification' RubricConsumerBlockedV1 'recovery_action=run sdd-init recovery'; do
    printf '%s\n' "$content" | grep -Fq "$text" || fail "$label lacks $text" || return 1
  done
}

test_state_matrix_and_single_owner() (
  local active="$TMP_ROOT/active" output="$TMP_ROOT/active.out" kind state
  write_state "$active"
  consume "$active" boundary > "$output" || fail 'active state blocked' || exit 1
  grep -Fqx 'schema=RubricConsumerEnvelopeV1' "$output" && grep -Fqx 'resolution_owner=orchestrator' "$output" && \
    grep -Fqx 'combined_row=boundary' "$output" && grep -Fqx 'downstream_reclassification=forbidden' "$output" && \
    [ "$(grep -c '^resolved_envelope_digest=' "$output")" = 1 ] || fail 'active state did not produce one owner envelope' || exit 1
  for kind in absent malformed duplicate staging recovery-required conflict unavailable outage identity readback; do
    state="$TMP_ROOT/$kind"
    case "$kind" in
      absent|outage) rm -f -- "$state" ;;
      *) cp -- "$active" "$state" ;;
    esac
    case "$kind" in
      malformed) awk -F= '$1 != "txn_id" { print }' "$state" > "$state.tmp" && mv -- "$state.tmp" "$state" ;;
      duplicate) printf '%s\n' 'state=active' >> "$state" ;;
      staging|recovery-required|conflict|unavailable) write_state "$state" "$kind" ;;
      identity) awk -F= '$1 == "identity" { print "identity=wrong"; next } { print }' "$state" > "$state.tmp" && mv -- "$state.tmp" "$state" ;;
      readback) awk -F= '$1 == "readback" { print "readback=missing"; next } { print }' "$state" > "$state.tmp" && mv -- "$state.tmp" "$state" ;;
    esac
    case "$kind" in absent|outage) expected=outage ;; staging|'recovery-required'|conflict) expected="$kind" ;; unavailable) expected='state-mismatch' ;; identity) expected='identity-mismatch' ;; readback) expected='readback-mismatch' ;; *) expected=malformed ;; esac
    assert_blocked "$kind" "$state" "$expected" || exit 1
  done
)

test_temporary_home_host_goldens() (
  local prose="$TMP_ROOT/prose" list="$TMP_ROOT/list" json="$TMP_ROOT/opencode.json" host
  load_overlay
  printf '%s\n' "$ANCHOR_PROSE" > "$TMP_ROOT/prose-input"
  rubric_transform_prose < "$TMP_ROOT/prose-input" > "$prose" || fail 'Claude prose golden did not render' || exit 1
  printf '%s\n' "$ANCHOR_ITEM3" > "$TMP_ROOT/list-input"
  rubric_transform_list < "$TMP_ROOT/list-input" > "$list" || fail 'list golden did not render' || exit 1
  jq -n --arg prompt "$RUBRIC_ITEM4" '{agent: {"gentle-orchestrator": {prompt: $prompt}}}' > "$json"
  assert_forwarding "$prose" 'Claude lazy prose' || exit 1
  for host in Pi Cursor 'VS Code Copilot' 'Gemini CLI' Antigravity; do assert_forwarding "$list" "$host list" || exit 1; done
  jq -r '.agent["gentle-orchestrator"].prompt' "$json" > "$TMP_ROOT/opencode-prompt"
  assert_forwarding "$TMP_ROOT/opencode-prompt" 'OpenCode JSON' || exit 1
  host_rows | grep -Fqx 'codex|rubric-none|.codex/AGENTS.md' || fail 'Codex is not rubric-none' || exit 1
  host_rows | grep -Fq 'kimi|' && fail 'Kimi must remain unmanaged' && exit 1
  grep -Fq 'Kimi is explicitly current-scope unmanaged' "$ROOT/deltas/rubric-tdd.md" || fail 'Kimi scope is undocumented' || exit 1
)

run() { if "$1"; then pass "${1#test_}"; else FAIL=$((FAIL + 1)); fi; }
run test_state_matrix_and_single_owner
run test_temporary_home_host_goldens
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
