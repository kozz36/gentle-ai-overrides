#!/usr/bin/env bash
# Read-only benchmark scorer. All clone writes are prohibited; temporary state stays in TMP.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
REQUIRED_BINDINGS=(RUBRIC_BENCHMARK_REFERENCE_CORPUS_ROOT RUBRIC_BENCHMARK_COMPARISON_CORPUS_ROOT)
missing_bindings=()
for binding in "${REQUIRED_BINDINGS[@]}"; do [ -n "${!binding:-}" ] || missing_bindings+=("$binding"); done
if [ "${#missing_bindings[@]}" -gt 0 ]; then
  printf 'SKIP: benchmark requires explicit external corpus bindings: %s\n' "${missing_bindings[*]}"
  exit 0
fi
for binding in "${REQUIRED_BINDINGS[@]}"; do
  git -C "${!binding}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf 'FAIL: %s must identify an external Git working tree.\n' "$binding" >&2; exit 2; }
done
CNSIC_ROOT="$RUBRIC_BENCHMARK_REFERENCE_CORPUS_ROOT"
GENTLE_ROOT="$RUBRIC_BENCHMARK_COMPARISON_CORPUS_ROOT"
ORACLE="$ROOT/tests/fixtures/rubric-compiler/benchmark/cnsic-oracle.tsv"
CONFIRMED="$ROOT/tests/fixtures/rubric-compiler/benchmark/cnsic-confirmed.tsv"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-benchmark.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
PASS=0
FAIL=0

ok() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
no() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

snapshot() {
  local repo=$1 out=$2
  (
    cd "$repo" || exit 1
    git rev-parse HEAD
    GIT_OPTIONAL_LOCKS=0 git status --porcelain=v1 --untracked-files=all
    find .rubric-eval -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
  ) > "$out"
}

binding_fields_complete() {
  awk '
    $0 == "bindings:" { active = 1; next }
    active && $0 == "rows:" { exit }
    active && /^  - id:/ {
      if (seen && !(declaration && proof && provenance)) exit 1
      seen = 1; declaration = proof = provenance = 0; next
    }
    active && /^[[:space:]]+command_declaration:/ { declaration = 1 }
    active && /^[[:space:]]+tool_proof:/ { proof = 1 }
    active && /^[[:space:]]+provenance:/ { provenance = 1 }
    END { exit !(seen && declaration && proof && provenance) }
  ' "$1"
}

repository_only() {
  local label=$1 candidate=$2 evidence=$3
  [ -f "$candidate" ] && [ -f "$evidence" ] || return 1
  binding_fields_complete "$candidate" || return 1
  grep -Eq '^(detected_but_unsatisfied|unsupported_classes|policy_questions):' "$candidate" || return 1
  grep -Eq '^(inference_limits|policy_questions):' "$candidate" || return 1
  grep -Fq 'provenance:' "$candidate" || return 1
  grep -Fq 'CodeGraph' "$evidence" || return 1
  ! grep -Eiq 'canonical[[:space:]-]*rubric|scorer-only oracle' "$candidate" || return 1
  ok "$label repository-only candidate reports provenance and safety without parity"
}

data_lines() { awk 'NF && $1 !~ /^#/' "$1"; }
row_count() { data_lines "$1" | awk 'END { print NR + 0 }'; }
valid_rows() {
  data_lines "$1" | awk -F '|' '
    NF != 3 || !$1 || !$2 || !$3 || seen[$1]++ { exit 1 }
    END { exit NR != 16 }
  '
}
binding_set() {
  data_lines "$1" | awk -F '|' '
    $3 != "-" { n = split($3, values, ","); for (i = 1; i <= n; i++) print values[i] }
  ' | LC_ALL=C sort -u
}

score_confirmed_cnsic() {
  valid_rows "$ORACLE" && valid_rows "$CONFIRMED" || return 1
  [ "$(row_count "$ORACLE")" = 16 ] && [ "$(row_count "$CONFIRMED")" = 16 ] || return 1
  data_lines "$ORACLE" | LC_ALL=C sort > "$TMP/oracle.rows"
  data_lines "$CONFIRMED" | LC_ALL=C sort > "$TMP/confirmed.rows"
  binding_set "$ORACLE" > "$TMP/oracle.bindings"
  binding_set "$CONFIRMED" > "$TMP/confirmed.bindings"
  cmp -s "$TMP/oracle.rows" "$TMP/confirmed.rows" || return 1
  cmp -s "$TMP/oracle.bindings" "$TMP/confirmed.bindings" || return 1
  [ "$(wc -l < "$TMP/oracle.bindings" | tr -d ' ')" = 7 ] || return 1
  ok 'CNSIC confirmed scorer reaches 16/16 signature-policy equality and exact 7-binding identity equality'
}

snapshot "$CNSIC_ROOT" "$TMP/cnsic.before" || { no 'CNSIC clone baseline snapshot'; exit 1; }
snapshot "$GENTLE_ROOT" "$TMP/gentle.before" || { no 'Gentle AI clone baseline snapshot'; exit 1; }

repository_only CNSIC "$CNSIC_ROOT/.rubric-eval/candidate-v2.yaml" "$CNSIC_ROOT/.rubric-eval/evidence-v2.md" || no 'CNSIC repository-only provenance and safety'
repository_only 'Gentle AI' "$GENTLE_ROOT/.rubric-eval/candidate-v2.yaml" "$GENTLE_ROOT/.rubric-eval/evidence-v2.md" || no 'Gentle AI repository-only provenance and safety'
score_confirmed_cnsic || no 'CNSIC confirmed scorer equality'

snapshot "$CNSIC_ROOT" "$TMP/cnsic.after" || no 'CNSIC clone post-benchmark snapshot'
snapshot "$GENTLE_ROOT" "$TMP/gentle.after" || no 'Gentle AI clone post-benchmark snapshot'
cmp -s "$TMP/cnsic.before" "$TMP/cnsic.after" && ok 'CNSIC scorer/reference clone remained immutable' || no 'CNSIC scorer/reference clone changed'
cmp -s "$TMP/gentle.before" "$TMP/gentle.after" && ok 'Gentle AI scorer/reference clone remained immutable' || no 'Gentle AI scorer/reference clone changed'

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
