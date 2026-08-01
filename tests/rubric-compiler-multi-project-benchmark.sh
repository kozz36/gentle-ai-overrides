#!/usr/bin/env bash
# Read-only scorer for fresh blind predictions; all temporary state stays in TMP.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/tests/fixtures/rubric-compiler/multi-project"
TASKS="$DIR/tasks.tsv"
LABELS="$DIR/labels.tsv"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/rubric-compiler-multi-project.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT

die() { printf 'error: %s\n' "$*" >&2; exit 2; }
digest() { sha256sum "$1" | awk '{print $1}'; }
rows() { awk 'BEGIN { FS="\t" } $0 !~ /^#/ && NR > 0 { print }' "$1"; }
ratio() { awk -v n="$1" -v d="$2" 'BEGIN { if (!d) print "N/A (0/0)"; else printf "%.2f%% (%d/%d)\n", 100*n/d, n, d }'; }
bindings() { [ -n "$1" ] && printf '%s\n' "$1" | tr ',' '\n' | LC_ALL=C sort -u; }
project_key() { [ "$1" = cnsic ] && printf cnsic || printf gentle; }

valid_mode() {
  case "$1" in strict-tdd|standard|skip|not-applicable|ambiguous|disputed) return 0;; esac
  return 1
}

valid_evidence() {
  local project="$1" values="$2" value seen="" old_ifs
  [ -z "$values" ] && return 0
  case "$values" in ,*|*,|*,,*) return 1;; esac
  old_ifs="$IFS"; IFS=,
  for value in $values; do
    IFS="$old_ifs"
    case "$project:$value" in
      cnsic:backend-unit|cnsic:backend-integration|cnsic:frontend-unit|cnsic:frontend-lint|cnsic:frontend-build|cnsic:frontend-e2e|cnsic:container-build|gentle-ai:go-unit|gentle-ai:go-build|gentle-ai:go-e2e-docker|gentle-ai:go-format-ci|gentle-ai:go-vet-ci|gentle-ai:organic-e2e-ci|gentle-ai:windows-release-blockers-ci|gentle-ai:darwin-release-blockers-ci) ;;
      *) return 1 ;;
    esac
    case ",$seen," in *",$value,"*) return 1;; esac
    seen="${seen:+$seen,}$value"
    IFS=,
  done
  IFS="$old_ifs"
}

validate_tasks() {
  awk -F '\t' '
    $0 ~ /^#/ { next } !header++ { ok = ($0 == "task_id\tproject\ttask_description\tsource_reference\tcommit\tdate\tpath_category"); next }
    NF != 7 || !$1 || !$2 || !$3 || !$4 || !$5 || !$6 || !$7 || seen[$1]++ { exit 1 }
    $1 !~ /^(cnsic|gentle)-h00[1-8]$/ || $5 !~ /^[0-9a-f]{40}$/ || $6 !~ /^2026-07-(2[5-9]|3[0-1])$/ { exit 1 }
    $2 == "cnsic" && $4 != "cnsic-read-only-history" { exit 1 }
    $2 == "gentle-ai" && $4 != "gentle-ai-public-history" { exit 1 }
    $2 != "cnsic" && $2 != "gentle-ai" { exit 1 }
    { count[$2]++ }
    END { exit !(ok && count["cnsic"] == 8 && count["gentle-ai"] == 8) }
  ' "$TASKS" || die 'invalid task schema, provenance, chronology, IDs, or project balance'
}

validate_labels() {
  local bound
  bound="$(awk -F ': ' '/^# task_fixture_sha256: / { print $2 }' "$LABELS")"
  [ "$bound" = "$(digest "$TASKS")" ] || die 'label task-fixture digest mismatch'
  awk -F '\t' '
    $0 ~ /^#/ { next } !header++ { ok = ($0 == "task_id\texpected_mode\texpected_evidence\tlabel_status\tlabel_provenance\tlabel_revision"); next }
    NF != 6 || !$1 || !$2 || !$4 || !$5 || !$6 || seen[$1]++ { exit 1 }
    $2 !~ /^(strict-tdd|standard|skip|not-applicable|ambiguous|disputed)$/ || $4 != "confirmed" || $5 != "maintainer-approved" || $6 !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ { exit 1 }
    END { exit !(ok && NR == 20) }
  ' "$LABELS" || die 'invalid scorer-only label schema or authority'
  join -t "$(printf '\t')" -j 1 <(rows "$TASKS" | tail -n +2 | cut -f1 | LC_ALL=C sort) <(rows "$LABELS" | tail -n +2 | cut -f1 | LC_ALL=C sort) | awk 'END { exit NR != 16 }' || die 'task and label IDs are not one-to-one'
  while IFS="$(printf '\t')" read -r id project _ _ _ _ _; do
    evidence="$(awk -F '\t' -v id="$id" '$1 == id { print $3 }' "$LABELS")"
    valid_evidence "$project" "$evidence" || die "invalid label evidence for $id"
  done < <(rows "$TASKS" | tail -n +2)
}

