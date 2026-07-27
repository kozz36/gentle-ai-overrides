#!/usr/bin/env bash
# Hermetic regression tests for apply.sh. Fixtures always live outside $HOME.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-overrides-tests.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }

expect_rc() {
  local expected="$1"
  shift
  "$@"
  local actual=$?
  [ "$actual" -eq "$expected" ] || fail "expected rc $expected, got $actual: $*"
}

mode_of() {
  if stat -c '%a' "$1" >/dev/null 2>&1; then
    stat -c '%a' "$1"
  else
    stat -f '%Lp' "$1"
  fi
}

load_overlay() {
  local home="$1" backups="$2"
  HOME="$home"
  GENTLE_AI_BACKUP_ROOT="$backups"
  APPLY_SH_LIB=1
  export HOME GENTLE_AI_BACKUP_ROOT APPLY_SH_LIB
  # shellcheck source=../apply.sh
  source "$ROOT/apply.sh"
}

test_claude_idempotence_and_backup() (
  local home="$TMP_ROOT/claude-home" backups="$TMP_ROOT/claude-backups" file
  file="$home/.claude/CLAUDE.md"
  mkdir -p "$(dirname -- "$file")"
  cat > "$file" <<'EOF'
<!-- gentle-ai:persona -->
## Rules

- legacy rule

## Expertise

legacy expertise

## Contextual Skill Loading (MANDATORY)

installer-managed content

## Persona Voice

installer-managed voice
<!-- /gentle-ai:persona -->
EOF
  chmod 640 "$file"

  load_overlay "$home" "$backups"
  expect_rc 0 persona_split_claude_apply "$file" || exit 1
  grep -Fq 'Never add "Co-Authored-By"' "$file" || fail 'Claude Rules were not replaced' || exit 1
  grep -Fq 'Clean/Hexagonal/Screaming Architecture' "$file" || fail 'Claude Expertise was not replaced' || exit 1
  grep -Fq 'installer-managed content' "$file" || fail 'Claude unmanaged content changed' || exit 1
  grep -Fq 'installer-managed voice' "$file" || fail 'Claude persona voice changed' || exit 1
  [ "$(mode_of "$file")" = 640 ] || fail 'Claude target mode changed' || exit 1
  grep -Fq 'legacy rule' "$backups/.claude/CLAUDE.md" || fail 'Claude backup is missing original content' || exit 1
  expect_rc 1 persona_split_claude_apply "$file" || exit 1
)

test_claude_missing_anchor() (
  local home="$TMP_ROOT/claude-missing-home" backups="$TMP_ROOT/claude-missing-backups" file
  file="$home/.claude/CLAUDE.md"
  mkdir -p "$(dirname -- "$file")"
  printf '%s\n' '<!-- gentle-ai:persona -->' '## Rules' '<!-- /gentle-ai:persona -->' > "$file"
  load_overlay "$home" "$backups"
  expect_rc 3 persona_split_claude_apply "$file" || exit 1
  [ ! -e "$backups/.claude/CLAUDE.md" ] || fail 'missing-anchor Claude target was backed up' || exit 1
)

test_claude_duplicate_markers() (
  local home="$TMP_ROOT/claude-duplicate-home" backups="$TMP_ROOT/claude-duplicate-backups" file
  file="$home/.claude/CLAUDE.md"
  mkdir -p "$(dirname -- "$file")"
  cat > "$file" <<'EOF'
<!-- gentle-ai:persona -->
## Rules
one
## Expertise
one
## Contextual Skill Loading
one
<!-- /gentle-ai:persona -->
<!-- gentle-ai:persona -->
## Rules
two
## Expertise
two
## Contextual Skill Loading
two
<!-- /gentle-ai:persona -->
EOF
  load_overlay "$home" "$backups"
  expect_rc 3 persona_split_claude_apply "$file" || exit 1
  grep -Fq '## Rules' "$file" || fail 'duplicate-marker target changed' || exit 1
)

