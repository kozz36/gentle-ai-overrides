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

test_rubric_list_replaces_legacy_item4() (
  local home="$TMP_ROOT/rubric-list-home" backups="$TMP_ROOT/rubric-list-backups" md json loose before json_before transformed expected loose_expected
  md="$home/.pi/agent/APPEND_SYSTEM.md"
  json="$home/.config/opencode/opencode.json"
  loose="$home/.pi/agent/LEGACY_PROSE.md"
  before="$TMP_ROOT/rubric-list-before.md"
  json_before="$TMP_ROOT/rubric-list-before.json"
  transformed="$TMP_ROOT/rubric-list-transformed.md"
  expected="$TMP_ROOT/rubric-list-expected.md"
  loose_expected="$TMP_ROOT/rubric-list-loose-expected.md"
  mkdir -p "$(dirname -- "$md")" "$(dirname -- "$json")"
  cat > "$md" <<'EOF'
Before the strict-TDD forwarding list.
3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Only consume an active/authoritative rubric; otherwise preserve binary `strict_tdd` behavior. Classify the
   change against the matching rubric row and forward its instruction to the sub-agent.
5. Subsequent numbered-list item must survive unchanged.
The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.
Following cache prose must survive unchanged.
EOF
  cp -- "$md" "$before"

  load_overlay "$home" "$backups"
  {
    printf '%s\n' 'Before the strict-TDD forwarding list.'
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'
    printf '%s\n' "$RUBRIC_ITEM4"
    printf '%s\n' '5. Subsequent numbered-list item must survive unchanged.'
    printf '%s\n' "$CACHE_NEW"
    printf '%s\n' 'Following cache prose must survive unchanged.'
  } > "$expected"

  rubric_transform_list < "$md" > "$transformed" || fail 'legacy list transform refused a valid fixture' || exit 1
  cmp -s "$transformed" "$expected" || fail 'legacy list transform did not replace the complete item 4 block' || exit 1
  grep -Fq 'matching rubric row' "$transformed" && fail 'legacy item 4 body survived transform' && exit 1
  grep -Fq '5. Subsequent numbered-list item must survive unchanged.' "$transformed" || fail 'transform consumed item 5' || exit 1
  grep -Fq 'Following cache prose must survive unchanged.' "$transformed" || fail 'transform consumed following cache prose' || exit 1

  CHECK_ONLY=1
  expect_rc 0 rubric_apply_md "$md" list || exit 1
  cmp -s "$md" "$before" || fail 'Markdown rubric check changed its target' || exit 1
  CHECK_ONLY=0
  expect_rc 0 rubric_apply_md "$md" list || exit 1
  cmp -s "$md" "$expected" || fail 'Markdown rubric apply did not install canonical content' || exit 1
  expect_rc 1 rubric_apply_md "$md" list || exit 1

  jq -n --rawfile prompt "$before" '{agent: {"gentle-orchestrator": {prompt: $prompt}}}' > "$json"
  cp -- "$json" "$json_before"
  CHECK_ONLY=1
  expect_rc 0 rubric_apply_json "$json" || exit 1
  cmp -s "$json" "$json_before" || fail 'JSON rubric check changed its target' || exit 1
  CHECK_ONLY=0
  expect_rc 0 rubric_apply_json "$json" || exit 1
  jq -e --rawfile expected "$expected" '.agent["gentle-orchestrator"].prompt == $expected' "$json" >/dev/null || fail 'JSON rubric apply did not install canonical content' || exit 1
  expect_rc 1 rubric_apply_json "$json" || exit 1

  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction' '' "$RUBRIC_PROSE" '' "$CACHE_OLD"
  } > "$loose"
  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction' "$RUBRIC_ITEM4" '' "$CACHE_NEW"
  } > "$loose_expected"
  rubric_transform_list < "$loose" > "$transformed" || fail 'legacy loose paragraph transform refused a valid fixture' || exit 1
  cmp -s "$transformed" "$loose_expected" || fail 'legacy loose paragraph was not migrated' || exit 1
)

