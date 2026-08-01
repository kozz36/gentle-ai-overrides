#!/usr/bin/env bash
# Static contract checks for the sdd-init rubric delta. This intentionally does
# not source apply.sh; transform and host coverage live in tests/run.sh.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-overrides-contract.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

fail() { printf 'FAIL: %s\n' "$*" >&2; return 1; }

line_number() {
  awk -v target="$2" '$0 == target { count++; line = NR } END { if (count == 1) print line; else exit 1 }' "$1"
}

assert_project_declared_satisfiability() {
  local file="$1" label="$2"
  grep -Fq 'project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool' "$file" || fail "$label lacks project-declared satisfiability" || return 1
  grep -Fq 'MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell' "$file" || fail "$label permits host-shell-only detection" || return 1
  grep -Fq 'A config section naming a framework without a declared dependency/environment/command is insufficient' "$file" || fail "$label accepts framework-only configuration" || return 1
  grep -Fq 'Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof' "$file" || fail "$label lacks scoped capability bindings" || return 1
  grep -Fq 'A method satisfiable in one scope is not satisfiable globally' "$file" || fail "$label permits cross-scope satisfiability" || return 1
  grep -Fq 'A generated row may require a method only when its bound command applies to that row' "$file" || fail "$label permits unbound row requirements" || return 1
  grep -Fq 'When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one' "$file" || fail "$label lacks scoped command persistence" || return 1
  grep -Fq 'If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope' "$file" || fail "$label permits cross-scope command borrowing" || return 1
  grep -Fq 'Every candidate capability binding records separate command_declaration and tool_proof fields' "$file" || fail "$label lacks separate command/proof fields" || return 1
  grep -Fq 'command_declaration identifies where the exact command is declared' "$file" || fail "$label lacks command declaration provenance" || return 1
  grep -Fq 'tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable' "$file" || fail "$label lacks independent tool proof" || return 1
  grep -Fq 'The command/script text itself can NEVER satisfy tool_proof' "$file" || fail "$label permits self-proving commands" || return 1
  grep -Fq 'An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted' "$file" || fail "$label lacks eslint unsatisfied example" || return 1
  grep -Fq 'Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied' "$file" || fail "$label lacks binding audit gate" || return 1
}

