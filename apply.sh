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
#   rubric-md        markdown SDD-orchestrator surface carrying the strict-TDD forwarding section
#   rubric-json      opencode.json -> .agent["gentle-orchestrator"].prompt
#   rubric-none      host has no strict-TDD forwarding section; nothing to inject
# ---------------------------------------------------------------------------
host_rows() {
  cat <<'ROWS'
claude-code|persona-split|.claude/CLAUDE.md
claude-code|persona-split|.claude/output-styles/neutral.md
claude-code|rubric-md|.claude/skills/_shared/sdd-orchestrator-workflow.md
pi|persona-marked|.pi/agent/APPEND_SYSTEM.md
pi|rubric-md|.pi/agent/APPEND_SYSTEM.md
opencode|persona-marked|.config/opencode/AGENTS.md
opencode|rubric-json|.config/opencode/opencode.json
codex|persona-headed|.codex/AGENTS.md
codex|rubric-none|.codex/AGENTS.md
cursor|persona-headed|.cursor/rules/gentle-ai.mdc
cursor|rubric-md|.cursor/rules/gentle-ai.mdc
vscode-copilot|persona-headed|.config/Code/User/prompts/gentle-ai.instructions.md
vscode-copilot|rubric-md|.config/Code/User/prompts/gentle-ai.instructions.md
antigravity|persona-marked|.gemini/GEMINI.md
antigravity|rubric-md|.gemini/GEMINI.md
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
# RUBRIC TDD: insert the paragraph into the strict-TDD forwarding section.
#
# Two known anchor shapes across hosts; the paragraph goes immediately after the
# strict-TDD forwarding instruction and before whatever follows it.
# ---------------------------------------------------------------------------
RUBRIC_TEXT="$(cat "$RUBRIC_FILE")"

# Anchor A (claude-code sdd-orchestrator-workflow.md): condensed one-paragraph form.
ANCHOR_A='When launching `sdd-apply` or `sdd-verify`, search for testing capabilities'
# Anchor B (pi, cursor, vscode-copilot, antigravity): numbered list + cache sentence.
ANCHOR_B='The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.'
# Anchor C (opencode.json orchestrator prompt): numbered list, no cache sentence.
ANCHOR_C='3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'

# Injects RUBRIC into stdin-content on stdout. Returns 1 if no anchor matched.
rubric_inject() {
  awk -v rubric="$RUBRIC_TEXT" -v a="$ANCHOR_A" -v b="$ANCHOR_B" -v c="$ANCHOR_C" '
    index($0, b) == 1 && !done { print rubric; print ""; print; done = 1; next }
    index($0, a) == 1 && !done { print; print ""; print rubric; done = 1; next }
    index($0, c) == 1 && !done { print; print ""; print rubric; done = 1; next }
    { print }
    END { exit(done ? 0 : 1) }
  '
}

rubric_apply_md() {
  local file="$1" tmp
  grep -qF -- "$RUBRIC_TEXT" "$file" && return 1          # already applied
  tmp="$(mktemp)"
  if ! rubric_inject < "$file" > "$tmp"; then rm -f "$tmp"; return 3; fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f "$tmp"; return 0; fi
  backup "$file"
  cat "$tmp" > "$file"
  rm -f "$tmp"
  return 0
}

# opencode.json is a 130KB config; the orchestrator prompt is one JSON string
# value. Round-trip it through jq so the surrounding JSON is never hand-edited.
rubric_apply_json() {
  local file="$1" prompt tmp_txt tmp_json
  command -v jq >/dev/null 2>&1 || return 3
  prompt="$(jq -r '.agent["gentle-orchestrator"].prompt // empty' "$file")"
  [ -n "$prompt" ] || return 3
  case "$prompt" in *"$RUBRIC_TEXT"*) return 1 ;; esac   # already applied

  tmp_txt="$(mktemp)"; tmp_json="$(mktemp)"
  if ! printf '%s\n' "$prompt" | rubric_inject > "$tmp_txt"; then
    rm -f "$tmp_txt" "$tmp_json"; return 3
  fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f "$tmp_txt" "$tmp_json"; return 0; fi

  if ! jq --rawfile p "$tmp_txt" '.agent["gentle-orchestrator"].prompt = ($p | rtrimstr("\n"))' \
        "$file" > "$tmp_json"; then
    rm -f "$tmp_txt" "$tmp_json"; return 3
  fi
  # Never install a JSON file we cannot parse back.
  if ! jq empty "$tmp_json" >/dev/null 2>&1; then
    rm -f "$tmp_txt" "$tmp_json"; return 3
  fi
  backup "$file"
  cat "$tmp_json" > "$file"
  jq empty "$file" >/dev/null 2>&1 || return 3
  rm -f "$tmp_txt" "$tmp_json"
  return 0
}

# ---------------------------------------------------------------------------
# Drive
# ---------------------------------------------------------------------------
[ -r "$PERSONA_FILE" ] || { echo "FATAL: missing $PERSONA_FILE" >&2; exit 1; }
[ -r "$RUBRIC_FILE" ]  || { echo "FATAL: missing $RUBRIC_FILE" >&2; exit 1; }

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
      rubric-md)
        rubric_apply_md "$file"; rc=$?
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
