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
PERSONA_STYLE_FILE="$OVERLAY_DIR/persona/neutral-style.md"
RUBRIC_FILE="$OVERLAY_DIR/deltas/rubric-tdd.md"
OPENCODE_ENGRAM_FILE="$OVERLAY_DIR/deltas/opencode-engram-idempotent.md"
INIT_RUBRIC_FILE="${INIT_RUBRIC_FILE:-$OVERLAY_DIR/deltas/sdd-init-rubric.md}"
STATE_JSON="$HOME/.gentle-ai/state.json"
PI_AGENT_HOME="${GENTLE_PI_AGENT_HOME:-${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}}"
BACKUP_ROOT="${GENTLE_AI_BACKUP_ROOT:-$OVERLAY_DIR/backups/$(date +%Y%m%d-%H%M%S)}"
BACKED_UP_FILES='|'

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

# Exit codes: 0 = clean, 1 = anchor missing (gentle-ai template changed),
#             2 = --check found pending work.
MISSING_ANCHOR=0
OPERATION_FAILED=0
TARGET_DRIFT=0
CAPABILITY_FAILED=0
PACKAGE_TARGET_FAILED=0
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
#   persona-split-style claude-code's selected externalized neutral.md or
#                       gentleman.md (tone/behavior); wholesale canonical
#                       replacement (no installer-managed regions inside).
#   rubric-list      markdown surface WITH the MANDATORY numbered list -> rubric is item 4
#   rubric-prose     markdown surface WITHOUT the list (claude-code's condensed workflow)
#                    -> the loose-paragraph shape is the only one that fits
#   rubric-json      opencode.json -> .agent["gentle-orchestrator"].prompt (carries the list)
#   pi-rubric-workflow Pi's package-owned lazy SDD workflow asset; marker-delimited
#                      project-rubric forwarding after its binary contract
#   pi-odd-forwarding Pi's package-owned ODD delegation asset; marker-delimited
#                     parent-only rubric forwarding when the released ODD section exists
#   rubric-none      host has no strict-TDD forwarding section; nothing to inject
#   sdd-init-delegation OpenCode's hidden agent uses either the native inline
#                       imperative or the exact native external prompt reference
# ---------------------------------------------------------------------------
host_rows() {
  cat <<'ROWS'
claude-code|persona-split-claude|.claude/CLAUDE.md
claude-code|persona-split-style|@claude-output-style@
claude-code|rubric-prose|.claude/skills/_shared/sdd-orchestrator-workflow.md
claude-code|sdd-init-skill|.claude/skills/sdd-init/SKILL.md
claude-code|sdd-init-details|.claude/skills/sdd-init/references/init-details.md
pi|pi-gentle-init-transaction|@pi-gentle-pi-gentle-init@
opencode|persona-marked|.config/opencode/AGENTS.md
opencode|rubric-json|.config/opencode/opencode.json
opencode|engram-idempotent|.config/opencode/plugins/engram.ts
opencode|sdd-init-skill|.config/opencode/skills/sdd-init/SKILL.md
opencode|sdd-init-details|.config/opencode/skills/sdd-init/references/init-details.md
opencode|sdd-init-delegation|.config/opencode/opencode.json
codex|persona-headed|.codex/AGENTS.md
codex|rubric-none|.codex/AGENTS.md
codex|sdd-init-skill|.codex/skills/sdd-init/SKILL.md
codex|sdd-init-details|.codex/skills/sdd-init/references/init-details.md
cursor|persona-headed|.cursor/rules/gentle-ai.mdc
cursor|rubric-list|.cursor/rules/gentle-ai.mdc
cursor|sdd-init-skill|.cursor/skills/sdd-init/SKILL.md
cursor|sdd-init-details|.cursor/skills/sdd-init/references/init-details.md
vscode-copilot|persona-headed|.config/Code/User/prompts/gentle-ai.instructions.md
vscode-copilot|rubric-list|.config/Code/User/prompts/gentle-ai.instructions.md
vscode-copilot|sdd-init-skill|.copilot/skills/sdd-init/SKILL.md
vscode-copilot|sdd-init-details|.copilot/skills/sdd-init/references/init-details.md
gemini-cli|persona-marked|.gemini/GEMINI.md
gemini-cli|rubric-list|.gemini/GEMINI.md
gemini-cli|sdd-init-skill|.gemini/skills/sdd-init/SKILL.md
gemini-cli|sdd-init-details|.gemini/skills/sdd-init/references/init-details.md
antigravity|persona-marked|.gemini/GEMINI.md
antigravity|rubric-list|.gemini/GEMINI.md
antigravity|sdd-init-skill|@antigravity-skills@/sdd-init/SKILL.md
antigravity|sdd-init-details|@antigravity-skills@/sdd-init/references/init-details.md
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

# Emit one JSON-string record per Pi package source without evaluating settings
# content. jq is preferred; Node is the safe JSON-parser fallback available with
# Pi. @json / JSON.stringify keep each arbitrary decoded string on one physical
# line, so a control character can never create a second classifier record.
pi_package_source_strings() {
  local settings="$1"

  if command -v jq >/dev/null 2>&1; then
    jq -r '
      .packages[]? |
      if type == "string" then .
      elif type == "object" and (.source? | type == "string") then .source
      else empty end |
      @json
    ' "$settings" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e '
      const fs = require("fs");
      const settings = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      const packages = settings && Array.isArray(settings.packages) ? settings.packages : [];
      for (const entry of packages) {
        const source = typeof entry === "string"
          ? entry
          : entry !== null && typeof entry === "object" && !Array.isArray(entry) &&
              typeof entry.source === "string"
            ? entry.source
            : null;
        if (source !== null) process.stdout.write(JSON.stringify(source) + "\n");
      }
    ' "$settings"
  else
    return 127
  fi
}

# Normalize the relative local-package form that Pi persists in user settings.
# Pi resolves the install input first, then stores it relative to $HOME/.pi/agent.
# This lexical stack deliberately does not follow symlinks; package asset confinement
# separately resolves the selected root and rejects links inside it before any read.
pi_normalize_user_local_source_rel() {
  local source="$1" part result
  local -a stack=(.pi agent) parts=()

  [[ "$source" =~ ^[A-Za-z0-9._/-]+$ ]] || return 1
  case "$source" in
    ''|/*|.|./*|*/.|*/./*|*//*|*/) return 1 ;;
  esac

  IFS=/ read -r -a parts <<< "$source"
  for part in "${parts[@]}"; do
    case "$part" in
      ''|.) return 1 ;;
      ..)
        [ "${#stack[@]}" -gt 0 ] || return 1
        unset 'stack[${#stack[@]}-1]'
        ;;
      *) stack+=("$part") ;;
    esac
  done
  [ "${#stack[@]}" -gt 0 ] || return 1
  result="$(IFS=/; printf '%s' "${stack[*]}")"
  case "$result" in gentle-pi|*/gentle-pi) printf '%s\n' "$result" ;; *) return 1 ;; esac
}

# Classify one complete JSON-string record emitted by pi_package_source_strings.
# Canonical supported identities contain no JSON escapes, so matching their complete
# framed representation is safer than decoding data into shell strings. Invalid
# frames fail closed, while unrelated names such as gentle-pi-helper remain ignored.
pi_classify_package_source_record() {
  local record="$1"
  local json_string_re='^"([^"\\[:cntrl:]]|\\(["\\/bfnrt]|u[[:xdigit:]]{4}))*"$'
  local git_source_re='^"git:(github\.com/Gentleman-Programming/gentle-pi|https://github\.com/Gentleman-Programming/gentle-pi(\.git)?|ssh://git@github\.com/Gentleman-Programming/gentle-pi(\.git)?|git@github\.com:Gentleman-Programming/gentle-pi(\.git)?)([@#][^[:space:]"\\]+)?"$'
  local npm_source_re='^"(npm:)?gentle-pi(@[A-Za-z0-9~^<>=*][A-Za-z0-9._~^<>=|*+-]*)?"$'
  local gentle_pi_identity_re='gentle-pi(\.git)?([^[:alnum:]_.-]|$)'
  local local_prefix local_rel

  # A parser must only emit a complete JSON string. This also catches accidental
  # raw-newline framing before root fallback can inspect a stale package layout.
  [[ "$record" =~ $json_string_re ]] || return 2

  if [[ "$record" =~ $git_source_re ]]; then
    printf '%s\n' git
    return 0
  fi
  if [[ "$record" =~ $npm_source_re ]]; then
    printf '%s\n' npm
    return 0
  fi

  # A local source is accepted only when it resolves beneath this user's HOME;
  # retain a repository-relative root so the rest of the selected-root checks
  # remain identical to git/npm layouts. Escaped JSON, traversal, and external
  # paths stay unsupported and never reach a package read.
  for local_prefix in "\"path:$HOME/" "\"file:$HOME/"; do
    case "$record" in
      "$local_prefix"*)
        local_rel="${record#"$local_prefix"}"
        local_rel="${local_rel%\"}"
        case "/$local_rel/" in *'//'|*'/./'*|*'/../'*) return 2 ;; esac
        [[ "$local_rel" =~ ^[A-Za-z0-9._/-]+/gentle-pi$ ]] || return 2
        printf 'local:%s\n' "$local_rel"
        return 0
        ;;
    esac
  done

  # Pi stores a user-local package path relative to $HOME/.pi/agent. Decode only
  # the unescaped safe subset that Pi emits, then require lexical HOME confinement.
  if [[ "$record" != *'\\'* ]]; then
    local_rel="${record#\"}"
    local_rel="${local_rel%\"}"
    case "$local_rel" in
      gentle-pi|*/gentle-pi)
        local_rel="$(pi_normalize_user_local_source_rel "$local_rel")" || return 2
        printf 'local:%s\n' "$local_rel"
        return 0
        ;;
    esac
  fi

  # An unsupported exact gentle-pi basename (including one with escaped control
  # data or a concatenated suffix) is configuration we must not bypass. Names with
  # a continued identifier character, e.g. gentle-pi-helper, are unrelated.
  [[ "$record" =~ $gentle_pi_identity_re ]] && return 2
  return 1
}

# Return one recognized gentle-pi package source kind from Pi's package settings.
# The package sources are data only: both safe parsers emit framed JSON records and
# this one shared exact-identity classifier maps supported forms. Return 1 when no
# gentle-pi source is configured and 2 for unavailable parsing, invalid, unsupported,
# malformed-framing, or conflicting configuration.
pi_configured_package_kind() {
  local settings="$HOME/.pi/agent/settings.json" sources record kind selected='' known=0 rc

  [ -e "$settings" ] || return 1
  [ -f "$settings" ] && [ -r "$settings" ] || return 2

  sources="$(pi_package_source_strings "$settings")" || return 2
  [ -n "$sources" ] || return 1

  while IFS= read -r record; do
    kind="$(pi_classify_package_source_record "$record")"
    rc=$?
    case "$rc" in
      0)
        known=$((known + 1))
        selected="$kind"
        ;;
      1) ;;
      *) return 2 ;;
    esac
  done <<EOF
$sources
EOF

  [ "$known" -eq 1 ] || { [ "$known" -eq 0 ] && return 1; return 2; }
  printf '%s\n' "$selected"
}

# Resolve the selected gentle-pi package root without assuming an npm install
# layout. Every package-owned asset is resolved beneath this one root, so a safely
# inspected explicit source wins over a stale alternate layout for the whole Pi
# overlay. Root fallback is allowed only when settings is absent or safely parsed
# without a gentle-pi source; two roots are deliberately ambiguous.
resolve_pi_gentle_package_root_rel() {
  local git_root='.pi/agent/git/github.com/Gentleman-Programming/gentle-pi'
  local npm_root='.pi/agent/npm/node_modules/gentle-pi'
  local configured configured_rc git_present=0 npm_present=0

  configured="$(pi_configured_package_kind)"
  configured_rc=$?
  case "$configured_rc" in
    0)
      case "$configured" in
        git) printf '%s\n' "$git_root" ;;
        npm) printf '%s\n' "$npm_root" ;;
        local:*) printf '%s\n' "${configured#local:}" ;;
        *) return 1 ;;
      esac
      return 0
      ;;
    2) return 1 ;;
  esac

  [ -d "$HOME/$git_root" ] && git_present=1
  [ -d "$HOME/$npm_root" ] && npm_present=1
  case "$git_present:$npm_present" in
    1:0) printf '%s\n' "$git_root" ;;
    0:1) printf '%s\n' "$npm_root" ;;
    *) return 1 ;;
  esac
}

# Resolve a Pi package-owned asset under the one selected package root. The caller
# supplies only a fixed package-relative asset path; no target may independently
# fall back to another package layout.
resolve_pi_gentle_asset_rel() {
  local asset_rel="$1" root
  root="$(resolve_pi_gentle_package_root_rel)" || return 1
  printf '%s/%s\n' "$root" "$asset_rel"
}

resolve_pi_gentle_workflow_rel() {
  resolve_pi_gentle_asset_rel 'assets/sdd-orchestrator-workflow.md'
}