assert_policy_contract() {
  local file="$1" label="$2"
  grep -Fq 'Before a valid answer, return the candidate but persist no selected policy or active rubric' "$file" || fail "$label persists policy before selection" || return 1
  grep -Fq 'Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric' "$file" || fail "$label allows active rubric in strict mode" || return 1
  grep -Fq 'Answer `rubric`: submit the candidate to the canonical compiler; only its verified activation may persist `strict_tdd: false` plus the active authoritative rubric' "$file" || fail "$label permits direct rubric-mode activation" || return 1
  grep -Fq 'Never populate `default` by unioning all detected methods' "$file" || fail "$label permits non-selective default rows" || return 1
  grep -Fq '## TDD RUBRIC (per-work-type — AUTHORITATIVE)' "$file" || fail "$label lacks authoritative rubric heading" || return 1
  grep -Fq '| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence |' "$file" || fail "$label lacks consumer-compatible rubric table" || return 1
  grep -Fq 'Signatures classify production implementation/work-type diffs' "$file" || fail "$label permits test-only production classification" || return 1
  grep -Fq '`default` is selected ONLY when no non-default signature matches' "$file" || fail "$label lets default join specific matches" || return 1
  grep -Fq 'When any non-default row matches, default does not join the union' "$file" || fail "$label unions default with specific rows" || return 1
  grep -Fq 'MODE enum: `skip < standard < strict-tdd`' "$file" || fail "$label lacks closed MODE order" || return 1
  grep -Fq '`strict-tdd` means a full test-first cycle' "$file" || fail "$label lacks strict-tdd meaning" || return 1
  grep -Fq '`standard` requires evidence without mandatory test-first ordering' "$file" || fail "$label lacks standard meaning" || return 1
  grep -Fq '`skip` has no automated test gate unless another matching row unions evidence' "$file" || fail "$label lacks skip meaning" || return 1
  grep -Fq 'Status: active/authoritative.' "$file" || fail "$label lacks active rubric status" || return 1
  grep -Fq '| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |' "$file" || fail "$label lacks provenance column" || return 1
  grep -Fq 'Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically' "$file" || fail "$label lacks deterministic provenance maintenance" || return 1
  grep -Fq 'Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric' "$file" || fail "$label permits duplicate policy artifacts" || return 1
  grep -Fq 'Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation' "$file" || fail "$label lacks strict destructive confirmation" || return 1
  grep -Fq 'Selecting rubric submits the candidate to compiler activation; only verified activation persists `strict_tdd: false` plus exactly one active rubric' "$file" || fail "$label permits direct re-init activation" || return 1
  grep -Fq 'OpenSpec: `testing.rubric.active` is the only active OpenSpec path; parallel `testing.methods` authority is forbidden' "$file" || fail "$label lacks canonical active path" || return 1
  grep -Fq 'Reject alternate active keys such as `rubric_status`' "$file" || fail "$label permits alternate active keys" || return 1
  grep -Fq 'Re-init reads only `testing.rubric.active`' "$file" || fail "$label reads noncanonical rubric paths" || return 1
  grep -Fq 'rubric: absent (not active:false, not candidate, no rows)' "$file" || fail "$label lacks strict rubric absence semantics" || return 1
  grep -Fq 'mode_order: [skip, standard, strict-tdd]' "$file" || fail "$label lacks canonical mode order serialization" || return 1
  grep -Fq 'matching: all-rows' "$file" || fail "$label lacks canonical matching serialization" || return 1
  grep -Fq 'bindings: [...]  # each has id, method, command context, scope/signature coverage, command_declaration, tool_proof' "$file" || fail "$label lacks canonical binding schema" || return 1
  grep -Fq 'rows: [...]      # each has signature, mode exact enum, binding IDs, source generated|manual' "$file" || fail "$label lacks canonical row schema" || return 1
}

validate_delta_shape() {
  awk '
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
    { if (inside) body[inside] = body[inside] (body[inside] == "" ? "" : "\n") $0 }
    END {
      for (name in expected) if (opened[name] != 1 || closed[name] != 1 || body[name] == "") bad = 1
      exit bad
    }
  ' "$1"
}

test_policy_contract() (
  local init="$ROOT/deltas/sdd-init-rubric.md" consumer="$ROOT/deltas/rubric-tdd.md"
  assert_project_declared_satisfiability "$init" 'sdd-init delta' || exit 1
  assert_policy_contract "$init" 'sdd-init delta' || exit 1
  grep -Fq 'RubricConsumerEnvelopeV1' "$consumer" || fail 'consumer lacks the state-gate envelope' || exit 1
  grep -Fq 'sole resolution owner' "$consumer" || fail 'consumer permits downstream resolution' || exit 1
  grep -Fq 'RubricConsumerBlockedV1' "$consumer" || fail 'consumer lacks the blocked state-gate envelope' || exit 1
  grep -Fq 'never fall back to rubric `default` or binary `strict_tdd`' "$consumer" || fail 'consumer permits fallback after rubric observation' || exit 1
  grep -Fq 'only when no rubric state has ever been observed' "$consumer" || fail 'consumer lacks the legacy boundary' || exit 1
)

test_delta_shape_grammar() (
  local dir="$TMP_ROOT/source-shapes" fixture
  mkdir -p "$dir"
  validate_delta_shape "$ROOT/deltas/sdd-init-rubric.md" || fail 'canonical delta has invalid shape markers' || exit 1
  for fixture in duplicate missing unpaired nested reordered; do
    case "$fixture" in
      duplicate) printf '%s\n' '<!-- shape:skill -->' 'one' '<!-- /shape:skill -->' '<!-- shape:skill -->' 'two' '<!-- /shape:skill -->' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      missing) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      unpaired) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      nested) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- shape:details -->' 'details' '<!-- /shape:details -->' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
      reordered) printf '%s\n' '<!-- shape:skill -->' 'skill' '<!-- /shape:details -->' '<!-- shape:details -->' 'details' '<!-- /shape:skill -->' '<!-- shape:pi -->' 'pi' '<!-- /shape:pi -->' > "$dir/$fixture.md" ;;
    esac
    if validate_delta_shape "$dir/$fixture.md"; then
      fail "$fixture malformed source shape was accepted" || exit 1
    fi
  done
)

