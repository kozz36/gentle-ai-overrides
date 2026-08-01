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
PERSONA_RULES_FILE="$OVERLAY_DIR/persona/claude-split-rules.md"
PERSONA_EXPERTISE_FILE="$OVERLAY_DIR/persona/claude-split-expertise.md"
PERSONA_NEUTRAL_FILE="$OVERLAY_DIR/persona/neutral-style.md"
RUBRIC_FILE="$OVERLAY_DIR/deltas/rubric-tdd.md"
PIMODEL_FILE="$OVERLAY_DIR/deltas/pi-model-agnostic.md"
OPENCODE_ENGRAM_FILE="$OVERLAY_DIR/deltas/opencode-engram-idempotent.md"
INIT_RUBRIC_FILE="${INIT_RUBRIC_FILE:-$OVERLAY_DIR/deltas/sdd-init-rubric.md}"
STATE_JSON="$HOME/.gentle-ai/state.json"
BACKUP_ROOT="${GENTLE_AI_BACKUP_ROOT:-$OVERLAY_DIR/backups/$(date +%Y%m%d-%H%M%S)}"
BACKED_UP_FILES='|'

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# Exit codes: 0 = clean, 1 = anchor missing (gentle-ai template changed),
#             2 = --check found pending work.
MISSING_ANCHOR=0
OPERATION_FAILED=0
TARGET_DRIFT=0
PENDING=0
CHANGED=0

# ---------------------------------------------------------------------------
# Host map. One row per (host, artifact).
#   host | surface | path
# surface:
#   persona-marked   persona block delimited by <!-- gentle-ai:persona --> markers
#   persona-headed   persona block with no markers; bounded by "## Rules" .. next <!-- gentle-ai: marker
#   persona-split-claude  claude-code's newer split shape (CLAUDE.md); overlay
#                        rewrites only ## Rules and ## Expertise subregions
#                        inside <!-- gentle-ai:persona -->, preserving the
#                        installer-managed Contextual Skill Loading and Persona
#                        Voice sections byte-exact.
#   persona-split-neutral claude-code's externalized neutral.md (tone/behavior);
#                        wholesale canonical replacement (no installer-managed
#                        regions inside).
#   rubric-list      markdown surface WITH the MANDATORY numbered list -> rubric is item 4
#   rubric-prose     markdown surface WITHOUT the list (claude-code's condensed workflow)
#                    -> the loose-paragraph shape is the only one that fits
#   rubric-json      opencode.json -> .agent["gentle-orchestrator"].prompt (carries the list)
#   rubric-none      host has no strict-TDD forwarding section; nothing to inject
#   sdd-init-prompt  OpenCode's executable sdd-init prompt; unlike the skill and
#                    reference support files, this is the hidden agent's runtime entrypoint
#   pi-models        pi's sdd-model-assignments block -> host-agnostic `inherit`
#                    (pi routes phases via ~/.pi/gentle-ai/models.json; the Claude
#                     aliases gentle-ai renders there are unresolvable). pi ONLY.
# ---------------------------------------------------------------------------
host_rows() {
  cat <<'ROWS'
claude-code|persona-split-claude|.claude/CLAUDE.md
claude-code|persona-split-neutral|.claude/output-styles/neutral.md
claude-code|rubric-prose|.claude/skills/_shared/sdd-orchestrator-workflow.md
claude-code|sdd-init-skill|.claude/skills/sdd-init/SKILL.md
claude-code|sdd-init-details|.claude/skills/sdd-init/references/init-details.md
claude-code|sdd-init-rubric-reference|.claude/skills/sdd-init/references/rubric-authoring.md
pi|persona-marked|.pi/agent/APPEND_SYSTEM.md
pi|rubric-list|.pi/agent/APPEND_SYSTEM.md
pi|pi-models|.pi/agent/APPEND_SYSTEM.md
pi|sdd-init-pi|.pi/agent/agents/sdd-init.md
pi|sdd-init-rubric-reference|.pi/agent/agents/references/rubric-authoring.md
opencode|persona-marked|.config/opencode/AGENTS.md
opencode|rubric-json|.config/opencode/opencode.json
opencode|engram-idempotent|.config/opencode/plugins/engram.ts
opencode|sdd-init-skill|.config/opencode/skills/sdd-init/SKILL.md
opencode|sdd-init-details|.config/opencode/skills/sdd-init/references/init-details.md
opencode|sdd-init-rubric-reference|.config/opencode/skills/sdd-init/references/rubric-authoring.md
opencode|sdd-init-prompt|.config/opencode/prompts/sdd/sdd-init.md
codex|persona-headed|.codex/AGENTS.md
codex|rubric-none|.codex/AGENTS.md
codex|sdd-init-skill|.codex/skills/sdd-init/SKILL.md
codex|sdd-init-details|.codex/skills/sdd-init/references/init-details.md
codex|sdd-init-rubric-reference|.codex/skills/sdd-init/references/rubric-authoring.md
cursor|persona-headed|.cursor/rules/gentle-ai.mdc
cursor|rubric-list|.cursor/rules/gentle-ai.mdc
cursor|sdd-init-skill|.cursor/skills/sdd-init/SKILL.md
cursor|sdd-init-details|.cursor/skills/sdd-init/references/init-details.md
cursor|sdd-init-rubric-reference|.cursor/skills/sdd-init/references/rubric-authoring.md
vscode-copilot|persona-headed|.config/Code/User/prompts/gentle-ai.instructions.md
vscode-copilot|rubric-list|.config/Code/User/prompts/gentle-ai.instructions.md
vscode-copilot|sdd-init-skill|.copilot/skills/sdd-init/SKILL.md
vscode-copilot|sdd-init-details|.copilot/skills/sdd-init/references/init-details.md
vscode-copilot|sdd-init-rubric-reference|.copilot/skills/sdd-init/references/rubric-authoring.md
gemini-cli|persona-marked|.gemini/GEMINI.md
gemini-cli|rubric-list|.gemini/GEMINI.md
gemini-cli|sdd-init-skill|.gemini/skills/sdd-init/SKILL.md
gemini-cli|sdd-init-details|.gemini/skills/sdd-init/references/init-details.md
gemini-cli|sdd-init-rubric-reference|.gemini/skills/sdd-init/references/rubric-authoring.md
antigravity|persona-marked|.gemini/GEMINI.md
antigravity|rubric-list|.gemini/GEMINI.md
antigravity|sdd-init-skill|@antigravity-skills@/sdd-init/SKILL.md
antigravity|sdd-init-details|@antigravity-skills@/sdd-init/references/init-details.md
antigravity|sdd-init-rubric-reference|@antigravity-skills@/sdd-init/references/rubric-authoring.md
ROWS
}