write_opencode_stock() {
  cat <<'EOF'
export const plugin = {
    "experimental.chat.system.transform": async (input, output) => {
      if (output.system.length > 0) {
        output.system[output.system.length - 1] += "\n\n" + MEMORY_INSTRUCTIONS
      } else {
        output.system.push(MEMORY_INSTRUCTIONS)
      }

      // ── Save nudge
      return
    },
}
EOF
}

test_opencode_stock_and_guarded_noop() (
  local home="$TMP_ROOT/opencode-home" backups="$TMP_ROOT/opencode-backups" file before
  file="$home/.config/opencode/plugins/engram.ts"
  mkdir -p "$(dirname -- "$file")"
  write_opencode_stock > "$file"
  before="$TMP_ROOT/opencode-stock-before.ts"
  cp -- "$file" "$before"
  load_overlay "$home" "$backups"
  CHECK_ONLY=1
  expect_rc 0 opencode_engram_apply "$file" || exit 1
  cmp -s "$file" "$before" || fail 'OpenCode --check changed its target' || exit 1
  [ ! -e "$backups/.config/opencode/plugins/engram.ts" ] || fail 'OpenCode --check created a backup' || exit 1
  export CHECK_ONLY=0
  expect_rc 0 opencode_engram_apply "$file" || exit 1
  grep -Fq 'const hasMemoryProtocol' "$file" || fail 'OpenCode stock body was not guarded' || exit 1
  grep -Fq '// ── Save nudge' "$file" || fail 'OpenCode save nudge changed' || exit 1
  expect_rc 1 opencode_engram_apply "$file" || exit 1
)

test_opencode_refuses_custom_body() (
  local home="$TMP_ROOT/opencode-custom-home" backups="$TMP_ROOT/opencode-custom-backups" file before
  file="$home/.config/opencode/plugins/engram.ts"
  mkdir -p "$(dirname -- "$file")"
  write_opencode_stock | sed 's/if (output.system.length > 0)/const userCustom = true/' > "$file"
  before="$TMP_ROOT/opencode-custom-before.ts"
  cp -- "$file" "$before"
  load_overlay "$home" "$backups"
  expect_rc 3 opencode_engram_apply "$file" || exit 1
  cmp -s "$file" "$before" || fail 'OpenCode custom body was overwritten' || exit 1
)

test_pi_exact_sdd_proposal() (
  local home="$TMP_ROOT/pi-home" backups="$TMP_ROOT/pi-backups" file
  file="$home/.pi/agent/APPEND_SYSTEM.md"
  mkdir -p "$(dirname -- "$file")"
  cat > "$file" <<'EOF'
Before the `sdd-propose` phase in interactive mode, offer the user a proposal question round.
Only for a selected SDD route, delegate to these phase agents: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard.
<!-- gentle-ai:sdd-model-assignments -->
## Model Assignments
| sdd-propose | opus | Architectural decisions |
<!-- /gentle-ai:sdd-model-assignments -->
The orchestrator resolves skills from the registry ONCE and passes model aliases.
| `sdd-propose` | exploration (optional) | `proposal` |
Unrelated prose: sdd-propose must remain unchanged.
EOF
  load_overlay "$home" "$backups"
  expect_rc 0 pimodel_apply "$file" || exit 1
  grep -Fq 'Before the `sdd-proposal` phase' "$file" || fail 'Pi interactive proposal identifier was not normalized' || exit 1
  grep -Fq 'sdd-explore, sdd-proposal, sdd-spec' "$file" || fail 'Pi delegation identifier was not normalized' || exit 1
  grep -Fq '| `sdd-proposal` | exploration (optional) | `proposal` |' "$file" || fail 'Pi phase table identifier was not normalized' || exit 1
  grep -Fq 'Unrelated prose: sdd-propose must remain unchanged.' "$file" || fail 'Pi global token replacement changed unrelated text' || exit 1
  expect_rc 1 pimodel_apply "$file" || exit 1
)