extract_validator() {
  local shape="$1" out="$2"
  awk -v shape="$shape" '
    $0 == "<!-- shape:" shape " -->" { inside = 1; next }
    $0 == "<!-- /shape:" shape " -->" { exit }
    inside && /^<!-- rubric-validator:start -->$/ { body = 1; next }
    inside && /^<!-- rubric-validator:end -->$/ { exit }
    inside && body { print }
  ' "$ROOT/deltas/sdd-init-rubric.md" > "$out"
  [ -s "$out" ] || fail "$shape lacks validator bytes"
}

test_validator_shape_parity() (
  local details="$TMP_ROOT/details-validator" pi="$TMP_ROOT/pi-validator"
  extract_validator details "$details" || exit 1
  extract_validator pi "$pi" || exit 1
  cmp -s "$details" "$pi" || fail 'details and Pi validator bytes differ' || exit 1
  [ "$(cksum < "$details")" = "$(cksum < "$pi")" ] || fail 'details and Pi validator checksums differ' || exit 1
)

test_structural_boundary() (
  local init="$ROOT/deltas/sdd-init-rubric.md"
  grep -Fq 'structure-valid/pending' "$init" || fail 'validator lacks structural pending result' || exit 1
  grep -Fq 'Candidate commands are data' "$init" || fail 'validator permits candidate execution' || exit 1
  grep -Fq 'No field named `provider` is accepted' "$init" || fail 'validator permits caller provider booleans' || exit 1
  ! grep -Fq 'manifest:true' "$init" || fail 'validator retains provider semantic acceptance' || exit 1
  grep -Fq 'The deterministic compiler is non-authoritative for semantic rows' "$init" || fail 'compiler may author semantic rows' || exit 1
  grep -Fq 'never invents or upgrades a semantic row' "$init" || fail 'compiler authority boundary is incomplete' || exit 1
)

extract_init_shape() {
  local shape="$1" out="$2"
  awk -v open="<!-- shape:$shape -->" -v end_marker="<!-- /shape:$shape -->" '
    $0 == open { inside = 1; next }
    $0 == end_marker { exit }
    inside { print }
  ' "$ROOT/deltas/sdd-init-rubric.md" > "$out"
  [ -s "$out" ] || fail "$shape source asset is missing"
}

