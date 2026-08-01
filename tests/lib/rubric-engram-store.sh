#!/usr/bin/env bash
# Hermetic EngramAdapterV1 test transport. Production maps these fixed verbs to
# MCP mem_search exact-topic -> mem_get_observation and mem_save/mem_update.
set -uo pipefail
LC_ALL=C

rces_bad() { return 1; }
rces_digest() { cksum "$1" | awk '{print $1":"$2}'; }
rces_hex() { xxd -p -c 999999 "$1" | tr -d '\n'; }
rces_unhex() { printf '%s' "$1" | xxd -r -p; }
rces_scalar() { [[ "$1" =~ ^[A-Za-z0-9._:/-]+$ ]]; }
rces_hexok() { [[ "$1" =~ ^([0-9a-f][0-9a-f])+$ ]]; }
rces_digok() { [[ "$1" =~ ^[0-9]+:[0-9]+$ ]]; }
rces_init() { mkdir -p "$1"; : > "$1/.engram-store"; }
rces_mode() { printf '%s\n' "$2" > "$1/mode"; }
rces_seed() {
  local store=$1 topic=$2 source=$3 hex digest
  rces_scalar "$topic" && [[ -f "$source" ]] || return 1
  hex=$(rces_hex "$source"); digest=$(rces_digest "$source")
  printf 'topic=%s\nobservation_id=obs-1\nstore_revision=1\ncontent_hex=%s\ncontent_digest=%s\n' "$topic" "$hex" "$digest" > "$store/current"
}
rces_field() { awk -F= -v key="$2" '$1==key{n++; value=substr($0,length(key)+2)} END{if(n==1&&value!="") print value; else exit 1}' "$1"; }
rces_request() {
  local file=$1; shift
  : > "$file"
  while (($#)); do printf '%s=%s\n' "$1" "$2" >> "$file"; shift 2; done
}
rces_exact() {
  local file=$1; shift; local count want key
  count=$(awk 'NF{n++}END{print n+0}' "$file")
  want=$#
  (( count == want )) || return 1
  for key; do rces_field "$file" "$key" >/dev/null || return 1; done
}
rces_reply() { local out=$1; shift; rces_request "$out" "$@"; }
rces_lookup() {
  local store=$1 req=$2 out=$3 mode topic id rev hex digest
  rces_exact "$req" schema verb request_id project topic || return 1
  [[ $(rces_field "$req" schema) == EngramAdapterV1 && $(rces_field "$req" verb) == lookup-canonical ]] || return 1
  topic=$(rces_field "$req" topic); mode=$(cat "$store/mode" 2>/dev/null || :)
  case "$mode" in duplicate|ambiguous|version-only) rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status conflict topic "$topic" code "$mode"; return;; error) rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status error topic "$topic"; return;; malformed) printf 'not-an-envelope\n' > "$out"; return;; esac
  [[ -f "$store/current" ]] || { rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status absent topic "$topic"; return; }
  [[ $(rces_field "$store/current" topic) == "$topic" ]] || return 1
  if [[ $mode == post-missing ]]; then rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status absent topic "$topic"; return; fi
  id=$(rces_field "$store/current" observation_id); rev=$(rces_field "$store/current" store_revision); hex=$(rces_field "$store/current" content_hex); digest=$(rces_field "$store/current" content_digest)
  [[ $mode == post-mismatch ]] && digest=0:0
  rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status found topic "$topic" observation_id "$id" store_revision "$rev" content_hex "$hex" content_digest "$digest"
}
rces_put() {
  local store=$1 req=$2 out=$3 mode topic presence old='' expected='' rev='' hex digest
  rces_exact "$req" schema verb request_id project topic expected_presence expected_observation_id expected_store_revision expected_content_digest content_hex content_digest || return 1
  [[ $(rces_field "$req" schema) == EngramAdapterV1 && $(rces_field "$req" verb) == compare-put-canonical ]] || return 1
  topic=$(rces_field "$req" topic); presence=$(rces_field "$req" expected_presence); hex=$(rces_field "$req" content_hex); digest=$(rces_field "$req" content_digest)
  [[ $presence == absent || $presence == found ]] && rces_hexok "$hex" && rces_digok "$digest" || return 1
  expected=$(rces_unhex "$hex" | cksum | awk '{print $1":"$2}'); [[ $expected == "$digest" ]] || return 1
  mode=$(cat "$store/mode" 2>/dev/null || :); [[ $mode == stale || $mode == error ]] && { rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status "$([[ $mode == stale ]] && printf conflict || printf error)"; return; }
  [[ -f "$store/current" ]] && old=found || old=absent
  [[ $old == "$presence" ]] || { rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status conflict; return; }
  if [[ $old == found ]]; then
    [[ $(rces_field "$store/current" topic) == "$topic" && $(rces_field "$store/current" observation_id) == $(rces_field "$req" expected_observation_id) && $(rces_field "$store/current" store_revision) == $(rces_field "$req" expected_store_revision) && $(rces_field "$store/current" content_digest) == $(rces_field "$req" expected_content_digest) ]] || { rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status conflict; return; }
    rev=$(( $(rces_field "$store/current" store_revision) + 1 ))
  else
    [[ $(rces_field "$req" expected_observation_id):$(rces_field "$req" expected_store_revision):$(rces_field "$req" expected_content_digest) == none:none:none ]] || return 1
    rev=1
  fi
  [[ $mode == lie-put ]] || printf 'topic=%s\nobservation_id=obs-1\nstore_revision=%s\ncontent_hex=%s\ncontent_digest=%s\n' "$topic" "$rev" "$hex" "$digest" > "$store/current"
  rces_reply "$out" schema EngramAdapterV1 request_id "$(rces_field "$req" request_id)" status written
}
rces_main() {
  [[ $# == 3 && -d $1 && ! -L $1 && -f $1/.engram-store ]] || return 2
  case $(rces_field "$2" verb) in lookup-canonical) rces_lookup "$@";; compare-put-canonical) rces_put "$@";; *) return 1;; esac
}
[[ ${BASH_SOURCE[0]} != "$0" ]] || rces_main "$@"