validate_predictions() {
  local file="$1" task_digest producer_lower
  [ -f "$file" ] || die 'prediction file is not readable'
  task_digest="$(digest "$TASKS")"
  awk -F '\t' '
    $0 ~ /^#/ { next } !header++ { ok = ($0 == "task_id\tpredicted_mode\tpredicted_evidence\ttask_fixture_sha256\tproducer_input"); next }
    NF != 5 || !$1 || !$4 || !$5 || seen[$1]++ { exit 1 }
    $2 == "" && $3 != "" { exit 1 }
    END { exit !ok }
  ' "$file" || die 'invalid prediction schema or duplicate/partial abstention'
  while IFS='|' read -r id mode evidence source_digest producer_input; do
    [ "$source_digest" = "$task_digest" ] || die "source digest mismatch for $id"
    producer_lower="$(printf '%s' "$producer_input" | LC_ALL=C tr '[:upper:]' '[:lower:]')"
    case "$producer_lower" in *oracle*|*label*|*semantic*|*benchmark*|*candidate*) die "unsafe producer input metadata for $id";; esac
    [ -z "$mode" ] || valid_mode "$mode" || die "invalid mode for $id"
    project="$(awk -F '\t' -v id="$id" '$1 == id { print $2 }' "$TASKS")"
    [ -n "$project" ] || die "unknown task ID $id"
    valid_evidence "$project" "$evidence" || die "invalid evidence for $id"
  done < <(rows "$file" | tail -n +2 | tr '\t' '|')
  join -t "$(printf '\t')" -j 1 <(rows "$file" | tail -n +2 | cut -f1 | LC_ALL=C sort) <(rows "$TASKS" | tail -n +2 | cut -f1 | LC_ALL=C sort) | awk 'END { exit NR != 16 }' || die 'prediction IDs do not exactly cover tasks'
}

add() { eval "$1=\$((${!1} + $2))"; }
value() { eval "printf '%s' \"\${$1}\""; }

score() {
  local file="$1" id project mode evidence expected expected_evidence status key predicted pmatch ematch tp fp fn
  for key in cnsic gentle pooled; do
    for metric in eligible abstain mode_tp mode_pred exact evidence_tp evidence_fp evidence_fn evidence_pred overlap; do eval "${key}_${metric}=0"; done
  done
  while IFS='|' read -r id expected expected_evidence status _ _; do
    IFS='|' read -r _ project _ _ _ _ _ < <(awk -F '\t' -v id="$id" '$1 == id { print }' "$TASKS" | tr '\t' '|')
    IFS='|' read -r _ mode evidence _ _ < <(awk -F '\t' -v id="$id" '$1 == id { print }' "$file" | tr '\t' '|')
    case "$expected" in ambiguous|disputed|not-applicable) continue;; esac
    [ "$status" = confirmed ] || continue
    key="$(project_key "$project")"
    for key in "$key" pooled; do
      add "${key}_eligible" 1
      [ -z "$mode$evidence" ] && add "${key}_abstain" 1
      [ -n "$mode" ] && add "${key}_mode_pred" 1
      [ "$mode" = "$expected" ] && { add "${key}_mode_tp" 1; pmatch=1; } || pmatch=0
      bindings "$expected_evidence" > "$TMP/expected"; bindings "$evidence" > "$TMP/predicted"
      tp="$(comm -12 "$TMP/expected" "$TMP/predicted" | wc -l | tr -d ' ')"
      fp="$(comm -23 "$TMP/predicted" "$TMP/expected" | wc -l | tr -d ' ')"
      fn="$(comm -23 "$TMP/expected" "$TMP/predicted" | wc -l | tr -d ' ')"
      predicted="$(wc -l < "$TMP/predicted" | tr -d ' ')"
      [ "$tp" -gt 0 ] && add "${key}_overlap" 1
      add "${key}_evidence_tp" "$tp"; add "${key}_evidence_fp" "$fp"; add "${key}_evidence_fn" "$fn"; add "${key}_evidence_pred" "$predicted"
      cmp -s "$TMP/expected" "$TMP/predicted" && ematch=1 || ematch=0
      [ "$pmatch:$ematch" = 1:1 ] && add "${key}_exact" 1
    done
  done < <(rows "$LABELS" | tail -n +2 | tr '\t' '|')
  for key in cnsic gentle pooled; do
    mode_tp="$(value "${key}_mode_tp")"
    mode_pred="$(value "${key}_mode_pred")"
    eligible="$(value "${key}_eligible")"
    evidence_tp="$(value "${key}_evidence_tp")"
    evidence_fp="$(value "${key}_evidence_fp")"
    evidence_fn="$(value "${key}_evidence_fn")"
    evidence_pred="$(value "${key}_evidence_pred")"
    printf 'project: %s\n' "$key"
    printf '  mode precision: %s\n' "$(ratio "$mode_tp" "$mode_pred")"
    printf '  mode recall: %s\n' "$(ratio "$mode_tp" "$eligible")"
    printf '  evidence precision: %s\n' "$(ratio "$evidence_tp" "$((evidence_tp + evidence_fp))")"
    printf '  evidence recall: %s\n' "$(ratio "$evidence_tp" "$((evidence_tp + evidence_fn))")"
    printf '  exact task match: %s\n' "$(ratio "$(value "${key}_exact")" "$eligible")"
    printf '  unsupported-evidence FP rate: %s\n' "$(ratio "$evidence_fp" "$evidence_pred")"
    printf '  abstention rate: %s\n' "$(ratio "$(value "${key}_abstain")" "$eligible")"
    printf '  evidence-overlap tasks: %s\n' "$(value "${key}_overlap")"
  done
  printf 'macro-by-class: N/A (insufficient defensible class support)\n'
}