test_deterministic_fallback_contract() (
  local reference="$TMP_ROOT/rubric-authoring.md" reason
  extract_init_shape reference "$reference" || exit 1
  grep -Fq '## Deterministic Baseline Fallback Producer' "$reference" || fail 'reference lacks deterministic fallback producer contract' || exit 1
  grep -Fq 'Fallback is eligible only before a valid candidate is published' "$reference" || fail 'fallback eligibility is not limited to pre-publication primary failure' || exit 1
  for reason in provider-unconfigured provider-unavailable provider-timeout primary-output-malformed primary-output-structurally-invalid; do
    grep -Fq "\`$reason\`" "$reference" || { fail "fallback reason is missing: $reason"; exit 1; }
  done
  grep -Fq 'A valid existing rubric is preserved; fallback never replaces it.' "$reference" || fail 'fallback may replace a valid rubric' || exit 1
  grep -Fq 'invalid, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched observed canonical state remains recovery-blocked; fallback MUST NOT overwrite or bypass it.' "$reference" || fail 'fallback may bypass observed invalid canonical state' || exit 1
  grep -Fq 'When primary output is malformed or structurally invalid before canonical state publication, discard it and invoke fallback only as a pending candidate.' "$reference" || fail 'malformed primary output may reach fallback after publication' || exit 1
  grep -Fq 'After canonical state is observed, malformed primary output remains recovery-blocked and never invokes fallback.' "$reference" || fail 'observed invalid state may invoke fallback' || exit 1
  grep -Fq 'Emit every Task-Intent Policy Baseline v1 row in baseline-table order' "$reference" || fail 'fallback ordering is not deterministic' || exit 1
  grep -Fq 'Bind only detected project capabilities that are satisfiable for the row scope' "$reference" || fail 'fallback may invent or mis-scope evidence bindings' || exit 1
  grep -Fq 'Do not infer external or project-specific policy, commands, evidence, or local rules' "$reference" || fail 'fallback may infer local policy' || exit 1
  grep -Fq 'producer: deterministic-baseline-fallback' "$reference" || fail 'fallback producer provenance is missing' || exit 1
  grep -Fq 'fallback_reason: one admitted enum value above' "$reference" || fail 'fallback reason provenance is missing' || exit 1
  grep -Fq 'fallback output is candidate/IR input only: it cannot write active YAML or Engram policy directly and cannot mint `ResolutionV1`.' "$reference" || fail 'fallback has a direct activation route' || exit 1
  grep -Fq 'The canonical compiler validates and publishes primary and fallback candidates through exactly one shared path:' "$reference" || fail 'fallback bypasses the shared compiler path' || exit 1
)

