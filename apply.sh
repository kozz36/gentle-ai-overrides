#!/usr/bin/env bash
#
# gentle-ai overrides overlay
#
# Re-applies the user's hand-made persona/orchestrator customizations to the
# agent-config files that `gentle-ai sync|upgrade|install` regenerates from the
# templates embedded in its Go binary.
#
# Design: anchor-based, NOT line-number based. Generated files shift between
# gentle-ai versions, so every edit is located by stable structural markers
# (HTML comment markers where gentle-ai emits them, heading boundaries where it
# does not) instead of by offset.
#
# Idempotent: running it twice is a no-op. Never invokes gentle-ai itself.
#
# Usage:
#   ./apply.sh            apply the overlay
#   ./apply.sh --check    report only, write nothing (exit 2 if work is pending)
#
set -uo pipefail

OVERLAY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PERSONA_FILE="$OVERLAY_DIR/persona/persona-block.md"
RUBRIC_FILE="$OVERLAY_DIR/deltas/rubric-tdd.md"
PIMODEL_FILE="$OVERLAY_DIR/deltas/pi-model-agnostic.md"
STATE_JSON="$HOME/.gentle-ai/state.json"
BACKUP_ROOT="$OVERLAY_DIR/backups/$(date +%Y%m%d-%H%M%S)"

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# Exit codes: 0 = clean, 1 = anchor missing (gentle-ai template changed),
#             2 = --check found pending work.
MISSING_ANCHOR=0
PENDING=0
CHANGED=0

# ---------------------------------------------------------------------------
# Host map. One row per (host, artifact).
#   host | surface | path
# surface:
#   persona-marked   persona block delimited by <!-- gentle-ai:persona --> markers
#   persona-headed   persona block with no markers; bounded by "## Rules" .. next <!-- gentle-ai: marker
#   persona-split    claude-code's newer split shape (CLAUDE.md + output-styles); user-managed, never touched
#   rubric-list      markdown surface WITH the MANDATORY numbered list -> rubric is item 4
#   rubric-prose     markdown surface WITHOUT the list (claude-code's condensed workflow)
#                    -> the loose-paragraph shape is the only one that fits
#   rubric-json      opencode.json -> .agent["gentle-orchestrator"].prompt (carries the list)
#   rubric-none      host has no strict-TDD forwarding section; nothing to inject
#   pi-models        pi's sdd-model-assignments block -> host-agnostic `inherit`
#                    (pi routes phases via ~/.pi/gentle-ai/models.json; the Claude
#                     aliases gentle-ai renders there are unresolvable). pi ONLY.
# ---------------------------------------------------------------------------
host_rows() {
  cat <<'ROWS'
claude-code|persona-split|.claude/CLAUDE.md
claude-code|persona-split|.claude/output-styles/neutral.md
claude-code|rubric-prose|.claude/skills/_shared/sdd-orchestrator-workflow.md
pi|persona-marked|.pi/agent/APPEND_SYSTEM.md
pi|rubric-list|.pi/agent/APPEND_SYSTEM.md
pi|pi-models|.pi/agent/APPEND_SYSTEM.md
opencode|persona-marked|.config/opencode/AGENTS.md
opencode|rubric-json|.config/opencode/opencode.json
codex|persona-headed|.codex/AGENTS.md
codex|rubric-none|.codex/AGENTS.md
cursor|persona-headed|.cursor/rules/gentle-ai.mdc
cursor|rubric-list|.cursor/rules/gentle-ai.mdc
vscode-copilot|persona-headed|.config/Code/User/prompts/gentle-ai.instructions.md
vscode-copilot|rubric-list|.config/Code/User/prompts/gentle-ai.instructions.md
antigravity|persona-marked|.gemini/GEMINI.md
antigravity|rubric-list|.gemini/GEMINI.md
ROWS
}

# Hosts gentle-ai currently has installed. Falls back to the full static list.
installed_hosts() {
  if [ -r "$STATE_JSON" ] && command -v jq >/dev/null 2>&1; then
    jq -r '.installed_agents[]?' "$STATE_JSON" 2>/dev/null && return 0
  fi
  printf '%s\n' claude-code opencode pi codex cursor vscode-copilot antigravity
}

report() { printf '  %-14s %-14s %s\n' "$1" "$2" "$3"; }

