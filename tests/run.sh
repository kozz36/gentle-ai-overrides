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

load_overlay_with_roots() {
  local home="$1" agent_home="$2" pi_home="$3" backups="$4"
  HOME="$home"
  GENTLE_PI_AGENT_HOME="$agent_home"
  PI_CODING_AGENT_DIR="$pi_home"
  GENTLE_AI_BACKUP_ROOT="$backups"
  APPLY_SH_LIB=1
  export HOME GENTLE_PI_AGENT_HOME PI_CODING_AGENT_DIR GENTLE_AI_BACKUP_ROOT APPLY_SH_LIB
  # shellcheck source=../apply.sh
  source "$ROOT/apply.sh"
}

write_diag_package() {
  local home="$1" root version="${2:-test}"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  mkdir -p "$root/assets/agents" "$root/assets/chains" "$root/assets/support"
  printf '{"name":"gentle-pi","version":"%s"}\n' "$version" > "$root/package.json"
  printf '%s\n' 'current chain' > "$root/assets/chains/sdd-full.chain.md"
  write_pi_init_stock > "$root/assets/agents/sdd-init.md"
  write_pi_workflow_220_fixture > "$root/assets/sdd-orchestrator-workflow.md"
}

write_diag_manifest() {
  local home="$1" hash="$2"
  mkdir -p "$home/.pi/agent/gentle-ai"
  printf '{"schemaVersion":1,"assets":{"chains/sdd-full.chain.md":"%s"}}\n' "$hash" > "$home/.pi/agent/gentle-ai/managed-assets.json"
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

test_rubric_list_migrates_predecessor_item4_and_cache() (
  local home="$TMP_ROOT/rubric-list-home" backups="$TMP_ROOT/rubric-list-backups" md json loose before json_before json_after transformed expected loose_expected
  local predecessor_cache='The orchestrator consumes validated rubric state ONCE per session (at first apply/verify launch) and caches it, classifying each apply slice by declared intent corroborated by its diff.'
  md="$home/.pi/agent/APPEND_SYSTEM.md"
  json="$home/.config/opencode/opencode.json"
  loose="$home/.pi/agent/LEGACY_PROSE.md"
  before="$TMP_ROOT/rubric-list-before.md"
  json_before="$TMP_ROOT/rubric-list-before.json"
  json_after="$TMP_ROOT/rubric-list-after.json"
  transformed="$TMP_ROOT/rubric-list-transformed.md"
  expected="$TMP_ROOT/rubric-list-expected.md"
  loose_expected="$TMP_ROOT/rubric-list-loose-expected.md"
  mkdir -p "$(dirname -- "$md")" "$(dirname -- "$json")"
  cat > "$md" <<'EOF'
Before the strict-TDD forwarding list.
3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate.
   The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols,
   reject incompatible intents, then forward its one combined row and canonical-model digest without downstream
   re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched
   state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever
   been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and
   Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
5. Subsequent numbered-list item must survive unchanged.
The orchestrator consumes validated rubric state ONCE per session (at first apply/verify launch) and caches it, classifying each apply slice by declared intent corroborated by its diff.
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

  rubric_transform_list < "$md" > "$transformed" || fail 'predecessor list transform refused a valid fixture' || exit 1
  cmp -s "$transformed" "$expected" || fail 'predecessor list transform did not replace the complete item 4 block and cache sentence' || exit 1
  ! grep -Fq "$predecessor_cache" "$transformed" || fail 'predecessor cache sentence survived list transform' || exit 1
  grep -Fq '5. Subsequent numbered-list item must survive unchanged.' "$transformed" || fail 'transform consumed item 5' || exit 1
  grep -Fq 'Following cache prose must survive unchanged.' "$transformed" || fail 'transform consumed following cache prose' || exit 1

  CHECK_ONLY=1
  expect_rc 0 rubric_apply_md "$md" list || exit 1
  cmp -s "$md" "$before" || fail 'Markdown rubric check changed its target' || exit 1
  CHECK_ONLY=0
  expect_rc 0 rubric_apply_md "$md" list || exit 1
  cmp -s "$md" "$expected" || fail 'Markdown rubric apply did not install canonical content' || exit 1
  expect_rc 1 rubric_apply_md "$md" list || exit 1
  cmp -s "$md" "$expected" || fail 'reapplying Markdown predecessor migration was not byte-idempotent' || exit 1

  jq -n --rawfile prompt "$before" '{agent: {"gentle-orchestrator": {prompt: $prompt}}}' > "$json"
  cp -- "$json" "$json_before"
  CHECK_ONLY=1
  expect_rc 0 rubric_apply_json "$json" || exit 1
  cmp -s "$json" "$json_before" || fail 'JSON rubric check changed its target' || exit 1
  CHECK_ONLY=0
  expect_rc 0 rubric_apply_json "$json" || exit 1
  jq -e --rawfile expected "$expected" '.agent["gentle-orchestrator"].prompt == $expected' "$json" >/dev/null || fail 'JSON rubric apply did not install canonical content' || exit 1
  jq -e --arg obsolete "$predecessor_cache" \
    '.agent["gentle-orchestrator"].prompt | contains($obsolete) | not' "$json" >/dev/null ||
    fail 'predecessor cache sentence survived JSON transform' || exit 1
  cp -- "$json" "$json_after"
  expect_rc 1 rubric_apply_json "$json" || exit 1
  cmp -s "$json" "$json_after" || fail 'reapplying JSON predecessor migration was not byte-idempotent' || exit 1

  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction' '' "$RUBRIC_PROSE" '' "$CACHE_OLD"
  } > "$loose"
  {
    printf '%s\n' '3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction' "$RUBRIC_ITEM4" '' "$CACHE_NEW"
  } > "$loose_expected"
  rubric_transform_list < "$loose" > "$transformed" || fail 'legacy loose paragraph transform refused a valid fixture' || exit 1
  cmp -s "$transformed" "$loose_expected" || fail 'legacy loose paragraph was not migrated' || exit 1
)

test_rubric_prose_migrates_known_predecessor_exactly() (
  local home="$TMP_ROOT/rubric-prose-home" backups="$TMP_ROOT/rubric-prose-backups" file before after duplicate ambiguous output
  local prose_anchor='When launching `sdd-apply` or `sdd-verify`, search for testing capabilities'
  local base_8f030e8_prose='Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate. The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /gentle-sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.'
  file="$home/.claude/skills/_shared/sdd-orchestrator-workflow.md"
  before="$TMP_ROOT/rubric-prose-before.md"
  after="$TMP_ROOT/rubric-prose-after.md"
  duplicate="$home/.claude/skills/_shared/DUPLICATE.md"
  ambiguous="$home/.claude/skills/_shared/AMBIGUOUS.md"
  output="$TMP_ROOT/rubric-prose-output.md"
  mkdir -p "$(dirname -- "$file")"
  {
    printf '%s\n' 'Before the condensed Strict TDD section.' "$prose_anchor" '' "$base_8f030e8_prose" '' 'After the managed prose must survive unchanged.'
  } > "$file"
  cp -- "$file" "$before"

  load_overlay "$home" "$backups"
  expect_rc 0 rubric_apply_md "$file" prose || exit 1
  [ "$(grep -Fxc "$RUBRIC_PROSE" "$file")" -eq 1 ] || fail 'known predecessor prose was not replaced by one canonical prose block' || exit 1
  ! grep -Fq "$base_8f030e8_prose" "$file" || fail 'known predecessor prose survived migration' || exit 1
  grep -Fqx 'Before the condensed Strict TDD section.' "$file" || fail 'predecessor migration changed leading surrounding text' || exit 1
  grep -Fqx 'After the managed prose must survive unchanged.' "$file" || fail 'predecessor migration changed trailing surrounding text' || exit 1
  cp -- "$file" "$after"
  expect_rc 1 rubric_apply_md "$file" prose || exit 1
  cmp -s "$file" "$after" || fail 'reapplying migrated prose was not byte-idempotent' || exit 1
  grep -Fq "$base_8f030e8_prose" "$before" || fail 'fixture does not contain the base 8f030e8 predecessor prose' || exit 1

  printf '%s\n' "$prose_anchor" "$base_8f030e8_prose" "$base_8f030e8_prose" > "$duplicate"
  cp -- "$duplicate" "$before"
  rubric_transform_prose < "$duplicate" > "$output" && fail 'duplicate predecessor prose was transformed' && exit 1
  expect_rc 3 rubric_apply_md "$duplicate" prose || exit 1
  cmp -s "$duplicate" "$before" || fail 'duplicate predecessor prose target changed after refusal' || exit 1

  printf '%s\n' "$prose_anchor" "$base_8f030e8_prose" "$RUBRIC_PROSE" > "$ambiguous"
  cp -- "$ambiguous" "$before"
  rubric_transform_prose < "$ambiguous" > "$output" && fail 'mixed predecessor and canonical prose was transformed' && exit 1
  expect_rc 3 rubric_apply_md "$ambiguous" prose || exit 1
  cmp -s "$ambiguous" "$before" || fail 'mixed predecessor and canonical prose target changed after refusal' || exit 1
)

test_human_clarification_without_runtime_dispatch() (
  local home="$TMP_ROOT/clarification-actions-home" backups="$TMP_ROOT/clarification-actions-backups" list prose workflow output
  list="$home/list.md"
  prose="$home/prose.md"
  workflow="$home/workflow.md"
  output="$TMP_ROOT/clarification-actions-output.md"
  mkdir -p "$home"

  load_overlay "$home" "$backups"
  printf '%s\n' "$ANCHOR_ITEM3" > "$list"
  rubric_transform_list < "$list" > "$output" || fail 'list clarification transform refused its anchor' || exit 1
  grep -Fq 'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' "$output" || fail 'list/OpenCode does not stop for human clarification' || exit 1
  grep -Fq 'do not fabricate runtime recovery dispatch.' "$output" || fail 'list/OpenCode permits runtime recovery dispatch' || exit 1
  ! grep -Fq 'recovery_action=run ' "$output" || fail 'list/OpenCode fabricated a recovery command' || exit 1

  printf '%s\n' "$ANCHOR_PROSE" > "$prose"
  rubric_transform_prose < "$prose" > "$output" || fail 'Claude prose clarification transform refused its anchor' || exit 1
  grep -Fq 'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' "$output" || fail 'Claude prose does not stop for human clarification' || exit 1
  ! grep -Fq 'recovery_action=run ' "$output" || fail 'Claude prose fabricated a recovery command' || exit 1

  write_pi_workflow_220_fixture > "$workflow"
  pi_rubric_workflow_transform < "$workflow" > "$output" || fail 'Pi clarification transform refused its workflow fixture' || exit 1
  grep -Fq 'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' "$output" || fail 'Pi workflow does not stop for human clarification' || exit 1
  ! grep -Fq 'recovery_action=run ' "$output" || fail 'Pi workflow fabricated a recovery command' || exit 1
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

write_pi_workflow_220_fixture() {
  cat <<'EOF'
## Strict TDD Forwarding

For `sdd-apply` and `sdd-verify`, read `openspec/config.yaml` when present.

If it declares strict TDD and a test command, include a non-negotiable instruction in the phase prompt:

```text
STRICT TDD MODE IS ACTIVE. Test runner: <command>. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.
```

Do not rely on the child agent to discover this independently.

## Archive Final-State Handoff

When launching `sdd-archive`, forward explicit final-state facts for any work completed after `apply-progress`, `verify-report`, or `sync-report` were persisted — verify warnings fixed in later commits, blockers resolved, tasks finished, updated test or issue counts — with commit or evidence references where available. Those artifacts are intermediate snapshots, valid at the time they were written; the archive report records the state at close, and explicit final-state facts in the `sdd-archive` launch prompt outrank stale snapshot claims.
EOF
}

write_pi_workflow_220_with_gap() {
  local gap="$1"
  write_pi_workflow_220_fixture | awk -v gap="$gap" '
    $0 == "## Archive Final-State Handoff" { print ""; print gap; print "" }
    { print }
  '
}

PI_GIT_PACKAGE_ROOT_REL='.pi/agent/git/github.com/Gentleman-Programming/gentle-pi'
PI_NPM_PACKAGE_ROOT_REL='.pi/agent/npm/node_modules/gentle-pi'
PI_GIT_WORKFLOW_REL="$PI_GIT_PACKAGE_ROOT_REL/assets/sdd-orchestrator-workflow.md"
PI_NPM_WORKFLOW_REL="$PI_NPM_PACKAGE_ROOT_REL/assets/sdd-orchestrator-workflow.md"
PI_GIT_INIT_REL="$PI_GIT_PACKAGE_ROOT_REL/assets/agents/sdd-init.md"
PI_NPM_INIT_REL="$PI_NPM_PACKAGE_ROOT_REL/assets/agents/sdd-init.md"
PI_WORKFLOW_PLACEHOLDER='@pi-gentle-pi-workflow@'
PI_SDD_INIT_PLACEHOLDER='@pi-gentle-pi-sdd-init@'

prepare_pi_package_home() {
  local home="$1"
  mkdir -p "$home/.gentle-ai" "$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  write_pi_init_stock > "$home/$PI_NPM_INIT_REL"
}

write_pi_workflow_at() {
  local file="$1"
  mkdir -p "$(dirname -- "$file")"
  write_pi_workflow_220_fixture > "$file"
}

write_pi_init_at() {
  local file="$1"
  mkdir -p "$(dirname -- "$file")"
  write_pi_init_stock > "$file"
}

write_pi_package_settings() {
  local home="$1" settings="$2"
  mkdir -p "$home/.pi/agent"
  printf '%s\n' "$settings" > "$home/.pi/agent/settings.json"
}

prepare_no_jq_path() {
  local bin="$1" node_bin="$2" tool target
  mkdir -p "$bin"
  for tool in awk basename bash cat cmp cp cut date dirname env grep head mkdir mktemp mv rm sed stat; do
    target="$(command -v "$tool")" || return 1
    ln -s "$target" "$bin/$tool" || return 1
  done
  if [ -n "$node_bin" ]; then
    [ -x "$node_bin" ] || return 1
    ln -s "$node_bin" "$bin/node" || return 1
  fi
}

assert_no_jq_node_path() {
  local expected_node="$1"
  if command -v jq >/dev/null 2>&1; then
    fail 'jq remained available in a no-jq PATH' || return 1
  fi
  if [ -n "$expected_node" ]; then
    [ "$(command -v node)" = "$expected_node" ] || fail 'the intended Node parser was not available in a no-jq PATH' || return 1
    node -e 'process.exit(0)' || fail 'the intended Node parser did not execute' || return 1
  elif command -v node >/dev/null 2>&1; then
    fail 'Node remained available in a no-parser PATH' || return 1
  fi
}

# A malformed logical source must stop before stale package roots or any Pi target
# can be selected. parser_path lets the same cases cover jq and the Node fallback.
assert_pi_framed_source_fails_closed_before_writes() {
  local parser="$1" parser_path="$2" label="$3" settings="$4"
  local home="$TMP_ROOT/pi-$parser-framing-$label-home" backups="$TMP_ROOT/pi-$parser-framing-$label-backups"
  local npm_workflow init_file npm_before init_before output apply_output rc
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  npm_before="$TMP_ROOT/pi-$parser-framing-$label-npm-before.md"
  init_before="$TMP_ROOT/pi-$parser-framing-$label-init-before.md"
  output="$TMP_ROOT/pi-$parser-framing-$label-output.txt"
  apply_output="$TMP_ROOT/pi-$parser-framing-$label-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" "$settings"
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$init_file" "$init_before"

  PATH="$parser_path" HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "$parser $label framed source apply returned $rc" || return 1
  PATH="$parser_path" HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "$parser $label framed source check returned $rc" || return 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail "$parser $label framed source did not report package target failure" || return 1
  cmp -s "$npm_workflow" "$npm_before" || fail "$parser $label framed source changed stale workflow" || return 1
  cmp -s "$init_file" "$init_before" || fail "$parser $label framed source changed Pi init" || return 1
  [ ! -e "$backups" ] || fail "$parser $label framed source created backups before writes" || return 1
}

test_pi_git_only_layout() (
  local home="$TMP_ROOT/pi-git-only-home" backups="$TMP_ROOT/pi-git-only-backups" workflow init
  mkdir -p "$home/.gentle-ai"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_init_at "$home/$PI_GIT_INIT_REL"

  load_overlay "$home" "$backups"
  workflow="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'git-only Pi workflow did not resolve' || exit 1
  init="$(resolve_target_rel pi "$PI_SDD_INIT_PLACEHOLDER")" || fail 'git-only Pi sdd-init did not resolve' || exit 1
  [ "$workflow" = "$PI_GIT_WORKFLOW_REL" ] || fail "git-only Pi workflow resolved $workflow" || exit 1
  [ "$init" = "$PI_GIT_INIT_REL" ] || fail "git-only Pi sdd-init resolved $init" || exit 1
  host_rows | grep -Fqx "pi|pi-rubric-workflow|$PI_WORKFLOW_PLACEHOLDER" || fail 'Pi workflow row is not resolver-backed' || exit 1
  host_rows | grep -Fqx "pi|sdd-init-pi|$PI_SDD_INIT_PLACEHOLDER" || fail 'Pi sdd-init row is not resolver-backed' || exit 1
)

test_pi_npm_only_layout() (
  local home="$TMP_ROOT/pi-npm-only-home" backups="$TMP_ROOT/pi-npm-only-backups" workflow init
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"

  load_overlay "$home" "$backups"
  workflow="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'npm-only Pi workflow did not resolve' || exit 1
  init="$(resolve_target_rel pi "$PI_SDD_INIT_PLACEHOLDER")" || fail 'npm-only Pi sdd-init did not resolve' || exit 1
  [ "$workflow" = "$PI_NPM_WORKFLOW_REL" ] || fail "npm-only Pi workflow resolved $workflow" || exit 1
  [ "$init" = "$PI_NPM_INIT_REL" ] || fail "npm-only Pi sdd-init resolved $init" || exit 1
)

test_pi_both_layouts_git_configured() (
  local home="$TMP_ROOT/pi-both-git-home" backups="$TMP_ROOT/pi-both-git-backups" workflow init
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_init_at "$home/$PI_GIT_INIT_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'

  load_overlay "$home" "$backups"
  workflow="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'configured git Pi workflow did not resolve' || exit 1
  init="$(resolve_target_rel pi "$PI_SDD_INIT_PLACEHOLDER")" || fail 'configured git Pi sdd-init did not resolve' || exit 1
  [ "$workflow" = "$PI_GIT_WORKFLOW_REL" ] || fail 'configured git source did not beat stale npm workflow' || exit 1
  [ "$init" = "$PI_GIT_INIT_REL" ] || fail 'configured git source did not beat stale npm sdd-init' || exit 1
  [ "${workflow%/assets/sdd-orchestrator-workflow.md}" = "${init%/assets/agents/sdd-init.md}" ] || fail 'configured git Pi assets did not share one package root' || exit 1
)

test_pi_both_layouts_npm_configured() (
  local home="$TMP_ROOT/pi-both-npm-home" backups="$TMP_ROOT/pi-both-npm-backups" workflow init
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_init_at "$home/$PI_GIT_INIT_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.3.0-rc.1"]}'

  load_overlay "$home" "$backups"
  workflow="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'configured npm Pi workflow did not resolve' || exit 1
  init="$(resolve_target_rel pi "$PI_SDD_INIT_PLACEHOLDER")" || fail 'configured npm Pi sdd-init did not resolve' || exit 1
  [ "$workflow" = "$PI_NPM_WORKFLOW_REL" ] || fail 'configured npm source did not beat stale git workflow' || exit 1
  [ "$init" = "$PI_NPM_INIT_REL" ] || fail 'configured npm source did not beat stale git sdd-init' || exit 1
  [ "${workflow%/assets/sdd-orchestrator-workflow.md}" = "${init%/assets/agents/sdd-init.md}" ] || fail 'configured npm Pi assets did not share one package root' || exit 1
)