test_rubric_list_refuses_ambiguous_headings() (
  local home="$TMP_ROOT/rubric-refusal-home" backups="$TMP_ROOT/rubric-refusal-backups" duplicate out_of_order after_item5 blank_separated prose_intervening before output
  duplicate="$home/.pi/agent/APPEND_SYSTEM.md"
  out_of_order="$home/.pi/agent/OUT_OF_ORDER.md"
  after_item5="$home/.pi/agent/AFTER_ITEM5.md"
  blank_separated="$home/.pi/agent/BLANK_SEPARATED.md"
  prose_intervening="$home/.pi/agent/PROSE_INTERVENING.md"
  before="$TMP_ROOT/rubric-refusal-before.md"
  output="$TMP_ROOT/rubric-refusal-output.md"
  mkdir -p "$(dirname -- "$duplicate")"

  load_overlay "$home" "$backups"
  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'
    printf '%s\n' "$RUBRIC_ITEM4"
    printf '%s\n' "$RUBRIC_ITEM4"
  } > "$duplicate"
  cp -- "$duplicate" "$before"
  rubric_transform_list < "$duplicate" > "$output" && fail 'duplicate item 4 headings were transformed' && exit 1
  expect_rc 3 rubric_apply_md "$duplicate" list || exit 1
  cmp -s "$duplicate" "$before" || fail 'duplicate item 4 target changed' || exit 1

  {
    printf '%s\n' "$RUBRIC_ITEM4"
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'
  } > "$out_of_order"
  rubric_transform_list < "$out_of_order" > "$output" && fail 'item 4 before item 3 was transformed' && exit 1
  expect_rc 3 rubric_apply_md "$out_of_order" list || exit 1

  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'
    printf '%s\n' '5. A later numbered-list item.'
    printf '%s\n' "$RUBRIC_ITEM4"
  } > "$after_item5"
  cp -- "$after_item5" "$before"
  rubric_transform_list < "$after_item5" > "$output" && fail 'item 4 after item 5 was transformed' && exit 1
  expect_rc 3 rubric_apply_md "$after_item5" list || exit 1
  cmp -s "$after_item5" "$before" || fail 'item 4 after item 5 target changed' || exit 1
  [ ! -e "$backups/.pi/agent/AFTER_ITEM5.md" ] || fail 'item 4 after item 5 refusal created a backup' || exit 1

  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction' '' "$RUBRIC_ITEM4"
  } > "$blank_separated"
  cp -- "$blank_separated" "$before"
  rubric_transform_list < "$blank_separated" > "$output" && fail 'blank-separated item 4 was transformed' && exit 1
  expect_rc 3 rubric_apply_md "$blank_separated" list || exit 1
  cmp -s "$blank_separated" "$before" || fail 'blank-separated item 4 target changed' || exit 1
  [ ! -e "$backups/.pi/agent/BLANK_SEPARATED.md" ] || fail 'blank-separated refusal created a backup' || exit 1

  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction' 'Intervening prose.' "$RUBRIC_ITEM4"
  } > "$prose_intervening"
  rubric_transform_list < "$prose_intervening" > "$output" && fail 'prose-intervening item 4 was transformed' && exit 1
  expect_rc 3 rubric_apply_md "$prose_intervening" list || exit 1
)