# Snapshot a file before the first write of THIS run. Some hosts carry two
# surfaces in one file (pi/cursor/copilot/antigravity hold both the persona and
# the SDD orchestrator), so guard against the second edit overwriting the
# pre-run snapshot taken by the first.
backup() {
  local f="$1" rel dest
  rel="${f#"$HOME"/}"
  dest="$BACKUP_ROOT/$rel"
  [ -e "$dest" ] && return 0
  mkdir -p "$(dirname -- "$dest")"
  cp -p -- "$f" "$dest"
}

# ---------------------------------------------------------------------------
# Persona: replace the whole persona block with the canonical one.
#
# The persona body is byte-identical across every old-shape host, so the
# overlay ships ONE canonical block and stamps it into each of them. The block
# is located by markers when gentle-ai emits them, otherwise by heading range.
# ---------------------------------------------------------------------------
persona_apply() {
  local file="$1" mode="$2" tmp start end
  tmp="$(mktemp)"

  if [ "$mode" = persona-marked ]; then
    start="$(grep -n '^<!-- gentle-ai:persona -->$' "$file" | head -1 | cut -d: -f1)"
    end="$(grep -n '^<!-- /gentle-ai:persona -->$' "$file" | head -1 | cut -d: -f1)"
    if [ -z "$start" ] || [ -z "$end" ]; then rm -f "$tmp"; return 3; fi
    # Body sits strictly between the markers.
    start=$((start + 1)); end=$((end - 1))
  else
    # persona-headed: "## Rules" .. line before the first gentle-ai section marker.
    start="$(grep -n '^## Rules$' "$file" | head -1 | cut -d: -f1)"
    end="$(grep -n '^<!-- gentle-ai:' "$file" | head -1 | cut -d: -f1)"
    if [ -z "$start" ] || [ -z "$end" ] || [ "$end" -le "$start" ]; then rm -f "$tmp"; return 3; fi
    end=$((end - 1))
  fi

  # Sanity: the region we are about to overwrite must actually look like the
  # persona (all 9 sections). Guards against a template reshuffle silently
  # eating unrelated content.
  local sections
  sections="$(sed -n "${start},${end}p" "$file" | grep -c '^## ')"
  if [ "$sections" -ne 9 ]; then rm -f "$tmp"; return 3; fi

  # Already applied? Compare the live region against the canonical block,
  # ignoring blank-line padding.
  if diff -q <(sed -n "${start},${end}p" "$file" | grep -v '^[[:space:]]*$') \
             <(grep -v '^[[:space:]]*$' "$PERSONA_FILE") >/dev/null 2>&1; then
    rm -f "$tmp"; return 1
  fi

  {
    [ "$start" -gt 1 ] && sed -n "1,$((start - 1))p" "$file"
    cat "$PERSONA_FILE"
    echo ""
    sed -n "$((end + 1)),\$p" "$file"
  } > "$tmp"

  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f "$tmp"; return 0; fi
  backup "$file"
  cat "$tmp" > "$file"   # preserve inode/permissions
  rm -f "$tmp"
  return 0
}

# ---------------------------------------------------------------------------
# RUBRIC TDD.
#
# The rubric condition is item 4 of the MANDATORY numbered list in the
# strict-TDD forwarding section. An earlier version of this overlay appended it
# as a LOOSE PARAGRAPH trailing the list -- semantically weaker, because a
# paragraph after the list reads as optional commentary while item 4 of a list
# headed "(MANDATORY)" inherits that force. This script therefore MIGRATES the
# loose form to the numbered form wherever it finds it.
#
# Hosts carrying the numbered list  -> shape:list-item  (item 4, appended to the list)
# claude-code's condensed workflow  -> shape:prose      (no list exists; paragraph is
#                                                        the only shape that fits)
#
# The transforms below are PURE and IDEMPOTENT: each one takes the current
# content on stdin and emits the desired content on stdout. "Already applied" is
# then simply output == input -- there is no separate, hand-maintained
# already-applied predicate that could drift from what the transform does.
# ---------------------------------------------------------------------------

[ -r "$PERSONA_FILE" ]  || { echo "FATAL: missing $PERSONA_FILE" >&2; exit 1; }
[ -r "$RUBRIC_FILE" ]   || { echo "FATAL: missing $RUBRIC_FILE" >&2; exit 1; }
[ -r "$PIMODEL_FILE" ]  || { echo "FATAL: missing $PIMODEL_FILE" >&2; exit 1; }