test_pi_final_240_npm_dual_assets() (
  local home="$TMP_ROOT/pi-final-240-home" backups="$TMP_ROOT/pi-final-240-backups" output rc
  local npm_workflow npm_init git_workflow git_init git_workflow_before git_init_before
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  npm_init="$home/$PI_NPM_INIT_REL"
  git_workflow="$home/$PI_GIT_WORKFLOW_REL"
  git_init="$home/$PI_GIT_INIT_REL"
  git_workflow_before="$TMP_ROOT/pi-final-240-git-workflow-before.md"
  git_init_before="$TMP_ROOT/pi-final-240-git-init-before.md"
  output="$TMP_ROOT/pi-final-240-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_workflow_at "$git_workflow"
  write_pi_init_at "$git_init"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.4.0"]}'
  cp -- "$git_workflow" "$git_workflow_before"
  cp -- "$git_init" "$git_init_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output"
  rc=$?
  [ "$rc" -eq 2 ] || fail "final gentle-pi 2.4.0 npm dual-asset check returned $rc" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$output" || exit 1
  grep -Fq '<!-- gentle-ai:pi-rubric-forwarding -->' "$npm_workflow" || fail 'final gentle-pi 2.4.0 npm workflow was not transformed' || exit 1
  grep -Fq '<!-- gentle-ai:sdd-init-rubric -->' "$npm_init" || fail 'final gentle-pi 2.4.0 npm sdd-init asset was not transformed' || exit 1
  cmp -s "$git_workflow" "$git_workflow_before" || fail 'final gentle-pi 2.4.0 npm selection changed stale git workflow' || exit 1
  cmp -s "$git_init" "$git_init_before" || fail 'final gentle-pi 2.4.0 npm selection changed stale git sdd-init asset' || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output"
  rc=$?
  [ "$rc" -eq 0 ] || fail "final gentle-pi 2.4.0 npm dual assets were not clean after apply: $rc" || exit 1
)

test_pi_both_layouts_without_jq_fails_before_writes() (
  local home="$TMP_ROOT/pi-no-jq-home" backups="$TMP_ROOT/pi-no-jq-backups" bin="$TMP_ROOT/pi-no-jq-bin"
  local git_workflow npm_workflow append git_before npm_before append_before output rc node_bin
  git_workflow="$home/$PI_GIT_WORKFLOW_REL"
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  append="$home/.pi/agent/APPEND_SYSTEM.md"
  git_before="$TMP_ROOT/pi-no-jq-git-before.md"
  npm_before="$TMP_ROOT/pi-no-jq-npm-before.md"
  append_before="$TMP_ROOT/pi-no-jq-append-before.md"
  output="$TMP_ROOT/pi-no-jq-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$git_workflow"
  write_pi_workflow_at "$npm_workflow"
  printf '%s\n' 'installer-owned Pi APPEND' > "$append"
  cp -- "$git_workflow" "$git_before"
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$append" "$append_before"
  node_bin="$(command -v node)" || fail 'Node is required for no-jq parser coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq command path' || exit 1

  PATH="$bin"
  assert_no_jq_node_path "$bin/node" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "no-jq ambiguous Pi layouts returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'no-jq ambiguity did not report package target failure' || exit 1
  cmp -s "$git_workflow" "$git_before" || fail 'no-jq ambiguity changed git workflow' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'no-jq ambiguity changed npm workflow' || exit 1
  cmp -s "$append" "$append_before" || fail 'no-jq ambiguity changed Pi APPEND' || exit 1
  [ ! -e "$backups" ] || fail 'no-jq ambiguity created backups before writes' || exit 1
)

test_pi_no_jq_node_unsupported_exact_source_fails_before_writes() (
  local home="$TMP_ROOT/pi-no-jq-node-unsupported-home" backups="$TMP_ROOT/pi-no-jq-node-unsupported-backups" bin="$TMP_ROOT/pi-no-jq-node-unsupported-bin"
  local npm_workflow init_file npm_before init_before output apply_output rc node_bin
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  npm_before="$TMP_ROOT/pi-no-jq-node-unsupported-npm-before.md"
  init_before="$TMP_ROOT/pi-no-jq-node-unsupported-init-before.md"
  output="$TMP_ROOT/pi-no-jq-node-unsupported-output.txt"
  apply_output="$TMP_ROOT/pi-no-jq-node-unsupported-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["file:/opt/gentle-pi"]}'
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$init_file" "$init_before"
  node_bin="$(command -v node)" || fail 'Node is required for no-jq parser coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq Node command path' || exit 1

  PATH="$bin"
  assert_no_jq_node_path "$bin/node" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "no-jq Node unsupported source apply returned $rc" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "no-jq Node unsupported source check returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'no-jq Node unsupported source did not report package target failure' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'no-jq Node unsupported source changed the stale workflow' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'no-jq Node unsupported source changed Pi init' || exit 1
  [ ! -e "$backups" ] || fail 'no-jq Node unsupported source created backups before writes' || exit 1
)

test_pi_no_jq_node_canonical_source_selects_configured_root() (
  local home="$TMP_ROOT/pi-no-jq-node-canonical-home" backups="$TMP_ROOT/pi-no-jq-node-canonical-backups" bin="$TMP_ROOT/pi-no-jq-node-canonical-bin"
  local actual node_bin
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'
  node_bin="$(command -v node)" || fail 'Node is required for no-jq parser coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq Node command path' || exit 1

  load_overlay "$home" "$backups"
  PATH="$bin"
  assert_no_jq_node_path "$bin/node" || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'no-jq Node canonical source did not resolve' || exit 1
  [ "$actual" = "$PI_GIT_WORKFLOW_REL" ] || fail 'no-jq Node canonical source did not select the configured git layout' || exit 1
)

test_pi_settings_without_safe_parser_fail_closed() (
  local home="$TMP_ROOT/pi-no-parser-home" backups="$TMP_ROOT/pi-no-parser-backups" bin="$TMP_ROOT/pi-no-parser-bin"
  local npm_workflow init_file npm_before init_before output apply_output rc
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  npm_before="$TMP_ROOT/pi-no-parser-npm-before.md"
  init_before="$TMP_ROOT/pi-no-parser-init-before.md"
  output="$TMP_ROOT/pi-no-parser-output.txt"
  apply_output="$TMP_ROOT/pi-no-parser-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.3.0-rc.1"]}'
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$init_file" "$init_before"
  prepare_no_jq_path "$bin" '' || fail 'could not create no-parser command path' || exit 1

  PATH="$bin"
  assert_no_jq_node_path '' || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "settings without a safe parser apply returned $rc" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "settings without a safe parser check returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'settings without a safe parser did not report package target failure' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'settings without a safe parser changed the workflow' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'settings without a safe parser changed Pi init' || exit 1
  [ ! -e "$backups" ] || fail 'settings without a safe parser created backups before writes' || exit 1
)

test_pi_no_jq_node_invalid_settings_fail_closed() (
  local home="$TMP_ROOT/pi-no-jq-node-invalid-home" backups="$TMP_ROOT/pi-no-jq-node-invalid-backups" bin="$TMP_ROOT/pi-no-jq-node-invalid-bin"
  local npm_workflow init_file npm_before init_before output apply_output rc node_bin
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  npm_before="$TMP_ROOT/pi-no-jq-node-invalid-npm-before.md"
  init_before="$TMP_ROOT/pi-no-jq-node-invalid-init-before.md"
  output="$TMP_ROOT/pi-no-jq-node-invalid-output.txt"
  apply_output="$TMP_ROOT/pi-no-jq-node-invalid-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":['
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$init_file" "$init_before"
  node_bin="$(command -v node)" || fail 'Node is required for no-jq parser coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq Node command path' || exit 1

  PATH="$bin"
  assert_no_jq_node_path "$bin/node" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "no-jq Node invalid settings apply returned $rc" || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "no-jq Node invalid settings check returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'no-jq Node invalid settings did not report package target failure' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'no-jq Node invalid settings changed the workflow' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'no-jq Node invalid settings changed Pi init' || exit 1
  [ ! -e "$backups" ] || fail 'no-jq Node invalid settings created backups before writes' || exit 1
)

test_pi_no_jq_settings_absent_unique_root_fallback() (
  local home="$TMP_ROOT/pi-no-jq-settings-absent-home" backups="$TMP_ROOT/pi-no-jq-settings-absent-backups" bin="$TMP_ROOT/pi-no-jq-settings-absent-bin"
  local actual node_bin
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  node_bin="$(command -v node)" || fail 'Node is required for no-jq parser coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq Node command path' || exit 1

  load_overlay "$home" "$backups"
  PATH="$bin"
  assert_no_jq_node_path "$bin/node" || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'no-jq settings-absent unique root did not resolve' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'no-jq settings-absent unique root selected the wrong layout' || exit 1
)

test_pi_no_jq_node_object_source_selects_npm() (
  local home="$TMP_ROOT/pi-no-jq-node-object-home" backups="$TMP_ROOT/pi-no-jq-node-object-backups" bin="$TMP_ROOT/pi-no-jq-node-object-bin"
  local actual node_bin
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":[{"source":"npm:gentle-pi@2.3.0-rc.1"}]}'
  node_bin="$(command -v node)" || fail 'Node is required for no-jq parser coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq Node command path' || exit 1

  load_overlay "$home" "$backups"
  PATH="$bin"
  assert_no_jq_node_path "$bin/node" || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'no-jq Node object source did not resolve' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'no-jq Node object source did not select npm layout' || exit 1
)

test_pi_jq_json_source_record_framing() (
  local parser_path="$PATH" case_name settings home backups actual configured
  command -v jq >/dev/null 2>&1 || fail 'jq is required for jq record-framing coverage' || exit 1

  for case_name in newline carriage-return tab backslash quote; do
    case "$case_name" in
      newline) settings='{"packages":["garbage\nnpm:gentle-pi@1"]}' ;;
      carriage-return) settings='{"packages":["npm:gentle-pi@1\rsuffix"]}' ;;
      tab) settings='{"packages":["npm:gentle-pi@1\tsuffix"]}' ;;
      backslash) settings='{"packages":["npm:gentle-pi@1\\suffix"]}' ;;
      quote) settings='{"packages":["npm:gentle-pi@1\"suffix"]}' ;;
    esac
    assert_pi_framed_source_fails_closed_before_writes jq "$parser_path" "$case_name" "$settings" || exit 1
  done

  home="$TMP_ROOT/pi-jq-framing-canonical-home"
  backups="$TMP_ROOT/pi-jq-framing-canonical-backups"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.3.0-rc.1"]}'
  load_overlay "$home" "$backups"
  configured="$(pi_configured_package_kind)" || fail 'jq canonical framed source did not classify' || exit 1
  [ "$configured" = npm ] || fail 'jq canonical framed source selected the wrong kind' || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'jq canonical framed source did not resolve' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'jq canonical framed source selected the wrong root' || exit 1

  home="$TMP_ROOT/pi-jq-framing-helper-home"
  backups="$TMP_ROOT/pi-jq-framing-helper-backups"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi-helper@1\nnot-a-gentle-pi-helper"]}'
  load_overlay "$home" "$backups"
  expect_rc 1 pi_configured_package_kind || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'jq escaped helper source blocked unique npm fallback' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'jq escaped helper source selected the wrong root' || exit 1
)