resolve_pi_gentle_delegation_rel() {
  resolve_pi_gentle_asset_rel 'assets/orchestrator-delegation.md'
}

resolve_pi_gentle_sdd_init_rel() {
  resolve_pi_gentle_asset_rel 'assets/agents/sdd-init.md'
}

resolve_pi_gentle_gentle_init_rel() {
  resolve_pi_gentle_asset_rel 'assets/agents/gentle-init.md'
}

# v2.2.0 installs Antigravity skills below the desktop root when it exists;
# otherwise the CLI root is authoritative. The resolved path remains subject to
# the same regular-file and missing-file checks as every other target.
resolve_target_rel() {
  local host="$1" rel="$2" suffix
  case "$host:$rel" in
    claude-code:@claude-output-style@)
      resolve_claude_output_style_rel
      ;;
    pi:@pi-gentle-pi-workflow@)
      resolve_pi_gentle_workflow_rel
      ;;
    pi:@pi-gentle-pi-delegation@)
      resolve_pi_gentle_delegation_rel
      ;;
    pi:@pi-gentle-pi-sdd-init@)
      resolve_pi_gentle_sdd_init_rel
      ;;
    pi:@pi-gentle-pi-gentle-init@)
      resolve_pi_gentle_gentle_init_rel
      ;;
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

