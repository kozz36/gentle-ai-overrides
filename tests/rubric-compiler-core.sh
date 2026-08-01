#!/usr/bin/env bash
# Hermetic contract checks for the producer-side rubric compiler boundary.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-core.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT
PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }
pass() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }

shape() {
  awk -v wanted="$1" '$0 == "<!-- shape:" wanted " -->" { in_shape = 1; next }
    $0 == "<!-- /shape:" wanted " -->" { exit } in_shape { print }' \
    "$ROOT/deltas/sdd-init-rubric.md"
}

require_contract() {
  local content="$1" label="$2" text
  for text in EvidenceV1 CandidateV1 QuestionV1 ConfirmationV1 CanonicalPolicyModelV1 \
    'OpenSpec remains unchanged' 'OpenSpec activation' ResolutionV1; do
    printf '%s\n' "$content" | grep -Fq "$text" || fail "$label lacks $text" || return 1
  done
}

candidate_valid() {
  local candidate="$1" confirmation="$2"
  awk -F= '
    $1 == "schema" || $1 == "digest" || $1 == "evidence" || $1 == "row" || $1 == "question" { seen[$1]++; value[$1] = $2; next }
    { bad = 1 }
    END { exit !( !bad && seen["schema"] == 1 && value["schema"] == "CandidateV1" && seen["digest"] == 1 && value["digest"] != "" && seen["evidence"] > 0 && seen["row"] > 0 && seen["question"] > 0 ) }
  ' "$candidate" || return 1
  awk -F= -v digest="$(awk -F= '$1 == "digest" { print $2 }' "$candidate")" '
    $1 == "schema" || $1 == "candidate_digest" || $1 == "maintainer" || $1 == "answer" { seen[$1]++; value[$1] = $2; next }
    { bad = 1 }
    END { exit !( !bad && seen["schema"] == 1 && value["schema"] == "ConfirmationV1" && seen["candidate_digest"] == 1 && value["candidate_digest"] == digest && seen["maintainer"] == 1 && value["maintainer"] != "" && seen["answer"] == 1 && value["answer"] == "rubric" ) }
  ' "$confirmation"
}

activate_openspec() {
  local candidate="$1" confirmation="$2" config="$3" resolution="$4" model digest txn tmp
  candidate_valid "$candidate" "$confirmation" || return 1
  [ "$(grep -c '^testing:$' "$config")" = 1 ] || return 1
  [ "$(grep -c '^  # gentle-ai:managed-testing:start$' "$config")" = 0 ] || return 1
  model="$TMP_ROOT/model"
  { printf '%s\n' 'schema=CanonicalPolicyModelV1'; LC_ALL=C sort "$candidate" "$confirmation"; } > "$model"
  digest="$(cksum "$model" | awk '{print $1 ":" $2}')"
  txn="v1:$digest"
  tmp="$(mktemp "$(dirname -- "$config")/.config.gentle-ai.XXXXXX")" || return 1
  awk -v txn="$txn" -v digest="$digest" '
    /^testing:$/ { print; print "  # gentle-ai:managed-testing:start"; print "  policy: \"rubric\""; print "  rubric:"; print "    active: true"; print "    authoritative: true"; print "    schema: \"ResolutionV1\""; print "    state: \"active\""; print "    txn_id: \"" txn "\""; print "    authority: \"openspec\""; print "    canonical_model_digest: \"" digest "\""; print "  # gentle-ai:managed-testing:end"; skip = 1; next }
    skip && /^[A-Za-z_][A-Za-z0-9_-]*:/ { skip = 0 }
    !skip { print }
  ' "$config" > "$tmp" || { rm -f -- "$tmp"; return 1; }
  grep -Fqx '    schema: "ResolutionV1"' "$tmp" && mv -- "$tmp" "$config" || { rm -f -- "$tmp"; return 1; }
  grep -Fqx "    txn_id: \"$txn\"" "$config" && grep -Fqx "    canonical_model_digest: \"$digest\"" "$config" || return 1
  printf 'schema=ResolutionV1\nstate=active\nauthority=openspec\ntxn_id=%s\ncanonical_model_digest=%s\nbackend_config_digest=%s\nreadback=verified\n' "$txn" "$digest" "$(cksum "$config" | awk '{print $1 ":" $2}')" > "$resolution"
}

test_shape_contract() (
  local name body
  for name in skill details pi; do
    body="$(shape "$name")"
    require_contract "$body" "$name" || exit 1
  done
  body="$(shape details)"
  printf '%s\n' "$body" | grep -Fq 'length-framing all scalar fields' || fail 'details lacks deterministic model serialization' || exit 1
  printf '%s\n' "$body" | grep -Fq 'same-directory temporary replacement' || fail 'details lacks atomic OpenSpec replacement' || exit 1
  printf '%s\n' "$body" | grep -Fq 'readback=verified' || fail 'details lacks independent activation readback' || exit 1
)

test_atomic_activation() (
  local candidate="$TMP_ROOT/candidate" confirmation="$TMP_ROOT/confirmation" config="$TMP_ROOT/config.yaml" resolution="$TMP_ROOT/resolution" before
  cat > "$candidate" <<'EOF'
schema=CandidateV1
digest=fixture-v1
evidence=unit:project:bash tests/run.sh
row=source:standard:unit
question=policy:strict|rubric
EOF
  cat > "$confirmation" <<'EOF'
schema=ConfirmationV1
candidate_digest=fixture-v1
maintainer=fixture
answer=rubric
EOF
  printf '%s\n' 'context: "preserve"' 'testing:' '  legacy: "replace"' 'strict_tdd: false' 'rules: "preserve"' > "$config"
  activate_openspec "$candidate" "$confirmation" "$config" "$resolution" || fail 'valid confirmed candidate did not activate' || exit 1
  grep -Fqx '    state: "active"' "$config" && grep -Fqx 'authority=openspec' "$resolution" && grep -Fqx 'readback=verified' "$resolution" || fail 'activation readback is incomplete' || exit 1
  before="$TMP_ROOT/before"
  cp -- "$config" "$before"
  printf '%s\n' 'schema=CandidateV1' >> "$candidate"
  ! activate_openspec "$candidate" "$confirmation" "$config" "$TMP_ROOT/rejected" || fail 'ambiguous candidate activated' || exit 1
  cmp -s "$before" "$config" || fail 'rejected candidate changed OpenSpec' || exit 1
  [ ! -e "$TMP_ROOT/rejected" ] || fail 'rejected candidate emitted a resolution' || exit 1
)

run() { if "$1"; then pass "${1#test_}"; else FAIL=$((FAIL + 1)); fi; }
run test_shape_contract
run test_atomic_activation
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