test_pi_no_jq_node_json_source_record_framing() (
  local bin="$TMP_ROOT/pi-no-jq-node-framing-bin" node_bin parser_path case_name settings home backups actual configured
  node_bin="$(command -v node)" || fail 'Node is required for no-jq record-framing coverage' || exit 1
  prepare_no_jq_path "$bin" "$node_bin" || fail 'could not create no-jq record-framing command path' || exit 1
  parser_path="$bin"
  PATH="$parser_path"
  assert_no_jq_node_path "$bin/node" || exit 1

  for case_name in newline carriage-return tab backslash quote; do
    case "$case_name" in
      newline) settings='{"packages":["garbage\nnpm:gentle-pi@1"]}' ;;
      carriage-return) settings='{"packages":["npm:gentle-pi@1\rsuffix"]}' ;;
      tab) settings='{"packages":["npm:gentle-pi@1\tsuffix"]}' ;;
      backslash) settings='{"packages":["npm:gentle-pi@1\\suffix"]}' ;;
      quote) settings='{"packages":["npm:gentle-pi@1\"suffix"]}' ;;
    esac
    assert_pi_framed_source_fails_closed_before_writes node "$parser_path" "$case_name" "$settings" || exit 1
  done

  home="$TMP_ROOT/pi-no-jq-node-framing-canonical-home"
  backups="$TMP_ROOT/pi-no-jq-node-framing-canonical-backups"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.3.0-rc.1"]}'
  load_overlay "$home" "$backups"
  configured="$(pi_configured_package_kind)" || fail 'no-jq Node canonical framed source did not classify' || exit 1
  [ "$configured" = npm ] || fail 'no-jq Node canonical framed source selected the wrong kind' || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'no-jq Node canonical framed source did not resolve' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'no-jq Node canonical framed source selected the wrong root' || exit 1

  home="$TMP_ROOT/pi-no-jq-node-framing-helper-home"
  backups="$TMP_ROOT/pi-no-jq-node-framing-helper-backups"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi-helper@1\nnot-a-gentle-pi-helper"]}'
  load_overlay "$home" "$backups"
  expect_rc 1 pi_configured_package_kind || exit 1
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'no-jq Node escaped helper source blocked unique npm fallback' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'no-jq Node escaped helper source selected the wrong root' || exit 1
)

test_pi_conflicting_configured_sources_fail() (
  local home="$TMP_ROOT/pi-conflicting-home" backups="$TMP_ROOT/pi-conflicting-backups"
  local git_workflow npm_workflow git_before npm_before output rc
  git_workflow="$home/$PI_GIT_WORKFLOW_REL"
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  git_before="$TMP_ROOT/pi-conflicting-git-before.md"
  npm_before="$TMP_ROOT/pi-conflicting-npm-before.md"
  output="$TMP_ROOT/pi-conflicting-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$git_workflow"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd","npm:gentle-pi@2.3.0-rc.1"]}'
  cp -- "$git_workflow" "$git_before"
  cp -- "$npm_workflow" "$npm_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "conflicting Pi sources returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'conflicting Pi sources did not report package target failure' || exit 1
  cmp -s "$git_workflow" "$git_before" || fail 'conflicting Pi sources changed git workflow' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'conflicting Pi sources changed npm workflow' || exit 1
  [ ! -e "$backups" ] || fail 'conflicting Pi sources created backups before writes' || exit 1
)

test_pi_selected_missing_path_does_not_fallback() (
  local home="$TMP_ROOT/pi-selected-missing-home" backups="$TMP_ROOT/pi-selected-missing-backups"
  local git_root npm_workflow npm_init npm_before npm_init_before output rc
  git_root="$home/.pi/agent/git/github.com/Gentleman-Programming/gentle-pi"
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  npm_init="$home/$PI_NPM_INIT_REL"
  npm_before="$TMP_ROOT/pi-selected-missing-npm-before.md"
  npm_init_before="$TMP_ROOT/pi-selected-missing-npm-init-before.md"
  output="$TMP_ROOT/pi-selected-missing-output.txt"
  prepare_pi_package_home "$home"
  mkdir -p "$git_root/assets"
  write_pi_init_at "$home/$PI_GIT_INIT_REL"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$npm_init" "$npm_init_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "selected-missing Pi source returned $rc" || exit 1
  awk -v path="$PI_GIT_WORKFLOW_REL" '$1 == "MISSING-FILE" && $2 == "pi-rubric-workflow" && $3 == path { found = 1 } END { exit !found }' "$output" || fail 'selected missing git workflow was not reported' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'selected missing git source fell back to npm workflow' || exit 1
  cmp -s "$npm_init" "$npm_init_before" || fail 'selected missing git workflow fell back to npm sdd-init' || exit 1
  [ ! -e "$backups" ] || fail 'selected missing path created backups before writes' || exit 1
)

test_pi_selected_missing_sdd_init_does_not_fallback() (
  local home="$TMP_ROOT/pi-selected-missing-init-home" backups="$TMP_ROOT/pi-selected-missing-init-backups"
  local git_workflow npm_workflow npm_init append git_before npm_before npm_init_before append_before output apply_output rc
  git_workflow="$home/$PI_GIT_WORKFLOW_REL"
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  npm_init="$home/$PI_NPM_INIT_REL"
  append="$home/.pi/agent/APPEND_SYSTEM.md"
  git_before="$TMP_ROOT/pi-selected-missing-init-git-before.md"
  npm_before="$TMP_ROOT/pi-selected-missing-init-npm-before.md"
  npm_init_before="$TMP_ROOT/pi-selected-missing-init-npm-init-before.md"
  append_before="$TMP_ROOT/pi-selected-missing-init-append-before.md"
  output="$TMP_ROOT/pi-selected-missing-init-output.txt"
  apply_output="$TMP_ROOT/pi-selected-missing-init-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$git_workflow"
  write_pi_workflow_at "$npm_workflow"
  printf '%s\n' 'installer-owned Pi APPEND' > "$append"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'
  cp -- "$git_workflow" "$git_before"
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$npm_init" "$npm_init_before"
  cp -- "$append" "$append_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "selected missing Pi sdd-init check returned $rc" || exit 1
  awk -v path="$PI_GIT_INIT_REL" '$1 == "MISSING-FILE" && $2 == "sdd-init-pi" && $3 == path { found = 1 } END { exit !found }' "$output" || fail 'selected missing git sdd-init was not reported' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "selected missing Pi sdd-init apply returned $rc" || exit 1
  cmp -s "$git_workflow" "$git_before" || fail 'missing git sdd-init allowed a git workflow write' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'missing git sdd-init fell back to npm workflow' || exit 1
  cmp -s "$npm_init" "$npm_init_before" || fail 'missing git sdd-init fell back to npm sdd-init' || exit 1
  cmp -s "$append" "$append_before" || fail 'missing git sdd-init changed Pi APPEND' || exit 1
  [ ! -e "$backups" ] || fail 'missing git sdd-init created backups before writes' || exit 1
)

test_pi_selected_unsafe_sdd_init_blocks_preflight() (
  local home="$TMP_ROOT/pi-selected-unsafe-init-home" backups="$TMP_ROOT/pi-selected-unsafe-init-backups"
  local git_init outside git_workflow npm_workflow append outside_before git_before npm_before append_before output apply_output rc
  git_init="$home/$PI_GIT_INIT_REL"
  outside="$TMP_ROOT/pi-selected-unsafe-init-outside.md"
  git_workflow="$home/$PI_GIT_WORKFLOW_REL"
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  append="$home/.pi/agent/APPEND_SYSTEM.md"
  outside_before="$TMP_ROOT/pi-selected-unsafe-init-outside-before.md"
  git_before="$TMP_ROOT/pi-selected-unsafe-init-git-before.md"
  npm_before="$TMP_ROOT/pi-selected-unsafe-init-npm-before.md"
  append_before="$TMP_ROOT/pi-selected-unsafe-init-append-before.md"
  output="$TMP_ROOT/pi-selected-unsafe-init-output.txt"
  apply_output="$TMP_ROOT/pi-selected-unsafe-init-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$git_workflow"
  write_pi_workflow_at "$npm_workflow"
  mkdir -p "$(dirname -- "$git_init")"
  printf '%s\n' 'outside sdd-init target' > "$outside"
  ln -s "$outside" "$git_init"
  printf '%s\n' 'installer-owned Pi APPEND' > "$append"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'
  cp -- "$outside" "$outside_before"
  cp -- "$git_workflow" "$git_before"
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$append" "$append_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unsafe selected Pi sdd-init check returned $rc" || exit 1
  awk -v path="$PI_GIT_INIT_REL" '$1 == "UNSAFE-TARGET" && $2 == "sdd-init-pi" && $3 == path { found = 1 } END { exit !found }' "$output" || fail 'unsafe selected git sdd-init was not reported' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unsafe selected Pi sdd-init apply returned $rc" || exit 1
  cmp -s "$outside" "$outside_before" || fail 'unsafe sdd-init link target changed' || exit 1
  cmp -s "$git_workflow" "$git_before" || fail 'unsafe git sdd-init allowed a git workflow write' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'unsafe git sdd-init changed stale npm workflow' || exit 1
  cmp -s "$append" "$append_before" || fail 'unsafe git sdd-init changed Pi APPEND' || exit 1
  [ ! -e "$backups" ] || fail 'unsafe git sdd-init created backups before writes' || exit 1
)

test_pi_object_source_selects_npm_with_jq() (
  local home="$TMP_ROOT/pi-object-source-home" backups="$TMP_ROOT/pi-object-source-backups" actual
  command -v jq >/dev/null 2>&1 || fail 'jq is required for object-form package-source coverage' || exit 1
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":[{"source":"npm:gentle-pi@2.3.0-rc.1"}]}'

  load_overlay "$home" "$backups"
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'object-form npm source did not resolve' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'object-form npm source did not select npm layout' || exit 1
)

test_pi_unsupported_configured_source_fails() (
  local home="$TMP_ROOT/pi-unsupported-source-home" backups="$TMP_ROOT/pi-unsupported-source-backups"
  local npm_workflow npm_before output rc
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  npm_before="$TMP_ROOT/pi-unsupported-source-npm-before.md"
  output="$TMP_ROOT/pi-unsupported-source-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["file:/opt/gentle-pi"]}'
  cp -- "$npm_workflow" "$npm_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unsupported Pi source returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'unsupported Pi source did not report package target failure' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'unsupported Pi source changed npm workflow' || exit 1
  [ ! -e "$backups" ] || fail 'unsupported Pi source created backups before writes' || exit 1
)

test_pi_unrecognized_git_identity_fails_closed_before_fallback() (
  local home="$TMP_ROOT/pi-unrecognized-git-home" backups="$TMP_ROOT/pi-unrecognized-git-backups"
  local npm_workflow init_file npm_before init_before output apply_output rc
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  npm_before="$TMP_ROOT/pi-unrecognized-git-npm-before.md"
  init_before="$TMP_ROOT/pi-unrecognized-git-init-before.md"
  output="$TMP_ROOT/pi-unrecognized-git-output.txt"
  apply_output="$TMP_ROOT/pi-unrecognized-git-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["git:example.com/vendor/gentle-pi@deadbeef"]}'
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$init_file" "$init_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unrecognized gentle-pi git source returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'unrecognized gentle-pi git source did not report package target failure' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'unrecognized gentle-pi git source changed stale npm workflow during check' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'unrecognized gentle-pi git source changed Pi init during check' || exit 1
  [ ! -e "$backups" ] || fail 'unrecognized gentle-pi git source created backups during check' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unrecognized gentle-pi git source apply returned $rc" || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'unrecognized gentle-pi git source apply changed stale npm workflow' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'unrecognized gentle-pi git source apply changed Pi init' || exit 1
  [ ! -e "$backups" ] || fail 'unrecognized gentle-pi git source apply created backups' || exit 1
)

test_pi_local_path_identity_fails_closed_before_fallback() (
  local home="$TMP_ROOT/pi-local-path-home" backups="$TMP_ROOT/pi-local-path-backups"
  local npm_workflow init_file npm_before init_before output apply_output rc
  npm_workflow="$home/$PI_NPM_WORKFLOW_REL"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  npm_before="$TMP_ROOT/pi-local-path-npm-before.md"
  init_before="$TMP_ROOT/pi-local-path-init-before.md"
  output="$TMP_ROOT/pi-local-path-output.txt"
  apply_output="$TMP_ROOT/pi-local-path-apply-output.txt"
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$npm_workflow"
  write_pi_package_settings "$home" '{"packages":["path:/opt/gentle-pi"]}'
  cp -- "$npm_workflow" "$npm_before"
  cp -- "$init_file" "$init_before"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unsupported gentle-pi path source returned $rc" || exit 1
  grep -Fq 'PACKAGE-TARGET-CONFIG-FAILURE' "$output" || fail 'unsupported gentle-pi path source did not report package target failure' || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'unsupported gentle-pi path source changed stale npm workflow during check' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'unsupported gentle-pi path source changed Pi init during check' || exit 1
  [ ! -e "$backups" ] || fail 'unsupported gentle-pi path source created backups during check' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$apply_output" 2>&1
  rc=$?
  [ "$rc" -eq 1 ] || fail "unsupported gentle-pi path source apply returned $rc" || exit 1
  cmp -s "$npm_workflow" "$npm_before" || fail 'unsupported gentle-pi path source apply changed stale npm workflow' || exit 1
  cmp -s "$init_file" "$init_before" || fail 'unsupported gentle-pi path source apply changed Pi init' || exit 1
  [ ! -e "$backups" ] || fail 'unsupported gentle-pi path source apply created backups' || exit 1
)

test_pi_unrelated_helper_does_not_block_unique_npm_layout() (
  local home="$TMP_ROOT/pi-helper-home" backups="$TMP_ROOT/pi-helper-backups" actual
  prepare_pi_package_home "$home"
  write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi-helper@1.0.0"]}'

  load_overlay "$home" "$backups"
  actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail 'unrelated gentle-pi-helper source blocked a unique npm layout' || exit 1
  [ "$actual" = "$PI_NPM_WORKFLOW_REL" ] || fail 'unrelated gentle-pi-helper source selected the wrong layout' || exit 1
)

test_pi_canonical_github_forms_select_git() (
  local form home backups actual index=0
  for form in \
    'git:github.com/Gentleman-Programming/gentle-pi@4a71fd' \
    'git:https://github.com/Gentleman-Programming/gentle-pi.git#4a71fd' \
    'git:ssh://git@github.com/Gentleman-Programming/gentle-pi.git#4a71fd' \
    'git:git@github.com:Gentleman-Programming/gentle-pi.git#4a71fd'; do
    index=$((index + 1))
    home="$TMP_ROOT/pi-canonical-github-$index-home"
    backups="$TMP_ROOT/pi-canonical-github-$index-backups"
    prepare_pi_package_home "$home"
    write_pi_workflow_at "$home/$PI_GIT_WORKFLOW_REL"
    write_pi_workflow_at "$home/$PI_NPM_WORKFLOW_REL"
    write_pi_package_settings "$home" "{\"packages\":[\"$form\"]}"

    load_overlay "$home" "$backups"
    actual="$(resolve_target_rel pi "$PI_WORKFLOW_PLACEHOLDER")" || fail "canonical GitHub source did not resolve: $form" || exit 1
    [ "$actual" = "$PI_GIT_WORKFLOW_REL" ] || fail "canonical GitHub source did not select git layout: $form" || exit 1
  done
)