test_cli_check_semantics() (
  local home="$TMP_ROOT/cli-home" backups="$TMP_ROOT/cli-backups" file rc
  file="$home/.pi/agent/APPEND_SYSTEM.md"
  mkdir -p "$home/.gentle-ai" "$(dirname -- "$file")"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  {
    printf '%s\n' '<!-- gentle-ai:persona -->'
    cat "$ROOT/persona/persona-block.md"
    printf '%s\n' '<!-- /gentle-ai:persona -->'
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'
    printf '%s\n' '<!-- gentle-ai:sdd-model-assignments -->' 'legacy model assignments' '<!-- /gentle-ai:sdd-model-assignments -->'
    printf '%s\n' 'The orchestrator resolves skills from the registry ONCE and passes model aliases.'
    printf '%s\n' 'Before the `sdd-propose` phase in interactive mode, offer the user a proposal question round.'
    printf '%s\n' 'Only for a selected SDD route, delegate to these phase agents: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard.'
    printf '%s\n' '| `sdd-propose` | exploration (optional) | `proposal` |'
  } > "$file"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 2 ] || fail "expected --check pending rc 2, got $rc" || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail '--check created a backup' || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" >/dev/null || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 0 ] || fail "expected clean --check rc 0, got $rc" || exit 1
)

test_symlink_refusal() (
  local home="$TMP_ROOT/symlink-home" backups="$TMP_ROOT/symlink-backups" target link
  target="$TMP_ROOT/symlink-target.md"
  link="$home/.pi/agent/APPEND_SYSTEM.md"
  mkdir -p "$(dirname -- "$link")"
  printf '%s\n' 'outside target' > "$target"
  ln -s "$target" "$link"
  load_overlay "$home" "$backups"
  expect_rc 4 pimodel_apply "$link" || exit 1
  grep -Fqx 'outside target' "$target" || fail 'symlink target changed' || exit 1
)

test_backup_failure_is_closed() (
  local home="$TMP_ROOT/backup-home" backups="$TMP_ROOT/backup-blocker" file before
  file="$home/.config/opencode/plugins/engram.ts"
  mkdir -p "$(dirname -- "$file")"
  write_opencode_stock > "$file"
  printf '%s\n' 'not a directory' > "$backups"
  before="$TMP_ROOT/backup-before.ts"
  cp -- "$file" "$before"
  load_overlay "$home" "$backups"
  expect_rc 4 opencode_engram_apply "$file" 2>/dev/null || exit 1
  cmp -s "$file" "$before" || fail 'target changed after backup failure' || exit 1
)

test_target_drift_is_closed() (
  local home="$TMP_ROOT/drift-home" backups="$TMP_ROOT/drift-backups" file snapshot replacement
  file="$home/.pi/agent/APPEND_SYSTEM.md"
  mkdir -p "$(dirname -- "$file")"
  printf '%s\n' 'transform input' > "$file"
  load_overlay "$home" "$backups"
  snapshot="$(target_tmp "$file")"
  replacement="$(target_tmp "$file")"
  cp -p -- "$file" "$snapshot"
  printf '%s\n' 'replacement output' > "$replacement"
  printf '%s\n' 'concurrent writer' > "$file"
  expect_rc 5 commit_replacement "$file" "$snapshot" "$replacement" || exit 1
  grep -Fqx 'concurrent writer' "$file" || fail 'drifted target was overwritten' || exit 1
  rm -f -- "$snapshot" "$replacement"
)

test_installed_hosts_fallback_includes_gemini() (
  local home="$TMP_ROOT/hosts-home" backups="$TMP_ROOT/hosts-backups"
  mkdir -p "$home"
  load_overlay "$home" "$backups"
  installed_hosts | grep -Fqx 'gemini-cli' || fail 'fallback host list omitted Gemini CLI' || exit 1
)

run() {
  local name="$1"
  if "$name"; then
    printf 'PASS: %s\n' "${name#test_}"
    PASS=$((PASS + 1))
  else
    printf 'FAIL: %s\n' "${name#test_}" >&2
    FAIL=$((FAIL + 1))
  fi
}

run test_claude_idempotence_and_backup
run test_claude_missing_anchor
run test_claude_duplicate_markers
run test_opencode_stock_and_guarded_noop
run test_opencode_refuses_custom_body
run test_pi_exact_sdd_proposal
run test_cli_check_semantics
run test_symlink_refusal
run test_backup_failure_is_closed
run test_target_drift_is_closed
run test_installed_hosts_fallback_includes_gemini

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
