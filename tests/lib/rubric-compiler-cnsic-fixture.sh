#!/usr/bin/env bash
# Shared hermetic CNSIC fixture: Unit1A-valid candidate -> records -> integrate -> confirmation.
rccf_load_unit1a() {
  export FIXTURES="$1/tests/fixtures/rubric-compiler/structure" TMP_ROOT="$2"
  # shellcheck disable=SC1090
  source <(awk 'NR >= 6 && NR <= 29 {print}' "$1/tests/rubric-compiler-structure.sh")
}
rccf_get() { tr -d '\n' < "$1"; }
rccf_sync_facts() {
  local b=$1 d p
  put "$b/facts/declaration/fingerprint" "$(fp "$b/facts/declaration")"
  put "$b/facts/tool/fingerprint" "$(fp "$b/facts/tool")"
  d="$(rccf_get "$b/facts/declaration/id")"; p="$(rccf_get "$b/facts/tool/id")"
  put "$b/rows/source/fact-fingerprint" "$(fps "$b" "$d" "$p")"
  put "$b/rows/default/fact-fingerprint" "$(fps "$b" "$d")"
  put "$b/reinit/source/prior-fingerprint" "$(fps "$b" "$d")"
}
rccf_cnsic_candidate() {
  local b=$1 r
  bundle "$b"; r="$b/repository"; cp -a "$ROOT/tests/fixtures/rubric-compiler/adapters/." "$r/"
  put "$b/observations/file/locator" AGENTS.md; put "$b/observations/file/checksum" "$(cksum "$r/AGENTS.md" | awk '{print $1 " " $2}')"
  put "$b/observations/graph/channel" file; put "$b/observations/graph/locator" requirements.txt; put "$b/observations/graph/checksum" "$(cksum "$r/requirements.txt" | awk '{print $1 " " $2}')"
  put "$b/facts/declaration/adapter" cnsic-python-v1; put "$b/facts/declaration/evidence-kind" command-declaration
  put "$b/facts/tool/adapter" cnsic-python-v1; put "$b/facts/tool/evidence-kind" tool-proof; list "$b/facts/tool/observation-refs" "$(rccf_get "$b/observations/graph/id")"
  put "$b/bindings/unit/context/executable" python; put "$b/bindings/unit/context/workdir" .; put "$b/bindings/unit/method" unit; put "$b/bindings/unit/scope" path-prefix:tests/unit; put "$b/bindings/unit/signature-coverage" tests/unit
  list "$b/bindings/unit/context/argv" -m pytest tests/unit/ -n auto -q; list "$b/bindings/unit/context/env"; rccf_sync_facts "$b"
}
rccf_cid() {
  local d=$1 t=$2 k
  (cd "$d" && find . -type f ! -name id ! -name identity ! -name fingerprint ! -name attestation-id -print | LC_ALL=C sort | while IFS= read -r f; do case "$t:$f" in binding:./attestation-refs/*) continue;; esac; printf '%s=' "$f"; cat "$f"; done) > "$d/identity"
  k="$(rccf_get "$d/kind")"; put "$d/id" "v1:$k:$(cksum "$d/identity" | awk '{print $1":"$2}')"
}
rccf_rebuild_confirmation() {
  local b=$1 d f old new i; local map="$b/.row-map"
  : > "$map"
  for d in "$b"/rows/*; do old="$(rccf_get "$d/id")"; rccf_cid "$d" row; printf '%s %s\n' "$old" "$(rccf_get "$d/id")" >> "$map"; done
  for d in "$b"/questions/* "$b"/reinit/*; do old="$(rccf_get "$d/row-ref")"; new="$(awk -v x="$old" '$1==x{print $2}' "$map")"; [ -n "$new" ] || return 1; put "$d/row-ref" "$new"; [ -e "$d/kind" ] && rccf_cid "$d" question; done
  rm -f "$map"; rm -rf "$b/record-order"; mkdir "$b/record-order"; i=0
  for d in "$b"/{observations,facts,attestations,bindings,rows,questions}/*; do rccf_get "$d/id"; printf '\n'; done | LC_ALL=C sort | while IFS= read -r new; do put "$b/record-order/$(printf '%03d' "$i")" "$new"; i=$((i + 1)); done
}
rccf_confirm() {
  local b=$1 d
  for d in "$b"/rows/*; do put "$d/state" confirmed; put "$d/confirmation-answer" yes; put "$d/confirmer" fixture; done
  for d in "$b"/questions/*; do put "$d/state" answered; done
  rccf_rebuild_confirmation "$b"
}