test_pi_workflow_rubric_forwarding_contract() (
  local home="$TMP_ROOT/pi-workflow-home" backups="$TMP_ROOT/pi-workflow-backups" stale_backups="$TMP_ROOT/pi-workflow-stale-backups"
  local append init_file workflow before_append before_workflow expected output after_first stale stale_before
  append="$home/.pi/agent/APPEND_SYSTEM.md"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  workflow="$home/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md"
  before_append="$TMP_ROOT/pi-workflow-append-before.md"
  before_workflow="$TMP_ROOT/pi-workflow-before.md"
  expected="$TMP_ROOT/pi-workflow-expected.md"
  output="$TMP_ROOT/pi-workflow-output.txt"
  after_first="$TMP_ROOT/pi-workflow-after-first.md"
  stale="$TMP_ROOT/pi-workflow-stale.md"
  stale_before="$TMP_ROOT/pi-workflow-stale-before.md"
  mkdir -p "$home/.gentle-ai" "$(dirname -- "$append")" "$(dirname -- "$init_file")" "$(dirname -- "$workflow")"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  printf '%s\n' '<!-- installer-owned Pi APPEND -->' 'do not modify' > "$append"
  write_pi_init_stock > "$init_file"
  write_pi_workflow_220_fixture > "$workflow"
  cp -- "$append" "$before_append"
  cp -- "$workflow" "$before_workflow"

  load_overlay "$home" "$backups"
  host_rows | grep -Fqx "pi|sdd-init-pi|$PI_SDD_INIT_PLACEHOLDER" || fail 'Pi packaged sdd-init asset row is not resolver-backed' || exit 1
  host_rows | grep -Fqx "pi|pi-rubric-workflow|$PI_WORKFLOW_PLACEHOLDER" || fail 'Pi package workflow placeholder row is missing' || exit 1
  if host_rows | grep -Fq '.pi/agent/APPEND_SYSTEM.md'; then
    fail 'Pi APPEND_SYSTEM.md is mapped' || exit 1
  fi
  pi_rubric_workflow_transform < "$workflow" > "$expected" || fail 'Pi 2.2.0 workflow fixture was refused' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output"
  [ "$?" -eq 2 ] || fail 'Pi workflow --check did not report pending work' || exit 1
  cmp -s "$workflow" "$before_workflow" || fail 'Pi workflow changed during --check' || exit 1
  cmp -s "$append" "$before_append" || fail 'Pi APPEND changed during workflow --check' || exit 1
  [ ! -e "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md" ] || fail 'Pi workflow --check created a backup' || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail 'Pi APPEND --check created a backup' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$output" || exit 1
  cmp -s "$workflow" "$expected" || fail 'Pi workflow apply did not install canonical forwarding block' || exit 1
  cmp -s "$before_workflow" "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md" || fail 'Pi workflow backup is not the original asset' || exit 1
  cmp -s "$append" "$before_append" || fail 'Pi APPEND changed during workflow apply' || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail 'Pi APPEND was backed up during workflow apply' || exit 1
  grep -Fq '<!-- gentle-ai:sdd-init-rubric -->' "$init_file" || fail 'Pi sdd-init was not still processed' || exit 1

  for golden in \
    'canonical `sdd-init` authoritative policy directly for the active artifact store' \
    'active/authoritative' \
    'caches the canonical policy ONCE per session' \
    'resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules' \
    '`default` ONLY when no non-default row matches' \
    'Policy-defined matching, precedence, and exceptions govern each slice.' \
    'If the canonical policy explicitly declares `all-rows` with `strictest-wins` and evidence union, use that declared resolution; otherwise use its declared resolution.' \
    "Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths" \
    'without substituting downstream matching rules or policy rewriting' \
    'Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy' \
    'Producer and activation semantics remain owned by `sdd-init`' \
    'Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification' \
    'Binary `strict_tdd` fallback is permitted ONLY when no rubric exists.' \
    'effective MODE is `strict-tdd`' \
    'The orchestrator is read-only: never author, generate, mutate, broaden, infer, alter, or rewrite the authoritative policy' \
    'It may mechanically match existing policy rows using only those declared rules and must never invent commands or evidence.'; do
    grep -Fq "$golden" "$workflow" || fail "Pi semantic golden is missing: $golden" || exit 1
  done
  for obsolete in RubricConsumerEnvelopeV1 RubricConsumerBlockedV1 'canonical-model digest' 'state gate' 'Resolve it ONCE per session' 'recovery_action=run '; do
    ! grep -Fq "$obsolete" "$workflow" || fail "Pi workflow retained obsolete $obsolete" || exit 1
  done
  grep -Fq 'Do not rely on the child agent to discover this independently.' "$workflow" || fail 'Pi binary fallback contract changed' || exit 1
  grep -Fqx '<!-- gentle-ai:pi-rubric-forwarding -->' "$workflow" || fail 'Pi workflow marker opening is missing' || exit 1
  grep -Fqx '<!-- /gentle-ai:pi-rubric-forwarding -->' "$workflow" || fail 'Pi workflow marker closing is missing' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check > "$output"
  [ "$?" -eq 0 ] || fail 'Pi workflow clean --check did not return 0' || exit 1
  cp -- "$workflow" "$after_first"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$output" || exit 1
  cmp -s "$workflow" "$after_first" || fail 'second Pi workflow apply was not byte-idempotent' || exit 1

  sed 's/resolve every distinct apply\/verify work slice AFRESH/resolve stale work slice/' "$workflow" > "$stale"
  cp -- "$stale" "$workflow"
  cp -- "$workflow" "$stale_before"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$stale_backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" > "$output" || exit 1
  cmp -s "$workflow" "$expected" || fail 'Pi stale marker body was not canonically refreshed' || exit 1
  cmp -s "$stale_before" "$stale_backups/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md" || fail 'Pi stale workflow backup is not the stale original' || exit 1
)

test_pi_workflow_refuses_malformed_or_stale_structure() (
  local home="$TMP_ROOT/pi-workflow-refusal-home" backups="$TMP_ROOT/pi-workflow-refusal-backups" file before gap name
  mkdir -p "$home/.pi/agent/npm/node_modules/gentle-pi/assets"
  load_overlay "$home" "$backups"
  CHECK_ONLY=0

  for name in partial duplicate reversed misplaced; do
    file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/$name.md"
    case "$name" in
      partial) gap="$PI_WORKFLOW_MARK_OPEN
stale partial body" ;;
      duplicate) gap="$RUBRIC_PI_WORKFLOW

$RUBRIC_PI_WORKFLOW" ;;
      reversed) gap="$PI_WORKFLOW_MARK_CLOSE
stale reversed body
$PI_WORKFLOW_MARK_OPEN" ;;
      misplaced) gap="unexpected intervening content
$RUBRIC_PI_WORKFLOW" ;;
    esac
    write_pi_workflow_220_with_gap "$gap" > "$file"
    before="$TMP_ROOT/pi-workflow-$name-before.md"
    cp -- "$file" "$before"
    expect_rc 3 rubric_apply_md "$file" pi-workflow || exit 1
    cmp -s "$file" "$before" || fail "Pi $name marker target changed after refusal" || exit 1
    [ ! -e "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/$name.md" ] || fail "Pi $name marker refusal created a backup" || exit 1
  done

  file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/anchor-inside.md"
  {
    printf '%s\n' "$PI_WORKFLOW_MARK_OPEN"
    write_pi_workflow_220_fixture
    printf '%s\n' "$PI_WORKFLOW_MARK_CLOSE"
  } > "$file"
  before="$TMP_ROOT/pi-workflow-anchor-inside-before.md"
  cp -- "$file" "$before"
  expect_rc 3 rubric_apply_md "$file" pi-workflow || exit 1
  cmp -s "$file" "$before" || fail 'Pi anchor-inside-marker target changed after refusal' || exit 1
  [ ! -e "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/anchor-inside.md" ] || fail 'Pi anchor-inside-marker refusal created a backup' || exit 1

  file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/missing-binary.md"
  printf '%s\n' '## Strict TDD Forwarding' '' '## Archive Final-State Handoff' > "$file"
  before="$TMP_ROOT/pi-workflow-missing-binary-before.md"
  cp -- "$file" "$before"
  expect_rc 3 rubric_apply_md "$file" pi-workflow || exit 1
  cmp -s "$file" "$before" || fail 'Pi missing binary anchor target changed after refusal' || exit 1

  file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/changed-binary.md"
  write_pi_workflow_220_fixture | sed 's/Do not rely on the child agent to discover this independently./Changed binary contract./' > "$file"
  before="$TMP_ROOT/pi-workflow-changed-binary-before.md"
  cp -- "$file" "$before"
  expect_rc 3 rubric_apply_md "$file" pi-workflow || exit 1
  cmp -s "$file" "$before" || fail 'Pi changed binary anchor target changed after refusal' || exit 1
)

test_pi_rc3_append_byte_preservation_and_obsolete_transform_removal() (
  local home="$TMP_ROOT/pi-rc3-home" backups="$TMP_ROOT/pi-rc3-backups" append init_file workflow before workflow_before rc
  append="$home/.pi/agent/APPEND_SYSTEM.md"
  init_file="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  workflow="$home/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md"
  before="$TMP_ROOT/pi-rc3-append-before.md"
  workflow_before="$TMP_ROOT/pi-rc3-workflow-before.md"
  mkdir -p "$home/.gentle-ai" "$(dirname -- "$append")" "$(dirname -- "$init_file")" "$(dirname -- "$workflow")"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  cat > "$append" <<'EOF'
<!-- gentle-ai:codegraph-guidance -->
## CodeGraph

When answering structural or codebase questions, use CodeGraph before broad filesystem searches. This is a hard ordering rule for repo maps, architecture, call flow, dependencies, symbol references, impact analysis, and “how does X work” questions.

Required order for structural/codebase questions:

1. Resolve the project root with `git rev-parse --show-toplevel || pwd`.
2. Confirm the root is a real project/workspace. Do not ask the user before initializing CodeGraph in a real project. Do not initialize CodeGraph in `$HOME`, temporary directories, or non-project folders.
3. Check for `<project-root>/.codegraph/` before any broad Read/Glob/Grep filesystem exploration.
4. If `.codegraph/` is missing and CodeGraph is enabled/available, immediately run `codegraph init <project-root>` once, then use the `codegraph_explore` MCP tool or `codegraph explore "..."`.
5. Missing .codegraph/ is the trigger to initialize, not a reason to skip CodeGraph. Do not fall back just because `.codegraph/` is missing; a missing index is the trigger to lazy-initialize, not a reason to skip CodeGraph.
6. Only fall back after CodeGraph init or CodeGraph use fails. Only fall back to normal filesystem tools after CodeGraph init or CodeGraph use fails, and briefly explain the fallback.

Broad Read/Glob/Grep exploration before this CodeGraph check is explicitly discouraged for structural/codebase questions.
<!-- /gentle-ai:codegraph-guidance -->

<!-- gentle-ai:agent-routing -->
## Implementation Routing

Route work for the requested outcome with the smallest useful topology. Every change takes exactly one implementation route: direct inline, delegated direct, or optional SDD.

- **Direct inline:** decide or verify from 1–3 files inline. Keep one mechanical, already-understood file change inline only when it needs no research and has no unresolved design decision.
- **Delegated direct:** delegate one narrow exploration when understanding needs 4+ files; delegate one writer for 2+ non-trivial files. Reading that prepares a write and broad research also delegate.
- **Optional SDD:** propose SDD only when durable proposal, spec, design, and tasks would materially reduce substantial ambiguity. SDD is selected only by an explicit request or an accepted proposal.
- File count, changed lines, size, or perceived risk alone never selects SDD and never forces a heavier route.
- These are implementation routes, not a ban on per-action delegation. Tests, builds, installs, and review actors may still use fresh workers without changing the selected route.
- Direct and delegated work never create SDD artifacts, prompts, phase attempts, or synthetic SDD runs.

### Receipt-driven development is user-owned

The user controls receipt-driven development with a switch: `gentle-ai review mode enable|disable|status`.

- It is **opt-in and off by default**. Until the user explicitly enables it, reviews do not run and delivery follows ordinary repository policy. Do not treat that as a fault to diagnose or work around.
- `status` is read-only. It reports the deciding source and the effective mode, and changes nothing. A `default` deciding source means nobody has chosen, so the effective mode is off.
- When the user asks to stop using receipt-driven development, run `disable`. Do not argue, do not work around it, and do not propose alternatives first.
- While it is disabled, keep implementing organically through direct inline, delegated direct, or optional SDD: do not start reviews, do not retry, do not reactivate it, and do not fall back to any retired path.
- Delivery under a disabled switch follows ordinary repository policy and reports `disabled/unmanaged`, never a fabricated approval.
- Never enable receipt-driven development on the user's behalf unless the user explicitly asks to.
<!-- /gentle-ai:agent-routing -->
EOF
  cp -- "$append" "$before"

  grep -Fqx '<!-- gentle-ai:codegraph-guidance -->' "$append" || fail 'rc.3 fixture lacks the CodeGraph opening marker' || exit 1
  grep -Fqx '<!-- /gentle-ai:codegraph-guidance -->' "$append" || fail 'rc.3 fixture lacks the CodeGraph closing marker' || exit 1
  grep -Fqx '<!-- gentle-ai:agent-routing -->' "$append" || fail 'rc.3 fixture lacks the routing opening marker' || exit 1
  grep -Fqx '<!-- /gentle-ai:agent-routing -->' "$append" || fail 'rc.3 fixture lacks the routing closing marker' || exit 1
  for obsolete_anchor in \
    '<!-- gentle-ai:persona -->' \
    '<!-- /gentle-ai:persona -->' \
    '#### Strict TDD Forwarding (MANDATORY)' \
    '3. If the search fails or `strict_tdd` is not found' \
    '4. **Additional condition — per-work-type rubric' \
    'The orchestrator resolves TDD status ONCE per session' \
    'Following cache prose must survive unchanged.' \
    '<!-- gentle-ai:sdd-model-assignments -->' \
    '<!-- /gentle-ai:sdd-model-assignments -->' \
    'The orchestrator resolves skills from the registry ONCE and passes model aliases.' \
    'Before the `sdd-propose` phase in interactive mode' \
    'Only for a selected SDD route, delegate to these phase agents:' \
    '| `sdd-propose` | exploration (optional) | `proposal` |'; do
    if grep -Fq -- "$obsolete_anchor" "$append"; then
      fail "rc.3 fixture retained obsolete anchor: $obsolete_anchor" || exit 1
    fi
  done
  write_pi_init_stock > "$init_file"
  write_pi_workflow_220_fixture > "$workflow"
  cp -- "$workflow" "$workflow_before"

  load_overlay "$home" "$backups"
  if host_rows | awk -F'|' '$1 == "pi" && $3 == ".pi/agent/APPEND_SYSTEM.md" { found = 1 } END { exit found ? 0 : 1 }'; then
    fail 'rc.3 still maps Pi APPEND_SYSTEM.md' || exit 1
  fi
  if declare -F pimodel_transform >/dev/null 2>&1; then
    fail 'rc.3 still loads the obsolete Pi model transform' || exit 1
  fi

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 2 ] || fail "expected --check pending rc 2, got $rc" || exit 1
  cmp -s "$append" "$before" || fail 'Pi APPEND_SYSTEM.md changed during --check' || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail 'Pi APPEND_SYSTEM.md was backed up during --check' || exit 1
  [ ! -e "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md" ] || fail '--check created an sdd-init backup' || exit 1
  [ ! -e "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md" ] || fail '--check created a Pi workflow backup' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" >/dev/null || exit 1
  cmp -s "$append" "$before" || fail 'Pi APPEND_SYSTEM.md changed during apply' || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail 'Pi APPEND_SYSTEM.md was backed up during apply' || exit 1
  grep -Fq '<!-- gentle-ai:sdd-init-rubric -->' "$init_file" || fail 'Pi sdd-init mapping was not applied' || exit 1
  grep -Fq '<!-- gentle-ai:pi-rubric-forwarding -->' "$workflow" || fail 'Pi workflow mapping was not applied' || exit 1
  cmp -s "$workflow_before" "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md" || fail 'Pi workflow backup is not the original' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 0 ] || fail "expected clean --check rc 0, got $rc" || exit 1
  cmp -s "$append" "$before" || fail 'Pi APPEND_SYSTEM.md changed after a clean check' || exit 1
)