test_rubric_authoring_reference_contract() (
  local reference="$TMP_ROOT/rubric-authoring.md" init="$ROOT/deltas/sdd-init-rubric.md" one two three four five matrix_rows skip_rows
  extract_init_shape reference "$reference" || exit 1
  grep -Fq 'MUST read `references/rubric-authoring.md`' "$init" || fail 'sdd-init does not require the authoring reference before rubric work' || exit 1
  grep -Fq 'a rubric candidate may be generated' "$init" || fail 'sdd-init does not require the reference before candidate generation' || exit 1
  grep -Fq 'Build two independent inventories' "$reference" || fail 'reference lacks separate inventories' || exit 1
  grep -Fq 'Test capability does not establish implementation mode.' "$reference" || fail 'reference conflates capability and mode' || exit 1
  grep -Fq 'Playwright/E2E is evidence, not a mode.' "$reference" || fail 'reference conflates E2E and mode' || exit 1
  grep -Fq 'Apply strictest-wins only across genuinely orthogonal matches and union their evidence.' "$reference" || fail 'reference lacks multi-match resolution' || exit 1
  grep -Fq 'a project-specific manual seed may be necessary' "$reference" || fail 'reference lacks manual-seed fallback' || exit 1
  grep -Fq 'Flag any command/cwd/proof contradiction.' "$reference" || fail 'self-audit does not catch command/cwd/proof contradictions' || exit 1
  grep -Fq 'Flag all-standard output when no policy evidence supports `standard`.' "$reference" || fail 'self-audit does not catch unsupported all-standard output' || exit 1
  grep -Fq '| `web/**` user-visible behavior | `standard` from' "$reference" || fail 'generic example does not separate UI mode and evidence' || exit 1
  grep -Fq 'Emit only the existing canonical directory candidate bundle/IR' "$reference" || fail 'reference permits ad hoc OpenSpec serialization' || exit 1
  grep -Fq 'A row with disciplines or evidence MUST reference binding IDs' "$reference" || fail 'reference permits method-only row evidence' || exit 1
  grep -Fq '`testing.methods` is not an authority namespace and is forbidden' "$reference" || fail 'reference permits parallel methods authority' || exit 1
  grep -Fq 'structural validator, exact replay through adapter records/gate, canonical-model verification, canonical serializer, and activation/readback gates' "$reference" || fail 'reference lacks canonical gate handoff' || exit 1
  grep -Fq 'ResolutionV1`, transaction, canonical-model digest, backend authority, and verified readback evidence' "$reference" || fail 'reference permits active authority without receipts' || exit 1
  grep -Fq 'binding id: ui-unit' "$reference" || fail 'reference lacks canonical binding-to-row example' || exit 1
  grep -Fq 'rows[binding_refs=[ui-unit]]' "$reference" || fail 'reference example does not close row binding IDs' || exit 1
  grep -Fq 'Never hand-author `openspec/config.yaml`, `testing.methods`, or active YAML' "$init" || fail 'Pi contract permits ad hoc active YAML' || exit 1
  grep -Fq 'parallel `testing.methods` authority is forbidden' "$init" || fail 'shared contract permits methods authority' || exit 1
  grep -Fq 'exact Result Contract in `references/rubric-authoring.md`' "$init" || fail 'shared contract lacks required result projection' || exit 1
  grep -Fq '## Task-Intent Policy Baseline v1' "$reference" || fail 'reference lacks versioned task-intent baseline' || exit 1
  grep -Fq 'This versioned Task-Intent Policy Baseline is global policy evidence, not advisory-only guidance.' "$reference" || fail 'baseline is merely advisory' || exit 1
  grep -Fq 'baseline_version: task-intent-policy-baseline/v1' "$reference" || fail 'baseline version is not bound as provenance' || exit 1
  grep -Fq 'baseline_source_digest' "$reference" || fail 'baseline source digest is not bound as provenance' || exit 1
  grep -Fq 'Baseline rows are prospective rules for future work, not claims that a task class currently exists' "$reference" || fail 'baseline omits future task intents' || exit 1
  grep -Fq 'An explicit project/manual row replaces the equivalent generated baseline row before runtime matching' "$reference" || fail 'manual/project equivalent co-matches baseline' || exit 1
  grep -Fq 'Absent project policy does not erase the baseline.' "$reference" || fail 'absent project policy erases baseline' || exit 1
  grep -Fq 'A broad directory or path family alone cannot select `strict-tdd`' "$reference" || fail 'reference permits broad path-only strict rows' || exit 1
  grep -Fq 'classify declared task intent, corroborate it with changed paths/symbols, reject ambiguous or multiple incompatible intents' "$reference" || fail 'runtime intent-first classification is incomplete' || exit 1
  grep -Fq 'Dependency, config, Docker, operations, prompt/model, and project-skill categories MUST remain separate questions' "$reference" || fail 'reference collapses granular category decisions' || exit 1
  grep -Fq 'Preserve the exact Lossless Blocking Prompt selection semantics' "$reference" || fail 'reference weakens the blocking prompt' || exit 1
  grep -Fq 'Prefer one compact specific skip row for non-executable documentation or metadata' "$reference" || fail 'reference permits skip-row proliferation' || exit 1
  grep -Fq 'Utility scripts are not automatically skip.' "$reference" || fail 'reference permits automatic script skips' || exit 1
  grep -Fq '## 1. Complete Rubric Table' "$reference" || fail 'result contract lacks rubric table' || exit 1
  grep -Fq '| # | Detectable signature | Implementation mode | Disciplines/evidence | Binding refs | Source | Rationale/policy evidence |' "$reference" || fail 'result contract rubric columns differ' || exit 1
  grep -Fq '## 2. Default' "$reference" || fail 'result contract lacks separate default' || exit 1
  grep -Fq 'Do not count or render `default` as a regular rubric row.' "$reference" || fail 'default is counted as a normal row' || exit 1
  grep -Fq '| # | ID | Method | Scope | Executable/argv | Workdir | Env/platform/requirements | Declaration | Tool proof |' "$reference" || fail 'result contract binding columns differ' || exit 1
  grep -Fq '| Case | Selected rows | Effective mode | Unioned evidence | Expected forwarding |' "$reference" || fail 'result contract simulation columns differ' || exit 1
  grep -Fq '| UI behavioral bug | `bug-fix`, `ui-behavior-or-bug` | `strict-tdd` | reproducing unit, e2e |' "$reference" || fail 'UI behavioral bug does not retain strict plus E2E evidence' || exit 1
  grep -Fq '| UI layout-only | `ui-layout-style-only` | `standard` | visual, e2e |' "$reference" || fail 'UI layout-only becomes strict' || exit 1
  grep -Fq '| Config-only | `config-infra-operations` | `standard` | smoke, rollback |' "$reference" || fail 'config-only becomes strict' || exit 1
  grep -Fq '| Docker-only | `config-infra-operations` | `standard` | build, smoke, rollback |' "$reference" || fail 'Docker-only becomes strict' || exit 1
  grep -Fq '| Prompt-only | `prompt-model-policy` | `standard` | characterization, domain validation |' "$reference" || fail 'prompt-only becomes strict' || exit 1
  grep -Fq '| Dependency-only | `dependency-bump` | `standard` | relevant/full regression, build |' "$reference" || fail 'dependency-only becomes strict' || exit 1
  grep -Fq '| Overlapping security + API change | `new-observable-behavior`, `security-state-data-mutation` | `strict-tdd` |' "$reference" || fail 'security/API overlap does not retain strict union' || exit 1
  one="$(line_number "$reference" '## 1. Complete Rubric Table')" && two="$(line_number "$reference" '## 2. Default')" && three="$(line_number "$reference" '## 3. Complete Validation Bindings Table')" && four="$(line_number "$reference" '## 4. Orchestrator Resolution Simulation Table')" && five="$(line_number "$reference" '## 5. Pending Questions And Activation/Receipt State')" && [ "$one" -lt "$two" ] && [ "$two" -lt "$three" ] && [ "$three" -lt "$four" ] && [ "$four" -lt "$five" ] || { fail 'result contract sections are not exactly ordered'; exit 1; }
  matrix_rows="$(awk '$0 == "## Task-Intent Policy Baseline v1" { inside = 1; next } inside && $0 == "## Layered Policy And Selective Matching" { exit } inside && /^\|/ && $0 !~ /^\| ---/ && $0 !~ /^\| Task-intent class/ { count++ } END { print count + 0 }' "$reference")"
  [ "$matrix_rows" = 14 ] || { fail "baseline matrix has $matrix_rows rows, expected 14"; exit 1; }
  skip_rows="$(awk '$0 == "## Task-Intent Policy Baseline v1" { inside = 1; next } inside && $0 == "## Layered Policy And Selective Matching" { exit } inside && /^\|/ && $0 ~ /\| `skip` \|/ { count++ } END { print count + 0 }' "$reference")"
  [ "$skip_rows" = 1 ] || { fail "baseline has $skip_rows visible skip classes, expected 1"; exit 1; }
  for row in \
    '| `new-observable-behavior` | `strict-tdd` |' \
    '| `bug-fix` | `strict-tdd` |' \
    '| `security-state-data-mutation` | `strict-tdd` |' \
    '| `migration-schema` | `strict-tdd` |' \
    '| `behavior-preserving-refactor` | `standard` |' \
    '| `ui-layout-style-only` | `standard` |' \
    '| `ui-behavior-or-bug` | `strict-tdd` |' \
    '| `cross-layer-port-wiring` | `standard` |' \
    '| `prompt-model-policy` | `standard` |' \
    '| `config-infra-operations` | `standard` |' \
    '| `executable-script` | `standard` |' \
    '| `docs-runbook-metadata` | `skip` |' \
    '| `dependency-bump` | `standard` |' \
    '| `default` | conservative `standard` |'; do
    grep -Fq "$row" "$reference" || { fail "baseline class is missing: $row"; exit 1; }
  done
  ! grep -Eiq 'cnsic|rbac_catalog|work_phases' "$reference" || fail 'generic reference contains project-specific policy strings' || exit 1
)

