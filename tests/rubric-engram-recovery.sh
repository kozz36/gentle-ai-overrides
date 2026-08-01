#!/usr/bin/env bash
# Hermetic fake-store checks for the rubric Engram and hybrid recovery contract.
set -uo pipefail

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-engram.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT
PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
digest() { cksum "$1" | awk '{print $1 ":" $2}'; }
field() { awk -F= -v key="$2" '$1 == key { count++; value = substr($0, length(key) + 2) } END { if (count == 1) print value; else exit 1 }' "$1"; }
safe_project() { case "$1" in ''|*[!A-Za-z0-9._-]*) return 1 ;; esac; }

store_write() {
  local store="$1" topic="$2" state="$3" txn="$4" model="$5" prior="$6" tmp revision
  revision=$((prior + 1))
  tmp="$(mktemp "$store/.current.XXXXXX")" || return 1
  printf 'schema=ActivationStateV1\ntopic=%s\nstate=%s\ntxn_id=%s\ncanonical_model_digest=%s\nbackend_payload_digest=%s\npredecessor_revision=%s\ncommitted_revision=%s\nbackend_revision=%s\nreadback=verified\n' \
    "$topic" "$state" "$txn" "$model" "$model" "$prior" "$revision" "$revision" > "$tmp" || return 1
  mv -- "$tmp" "$store/current"
}

store_readback() {
  local store="$1" topic="$2" state="$3" txn="$4" model="$5" file revision
  file="$store/current"
  [ -f "$file" ] && [ "$(field "$file" schema)" = ActivationStateV1 ] && \
    [ "$(field "$file" topic)" = "$topic" ] && [ "$(field "$file" state)" = "$state" ] && \
    [ "$(field "$file" txn_id)" = "$txn" ] && [ "$(field "$file" canonical_model_digest)" = "$model" ] && \
    [ "$(field "$file" backend_payload_digest)" = "$model" ] && [ "$(field "$file" readback)" = verified ] || return 1
  revision="$(field "$file" backend_revision)" || return 1
  [ "$(field "$file" committed_revision)" = "$revision" ] && case "$revision" in *[!0-9]*|'') return 1 ;; *) return 0 ;; esac
}

journal_write() {
  local journal="$1" state="$2" topic="$3" txn="$4" model="$5" preimage="$6"
  printf 'schema=RecoveryV1\nstate=%s\ntopic=%s\ntxn_id=%s\ncanonical_model_digest=%s\npreimage=%s\n' \
    "$state" "$topic" "$txn" "$model" "$preimage" > "$journal"
}

activate_engram() {
  local project="$1" model_file="$2" store="$3" journal="$4" result="$5" fault="${6:-}" topic model txn prior preimage
  safe_project "$project" && [ -d "$store" ] && [ -f "$model_file" ] || return 1
  if [ -f "$journal" ] && [ "$(field "$journal" state)" = recovery-required ]; then return 1; fi
  topic="sdd-init/$project"
  model="$(digest "$model_file")"
  txn="v1:$model"
  preimage="$journal.preimage"
  if [ -f "$store/current" ]; then
    cp -- "$store/current" "$preimage" || return 1
    prior="$(field "$store/current" backend_revision)" || return 1
  else
    : > "$preimage"
    prior=0
  fi
  store_write "$store" "$topic" staging "$txn" "$model" "$prior" || return 1
  store_readback "$store" "$topic" staging "$txn" "$model" || return 1
  if [ "$fault" = after-staging ]; then
    journal_write "$journal" recovery-required "$topic" "$txn" "$model" "$([ -s "$preimage" ] && printf present || printf absent)"
    return 1
  fi
  prior="$(field "$store/current" backend_revision)" || return 1
  store_write "$store" "$topic" active "$txn" "$model" "$prior" || return 1
  store_readback "$store" "$topic" active "$txn" "$model" || return 1
  printf 'schema=ResolutionV1\nmode=engram\nstate=active\nauthority=engram\ntxn_id=%s\ncanonical_model_digest=%s\nengram_topic=%s\nengram_backend_revision=%s\nreadback=verified\n' \
    "$txn" "$model" "$topic" "$(field "$store/current" backend_revision)" > "$result"
}

recover_engram() {
  local store="$1" journal="$2" preimage
  [ -f "$journal" ] && [ "$(field "$journal" state)" = recovery-required ] || return 1
  preimage="$journal.preimage"
  if [ "$(field "$journal" preimage)" = present ]; then
    cp -- "$preimage" "$store/current" || return 1
    cmp -s "$preimage" "$store/current" || return 1
  else
    rm -f -- "$store/current"
    [ ! -e "$store/current" ] || return 1
  fi
  journal_write "$journal" recovered "$(field "$journal" topic)" "$(field "$journal" txn_id)" "$(field "$journal" canonical_model_digest)" "$(field "$journal" preimage)"
}