self_test() {
  local predictions="$TMP/self-test-predictions.tsv" output="$TMP/self-test-output" header
  [ "$(ratio 2 3)" = '66.67% (2/3)' ] || die 'formula self-test TP/FP precision failed'
  [ "$(ratio 2 5)" = '40.00% (2/5)' ] || die 'formula self-test TP/FN recall failed'
  [ "$(ratio 0 0)" = 'N/A (0/0)' ] || die 'formula self-test zero-division handling failed'
  {
    printf '%s\n' '# schema: rubric-compiler-multi-project-predictions/v1'
    printf '%s\n' $'task_id\tpredicted_mode\tpredicted_evidence\ttask_fixture_sha256\tproducer_input'
    rows "$TASKS" | tail -n +2 | awk -F '\t' -v source_digest="$(digest "$TASKS")" '{ print $1 "\tstandard\t\t" source_digest "\tblind-task-fixture" }'
  } > "$predictions"
  validate_predictions "$predictions"
  score "$predictions" > "$output"
  grep -Fq 'mode precision: 14.29% (2/14)' "$output" || die 'scorer self-test mode TP/FP outcome failed'
  grep -Fq 'evidence recall: 0.00% (0/25)' "$output" || die 'scorer self-test evidence FN outcome failed'
  grep -Fq 'unsupported-evidence FP rate: N/A (0/0)' "$output" || die 'scorer self-test zero prediction outcome failed'
  for case_name in trailing leading consecutive; do
    case "$case_name" in
      trailing) evidence='backend-unit,' ;;
      leading) evidence=',backend-unit' ;;
      consecutive) evidence='backend-unit,,backend-integration' ;;
    esac
    rows "$TASKS" | tail -n +2 | awk -F '\t' -v evidence="$evidence" -v source_digest="$(digest "$TASKS")" 'BEGIN { print "task_id\tpredicted_mode\tpredicted_evidence\ttask_fixture_sha256\tproducer_input" } { value = ($1 == "cnsic-h001" ? evidence : ""); print $1 "\tstandard\t" value "\t" source_digest "\tblind-task-fixture" }' > "$TMP/$case_name.tsv"
    if bash "$0" --predictions "$TMP/$case_name.tsv" >/dev/null 2>&1; then die "scorer self-test accepted $case_name empty evidence item"; fi
  done
  rows "$TASKS" | tail -n +2 | awk -F '\t' -v source_digest="$(digest "$TASKS")" 'BEGIN { print "task_id\tpredicted_mode\tpredicted_evidence\ttask_fixture_sha256\tproducer_input" } { input = ($1 == "cnsic-h001" ? "ORACLE" : "blind-task-fixture"); print $1 "\tstandard\t\t" source_digest "\t" input }' > "$TMP/uppercase-oracle.tsv"
  if bash "$0" --predictions "$TMP/uppercase-oracle.tsv" >/dev/null 2>&1; then die 'scorer self-test accepted uppercase oracle metadata'; fi
  header="$(awk 'NR == 1 { print; exit }' "$DIR/producer-cnsic-v1.tsv")"
  [ "$header" = "$(awk 'NR == 1 { print; exit }' "$DIR/producer-gentle-v1.tsv")" ] || die 'producer headers differ'
  awk 'FNR == 1 { if (NR == 1) print; next } { print }' "$DIR/producer-cnsic-v1.tsv" "$DIR/producer-gentle-v1.tsv" > "$TMP/producer-union.tsv"
  cmp -s "$TMP/producer-union.tsv" "$DIR/predictions-v1.tsv" || die 'combined predictions drift from producer outputs'
  printf 'self-test: formulas, input rejection, and producer union integrity passed\n'
}

PREDICTIONS=""
SELF_TEST=0
case "${1:-}" in
  '') ;;
  --self-test) SELF_TEST=1 ;;
  --predictions) [ $# -eq 2 ] || die 'usage: --predictions FILE'; PREDICTIONS="$2" ;;
  *) die 'usage: [--self-test] [--predictions FILE]' ;;
esac
validate_tasks
validate_labels
[ "$SELF_TEST" -eq 1 ] && self_test
if [ -z "$PREDICTIONS" ]; then
  printf 'status: awaiting-blind-predictions\n'
else
  validate_predictions "$PREDICTIONS"
  score "$PREDICTIONS"
fi