# Pull one <!-- shape:NAME --> ... <!-- /shape:NAME --> block out of a delta file.
extract_shape_from() {
  awk -v tag_open="<!-- shape:$2 -->" -v tag_close="<!-- /shape:$2 -->" '
    $0 == tag_close { inside = 0 }
    inside          { print }
    $0 == tag_open  { inside = 1 }
  ' "$1"
}

extract_shape() { extract_shape_from "$RUBRIC_FILE" "$1"; }

RUBRIC_ITEM4="$(extract_shape list-item)"
RUBRIC_PROSE="$(extract_shape prose)"
CACHE_NEW="$(extract_shape cache-sentence)"

[ -n "$RUBRIC_ITEM4" ] && [ -n "$RUBRIC_PROSE" ] && [ -n "$CACHE_NEW" ] || {
  echo "FATAL: $RUBRIC_FILE is missing one of the shape blocks" >&2; exit 1; }

# First line of item 4 -- the marker used to detect "the numbered form is here".
RUBRIC_ITEM4_HEAD="$(printf '%s\n' "$RUBRIC_ITEM4" | head -1)"

# Anchor: last item of the numbered list. Item 4 is appended directly after it.
# Prefix match -- hosts differ in the tail ("(sub-agent uses Standard Mode)." vs
# "(use Standard Mode)." vs nothing at all in opencode.json).
ANCHOR_ITEM3='3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'

# Anchor: claude-code's condensed prose form, which has no numbered list.
ANCHOR_PROSE='When launching `sdd-apply` or `sdd-verify`, search for testing capabilities'

# The weaker caching sentence some hosts carry. Upgraded in place where present,
# so the rubric is explicitly part of what gets cached. Never invented where absent.
CACHE_OLD='The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.'

# Transform for hosts WITH the numbered list. Idempotent:
#   - inserts item 4 after item 3 only if item 4 is not already there
#   - drops the legacy loose paragraph (and the blank line it leaves behind)
#   - upgrades the caching sentence only where the weak one exists
# Exits 1 if the list anchor is gone (gentle-ai reshaped the template).
rubric_transform_list() {
  ITEM4="$RUBRIC_ITEM4" ITEM4_HEAD="$RUBRIC_ITEM4_HEAD" PROSE="$RUBRIC_PROSE" \
  A3="$ANCHOR_ITEM3" C_OLD="$CACHE_OLD" C_NEW="$CACHE_NEW" \
  awk '
    BEGIN {
      item4 = ENVIRON["ITEM4"]; head = ENVIRON["ITEM4_HEAD"]; prose = ENVIRON["PROSE"]
      a3 = ENVIRON["A3"];       c_old = ENVIRON["C_OLD"];     c_new = ENVIRON["C_NEW"]
    }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (!anchor && index(line[i], a3) == 1)   anchor = i    # end of the numbered list
        if (!have4  && index(line[i], head) == 1) have4  = i    # item 4 already present
        if (!loose  && line[i] == prose)          loose  = i    # legacy loose paragraph
      }
      if (!anchor) exit 1                                       # template changed -> refuse

      if (loose) {
        drop[loose] = 1
        # The paragraph sits blank-line-padded. Removing it would leave two
        # consecutive blanks, so swallow the trailing one.
        if (line[loose - 1] ~ /^[ \t]*$/ && line[loose + 1] ~ /^[ \t]*$/) drop[loose + 1] = 1
      }

      for (i = 1; i <= n; i++) {
        if (drop[i]) continue
        print (line[i] == c_old) ? c_new : line[i]
        if (i == anchor && !have4) print item4                  # item 4 joins the list
      }
      exit 0
    }
  '
}

# Transform for claude-code's condensed workflow: no numbered list exists there, so
# the loose-paragraph form is the only shape that fits. Left in prose form.
rubric_transform_prose() {
  PROSE="$RUBRIC_PROSE" AP="$ANCHOR_PROSE" awk '
    BEGIN { prose = ENVIRON["PROSE"]; ap = ENVIRON["AP"] }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (!anchor && index(line[i], ap) == 1) anchor = i
        if (!have   && line[i] == prose)        have   = i
      }
      if (!anchor) exit 1
      for (i = 1; i <= n; i++) {
        print line[i]
        if (i == anchor && !have) { print ""; print prose }
      }
      exit 0
    }
  '
}