test_symlink_refusal() (
  local home="$TMP_ROOT/symlink-home" backups="$TMP_ROOT/symlink-backups" target link
  target="$TMP_ROOT/symlink-target.md"
  link="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  mkdir -p "$(dirname -- "$link")"
  printf '%s\n' 'outside target' > "$target"
  ln -s "$target" "$link"
  load_overlay "$home" "$backups"
  expect_rc 4 init_rubric_apply "$link" pi || exit 1
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

test_sdd_init_host_rows_cover_cursor_copilot_and_pi() (
  local home="$TMP_ROOT/skills-hosts-home" backups="$TMP_ROOT/skills-hosts-backups"
  mkdir -p "$home"
  load_overlay "$home" "$backups"
  host_rows | grep -Fqx 'cursor|sdd-init-skill|.cursor/skills/sdd-init/SKILL.md' || fail 'Cursor sdd-init skill row is missing' || exit 1
  host_rows | grep -Fqx 'cursor|sdd-init-details|.cursor/skills/sdd-init/references/init-details.md' || fail 'Cursor sdd-init details row is missing' || exit 1
  host_rows | grep -Fqx 'vscode-copilot|sdd-init-skill|.copilot/skills/sdd-init/SKILL.md' || fail 'Copilot sdd-init skill row is missing' || exit 1
  host_rows | grep -Fqx 'vscode-copilot|sdd-init-details|.copilot/skills/sdd-init/references/init-details.md' || fail 'Copilot sdd-init details row is missing' || exit 1
  host_rows | grep -Fqx 'claude-code|persona-split-style|@claude-output-style@' || fail 'Claude selected style row is missing' || exit 1
  host_rows | grep -Fqx "pi|sdd-init-pi|$PI_SDD_INIT_PLACEHOLDER" || fail 'Pi packaged sdd-init row is not resolver-backed' || exit 1
  host_rows | grep -Fqx "pi|pi-rubric-workflow|$PI_WORKFLOW_PLACEHOLDER" || fail 'Pi workflow row is missing' || exit 1
  host_rows | grep -Fqx 'opencode|sdd-init-delegation|.config/opencode/opencode.json' || fail 'OpenCode inline sdd-init delegation row is missing' || exit 1
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

test_claude_style_resolution_refuses_ambiguity() (
  local home="$TMP_ROOT/claude-style-resolution-home" backups="$TMP_ROOT/claude-style-resolution-backups"
  mkdir -p "$home/.gentle-ai" "$home/.claude/output-styles"
  printf '%s\n' '{"persona":"neutral"}' > "$home/.gentle-ai/state.json"
  jq -n '{outputStyle: "Gentleman"}' > "$home/.claude/settings.json"
  printf '%s\n' neutral > "$home/.claude/output-styles/neutral.md"
  printf '%s\n' gentleman > "$home/.claude/output-styles/gentleman.md"
  load_overlay "$home" "$backups"
  if resolve_claude_output_style_rel >/dev/null 2>&1; then
    fail 'conflicting Claude persona selectors passed resolution' || exit 1
  fi
  rm -f -- "$home/.claude/settings.json"
  printf '%s\n' '{"persona":"gentleman-neutral-artifacts"}' > "$home/.gentle-ai/state.json"
  [ "$(resolve_claude_output_style_rel)" = '.claude/output-styles/gentleman.md' ] || fail 'gentleman-neutral-artifacts did not select gentleman.md' || exit 1
  printf '%s\n' '{"persona":"full-gentleman"}' > "$home/.gentle-ai/state.json"
  if resolve_claude_output_style_rel >/dev/null 2>&1; then
    fail 'full-gentleman preset passed Claude persona resolution' || exit 1
  fi
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

test_opencode_sdd_init_inline_delegation_validation() (
  local home="$TMP_ROOT/opencode-init-inline-home" backups="$TMP_ROOT/opencode-init-inline-backups" config
  config="$home/.config/opencode/opencode.json"
  mkdir -p "$(dirname -- "$config")"
  write_opencode_init_config "$config"

  load_overlay "$home" "$backups"
  [ "$(opencode_sdd_init_mode "$config")" = inline ] || fail 'OpenCode rc.3 inline sdd-init prompt was not recognized' || exit 1
  opencode_sdd_init_delegates "$config" || fail 'OpenCode rc.3 inline sdd-init prompt did not delegate to the managed skill' || exit 1
  write_opencode_sdd_init_prompt "$config" '{file:./prompts/sdd/sdd-init.md}'
  [ "$(opencode_sdd_init_mode "$config")" = external ] || fail 'OpenCode exact external prompt was not recognized' || exit 1
  [ "$(opencode_sdd_init_external_target "$config")" = "$home/.config/opencode/prompts/sdd/sdd-init.md" ] || fail 'OpenCode external prompt did not map to its fixed target' || exit 1
  write_opencode_sdd_init_prompt "$config" '{file:./prompts/sdd/other.md}'
  opencode_sdd_init_mode "$config" >/dev/null 2>&1 && fail 'OpenCode arbitrary external prompt passed validation' && exit 1
  :
)

test_opencode_sdd_init_final_contract_validation() (
  local home="$TMP_ROOT/opencode-init-final-home" backups="$TMP_ROOT/opencode-init-final-backups" config prompt label
  config="$home/.config/opencode/opencode.json"
  mkdir -p "$(dirname -- "$config")"
  write_opencode_final_init_config "$config"

  load_overlay "$home" "$backups"
  [ "$(opencode_sdd_init_mode "$config")" = inline ] || fail 'OpenCode final 2.5.0 appended prompt was not recognized' || exit 1
  opencode_sdd_init_delegates "$config" || fail 'OpenCode final 2.5.0 prompt did not delegate to the managed skill' || exit 1
  write_opencode_sdd_init_prompt "$config" "$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"
  [ "$(opencode_sdd_init_mode "$config")" = inline ] || fail 'OpenCode final 2.5.0 zero-block prompt was not recognized' || exit 1
  opencode_sdd_init_delegates "$config" || fail 'OpenCode final 2.5.0 zero-block prompt did not delegate to the managed skill' || exit 1
  prompt="$(opencode_sdd_init_final_prompt)"$'\n'
  [ "$(write_opencode_sdd_init_prompt "$config" "$prompt"; opencode_sdd_init_mode "$config")" = inline ] || fail 'OpenCode final prompt with its single canonical terminal newline was refused' || exit 1

  write_opencode_sdd_init_prompt "$config" "$(opencode_sdd_init_260_prompt)"
  [ "$(opencode_sdd_init_mode "$config")" = inline ] || fail 'OpenCode final 2.6.0 language-only prompt was not recognized' || exit 1
  opencode_sdd_init_delegates "$config" || fail 'OpenCode final 2.6.0 language-only prompt did not delegate to the managed skill' || exit 1
  prompt="$(opencode_sdd_init_260_prompt)"$'\n'
  [ "$(write_opencode_sdd_init_prompt "$config" "$prompt"; opencode_sdd_init_mode "$config")" = inline ] || fail 'OpenCode final 2.6.0 prompt with its single canonical terminal newline was refused' || exit 1

  for label in 260-arbitrary-suffix 260-partial-marker 260-duplicate-marker 260-reordered-suffix 260-unknown-suffix 260-double-terminal-newline; do
    case "$label" in
      260-arbitrary-suffix) prompt="$(opencode_sdd_init_260_prompt)"$'\nUnexpected suffix.' ;;
      260-partial-marker) prompt="$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"$'\n\n<!-- gentle-ai:agent-language-contract -->\npartial contract block' ;;
      260-duplicate-marker) prompt="$(opencode_sdd_init_260_prompt)"$'\n\n'"$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK" ;;
      260-reordered-suffix) prompt="$(opencode_sdd_init_260_prompt)"$'\n\n'"$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK" ;;
      260-unknown-suffix) prompt="$(opencode_sdd_init_260_prompt)"$'\n\n<!-- gentle-ai:unknown -->\nunknown managed block\n<!-- /gentle-ai:unknown -->' ;;
      260-double-terminal-newline) prompt="$(opencode_sdd_init_260_prompt)"$'\n\n' ;;
    esac
    write_opencode_sdd_init_prompt "$config" "$prompt"
    opencode_sdd_init_mode "$config" >/dev/null 2>&1 && fail "OpenCode $label prompt passed final-contract validation" && exit 1
  done

  for label in arbitrary-prefix embedded-sentence arbitrary-suffix partial-marker duplicate-marker out-of-order-marker unknown-marker invented-artifact-language-marker visible wrong-skill-path redirected refusal; do
    case "$label" in
      arbitrary-prefix) prompt=$'Unrelated prefix.\n'"$(opencode_sdd_init_final_prompt)" ;;
      embedded-sentence) prompt="Unrelated text. $OPENCODE_SDD_INIT_RC3_PROMPT Still unrelated text." ;;
      arbitrary-suffix) prompt="$(opencode_sdd_init_final_prompt)"$'\nUnexpected suffix.' ;;
      partial-marker) prompt="$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"$'\n\n<!-- gentle-ai:codegraph-guidance -->\npartial CodeGraph block' ;;
      duplicate-marker) prompt="$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"$'\n\n'"$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK"$'\n\n'"$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK"$'\n\n'"$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK" ;;
      out-of-order-marker) prompt="$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"$'\n\n'"$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK"$'\n\n'"$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK" ;;
      unknown-marker) prompt="$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"$'\n\n'"$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK"$'\n\n<!-- gentle-ai:unknown -->\nunknown managed block\n<!-- /gentle-ai:unknown -->\n\n'"$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK" ;;
      invented-artifact-language-marker) prompt="$OPENCODE_SDD_INIT_FINAL_PARAGRAPH"$'\n\n'"$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK"$'\n\n<!-- gentle-ai:agent-language-contract -->\n## Agent Language Contract\n\n<!-- gentle-ai:artifact-language -->\ninvented managed block\n<!-- /gentle-ai:artifact-language -->\n\nInstaller-managed Agent Language Contract guidance.\n<!-- /gentle-ai:agent-language-contract -->' ;;
      visible) prompt="$(opencode_sdd_init_final_prompt)" ;;
      wrong-skill-path) prompt="${OPENCODE_SDD_INIT_FINAL_PARAGRAPH/SKILL.md/OTHER.md}"$'\n\n'"$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK"$'\n\n'"$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK" ;;
      redirected) prompt='Delegate to another skill.' ;;
      refusal) prompt='Do not read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md.' ;;
    esac
    if [ "$label" = visible ]; then
      write_opencode_sdd_init_prompt "$config" "$prompt" false
    else
      write_opencode_sdd_init_prompt "$config" "$prompt"
    fi
    if opencode_sdd_init_mode "$config" >/dev/null 2>&1; then
      case "$label" in
        invented-artifact-language-marker) fail 'OpenCode invented artifact-language marker was not rejected as unknown' ;;
        *) fail "OpenCode $label prompt passed final-contract validation" ;;
      esac
      exit 1
    fi
  done
  :
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

write_claude_split_stock() {
  cat <<'EOF'
<!-- gentle-ai:persona -->
## Rules

Installer-owned rules.

## Expertise

Installer-owned expertise.

## Contextual Skill Loading (MANDATORY)

Installer-owned skills.

## Persona Voice

Installer-owned voice.
<!-- /gentle-ai:persona -->
EOF
}

write_pi_append_stock() {
  cat <<'EOF'
<!-- gentle-ai:persona -->
## Rules

Installer-owned rules.

## Personality

Installer-owned personality.

## Persona Scope

Installer-owned scope.

## Language

Installer-owned language.

## Tone

Installer-owned tone.

## Philosophy

Installer-owned philosophy.

## Expertise

Installer-owned expertise.

## Behavior

Installer-owned behavior.

## Contextual Skill Loading

Installer-owned skills.
<!-- /gentle-ai:persona -->
3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction

The orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.
<!-- gentle-ai:sdd-model-assignments -->
legacy model assignments
<!-- /gentle-ai:sdd-model-assignments -->
The orchestrator resolves skills from the registry ONCE and passes model aliases.
Before the `sdd-propose` phase in interactive mode, offer the user a proposal question round.
Only for a selected SDD route, delegate to these phase agents: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard.
| `sdd-propose` | exploration (optional) | `proposal` |
EOF
}

OPENCODE_SDD_INIT_RC3_PROMPT='Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly.'
OPENCODE_SDD_INIT_FINAL_PARAGRAPH="You are an SDD executor for the init phase, not the orchestrator. Do this phase's work yourself. Do NOT delegate, Do NOT call task, and Do NOT launch sub-agents. Read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md and follow it exactly."
OPENCODE_SDD_INIT_CODEGRAPH_BLOCK=$'<!-- gentle-ai:codegraph-guidance -->\n## CodeGraph\n\nInstaller-managed CodeGraph guidance.\n<!-- /gentle-ai:codegraph-guidance -->'
OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK=$'<!-- gentle-ai:agent-language-contract -->\n## Agent Language Contract\n\nInstaller-managed Agent Language Contract guidance.\n<!-- /gentle-ai:agent-language-contract -->'

opencode_sdd_init_final_prompt() {
  printf '%s\n\n%s\n\n%s' \
    "$OPENCODE_SDD_INIT_FINAL_PARAGRAPH" \
    "$OPENCODE_SDD_INIT_CODEGRAPH_BLOCK" \
    "$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK"
}

opencode_sdd_init_260_prompt() {
  printf '%s\n\n%s' \
    "$OPENCODE_SDD_INIT_FINAL_PARAGRAPH" \
    "$OPENCODE_SDD_INIT_AGENT_LANGUAGE_CONTRACT_BLOCK"
}

write_opencode_sdd_init_prompt() {
  local file="$1" prompt="$2" hidden="${3:-true}"
  jq -n --arg prompt "$prompt" --argjson hidden "$hidden" '{agent: {"sdd-init": {hidden: $hidden, prompt: $prompt}}}' > "$file"
}

write_opencode_init_config() {
  local file="$1" orchestrator
  orchestrator=$'3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction\n\nThe orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.'
  jq -n --arg orchestrator "$orchestrator" --arg prompt "$OPENCODE_SDD_INIT_RC3_PROMPT" '
    {agent: {
      "gentle-orchestrator": {prompt: $orchestrator},
      "sdd-init": {hidden: true, prompt: $prompt}
    }}
  ' > "$file"
}

write_opencode_final_init_config() {
  local file="$1" orchestrator prompt
  orchestrator=$'3. If the search fails or `strict_tdd` is not found, do NOT add the TDD instruction\n\nThe orchestrator resolves TDD status ONCE per session (at first apply/verify launch) and caches it.'
  prompt="${2:-$(opencode_sdd_init_final_prompt)}"
  jq -n --arg orchestrator "$orchestrator" --arg prompt "$prompt" '
    {agent: {
      "gentle-orchestrator": {prompt: $orchestrator},
      "sdd-init": {hidden: true, prompt: $prompt}
    }}
  ' > "$file"
}

write_opencode_external_init_config() {
  local file="$1" next
  write_opencode_init_config "$file"
  next="${file}.next"
  jq '.agent["sdd-init"].prompt = "{file:./prompts/sdd/sdd-init.md}"' "$file" > "$next"
  mv -- "$next" "$file"
}