test_cli_check_semantics() (
  local home="$TMP_ROOT/cli-home" backups="$TMP_ROOT/cli-backups" file init_file rc
  file="$home/.pi/agent/APPEND_SYSTEM.md"
  init_file="$home/.pi/agent/agents/sdd-init.md"
  mkdir -p "$home/.gentle-ai" "$(dirname -- "$file")" "$(dirname -- "$init_file")"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  {
    printf '%s\n' '<!-- gentle-ai:persona -->'
    cat "$ROOT/persona/persona-block.md"
    printf '%s\n' '<!-- /gentle-ai:persona -->'
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction'
    printf '%s\n' '4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**'
    printf '%s\n' '   Classify the change against the matching rubric row and forward its instruction to the sub-agent.'
    printf '%s\n' 'The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.'
    printf '%s\n' 'Following cache prose must survive unchanged.'
    printf '%s\n' '<!-- gentle-ai:sdd-model-assignments -->' 'legacy model assignments' '<!-- /gentle-ai:sdd-model-assignments -->'
    printf '%s\n' 'The orchestrator resolves skills from the registry ONCE and passes model aliases.'
    printf '%s\n' 'Before the `sdd-propose` phase in interactive mode, offer the user a proposal question round.'
    printf '%s\n' 'Only for a selected SDD route, delegate to these phase agents: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard.'
    printf '%s\n' '| `sdd-propose` | exploration (optional) | `proposal` |'
  } > "$file"
  write_pi_init_stock > "$init_file"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 2 ] || fail "expected --check pending rc 2, got $rc" || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail '--check created a backup' || exit 1
  [ ! -e "$backups/.pi/agent/agents/sdd-init.md" ] || fail '--check created an init-agent backup' || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" >/dev/null || exit 1
  grep -Fq 'matching rubric row and forward' "$file" && fail 'CLI retained stale item 4 body' && exit 1
  grep -Fq 'change against ALL matching non-default rows' "$file" || fail 'CLI did not install current item 4 body' || exit 1
  grep -Fq 'Following cache prose must survive unchanged.' "$file" || fail 'CLI consumed following cache prose' || exit 1
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

test_sdd_init_host_rows_cover_cursor_and_copilot() (
  local home="$TMP_ROOT/skills-hosts-home" backups="$TMP_ROOT/skills-hosts-backups"
  mkdir -p "$home"
  load_overlay "$home" "$backups"
  host_rows | grep -Fqx 'cursor|sdd-init-skill|.cursor/skills/sdd-init/SKILL.md' || fail 'Cursor sdd-init skill row is missing' || exit 1
  host_rows | grep -Fqx 'cursor|sdd-init-details|.cursor/skills/sdd-init/references/init-details.md' || fail 'Cursor sdd-init details row is missing' || exit 1
  host_rows | grep -Fqx 'vscode-copilot|sdd-init-skill|.copilot/skills/sdd-init/SKILL.md' || fail 'Copilot sdd-init skill row is missing' || exit 1
  host_rows | grep -Fqx 'vscode-copilot|sdd-init-details|.copilot/skills/sdd-init/references/init-details.md' || fail 'Copilot sdd-init details row is missing' || exit 1
  host_rows | grep -Fqx 'opencode|sdd-init-prompt|.config/opencode/prompts/sdd/sdd-init.md' || fail 'OpenCode executable sdd-init prompt row is missing' || exit 1
)

test_antigravity_skill_root_resolution() (
  local home="$TMP_ROOT/antigravity-root-home" backups="$TMP_ROOT/antigravity-root-backups" placeholder
  placeholder='@antigravity-skills@/sdd-init/SKILL.md'
  mkdir -p "$home/.gemini/antigravity-cli"
  load_overlay "$home" "$backups"
  [ "$(resolve_target_rel antigravity "$placeholder")" = '.gemini/antigravity-cli/skills/sdd-init/SKILL.md' ] || fail 'Antigravity did not select CLI skills when desktop is absent' || exit 1
  mkdir -p "$home/.gemini/antigravity-desktop"
  [ "$(resolve_target_rel antigravity "$placeholder")" = '.gemini/antigravity-desktop/skills/sdd-init/SKILL.md' ] || fail 'Antigravity did not prefer desktop skills' || exit 1
)

write_init_skill_stock() {
  cat <<'EOF'
---
name: sdd-init
---

Installer-owned introduction.

## Decision Gates

Installer-owned decisions.
EOF
}