# ---------------------------------------------------------------------------
# pi model-agnostic assignments.
#
# gentle-ai renders the SDD model-assignments table with CLAUDE aliases (opus /
# sonnet / haiku) into every host, including pi. pi cannot resolve those aliases:
# its phase routing lives in ~/.pi/gentle-ai/models.json, which maps every phase
# to a concrete provider model. The rendered table therefore tells pi's
# orchestrator to pass aliases that do not exist in pi, contradicting pi's own
# authoritative routing.
#
# This delta rewrites pi's block so the Default Model column reads `inherit` and
# the prose defers to models.json. Applied to pi ONLY -- claude-code's table is
# rendered from state.json `claude_phase_assignments` and is correct there.
# ---------------------------------------------------------------------------
PI_BLOCK="$(extract_shape_from "$PIMODEL_FILE" block)"
PI_SKILLS="$(extract_shape_from "$PIMODEL_FILE" skills-sentence)"

[ -n "$PI_BLOCK" ] && [ -n "$PI_SKILLS" ] || {
  echo "FATAL: $PIMODEL_FILE is missing one of the shape blocks" >&2; exit 1; }

PI_MARK_OPEN='<!-- gentle-ai:sdd-model-assignments -->'
PI_MARK_CLOSE='<!-- /gentle-ai:sdd-model-assignments -->'
# The one sentence outside the block that tells the orchestrator to cache and pass
# `phase -> alias`. Matched by prefix; replaced wholesale.
PI_SKILLS_ANCHOR='The orchestrator resolves skills from the registry ONCE'

# Pure + idempotent: replaces the marker-delimited body and the alias sentence.
# Exits 1 if either marker is gone.
pimodel_transform() {
  BLOCK="$PI_BLOCK" SKILLS="$PI_SKILLS" \
  M_OPEN="$PI_MARK_OPEN" M_CLOSE="$PI_MARK_CLOSE" S_ANCHOR="$PI_SKILLS_ANCHOR" \
  awk '
    BEGIN {
      block = ENVIRON["BLOCK"]; skills = ENVIRON["SKILLS"]
      m_open = ENVIRON["M_OPEN"]; m_close = ENVIRON["M_CLOSE"]; s_anchor = ENVIRON["S_ANCHOR"]
    }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (!o && line[i] == m_open)  o = i
        if (o && !c && line[i] == m_close) c = i
      }
      if (!o || !c) exit 1                                   # template changed -> refuse

      for (i = 1; i <= n; i++) {
        if (i > o && i < c) continue                         # drop the old body
        if (i == c) { print block; print "" }                # canonical body, then the marker
        print (index(line[i], s_anchor) == 1) ? skills : line[i]
      }
      exit 0
    }
  '
}

pimodel_apply() {
  local file="$1" tmp
  tmp="$(mktemp)"
  if ! pimodel_transform < "$file" > "$tmp"; then rm -f "$tmp"; return 3; fi
  if cmp -s "$tmp" "$file"; then rm -f "$tmp"; return 1; fi   # output == input
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f "$tmp"; return 0; fi
  backup "$file"
  cat "$tmp" > "$file"   # preserve inode/permissions
  rm -f "$tmp"
  return 0
}

# rc 0 = written/pending, 1 = already applied, 3 = anchor gone.
rubric_apply_md() {
  local file="$1" shape="$2" tmp
  tmp="$(mktemp)"
  if ! "rubric_transform_$shape" < "$file" > "$tmp"; then rm -f "$tmp"; return 3; fi
  if cmp -s "$tmp" "$file"; then rm -f "$tmp"; return 1; fi   # output == input
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f "$tmp"; return 0; fi
  backup "$file"
  cat "$tmp" > "$file"   # preserve inode/permissions
  rm -f "$tmp"
  return 0
}