extract_rubric_shape() {
  local shape="$1" out="$2"
  awk -v open="<!-- shape:$shape -->" -v end_marker="<!-- /shape:$shape -->" '
    $0 == open { inside = 1; next }
    $0 == end_marker { exit }
    inside { print }
  ' "$ROOT/deltas/rubric-tdd.md" > "$out"
  [ -s "$out" ] || fail "$shape rubric shape is missing"
}

test_consumer_host_shape_goldens() (
  local list="$TMP_ROOT/rubric-list" prose="$TMP_ROOT/rubric-prose" cache="$TMP_ROOT/rubric-cache"
  local expected_list="$TMP_ROOT/expected-list" expected_prose="$TMP_ROOT/expected-prose" expected_cache="$TMP_ROOT/expected-cache"
  local expected_hosts="$TMP_ROOT/expected-hosts" actual_hosts="$TMP_ROOT/actual-hosts" json="$TMP_ROOT/opencode.json"

  cat > "$expected_list" <<'EOF'
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate.
   The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification.
   Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`.
   Binary `strict_tdd` is permitted only when no rubric state has ever been observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
EOF
  cat > "$expected_prose" <<'EOF'
Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate. The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever been observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
EOF
  printf '%s\n' 'The orchestrator consumes the producer-resolved rubric envelope ONCE per session (at first apply/verify launch) and caches it, re-classifying each apply slice by its diff signature.' > "$expected_cache"
  printf '%s\n' \
    'claude-code|rubric-prose' \
    'pi|rubric-list' \
    'opencode|rubric-json' \
    'codex|rubric-none' \
    'cursor|rubric-list' \
    'vscode-copilot|rubric-list' \
    'gemini-cli|rubric-list' \
    'antigravity|rubric-list' > "$expected_hosts"

  extract_rubric_shape list-item "$list" || exit 1
  extract_rubric_shape prose "$prose" || exit 1
  extract_rubric_shape cache-sentence "$cache" || exit 1
  cmp -s "$list" "$expected_list" || fail 'list rubric golden differs' || exit 1
  cmp -s "$prose" "$expected_prose" || fail 'Claude lazy-prose rubric golden differs' || exit 1
  cmp -s "$cache" "$expected_cache" || fail 'rubric cache golden differs' || exit 1
  awk '/^  cat <<'\''ROWS'\''$/{inside=1; next} inside && /^ROWS$/{exit} inside && $0 ~ /\|rubric-(prose|list|json|none)\|/ { split($0, fields, "|"); print fields[1] "|" fields[2] }' "$ROOT/apply.sh" > "$actual_hosts"
  cmp -s "$actual_hosts" "$expected_hosts" || fail 'managed rubric host map differs or expands Kimi scope' || exit 1
  ! grep -Fq 'kimi|' "$ROOT/apply.sh" || fail 'Kimi is unexpectedly managed' || exit 1
  grep -Fq 'Kimi is explicitly current-scope unmanaged.' "$list" || fail 'Kimi scope boundary is not explicit' || exit 1
  grep -Fq 'RubricConsumerEnvelopeV1' "$list" || fail 'list lacks consumer envelope wording' || exit 1
  grep -Fq 'RubricConsumerBlockedV1' "$prose" || fail 'prose lacks consumer blocked wording' || exit 1
  ! grep -Fq 'otherwise preserve binary `strict_tdd` behavior' "$ROOT/deltas/rubric-tdd.md" || fail 'legacy fallback wording remains' || exit 1
  ! grep -Fq 'change against the matching rubric row' "$ROOT/deltas/rubric-tdd.md" || fail 'single-row fallback wording remains' || exit 1

  jq -n --rawfile prompt "$expected_list" '{agent: {"gentle-orchestrator": {prompt: ($prompt | rtrimstr("\n"))}}}' > "$json"
  jq -e --rawfile expected "$expected_list" '.agent["gentle-orchestrator"].prompt == ($expected | rtrimstr("\n"))' "$json" >/dev/null || fail 'OpenCode JSON rubric golden differs' || exit 1
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

run test_policy_contract
run test_delta_shape_grammar
run test_validator_shape_parity
run test_structural_boundary
run test_deterministic_fallback_contract
run test_rubric_authoring_reference_contract
run test_consumer_host_shape_goldens

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