resolve_opencode_sdd_init_prompt() {
  local home="$1" config prompt
  config="$home/.config/opencode/opencode.json"
  prompt="$(jq -er '.agent["sdd-init"].prompt | strings' "$config")" || return 1
  [ "$prompt" = '{file:./prompts/sdd/sdd-init.md}' ] || return 1
  printf '%s\n' "$home/.config/opencode/prompts/sdd/sdd-init.md"
}

test_opencode_sdd_init_prompt_lifecycle_and_reachability() (
  local home="$TMP_ROOT/opencode-init-prompt-home" backups="$TMP_ROOT/opencode-init-prompt-backups" \
    missing_backups="$TMP_ROOT/opencode-init-prompt-missing-backups" \
    duplicate_backups="$TMP_ROOT/opencode-init-prompt-duplicate-backups" \
    config file before snapshot replacement
  config="$home/.config/opencode/opencode.json"
  file="$home/.config/opencode/prompts/sdd/sdd-init.md"
  before="$TMP_ROOT/opencode-init-prompt-before.md"
  mkdir -p "$(dirname -- "$config")" "$(dirname -- "$file")"
  jq -n '{agent: {"sdd-init": {prompt: "{file:./prompts/sdd/sdd-init.md}"}}}' > "$config"
  write_init_skill_stock > "$file"
  cp -- "$file" "$before"

  load_overlay "$home" "$backups"
  [ "$(resolve_opencode_sdd_init_prompt "$home")" = "$file" ] || fail 'OpenCode sdd-init prompt did not resolve to the managed entrypoint' || exit 1
  CHECK_ONLY=1
  expect_rc 0 init_rubric_apply "$file" skill || exit 1
  cmp -s "$file" "$before" || fail 'OpenCode sdd-init --check changed the executable prompt' || exit 1
  [ ! -e "$backups/.config/opencode/prompts/sdd/sdd-init.md" ] || fail 'OpenCode sdd-init --check created a backup' || exit 1
  CHECK_ONLY=0
  expect_rc 0 init_rubric_apply "$file" skill || exit 1
  grep -Fq '<!-- gentle-ai:sdd-init-rubric -->' "$file" || fail 'OpenCode executable prompt lacks the managed rubric marker' || exit 1
  grep -Fq 'single writer of project TDD policy' "$file" || fail 'OpenCode executable prompt lacks the managed contract' || exit 1
  awk '/<!-- gentle-ai:sdd-init-rubric -->/{ marker = NR } /^## Decision Gates$/{ decision = NR } END { exit !(marker && decision && marker < decision) }' "$file" || fail 'OpenCode managed contract is not before the decision gate' || exit 1
  cmp -s "$before" "$backups/.config/opencode/prompts/sdd/sdd-init.md" || fail 'OpenCode executable prompt backup is not original' || exit 1
  expect_rc 1 init_rubric_apply "$file" skill || exit 1

  cat > "$file" <<'EOF'
Before managed section.
<!-- gentle-ai:sdd-init-rubric -->
stale managed content
<!-- /gentle-ai:sdd-init-rubric -->

## Decision Gates

After managed section.
EOF
  load_overlay "$home" "$TMP_ROOT/opencode-init-prompt-replacement-backups"
  expect_rc 0 init_rubric_apply "$file" skill || exit 1
  grep -Fq 'stale managed content' "$file" && fail 'OpenCode executable prompt retained stale managed content' && exit 1
  grep -Fq 'After managed section.' "$file" || fail 'OpenCode executable prompt replacement changed surrounding content' || exit 1

  printf '%s\n' 'no decision anchor' > "$file"
  cp -- "$file" "$TMP_ROOT/opencode-init-prompt-missing-before.md"
  load_overlay "$home" "$missing_backups"
  expect_rc 3 init_rubric_apply "$file" skill || exit 1
  cmp -s "$file" "$TMP_ROOT/opencode-init-prompt-missing-before.md" || fail 'missing-anchor executable prompt changed' || exit 1
  [ ! -e "$missing_backups/.config/opencode/prompts/sdd/sdd-init.md" ] || fail 'missing-anchor executable prompt was backed up' || exit 1

  {
    write_init_skill_stock
    printf '%s\n' '<!-- gentle-ai:sdd-init-rubric -->' 'one' '<!-- /gentle-ai:sdd-init-rubric -->'
    printf '%s\n' '<!-- gentle-ai:sdd-init-rubric -->' 'two' '<!-- /gentle-ai:sdd-init-rubric -->'
  } > "$file"
  cp -- "$file" "$TMP_ROOT/opencode-init-prompt-duplicate-before.md"
  load_overlay "$home" "$duplicate_backups"
  expect_rc 3 init_rubric_apply "$file" skill || exit 1
  cmp -s "$file" "$TMP_ROOT/opencode-init-prompt-duplicate-before.md" || fail 'duplicate-marker executable prompt changed' || exit 1
  [ ! -e "$duplicate_backups/.config/opencode/prompts/sdd/sdd-init.md" ] || fail 'duplicate-marker executable prompt was backed up' || exit 1

  write_init_skill_stock > "$file"
  load_overlay "$home" "$TMP_ROOT/opencode-init-prompt-drift-backups"
  snapshot="$(target_tmp "$file")"
  replacement="$(target_tmp "$file")"
  cp -p -- "$file" "$snapshot"
  printf '%s\n' 'replacement output' > "$replacement"
  printf '%s\n' 'concurrent writer' > "$file"
  expect_rc 5 commit_replacement "$file" "$snapshot" "$replacement" || exit 1
  grep -Fqx 'concurrent writer' "$file" || fail 'drifted executable prompt was overwritten' || exit 1
  rm -f -- "$snapshot" "$replacement"
)