# Package-relative paths must not follow a link in any component or resolve
# outside their selected root. This shared primitive protects both grouped writes
# and advisory source reads before a package asset is enumerated or hashed.
pi_package_path_confined() {
  local root="$1" path="$2" root_real dir_real rel part current
  # Canonical package selection may itself traverse a symlink above the selected
  # root. Only components *inside* that resolved root are untrusted here.
  [ -d "$root" ] || return 1
  root_real="$(cd -P -- "$root" 2>/dev/null && pwd -P)" || return 1
  case "$path" in "$root"/*) rel="${path#"$root"/}" ;; *) return 1 ;; esac
  current="$root"
  while [ -n "$rel" ]; do
    part="${rel%%/*}"
    current="$current/$part"
    [ ! -L "$current" ] || return 1
    [ "$part" = "$rel" ] && break
    rel="${rel#*/}"
  done
  dir_real="$(cd -P -- "$(dirname -- "$path")" 2>/dev/null && pwd -P)" || return 1
  case "$dir_real/$(basename -- "$path")" in "$root_real"/*) return 0 ;; *) return 1 ;; esac
}

pi_group_safe_target() {
  local root="$1" file="$2"
  [ -f "$file" ] && [ ! -L "$file" ] && pi_package_path_confined "$root" "$file"
}

# Claude Code keeps its selected output style in settings while Gentle AI
# persists the selected persona. Either is authoritative when present; a
# disagreement must not be guessed through because it could overwrite the
# unselected native style.
claude_style_from_state() {
  local persona
  [ -e "$STATE_JSON" ] || return 0
  command -v jq >/dev/null 2>&1 || return 1
  persona="$(jq -r 'if type != "object" then error("state must be an object") elif has("persona") then (.persona | if type == "string" then ascii_downcase else error("persona must be a string") end) else empty end' "$STATE_JSON" 2>/dev/null)" || return 1
  case "$persona" in
    '') ;;
    neutral) printf '%s\n' neutral ;;
    gentleman|gentleman-neutral-artifacts) printf '%s\n' gentleman ;;
    *) return 1 ;;
  esac
}

claude_style_from_settings() {
  local settings="$HOME/.claude/settings.json" style
  [ -e "$settings" ] || return 0
  command -v jq >/dev/null 2>&1 || return 1
  style="$(jq -r 'if type != "object" then error("settings must be an object") elif has("outputStyle") then (.outputStyle | if type == "string" then ascii_downcase else error("outputStyle must be a string") end) else empty end' "$settings" 2>/dev/null)" || return 1
  case "$style" in
    '') ;;
    neutral|gentleman) printf '%s\n' "$style" ;;
    *) return 1 ;;
  esac
}

resolve_claude_output_style_rel() {
  local state_style settings_style native neutral gentleman
  state_style="$(claude_style_from_state)" || return 1
  settings_style="$(claude_style_from_settings)" || return 1
  if [ -n "$state_style" ] && [ -n "$settings_style" ] && [ "$state_style" != "$settings_style" ]; then
    return 1
  fi
  native="${state_style:-$settings_style}"
  if [ -n "$native" ]; then
    printf '%s\n' ".claude/output-styles/$native.md"
    return 0
  fi

  # Minimal fixtures may intentionally omit persisted selectors. Accept only a
  # single exposed native style; zero or two files is unsupported ambiguity.
  neutral="$HOME/.claude/output-styles/neutral.md"
  gentleman="$HOME/.claude/output-styles/gentleman.md"
  if { [ -e "$neutral" ] || [ -L "$neutral" ]; } && ! { [ -e "$gentleman" ] || [ -L "$gentleman" ]; }; then
    printf '%s\n' '.claude/output-styles/neutral.md'
  elif { [ -e "$gentleman" ] || [ -L "$gentleman" ]; } && ! { [ -e "$neutral" ] || [ -L "$neutral" ]; }; then
    printf '%s\n' '.claude/output-styles/gentleman.md'
  else
    return 1
  fi
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
# Personality/Tone/Behavior/Language to ~/.claude/output-styles/gentleman.md.
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
# Persona split for claude-code's gentleman.md: the externalized tone/behavior
# file. Wholesale replacement with the canonical file (the entire file is
# user-owned; there are no installer-managed regions inside it).
# ---------------------------------------------------------------------------
persona_split_style_apply() {
  local file="$1" snapshot rc
  snapshot="$(target_tmp "$file")" || return 4
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$snapshot"
    return 4
  fi
  if diff -q "$snapshot" "$PERSONA_STYLE_FILE" >/dev/null 2>&1; then rm -f -- "$snapshot"; return 1; fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$PERSONA_STYLE_FILE"; rc=$?
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
[ -r "$PERSONA_STYLE_FILE" ]  || { echo "FATAL: missing $PERSONA_STYLE_FILE" >&2; exit 1; }
[ -r "$RUBRIC_FILE" ]   || { echo "FATAL: missing $RUBRIC_FILE" >&2; exit 1; }
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

# The Pi ODD block is a separately managed source shape. Refuse a malformed or
# duplicated source marker rather than concatenating a partial prompt into a
# package asset.
extract_unique_shape() {
  local wanted="$1"
  awk -v wanted="$wanted" '
    BEGIN {
      open_marker = "<!-- shape:" wanted " -->"
      close_marker = "<!-- /shape:" wanted " -->"
    }
    $0 == open_marker {
      opens++
      if (inside || opens > 1) bad = 1
      inside = 1
      next
    }
    $0 == close_marker {
      closes++
      if (!inside || closes > 1) bad = 1
      inside = 0
      next
    }
    index($0, "shape:" wanted) { bad = 1; next }
    { if (inside) body = body (body == "" ? "" : "\n") $0 }
    END {
      if (opens != 1 || closes != 1 || inside || bad || body == "") exit 1
      print body
    }
  ' "$RUBRIC_FILE"
}

RUBRIC_ITEM4="$(extract_shape list-item)"
RUBRIC_PROSE="$(extract_shape prose)"
# Exact immediately preceding HEAD forms. These are recognition-only migration
# inputs: transforms replace one complete known form in place, never delete a
# loose substring from a custom consumer.
RUBRIC_ITEM4_HEAD_PREVIOUS="$(cat <<'EOF'
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   For each `sdd-apply` or `sdd-verify` work slice, read the canonical `sdd-init` authoritative policy directly for the active artifact store.
   The orchestrator caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules.
   Corroborate changed paths/symbols only where that policy declares them relevant, and stop for clarification when declared intent conflicts with that evidence.
   Select `default` ONLY when no non-default row matches; otherwise apply strictest MODE precedence and union only applicable non-default rows' obligations.
   Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths without substituting downstream matching rules or policy rewriting.
   Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy. Producer and activation semantics remain owned by `sdd-init`.
   Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification; do not fabricate runtime recovery dispatch.
   Binary `strict_tdd` fallback is permitted ONLY when no rubric exists. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
   Declared work intent selects MODE; project scope selects only applicable command bindings. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence.
EOF
)"
RUBRIC_ITEM4_LEGACY="$(cat <<'EOF'
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate.
   The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols,
   reject incompatible intents, then forward its one combined row and canonical-model digest without downstream
   re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched
   state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever
   been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and
   Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
EOF
)"
RUBRIC_PROSE_HEAD_PREVIOUS="$(cat <<'EOF'
For each `sdd-apply` or `sdd-verify` work slice, read the canonical `sdd-init` authoritative policy directly for the active artifact store. The orchestrator caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; corroborate changed paths/symbols only where that policy declares them relevant, and stop for clarification when declared intent conflicts with that evidence. Select `default` ONLY when no non-default row matches; otherwise apply strictest MODE precedence and union only applicable non-default rows' obligations. Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths without substituting downstream matching rules or policy rewriting. Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy. Producer and activation semantics remain owned by `sdd-init`. Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification; do not fabricate runtime recovery dispatch. Binary `strict_tdd` fallback is permitted ONLY when no rubric exists. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged. Declared work intent selects MODE; project scope selects only applicable command bindings. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence.
EOF
)"
# Exact prose emitted by the older overlay revision (base 8f030e8).
RUBRIC_PROSE_PREVIOUS='Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate. The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /gentle-sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.'
CACHE_NEW="$(extract_shape cache-sentence)"
CACHE_HEAD_PREVIOUS='The orchestrator reads the canonical `sdd-init` authoritative policy directly from the active artifact store and caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; producer and activation semantics remain owned by `sdd-init`. Declared work intent selects MODE; project scope selects only applicable command bindings. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence.'
RUBRIC_PI_WORKFLOW="$(extract_shape pi-workflow)"
RUBRIC_PI_ODD_FORWARDING="$(extract_unique_shape pi-odd-forwarding)" || {
  echo "FATAL: invalid pi-odd-forwarding shape in $RUBRIC_FILE" >&2; exit 1; }
# Exact immediately preceding Pi consumer blocks. These recognition-only bytes
# are accepted for an in-place upgrade; any other complete marker body refuses.
RUBRIC_PI_WORKFLOW_HEAD_PREVIOUS="$(cat <<'EOF'
<!-- gentle-ai:pi-rubric-forwarding -->
### Project TDD Rubric Forwarding

Compatibility is verified with official Gentle AI 2.6.0 with `gentle-pi@2.4.0`. Pi preservation boundary: this forwarding block owns only this package workflow; APPEND_SYSTEM.md remains installer-managed and untouched. Do not read, transform, back up, or write it.

For each actual `sdd-apply` or `sdd-verify` work slice, use the session-selected artifact store; do not switch stores merely because `openspec/config.yaml` exists. The orchestrator reads the canonical `sdd-init` authoritative policy directly for the active artifact store and caches the canonical policy ONCE per session. Reuse its canonical paths, topics, and validity requirements: OpenSpec reads only `openspec/config.yaml` `testing.rubric.active: true`; Engram reads only the canonical `sdd-init/{project}` policy artifact carrying `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` and `Status: active/authoritative.`; hybrid requires semantically equivalent active/authoritative policy in its configured stores. A valid rubric and its resolved slice instruction govern this forwarding.

The orchestrator must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; corroborate changed paths or symbols only where that policy declares them relevant, and stop for clarification when declared intent conflicts with that evidence. Policy-defined matching, precedence, and exceptions govern each slice. Do not replace declared exceptions or precedence with generic all-matches, strictest-wins, or union behavior. If the canonical policy explicitly declares `all-rows` with `strictest-wins` and evidence union, use that declared resolution; otherwise use its declared resolution. Select `default` ONLY when no non-default row matches. Only use `default` when no non-default match exists and that policy actually declares a default. If policy sources or declared resolution rules combine ambiguously, do not adjudicate a MODE; stop for human clarification.

Declared work intent selects MODE; project scope selects only applicable command bindings. Test-only maintenance may bind mapped production-scope evidence but never infers production work intent. Mixed intents union applicable scoped evidence and select the highest applicable MODE only after explicit exceptions and precedence. A manual old-path rule conflict with intent policy is shown and requires clarification; never rewrite the manual row. Unmatched executable, configuration, or CI work needs a visible rationale or blocking decision; never silently receives no evidence. These are existing policy-row semantics, not a consumer schema, parser, or fallback authority.

Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths to every `sdd-apply` and `sdd-verify` launch without substituting downstream matching rules or policy rewriting. Forward only commands applicable to the current phase under declared bindings. Do not reuse an apply command for verify, or a verify command for apply, unless the policy explicitly declares it shared. A legacy flat command with no phase binding remains applicable as declared; lack of a phase binding alone does not invalidate it. If a needed phase command has an unknown binding, stop for clarification; do not invent a command. Before launch, add plain prompt content to the existing parent phase prompt: the canonical source reference, slice, resolved MODE, phase-applicable exact commands, disciplines/evidence, and skill paths; then send it to the child. A child agent's own configuration or gate can still conflict; do not claim this prompt guarantees child enforcement or change the child without separate scope. Do not inline all artifact contents; executors read their artifacts normally. Preflight or native-status injection by a runtime extension does not resolve MODE; the parent orchestrator remains responsible for MODE resolution. This is parent LLM instruction, not a new parser, runtime adapter, schema, trace protocol, or capture protocol. This forwarding applies only to `sdd-apply` and `sdd-verify`, not to RDD reviewers.

Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy. Producer and activation semantics remain owned by `sdd-init`. Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification; do not fabricate runtime recovery dispatch. Binary `strict_tdd` fallback is permitted ONLY when no rubric exists. The preserved binary Strict TDD clause above is fallback-only when there is genuinely no rubric. Missing required canonical policy, or invalid, ambiguous, or conflicting policy, is not no rubric; stop for human clarification.

When the effective MODE is `strict-tdd`, include `STRICT TDD MODE IS ACTIVE. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.` with the policy's forwarded obligations.

The orchestrator is read-only: never author, generate, mutate, broaden, infer, alter, or rewrite the authoritative policy's rows, commands, bindings, or evidence. It may mechanically match existing policy rows using only those declared rules and must never invent commands or evidence.
<!-- /gentle-ai:pi-rubric-forwarding -->
EOF
)"
RUBRIC_PI_ODD_FORWARDING_HEAD_PREVIOUS="$(cat <<'EOF'
<!-- gentle-ai:pi-odd-forwarding -->
### Approved Rubric Forwarding for ODD

This is a parent-only ODD forwarding instruction. It supplements the native Organic Driven Development topology; it does not create an ODD agent, parser, schema, compiler, task store, or worker-side policy resolver.

When an approved rubric exists, resolve its declared per-work intent rules through that rubric's canonical locator and declared matching, precedence, and exceptions. Resolve again for every distinct ODD task and every resume before launching its worker. Forward the resolved `strict-tdd`, `standard`, or `skip` MODE, the canonical rubric source, applicable exact commands, skill paths, and required disciplines/evidence in the parent launch prompt. Preserve declared phase bindings: an unknown, conflicting, or ambiguous binding, command, source, matching rule, precedence, exception, or MODE requires focused clarification; never invent a generic ODD command, precedence, exception, implicit policy activation, or MODE coercion.

`strict-tdd` means a full test-first cycle and maps native binary test-first activation to enabled. Require observed RED, GREEN, TRIANGULATE, and REFACTOR with its declared obligations. `standard` requires declared evidence without mandatory test-first ordering and maps that binary activation to disabled while preserving every applicable check and evidence obligation. `skip` has no automated test gate unless applicable rows union evidence; it maps test-first activation to disabled while preserving that union and native ordinary validation. Binary test-first activation represents sequencing only; it never replaces the resolved MODE or complete evidence obligation.

For every supported resolved row, forward native ODD inputs: test-first activation, canonical source, and exact runner. The canonical source is the rubric locator. The exact runner is the one declared applicable test-first command for `strict-tdd`, and `not-applicable` for `standard` or `skip` rather than an invented command. Forward the actual MODE and all phase-applicable exact commands, skill paths, and evidence alongside those native inputs; this uses existing declared policy data and requires no new schema. If an exact ODD binding cannot be supplied, stop only that dependent worker launch and ask focused clarification; never repurpose an SDD command.

If no approved rubric exists, use the existing configured or user-selected ODD mode, source, and exact runner. Tests or frameworks being present do not activate TDD. Continue ordinary functional checks when native test-first activation is disabled, and do not invoke `sdd-init` to resolve ODD TDD. An absent rubric is not invalid or conflicting. Required-but-missing, invalid, ambiguous, or conflicting approved-rubric state is a clarification boundary, not fallback authority.

The task document records resolved context and evidence; it does not replace the authoritative policy. Refresh the resolved instruction before each distinct task or resume, while retaining native ODD tracking, the full project Engram mirror, and parent reconciliation. Do not alter native ODD tracking, the full project Engram mirror, resume reconciliation, generic workers, or the RDD sequence. This prompt delivery does not prove autonomous worker compliance.
<!-- /gentle-ai:pi-odd-forwarding -->
EOF
)"

[ -n "$RUBRIC_ITEM4" ] && [ -n "$RUBRIC_PROSE" ] && [ -n "$RUBRIC_PROSE_PREVIOUS" ] && [ -n "$CACHE_NEW" ] && [ -n "$RUBRIC_PI_WORKFLOW" ] && [ -n "$RUBRIC_PI_ODD_FORWARDING" ] || {
  echo "FATAL: $RUBRIC_FILE is missing one of the shape blocks" >&2; exit 1; }

# Anchor: last item of the numbered list. Item 4 is appended directly after it.
# Prefix match -- hosts differ in the tail ("(sub-agent uses Standard Mode)." vs
# "(use Standard Mode)." vs nothing at all in opencode.json).
ANCHOR_ITEM3='3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'

# Anchor: claude-code's condensed prose form, which has no numbered list.
ANCHOR_PROSE='When launching `sdd-apply` or `sdd-verify`, search for testing capabilities'

# Verified gentle-pi@2.4.0 lazy workflow structure. The binary forwarding contract is
# deliberately not rewritten; the Pi-only marker block is inserted immediately
# after it and before the following archive section.
PI_WORKFLOW_HEADING='## Strict TDD Forwarding'
PI_WORKFLOW_ARCHIVE='## Archive Final-State Handoff'
PI_WORKFLOW_MARK_OPEN='<!-- gentle-ai:pi-rubric-forwarding -->'
PI_WORKFLOW_MARK_CLOSE='<!-- /gentle-ai:pi-rubric-forwarding -->'
PI_WORKFLOW_BINARY='For `sdd-apply` and `sdd-verify`, read `openspec/config.yaml` when present.

If it declares strict TDD and a test command, include a non-negotiable instruction in the phase prompt:

```text
STRICT TDD MODE IS ACTIVE. Test runner: <command>. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.
```

Do not rely on the child agent to discover this independently.'

# Official gentle-shell v3.1.0 anchors for the package-owned ODD delegation
# surface. Packages that do not carry the ODD section are deliberately n/a.
PI_ODD_HEADING='### Organic Driven Development (ODD)'
PI_ODD_CHECKS='#### Checks and candidate consent'
PI_ODD_DELEGATION='### Delegation Rules'
PI_ODD_MARK_OPEN='<!-- gentle-ai:pi-odd-forwarding -->'
PI_ODD_MARK_CLOSE='<!-- /gentle-ai:pi-odd-forwarding -->'

# The weaker caching sentence some hosts carry. Upgraded in place where present,
# so the rubric is explicitly part of what gets cached. Never invented where absent.
CACHE_OLD='The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.'
# This older managed cache-family prefix is a sentinel only: its one exact known
# sentence above is migrated, while truncated or customized variants refuse.
CACHE_OLDER_SENTINEL='The orchestrator resolves TDD status ONCE per session'
# Exact cache sentence emitted by base 8f030e8. Upgraded only when present.
CACHE_PREVIOUS='The orchestrator consumes validated rubric state ONCE per session (at first apply/verify launch) and caches it, classifying each apply slice by declared intent corroborated by its diff.'

# Transform for hosts WITH the numbered list. Idempotent:
#   - inserts item 4 after item 3 when item 4 is absent
#   - replaces an existing item 4 and its indented continuation lines
#   - drops the legacy loose paragraph (and the blank line it leaves behind)
#   - upgrades exact known predecessor caching sentences only where they exist
# Exits 1 if the list anchor is gone (gentle-ai reshaped the template).
rubric_transform_list() {
  ITEM4="$RUBRIC_ITEM4" PREVIOUS="$RUBRIC_ITEM4_HEAD_PREVIOUS" LEGACY="$RUBRIC_ITEM4_LEGACY" \
  PROSE="$RUBRIC_PROSE" A3="$ANCHOR_ITEM3" C_OLD="$CACHE_OLD" C_OLDER_SENTINEL="$CACHE_OLDER_SENTINEL" C_HEAD="$CACHE_HEAD_PREVIOUS" \
  C_PREVIOUS="$CACHE_PREVIOUS" C_NEW="$CACHE_NEW" awk '
    BEGIN {
      item4 = ENVIRON["ITEM4"]; previous = ENVIRON["PREVIOUS"]; legacy = ENVIRON["LEGACY"]
      prose = ENVIRON["PROSE"]; a3 = ENVIRON["A3"]; c_old = ENVIRON["C_OLD"]
      c_older_sentinel = ENVIRON["C_OLDER_SENTINEL"]
      c_head = ENVIRON["C_HEAD"]; c_previous = ENVIRON["C_PREVIOUS"]; c_new = ENVIRON["C_NEW"]
    }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (index(line[i], a3) == 1) { anchors++; anchor = i }
        if (line[i] == prose) { loose++; loose_at = i }
        if (line[i] == c_new) { caches++; cache_at = i; cache_kind = "new" }
        if (line[i] == c_old) { caches++; cache_at = i; cache_kind = "old" }
        if (line[i] == c_head) { caches++; cache_at = i; cache_kind = "head" }
        if (line[i] == c_previous) { caches++; cache_at = i; cache_kind = "previous" }
        if (index(line[i], "approved workflow-neutral project-policy authority") || \
            index(line[i], "canonical `sdd-init` authoritative policy") || \
            index(line[i], "RubricConsumerEnvelopeV1") || \
            index(line[i], "The orchestrator reads the canonical `sdd-init` authoritative policy") || \
            index(line[i], "The orchestrator consumes validated rubric state") || \
            index(line[i], c_older_sentinel)) sentinel[i] = 1
      }
      if (anchors != 1 || loose > 1 || caches > 1) exit 1
      item_start = anchor + 1
      if (item_start <= n && line[item_start] ~ /^4\. \*\*Additional condition/) {
        item_end = item_start + 1
        while (item_end <= n && line[item_end] ~ /^[ \t]+/) item_end++
        candidate = line[item_start]
        for (i = item_start + 1; i < item_end; i++) candidate = candidate "\n" line[i]
        if (candidate != item4 && candidate != previous && candidate != legacy) exit 1
        have4 = 1
      }
      # A managed-looking item anywhere except immediately after item 3 is an
      # out-of-order, duplicate, or custom predecessor and must fail closed.
      for (i = 1; i <= n; i++) if (i != item_start && line[i] ~ /^4\. \*\*Additional condition/) exit 1
      if (loose && have4) exit 1
      for (i = 1; i <= n; i++) {
        if (sentinel[i] && !(have4 && i >= item_start && i < item_end) && i != cache_at && i != loose_at) exit 1
      }
      if (loose) {
        drop[loose_at] = 1
        if (line[loose_at - 1] ~ /^[ \t]*$/ && line[loose_at + 1] ~ /^[ \t]*$/) drop[loose_at + 1] = 1
      }
      for (i = 1; i <= n; i++) {
        if (have4 && i == item_start) { print item4; i = item_end - 1; continue }
        if (drop[i]) continue
        if (i == cache_at && cache_kind != "new") print c_new
        else print line[i]
        if (i == anchor && !have4) print item4
      }
      exit 0
    }
  '
}

# Transform for claude-code's condensed workflow. Current, immediate-HEAD, and
# older exact predecessor payloads are accepted once each; every mixed, duplicate,
# partial, or custom managed payload refuses before a write.
rubric_transform_prose() {
  PROSE="$RUBRIC_PROSE" HEAD_PREVIOUS="$RUBRIC_PROSE_HEAD_PREVIOUS" PREVIOUS="$RUBRIC_PROSE_PREVIOUS" AP="$ANCHOR_PROSE" awk '
    BEGIN { prose = ENVIRON["PROSE"]; head_previous = ENVIRON["HEAD_PREVIOUS"]; previous = ENVIRON["PREVIOUS"]; ap = ENVIRON["AP"] }
    { line[NR] = $0 }
    END {
      n = NR
      for (i = 1; i <= n; i++) {
        if (index(line[i], ap) == 1) { anchors++; anchor = i }
        if (line[i] == prose) { forms++; current = 1; current_at = i }
        if (line[i] == head_previous) { forms++; prior_at = i }
        if (line[i] == previous) { forms++; prior_at = i }
        if (index(line[i], "approved workflow-neutral project-policy authority") || \
            index(line[i], "canonical `sdd-init` authoritative policy") || \
            index(line[i], "RubricConsumerEnvelopeV1") || \
            index(line[i], "For each `sdd-apply` or `sdd-verify` work slice")) sentinel[i] = 1
      }
      if (anchors != 1 || forms > 1) exit 1
      for (i = 1; i <= n; i++) if (sentinel[i] && i != current_at && i != prior_at) exit 1
      for (i = 1; i <= n; i++) {
        if (i == prior_at) print prose
        else print line[i]
        if (i == anchor && !current && !prior_at) { print ""; print prose }
      }
      exit 0
    }
  '
}

# Pi's lazy workflow carries its own exact binary Strict TDD contract. Preserve
# that contract byte-for-byte and manage only this overlay-owned block after it.
# The structure is fail-closed: each anchor must be unique and ordered, and a
# marker pair must be absent or exactly one complete pair in the allowed gap.
pi_rubric_workflow_transform_raw() {
  BLOCK="$RUBRIC_PI_WORKFLOW" HEADING="$PI_WORKFLOW_HEADING" ARCHIVE="$PI_WORKFLOW_ARCHIVE" \
  BINARY="$PI_WORKFLOW_BINARY" OPEN_MARKER="$PI_WORKFLOW_MARK_OPEN" CLOSE_MARKER="$PI_WORKFLOW_MARK_CLOSE" \
    awk '
      BEGIN {
        block = ENVIRON["BLOCK"]; heading = ENVIRON["HEADING"]; archive = ENVIRON["ARCHIVE"]
        binary = ENVIRON["BINARY"]; open_marker = ENVIRON["OPEN_MARKER"]; close_marker = ENVIRON["CLOSE_MARKER"]
        binary_lines = split(binary, binary_line, "\n")
      }
      { line[NR] = $0 }
      END {
        n = NR
        for (i = 1; i <= n; i++) {
          if (line[i] == heading) { headings++; heading_line = i }
          if (line[i] == archive) { archives++; archive_line = i }
          if (line[i] == open_marker) { opens++; open_line = i }
          if (line[i] == close_marker) { closes++; close_line = i }
          if (index(line[i], "gentle-ai:pi-rubric-forwarding") && line[i] != open_marker && line[i] != close_marker) malformed_marker = 1
        }
        for (i = 1; i <= n - binary_lines + 1; i++) {
          matches = 1
          for (j = 1; j <= binary_lines; j++) if (line[i + j - 1] != binary_line[j]) matches = 0
          if (matches) { binaries++; binary_start = i; binary_end = i + binary_lines - 1 }
        }
        if (headings != 1 || archives != 1 || binaries != 1 || malformed_marker || \
            heading_line >= binary_start || binary_end >= archive_line) exit 1
        if (opens != closes || opens > 1 || (opens == 1 && open_line >= close_line)) exit 1
        if (opens == 1 && (open_line <= binary_end || close_line >= archive_line || \
                           (heading_line >= open_line && heading_line <= close_line) || \
                           (binary_start >= open_line && binary_start <= close_line) || \
                           (archive_line >= open_line && archive_line <= close_line))) exit 1
        for (i = binary_end + 1; i < archive_line; i++) {
          if (opens == 1 && i >= open_line && i <= close_line) continue
          if (line[i] !~ /^[ \t]*$/) exit 1
        }

        for (i = 1; i <= n; i++) {
          if (i <= binary_end) { print line[i]; continue }
          if (i > binary_end && i < archive_line) continue
          if (i == archive_line) { print ""; print block; print ""; print line[i]; continue }
          print line[i]
        }
        exit 0
      }
    '
}

# Preserve the source terminal-newline state after the line-oriented structural
# transforms. This is intentionally byte-scoped: all interior bytes are emitted
# by the validated transform, then only its artificial trailing LF is removed.
pi_preserve_terminal_newline() {
  local transform="$1" source output rc
  source="$(mktemp "${TMPDIR:-/tmp}/gentle-ai-overlay-source.XXXXXX")" || return 4
  output="$(mktemp "${TMPDIR:-/tmp}/gentle-ai-overlay-output.XXXXXX")" || { rm -f -- "$source"; return 4; }
  cat > "$source"
  "$transform" < "$source" > "$output"; rc=$?
  if [ "$rc" -eq 0 ] && ! python3 - "$source" "$output" <<'PY'
import pathlib
import sys
source = pathlib.Path(sys.argv[1]).read_bytes()
output = pathlib.Path(sys.argv[2])
result = output.read_bytes()
if not source.endswith(b"\n") and result.endswith(b"\n"):
    output.write_bytes(result[:-1])
PY
  then
    rc=4
  fi
  [ "$rc" -eq 0 ] && cat "$output"
  rm -f -- "$source" "$output"
  return "$rc"
}

pi_rubric_workflow_transform() { pi_byte_transform workflow; }

# ---------------------------------------------------------------------------
# Pi ODD delegation forwarding.
#
# This overlay owns only its marker-delimited parent instruction. The three
# release anchors remain installer-owned and are validated before a replacement;
# package versions without the ODD section return 2 (n/a), not an error.
# ---------------------------------------------------------------------------
pi_odd_forwarding_transform_raw() {
  BLOCK="$RUBRIC_PI_ODD_FORWARDING" HEADING="$PI_ODD_HEADING" CHECKS="$PI_ODD_CHECKS" \
  DELEGATION="$PI_ODD_DELEGATION" OPEN_MARKER="$PI_ODD_MARK_OPEN" CLOSE_MARKER="$PI_ODD_MARK_CLOSE" \
    awk '
      BEGIN {
        block = ENVIRON["BLOCK"]; heading = ENVIRON["HEADING"]
        checks = ENVIRON["CHECKS"]; delegation = ENVIRON["DELEGATION"]
        open_marker = ENVIRON["OPEN_MARKER"]; close_marker = ENVIRON["CLOSE_MARKER"]
      }
      { line[NR] = $0 }
      END {
        n = NR
        for (i = 1; i <= n; i++) {
          if (line[i] == heading) { headings++; heading_line = i }
          if (line[i] == checks) { check_sections++; checks_line = i }
          if (line[i] == delegation) { delegations++; delegation_line = i }
          if (line[i] == open_marker) { opens++; open_line = i }
          if (line[i] == close_marker) { closes++; close_line = i }
          if (index(line[i], "gentle-ai:pi-odd-forwarding") && line[i] != open_marker && line[i] != close_marker) malformed_marker = 1
        }

        # Older packages have no ODD section or managed marker. Leave them fully
        # untouched; their absence is not an unsupported or broken variant.
        if (headings == 0 && opens == 0 && closes == 0 && !malformed_marker) exit 2

        if (headings != 1 || check_sections != 1 || delegations != 1 || malformed_marker || \
            heading_line >= checks_line || checks_line >= delegation_line) exit 1
        if (opens != closes || opens > 1 || (opens == 1 && open_line >= close_line)) exit 1
        if (opens == 1 && (open_line <= checks_line || close_line >= delegation_line || \
                           heading_line >= open_line || checks_line >= open_line || delegation_line <= close_line)) exit 1

        for (i = 1; i <= n; i++) {
          if (opens == 1 && i == open_line) {
            print block
            continue
          }
          if (opens == 1 && i > open_line && i <= close_line) continue
          if (opens == 0 && i == delegation_line) {
            print block
            print ""
          }
          print line[i]
        }
        exit 0
      }
    '
}

pi_odd_forwarding_transform() { pi_byte_transform odd; }

odd_forwarding_apply() {
  local file="$1" tmp snapshot rc
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi
  pi_odd_forwarding_transform < "$snapshot" > "$tmp"; rc=$?
  case "$rc" in
    0) ;;
    2) rm -f -- "$tmp" "$snapshot"; return 2 ;;
    *) rm -f -- "$tmp" "$snapshot"; return 3 ;;
  esac
  if cmp -s "$tmp" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 1
  fi
  if [ "$CHECK_ONLY" -eq 1 ]; then rm -f -- "$tmp" "$snapshot"; return 0; fi
  commit_replacement "$file" "$snapshot" "$tmp"; rc=$?
  rm -f -- "$tmp" "$snapshot"
  return "$rc"
}

# ---------------------------------------------------------------------------
# OpenCode Engram source block.
# ---------------------------------------------------------------------------
OPENCODE_ENGRAM_BLOCK="$(extract_shape_from "$OPENCODE_ENGRAM_FILE" block)"
OPENCODE_ENGRAM_STOCK_BLOCK='    "experimental.chat.system.transform": async (input, output) => {
      if (output.system.length > 0) {
        output.system[output.system.length - 1] += "\n\n" + MEMORY_INSTRUCTIONS
      } else {
        output.system.push(MEMORY_INSTRUCTIONS)
      }'

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
# This source delta is security-sensitive input to every producer surface.
# The `pi` shape is immutable historical recognition data; the distinct neutral
# `gentle-init-pi` shape is the only future Pi insertion payload.
extract_init_rubric_shape() {
  local wanted="$1"
  awk -v wanted="$wanted" '
    BEGIN { expected["skill"] = expected["details"] = expected["pi"] = expected["gentle-init-pi"] = 1 }
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
# Exact historical bytes: use only to recognize and retire a prior Pi block.
INIT_RUBRIC_PI="$(extract_init_rubric_shape pi)" || { echo "FATAL: invalid $INIT_RUBRIC_FILE shape markers" >&2; exit 1; }
# Neutral future bytes: use only to insert or refresh the gentle-init block.
GENTLE_INIT_RUBRIC_PI="$(extract_init_rubric_shape gentle-init-pi)" || { echo "FATAL: invalid $INIT_RUBRIC_FILE shape markers" >&2; exit 1; }
INIT_RUBRIC_OPEN='<!-- gentle-ai:sdd-init-rubric -->'
INIT_RUBRIC_CLOSE='<!-- /gentle-ai:sdd-init-rubric -->'
GENTLE_INIT_RUBRIC_OPEN='<!-- gentle-ai:gentle-init-rubric -->'
GENTLE_INIT_RUBRIC_CLOSE='<!-- /gentle-ai:gentle-init-rubric -->'

[ -n "$INIT_RUBRIC_SKILL" ] && [ -n "$INIT_RUBRIC_DETAILS" ] && [ -n "$INIT_RUBRIC_PI" ] && [ -n "$GENTLE_INIT_RUBRIC_PI" ] || {
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

# ---------------------------------------------------------------------------
# Pi gentle-init capability migration.
#
# The future regular package target is validated before the legacy sibling is
# considered. Both candidates are built before any backup or replacement.
# ---------------------------------------------------------------------------
PI_GENTLE_INIT_PUBLICATION_BOUNDARY='## Publication boundary'

# These Pi asset transforms are byte-oriented: markdown may deliberately lack a
# final newline, so line-oriented tools would rewrite accepted upstream bytes.
# Python is validated at this narrow capability boundary rather than becoming a
# global overlay dependency for current packages that lack gentle-init.
pi_byte_transform() {
  local rc
  command -v python3 >/dev/null 2>&1 || return 12
  python3 --version >/dev/null 2>&1 || return 12
  MODE="$1" BLOCK="$GENTLE_INIT_RUBRIC_PI" LEGACY="$INIT_RUBRIC_PI" \
  ANCHOR="$PI_GENTLE_INIT_PUBLICATION_BOUNDARY" GENTLE_OPEN="$GENTLE_INIT_RUBRIC_OPEN" \
  GENTLE_CLOSE="$GENTLE_INIT_RUBRIC_CLOSE" LEGACY_OPEN="$INIT_RUBRIC_OPEN" \
  LEGACY_CLOSE="$INIT_RUBRIC_CLOSE" WORKFLOW_BLOCK="$RUBRIC_PI_WORKFLOW" \
  WORKFLOW_PREVIOUS="$RUBRIC_PI_WORKFLOW_HEAD_PREVIOUS" ODD_BLOCK="$RUBRIC_PI_ODD_FORWARDING" \
  ODD_PREVIOUS="$RUBRIC_PI_ODD_FORWARDING_HEAD_PREVIOUS" WORKFLOW_HEADING="$PI_WORKFLOW_HEADING" \
  WORKFLOW_ARCHIVE="$PI_WORKFLOW_ARCHIVE" WORKFLOW_BINARY="$PI_WORKFLOW_BINARY" \
  WORKFLOW_OPEN="$PI_WORKFLOW_MARK_OPEN" WORKFLOW_CLOSE="$PI_WORKFLOW_MARK_CLOSE" \
  ODD_HEADING="$PI_ODD_HEADING" ODD_CHECKS="$PI_ODD_CHECKS" ODD_DELEGATION="$PI_ODD_DELEGATION" \
  ODD_OPEN="$PI_ODD_MARK_OPEN" ODD_CLOSE="$PI_ODD_MARK_CLOSE" python3 -c '
import os
import sys

mode = os.environ["MODE"]
data = sys.stdin.buffer.read()
def text(name):
    return os.environ[name].encode("utf-8")
def bare(line):
    if line.endswith(b"\r\n"):
        return line[:-2]
    if line.endswith(b"\n"):
        return line[:-1]
    return line
def line_end(line):
    return b"\r\n" if line.endswith(b"\r\n") else b"\n"
def exact_indices(lines, value):
    return [i for i, line in enumerate(lines) if bare(line) == value]
def marker_indices(lines, marker, opening, closing):
    malformed = any(marker in bare(line) and bare(line) not in (opening, closing) for line in lines)
    return exact_indices(lines, opening), exact_indices(lines, closing), malformed
def rendered_block(value, ending):
    return ending.join(value.split(b"\n")) + ending
def replace_recognized(lines, opening, closing, marker, current, predecessor, start, end, ending):
    opens, closes, malformed = marker_indices(lines, marker, opening, closing)
    if malformed or len(opens) != len(closes) or len(opens) > 1:
        raise SystemExit(1)
    # The workflow gap is upstream-owned but must remain blank whether this
    # transform inserts its marker or replaces one it already recognizes. Tabs
    # and any number of blank lines remain accepted and byte-preserved.
    if marker == b"gentle-ai:pi-rubric-forwarding":
        for index in range(start + 1, end):
            if opens and opens[0] <= index <= closes[0]:
                continue
            if bare(lines[index]).strip(b" \t"):
                raise SystemExit(1)
    if opens:
        if opens[0] >= closes[0] or not (start < opens[0] and closes[0] < end):
            raise SystemExit(1)
        managed = b"".join(lines[opens[0]:closes[0] + 1])
        if managed not in (rendered_block(current, ending), rendered_block(predecessor, ending)):
            raise SystemExit(1)
        lines[opens[0]:closes[0] + 1] = [rendered_block(current, ending)]
    else:
        # Insertion is at the verified anchor; every pre-existing byte stays put.
        lines[end:end] = [rendered_block(current, ending), ending]
    return lines
lines = data.splitlines(keepends=True)
if mode == "gentle":
    anchor = text("ANCHOR")
    opening = text("GENTLE_OPEN")
    closing = text("GENTLE_CLOSE")
    marker = b"gentle-ai:gentle-init-rubric"
    anchors = exact_indices(lines, anchor)
    opens, closes, malformed = marker_indices(lines, marker, opening, closing)
    legacy_opens, legacy_closes, legacy_malformed = marker_indices(lines, b"gentle-ai:sdd-init-rubric", text("LEGACY_OPEN"), text("LEGACY_CLOSE"))
    if len(anchors) != 1 or malformed or legacy_opens or legacy_closes or legacy_malformed or len(opens) != len(closes) or len(opens) > 1:
        raise SystemExit(1)
    anchor_at = anchors[0]
    ending = line_end(lines[anchor_at])
    if opens:
        if opens[0] >= closes[0] or opens[0] >= anchor_at or closes[0] + 1 != anchor_at:
            raise SystemExit(1)
        managed = b"".join(lines[opens[0]:closes[0] + 1])
        if managed != text("BLOCK") + ending:
            raise SystemExit(1)
    else:
        lines[anchor_at:anchor_at] = [text("BLOCK") + ending]
elif mode == "legacy":
    opening = text("LEGACY_OPEN")
    closing = text("LEGACY_CLOSE")
    marker = b"gentle-ai:sdd-init-rubric"
    opens, closes, malformed = marker_indices(lines, marker, opening, closing)
    if malformed or len(opens) != len(closes) or len(opens) > 1:
        raise SystemExit(1)
    if opens:
        if opens[0] >= closes[0]:
            raise SystemExit(1)
        ending = line_end(lines[opens[0]])
        managed = b"".join(lines[opens[0]:closes[0] + 1])
        if managed != rendered_block(text("LEGACY"), ending):
            raise SystemExit(1)
        after = closes[0] + 1
        if after >= len(lines) or lines[after] != ending or after + 1 >= len(lines) or bare(lines[after + 1]) != b"## Memory Contract":
            raise SystemExit(1)
        del lines[opens[0]:after + 1]
elif mode == "workflow":
    heading = text("WORKFLOW_HEADING")
    archive = text("WORKFLOW_ARCHIVE")
    binary = text("WORKFLOW_BINARY").split(b"\n")
    headings = exact_indices(lines, heading)
    archives = exact_indices(lines, archive)
    matches = [i for i in range(len(lines) - len(binary) + 1) if [bare(line) for line in lines[i:i + len(binary)]] == binary]
    if len(headings) != 1 or len(archives) != 1 or len(matches) != 1 or not (headings[0] < matches[0] and matches[0] + len(binary) - 1 < archives[0]):
        raise SystemExit(1)
    ending = line_end(lines[archives[0]])
    lines = replace_recognized(lines, text("WORKFLOW_OPEN"), text("WORKFLOW_CLOSE"), b"gentle-ai:pi-rubric-forwarding", text("WORKFLOW_BLOCK"), text("WORKFLOW_PREVIOUS"), matches[0] + len(binary) - 1, archives[0], ending)
elif mode == "odd":
    heading = text("ODD_HEADING")
    checks = text("ODD_CHECKS")
    delegation = text("ODD_DELEGATION")
    headings = exact_indices(lines, heading)
    check_sections = exact_indices(lines, checks)
    delegations = exact_indices(lines, delegation)
    opens, closes, malformed = marker_indices(lines, b"gentle-ai:pi-odd-forwarding", text("ODD_OPEN"), text("ODD_CLOSE"))
    if not headings and not opens and not closes and not malformed:
        raise SystemExit(2)
    if len(headings) != 1 or len(check_sections) != 1 or len(delegations) != 1 or not (headings[0] < check_sections[0] < delegations[0]):
        raise SystemExit(1)
    ending = line_end(lines[delegations[0]])
    lines = replace_recognized(lines, text("ODD_OPEN"), text("ODD_CLOSE"), b"gentle-ai:pi-odd-forwarding", text("ODD_BLOCK"), text("ODD_PREVIOUS"), check_sections[0], delegations[0], ending)
else:
    raise SystemExit(1)
sys.stdout.buffer.write(b"".join(lines))
'
  rc=$?
  case "$rc" in 126|127) return 12 ;; *) return "$rc" ;; esac
}

gentle_init_rubric_transform() { pi_byte_transform gentle; }
pi_legacy_sdd_init_retire_transform() { pi_byte_transform legacy; }

# Test-only fault injection requires both an explicit test-mode gate and a
# named token. A hook token by itself is ignored in normal operation; the hooks
# avoid permission-based failure simulation, which is unreliable under root.
pair_test_hook() {
  [ "${GENTLE_AI_TEST_MODE:-}" = 1 ] || return 1
  case ",${GENTLE_AI_TEST_PAIR_HOOK:-}," in *",$1,"*) return 0 ;; *) return 1 ;; esac
}

recovery_tmp() {
  local file="$1" dir base
  pair_test_hook recovery-alloc && return 1
  dir="$(dirname -- "$file")"
  base="$(basename -- "$file")"
  mktemp "$dir/.${base}.gentle-ai-recovery.XXXXXX"
}

# Commit a selected set of already-built candidates as one logical Pi transaction.
# Each tuple is file, preimage snapshot, candidate, and package-relative label.
# All replacements are staged before any backup; all changing targets are backed up
# before the first rename. A handled rename failure restores every replaced target.
PI_TRANSACTION_MIXED_TARGETS=''
PI_TRANSACTION_RECOVERY_ARTIFACTS=''
PI_TRANSACTION_VERIFIED_BACKUPS=''
PI_TRANSACTION_UNTOUCHED_DRIFT=''

pi_transaction_append_unique() {
  local variable="$1" value="$2" current
  eval "current=\${$variable}"
  case ",$current," in *",$value,"*) ;; *) eval "$variable=\${current}\${current:+,}\$value" ;; esac
}

pi_transaction_mark_mixed() { pi_transaction_append_unique PI_TRANSACTION_MIXED_TARGETS "$1"; }

pi_transaction_record_verified_backup() {
  local file="$1" snapshot="$2" rel backup_file
  rel="${file#"$HOME"/}"
  backup_file="$BACKUP_ROOT/$rel"
  [ -f "$backup_file" ] && [ ! -L "$backup_file" ] && cmp -s "$snapshot" "$backup_file" || return 1
  pi_transaction_append_unique PI_TRANSACTION_VERIFIED_BACKUPS "$backup_file"
}

# A retained recovery path is reported only after a preimage copy and exact byte
# comparison succeeded. An unchanged participant has no transaction backup; it is
# reported separately if it drifts rather than being mislabeled backup-only.
pi_transaction_restore_target() {
  local root="$1" file="$2" snapshot="$3" candidate="$4" label="$5" recovery
  if ! pi_group_safe_target "$root" "$file" || ! cmp -s "$file" "$candidate"; then
    pi_transaction_mark_mixed "$label"
    return 0
  fi
  recovery="$(recovery_tmp "$file")" || { pi_transaction_mark_mixed "$label"; return 0; }
  if pair_test_hook recovery-copy || ! cp -p -- "$snapshot" "$recovery" || ! cmp -s "$snapshot" "$recovery"; then
    rm -f -- "$recovery"
    pi_transaction_mark_mixed "$label"
    return 0
  fi
  if pair_test_hook rollback || pair_test_hook "rollback-${label}" || ! mv -f -- "$recovery" "$file"; then
    pi_transaction_mark_mixed "$label"
    if [ -f "$recovery" ] && [ ! -L "$recovery" ] && cmp -s "$snapshot" "$recovery"; then
      pi_transaction_append_unique PI_TRANSACTION_RECOVERY_ARTIFACTS "$recovery"
    fi
  fi
}

pi_transaction_recovery_report() {
  [ -n "$PI_TRANSACTION_RECOVERY_ARTIFACTS" ] && printf 'verified recovery artifacts: %s; ' "$PI_TRANSACTION_RECOVERY_ARTIFACTS"
  [ -n "$PI_TRANSACTION_VERIFIED_BACKUPS" ] && printf 'verified backups: %s; ' "$PI_TRANSACTION_VERIFIED_BACKUPS"
  [ -n "$PI_TRANSACTION_UNTOUCHED_DRIFT" ] && printf 'concurrently changed untouched participants without verified recovery: %s' "$PI_TRANSACTION_UNTOUCHED_DRIFT" || printf 'no unverified untouched participants'
}

commit_replacement_group() {
  # Every tuple participates in drift detection, including byte-identical
  # candidates. Only changed tuples are staged, backed up, and renamed.
  local root="$1" count="$2" i j file snapshot candidate label stage rc=0
  local -a files=() snapshots=() candidates=() labels=() stages=() replaced=() changed=()
  PI_TRANSACTION_MIXED_TARGETS=''
  PI_TRANSACTION_RECOVERY_ARTIFACTS=''
  PI_TRANSACTION_VERIFIED_BACKUPS=''
  PI_TRANSACTION_UNTOUCHED_DRIFT=''
  shift 2
  for ((i = 0; i < count; i++)); do
    files[i]="$1"; snapshots[i]="$2"; candidates[i]="$3"; labels[i]="$4"; shift 4
    if pair_test_hook "drift-stage-${labels[i]}"; then printf 'concurrent %s edit\n' "${labels[i]}" > "${files[i]}"; fi
    pi_group_safe_target "$root" "${files[i]}" && cmp -s "${files[i]}" "${snapshots[i]}" || {
      for stage in "${stages[@]}"; do [ -z "${stage:-}" ] || rm -f -- "$stage"; done
      return 5
    }
    if ! cmp -s "${candidates[i]}" "${snapshots[i]}"; then
      changed[i]=1
      stages[i]="$(target_tmp "${files[i]}")" || { rc=7; break; }
      if ! cp -p -- "${files[i]}" "${stages[i]}" || ! cat "${candidates[i]}" > "${stages[i]}" || ! cmp -s "${candidates[i]}" "${stages[i]}"; then rc=7; break; fi
    fi
  done
  if [ "$rc" -ne 0 ]; then
    for stage in "${stages[@]}"; do [ -z "${stage:-}" ] || rm -f -- "$stage"; done
    return "$rc"
  fi
  for ((i = 0; i < count; i++)); do
    [ "${changed[i]:-0}" -eq 1 ] || continue
    if pair_test_hook "backup-${labels[i]}" || ! backup "${files[i]}" "${snapshots[i]}" || ! pi_transaction_record_verified_backup "${files[i]}" "${snapshots[i]}"; then
      for stage in "${stages[@]}"; do [ -z "${stage:-}" ] || rm -f -- "$stage"; done
      return 7
    fi
  done
  # A test-only hook models a concurrent editor after backups. It is deliberately
  # unavailable outside explicit test mode.
  for ((i = 0; i < count; i++)); do
    if pair_test_hook "drift-backup-${labels[i]}"; then printf '%s\n' "concurrent ${labels[i]} edit" > "${files[i]}"; fi
  done
  # Validate all participants after the last backup and before the first rename.
  for ((i = 0; i < count; i++)); do
    if ! pi_group_safe_target "$root" "${files[i]}" || ! cmp -s "${files[i]}" "${snapshots[i]}"; then
      for stage in "${stages[@]}"; do [ -z "${stage:-}" ] || rm -f -- "$stage"; done
      return 5
    fi
  done
  for ((i = 0; i < count; i++)); do
    [ "${changed[i]:-0}" -eq 1 ] || continue
    # Revalidate immediately before this replacement so a changed future target
    # is never overwritten after an earlier rename.
    if ! pi_group_safe_target "$root" "${files[i]}" || ! cmp -s "${files[i]}" "${snapshots[i]}"; then
      rc=5
    elif pair_test_hook "rename-${labels[i]}" || ! mv -f -- "${stages[i]}" "${files[i]}"; then
      rc=7
    else
      replaced+=("$i")
      if [ "${#replaced[@]}" -eq 1 ] && pair_test_hook drift-after-first-rename-delegation; then
        for ((j = 0; j < count; j++)); do [ "${labels[j]}" = delegation ] && printf '%s\n' 'concurrent delegation edit' > "${files[j]}"; done
      fi
      continue
    fi
    [ -z "${stages[i]:-}" ] || rm -f -- "${stages[i]}"
      for stage in "${stages[@]}"; do [ -z "${stage:-}" ] || rm -f -- "$stage"; done
      for ((j = ${#replaced[@]} - 1; j >= 0; j--)); do
        i="${replaced[j]}"; file="${files[i]}"; snapshot="${snapshots[i]}"; candidate="${candidates[i]}"; label="${labels[i]}"
        # Never roll back over a concurrent edit made after our replacement.
        pi_transaction_restore_target "$root" "$file" "$snapshot" "$candidate" "$label"
      done
      [ -n "$PI_TRANSACTION_MIXED_TARGETS" ] && return 8
      return "$rc"
  done
  # Unchanged participants remain protected until the final success decision.
  for ((i = 0; i < count; i++)); do
    [ "${changed[i]:-0}" -eq 1 ] && continue
    if pair_test_hook "drift-final-${labels[i]}"; then printf 'concurrent %s edit\n' "${labels[i]}" > "${files[i]}"; fi
    if ! pi_group_safe_target "$root" "${files[i]}" || ! cmp -s "${files[i]}" "${snapshots[i]}"; then
      pi_transaction_append_unique PI_TRANSACTION_UNTOUCHED_DRIFT "${labels[i]}"
      for ((j = ${#replaced[@]} - 1; j >= 0; j--)); do
        i="${replaced[j]}"; file="${files[i]}"; snapshot="${snapshots[i]}"; candidate="${candidates[i]}"; label="${labels[i]}"
        pi_transaction_restore_target "$root" "$file" "$snapshot" "$candidate" "$label"
      done
      [ -n "$PI_TRANSACTION_MIXED_TARGETS" ] && return 8
      return 5
    fi
  done
  return 0
}

# Future Pi migration is one four-surface transaction rooted at the configured
# package. Current packages without gentle-init never enter this function.
pi_gentle_init_transaction_apply() {
  local gentle_file="$1" legacy_file="$2" workflow_file="$3" delegation_file="$4" root
  local gentle_tmp legacy_tmp workflow_tmp delegation_tmp gentle_snapshot legacy_snapshot workflow_snapshot delegation_snapshot rc count=0 file
  local delegation_present=0
  local -a args
  root="$(dirname -- "$(dirname -- "$(dirname -- "$gentle_file")")")"
  for file in "$gentle_file" "$legacy_file" "$workflow_file"; do pi_group_safe_target "$root" "$file" || return 4; done
  if [ -e "$delegation_file" ] || [ -L "$delegation_file" ]; then
    pi_group_safe_target "$root" "$delegation_file" || return 4
    delegation_present=1
  fi
  PI_TRANSACTION_ODD_STATUS=''
  gentle_snapshot="$(target_tmp "$gentle_file")" || return 4
  legacy_snapshot="$(target_tmp "$legacy_file")" || { rm -f -- "$gentle_snapshot"; return 4; }
  workflow_snapshot="$(target_tmp "$workflow_file")" || { rm -f -- "$gentle_snapshot" "$legacy_snapshot"; return 4; }
  if [ "$delegation_present" -eq 1 ]; then
    delegation_snapshot="$(target_tmp "$delegation_file")" || { rm -f -- "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot"; return 4; }
  fi
  if ! cp -p -- "$gentle_file" "$gentle_snapshot" || ! cp -p -- "$legacy_file" "$legacy_snapshot" || ! cp -p -- "$workflow_file" "$workflow_snapshot" || \
     { [ "$delegation_present" -eq 1 ] && ! cp -p -- "$delegation_file" "$delegation_snapshot"; }; then
    rm -f -- "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "${delegation_snapshot:-}"
    return 4
  fi
  gentle_tmp="$(target_tmp "$gentle_file")" || { rm -f -- "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "${delegation_snapshot:-}"; return 4; }
  legacy_tmp="$(target_tmp "$legacy_file")" || { rm -f -- "$gentle_tmp" "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "${delegation_snapshot:-}"; return 4; }
  workflow_tmp="$(target_tmp "$workflow_file")" || { rm -f -- "$gentle_tmp" "$legacy_tmp" "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "${delegation_snapshot:-}"; return 4; }
  if [ "$delegation_present" -eq 1 ]; then
    delegation_tmp="$(target_tmp "$delegation_file")" || { rm -f -- "$gentle_tmp" "$legacy_tmp" "$workflow_tmp" "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "$delegation_snapshot"; return 4; }
  fi
  gentle_init_rubric_transform < "$gentle_snapshot" > "$gentle_tmp"; rc=$?
  if [ "$rc" -eq 0 ]; then pi_legacy_sdd_init_retire_transform < "$legacy_snapshot" > "$legacy_tmp"; rc=$?; fi
  if [ "$rc" -eq 0 ]; then pi_rubric_workflow_transform < "$workflow_snapshot" > "$workflow_tmp"; rc=$?; fi
  if [ "$rc" -eq 0 ] && [ "$delegation_present" -eq 1 ]; then
    pi_odd_forwarding_transform < "$delegation_snapshot" > "$delegation_tmp"; rc=$?
    if [ "$rc" -eq 2 ]; then
      if cp -p -- "$delegation_snapshot" "$delegation_tmp"; then rc=0; else rc=4; fi
      PI_TRANSACTION_ODD_STATUS=n/a
    fi
  elif [ "$delegation_present" -eq 0 ]; then
    PI_TRANSACTION_ODD_STATUS=n/a
  fi
  if [ "$rc" -ne 0 ]; then
    rm -f -- "$gentle_tmp" "$legacy_tmp" "$workflow_tmp" "${delegation_tmp:-}" "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "${delegation_snapshot:-}"
    [ "$rc" -eq 12 ] && return 12
    return 3
  fi
  args=("$gentle_file" "$gentle_snapshot" "$gentle_tmp" gentle-init "$legacy_file" "$legacy_snapshot" "$legacy_tmp" sdd-init "$workflow_file" "$workflow_snapshot" "$workflow_tmp" workflow)
  count=3
  if [ "$delegation_present" -eq 1 ]; then args+=("$delegation_file" "$delegation_snapshot" "$delegation_tmp" delegation); count=4; fi
  if cmp -s "$gentle_tmp" "$gentle_snapshot" && cmp -s "$legacy_tmp" "$legacy_snapshot" && cmp -s "$workflow_tmp" "$workflow_snapshot" && \
     { [ "$delegation_present" -eq 0 ] || cmp -s "$delegation_tmp" "$delegation_snapshot"; }; then
    rc=1
  elif [ "$CHECK_ONLY" -eq 1 ]; then
    rc=0
  else
    commit_replacement_group "$root" "$count" "${args[@]}"; rc=$?
  fi
  rm -f -- "$gentle_tmp" "$legacy_tmp" "$workflow_tmp" "${delegation_tmp:-}" "$gentle_snapshot" "$legacy_snapshot" "$workflow_snapshot" "${delegation_snapshot:-}"
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

# OpenCode supports exactly four hidden sdd-init shapes: the final 2.6.0
# executor prompt followed only by agent-language-contract, the final 2.5.0
# executor prompt with either no blocks or the ordered CodeGraph/agent-language
# pair, the rc.3 one-sentence inline prompt, and the old exact external reference.
# Managed block bodies remain installer-owned. Nothing else is executable.
opencode_sdd_init_mode() {
  local file="$1"
  local rc3_inline='Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly.'
  local final_paragraph="You are an SDD executor for the init phase, not the orchestrator. Do this phase's work yourself. Do NOT delegate, Do NOT call task, and Do NOT launch sub-agents. Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly."
  local external='{file:./prompts/sdd/sdd-init.md}'
  local codegraph_open='<!-- gentle-ai:codegraph-guidance -->'
  local codegraph_close='<!-- /gentle-ai:codegraph-guidance -->'
  local language_contract_open='<!-- gentle-ai:agent-language-contract -->'
  local language_contract_close='<!-- /gentle-ai:agent-language-contract -->'

  command -v jq >/dev/null 2>&1 || return 1
  jq -er --arg rc3_inline "$rc3_inline" --arg final_paragraph "$final_paragraph" --arg external "$external" \
    --arg codegraph_open "$codegraph_open" --arg codegraph_close "$codegraph_close" \
    --arg language_contract_open "$language_contract_open" --arg language_contract_close "$language_contract_close" '
      def final_inline:
        . as $raw_prompt
        | ($raw_prompt | if endswith("\n") then rtrimstr("\n") else . end) as $prompt
        | ($prompt | split("\n")) as $lines
        | [$lines | to_entries[] | select(.value == $codegraph_open) | .key] as $codegraph_opens
        | [$lines | to_entries[] | select(.value == $codegraph_close) | .key] as $codegraph_closes
        | [$lines | to_entries[] | select(.value == $language_contract_open) | .key] as $language_contract_opens
        | [$lines | to_entries[] | select(.value == $language_contract_close) | .key] as $language_contract_closes
        | ($codegraph_opens[0] // -1) as $codegraph_open_line
        | ($codegraph_closes[0] // -1) as $codegraph_close_line
        | ($language_contract_opens[0] // -1) as $language_contract_open_line
        | ($language_contract_closes[0] // -1) as $language_contract_close_line
        | [$lines[] | select(contains("gentle-ai:")) | select(. != $codegraph_open and . != $codegraph_close and . != $language_contract_open and . != $language_contract_close)] as $unknown_markers
        | ($lines | length) as $line_count
        | ($raw_prompt == $prompt or ($raw_prompt == ($prompt + "\n") and ($prompt | endswith("\n") | not)))
          and (
            ($lines == [$final_paragraph])
            or (
              $lines[0] == $final_paragraph
              and $lines[1] == ""
              and $codegraph_opens == []
              and $codegraph_closes == []
              and $language_contract_opens == [2]
              and $language_contract_close_line > ($language_contract_open_line + 1)
              and $language_contract_closes == [($line_count - 1)]
              and ($unknown_markers | length == 0)
            )
            or (
              $lines[0] == $final_paragraph
              and $lines[1] == ""
              and $codegraph_opens == [2]
              and ($codegraph_closes | length == 1)
              and $codegraph_close_line > ($codegraph_open_line + 1)
              and $language_contract_opens == [($codegraph_close_line + 2)]
              and $language_contract_close_line > ($language_contract_open_line + 1)
              and $language_contract_closes == [($line_count - 1)]
              and ($unknown_markers | length == 0)
            )
          );

      .agent["sdd-init"] as $agent
      | if ($agent | type) != "object" or $agent.hidden != true or ($agent.prompt | type) != "string" then error("invalid hidden sdd-init agent")
        elif $agent.prompt == $rc3_inline then "inline"
        elif $agent.prompt == $external then "external"
        elif ($agent.prompt | final_inline) then "inline"
        else error("unsupported sdd-init prompt")
        end
    ' "$file" 2>/dev/null
}

opencode_sdd_init_delegates() {
  [ "$(opencode_sdd_init_mode "$1" 2>/dev/null)" = inline ]
}

opencode_sdd_init_external_target() {
  [ "$(opencode_sdd_init_mode "$1" 2>/dev/null)" = external ] || return 1
  printf '%s\n' "$HOME/.config/opencode/prompts/sdd/sdd-init.md"
}

# rc 0 = written/pending, 1 = already applied, 3 = anchor gone,
# 4 = operational failure, 5 = target drift.
rubric_apply_md() {
  local file="$1" shape="$2" transform tmp snapshot rc
  case "$shape" in
    list|prose) transform="rubric_transform_$shape" ;;
    pi-workflow) transform=pi_rubric_workflow_transform ;;
    *) return 4 ;;
  esac
  tmp="$(target_tmp "$file")" || return 4
  snapshot="$(target_tmp "$file")" || { rm -f -- "$tmp"; return 4; }
  if ! safe_target "$file" || ! cp -p -- "$file" "$snapshot"; then
    rm -f -- "$tmp" "$snapshot"; return 4
  fi
  if ! "$transform" < "$snapshot" > "$tmp"; then rm -f -- "$tmp" "$snapshot"; return 3; fi
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
# Read-only Pi managed-asset diagnostic. This is advisory: it neither changes
# overlay state nor participates in preflight or exit-code decisions.
# ---------------------------------------------------------------------------
diag_report() { printf '  %s %s\n' "$1" "$2"; }

valid_asset_hash() { [[ "$1" =~ ^[0-9a-f]{64}$ ]]; }

valid_asset_path() {
  case "$1" in agents/*|chains/*|gentle-ai/support/*) ;; *) return 1 ;; esac
  case "/$1/" in *'//'|*'/./'*|*'/../'*|*/.*/*) return 1 ;; esac
  case "$1" in *.md) ;; *) return 1 ;; esac
  case "$1" in *[!A-Za-z0-9._/-]*) return 1 ;; esac
}

valid_asset_entries() {
  jq -e 'if (.assets | type) != "object" then false else
    all(.assets | to_entries[]; (.key | type) == "string" and (.value | type) == "string" and
      (.key | test("^(agents|chains|gentle-ai/support)/[A-Za-z0-9._/-]+\\.md$") and contains("//") | not) and
      (.key | split("/") | all(.[]; . != "." and . != ".." and startswith(".") | not)) and
      (.value | test("^[0-9a-f]{64}$")))
    end' "$1" >/dev/null 2>&1
}

asset_path_from_tree() {
  local section="$1" root="$2" entry="$3" suffix
  suffix="${entry#"$root"/}"
  case "$section" in support) printf 'gentle-ai/support/%s\n' "$suffix" ;; *) printf '%s/%s\n' "$section" "$suffix" ;; esac
}

asset_path_has_symlink() {
  local root="$1" file="$2" suffix part current
  suffix="${file#"$root"/}"
  [ "$suffix" != "$file" ] || return 1
  current="$root"
  while [ -n "$suffix" ]; do
    part="${suffix%%/*}"
    current="$current/$part"
    [ -L "$current" ] && return 0
    [ "$part" = "$suffix" ] && break
    suffix="${suffix#*/}"
  done
  return 1
}