# Hosts gentle-ai currently has installed. Falls back to the full static list.
installed_hosts() {
  local hosts
  if [ -r "$STATE_JSON" ] && command -v jq >/dev/null 2>&1; then
    hosts="$(jq -r '.installed_agents[]?' "$STATE_JSON" 2>/dev/null)"
    if [ -n "$hosts" ]; then
      printf '%s\n' "$hosts"
      return 0
    fi
  fi
  printf '%s\n' claude-code opencode pi codex cursor vscode-copilot gemini-cli antigravity
}

# v2.2.0 installs Antigravity skills below the desktop root when it exists;
# otherwise the CLI root is authoritative. The resolved path remains subject to
# the same regular-file and missing-file checks as every other target.
resolve_target_rel() {
  local host="$1" rel="$2" suffix
  case "$host:$rel" in
    antigravity:@antigravity-skills@/*)
      suffix="${rel#@antigravity-skills@/}"
      if [ -d "$HOME/.gemini/antigravity-desktop" ]; then
        printf '%s\n' ".gemini/antigravity-desktop/skills/$suffix"
      else
        printf '%s\n' ".gemini/antigravity-cli/skills/$suffix"
      fi
      ;;
    *) printf '%s\n' "$rel" ;;
  esac
}

report() { printf '  %-14s %-14s %s\n' "$1" "$2" "$3"; }

# Snapshot a file before the first write of THIS run. Some hosts carry two
# surfaces in one file (pi/cursor/copilot/antigravity hold both the persona and
# the SDD orchestrator), so guard against the second edit overwriting the
# pre-run snapshot taken by the first.
backup() {
  local f="$1" snapshot="$2" rel dest
  case "$BACKED_UP_FILES" in *"|$f|"*) return 0 ;; esac
  rel="${f#"$HOME"/}"
  dest="$BACKUP_ROOT/$rel"
  [ ! -e "$dest" ] || return 1
  mkdir -p "$(dirname -- "$dest")" || return 1
  cp -p -- "$snapshot" "$dest" || return 1
  BACKED_UP_FILES="${BACKED_UP_FILES}${f}|"
}

# The overlay must never follow a link into an arbitrary file. Replacement is
# atomic only when the temporary file is created beside the target.
safe_target() {
  [ ! -L "$1" ] && [ -f "$1" ]
}

target_tmp() {
  local file="$1" dir base
  dir="$(dirname -- "$file")"
  base="$(basename -- "$file")"
  mktemp "$dir/.${base}.gentle-ai.XXXXXX"
}

# Return 4 for an operational failure and 5 when another writer changed the
# target after the transform read it. The final rename remains same-directory
# and therefore cannot leave a partially written target behind.
commit_replacement() {
  local file="$1" snapshot="$2" replacement="$3" tmp

  safe_target "$file" || return 4
  cmp -s "$file" "$snapshot" || return 5
  backup "$file" "$snapshot" || return 4

  tmp="$(target_tmp "$file")" || return 4
  if ! cp -p -- "$file" "$tmp" || ! cat "$replacement" > "$tmp" || ! cmp -s "$replacement" "$tmp"; then
    rm -f -- "$tmp"
    return 4
  fi

  # Recheck after the backup and immediately before the atomic replacement.
  if ! safe_target "$file" || ! cmp -s "$file" "$snapshot"; then
    rm -f -- "$tmp"
    return 5
  fi
  mv -f -- "$tmp" "$file" || { rm -f -- "$tmp"; return 4; }
}

# ---------------------------------------------------------------------------
# Persona: replace the whole persona block with the canonical one.
#
# The persona body is byte-identical across every old-shape host, so the
# overlay ships ONE canonical block and stamps it into each of them. The block
# is located by markers when gentle-ai emits them, otherwise by heading range.
# ---------------------------------------------------------------------------
persona_apply() {
  local file="$1" mode="$2" tmp snapshot start end rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"
    return 4
  fi

  if [ "$mode" = persona-marked ]; then
    start="$(grep -n '^<!-- gentle-ai:persona -->$' "$snapshot" | head -1 | cut -d: -f1)"
    end="$(grep -n '^<!-- /gentle-ai:persona -->$' "$snapshot" | head -1 | cut -d: -f1)"
    if [ -z "$start" ] || [ -z "$end" ]; then rm -f -- "$tmp" "$snapshot"; return 3; fi
    # Body sits strictly between the markers.
    start=$((start + 1)); end=$((end - 1))
  else
    # persona-headed: "## Rules" .. line before the first gentle-ai section marker.
    start="$(grep -n '^## Rules$' "$snapshot" | head -1 | cut -d: -f1)"
    end="$(grep -n '^<!-- gentle-ai:' "$snapshot" | head -1 | cut -d: -f1)"
    if [ -z "$start" ] || [ -z "$end" ] || [ "$end" -le "$start" ]; then rm -f -- "$tmp" "$snapshot"; return 3; fi
    end=$((end - 1))
  fi

  # Sanity: the region we are about to overwrite must actually look like the
  # persona (all 9 sections). Guards against a template reshuffle silently
  # eating unrelated content.
  local sections
  sections="$(sed -n "${start},${end}p" "$snapshot" | grep -c '^## ')"
  if [ "$sections" -ne 9 ]; then rm -f -- "$tmp" "$snapshot"; return 3; fi

  # Already applied? Compare the live region against the canonical block,
  # ignoring blank-line padding.
  if diff -q <(sed -n "${start},${end}p" "$snapshot" | grep -v '^[[:space:]]*$') \
              <(grep -v '^[[:space:]]*$' "$PERSONA_FILE") >/dev/null 2>&1; then
    rm -f -- "$tmp" "$snapshot"; return 1
  fi

  if ! {
    [ "$start" -gt 1 ] && sed -n "1,$((start - 1))p" "$snapshot"
    cat "$PERSONA_FILE"
    echo ""
    sed -n "$((end + 1)),\$p" "$snapshot"
  } > "$tmp"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# ---------------------------------------------------------------------------
# Persona split for claude-code: the new gentle-ai shape puts only
# Rules/Expertise/Contextual Skill Loading/Persona Voice inside the
# <!-- gentle-ai:persona --> block of CLAUDE.md, and externalizes
# Personality/Tone/Behavior/Language to ~/.claude/output-styles/neutral.md.
#
# This function replaces ONLY the ## Rules and ## Expertise subregions inside
# the marked persona block, preserving Contextual Skill Loading and Persona
# Voice byte-exact (those carry installer-managed directives, not user tone).
# Anchor: heading-bounded within the persona block. If the headings vanish
# (template reshuffle), refuse with rc 3.
# ---------------------------------------------------------------------------
persona_split_claude_apply() {
  local file="$1" tmp snapshot p_start p_end rules_start exp_start skills_start voice_start exp_end rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"
    return 4
  fi

  p_start="$(grep -n '^<!-- gentle-ai:persona -->$' "$snapshot" | head -1 | cut -d: -f1)"
  p_end="$(grep -n '^<!-- /gentle-ai:persona -->$' "$snapshot" | head -1 | cut -d: -f1)"
  if [ -z "$p_start" ] || [ -z "$p_end" ] || [ "$p_start" -ge "$p_end" ]; then rm -f -- "$tmp" "$snapshot"; return 3; fi

  # Each delimiter and managed heading must occur exactly once and in order.
  if [ "$(grep -c '^<!-- gentle-ai:persona -->$' "$snapshot")" -ne 1 ] || \
     [ "$(grep -c '^<!-- /gentle-ai:persona -->$' "$snapshot")" -ne 1 ]; then
    rm -f -- "$tmp" "$snapshot"; return 3
  fi
  rules_start="$(awk -v s="$p_start" -v e="$p_end" 'NR>s && NR<e && /^## Rules$/{n++; line=NR} END {if (n == 1) print line}' "$snapshot")"
  exp_start="$(awk -v s="$p_start" -v e="$p_end" 'NR>s && NR<e && /^## Expertise$/{n++; line=NR} END {if (n == 1) print line}' "$snapshot")"
  skills_start="$(awk -v s="$p_start" -v e="$p_end" 'NR>s && NR<e && /^## Contextual Skill Loading( \(MANDATORY\))?$/{n++; line=NR} END {if (n == 1) print line}' "$snapshot")"
  voice_start="$(awk -v s="$p_start" -v e="$p_end" 'NR>s && NR<e && /^## Persona Voice$/{n++; line=NR} END {if (n == 1) print line}' "$snapshot")"
  if [ -z "$rules_start" ] || [ -z "$exp_start" ] || [ -z "$skills_start" ] || [ -z "$voice_start" ] || \
     [ "$rules_start" -ge "$exp_start" ] || [ "$exp_start" -ge "$skills_start" ] || [ "$skills_start" -ge "$voice_start" ]; then
    rm -f -- "$tmp" "$snapshot"; return 3
  fi

  # ## Expertise region ENDS at the line before the next ## heading after it.
  # This is where the canonical ## Expertise block ends (includes Expertise
  # heading, content, and trailing blank lines up to next ##).
  exp_end=$((skills_start - 1))

  # For comparison: live Rules region is rules_start .. (exp_start - 1) which
  # includes everything from "## Rules" through the blank line(s) before
  # "## Expertise".
  local live_rules live_exp can_rules can_exp
  live_rules="$(sed -n "${rules_start},$((exp_start - 1))p" "$snapshot" | grep -v '^[[:space:]]*$')"
  live_exp="$(sed -n "${exp_start},${exp_end}p" "$snapshot" | grep -v '^[[:space:]]*$')"
  can_rules="$(grep -v '^[[:space:]]*$' "$PERSONA_RULES_FILE")"
  can_exp="$(grep -v '^[[:space:]]*$' "$PERSONA_EXPERTISE_FILE")"
  if [ "$live_rules" = "$can_rules" ] && [ "$live_exp" = "$can_exp" ]; then
    rm -f -- "$tmp" "$snapshot"; return 1
  fi

  # Rebuild: head (up to line before ## Rules) .. canonical Rules (starts with
  # "## Rules") .. blank separator .. canonical Expertise (starts with
  # "## Expertise") .. tail (from line after Expertise region).
  if ! {
    [ "$rules_start" -gt 1 ] && sed -n "1,$((rules_start - 1))p" "$snapshot"
    cat "$PERSONA_RULES_FILE"
    echo ""
    cat "$PERSONA_EXPERTISE_FILE"
    echo ""
    sed -n "$((exp_end + 1)),\$p" "$snapshot"
  } > "$tmp"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# ---------------------------------------------------------------------------
# Persona split for claude-code's neutral.md: the externalized tone/behavior
# file. Wholesale replacement with the canonical file (the entire file is
# user-owned; there are no installer-managed regions inside it).
# ---------------------------------------------------------------------------
persona_split_neutral_apply() {
  local file="$1" snapshot rc
  snapshot="$(target_tmp "$file")" || return 4
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$snapshot"
    return 4
  fi
  if diff -q "$snapshot" "$PERSONA_NEUTRAL_FILE" >/dev/null 2>&1; then rm -f -- "$snapshot"; return 1; fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$PERSONA_NEUTRAL_FILE"; rc=$?
  rm -f -- "$snapshot"
  return "$rc"
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
[ -r "$PERSONA_RULES_FILE" ]     || { echo "FATAL: missing $PERSONA_RULES_FILE" >&2; exit 1; }
[ -r "$PERSONA_EXPERTISE_FILE" ]|| { echo "FATAL: missing $PERSONA_EXPERTISE_FILE" >&2; exit 1; }
[ -r "$PERSONA_NEUTRAL_FILE" ]  || { echo "FATAL: missing $PERSONA_NEUTRAL_FILE" >&2; exit 1; }
[ -r "$RUBRIC_FILE" ]   || { echo "FATAL: missing $RUBRIC_FILE" >&2; exit 1; }
[ -r "$PIMODEL_FILE" ]  || { echo "FATAL: missing $PIMODEL_FILE" >&2; exit 1; }
[ -r "$OPENCODE_ENGRAM_FILE" ] || { echo "FATAL: missing $OPENCODE_ENGRAM_FILE" >&2; exit 1; }
[ -r "$INIT_RUBRIC_FILE" ] || { echo "FATAL: missing $INIT_RUBRIC_FILE" >&2; exit 1; }

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

# First line of item 4 -- the marker used to locate the numbered-list block.
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
#   - inserts item 4 after item 3 when item 4 is absent
#   - replaces an existing item 4 and its indented continuation lines
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
        if (!anchor && index(line[i], a3) == 1) anchor = i      # end of the numbered list
        if (index(line[i], head) == 1) { have4++; item4_at = i }
        if (!loose  && line[i] == prose)          loose  = i    # legacy loose paragraph
      }
      if (!anchor) exit 1                                       # template changed -> refuse
      if (have4 > 1 || (have4 && item4_at != anchor + 1)) exit 1 # item 4 must immediately follow item 3

      if (loose) {
        drop[loose] = 1
        # The paragraph sits blank-line-padded. Removing it would leave two
        # consecutive blanks, so swallow the trailing one.
        if (line[loose - 1] ~ /^[ \t]*$/ && line[loose + 1] ~ /^[ \t]*$/) drop[loose + 1] = 1
      }

      for (i = 1; i <= n; i++) {
        if (replace4) {
          # Drop only indented continuation lines. A blank line terminates the
          # item and must survive as the separator before following prose.
          if (line[i] ~ /^[ \t]*$/) replace4 = 0
          else if (line[i] ~ /^[ \t]/) continue
          else replace4 = 0
        }
        if (drop[i]) continue
        if (i == item4_at) {
          print item4
          replace4 = 1
          continue
        }
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
OPENCODE_ENGRAM_BLOCK="$(extract_shape_from "$OPENCODE_ENGRAM_FILE" block)"
OPENCODE_ENGRAM_STOCK_BLOCK='    "experimental.chat.system.transform": async (input, output) => {
      if (output.system.length > 0) {
        output.system[output.system.length - 1] += "\n\n" + MEMORY_INSTRUCTIONS
      } else {
        output.system.push(MEMORY_INSTRUCTIONS)
      }'

[ -n "$PI_BLOCK" ] && [ -n "$PI_SKILLS" ] || {
  echo "FATAL: $PIMODEL_FILE is missing one of the shape blocks" >&2; exit 1; }

[ -n "$OPENCODE_ENGRAM_BLOCK" ] || {
  echo "FATAL: $OPENCODE_ENGRAM_FILE is missing the block shape" >&2; exit 1; }

# ---------------------------------------------------------------------------
# SDD init rubric producer contract.
#
# The shared SDD skill and its reference are independent installer files, while
# Pi uses a standalone phase-agent file. All three receive a marker-delimited
# instruction contract. The anchor and the complete marker pair must each be
# unique: partial or ambiguous templates are refused before a backup or write.
# ---------------------------------------------------------------------------
# This source delta is security-sensitive input to every new producer surface.
# Validate its complete four-shape grammar without changing legacy extractors.
extract_init_rubric_shape() {
  local wanted="$1"
  awk -v wanted="$wanted" '
     BEGIN { expected["skill"] = expected["details"] = expected["pi"] = expected["reference"] = 1 }
    /^<!-- shape:[a-z][a-z0-9-]* -->$/ {
      name = $0; sub(/^<!-- shape:/, "", name); sub(/ -->$/, "", name)
      if (!(name in expected) || opened[name] || inside) bad = 1
      else { opened[name] = 1; inside = name }
      next
    }
    /^<!-- \/shape:[a-z][a-z0-9-]* -->$/ {
      name = $0; sub(/^<!-- \/shape:/, "", name); sub(/ -->$/, "", name)
      if (!(name in expected) || !inside || name != inside || closed[name]) bad = 1
      else { closed[name] = 1; inside = "" }
      next
    }
    /<!--[ ]*\/?shape:/ { bad = 1; next }
    { if (inside == wanted) body = body (body == "" ? "" : "\n") $0 }
    END {
      for (name in expected) if (opened[name] != 1 || closed[name] != 1) bad = 1
      if (bad || inside || body == "") exit 1
      print body
    }
  ' "$INIT_RUBRIC_FILE"
}

INIT_RUBRIC_SKILL="$(extract_init_rubric_shape skill)" || { echo "FATAL: invalid $INIT_RUBRIC_FILE shape markers" >&2; exit 1; }
INIT_RUBRIC_DETAILS="$(extract_init_rubric_shape details)" || { echo "FATAL: invalid $INIT_RUBRIC_FILE shape markers" >&2; exit 1; }
INIT_RUBRIC_PI="$(extract_init_rubric_shape pi)" || { echo "FATAL: invalid $INIT_RUBRIC_FILE shape markers" >&2; exit 1; }
INIT_RUBRIC_REFERENCE="$(extract_init_rubric_shape reference)" || { echo "FATAL: invalid $INIT_RUBRIC_FILE shape markers" >&2; exit 1; }
INIT_RUBRIC_OPEN='<!-- gentle-ai:sdd-init-rubric -->'
INIT_RUBRIC_CLOSE='<!-- /gentle-ai:sdd-init-rubric -->'

[ -n "$INIT_RUBRIC_SKILL" ] && [ -n "$INIT_RUBRIC_DETAILS" ] && [ -n "$INIT_RUBRIC_PI" ] && [ -n "$INIT_RUBRIC_REFERENCE" ] || {
  echo "FATAL: $INIT_RUBRIC_FILE is missing one of the shape blocks" >&2; exit 1; }

init_rubric_transform() {
  local shape="$1" block anchor
  case "$shape" in
    skill) block="$INIT_RUBRIC_SKILL"; anchor='## Decision Gates' ;;
    details) block="$INIT_RUBRIC_DETAILS"; anchor='## Output Templates' ;;
    pi) block="$INIT_RUBRIC_PI"; anchor='## Memory Contract' ;;
    *) return 1 ;;
  esac

  BLOCK="$block" ANCHOR="$anchor" OPEN_MARKER="$INIT_RUBRIC_OPEN" CLOSE_MARKER="$INIT_RUBRIC_CLOSE" \
    awk 'BEGIN { block=ENVIRON["BLOCK"]; anchor=ENVIRON["ANCHOR"]; open_marker=ENVIRON["OPEN_MARKER"]; close_marker=ENVIRON["CLOSE_MARKER"] }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (line[i] == anchor) { anchors++; anchor_line = i }
        if (line[i] == open_marker) { opens++; open_line = i }
        if (line[i] == close_marker) { closes++; close_line = i }
      }
      if (anchors != 1 || opens != closes || opens > 1 || (opens == 1 && open_line >= close_line) || \
          (opens == 1 && anchor_line > open_line && anchor_line < close_line)) exit 1

      for (i = 1; i <= n; i++) {
        if (line[i] == anchor) { print block; print "" }
        if (opens == 1 && i > open_line && i < close_line) continue
        if (opens == 1 && i == open_line) continue
        if (opens == 1 && i == close_line) continue
        # The canonical block owns one separator before its anchor. Drop only
        # that exact generated separator so replacement stays byte-idempotent.
        if (opens == 1 && i == close_line + 1 && line[i] ~ /^[ \t]*$/ && line[i + 1] == anchor) continue
        print line[i]
      }
      exit 0
    }
  '
}

init_rubric_apply() {
  local file="$1" shape="$2" tmp snapshot rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi
  if ! init_rubric_transform "$shape" < "$snapshot" > "$tmp"; then
    rm -f -- "$tmp" "$snapshot"; return 3
  fi
  if cmp -s "$tmp" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 1
  fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# The reference is a complete managed file, unlike the marker-bounded skill
# sections. Create it only below an existing safe references directory; replace
# a regular existing file atomically and never follow a link.
init_rubric_reference_apply() {
  local file="$1" parent grandparent tmp rc
  parent="$(dirname -- "$file")"
  if [ ! -e "$parent" ] && [ ! -L "$parent" ]; then
    grandparent="$(dirname -- "$parent")"
    [ -d "$grandparent" ] && [ ! -L "$grandparent" ] || return 4
    if [ "$CHECK_ONLY" -eq 1 ]; then return 0; fi
    mkdir -- "$parent" || return 4
  fi
  [ -d "$parent" ] && [ ! -L "$parent" ] || return 4

  tmp="$(target_tmp "$file")" || return 4
  if ! printf '%s\n' "$INIT_RUBRIC_REFERENCE" > "$tmp" || ! chmod 644 "$tmp"; then
    rm -f -- "$tmp"
    return 4
  fi

  if [ -e "$file" ] || [ -L "$file" ]; then
    if ! safe_target "$file"; then
      rm -f -- "$tmp"
      return 4
    fi
    if cmp -s "$tmp" "$file"; then
      rm -f -- "$tmp"
      return 1
    fi
    if [ "$CHECK_ONLY" -eq 1 ]; then
      rm -f -- "$tmp"
      return 0
    fi
    commit_replacement "$file" "$file" "$tmp"; rc=$?
    rm -f -- "$tmp"
    return "$rc"
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then
    rm -f -- "$tmp"
    return 0
  fi
  if [ -e "$file" ] || [ -L "$file" ]; then
    rm -f -- "$tmp"
    return 5
  fi
  mv -- "$tmp" "$file" || { rm -f -- "$tmp"; return 4; }
}

PI_MARK_OPEN='<!-- gentle-ai:sdd-model-assignments -->'
PI_MARK_CLOSE='<!-- /gentle-ai:sdd-model-assignments -->'
# The one sentence outside the block that tells the orchestrator to cache and pass
# `phase -> alias`. Matched by prefix; replaced wholesale.
PI_SKILLS_ANCHOR='The orchestrator resolves skills from the registry ONCE'
PI_PROPOSAL_INTERACTIVE_HEAD='Before the `sdd-'
PI_PROPOSAL_INTERACTIVE_TAIL=' phase in interactive mode, offer the user a proposal question round'
PI_PROPOSAL_DELEGATION_HEAD='Only for a selected SDD route, delegate to these phase agents: sdd-init, sdd-explore, '
PI_PROPOSAL_DELEGATION_TAIL=', sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard.'
PI_PROPOSAL_TABLE_HEAD='| `sdd-'
PI_PROPOSAL_TABLE_TAIL='` | exploration (optional) | `proposal` |'

# Pure + idempotent: replaces the marker-delimited body and the alias sentence.
# Refuses missing/duplicate markers or any absent/duplicate proposal context.
pimodel_transform() {
  BLOCK="$PI_BLOCK" SKILLS="$PI_SKILLS" \
  M_OPEN="$PI_MARK_OPEN" M_CLOSE="$PI_MARK_CLOSE" S_ANCHOR="$PI_SKILLS_ANCHOR" \
  P1H="$PI_PROPOSAL_INTERACTIVE_HEAD" P1T="$PI_PROPOSAL_INTERACTIVE_TAIL" \
  P2H="$PI_PROPOSAL_DELEGATION_HEAD" P2T="$PI_PROPOSAL_DELEGATION_TAIL" \
  P3H="$PI_PROPOSAL_TABLE_HEAD" P3T="$PI_PROPOSAL_TABLE_TAIL" \
  awk '
    BEGIN {
      block = ENVIRON["BLOCK"]; skills = ENVIRON["SKILLS"]
      m_open = ENVIRON["M_OPEN"]; m_close = ENVIRON["M_CLOSE"]; s_anchor = ENVIRON["S_ANCHOR"]
      p1h = ENVIRON["P1H"]; p1t = ENVIRON["P1T"]
      p2h = ENVIRON["P2H"]; p2t = ENVIRON["P2T"]
      p3h = ENVIRON["P3H"]; p3t = ENVIRON["P3T"]
    }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (line[i] == m_open)  { opens++; o = i }
        if (line[i] == m_close) { closes++; c = i }
      }
      if (opens != 1 || closes != 1 || !o || !c || o >= c) exit 1

      for (i = 1; i <= n; i++) {
        if (i > o && i < c) continue                         # drop the old body
        if (i == c) { print block; print "" }                # canonical body, then the marker
        rendered = (index(line[i], s_anchor) == 1) ? skills : line[i]
        # Only the three known Pi SDD contexts use the concrete proposal-agent
        # identifier. Never rewrite unrelated user or installer text globally.
        if (index(line[i], p1h) == 1 && index(line[i], p1t) && \
            (index(line[i], "sdd-propose") || index(line[i], "sdd-proposal"))) {
          proposal_interactive++
          sub(/sdd-propose/, "sdd-proposal", rendered)
        }
        if (index(line[i], p2h) == 1 && index(line[i], p2t) && \
            (index(line[i], "sdd-propose") || index(line[i], "sdd-proposal"))) {
          proposal_delegation++
          sub(/sdd-propose/, "sdd-proposal", rendered)
        }
        if (index(line[i], p3h) == 1 && index(line[i], p3t) && \
            (index(line[i], "sdd-propose") || index(line[i], "sdd-proposal"))) {
          proposal_table++
          sub(/sdd-propose/, "sdd-proposal", rendered)
        }
        print rendered
      }
      if (proposal_interactive != 1 || proposal_delegation != 1 || proposal_table != 1) exit 1
      exit 0
    }
  '
}

pimodel_apply() {
  local file="$1" tmp snapshot rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi
  if ! pimodel_transform < "$snapshot" > "$tmp"; then rm -f -- "$tmp" "$snapshot"; return 3; fi
  if cmp -s "$tmp" "$snapshot"; then rm -f -- "$tmp" "$snapshot"; return 1; fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# ---------------------------------------------------------------------------
# OpenCode Engram prompt injection.
#
# OpenCode already receives the full Engram protocol through AGENTS.md. Keep
# the plugin fallback for configurations without that protocol, but avoid
# appending a second copy on every message when the protocol is already in the
# merged system prompt. The save nudge below this block remains untouched.
# ---------------------------------------------------------------------------
opencode_engram_transform() {
  BLOCK="$OPENCODE_ENGRAM_BLOCK" STOCK="$OPENCODE_ENGRAM_STOCK_BLOCK" awk '
    BEGIN {
      block = ENVIRON["BLOCK"]; stock = ENVIRON["STOCK"]
      start = "    \"experimental.chat.system.transform\": async (input, output) => {"
      save_nudge = "      // ── Save nudge"
    }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (line[i] == start) { starts++; start_line = i }
        if (index(line[i], save_nudge) == 1) { nudges++; nudge_line = i }
      }
      if (starts != 1 || nudges != 1 || start_line >= nudge_line) exit 1

      last = nudge_line - 1
      while (last >= start_line && line[last] ~ /^[[:space:]]*$/) last--
      managed = ""
      for (i = start_line; i <= last; i++) managed = managed (i == start_line ? "" : "\n") line[i]
      if (managed != stock && managed != block) exit 1

      for (i = 1; i <= n; i++) {
        if (i == start_line) {
          print block
          print ""
        }
        if (i >= start_line && i < nudge_line) continue
        print line[i]
      }
      exit 0
    }
  '
}

opencode_engram_apply() {
  local file="$1" tmp snapshot rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi
  if ! opencode_engram_transform < "$snapshot" > "$tmp"; then rm -f -- "$tmp" "$snapshot"; return 3; fi
  if cmp -s "$tmp" "$snapshot"; then rm -f -- "$tmp" "$snapshot"; return 1; fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# rc 0 = written/pending, 1 = already applied, 3 = anchor gone,
# 4 = operational failure, 5 = target drift.
rubric_apply_md() {
  local file="$1" shape="$2" tmp snapshot rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi
  if ! "rubric_transform_$shape" < "$snapshot" > "$tmp"; then rm -f -- "$tmp" "$snapshot"; return 3; fi
  if cmp -s "$tmp" "$snapshot"; then rm -f -- "$tmp" "$snapshot"; return 1; fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# opencode.json is a 130KB config; the orchestrator prompt is one JSON string
# value. Round-trip it through jq so the surrounding JSON is never hand-edited.
rubric_apply_json() {
  local file="$1" snapshot tmp_cur tmp_new tmp_json rc
  command -v jq >/dev/null 2>&1 || return 3

  snapshot="$(target_tmp "$file")" || return 4
  tmp_cur="$(target_tmp "$file")" || { rm -f -- "$snapshot"; return 4; }
  tmp_new="$(target_tmp "$file")" || { rm -f -- "$snapshot" "$tmp_cur"; return 4; }
  tmp_json="$(target_tmp "$file")" || { rm -f -- "$snapshot" "$tmp_cur" "$tmp_new"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 4
  fi
  if ! jq -r '.agent["gentle-orchestrator"].prompt // empty' "$snapshot" > "$tmp_cur" || [ ! -s "$tmp_cur" ]; then
    rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi

  if ! rubric_transform_list < "$tmp_cur" > "$tmp_new"; then
    rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi
  if cmp -s "$tmp_new" "$tmp_cur"; then                       # already applied
    rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 1
  fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 0; fi

  if ! jq --rawfile p "$tmp_new" '.agent["gentle-orchestrator"].prompt = ($p | rtrimstr("\n"))' \
        "$snapshot" > "$tmp_json"; then
    rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi
  # Never install a JSON file we cannot parse back.
  if ! jq empty "$tmp_json" >/dev/null 2>&1; then
    rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"; return 3
  fi
  commit_replacement "$file" "$snapshot" "$tmp_json"; rc=$?
  rm -f -- "$snapshot" "$tmp_cur" "$tmp_new" "$tmp_json"
  return "$rc"
}

# ---------------------------------------------------------------------------
# Drive
# ---------------------------------------------------------------------------
if [ "${APPLY_SH_LIB:-0}" = 1 ]; then
  return 0 2>/dev/null || exit 0
fi

if [ "$CHECK_ONLY" -eq 0 ]; then
  "$OVERLAY_DIR/apply.sh" --check >/dev/null
  preflight_rc=$?
  case "$preflight_rc" in
    0|2) ;;
    1)
      echo "FAIL: preflight found a missing file or anchor; nothing was written."
      echo "      Run $OVERLAY_DIR/apply.sh --check for details."
      exit 1
      ;;
    *)
      echo "FAIL: preflight exited unexpectedly with status $preflight_rc; nothing was written."
      exit "$preflight_rc"
      ;;
  esac
fi

echo "gentle-ai overrides overlay"
[ "$CHECK_ONLY" -eq 1 ] && echo "(--check: reporting only, nothing will be written)"
echo

HOSTS="$(installed_hosts)"

while IFS= read -r host; do
  echo "$host"
  matched=0
  while IFS='|' read -r h surface rel; do
    [ "$h" = "$host" ] || continue
    matched=1
    rel="$(resolve_target_rel "$host" "$rel")"
    file="$HOME/$rel"
    short="${rel}"

    if [ ! -e "$file" ] && [ ! -L "$file" ] && [ "$surface" != sdd-init-rubric-reference ]; then
      report "MISSING-FILE" "$surface" "$short"
      MISSING_ANCHOR=1
      continue
    fi
    if { [ -e "$file" ] || [ -L "$file" ]; } && ! safe_target "$file"; then
      report "UNSAFE-TARGET" "$surface" "$short"
      OPERATION_FAILED=1
      break 2
    fi

    case "$surface" in
      persona-split-claude)
        persona_split_claude_apply "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "persona" "$short (split: Rules+Expertise)"; PENDING=1
              else report "applied" "persona" "$short (split: Rules+Expertise)"; CHANGED=1; fi ;;
          1) report "already-applied" "persona" "$short (split: Rules+Expertise)" ;;
          3) report "ANCHOR-NOT-FOUND" "persona" "$short (split: Rules+Expertise)"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "persona" "$short (split: Rules+Expertise)"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "persona" "$short (split: Rules+Expertise)"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "persona" "$short (split: Rules+Expertise)"; OPERATION_FAILED=1 ;;
        esac
        ;;
      persona-split-neutral)
        persona_split_neutral_apply "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "persona" "$short (split: neutral)"; PENDING=1
              else report "applied" "persona" "$short (split: neutral)"; CHANGED=1; fi ;;
          1) report "already-applied" "persona" "$short (split: neutral)" ;;
          3) report "ANCHOR-NOT-FOUND" "persona" "$short (split: neutral)"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "persona" "$short (split: neutral)"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "persona" "$short (split: neutral)"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "persona" "$short (split: neutral)"; OPERATION_FAILED=1 ;;
        esac
        ;;
      persona-marked|persona-headed)
        persona_apply "$file" "$surface"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "persona" "$short"; PENDING=1
             else report "applied" "persona" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "persona" "$short" ;;
          3) report "ANCHOR-NOT-FOUND" "persona" "$short"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "persona" "$short"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "persona" "$short"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "persona" "$short"; OPERATION_FAILED=1 ;;
        esac
        ;;
      rubric-list|rubric-prose)
        rubric_apply_md "$file" "${surface#rubric-}"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "rubric-tdd" "$short"; PENDING=1
             else report "applied" "rubric-tdd" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "rubric-tdd" "$short" ;;
          3) report "ANCHOR-NOT-FOUND" "rubric-tdd" "$short"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "rubric-tdd" "$short"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "rubric-tdd" "$short"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "rubric-tdd" "$short"; OPERATION_FAILED=1 ;;
        esac
        ;;
      rubric-json)
        rubric_apply_json "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "rubric-tdd" "$short"; PENDING=1
             else report "applied" "rubric-tdd" "$short (jq)"; CHANGED=1; fi ;;
          1) report "already-applied" "rubric-tdd" "$short (jq)" ;;
          3) report "ANCHOR-NOT-FOUND" "rubric-tdd" "$short (jq)"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "rubric-tdd" "$short (jq)"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "rubric-tdd" "$short (jq)"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "rubric-tdd" "$short (jq)"; OPERATION_FAILED=1 ;;
        esac
        ;;
      engram-idempotent)
        opencode_engram_apply "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "engram" "$short (idempotent injection)"; PENDING=1
             else report "applied" "engram" "$short (idempotent injection)"; CHANGED=1; fi ;;
          1) report "already-applied" "engram" "$short (idempotent injection)" ;;
          3) report "ANCHOR-NOT-FOUND" "engram" "$short (idempotent injection)"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "engram" "$short (idempotent injection)"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "engram" "$short (idempotent injection)"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "engram" "$short (idempotent injection)"; OPERATION_FAILED=1 ;;
        esac
        ;;
      sdd-init-skill|sdd-init-details|sdd-init-pi|sdd-init-prompt)
        case "$surface" in
          sdd-init-skill) shape=skill ;;
          sdd-init-details) shape=details ;;
          sdd-init-pi) shape=pi ;;
          sdd-init-prompt) shape=skill ;;
        esac
        init_rubric_apply "$file" "$shape"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "sdd-init-rubric" "$short"; PENDING=1
             else report "applied" "sdd-init-rubric" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "sdd-init-rubric" "$short" ;;
          3) report "ANCHOR-NOT-FOUND" "sdd-init-rubric" "$short"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "sdd-init-rubric" "$short"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "sdd-init-rubric" "$short"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "sdd-init-rubric" "$short"; OPERATION_FAILED=1 ;;
        esac
        ;;
      sdd-init-rubric-reference)
        init_rubric_reference_apply "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "sdd-init-rubric-reference" "$short"; PENDING=1
             else report "applied" "sdd-init-rubric-reference" "$short"; CHANGED=1; fi ;;
          1) report "already-applied" "sdd-init-rubric-reference" "$short" ;;
          4) report "WRITE-FAILED" "sdd-init-rubric-reference" "$short"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "sdd-init-rubric-reference" "$short"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "sdd-init-rubric-reference" "$short"; OPERATION_FAILED=1 ;;
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
          3) report "ANCHOR-NOT-FOUND" "pi-models" "$short"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "pi-models" "$short"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "pi-models" "$short"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "pi-models" "$short"; OPERATION_FAILED=1 ;;
        esac
        ;;
    esac
    if [ "$OPERATION_FAILED" -eq 1 ] || [ "$TARGET_DRIFT" -eq 1 ]; then
      break 2
    fi
  done <<EOF
$(host_rows)
EOF
  [ "$matched" -eq 1 ] || report "unknown-host" "-" "no artifacts mapped"
  echo
done <<HOSTS_EOF
$HOSTS
HOSTS_EOF

if [ "$OPERATION_FAILED" -eq 1 ]; then
  echo "FAIL: a target was unsafe or a backup/write operation failed; nothing further was written."
  exit 1
fi

if [ "$TARGET_DRIFT" -eq 1 ]; then
  echo "FAIL: a target changed while it was being transformed; it was not overwritten."
  exit 1
fi

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