write_init_details_stock() {
  cat <<'EOF'
# SDD Init Details

Installer-owned detection guidance.

## Output Templates

Installer-owned output guidance.
EOF
}

write_pi_init_stock() {
  cat <<'EOF'
---
name: sdd-init
---

Pi executor instructions.

## Memory Contract

Installer-owned persistence instructions.
EOF
}

expect_invalid_init_rubric_delta() {
  local fixture="$1"
  expect_rc 1 env APPLY_SH_LIB=1 INIT_RUBRIC_FILE="$fixture" bash -c 'source "$1"' _ "$ROOT/apply.sh" || return 1
}

test_init_rubric_source_shape_refusal() (
  local dir="$TMP_ROOT/init-source-shapes" duplicate missing unpaired nested reordered
  mkdir -p "$dir"
  duplicate="$dir/duplicate.md"
  missing="$dir/missing.md"
  unpaired="$dir/unpaired.md"
  nested="$dir/nested.md"
  reordered="$dir/reordered.md"
  printf '%s\n' '<!-- shape:skill -->' 'one' '<!-- /shape:skill -->' '<!-- shape:skill -->' 'two' '<!-- /shape:skill -->' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$duplicate"
  printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$missing"
  printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$unpaired"
  printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$nested"
  printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- /shape:details -->' '<!-- shape:details -->' 'details' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$reordered"
  expect_invalid_init_rubric_delta "$duplicate" || exit 1
  expect_invalid_init_rubric_delta "$missing" || exit 1
  expect_invalid_init_rubric_delta "$unpaired" || exit 1
  expect_invalid_init_rubric_delta "$nested" || exit 1
  expect_invalid_init_rubric_delta "$reordered" || exit 1
)