# opencode.json is a 130KB config; the orchestrator prompt is one JSON string
# value. Round-trip it through jq so the surrounding JSON is never hand-edited.
rubric_apply_json() {
  local file="$1" tmp_cur tmp_new tmp_json
  command -v jq >/dev/null 2>&1 || return 3

  tmp_cur="$(mktemp)"; tmp_new="$(mktemp)"; tmp_json="$(mktemp)"
  jq -r '.agent["gentle-orchestrator"].prompt // empty' "$file" > "$tmp_cur"
  if [ ! -s "$tmp_cur" ]; then rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 3; fi

  if ! rubric_transform_list < "$tmp_cur" > "$tmp_new"; then
    rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi
  if cmp -s "$tmp_new" "$tmp_cur"; then                       # already applied
    rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 1
  fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 0; fi

  if ! jq --rawfile p "$tmp_new" '.agent["gentle-orchestrator"].prompt = ($p | rtrimstr("\n"))' \
        "$file" > "$tmp_json"; then
    rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi
  # Never install a JSON file we cannot parse back.
  if ! jq empty "$tmp_json" >/dev/null 2>&1; then
    rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi
  backup "$file"
  cat "$tmp_json" > "$file"
  jq empty "$file" >/dev/null 2>&1 || { rm -f "$tmp_cur" "$tmp_new" "$tmp_json"; return 3; }
  rm -f "$tmp_cur" "$tmp_new" "$tmp_json"
  return 0
}

# ---------------------------------------------------------------------------
# Drive
# ---------------------------------------------------------------------------
echo "gentle-ai overrides overlay"
[ "$CHECK_ONLY" -eq 1 ] && echo "(--check: reporting only, nothing will be written)"
echo

HOSTS="$(installed_hosts)"

for host in $HOSTS; do
  echo "$host"
  matched=0
  while IFS='|' read -r h surface rel; do
    [ "$h" = "$host" ] || continue
    matched=1
    file="$HOME/$rel"
    short="${rel}"

    if [ ! -f "$file" ]; then
      report "MISSING-FILE" "$surface" "$short"
      MISSING_ANCHOR=1
      continue
    fi

    case "$surface" in
      persona-split)
        # claude-code's newer split persona shape. The user maintains these by
        # hand and they are already correct; the overlay deliberately does not
        # rewrite them.
        report "already-applied" "persona" "$short (user-managed split shape)"
        ;;
      persona-marked|persona-headed)
        persona_apply "$file" "$surface"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "persona" "$short"; PENDING=1
             else report "applied" "persona" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "persona" "$short" ;;
          *) report "ANCHOR-NOT-FOUND" "persona" "$short"; MISSING_ANCHOR=1 ;;
        esac
        ;;
      rubric-list|rubric-prose)
        rubric_apply_md "$file" "${surface#rubric-}"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "rubric-tdd" "$short"; PENDING=1
             else report "applied" "rubric-tdd" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "rubric-tdd" "$short" ;;
          *) report "ANCHOR-NOT-FOUND" "rubric-tdd" "$short"; MISSING_ANCHOR=1 ;;
        esac
        ;;
      rubric-json)
        rubric_apply_json "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "rubric-tdd" "$short"; PENDING=1
             else report "applied" "rubric-tdd" "$short (jq)"; CHANGED=1; fi ;;
          1) report "already-applied" "rubric-tdd" "$short (jq)" ;;
          *) report "ANCHOR-NOT-FOUND" "rubric-tdd" "$short (jq)"; MISSING_ANCHOR=1 ;;
        esac
        ;;
      rubric-none)
        # This host's template has no strict-TDD forwarding section at all.
        report "n/a" "rubric-tdd" "$short (no strict-TDD section in template)"
        ;;
      pi-models)
        pimodel_apply "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "pi-models" "$short"; PENDING=1
             else report "applied" "pi-models" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "pi-models" "$short" ;;
          *) report "ANCHOR-NOT-FOUND" "pi-models" "$short"; MISSING_ANCHOR=1 ;;
        esac
        ;;
    esac
  done <<EOF
$(host_rows)
EOF
  [ "$matched" -eq 1 ] || report "unknown-host" "-" "no artifacts mapped"
  echo
done

if [ "$MISSING_ANCHOR" -eq 1 ]; then
  echo "FAIL: an anchor was not found. gentle-ai most likely changed its template;"
  echo "      review persona/persona-block.md and deltas/rubric-tdd.md before re-running."
  exit 1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  [ "$PENDING" -eq 1 ] && { echo "Pending: overlay is NOT fully applied. Run ./apply.sh"; exit 2; }
  echo "OK: overlay fully applied, nothing to do."
  exit 0
fi

if [ "$CHANGED" -eq 1 ]; then
  echo "OK: overlay applied. Backups: $BACKUP_ROOT"
else
  echo "OK: nothing to do, overlay already applied."
fi
exit 0