asset_sha256() {
  [ -f "$1" ] && [ ! -L "$1" ] || return 1
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    return 1
  fi
}

package_source_for() {
  case "$1" in
    agents/*|chains/*) printf '%s\n' "$PACKAGE_ROOT/assets/$1" ;;
    gentle-ai/support/*) printf '%s\n' "$PACKAGE_ROOT/assets/support/${1#gentle-ai/support/}" ;;
  esac
}

installed_asset_for() {
  case "$1" in
    agents/*|chains/*) printf '%s\n' "$PI_AGENT_HOME/$1" ;;
    gentle-ai/support/*) printf '%s\n' "$PI_AGENT_HOME/$1" ;;
  esac
}

manifest_hash_for() {
  local wanted="$1" path hash extra
  [ -n "$MANIFEST_ROWS" ] || return 1
  while IFS=$'\t' read -r path hash extra; do
    [ -z "$extra" ] && [ "$path" = "$wanted" ] && { printf '%s\n' "$hash"; return 0; }
  done <<< "$MANIFEST_ROWS"
  return 1
}

source_has_path() {
  local wanted="$1" path
  [ -n "$SOURCE_ROWS" ] || return 1
  while IFS= read -r path; do [ "$path" = "$wanted" ] && return 0; done <<< "$SOURCE_ROWS"
  return 1
}

source_path_is_skipped() {
  local wanted="$1" path
  [ -n "$SOURCE_SKIPPED_ROWS" ] || return 1
  while IFS= read -r path; do
    [ "$wanted" = "$path" ] && return 0
    case "$wanted" in "$path"/*) return 0 ;; esac
  done <<< "$SOURCE_SKIPPED_ROWS"
  return 1
}

source_path_was_reported_skipped() {
  local wanted="$1" path
  [ -n "$SOURCE_SKIPPED_ROWS" ] || return 1
  while IFS= read -r path; do [ "$wanted" = "$path" ] && return 0; done <<< "$SOURCE_SKIPPED_ROWS"
  return 1
}

source_group_incomplete() {
  local path="$1" group
  case "$path" in gentle-ai/support/*) group=support ;; *) group="${path%%/*}" ;; esac
  case "$SOURCE_INCOMPLETE_GROUPS" in *"|$group|"*) return 0 ;; esac
  return 1
}

known_legacy_origin() {
  local wanted="$1" installed_hash="$2" path hash version extra
  if [ "$wanted" = chains/sdd-full.chain.md ] && \
     [ "$installed_hash" = 398f105e58b36fb169617257f4fc55b8bebdd5d26ddcb8b01556aed8dec0c0b ]; then
    printf '%s\n' 'exact gentle-pi@2.1.2 content; https://registry.npmjs.org/gentle-pi/2.1.2'
    return 0
  fi
  [ -n "$LEGACY_ROWS" ] || return 1
  while IFS='|' read -r path hash version extra; do
    [ -z "$extra" ] && [ "$path" = "$wanted" ] && [ "$hash" = "$installed_hash" ] && {
      printf 'bundled gentle-pi@%s migration registry\n' "$version"; return 0; }
  done <<< "$LEGACY_ROWS"
  return 1
}

asset_state() {
  local path="$1" source_hash="$2" installed_hash="$3" manifest_hash="$4" origin
  if [ "$installed_hash" = "$source_hash" ]; then
    if [ "$manifest_hash" = "$source_hash" ]; then
      printf 'CURRENT-MANAGED %s (raw source and ownership hashes match)\n' "$path"
    else
      printf 'CURRENT-UNMANAGED %s (matches current source; manifest ownership is absent or different)\n' "$path"
    fi
    return 0
  fi
  if origin="$(known_legacy_origin "$path" "$installed_hash")"; then
    printf 'KNOWN-OBSOLETE %s (%s; inspect/review update)\n' "$path" "$origin"
  elif [ "${path#agents/}" != "$path" ]; then
    printf 'CUSTOMIZED-UNKNOWN %s (agent routing/model rendering can differ; raw ownership is not proven)\n' "$path"
  else
    printf 'CUSTOMIZED-UNKNOWN %s (changed content has no known official hash proof)\n' "$path"
  fi
}

discover_gentle_pi_package() {
  local candidate metadata version seen='|' configured configured_rc package_root_rel
  local -a candidates=()
  PACKAGE_ROOT=''
  PACKAGE_VERSION=''
  PACKAGE_DISCOVERY_STATUS=MISSING

  configured="$(pi_configured_package_kind)"
  configured_rc=$?
  case "$configured_rc" in
    0)
      package_root_rel="$(resolve_pi_gentle_package_root_rel)" || { PACKAGE_DISCOVERY_STATUS=UNAVAILABLE; return 1; }
      candidates=("$HOME/$package_root_rel")
      ;;
    1)
      candidates=(
        "$PI_AGENT_HOME/npm/node_modules/gentle-pi"
        "${PI_CODING_AGENT_DIR:-}/npm/node_modules/gentle-pi"
        "$HOME/.pi/agent/npm/node_modules/gentle-pi"
      )
      ;;
    *) PACKAGE_DISCOVERY_STATUS=UNAVAILABLE; return 1 ;;
  esac

  for candidate in "${candidates[@]}"; do
    [ -n "$candidate" ] || continue
    case "$seen" in *"|$candidate|"*) continue ;; esac
    seen="${seen}${candidate}|"
    metadata="$candidate/package.json"
    # Absence is not a read; it permits the documented locator fallback.
    [ -e "$metadata" ] || [ -L "$metadata" ] || continue
    # Constrain package metadata before jq can parse it.
    if ! pi_package_path_confined "$candidate" "$metadata"; then
      PACKAGE_DISCOVERY_STATUS=UNAVAILABLE
      return 1
    fi
    if [ -L "$metadata" ] || [ ! -f "$metadata" ] || [ ! -r "$metadata" ]; then
      PACKAGE_DISCOVERY_STATUS=UNAVAILABLE
      return 1
    fi
    if ! version="$(jq -er 'select(type == "object" and .name == "gentle-pi" and (.version | type == "string") and (.version | test("^[A-Za-z0-9._+-]+$"))) | .version' "$metadata" 2>/dev/null)"; then
      PACKAGE_DISCOVERY_STATUS=MALFORMED
      return 1
    fi
    PACKAGE_ROOT="$candidate"
    PACKAGE_VERSION="$version"
    PACKAGE_DISCOVERY_STATUS=OK
    return 0
  done
  return 1
}

load_legacy_registry() {
  local registry_dir registry rows path hash version extra valid
  LEGACY_ROWS=''
  registry_dir="$PACKAGE_ROOT/assets/migrations"
  # Do not expand or enumerate a registry directory until it is confined.
  if ! pi_package_path_confined "$PACKAGE_ROOT" "$registry_dir"; then
    diag_report UNAVAILABLE 'migration registry directory (unsafe/unverifiable; not read)'
    return 0
  fi
  [ -d "$registry_dir" ] && [ ! -L "$registry_dir" ] || return 0
  for registry in "$registry_dir"/*.json; do
    [ -e "$registry" ] || [ -L "$registry" ] || continue
    if ! pi_package_path_confined "$PACKAGE_ROOT" "$registry" || [ -L "$registry" ] || [ ! -f "$registry" ] || [ ! -r "$registry" ]; then
      diag_report UNAVAILABLE "migration registry $(basename -- "$registry") (unsafe/unverifiable; not read)"
      continue
    fi
    if ! jq -e 'type == "object" and .schemaVersion == 1 and (.packageVersion | type == "string") and (.packageVersion | test("^[A-Za-z0-9._+-]+$")) and (.assets | type == "object")' "$registry" >/dev/null 2>&1 || ! valid_asset_entries "$registry"; then
      diag_report MALFORMED "migration registry $(basename -- "$registry") (schema 1 safe path/hash entries required)"
      continue
    fi
    version="$(jq -r '.packageVersion' "$registry")"
    rows="$(jq -r '.assets | to_entries[] | [.key, .value] | @tsv' "$registry")"
    valid=1
    if [ -n "$rows" ]; then
      while IFS=$'\t' read -r path hash extra; do
        if [ -n "$extra" ] || ! valid_asset_path "$path" || ! valid_asset_hash "$hash"; then valid=0; break; fi
      done <<< "$rows"
    fi
    if [ "$valid" -eq 0 ]; then
      diag_report MALFORMED "migration registry $(basename -- "$registry") (schema 1 safe path/hash entries required)"
      continue
    fi
    if [ -n "$rows" ]; then
      while IFS=$'\t' read -r path hash extra; do
        LEGACY_ROWS="${LEGACY_ROWS}${LEGACY_ROWS:+$'\n'}${path}|${hash}|${version}"
      done <<< "$rows"
    fi
  done
}

diagnose_asset() {
  local path="$1" source installed source_hash installed_hash manifest_hash
  source="$(package_source_for "$path")"
  installed="$(installed_asset_for "$path")"
  # Confinement is checked before any source metadata or checksum access.
  if ! pi_package_path_confined "$PACKAGE_ROOT" "$source"; then
    diag_report UNAVAILABLE "$path (source package path unsafe/unverifiable; not read)"
    return 0
  fi
  if [ ! -f "$source" ] || [ -L "$source" ]; then
    diag_report MISSING "$path (manifest ownership has no current package asset)"
    return 0
  fi
  source_hash="$(asset_sha256 "$source")" || { diag_report UNAVAILABLE "$path (source asset hash unavailable)"; return 0; }
  if asset_path_has_symlink "$PI_AGENT_HOME" "$installed"; then
    diag_report UNAVAILABLE "$path (installed asset path contains a symlink; not read)"
    return 0
  fi
  if [ ! -e "$installed" ] && [ ! -L "$installed" ]; then
    diag_report MISSING "$path (installed asset is absent)"
    return 0
  fi
  if [ ! -f "$installed" ] || [ -L "$installed" ]; then
    diag_report UNAVAILABLE "$path (installed asset is not a regular readable file)"
    return 0
  fi
  installed_hash="$(asset_sha256 "$installed")" || { diag_report UNAVAILABLE "$path (installed asset hash unavailable)"; return 0; }
  if [ "${MANIFEST_MALFORMED:-0}" -eq 1 ] && [ "$installed_hash" = "$source_hash" ]; then
    diag_report MALFORMED "$path (ownership metadata invalid; current classification skipped)"
    return 0
  fi
  manifest_hash="$(manifest_hash_for "$path" 2>/dev/null || true)"
  asset_state "$path" "$source_hash" "$installed_hash" "$manifest_hash"
}

managed_asset_diagnostic() {
  local manifest="$PI_AGENT_HOME/gentle-ai/managed-assets.json" rows path hash extra source_dir source_file rel valid source_inventory
  MANIFEST_ROWS=''
  MANIFEST_MALFORMED=0
  SOURCE_ROWS=''
  SOURCE_SKIPPED_ROWS=''
  SOURCE_INCOMPLETE_GROUPS='|'
  printf '%s\n' 'gentle-pi managed-asset diagnostic (advisory; read-only)'
  if ! command -v jq >/dev/null 2>&1; then
    diag_report UNAVAILABLE 'jq is required to verify package and manifest metadata'
    return 0
  fi
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    diag_report UNAVAILABLE 'sha256sum or shasum is required to compare asset content'
    return 0
  fi
  if ! discover_gentle_pi_package; then
    diag_report "$PACKAGE_DISCOVERY_STATUS" 'gentle-pi package.json (verified package identity unavailable)'
    return 0
  fi
  diag_report SOURCE "verified gentle-pi@$PACKAGE_VERSION package assets"
  if [ ! -e "$manifest" ] && [ ! -L "$manifest" ]; then
    diag_report MISSING 'managed-assets.json (ownership metadata unavailable)'
  elif [ ! -f "$manifest" ] || [ -L "$manifest" ] || [ ! -r "$manifest" ] || \
       ! jq -e 'type == "object" and .schemaVersion == 1 and (.assets | type == "object")' "$manifest" >/dev/null 2>&1 || \
       ! valid_asset_entries "$manifest"; then
    MANIFEST_MALFORMED=1
    diag_report MALFORMED 'managed-assets.json (schema 1 safe path/hash entries required)'
  else
    rows="$(jq -r '.assets | to_entries[] | [.key, .value] | @tsv' "$manifest")"
    valid=1
    if [ -n "$rows" ]; then
      while IFS=$'\t' read -r path hash extra; do
        if [ -n "$extra" ] || ! valid_asset_path "$path" || ! valid_asset_hash "$hash"; then valid=0; break; fi
      done <<< "$rows"
    fi
    if [ "$valid" -eq 1 ]; then
      MANIFEST_ROWS="$rows"
    else
      MANIFEST_MALFORMED=1
      diag_report MALFORMED 'managed-assets.json (schema 1 safe path/hash entries required)'
    fi
  fi
  load_legacy_registry
  for rel in agents chains support; do
    source_dir="$PACKAGE_ROOT/assets/$rel"
    # Do not enumerate a symlinked/escaped source tree: find or hashing it
    # would read package-external bytes before advisory classification.
    if ! pi_package_path_confined "$PACKAGE_ROOT" "$source_dir"; then
      SOURCE_INCOMPLETE_GROUPS="${SOURCE_INCOMPLETE_GROUPS}${rel}|"
      diag_report UNAVAILABLE "package assets/$rel (source directory unsafe/unverifiable; not read)"
      continue
    fi
    if [ ! -d "$source_dir" ] || [ -L "$source_dir" ]; then
      diag_report MISSING "package assets/$rel (source directory unavailable)"
      continue
    fi
    if [ ! -r "$source_dir" ] || [ ! -x "$source_dir" ]; then
      SOURCE_INCOMPLETE_GROUPS="${SOURCE_INCOMPLETE_GROUPS}${rel}|"
      diag_report UNAVAILABLE "package assets/$rel (source directory unreadable)"
      continue
    fi
    if ! source_inventory="$(LC_ALL=C find "$source_dir" -mindepth 1 -print 2>/dev/null | LC_ALL=C sort)"; then
      SOURCE_INCOMPLETE_GROUPS="${SOURCE_INCOMPLETE_GROUPS}${rel}|"
      diag_report UNAVAILABLE "package assets/$rel (source inventory incomplete)"
      continue
    fi
    if [ -n "$source_inventory" ]; then
      while IFS= read -r source_file; do
        path="$(asset_path_from_tree "$rel" "$source_dir" "$source_file")"
        if ! pi_package_path_confined "$PACKAGE_ROOT" "$source_file"; then
          SOURCE_SKIPPED_ROWS="${SOURCE_SKIPPED_ROWS}${SOURCE_SKIPPED_ROWS:+$'\n'}$path"
          diag_report UNAVAILABLE "$path (source package entry is unsafe/unverifiable; not read)"
        elif [ -d "$source_file" ]; then
          :
        elif [ -f "$source_file" ]; then
          case "$source_file" in
            *.md) if valid_asset_path "$path"; then SOURCE_ROWS="${SOURCE_ROWS}${SOURCE_ROWS:+$'\n'}$path"
                  else diag_report MALFORMED "package asset path $path"; fi ;;
          esac
        else
          SOURCE_SKIPPED_ROWS="${SOURCE_SKIPPED_ROWS}${SOURCE_SKIPPED_ROWS:+$'\n'}$path"
          diag_report UNAVAILABLE "$path (source package entry is non-regular; not read)"
        fi
      done <<< "$source_inventory"
    fi
  done
  if [ -n "$SOURCE_ROWS" ]; then
    while IFS= read -r path; do diagnose_asset "$path"; done <<< "$SOURCE_ROWS"
  fi
  if [ -n "$MANIFEST_ROWS" ]; then
    while IFS=$'\t' read -r path hash extra; do
      if source_group_incomplete "$path"; then
        diag_report UNAVAILABLE "$path (source inventory incomplete; ownership comparison skipped)"
      elif source_path_is_skipped "$path"; then
        source_path_was_reported_skipped "$path" || diag_report UNAVAILABLE "$path (source package entry unavailable; ownership comparison skipped)"
      else
        source_has_path "$path" || diag_report MISSING "$path (manifest ownership has no current package asset)"
      fi
    done <<< "$MANIFEST_ROWS"
  fi
  diag_report RECOMMENDATION 'inspect/review reported assets and update through Gentle AI when appropriate'
  return 0
}

# ---------------------------------------------------------------------------
# Drive
# ---------------------------------------------------------------------------
if [ "${APPLY_SH_LIB:-0}" = 1 ]; then
  return 0 2>/dev/null || exit 0
fi

managed_asset_diagnostic
printf '\n'

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
    unresolved_rel="$rel"
    if ! rel="$(resolve_target_rel "$host" "$rel")" || [ -z "$rel" ]; then
      case "$host:$unresolved_rel" in
        pi:@pi-gentle-pi-gentle-init@|pi:@pi-gentle-pi-workflow@|pi:@pi-gentle-pi-delegation@|pi:@pi-gentle-pi-sdd-init@)
          report "PACKAGE-TARGET-CONFIG-FAILURE" "$surface" "$unresolved_rel (ambiguous, conflicting, or unsupported gentle-pi package source)"
          PACKAGE_TARGET_FAILED=1
          break 2
          ;;
        *)
          report "UNSUPPORTED-VARIANT" "$surface" "unresolved target"
          MISSING_ANCHOR=1
          continue
          ;;
      esac
    fi
    file="$HOME/$rel"
    short="${rel}"

    if [ ! -e "$file" ] && [ ! -L "$file" ]; then
      if [ "$surface" = pi-odd-forwarding ]; then
        report "n/a" "odd-rubric" "$short (selected package has no ODD delegation asset)"
        continue
      fi
      if [ "$surface" = pi-gentle-init-transaction ]; then
        report "n/a" "pi-gentle-init" "$short (selected package lacks gentle-init; all four Pi surfaces retained)"
        continue
      fi
      report "MISSING-FILE" "$surface" "$short"
      MISSING_ANCHOR=1
      continue
    fi
    if ! safe_target "$file"; then
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
      persona-split-style)
        persona_split_style_apply "$file"; rc=$?
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "persona" "$short (split style)"; PENDING=1
              else report "applied" "persona" "$short (split style)"; CHANGED=1; fi ;;
          1) report "already-applied" "persona" "$short (split style)" ;;
          3) report "ANCHOR-NOT-FOUND" "persona" "$short (split style)"; MISSING_ANCHOR=1 ;;
          4) report "WRITE-FAILED" "persona" "$short (split style)"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "persona" "$short (split style)"; TARGET_DRIFT=1 ;;
          *) report "WRITE-FAILED" "persona" "$short (split style)"; OPERATION_FAILED=1 ;;
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
        shape="${surface#rubric-}"
        rubric_apply_md "$file" "$shape"; rc=$?
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
      pi-gentle-init-transaction)
        legacy_file="$(dirname -- "$file")/sdd-init.md"
        workflow_file="$(dirname -- "$(dirname -- "$file")")/sdd-orchestrator-workflow.md"
        delegation_file="$(dirname -- "$(dirname -- "$file")")/orchestrator-delegation.md"
        if [ ! -e "$file" ] && [ ! -L "$file" ]; then
          report "n/a" "pi-gentle-init" "$short (selected package lacks gentle-init; all four Pi surfaces retained)"
          continue
        fi
        pi_gentle_init_transaction_apply "$file" "$legacy_file" "$workflow_file" "$delegation_file"; rc=$?
        [ "${PI_TRANSACTION_ODD_STATUS:-}" = n/a ] && report "n/a" "odd-rubric" "${delegation_file#"$HOME"/} (optional ODD asset/section absent)"
        case "$rc" in
          0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "pi-gentle-init" "$short (four-surface transaction)"; PENDING=1
             else report "applied" "pi-gentle-init" "$short (four-surface transaction)"; CHANGED=1; fi ;;
          1) report "already-applied" "pi-gentle-init" "$short (four-surface transaction)" ;;
          3) report "REFUSED" "pi-gentle-init" "$short (invalid sibling anchor, marker, or predecessor; no backups/writes)"; MISSING_ANCHOR=1 ;;
          4) report "UNSAFE-TARGET" "pi-gentle-init" "$short (one of four selected package siblings)"; OPERATION_FAILED=1 ;;
          5) report "TARGET-DRIFT" "pi-gentle-init" "$short (selected sibling changed during transaction; $(pi_transaction_recovery_report))"; TARGET_DRIFT=1 ;;
          7) report "WRITE-FAILED" "pi-gentle-init" "$short (transaction compensated; retained preimage backups)"; OPERATION_FAILED=1 ;;
          8) report "RECOVERY-REQUIRED" "pi-gentle-init" "$short (transaction-written targets may remain changed: $PI_TRANSACTION_MIXED_TARGETS; $(pi_transaction_recovery_report))"; OPERATION_FAILED=1 ;;
          12) report "MISSING-CAPABILITY" "pi-gentle-init" "$short (python3 byte-transform dependency unavailable or unusable)"; CAPABILITY_FAILED=1 ;;
          *) report "WRITE-FAILED" "pi-gentle-init" "$short"; OPERATION_FAILED=1 ;;
        esac
        ;;
      sdd-init-skill|sdd-init-details)
        case "$surface" in
          sdd-init-skill) shape=skill ;;
          sdd-init-details) shape=details ;;
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
      sdd-init-delegation)
        init_mode="$(opencode_sdd_init_mode "$file" 2>/dev/null)"
        if [ "$init_mode" = inline ]; then
          report "reachable" "sdd-init-rubric" "$short (inline prompt -> managed skill)"
        elif [ "$init_mode" = external ]; then
          prompt_file="$(opencode_sdd_init_external_target "$file")" || {
            report "UNREACHABLE" "sdd-init-rubric" "$short (unsupported external prompt)"
            MISSING_ANCHOR=1
            continue
          }
          prompt_short=".config/opencode/prompts/sdd/sdd-init.md"
          if [ ! -e "$prompt_file" ] && [ ! -L "$prompt_file" ]; then
            report "MISSING-FILE" "sdd-init-rubric" "$prompt_short (external prompt)"
            MISSING_ANCHOR=1
          elif ! safe_target "$prompt_file"; then
            report "UNSAFE-TARGET" "sdd-init-rubric" "$prompt_short (external prompt)"
            OPERATION_FAILED=1
          else
            init_rubric_apply "$prompt_file" skill; rc=$?
            case "$rc" in
              0) if [ "$CHECK_ONLY" -eq 1 ]; then report "PENDING" "sdd-init-rubric" "$prompt_short (external prompt)"; PENDING=1
                 else report "applied" "sdd-init-rubric" "$prompt_short (external prompt)"; CHANGED=1; fi ;;
              1) report "already-applied" "sdd-init-rubric" "$prompt_short (external prompt)" ;;
              3) report "ANCHOR-NOT-FOUND" "sdd-init-rubric" "$prompt_short (external prompt)"; MISSING_ANCHOR=1 ;;
              4) report "WRITE-FAILED" "sdd-init-rubric" "$prompt_short (external prompt)"; OPERATION_FAILED=1 ;;
              5) report "TARGET-DRIFT" "sdd-init-rubric" "$prompt_short (external prompt)"; TARGET_DRIFT=1 ;;
              *) report "WRITE-FAILED" "sdd-init-rubric" "$prompt_short (external prompt)"; OPERATION_FAILED=1 ;;
            esac
          fi
        else
          report "UNREACHABLE" "sdd-init-rubric" "$short (unsupported hidden prompt shape)"
          MISSING_ANCHOR=1
        fi
        ;;
      rubric-none)
        # This host's template has no strict-TDD forwarding section at all.
        report "n/a" "rubric-tdd" "$short (no strict-TDD section in template)"
        ;;
    esac
    if [ "$OPERATION_FAILED" -eq 1 ] || [ "$TARGET_DRIFT" -eq 1 ] || [ "$CAPABILITY_FAILED" -eq 1 ]; then
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

if [ "$PACKAGE_TARGET_FAILED" -eq 1 ]; then
  echo "FAIL: Pi package target configuration is ambiguous, conflicting, or unsupported; nothing was written."
  exit 1
fi

if [ "$CAPABILITY_FAILED" -eq 1 ]; then
  echo "FAIL: required Pi migration byte-transform capability is unavailable; nothing was written."
  exit 1
fi

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