test_init_rubric_refuses_anchor_inside_managed_section() (
  local home="$TMP_ROOT/init-span-home" backups="$TMP_ROOT/init-span-backups" file before
  file="$home/.config/opencode/skills/sdd-init/SKILL.md"
  mkdir -p "$(dirname -- "$file")"
  cat > "$file" <<'EOF'
Before managed section.
<!-- gentle-ai:sdd-init-rubric -->
legacy managed content
## Decision Gates
legacy managed content
<!-- /gentle-ai:sdd-init-rubric -->
After managed section.
EOF
  before="$TMP_ROOT/init-span-before.md"
  cp -- "$file" "$before"

  load_overlay "$home" "$backups"
  expect_rc 3 init_rubric_apply "$file" skill || exit 1
  cmp -s "$file" "$before" || fail 'anchor-spanning managed section changed target' || exit 1
  grep -Fq '## Decision Gates' "$file" || fail 'anchor-spanning target lost required anchor' || exit 1
  [ ! -e "$backups/.config/opencode/skills/sdd-init/SKILL.md" ] || fail 'anchor-spanning refusal created a backup' || exit 1
)

test_init_rubric_shared_skill_idempotence_and_backup() (
  local home="$TMP_ROOT/init-skill-home" backups="$TMP_ROOT/init-skill-backups" file before
  file="$home/.config/opencode/skills/sdd-init/SKILL.md"
  mkdir -p "$(dirname -- "$file")"
  write_init_skill_stock > "$file"
  chmod 640 "$file"
  before="$TMP_ROOT/init-skill-before.md"
  cp -- "$file" "$before"

  load_overlay "$home" "$backups"
  expect_rc 0 init_rubric_apply "$file" skill || exit 1
  grep -Fq '<!-- gentle-ai:sdd-init-rubric -->' "$file" || fail 'shared skill rubric block was not inserted' || exit 1
  grep -Fq 'single writer of project TDD policy' "$file" || fail 'shared skill lacks producer ownership contract' || exit 1
  grep -Fq 'strictest-wins' "$file" || fail 'shared skill lacks strictest-wins contract' || exit 1
  grep -Fq 'Installer-owned introduction.' "$file" || fail 'shared skill surrounding content changed' || exit 1
  grep -Fq '## Decision Gates' "$file" || fail 'shared skill anchor changed' || exit 1
  [ "$(mode_of "$file")" = 640 ] || fail 'shared skill mode changed' || exit 1
  cmp -s "$before" "$backups/.config/opencode/skills/sdd-init/SKILL.md" || fail 'shared skill backup is not the original' || exit 1
  expect_rc 1 init_rubric_apply "$file" skill || exit 1
)

test_init_rubric_reference_and_pi_idempotence() (
  local home="$TMP_ROOT/init-reference-home" backups="$TMP_ROOT/init-reference-backups" reference pi
  reference="$home/.claude/skills/sdd-init/references/init-details.md"
  pi="$home/.pi/agent/agents/sdd-init.md"
  mkdir -p "$(dirname -- "$reference")" "$(dirname -- "$pi")"
  write_init_details_stock > "$reference"
  write_pi_init_stock > "$pi"

  load_overlay "$home" "$backups"
  expect_rc 0 init_rubric_apply "$reference" details || exit 1
  expect_rc 0 init_rubric_apply "$pi" pi || exit 1
  grep -Fq 'closed vocabulary' "$reference" || fail 'reference lacks closed evidence vocabulary' || exit 1
  grep -Fq 'openspec/config.yaml' "$reference" || fail 'reference lacks OpenSpec persistence contract' || exit 1
  grep -Fq 'allowed_answers: strict|rubric' "$pi" || fail 'Pi agent lacks blocking answer domain' || exit 1
  grep -Fq 'STOP: do not continue to downstream phases.' "$pi" || fail 'Pi agent lacks blocking stop instruction' || exit 1
  expect_rc 1 init_rubric_apply "$reference" details || exit 1
  expect_rc 1 init_rubric_apply "$pi" pi || exit 1
)