test_neutral_external_profile_lifecycle() (
  local home="$TMP_ROOT/neutral-external-home" backups="$TMP_ROOT/neutral-external-backups" rc
  local state="$home/.gentle-ai/state.json" settings="$home/.claude/settings.json"
  local claude="$home/.claude/CLAUDE.md" neutral="$home/.claude/output-styles/neutral.md"
  local workflow="$home/.claude/skills/_shared/sdd-orchestrator-workflow.md"
  local config="$home/.config/opencode/opencode.json" prompt="$home/.config/opencode/prompts/sdd/sdd-init.md"
  local opencode_skill="$home/.config/opencode/skills/sdd-init/SKILL.md"
  local state_before settings_before agent_before neutral_before prompt_before

  mkdir -p "$(dirname -- "$state")" "$(dirname -- "$claude")" "$(dirname -- "$neutral")" \
    "$(dirname -- "$workflow")" "$(dirname -- "$home/.claude/skills/sdd-init/references/init-details.md")" \
    "$(dirname -- "$config")" "$(dirname -- "$home/.config/opencode/AGENTS.md")" \
    "$(dirname -- "$home/.config/opencode/plugins/engram.ts")" "$(dirname -- "$opencode_skill")" \
    "$(dirname -- "$home/.config/opencode/skills/sdd-init/references/init-details.md")" "$(dirname -- "$prompt")"
  printf '%s\n' '{"installed_agents":["claude-code","opencode"],"persona":"neutral"}' > "$state"
  jq -n '{outputStyle: "Neutral", profile: "selected-profile"}' > "$settings"
  write_claude_split_stock > "$claude"
  printf '%s\n' 'Installer-owned neutral style.' > "$neutral"
  printf '%s\n' 'When launching `sdd-apply` or `sdd-verify`, search for testing capabilities' > "$workflow"
  write_init_skill_stock > "$home/.claude/skills/sdd-init/SKILL.md"
  write_init_details_stock > "$home/.claude/skills/sdd-init/references/init-details.md"
  {
    printf '%s\n' '<!-- gentle-ai:persona -->'
    cat "$ROOT/persona/persona-block.md"
    printf '%s\n' '<!-- /gentle-ai:persona -->'
  } > "$home/.config/opencode/AGENTS.md"
  write_opencode_external_init_config "$config"
  write_opencode_stock > "$home/.config/opencode/plugins/engram.ts"
  write_init_skill_stock > "$opencode_skill"
  write_init_details_stock > "$home/.config/opencode/skills/sdd-init/references/init-details.md"
  write_init_skill_stock > "$prompt"

  state_before="$TMP_ROOT/neutral-external-state-before.json"
  settings_before="$TMP_ROOT/neutral-external-settings-before.json"
  neutral_before="$TMP_ROOT/neutral-external-style-before.md"
  prompt_before="$TMP_ROOT/neutral-external-prompt-before.md"
  cp -- "$state" "$state_before"
  cp -- "$settings" "$settings_before"
  cp -- "$neutral" "$neutral_before"
  cp -- "$prompt" "$prompt_before"
  agent_before="$(jq -c '.agent["sdd-init"]' "$config")"

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 2 ] || fail "neutral external --check should be pending, got rc $rc" || exit 1
  cmp -s "$state" "$state_before" || fail 'neutral external --check changed persisted persona' || exit 1
  cmp -s "$settings" "$settings_before" || fail 'neutral external --check changed Claude outputStyle' || exit 1
  cmp -s "$neutral" "$neutral_before" || fail 'neutral external --check changed selected style' || exit 1
  cmp -s "$prompt" "$prompt_before" || fail 'neutral external --check changed executable prompt' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" >/dev/null || exit 1
  grep -Fq '# Neutral Output Style' "$neutral" || fail 'neutral external layout did not transform neutral.md' || exit 1
  grep -Fq 'single writer of project TDD policy' "$prompt" || fail 'neutral external layout did not transform executable prompt' || exit 1
  cmp -s "$state" "$state_before" || fail 'neutral external layout changed persisted persona selection' || exit 1
  cmp -s "$settings" "$settings_before" || fail 'neutral external layout changed Claude profile selection' || exit 1
  [ "$(jq -c '.agent["sdd-init"]' "$config")" = "$agent_before" ] || fail 'neutral external layout changed OpenCode sdd-init selection' || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 0 ] || fail "neutral external layout should be clean after apply, got rc $rc" || exit 1
)

# This fixture mirrors the active Claude, Pi, and OpenCode assets emitted by a
# fresh Gentle AI 2.6.0 install with gentle-pi@2.4.0. It must not create legacy paths.
test_fresh_260_active_layout_lifecycle() (
  local home="$TMP_ROOT/fresh-260-home" backups="$TMP_ROOT/fresh-260-backups" output rc config_before
  local claude="$home/.claude/CLAUDE.md" gentleman="$home/.claude/output-styles/gentleman.md"
  local pi="$home/.pi/agent/APPEND_SYSTEM.md" pi_init="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
  local pi_workflow="$home/.pi/agent/npm/node_modules/gentle-pi/assets/sdd-orchestrator-workflow.md"
  local config="$home/.config/opencode/opencode.json" opencode_skill="$home/.config/opencode/skills/sdd-init/SKILL.md"
  local pi_before

  mkdir -p "$home/.gentle-ai" "$(dirname -- "$claude")" "$(dirname -- "$gentleman")" \
    "$(dirname -- "$home/.claude/skills/_shared/sdd-orchestrator-workflow.md")" \
    "$(dirname -- "$home/.claude/skills/sdd-init/references/init-details.md")" \
    "$(dirname -- "$pi")" "$(dirname -- "$pi_init")" "$(dirname -- "$pi_workflow")" \
    "$(dirname -- "$config")" "$(dirname -- "$home/.config/opencode/AGENTS.md")" \
    "$(dirname -- "$home/.config/opencode/plugins/engram.ts")" \
    "$(dirname -- "$opencode_skill")" \
    "$(dirname -- "$home/.config/opencode/skills/sdd-init/references/init-details.md")"
  printf '%s\n' '{"installed_agents":["claude-code","pi","opencode"]}' > "$home/.gentle-ai/state.json"
  write_claude_split_stock > "$claude"
  printf '%s\n' 'Installer-owned gentleman style.' > "$gentleman"
  printf '%s\n' 'When launching `sdd-apply` or `sdd-verify`, search for testing capabilities' > "$home/.claude/skills/_shared/sdd-orchestrator-workflow.md"
  write_init_skill_stock > "$home/.claude/skills/sdd-init/SKILL.md"
  write_init_details_stock > "$home/.claude/skills/sdd-init/references/init-details.md"
  write_pi_append_stock > "$pi"
  pi_before="$TMP_ROOT/fresh-260-pi-append-before.md"
  cp -- "$pi" "$pi_before"
  write_pi_init_stock > "$pi_init"
  write_pi_workflow_220_fixture > "$pi_workflow"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.4.0"]}'
  {
    printf '%s\n' '<!-- gentle-ai:persona -->'
    cat "$ROOT/persona/persona-block.md"
    printf '%s\n' '<!-- /gentle-ai:persona -->'
  } > "$home/.config/opencode/AGENTS.md"
  write_opencode_final_init_config "$config" "$(opencode_sdd_init_260_prompt)"
  write_opencode_stock > "$home/.config/opencode/plugins/engram.ts"
  write_init_skill_stock > "$opencode_skill"
  write_init_details_stock > "$home/.config/opencode/skills/sdd-init/references/init-details.md"

  output="$TMP_ROOT/fresh-260-check-before.txt"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check > "$output"
  rc=$?
  [ "$rc" -eq 2 ] || { cat "$output" >&2; fail "fresh 2.6.0 layout should be pending, got rc $rc"; exit 1; }
  [ ! -e "$backups/.claude/output-styles/gentleman.md" ] || fail 'fresh 2.6.0 --check created a Claude backup' || exit 1
  cmp -s "$pi" "$pi_before" || fail 'fresh 2.6.0 --check changed Pi APPEND' || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail 'fresh 2.6.0 --check backed up Pi APPEND' || exit 1

  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" >/dev/null || exit 1
  cmp -s "$pi" "$pi_before" || fail 'fresh 2.6.0 apply changed Pi APPEND' || exit 1
  [ ! -e "$backups/.pi/agent/APPEND_SYSTEM.md" ] || fail 'fresh 2.6.0 apply backed up Pi APPEND' || exit 1
  grep -Fq '# Neutral Output Style' "$gentleman" || fail 'fresh 2.6.0 Claude style was not transformed' || exit 1
  grep -Fq 'allowed_answers: strict|rubric' "$pi_init" || fail 'fresh 2.6.0 Pi executable asset was not transformed' || exit 1
  grep -Fq '<!-- gentle-ai:pi-rubric-forwarding -->' "$pi_workflow" || fail 'fresh 2.6.0 Pi package workflow was not transformed' || exit 1
  grep -Fq 'single writer of project TDD policy' "$opencode_skill" || fail 'fresh 2.6.0 OpenCode skill was not transformed' || exit 1
  [ ! -e "$home/.config/opencode/prompts/sdd/sdd-init.md" ] || fail 'fresh 2.6.0 layout manufactured an OpenCode prompt file' || exit 1
  load_overlay "$home" "$backups"
  [ "$(opencode_sdd_init_mode "$config")" = inline ] || fail 'fresh 2.6.0 language-only OpenCode sdd-init prompt does not use the final inline contract' || exit 1
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 0 ] || fail "fresh 2.6.0 layout should be clean after apply, got rc $rc" || exit 1

  config_before="$TMP_ROOT/fresh-260-opencode-config-before.json"
  cp -- "$config" "$config_before"
  jq '.agent["sdd-init"].prompt = "Do not read your skill file at ~/.config/opencode/skills/sdd-init/SKILL.md."' "$config" > "$config_before.next"
  mv -- "$config_before.next" "$config"
  printf '%s\n' 'pending Claude style must survive failed preflight' > "$gentleman"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || fail "refused OpenCode sdd-init prompt should block apply, got rc $rc" || exit 1
  grep -Fqx 'pending Claude style must survive failed preflight' "$gentleman" || fail 'refused OpenCode prompt allowed a preflight write' || exit 1

  jq '.agent["sdd-init"].prompt = "{file:./prompts/sdd/sdd-init.md}"' "$config_before" > "$config_before.next"
  mv -- "$config_before.next" "$config"
  printf '%s\n' 'pending Claude style must survive missing external prompt' > "$gentleman"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || fail "missing external prompt should block apply, got rc $rc" || exit 1
  grep -Fqx 'pending Claude style must survive missing external prompt' "$gentleman" || fail 'missing external prompt allowed a preflight write' || exit 1

  jq '.agent["sdd-init"].prompt = "{file:./prompts/sdd/other.md}"' "$config_before" > "$config_before.next"
  mv -- "$config_before.next" "$config"
  printf '%s\n' 'pending Claude style must survive arbitrary external prompt' > "$gentleman"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || fail "arbitrary external prompt should block apply, got rc $rc" || exit 1
  grep -Fqx 'pending Claude style must survive arbitrary external prompt' "$gentleman" || fail 'arbitrary external prompt allowed a preflight write' || exit 1

  mkdir -p "$home/.config/opencode/prompts/sdd"
  printf '%s\n' 'outside prompt target' > "$TMP_ROOT/external-prompt-target.md"
  ln -s "$TMP_ROOT/external-prompt-target.md" "$home/.config/opencode/prompts/sdd/sdd-init.md"
  jq '.agent["sdd-init"].prompt = "{file:./prompts/sdd/sdd-init.md}"' "$config_before" > "$config_before.next"
  mv -- "$config_before.next" "$config"
  printf '%s\n' 'pending Claude style must survive unsafe external prompt' > "$gentleman"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || fail "unsafe external prompt should block apply, got rc $rc" || exit 1
  grep -Fqx 'pending Claude style must survive unsafe external prompt' "$gentleman" || fail 'unsafe external prompt allowed a preflight write' || exit 1

  cp -- "$config_before" "$config"
  rm -f -- "$home/.config/opencode/prompts/sdd/sdd-init.md"
  rm -f -- "$pi_init"
  HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=0 "$ROOT/apply.sh" --check >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || fail "missing Pi executable asset should block preflight, got rc $rc" || exit 1
)

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
  pi="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
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

test_managed_asset_diagnostic() (
  local home="$TMP_ROOT/diagnostic-home" backups="$TMP_ROOT/diagnostic-backups" root source target manifest output before_source before_target before_manifest hash hash_file expected stale normal check lib_output diagnostic_line transform_line
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  manifest="$home/.pi/agent/gentle-ai/managed-assets.json"
  output="$TMP_ROOT/diagnostic.out"
  normal="$TMP_ROOT/diagnostic-normal.out"
  check="$TMP_ROOT/diagnostic-check.out"
  lib_output="$TMP_ROOT/diagnostic-lib.out"
  before_source="$TMP_ROOT/diagnostic-before-source"
  before_target="$TMP_ROOT/diagnostic-before-target"
  before_manifest="$TMP_ROOT/diagnostic-before-manifest"
  write_diag_package "$home"
  mkdir -p "$(dirname -- "$target")" "$home/.pi/agent/agents" "$home/.gentle-ai"
  cp -- "$source" "$target"
  printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
  printf '\n' > "$home/.pi/agent/APPEND_SYSTEM.md"

  load_overlay "$home" "$backups"
  hash="$(asset_sha256 "$source")"
  write_diag_manifest "$home" "$hash"
  cp -- "$source" "$before_source"
  cp -- "$target" "$before_target"
  cp -- "$manifest" "$before_manifest"
  managed_asset_diagnostic > "$output"
  grep -Fq 'CURRENT-MANAGED chains/sdd-full.chain.md' "$output" || fail 'current managed asset was not reported' || exit 1
  cmp -s "$source" "$before_source" || fail 'diagnostic changed package input' || exit 1
  cmp -s "$target" "$before_target" || fail 'diagnostic changed installed input' || exit 1
  cmp -s "$manifest" "$before_manifest" || fail 'diagnostic changed manifest input' || exit 1

  # The published hash has no offline fixture preimage; exercise the pure classifier, then hash real bytes below.
  stale="$(asset_state chains/sdd-full.chain.md "$hash" 398f105e58b36fb169617257f4fc55b8bebdd5d26ddcb8b01556aed8dec0c0b "$hash" '')"
  printf '%s\n' "$stale" | grep -Fq 'KNOWN-OBSOLETE' || fail 'published exact stale hash was not classified' || exit 1
  hash_file="$TMP_ROOT/diagnostic-hash-input"
  printf '%s\n' 'hashable' > "$hash_file"
  expected="$(sha256sum "$hash_file" 2>/dev/null || shasum -a 256 "$hash_file")"
  expected="${expected%% *}"
  [ "$(asset_sha256 "$hash_file")" = "$expected" ] || fail 'diagnostic hash helper did not hash fixture bytes' || exit 1

  env -u APPLY_SH_LIB HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" > "$normal" || exit 1
  [ "$(grep -Fc 'managed-asset diagnostic' "$normal")" -eq 1 ] || fail 'normal apply emitted duplicate diagnostic output' || exit 1
  diagnostic_line="$(grep -n 'managed-asset diagnostic' "$normal" | cut -d: -f1)"
  transform_line="$(grep -n 'sdd-init-rubric.*agents/sdd-init.md' "$normal" | cut -d: -f1)"
  [ "$diagnostic_line" -lt "$transform_line" ] || fail 'diagnostic did not precede overlay transform' || exit 1
  cmp -s "$source" "$before_source" || fail 'normal apply changed package diagnostic input' || exit 1
  cmp -s "$target" "$before_target" || fail 'normal apply changed installed diagnostic input' || exit 1
  cmp -s "$manifest" "$before_manifest" || fail 'normal apply changed manifest diagnostic input' || exit 1

  env -u APPLY_SH_LIB HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check > "$check"
  [ "$?" -eq 0 ] || fail 'expected clean diagnostic --check exit 0' || exit 1
  [ "$(grep -Fc 'managed-asset diagnostic' "$check")" -eq 1 ] || fail '--check emitted duplicate diagnostic output' || exit 1
  cmp -s "$source" "$before_source" || fail '--check changed package diagnostic input' || exit 1
  cmp -s "$target" "$before_target" || fail '--check changed installed diagnostic input' || exit 1
  cmp -s "$manifest" "$before_manifest" || fail '--check changed manifest diagnostic input' || exit 1
  env -u GENTLE_PI_AGENT_HOME -u PI_CODING_AGENT_DIR HOME="$home" APPLY_SH_LIB=1 bash -c 'source "$1"' _ "$ROOT/apply.sh" > "$lib_output"
  [ ! -s "$lib_output" ] || fail 'library sourcing emitted diagnostic output' || exit 1

  home="$TMP_ROOT/diagnostic-unowned-home"
  write_diag_package "$home"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  mkdir -p "$(dirname -- "$target")" "$home/.pi/agent/agents"
  cp -- "$source" "$target"
  printf '%s\n' '---' 'model: source-model' '---' 'agent body' > "$root/assets/agents/sdd-apply.md"
  printf '%s\n' '---' 'model: routed-model' '---' 'agent body' > "$home/.pi/agent/agents/sdd-apply.md"
  mkdir -p "$home/.pi/agent/gentle-ai"
  printf '%s\n' '{"schemaVersion":1,"assets":{}}' > "$home/.pi/agent/gentle-ai/managed-assets.json"
  load_overlay "$home" "$TMP_ROOT/diagnostic-unowned-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'CURRENT-UNMANAGED chains/sdd-full.chain.md' "$output" || fail 'current unowned asset was not reported' || exit 1
  grep -Fq 'CUSTOMIZED-UNKNOWN agents/sdd-apply.md' "$output" || fail 'model-frontmatter difference was falsely stale' || exit 1
  grep -Fq 'routing/model rendering can differ' "$output" || fail 'agent routing uncertainty was not explained' || exit 1

  home="$TMP_ROOT/diagnostic-malformed-home"
  write_diag_package "$home"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  mkdir -p "$(dirname -- "$target")" "$home/.pi/agent/gentle-ai" "$root/assets/migrations"
  printf '%s\n' 'unknown edit' > "$target"
  printf '%s\n' '{"schemaVersion":1,"assets":{"../../unsafe":"not-a-hash"}}' > "$home/.pi/agent/gentle-ai/managed-assets.json"
  printf '%s\n' '{"schemaVersion":1,"packageVersion":"old","assets":{"chains/sdd-full.chain.md":"not-a-hash"}}' > "$root/assets/migrations/bad.json"
  load_overlay "$home" "$TMP_ROOT/diagnostic-malformed-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MALFORMED managed-assets.json' "$output" || fail 'unsafe manifest entry was not rejected' || exit 1
  grep -Fq 'MALFORMED migration registry bad.json' "$output" || fail 'unsafe migration hash was not rejected' || exit 1
  grep -Fq 'CUSTOMIZED-UNKNOWN chains/sdd-full.chain.md' "$output" || fail 'unknown edit was called stale' || exit 1

  home="$TMP_ROOT/diagnostic-missing-home"
  write_diag_package "$home"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  mkdir -p "$(dirname -- "$target")" "$home/.pi/agent/gentle-ai"
  cp -- "$source" "$target"
  load_overlay "$home" "$TMP_ROOT/diagnostic-missing-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MISSING managed-assets.json' "$output" || fail 'missing manifest was not reported' || exit 1
  grep -Fq 'CURRENT-UNMANAGED chains/sdd-full.chain.md' "$output" || fail 'missing metadata hid current unowned asset' || exit 1
  hash="$(asset_sha256 "$source")"
  printf '{"schemaVersion":1,"assets":{"chains/sdd-plan.chain.md":"%s"}}\n' "$hash" > "$home/.pi/agent/gentle-ai/managed-assets.json"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MISSING chains/sdd-plan.chain.md' "$output" || fail 'manifest asset missing from package was not reported' || exit 1

  home="$TMP_ROOT/diagnostic-no-package-home"
  mkdir -p "$home/.pi/agent"
  load_overlay "$home" "$TMP_ROOT/diagnostic-no-package-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MISSING gentle-pi package.json' "$output" || fail 'missing package identity was not reported' || exit 1

  home="$TMP_ROOT/diagnostic-package-home"
  mkdir -p "$home/.pi/agent/npm/node_modules/gentle-pi"
  printf '%s\n' '{bad package' > "$home/.pi/agent/npm/node_modules/gentle-pi/package.json"
  load_overlay "$home" "$TMP_ROOT/diagnostic-package-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MALFORMED gentle-pi package.json' "$output" || fail 'malformed package identity was not reported' || exit 1
)