openspec_active() {
  local file="$1" txn="$2" model="$3"
  [ "$(field "$file" schema)" = ResolutionV1 ] && [ "$(field "$file" state)" = active ] && \
    [ "$(field "$file" authority)" = openspec ] && [ "$(field "$file" txn_id)" = "$txn" ] && \
    [ "$(field "$file" canonical_model_digest)" = "$model" ]
}

activate_hybrid() {
  local project="$1" model="$2" openspec="$3" store="$4" journal="$5" result="$6" fault="${7:-}" digest_value txn engram
  digest_value="$(digest "$model")"
  txn="v1:$digest_value"
  openspec_active "$openspec" "$txn" "$digest_value" || return 1
  engram="$TMP_ROOT/engram-resolution"
  activate_engram "$project" "$model" "$store" "$journal" "$engram" "$fault" || return 1
  [ "$(field "$engram" txn_id)" = "$txn" ] && [ "$(field "$engram" canonical_model_digest)" = "$digest_value" ] || return 1
  printf 'schema=ResolutionV1\nmode=hybrid\nstate=active\nauthority=openspec\ntxn_id=%s\ncanonical_model_digest=%s\nengram_backend_revision=%s\nreadback=verified\n' \
    "$txn" "$digest_value" "$(field "$engram" engram_backend_revision)" > "$result"
}

test_exact_topic_and_readback() (
  local model="$TMP_ROOT/model" store="$TMP_ROOT/store" journal="$TMP_ROOT/journal" result="$TMP_ROOT/result" home_before clean
  mkdir "$store"
  printf '%s\n' 'schema=CanonicalPolicyModelV1' 'rows=fixture' > "$model"
  home_before="$HOME"
  activate_engram demo "$model" "$store" "$journal" "$result" || fail 'Engram activation failed' || exit 1
  [ "$HOME" = "$home_before" ] || fail 'fake store changed HOME' || exit 1
  grep -Fqx 'engram_topic=sdd-init/demo' "$result" && grep -Fqx 'readback=verified' "$result" || fail 'exact topic or readback binding is missing' || exit 1
  ! activate_engram '../global' "$model" "$store" "$journal" "$TMP_ROOT/global-result" || fail 'global Engram topic was accepted' || exit 1
  clean="$TMP_ROOT/clean-current"
  cp -- "$store/current" "$clean"
  awk -F= '$1 == "backend_revision" { print "backend_revision=999"; next } { print }' "$clean" > "$store/current"
  ! store_readback "$store" sdd-init/demo active "$(field "$result" txn_id)" "$(field "$result" canonical_model_digest)" || fail 'backend revision mismatch passed' || exit 1
  cp -- "$clean" "$store/current"
  printf '%s\n' 'canonical_model_digest=tampered' >> "$store/current"
  ! store_readback "$store" sdd-init/demo active "$(field "$result" txn_id)" "$(field "$result" canonical_model_digest)" || fail 'tampered backend readback passed' || exit 1
)

test_hybrid_recovery_before_resume() (
  local model="$TMP_ROOT/hybrid-model" openspec="$TMP_ROOT/openspec" store="$TMP_ROOT/hybrid-store" journal="$TMP_ROOT/hybrid-journal" result="$TMP_ROOT/hybrid-result" digest_value txn
  mkdir "$store"
  printf '%s\n' 'schema=CanonicalPolicyModelV1' 'rows=hybrid' > "$model"
  digest_value="$(digest "$model")"
  txn="v1:$digest_value"
  printf 'schema=ResolutionV1\nstate=active\nauthority=openspec\ntxn_id=%s\ncanonical_model_digest=%s\nreadback=verified\n' "$txn" "$digest_value" > "$openspec"
  activate_hybrid demo "$model" "$openspec" "$store" "$journal" "$result" || fail 'hybrid activation failed' || exit 1
  grep -Fqx 'authority=openspec' "$result" && grep -Fqx "txn_id=$txn" "$result" && grep -Fqx "canonical_model_digest=$digest_value" "$result" && grep -Fqx 'readback=verified' "$result" || fail 'hybrid did not retain OpenSpec authority and equivalence' || exit 1

  rm -f -- "$store/current" "$journal"
  ! activate_hybrid demo "$model" "$openspec" "$store" "$journal" "$result" after-staging || fail 'partial hybrid activation succeeded' || exit 1
  grep -Fqx 'state=recovery-required' "$journal" && store_readback "$store" sdd-init/demo staging "$txn" "$digest_value" || fail 'partial activation lacks recoverable staging state' || exit 1
  ! activate_hybrid demo "$model" "$openspec" "$store" "$journal" "$result" || fail 'activation resumed without recovery' || exit 1
  recover_engram "$store" "$journal" || fail 'compensation failed' || exit 1
  grep -Fqx 'state=recovered' "$journal" && [ ! -e "$store/current" ] || fail 'recovery was not independently verified' || exit 1
  activate_hybrid demo "$model" "$openspec" "$store" "$journal" "$result" || fail 'activation did not resume after verified recovery' || exit 1
)

run() { if "$1"; then pass "${1#test_}"; else FAIL=$((FAIL + 1)); fi; }
run test_exact_topic_and_readback
run test_hybrid_recovery_before_resume
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