test_init_rubric_replaces_complete_section() (
  local home="$TMP_ROOT/init-replace-home" backups="$TMP_ROOT/init-replace-backups" file
  file="$home/.codex/skills/sdd-init/SKILL.md"
  mkdir -p "$(dirname -- "$file")"
  cat > "$file" <<'EOF'
Before managed section.
<!-- gentle-ai:sdd-init-rubric -->
<!-- /gentle-ai:sdd-init-rubric -->

## Decision Gates

After managed section.
EOF

  load_overlay "$home" "$backups"
  expect_rc 0 init_rubric_apply "$file" skill || exit 1
  grep -Fq 'Before managed section.' "$file" || fail 'replacement changed preceding content' || exit 1
  grep -Fq 'After managed section.' "$file" || fail 'replacement changed following content' || exit 1
  grep -Fq 'stale managed content' "$file" && fail 'replacement retained stale managed content' && exit 1
  grep -Fq 'mechanical strictest-wins MODE precedence' "$file" || fail 'replacement lacks mechanical strictest-wins contract' || exit 1
  expect_rc 1 init_rubric_apply "$file" skill || exit 1
)

test_init_rubric_refuses_ambiguous_or_partial_shapes() (
  local home="$TMP_ROOT/init-refusal-home" backups="$TMP_ROOT/init-refusal-backups" skill details pi duplicate before
  skill="$home/.config/opencode/skills/sdd-init/SKILL.md"
  details="$home/.config/opencode/skills/sdd-init/references/init-details.md"
  pi="$home/.pi/agent/agents/sdd-init.md"
  duplicate="$home/.claude/skills/sdd-init/SKILL.md"
  mkdir -p "$(dirname -- "$skill")" "$(dirname -- "$details")" "$(dirname -- "$pi")" "$(dirname -- "$duplicate")"

  printf '%s\n' 'no decision anchor' > "$skill"
  write_init_details_stock | awk '/^## Output Templates$/{print} {print}' > "$details"
  {
    write_pi_init_stock
    printf '%s\n' '<!-- gentle-ai:sdd-init-rubric -->' 'partial managed block'
  } > "$pi"
  {
    write_init_skill_stock
    printf '%s\n' '<!-- gentle-ai:sdd-init-rubric -->' 'one' '<!-- /gentle-ai:sdd-init-rubric -->'
    printf '%s\n' '<!-- gentle-ai:sdd-init-rubric -->' 'two' '<!-- /gentle-ai:sdd-init-rubric -->'
  } > "$duplicate"
  before="$TMP_ROOT/init-refusal-before.md"
  cp -- "$pi" "$before"

  load_overlay "$home" "$backups"
  expect_rc 3 init_rubric_apply "$skill" skill || exit 1
  expect_rc 3 init_rubric_apply "$details" details || exit 1
  expect_rc 3 init_rubric_apply "$pi" pi || exit 1
  expect_rc 3 init_rubric_apply "$duplicate" skill || exit 1
  cmp -s "$pi" "$before" || fail 'partial-marker Pi target changed' || exit 1
  [ ! -e "$backups/.pi/agent/agents/sdd-init.md" ] || fail 'refused target was backed up' || exit 1
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
run test_rubric_list_replaces_legacy_item4
run test_rubric_list_refuses_ambiguous_headings
run test_cli_check_semantics
run test_symlink_refusal
run test_backup_failure_is_closed
run test_target_drift_is_closed
run test_installed_hosts_fallback_includes_gemini
run test_sdd_init_host_rows_cover_cursor_and_copilot
run test_antigravity_skill_root_resolution
run test_opencode_sdd_init_prompt_lifecycle_and_reachability
run test_init_rubric_source_shape_refusal
run test_init_rubric_refuses_anchor_inside_managed_section
run test_init_rubric_shared_skill_idempotence_and_backup
run test_init_rubric_reference_and_pi_idempotence
run test_init_rubric_replaces_complete_section
run test_init_rubric_refuses_ambiguous_or_partial_shapes

bash "$ROOT/tests/init-rubric-contract.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-compiler-core.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