test_managed_asset_diagnostic_defects() (
  local home="$TMP_ROOT/diagnostic-defects-home" backups="$TMP_ROOT/diagnostic-defects-backups" root source target manifest output error hash value outside preferred default pi_home
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  manifest="$home/.pi/agent/gentle-ai/managed-assets.json"
  output="$TMP_ROOT/diagnostic-defects.out"
  error="$TMP_ROOT/diagnostic-defects.err"
  write_diag_package "$home"
  mkdir -p "$(dirname -- "$target")" "$(dirname -- "$manifest")"
  cp -- "$source" "$target"
  load_overlay "$home" "$backups"
  hash="$(asset_sha256 "$source")"

  for value in '{"bad":"type"}' '[]' 'null' '7'; do
    printf '{"schemaVersion":1,"assets":{"chains/sdd-full.chain.md":%s}}\n' "$value" > "$manifest"
    managed_asset_diagnostic > "$output" 2> "$error"
    grep -Fq 'MALFORMED managed-assets.json' "$output" || fail "non-string manifest value $value was accepted" || exit 1
    ! grep -Fq 'CURRENT-UNMANAGED chains/sdd-full.chain.md' "$output" || fail "non-string manifest value $value reached ownership lookup" || exit 1
    [ ! -s "$error" ] || fail "non-string manifest value $value emitted jq diagnostics" || exit 1
  done

  printf '{"schemaVersion":1,"assets":{"chains/sdd-full.chain.md":"%s"}}\n' "$hash" > "$manifest"
  mkdir -p "$root/assets/migrations"
  printf '%s\n' '{"schemaVersion":1,"packageVersion":"old","assets":{"chains/sdd-full.chain.md":{"bad":"type"}}}' > "$root/assets/migrations/bad.json"
  managed_asset_diagnostic > "$output" 2> "$error"
  grep -Fq 'MALFORMED migration registry bad.json' "$output" || fail 'non-string registry value was accepted' || exit 1
  [ ! -s "$error" ] || fail 'non-string registry value emitted jq diagnostics' || exit 1

  outside="$TMP_ROOT/diagnostic-linked-outside"
  mkdir -p "$outside"
  ln -s "$target" "$root/assets/chains/linked.md"
  ln -s "$outside" "$root/assets/chains/linked-dir"
  managed_asset_diagnostic > "$output"
  grep -Fq 'UNAVAILABLE chains/linked.md' "$output" || fail 'source file symlink was skipped' || exit 1
  grep -Fq 'UNAVAILABLE chains/linked-dir' "$output" || fail 'source directory symlink was skipped' || exit 1
  ! grep -Fq 'CURRENT-MANAGED chains/linked.md' "$output" || fail 'source symlink was classified as current' || exit 1

  home="$TMP_ROOT/diagnostic-installed-link-home"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  manifest="$home/.pi/agent/gentle-ai/managed-assets.json"
  write_diag_package "$home"
  mkdir -p "$(dirname -- "$target")" "$(dirname -- "$manifest")"
  ln -s "$outside" "$target"
  load_overlay "$home" "$TMP_ROOT/diagnostic-installed-link-backups"
  hash="$(asset_sha256 "$source")"
  printf '{"schemaVersion":1,"assets":{"chains/sdd-full.chain.md":"%s"}}\n' "$hash" > "$manifest"
  managed_asset_diagnostic > "$output"
  grep -Fq 'UNAVAILABLE chains/sdd-full.chain.md' "$output" || fail 'installed symlink was not reported' || exit 1

  home="$TMP_ROOT/diagnostic-installed-nested-link-home"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/nested/current.md"
  target="$home/.pi/agent/chains/nested/current.md"
  manifest="$home/.pi/agent/gentle-ai/managed-assets.json"
  write_diag_package "$home"
  mkdir -p "$(dirname -- "$source")" "$(dirname -- "$manifest")" "$outside/nested-target"
  printf '%s\n' 'nested source' > "$source"
  cp -- "$source" "$outside/nested-target/current.md"
  mkdir -p "$home/.pi/agent/chains"
  ln -s "$outside/nested-target" "$home/.pi/agent/chains/nested"
  load_overlay "$home" "$TMP_ROOT/diagnostic-installed-nested-link-backups"
  hash="$(asset_sha256 "$source")"
  printf '{"schemaVersion":1,"assets":{"chains/nested/current.md":"%s"}}\n' "$hash" > "$manifest"
  managed_asset_diagnostic > "$output"
  grep -Fq 'UNAVAILABLE chains/nested/current.md' "$output" || fail 'installed nested symlink was not reported' || exit 1
  ! grep -Fq 'CURRENT-MANAGED chains/nested/current.md' "$output" || fail 'installed nested symlink was read as current' || exit 1

  default="$TMP_ROOT/diagnostic-default-root"
  preferred="$TMP_ROOT/diagnostic-preferred-root"
  pi_home="$TMP_ROOT/diagnostic-pi-root"
  write_diag_package "$default" default
  mkdir -p "$preferred/.pi/agent/npm/node_modules/gentle-pi"
  printf '%s\n' '{broken' > "$preferred/.pi/agent/npm/node_modules/gentle-pi/package.json"
  load_overlay_with_roots "$default" "$preferred/.pi/agent" '' "$TMP_ROOT/diagnostic-locator-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MALFORMED gentle-pi package.json' "$output" || fail 'malformed preferred package fell back to default' || exit 1
  ! grep -Fq 'verified gentle-pi@default' "$output" || fail 'malformed preferred package mixed roots' || exit 1

  preferred="$TMP_ROOT/diagnostic-preferred-valid-root"
  write_diag_package "$preferred" preferred
  load_overlay_with_roots "$default" "$preferred/.pi/agent" '' "$TMP_ROOT/diagnostic-locator-valid-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'SOURCE verified gentle-pi@preferred' "$output" || fail 'valid preferred package was not selected' || exit 1
  ! grep -Fq 'verified gentle-pi@default' "$output" || fail 'valid preferred package mixed roots' || exit 1

  preferred="$TMP_ROOT/diagnostic-preferred-missing-root"
  write_diag_package "$pi_home" pi-root
  load_overlay_with_roots "$default" "$preferred/.pi/agent" "$pi_home/.pi/agent" "$TMP_ROOT/diagnostic-locator-missing-backups"
  managed_asset_diagnostic > "$output"
  grep -Fq 'SOURCE verified gentle-pi@pi-root' "$output" || fail 'missing preferred package did not use Pi canonical root' || exit 1
  ! grep -Fq 'verified gentle-pi@default' "$output" || fail 'missing preferred package skipped Pi canonical root' || exit 1
)

test_managed_asset_diagnostic_incomplete_inventory() (
  local home="$TMP_ROOT/diagnostic-incomplete-home" backups="$TMP_ROOT/diagnostic-incomplete-backups" root source target manifest output error hash mode_zero no_execute fifo bin real_find
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  source="$root/assets/chains/sdd-full.chain.md"
  target="$home/.pi/agent/chains/sdd-full.chain.md"
  manifest="$home/.pi/agent/gentle-ai/managed-assets.json"
  output="$TMP_ROOT/diagnostic-incomplete.out"
  error="$TMP_ROOT/diagnostic-incomplete.err"
  write_diag_package "$home"
  mkdir -p "$(dirname -- "$target")" "$(dirname -- "$manifest")"
  cp -- "$source" "$target"
  load_overlay "$home" "$backups"
  hash="$(asset_sha256 "$source")"
  printf '{"schemaVersion":1,"assets":{"chains/sdd-full.chain.md":"%s"}}\n' "$hash" > "$manifest"

  mode_zero="$root/assets/chains/mode-zero"
  no_execute="$root/assets/chains/no-execute"
  fifo="$root/assets/chains/special.md"
  mkdir -p "$mode_zero" "$no_execute"
  printf '%s\n' 'hidden' > "$mode_zero/hidden.md"
  printf '%s\n' 'hidden' > "$no_execute/hidden.md"
  mkfifo "$fifo"
  trap 'chmod 755 "$mode_zero" "$no_execute" 2>/dev/null || true' EXIT
  chmod 000 "$mode_zero"
  chmod 600 "$no_execute"
  managed_asset_diagnostic > "$output" 2> "$error"
  if [ ! -r "$mode_zero" ] || [ ! -x "$mode_zero" ] || [ ! -x "$no_execute" ]; then
    grep -Fq 'UNAVAILABLE package assets/chains (source inventory incomplete)' "$output" || fail 'unreadable nested directory was silently omitted' || exit 1
    ! grep -Fq 'CURRENT-MANAGED chains/sdd-full.chain.md' "$output" || fail 'incomplete chains inventory claimed current' || exit 1
  fi
  chmod 755 "$mode_zero" "$no_execute"
  managed_asset_diagnostic > "$output" 2> "$error"
  grep -Fq 'UNAVAILABLE chains/special.md' "$output" || fail 'FIFO source entry was not reported without reading it' || exit 1
  [ ! -s "$error" ] || fail 'source inventory emitted raw stderr' || exit 1

  bin="$TMP_ROOT/diagnostic-find-bin"
  real_find="$(command -v find)"
  mkdir -p "$bin"
  cat > "$bin/find" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "$DIAG_FIND_FAIL_DIR" ]; then exit 1; fi
exec "$DIAG_REAL_FIND" "$@"
EOF
  chmod 755 "$bin/find"
  (
    PATH="$bin:$PATH"
    DIAG_REAL_FIND="$real_find"
    DIAG_FIND_FAIL_DIR="$root/assets/chains"
    export PATH DIAG_REAL_FIND DIAG_FIND_FAIL_DIR
    managed_asset_diagnostic
  ) > "$output" 2> "$error"
  grep -Fq 'UNAVAILABLE package assets/chains (source inventory incomplete)' "$output" || fail 'controlled find failure was not reported' || exit 1
  ! grep -Fq 'CURRENT-MANAGED chains/sdd-full.chain.md' "$output" || fail 'controlled incomplete inventory claimed current' || exit 1
  ! grep -Fq 'MISSING chains/sdd-full.chain.md (manifest ownership has no current package asset)' "$output" || fail 'controlled incomplete inventory was mislabeled missing' || exit 1
  [ ! -s "$error" ] || fail 'controlled find failure emitted raw stderr' || exit 1
)

test_managed_asset_diagnostic_rejects_unsafe_package_metadata() (
  local home backups root metadata output error kind rc fifo_reader fifo_reader_pid fifo_reader_terminated
  command -v python3 >/dev/null 2>&1 || fail 'python3 is required for package metadata FIFO coverage' || exit 1

  run_with_watchdog() {
    local stdout_path="$1" stderr_path="$2"
    shift 2
    python3 - "$stdout_path" "$stderr_path" "$@" <<'PY'
import os
import signal
import subprocess
import sys
import time

stdout_path, stderr_path = sys.argv[1:3]
child = None

def stop_child():
    if child is None:
        return
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(child.pid, sig)
        except ProcessLookupError:
            break
        time.sleep(.1)
    try:
        child.wait(timeout=.2)
    except subprocess.TimeoutExpired:
        pass

signal.signal(signal.SIGTERM, lambda signum, _frame: sys.exit(128 + signum))
try:
    with open(stdout_path, "wb") as stdout, open(stderr_path, "wb") as stderr:
        deadline = time.monotonic() + 2
        child = subprocess.Popen(
            sys.argv[3:], env=os.environ.copy(), stdout=stdout, stderr=stderr,
            start_new_session=True)
        try:
            rc = child.wait(timeout=max(0, deadline - time.monotonic()))
        except subprocess.TimeoutExpired:
            rc = 124
finally:
    stop_child()
sys.exit(rc)
PY
  }

  fifo_reader="$TMP_ROOT/diagnostic-package-blocked.fifo"
  fifo_reader_pid="$TMP_ROOT/diagnostic-package-blocked.pid"
  fifo_reader_terminated="$TMP_ROOT/diagnostic-package-blocked.term"
  mkfifo "$fifo_reader"
  SECONDS=0
  run_with_watchdog "$TMP_ROOT/diagnostic-package-blocked.out" "$TMP_ROOT/diagnostic-package-blocked.err" bash -c 'trap "printf terminated > \"$3\"; exit" TERM; cat -- "$1" >/dev/null & child=$!; printf "%s\n" "$child" > "$2"; wait "$child"' _ "$fifo_reader" "$fifo_reader_pid" "$fifo_reader_terminated"
  rc=$?
  [ "$rc" -eq 124 ] || fail "blocked FIFO reader returned $rc instead of 124" || exit 1
  [ "$SECONDS" -ge 2 ] || fail 'blocked FIFO reader returned a fake timeout before the deadline' || exit 1
  [ "$SECONDS" -lt 5 ] || fail 'blocked FIFO reader exceeded the watchdog deadline' || exit 1
  [ -s "$fifo_reader_pid" ] || fail 'blocked FIFO reader did not start a descendant' || exit 1
  [ -f "$fifo_reader_terminated" ] || fail 'watchdog did not terminate its process group with SIGTERM' || exit 1
  ! kill -0 "$(cat "$fifo_reader_pid")" 2>/dev/null || fail 'watchdog left the blocked FIFO reader running' || exit 1
  run_with_watchdog "$TMP_ROOT/diagnostic-package-blocked.out" "$TMP_ROOT/diagnostic-package-blocked.err" bash -c 'cat -- "$1" >/dev/null & printf "%s\n" "$!" > "$2"; kill -TERM "$PPID"; wait' _ "$fifo_reader" "$fifo_reader_pid"
  [ "$?" -eq 143 ] || fail 'watchdog did not handle received SIGTERM' || exit 1
  ! kill -0 "$(cat "$fifo_reader_pid")" 2>/dev/null || fail 'received SIGTERM left the child group running' || exit 1
  run_with_watchdog "$TMP_ROOT/diagnostic-package-blocked.out" "$TMP_ROOT/diagnostic-package-blocked.err" bash -c 'cat -- "$1" >/dev/null & printf "%s\n" "$!" > "$2"; exit 0' _ "$fifo_reader" "$fifo_reader_pid"
  [ "$?" -eq 0 ] || fail 'successful leader did not preserve exit 0' || exit 1
  ! kill -0 "$(cat "$fifo_reader_pid")" 2>/dev/null || fail 'successful leader left its descendant running' || exit 1

  : > "$fifo_reader_pid"
  SECONDS=0
  run_with_watchdog "$TMP_ROOT/diagnostic-package-blocked.out" "$TMP_ROOT/diagnostic-package-blocked.err" bash -c '
    printf "%s\n" "$$" > "$2"
    trap "" TERM
    printf ready > "$3"
    exec cat -- "$1"
  ' _ "$fifo_reader" "$fifo_reader_pid" "$fifo_reader_pid.ignoring"
  rc=$?
  [ -s "$fifo_reader_pid" ] || fail 'TERM-ignoring FIFO reader did not start' || exit 1
  if kill -0 "$(cat "$fifo_reader_pid")" 2>/dev/null; then
    kill -KILL -- "-$(cat "$fifo_reader_pid")" 2>/dev/null || true
    fail 'watchdog left its TERM-ignoring FIFO reader running'
    exit 1
  fi
  [ -f "$fifo_reader_pid.ignoring" ] || fail 'FIFO reader never ignored TERM' || exit 1
  [ "$rc" -eq 124 ] || fail "TERM-ignoring FIFO reader returned $rc instead of 124" || exit 1
  [ "$SECONDS" -ge 2 ] || fail 'TERM-ignoring reader returned before the deadline' || exit 1
  [ "$SECONDS" -lt 5 ] || fail 'TERM-ignoring reader exceeded the watchdog deadline' || exit 1

  for kind in fifo directory socket unreadable; do
    if [ "$kind" = socket ]; then home="$TMP_ROOT/p"; else home="$TMP_ROOT/diagnostic-package-$kind-home"; fi
    backups="$TMP_ROOT/diagnostic-package-$kind-backups"
    root="$home/.pi/agent/npm/node_modules/gentle-pi"
    metadata="$root/package.json"
    output="$TMP_ROOT/diagnostic-package-$kind.out"
    error="$TMP_ROOT/diagnostic-package-$kind.err"
    write_diag_package "$home"
    mv -- "$metadata" "$root/package.real"
    case "$kind" in
      fifo) mkfifo "$metadata" ;;
      directory) mkdir "$metadata" ;;
      socket)
        (
          cd -- "$root" || exit
          python3 - <<'PY'
import socket
with socket.socket(socket.AF_UNIX) as socket_file:
    socket_file.bind("package.json")
PY
        )
        [ -S "$metadata" ] || fail 'package metadata socket was not created' || exit 1
        ;;
      unreadable) : > "$metadata"; chmod 000 "$metadata"; [ ! -r "$metadata" ] || continue ;;
    esac
    run_with_watchdog "$output" "$error" env HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" APPLY_SH_LIB=1 bash -c 'source "$1"; managed_asset_diagnostic' _ "$ROOT/apply.sh"
    rc=$?
    [ "$rc" -eq 0 ] || fail "$kind package metadata diagnostic returned $rc" || exit 1
    grep -Fq 'UNAVAILABLE gentle-pi package.json' "$output" || fail "$kind package metadata was not unavailable" || exit 1
    [ ! -s "$error" ] || fail "$kind package metadata emitted raw stderr" || exit 1
    if [ "$kind" = fifo ]; then
      mkdir -p "$home/.gentle-ai"
      printf '%s\n' '{"installed_agents":["pi"]}' > "$home/.gentle-ai/state.json"
      printf '\n' > "$home/.pi/agent/APPEND_SYSTEM.md"
      run_with_watchdog "$output" "$error" env HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh" --check
      rc=$?
      [ "$rc" -eq 2 ] || fail "FIFO package metadata check returned $rc" || exit 1
      run_with_watchdog "$output" "$error" env HOME="$home" GENTLE_AI_BACKUP_ROOT="$backups" "$ROOT/apply.sh"
      rc=$?
      [ "$rc" -eq 0 ] || fail "FIFO package metadata apply returned $rc" || exit 1
    fi
  done
)

test_managed_asset_diagnostic_rejects_forged_package_identity() (
  local home="$TMP_ROOT/diagnostic-package-identity-home" backups="$TMP_ROOT/diagnostic-package-identity-backups"
  local root metadata output="$TMP_ROOT/diagnostic-package-identity.out" error="$TMP_ROOT/diagnostic-package-identity.err" value
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  metadata="$root/package.json"
  write_diag_package "$home"
  printf '%s\n' '{"name":"gentle-pi","version":"outside"}' > "$TMP_ROOT/diagnostic-package-outside.json"
  mv -- "$metadata" "$root/package.real"
  ln -s "$TMP_ROOT/diagnostic-package-outside.json" "$metadata"
  load_overlay "$home" "$backups"
  managed_asset_diagnostic > "$output" 2> "$error"
  grep -Fq 'UNAVAILABLE gentle-pi package.json' "$output" || fail 'symlinked package metadata was read' || exit 1
  ! grep -Fq 'verified gentle-pi@outside' "$output" || fail 'symlinked package metadata forged a source version' || exit 1
  [ ! -s "$error" ] || fail 'symlinked package metadata emitted raw stderr' || exit 1

  home="$TMP_ROOT/diagnostic-package-forged-home"
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  metadata="$root/package.json"
  write_diag_package "$home"
  load_overlay "$home" "$TMP_ROOT/diagnostic-package-forged-backups"
  for value in 'ok\nCURRENT-MANAGED forged' 'ok\tCURRENT-MANAGED forged' 'ok\u001b[31mCURRENT-MANAGED forged'; do
    printf '{"name":"gentle-pi","version":"%s"}\n' "$value" > "$metadata"
    managed_asset_diagnostic > "$output" 2> "$error"
    grep -Fq 'MALFORMED gentle-pi package.json' "$output" || fail "forged package version $value was accepted" || exit 1
    ! grep -Fq 'CURRENT-MANAGED forged' "$output" || fail "forged package version $value injected a diagnostic line" || exit 1
    [ ! -s "$error" ] || fail "forged package version $value emitted raw stderr" || exit 1
  done
  printf '%s\n' '{"name":"gentle-pi","version":"2.5.0-rc.1+build.7"}' > "$metadata"
  managed_asset_diagnostic > "$output"
  grep -Fq 'SOURCE verified gentle-pi@2.5.0-rc.1+build.7' "$output" || fail 'valid prerelease/build package version was rejected' || exit 1
)

test_managed_asset_diagnostic_respects_configured_package_root() (
  local home="$TMP_ROOT/diagnostic-configured-root-home" backups="$TMP_ROOT/diagnostic-configured-root-backups"
  local npm git output="$TMP_ROOT/diagnostic-configured-root.out" error="$TMP_ROOT/diagnostic-configured-root.err" stale="$TMP_ROOT/diagnostic-configured-stale-npm"
  npm="$home/.pi/agent/npm/node_modules/gentle-pi"
  git="$home/.pi/agent/git/github.com/Gentleman-Programming/gentle-pi"
  write_diag_package "$home" stale-npm
  mkdir -p "$git"
  cp -R -- "$npm/assets" "$git/assets"
  printf '%s\n' '{"name":"gentle-pi","version":"configured-git"}' > "$git/package.json"
  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'
  load_overlay "$home" "$backups"
  managed_asset_diagnostic > "$output" 2> "$error"
  grep -Fq 'SOURCE verified gentle-pi@configured-git' "$output" || fail 'configured git package did not beat stale npm metadata' || exit 1
  ! grep -Fq 'verified gentle-pi@stale-npm' "$output" || fail 'configured git diagnostic mixed package roots' || exit 1
  [ ! -s "$error" ] || fail 'configured git package emitted raw stderr' || exit 1

  mv -- "$npm" "$stale"
  managed_asset_diagnostic > "$output"
  grep -Fq 'SOURCE verified gentle-pi@configured-git' "$output" || fail 'configured git-only package was not discovered' || exit 1

  mv -- "$stale" "$npm"
  write_pi_package_settings "$home" '{"packages":["npm:gentle-pi@2.5.0"]}'
  managed_asset_diagnostic > "$output"
  grep -Fq 'SOURCE verified gentle-pi@stale-npm' "$output" || fail 'configured npm package was not selected' || exit 1
  ! grep -Fq 'verified gentle-pi@configured-git' "$output" || fail 'configured npm diagnostic mixed package roots' || exit 1

  write_pi_package_settings "$home" '{"packages":["git:github.com/Gentleman-Programming/gentle-pi@4a71fd"]}'
  printf '%s\n' '{bad package' > "$git/package.json"
  managed_asset_diagnostic > "$output"
  grep -Fq 'MALFORMED gentle-pi package.json' "$output" || fail 'malformed configured package was not rejected' || exit 1
  ! grep -Fq 'verified gentle-pi@stale-npm' "$output" || fail 'malformed configured package fell back to npm' || exit 1
)

test_managed_asset_diagnostic_marks_skipped_source_scope_unavailable() (
  local home="$TMP_ROOT/diagnostic-skipped-source-home" backups="$TMP_ROOT/diagnostic-skipped-source-backups"
  local root manifest output="$TMP_ROOT/diagnostic-skipped-source.out" error="$TMP_ROOT/diagnostic-skipped-source.err" outside="$TMP_ROOT/diagnostic-skipped-source-outside" hash
  root="$home/.pi/agent/npm/node_modules/gentle-pi"
  manifest="$home/.pi/agent/gentle-ai/managed-assets.json"
  write_diag_package "$home"
  load_overlay "$home" "$backups"
  hash="$(asset_sha256 "$root/assets/chains/sdd-full.chain.md")"
  mkdir -p "$(dirname -- "$manifest")" "$outside"
  ln -s "$outside" "$root/assets/chains/linked.md"
  ln -s "$outside" "$root/assets/chains/linked-dir"
  mkfifo "$root/assets/chains/special.md"
  printf '{"schemaVersion":1,"assets":{"chains/linked.md":"%s","chains/linked-dir/child.md":"%s","chains/special.md":"%s","chains/regular-missing.md":"%s"}}\n' "$hash" "$hash" "$hash" "$hash" > "$manifest"
  managed_asset_diagnostic > "$output" 2> "$error"
  grep -Fq 'UNAVAILABLE chains/linked.md' "$output" || fail 'source file symlink was not unavailable' || exit 1
  ! grep -Fq 'MISSING chains/linked.md' "$output" || fail 'source file symlink was mislabeled missing' || exit 1
  grep -Fq 'UNAVAILABLE chains/linked-dir/child.md' "$output" || fail 'source directory symlink child was not unavailable' || exit 1
  ! grep -Fq 'MISSING chains/linked-dir/child.md' "$output" || fail 'source directory symlink child was mislabeled missing' || exit 1
  grep -Fq 'UNAVAILABLE chains/special.md' "$output" || fail 'source FIFO was not unavailable' || exit 1
  ! grep -Fq 'MISSING chains/special.md' "$output" || fail 'source FIFO was mislabeled missing' || exit 1
  grep -Fq 'MISSING chains/regular-missing.md' "$output" || fail 'regular missing source was not reported missing' || exit 1
  [ ! -s "$error" ] || fail 'skipped source inventory emitted raw stderr' || exit 1
)

test_init_rubric_refuses_ambiguous_or_partial_shapes() (
  local home="$TMP_ROOT/init-refusal-home" backups="$TMP_ROOT/init-refusal-backups" skill details pi duplicate before
  skill="$home/.config/opencode/skills/sdd-init/SKILL.md"
  details="$home/.config/opencode/skills/sdd-init/references/init-details.md"
  pi="$home/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md"
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
  [ ! -e "$backups/.pi/agent/npm/node_modules/gentle-pi/assets/agents/sdd-init.md" ] || fail 'refused target was backed up' || exit 1
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
run test_rubric_list_migrates_predecessor_item4_and_cache
run test_rubric_prose_migrates_known_predecessor_exactly
run test_human_clarification_without_runtime_dispatch
run test_rubric_list_refuses_ambiguous_headings
run test_pi_git_only_layout
run test_pi_npm_only_layout
run test_pi_both_layouts_git_configured
run test_pi_both_layouts_npm_configured
run test_pi_final_240_npm_dual_assets
run test_pi_both_layouts_without_jq_fails_before_writes
run test_pi_no_jq_node_unsupported_exact_source_fails_before_writes
run test_pi_no_jq_node_canonical_source_selects_configured_root
run test_pi_settings_without_safe_parser_fail_closed
run test_pi_no_jq_node_invalid_settings_fail_closed
run test_pi_no_jq_settings_absent_unique_root_fallback
run test_pi_no_jq_node_object_source_selects_npm
run test_pi_jq_json_source_record_framing
run test_pi_no_jq_node_json_source_record_framing
run test_pi_conflicting_configured_sources_fail
run test_pi_selected_missing_path_does_not_fallback
run test_pi_selected_missing_sdd_init_does_not_fallback
run test_pi_selected_unsafe_sdd_init_blocks_preflight
run test_pi_object_source_selects_npm_with_jq
run test_pi_unsupported_configured_source_fails
run test_pi_unrecognized_git_identity_fails_closed_before_fallback
run test_pi_local_path_identity_fails_closed_before_fallback
run test_pi_unrelated_helper_does_not_block_unique_npm_layout
run test_pi_canonical_github_forms_select_git
run test_pi_workflow_rubric_forwarding_contract
run test_pi_workflow_refuses_malformed_or_stale_structure
run test_pi_rc3_append_byte_preservation_and_obsolete_transform_removal
run test_symlink_refusal
run test_backup_failure_is_closed
run test_target_drift_is_closed
run test_installed_hosts_fallback_includes_gemini
run test_sdd_init_host_rows_cover_cursor_copilot_and_pi
run test_antigravity_skill_root_resolution
run test_claude_style_resolution_refuses_ambiguity
run test_opencode_sdd_init_inline_delegation_validation
run test_opencode_sdd_init_final_contract_validation
run test_init_rubric_source_shape_refusal
run test_init_rubric_refuses_anchor_inside_managed_section
run test_init_rubric_shared_skill_idempotence_and_backup
run test_init_rubric_reference_and_pi_idempotence
run test_init_rubric_replaces_complete_section
run test_managed_asset_diagnostic
run test_managed_asset_diagnostic_defects
run test_managed_asset_diagnostic_incomplete_inventory
run test_managed_asset_diagnostic_rejects_unsafe_package_metadata
run test_managed_asset_diagnostic_rejects_forged_package_identity
run test_managed_asset_diagnostic_respects_configured_package_root
run test_managed_asset_diagnostic_marks_skipped_source_scope_unavailable
run test_init_rubric_refuses_ambiguous_or_partial_shapes
run test_neutral_external_profile_lifecycle
run test_fresh_260_active_layout_lifecycle

bash "$ROOT/tests/init-rubric-contract.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-compiler-core.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-engram-recovery.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-consumer-gate.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-compiler-benchmark.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-compiler-semantic-evaluation.sh" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-compiler-multi-project-benchmark.sh" --self-test && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
bash "$ROOT/tests/rubric-compiler-multi-project-benchmark.sh" --predictions "$ROOT/tests/fixtures/rubric-compiler/multi-project/predictions-v1.tsv" && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
