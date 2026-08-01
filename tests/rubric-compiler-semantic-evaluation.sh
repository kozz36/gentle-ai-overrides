#!/usr/bin/env bash
# Validates semantic-evaluation artifact integrity and maintainer-only authority.
set -uo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EVAL="$ROOT/tests/fixtures/rubric-compiler/semantic-evaluation"
REQUIRED_BINDINGS=(RUBRIC_SEMANTIC_REFERENCE_CORPUS_ROOT RUBRIC_SEMANTIC_COMPARISON_CORPUS_ROOT RUBRIC_SEMANTIC_PRIMARY_EXPERIMENT_ROOT RUBRIC_SEMANTIC_ENRICHED_EXPERIMENT_ROOT RUBRIC_SEMANTIC_COMPILER_EXPERIMENT_ROOT RUBRIC_SEMANTIC_TASK_BASELINE_EXPERIMENT_ROOT)
missing_bindings=()
for binding in "${REQUIRED_BINDINGS[@]}"; do [ -n "${!binding:-}" ] || missing_bindings+=("$binding"); done
if [ "${#missing_bindings[@]}" -gt 0 ]; then
  printf 'SKIP: semantic evaluation requires explicit external corpus bindings: %s\n' "${missing_bindings[*]}"
  exit 0
fi
for binding in "${REQUIRED_BINDINGS[@]}"; do
  git -C "${!binding}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf 'FAIL: %s must identify an external Git working tree.\n' "$binding" >&2; exit 2; }
done
CNSIC_ROOT="$RUBRIC_SEMANTIC_REFERENCE_CORPUS_ROOT"
GENTLE_ROOT="$RUBRIC_SEMANTIC_COMPARISON_CORPUS_ROOT"
PRIMARY_ROOT="$RUBRIC_SEMANTIC_PRIMARY_EXPERIMENT_ROOT"
ENRICHED_ROOT="$RUBRIC_SEMANTIC_ENRICHED_EXPERIMENT_ROOT"
COMPILER_ROOT="$RUBRIC_SEMANTIC_COMPILER_EXPERIMENT_ROOT"
TASK_BASELINE_ROOT="$RUBRIC_SEMANTIC_TASK_BASELINE_EXPERIMENT_ROOT"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-semantic-evaluation.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT
PASS=0
FAIL=0

ok() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
no() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL + 1)); }

snapshot() {
  local repo=$1 out=$2 surface
  (
    cd "$repo" || exit 1
    git rev-parse HEAD
    GIT_OPTIONAL_LOCKS=0 git status --porcelain=v1 --untracked-files=all
    for surface in .rubric-eval .codegraph .experiment-evidence; do
      [ -e "$surface" ] || continue
      find "$surface" -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
    done
  ) > "$out"
}

count_exact() { grep -Fxc "$2" "$1"; }
has_heading() { grep -Fxq "## $2" "$1"; }

has_axis_dimensions() {
  local report=$1 dimension
  for dimension in \
    'Implementation mode fidelity' \
    'Test-authoring discipline/forwarding fidelity' \
    'Functional validation evidence' \
    'Visual/E2E validation evidence' \
    'Command/harness fidelity' \
    'Coverage and other evidence' \
    'Multi-match resolution' \
    'Fail-closed uncertainty' \
    'Project-specific policy gaps'; do
    grep -Fq "| $dimension |" "$report" || return 1
  done
}

conflates_mode_and_evidence() {
  grep -Eqi '(Playwright|E2E).*(defines|determines|replaces|implies).*(implementation )?mode' "$1" || \
    grep -Eqi 'strict-tdd.*(requires|is defined by).*(Playwright|E2E)' "$1"
}

valid_report() {
  local report=$1 heading
  [ "$(count_exact "$report" 'schema: human-semantic-evaluation/v1')" = 1 ] || return 1
  [ "$(count_exact "$report" 'status: needs-human-approval')" = 1 ] || return 1
  [ "$(grep -Ec '^recommendation: (approve|revise|reject)$' "$report")" = 1 ] || return 1
  [ "$(grep -Ec '^confidence: (low|medium|high)$' "$report")" = 1 ] || return 1
  grep -Eq '^subject: .+' "$report" || return 1
  for heading in 'Source Bindings' 'Evaluation Dimensions' 'Similarities' 'Differences' 'Behavioral Impact' 'Unsupported Or Missing Claims' 'Recommendation' 'Maintainer Decision'; do
    has_heading "$report" "$heading" || return 1
  done
  grep -Eq '^\| .+ \| .+ \| `?(HEAD|sha256):' "$report" || return 1
  grep -Fq 'decision: pending' "$report" || return 1
  grep -Fq 'decision_authority: maintainer' "$report" || return 1
  has_axis_dimensions "$report" || return 1
  ! conflates_mode_and_evidence "$report" || return 1
  ! grep -Eq '^status: (approved|rejected|revised)$' "$report"
}

bound_digest() {
  local report=$1 file=$2 digest
  digest="$(sha256sum "$file" | awk '{print $1}')" || return 1
  grep -Fq "sha256:$digest" "$report"
}

line_number() {
  awk -v target="$2" '$0 == target { count++; line = NR } END { if (count == 1) print line; else exit 1 }' "$1"
}

valid_snapshot() {
  local snapshot=$1 source=$2 head=$3 digest=$4 payload
  [ "$(count_exact "$snapshot" 'schema: human-semantic-evaluation-observed-output/v1')" = 1 ] || return 1
  grep -Fxq "source_path: $source" "$snapshot" || return 1
  grep -Fxq "repository_head: $head" "$snapshot" || return 1
  grep -Fxq "source_sha256: $digest" "$snapshot" || return 1
  grep -Fxq 'artifact_freshness: stale-unbound' "$snapshot" || return 1
  grep -Fxq 'display_kind: faithful-display-copy' "$snapshot" || return 1
  grep -Fq 'faithful display copy' "$snapshot" || return 1
  grep -Fq 'not activation authority' "$snapshot" || return 1
  [ "$(count_exact "$snapshot" '```yaml')" = 1 ] || return 1
  payload="$TMP/$(basename "$snapshot").payload"
  awk '$0 == "```yaml" { inside = 1; next } inside && $0 == "```" { exit } inside { print }' "$snapshot" > "$payload"
  cmp -s "$source" "$payload"
}

valid_index() {
  local index=$1 task compiler enriched first second third fourth fifth decision sixth seventh eighth ninth tenth
  task="$(line_number "$index" '## Task-Intent Baseline Blind Experiment')" || return 1
  compiler="$(line_number "$index" '## Compiler-Bound Blind SDD-Init Experiment')" || return 1
  enriched="$(line_number "$index" '## Enriched Blind SDD-Init Experiment')" || return 1
  first="$(line_number "$index" '2. [Enriched experiment output](cnsic-enriched-experiment-output.md)')" || return 1
  second="$(line_number "$index" '3. [Enriched experiment table comparison](cnsic-enriched-experiment-table-comparison.md)')" || return 1
  third="$(line_number "$index" '4. [Enriched experiment evaluation](cnsic-enriched-experiment-evaluation.md)')" || return 1
  fourth="$(line_number "$index" '## Primary Blind SDD-Init Experiment')" || return 1
  fifth="$(line_number "$index" '2. [Primary experiment output](cnsic-primary-experiment-output.md)')" || return 1
  decision="$(line_number "$index" '5. [Primary experiment decision record](cnsic-primary-experiment-decision.md)')" || return 1
  sixth="$(line_number "$index" '## Historical Stale-Output Review')" || return 1
  seventh="$(line_number "$index" '1. [CNSIC canonical reference](cnsic-canonical-reference.md)')" || return 1
  eighth="$(line_number "$index" '2. [CNSIC observed generator output](cnsic-observed-generator-output.md)')" || return 1
  ninth="$(line_number "$index" '3. [CNSIC rubric table comparison](cnsic-rubric-table-comparison.md)')" || return 1
  tenth="$(line_number "$index" '4. [CNSIC semantic evaluation](cnsic-evaluation.md)')" || return 1
  [ "$task" -lt "$compiler" ] && [ "$compiler" -lt "$enriched" ] && [ "$enriched" -lt "$first" ] && [ "$first" -lt "$second" ] && [ "$second" -lt "$third" ] && [ "$third" -lt "$fourth" ] && [ "$fourth" -lt "$fifth" ] && [ "$fifth" -lt "$decision" ] && [ "$decision" -lt "$sixth" ] && [ "$sixth" -lt "$seventh" ] && [ "$seventh" -lt "$eighth" ] && [ "$eighth" -lt "$ninth" ] && [ "$ninth" -lt "$tenth" ] || return 1
  [ "$(count_exact "$index" "| CNSIC semantic evaluation | pending | \`[approve, revise, reject]\` |")" = 1 ] || return 1
  [ "$(count_exact "$index" "| Gentle AI semantic evaluation | pending | \`[approve, revise, reject]\` |")" = 1 ] || return 1
  [ "$(count_exact "$index" "| Task-intent baseline experiment evaluation | pending | \`[approve, revise, reject]\` |")" = 1 ] || return 1
  [ "$(count_exact "$index" "| Compiler-bound experiment evaluation | pending | \`[approve, revise, reject]\` |")" = 1 ] || return 1
  [ "$(count_exact "$index" "| Enriched experiment evaluation | pending | \`[approve, revise, reject]\` |")" = 1 ] || return 1
  [ "$(count_exact "$index" "| Primary experiment evaluation | reject ([decision record](cnsic-primary-experiment-decision.md)) | \`[approve, revise, reject]\` |")" = 1 ] || return 1
  grep -Fq 'The task-intent baseline, compiler-bound, enriched, historical CNSIC, and Gentle AI reports remain' "$index" && \
    grep -Fq "\`needs-human-approval\`." "$index" && \
    grep -Fq "primary experiment evaluation's envelope is" "$index" && \
    grep -Fq 'resolved externally by its bound decision record;' "$index" && \
    grep -Fq 'decision record; the rejected output remains' "$index" && \
    grep -Fq 'unactivated.' "$index"
}

valid_compiler_output() {
  local display=$1 source=$2 manifest=$3 payload
  [ "$(count_exact "$display" 'schema: human-semantic-evaluation-compiler-bound-experiment-output/v1')" = 1 ] || return 1
  grep -Fxq "source_path: $source" "$display" || return 1
  grep -Fxq "candidate_sha256: $(sha256sum "$source" | awk '{print $1}')" "$display" || return 1
  grep -Fxq "manifest_sha256: $(sha256sum "$manifest" | awk '{print $1}')" "$display" || return 1
  grep -Fq 'not activation' "$display" || return 1
  grep -Fq "authority. No active YAML or \`ResolutionV1\` was emitted." "$display" || return 1
  payload="$TMP/compiler.payload"
  awk '$0 == "```json" { inside = 1; next } inside && $0 == "```" { exit } inside { print }' "$display" > "$payload"
  cmp -s "$source" "$payload"
}

valid_compiler_comparison() {
  local file=$1
  grep -Fq '## Canonical Rubric Table' "$file" && grep -Fq '## Compiler-Bound Candidate Table' "$file" && \
    grep -Fq '## Semantic Alignment Matrix' "$file" && grep -Fq '## V1 To V2 To V3 Delta' "$file" && \
    grep -Fxq '| aligned | 1 |' "$file" && grep -Fxq '| partially-aligned | 1 |' "$file" && \
    grep -Fxq '| missing | 10 |' "$file" && grep -Fxq '| conflict | 4 |' "$file" && \
    grep -Fq 'decision: pending' "$file" && grep -Fq 'allowed_maintainer_actions: [approve, revise, reject]' "$file"
}

valid_task_baseline() {
  local root=$1 output=$2 comparison=$3 report=$4 candidate result manifest provenance final registry
  candidate="$root/.experiment-evidence/candidate-ir.json"; result="$root/.experiment-evidence/result.md"; manifest="$root/.experiment-evidence/manifest.md"; provenance="$root/.experiment-evidence/provenance.md"; final="$root/.experiment-evidence/final-status.md"; registry="$root/.atl/skill-registry.md"
  [ "$(sha256sum "$candidate" | awk '{print $1}')" = af00ca093c2e49c6ec05c3fea20a0efffcfbc294dcb59d3e1a4c1527c8691a6f ] || return 1
  [ "$(sha256sum "$result" | awk '{print $1}')" = a8ee263b7cd85548c82462d8979786f6cf61ddb940c790d4d18db77bd662269c ] || return 1
  [ "$(sha256sum "$manifest" | awk '{print $1}')" = fa57e0962dabae5897af0bd2ffccf852f21c6be315d4d22268b9d96143c7b63c ] || return 1
  [ "$(sha256sum "$root/.experiment-evidence/manifest.sha256" | awk '{print $1}')" = 2ba5520823981fbf24665453d889c30434cef611bd9fa71c1b0eb4368bca5ff3 ] || return 1
  [ "$(sha256sum "$provenance" | awk '{print $1}')" = f80a172d6c68cc3ab7989c9aa036e5e65c03b75d9447700557a9b547d0163853 ] || return 1
  [ "$(sha256sum "$final" | awk '{print $1}')" = c0ce72132a51e453b12af783e4e12ebae375cc00b1277e039302ba1aa13c984d ] || return 1
  [ "$(sha256sum "$registry" | awk '{print $1}')" = 1def63df0b2433cee4116f0c71cf39f2fa8b852e30b340ffb83e239db28fb2a1 ] || return 1
  (cd "$root" && sha256sum -c .experiment-evidence/manifest.sha256 >/dev/null) || return 1
  [ "$(grep -Ec '"source":"generated"' "$candidate")" = 14 ] || return 1
  [ "$(grep -Ec '^[[:space:]]*\{"id":"b-' "$candidate")" = 6 ] || return 1
  [ "$(grep -Ec '"mode":"skip"' "$candidate")" = 1 ] || return 1
  grep -Fq '"selection":"unmatched-only"' "$candidate" && grep -Fq '"mode":"standard"' "$candidate" || return 1
  for case in 'New endpoint' 'Bug fix' 'Behavior-preserving refactor' 'UI layout-only' 'UI behavioral bug' 'Migration' 'Config-only' 'Docker-only' 'Prompt-only' 'Script-only' 'Docs-only' 'Dependency-only' 'Unmatched production file' 'Overlapping security + API change'; do grep -Fq "| $case |" "$result" || return 1; done
  grep -Fq 'Visible row count: **13**. Default is excluded' "$result" && grep -Fq "No \`testing.methods\` namespace and no hand-authored active YAML" "$result" || return 1
  grep -Fq 'decision: pending' "$report" && grep -Fq 'allowed_maintainer_actions: [approve, revise, reject]' "$comparison" || return 1
  ! grep -Fq 'f36ddae7745fc3afae9c9d4e4d5458875b07305eea500b0926d7867931310d9f' "$output" "$comparison" "$report"
}

valid_enriched_output() {
  local display=$1 source=$2 manifest=$3 head=$4 output_digest=$5 manifest_digest=$6 payload
  [ "$(count_exact "$display" 'schema: human-semantic-evaluation-enriched-experiment-output/v1')" = 1 ] || return 1
  grep -Fxq "experiment_path: $ENRICHED_ROOT" "$display" || return 1
  grep -Fxq "source_head: $head" "$display" || return 1
  grep -Fxq "source_path: $source" "$display" || return 1
  grep -Fxq "output_sha256: $output_digest" "$display" || return 1
  grep -Fxq "manifest_path: $manifest" "$display" || return 1
  grep -Fxq "manifest_sha256: $manifest_digest" "$display" || return 1
  grep -Fxq 'reference_body_sha256: 06eb642b8f5d1a2789426ca19e96060881793b1d4e401bf5ff542ba622c45313' "$display" || return 1
  grep -Fxq 'artifact_freshness: fresh-source-bound' "$display" || return 1
  grep -Fq 'not activation authority' "$display" || return 1
  [ "$(count_exact "$display" '```yaml')" = 1 ] || return 1
  payload="$TMP/$(basename "$display").payload"
  awk '$0 == "```yaml" { inside = 1; next } inside && $0 == "```" { exit } inside { print }' "$display" > "$payload"
  cmp -s "$source" "$payload"
}

valid_primary_decision() {
  local decision=$1 report=$2 output=$3 manifest=$4 head=$5 output_digest manifest_digest report_digest
  output_digest="$(sha256sum "$output" | awk '{print $1}')" || return 1
  manifest_digest="$(sha256sum "$manifest" | awk '{print $1}')" || return 1
  report_digest="$(sha256sum "$report" | awk '{print $1}')" || return 1
  [ "$(count_exact "$decision" 'schema: human-semantic-evaluation-decision-record/v1')" = 1 ] || return 1
  [ "$(grep -Ec '^decision: (approve|revise|reject)$' "$decision")" = 1 ] || return 1
  grep -Fxq 'decision: reject' "$decision" || return 1
  grep -Fxq 'authority: maintainer' "$decision" || return 1
  grep -Eq '^recorded_at: [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' "$decision" || return 1
  grep -Fxq 'user_evidence: reject' "$decision" || return 1
  grep -Fxq 'evaluation_path: cnsic-primary-experiment-evaluation.md' "$decision" || return 1
  grep -Fxq "evaluation_sha256: $report_digest" "$decision" || return 1
  grep -Fxq "source_head: $head" "$decision" || return 1
  grep -Fxq "output_sha256: $output_digest" "$decision" || return 1
  grep -Fxq "manifest_sha256: $manifest_digest" "$decision" || return 1
  grep -Fq 'remains immutable with its' "$decision" && \
    grep -Fq "\`needs-human-approval\` envelope" "$decision" && \
    grep -Fq 'resolves that envelope' "$decision" && \
    grep -Fq 'externally; it does not alter' "$decision" && \
    grep -Fq 'must not be activated or revised in place' "$decision" && \
    grep -Fq 'new fresh blind run' "$decision" && \
    grep -Fq 'new decision record.' "$decision"
}

valid_primary_output() {
  local display=$1 source=$2 manifest=$3 head=$4 output_digest=$5 manifest_digest=$6 payload
  [ "$(count_exact "$display" 'schema: human-semantic-evaluation-primary-experiment-output/v1')" = 1 ] || return 1
  grep -Fxq "experiment_path: $PRIMARY_ROOT" "$display" || return 1
  grep -Fxq "source_head: $head" "$display" || return 1
  grep -Fxq "source_path: $source" "$display" || return 1
  grep -Fxq "output_sha256: $output_digest" "$display" || return 1
  grep -Fxq "manifest_path: $manifest" "$display" || return 1
  grep -Fxq "manifest_sha256: $manifest_digest" "$display" || return 1
  grep -Fxq 'artifact_freshness: fresh-source-bound' "$display" || return 1
  grep -Fq 'not activation authority' "$display" || return 1
  [ "$(count_exact "$display" '```yaml')" = 1 ] || return 1
  payload="$TMP/$(basename "$display").payload"
  awk '$0 == "```yaml" { inside = 1; next } inside && $0 == "```" { exit } inside { print }' "$display" > "$payload"
  cmp -s "$source" "$payload"
}

primary_canonical_coverage() {
  local comparison=$1 trigger
  for trigger in \
    'New endpoint or new domain function in services/agent/llm implementing behavior' \
    'Bug fix' \
    'db/schema/migrations/**' \
    'db/rbac_catalog_v50.py or require_capability' \
    'New cross-bounded-context SELECT/JOIN in services or db/queries' \
    'agent/tools/**' \
    'Egress chokepoint semantic change' \
    'LLM/Runner/transport wired to existing port' \
    'frontend/src/**' \
    'Behavior-preserving refactor' \
    'prompt or work_phases.py' \
    'config.py' \
    'Infra Docker/env files' \
    'scripts/**' \
    'docs/CHANGELOG/runbooks' \
    'Dependency bump'; do
    grep -Fq "| $trigger |" "$comparison" || return 1
  done
}

valid_primary_comparison() {
  local comparison=$1 generated_rows canonical_rows matrix_rows
  grep -Fq 'Engram #3351, supersedes #305' "$comparison" || return 1
  grep -Fq 'sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e' "$comparison" || return 1
  grep -Fq "HEAD: $(git -C "$PRIMARY_ROOT" rev-parse HEAD)" "$comparison" || return 1
  grep -Fq "$PRIMARY_ROOT/openspec/config.yaml" "$comparison" || return 1
  grep -Fq "sha256:$(sha256sum "$PRIMARY_ROOT/openspec/config.yaml" | awk '{print $1}')" "$comparison" || return 1
  grep -Fq "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" "$comparison" || return 1
  grep -Fq "sha256:$(sha256sum "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" | awk '{print $1}')" "$comparison" || return 1
  grep -Fxq '| signature | implementation mode | disciplines | evidence |' "$comparison" || return 1
  for row in \
    '| source | standard | backend-pytest, backend-integration-pytest, backend-container-build | unit, integration, build |' \
    '| boundary/api | standard | backend-pytest, backend-integration-pytest, e2e-playwright, backend-container-build | unit, integration, e2e, build |' \
    '| ui | standard | frontend-vitest, frontend-eslint, frontend-build, e2e-playwright | unit, lint, build, e2e |' \
    '| migration | standard | backend-pytest, backend-integration-pytest, backend-container-build | unit, integration, build |' \
    '| docs | skip |  |  |' \
    '| default | standard | backend-pytest | unit |'; do
    grep -Fxq "$row" "$comparison" || return 1
  done
  grep -Fxq 'rows: 6' "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" || return 1
  grep -Fxq 'bindings: 7' "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" || return 1
  primary_canonical_coverage "$comparison" || return 1
  canonical_rows="$(table_row_count "$comparison" '## Canonical Rubric Table' '## Generated Rubric Table')"
  generated_rows="$(table_row_count "$comparison" '## Generated Rubric Table' '## Semantic Alignment Matrix')"
  matrix_rows="$(table_row_count "$comparison" '## Semantic Alignment Matrix' '## Summary')"
  [ "$canonical_rows:$generated_rows:$matrix_rows" = '16:6:16' ] || return 1
  awk -F '|' '
    BEGIN { FS = "|" }
    $0 == "## Semantic Alignment Matrix" { inside = 1; next }
    inside && $0 == "## Summary" { exit }
    inside && /^\|/ && $0 !~ /^\| ---/ && $0 !~ /^\| canonical trigger/ {
      assessment = $8
      gsub(/^[[:space:]]+/, "", assessment)
      gsub(/[[:space:]]+$/, "", assessment)
      if (assessment !~ /^(aligned|partially-aligned|missing|conflict)$/) exit 1
      count++
    }
    END { exit count != 16 }
  ' "$comparison" || return 1
  grep -Fxq '| aligned | 1 |' "$comparison" || return 1
  grep -Fxq '| partially-aligned | 6 |' "$comparison" || return 1
  grep -Fxq '| missing | 7 |' "$comparison" || return 1
  grep -Fxq '| conflict | 2 |' "$comparison" || return 1
  grep -Fq 'decision: pending' "$comparison" || return 1
  grep -Fq 'allowed_maintainer_actions: [approve, revise, reject]' "$comparison"
}

valid_enriched_comparison() {
  local comparison=$1 generated_rows canonical_rows matrix_rows
  grep -Fq 'Engram #3351, supersedes #305' "$comparison" || return 1
  grep -Fq 'reference_body_sha256:06eb642b8f5d1a2789426ca19e96060881793b1d4e401bf5ff542ba622c45313' "$comparison" || return 1
  grep -Fq "HEAD: $(git -C "$ENRICHED_ROOT" rev-parse HEAD)" "$comparison" || return 1
  grep -Fq "$ENRICHED_ROOT/openspec/config.yaml" "$comparison" || return 1
  grep -Fq "sha256:$(sha256sum "$ENRICHED_ROOT/openspec/config.yaml" | awk '{print $1}')" "$comparison" || return 1
  grep -Fq "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" "$comparison" || return 1
  grep -Fq "sha256:$(sha256sum "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" | awk '{print $1}')" "$comparison" || return 1
  grep -Fq 'decision: reject' "$comparison" || return 1
  grep -Fxq '| signature | implementation mode | disciplines | source |' "$comparison" || return 1
  for row in \
    '| db/schema/migrations/** or db/schema.py migration registry | strict-tdd | unit, integration, build | generated |' \
    '| adapters/**, services/**, agent/**, llm/**, db/** Python behavior or API boundary changes | strict-tdd | unit, build | generated |' \
    '| authentication, authorization, secrets, state transitions, persistence, or audit behavior | strict-tdd | unit, integration, build | generated |' \
    '| frontend/** user-visible behavior, accessibility, client state, or UI | strict-tdd | unit, lint, build, e2e | generated |' \
    '| cross-layer assistant, transport, or integration boundary | strict-tdd | unit, integration, e2e, build | generated |' \
    '| behavior-preserving refactor of executable code | strict-tdd | unit, build | generated |' \
    '| docs/**, *.md, CHANGELOG.md, LICENSE | skip | none | generated |' \
    '| scripts/** utility/wrapper changes without dedicated tests | skip | none | generated |' \
    '| dependency-only, configuration-only, Docker/operations-only, prompt-only, or project-skill-only diffs | skip | none | generated, maintainer-selected |' \
    '| unmatched-only default | skip | none | generated, maintainer-selected |'; do
    grep -Fxq "$row" "$comparison" || return 1
  done
  grep -Fxq 'rows=10' "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" || return 1
  grep -Fxq 'bindings=8' "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" || return 1
  primary_canonical_coverage "$comparison" || return 1
  canonical_rows="$(table_row_count "$comparison" '## Canonical Rubric Table' '## Enriched Generated Rubric Table')"
  generated_rows="$(table_row_count "$comparison" '## Enriched Generated Rubric Table' '## Semantic Alignment Matrix')"
  matrix_rows="$(table_row_count "$comparison" '## Semantic Alignment Matrix' '## Improvement Delta From Rejected First Experiment')"
  [ "$canonical_rows:$generated_rows:$matrix_rows" = '16:10:16' ] || return 1
  awk -F '|' '
    $0 == "## Semantic Alignment Matrix" { inside = 1; next }
    inside && $0 == "## Improvement Delta From Rejected First Experiment" { exit }
    inside && /^\|/ && $0 !~ /^\| ---/ && $0 !~ /^\| canonical trigger/ {
      assessment = $8
      gsub(/^[[:space:]]+/, "", assessment)
      gsub(/[[:space:]]+$/, "", assessment)
      if (assessment !~ /^(aligned|partially-aligned|missing|conflict)$/) exit 1
      count++
    }
    END { exit count != 16 }
  ' "$comparison" || return 1
  grep -Fxq '| aligned | 2 |' "$comparison" || return 1
  grep -Fxq '| partially-aligned | 8 |' "$comparison" || return 1
  grep -Fxq '| missing | 0 |' "$comparison" || return 1
  grep -Fxq '| conflict | 6 |' "$comparison" || return 1
  grep -Fq '## Improvement Delta From Rejected First Experiment' "$comparison" || return 1
  grep -Fq 'Material producer richness improvement' "$comparison" || return 1
  grep -Fq 'No activation improvement' "$comparison" || return 1
  grep -Fq 'decision: pending' "$comparison" && \
    grep -Fq 'allowed_maintainer_actions: [approve, revise, reject]' "$comparison"
}

table_row_count() {
  awk -v start="$2" -v end="$3" '
    $0 == start { inside = 1; next }
    inside && $0 == end { exit }
    inside && /^\|/ && $0 !~ /^\| ---/ && $0 !~ /^\| (Signature|signature|canonical trigger)/ { count++ }
    END { print count + 0 }
  ' "$1"
}

valid_comparison() {
  local comparison=$1 generated_rows canonical_rows matrix_rows
  grep -Fq 'Engram #3351, supersedes #305' "$comparison" || return 1
  grep -Fq 'sha256:d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e' "$comparison" || return 1
  grep -Fq 'HEAD: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab' "$comparison" || return 1
  grep -Fq 'sha256:5f510a8f37d388e08c73f95cac2f2d2d3a9067e42e4e1afefa1283efad566c13' "$comparison" || return 1
  grep -Fq 'artifact_freshness: stale-unbound' "$comparison" || return 1
  grep -Fxq '| signature | implementation mode | disciplines | evidence bindings | source |' "$comparison" || return 1
  for row in \
    '| backend-source | standard | unit | backend-unit | generated |' \
    '| boundary-api | strict-tdd | unit, integration | backend-unit, backend-integration | generated |' \
    '| ui-visible | strict-tdd | unit, lint, build, e2e | frontend-unit, frontend-lint, frontend-build, frontend-e2e | generated |' \
    '| migration | strict-tdd | unit, integration, build | backend-unit, backend-integration, container-build | generated |' \
    '| docs | skip |  |  | generated |' \
    '| default | standard |  |  | generated |'; do
    grep -Fxq "$row" "$comparison" || return 1
  done
  for trigger in \
    'New endpoint or new domain function in services/agent/llm implementing behavior' \
    'Bug fix' \
    'db/schema/migrations/**' \
    'db/rbac_catalog_v50.py or require_capability' \
    'New cross-bounded-context SELECT/JOIN in services or db/queries' \
    'agent/tools/**' \
    'Egress chokepoint semantic change' \
    'LLM/Runner/transport wired to existing port' \
    'frontend/src/**' \
    'Behavior-preserving refactor' \
    'prompt or work_phases.py' \
    'config.py' \
    'Infra Docker/env files' \
    'scripts/**' \
    'docs/CHANGELOG/runbooks' \
    'Dependency bump'; do
    grep -Fq "| $trigger |" "$comparison" || return 1
  done
  canonical_rows="$(table_row_count "$comparison" '## Canonical Rubric Table' '## Generated Rubric Table')"
  generated_rows="$(table_row_count "$comparison" '## Generated Rubric Table' '## Semantic Alignment Matrix')"
  matrix_rows="$(table_row_count "$comparison" '## Semantic Alignment Matrix' '## Summary')"
  [ "$canonical_rows:$generated_rows:$matrix_rows" = '16:6:16' ] || return 1
  awk -F '|' '
    BEGIN { FS = "|" }
    $0 == "## Semantic Alignment Matrix" { inside = 1; next }
    inside && $0 == "## Summary" { exit }
    inside && /^\|/ && $0 !~ /^\| ---/ && $0 !~ /^\| canonical trigger/ {
      assessment = $8
      gsub(/^[[:space:]]+/, "", assessment)
      gsub(/[[:space:]]+$/, "", assessment)
      if (assessment !~ /^(aligned|partially-aligned|missing|conflict)$/) exit 1
      count++
    }
    END { exit count != 16 }
  ' "$comparison" || return 1
  grep -Fxq '| aligned | 1 |' "$comparison" || return 1
  grep -Fxq '| partially-aligned | 7 |' "$comparison" || return 1
  grep -Fxq '| missing | 7 |' "$comparison" || return 1
  grep -Fxq '| conflict | 1 |' "$comparison" || return 1
  grep -Fq 'decision: pending' "$comparison" || return 1
  grep -Fq 'allowed_maintainer_actions: [approve, revise, reject]' "$comparison"
}

snapshot "$CNSIC_ROOT" "$TMP/cnsic.before" || { no 'CNSIC pre-evaluation snapshot'; exit 1; }
snapshot "$GENTLE_ROOT" "$TMP/gentle.before" || { no 'Gentle AI pre-evaluation snapshot'; exit 1; }
snapshot "$PRIMARY_ROOT" "$TMP/primary.before" || { no 'primary experiment pre-evaluation snapshot'; exit 1; }
snapshot "$ENRICHED_ROOT" "$TMP/enriched.before" || { no 'enriched experiment pre-evaluation snapshot'; exit 1; }
snapshot "$COMPILER_ROOT" "$TMP/compiler.before" || { no 'compiler-bound experiment pre-evaluation snapshot'; exit 1; }

REFERENCE="$EVAL/cnsic-canonical-reference.md"
CNSIC_REPORT="$EVAL/cnsic-evaluation.md"
GENTLE_REPORT="$EVAL/gentle-ai-evaluation.md"
CNSIC_SNAPSHOT="$EVAL/cnsic-observed-generator-output.md"
GENTLE_SNAPSHOT="$EVAL/gentle-ai-observed-generator-output.md"
INDEX="$EVAL/review-index.md"
COMPARISON="$EVAL/cnsic-rubric-table-comparison.md"
PRIMARY_OUTPUT="$EVAL/cnsic-primary-experiment-output.md"
PRIMARY_COMPARISON="$EVAL/cnsic-primary-experiment-table-comparison.md"
PRIMARY_REPORT="$EVAL/cnsic-primary-experiment-evaluation.md"
PRIMARY_DECISION="$EVAL/cnsic-primary-experiment-decision.md"
ENRICHED_OUTPUT="$EVAL/cnsic-enriched-experiment-output.md"
ENRICHED_COMPARISON="$EVAL/cnsic-enriched-experiment-table-comparison.md"
ENRICHED_REPORT="$EVAL/cnsic-enriched-experiment-evaluation.md"
COMPILER_OUTPUT="$EVAL/cnsic-compiler-bound-experiment-output.md"
COMPILER_COMPARISON="$EVAL/cnsic-compiler-bound-experiment-table-comparison.md"
COMPILER_REPORT="$EVAL/cnsic-compiler-bound-experiment-evaluation.md"
TASK_OUTPUT="$EVAL/cnsic-task-baseline-experiment-output.md"
TASK_COMPARISON="$EVAL/cnsic-task-baseline-experiment-table-comparison.md"
TASK_REPORT="$EVAL/cnsic-task-baseline-experiment-evaluation.md"
REFERENCE_DIGEST="$(awk '/^<!-- canonical-reference:start -->$/{inside=1;next}/^<!-- canonical-reference:end -->$/{exit}inside{print}' "$REFERENCE" | sha256sum | awk '{print $1}')"

if [ "$(count_exact "$REFERENCE" 'schema: human-semantic-evaluation-reference/v1')" = 1 ] && \
  grep -Fq 'project: cnsic-agent' "$REFERENCE" && \
  grep -Fq 'source_observation: "#3351"' "$REFERENCE" && \
  grep -Fq 'supersedes_observation: "#305"' "$REFERENCE" && \
  grep -Fq 'reference_kind: faithful-behavioral-snapshot' "$REFERENCE" && \
  grep -Fxq "reference_body_sha256: $REFERENCE_DIGEST" "$REFERENCE" && \
  grep -Fq "sha256:$REFERENCE_DIGEST" "$CNSIC_REPORT" && \
  grep -Fq 'not claimed to be byte-identical' "$REFERENCE" && \
  grep -Fq '<!-- canonical-reference:start -->' "$REFERENCE" && \
  grep -Fq '<!-- canonical-reference:end -->' "$REFERENCE"; then
  ok 'CNSIC reference declares faithful Engram provenance without byte-parity claim'
else
  no 'CNSIC reference provenance or boundary is incomplete'
fi

if valid_report "$CNSIC_REPORT"; then ok 'CNSIC report has the human-in-the-loop envelope'; else no 'CNSIC report envelope is invalid'; fi
if valid_report "$GENTLE_REPORT"; then ok 'Gentle AI report has the human-in-the-loop envelope'; else no 'Gentle AI report envelope is invalid'; fi
if valid_report "$PRIMARY_REPORT"; then ok 'primary experiment report has the human-in-the-loop envelope'; else no 'primary experiment report envelope is invalid'; fi
if valid_report "$ENRICHED_REPORT"; then ok 'enriched experiment report has the human-in-the-loop envelope'; else no 'enriched experiment report envelope is invalid'; fi
if valid_report "$COMPILER_REPORT"; then ok 'compiler-bound experiment report has the human-in-the-loop envelope'; else no 'compiler-bound experiment report envelope is invalid'; fi
if grep -Fxq 'status: needs-human-approval' "$TASK_REPORT" && grep -Fxq 'recommendation: revise' "$TASK_REPORT" && grep -Fxq 'decision: pending' "$TASK_REPORT" && grep -Fxq 'decision_authority: maintainer' "$TASK_REPORT"; then ok 'task-baseline experiment report has the human-in-the-loop envelope'; else no 'task-baseline experiment report envelope is invalid'; fi

if valid_task_baseline "$TASK_BASELINE_ROOT" "$TASK_OUTPUT" "$TASK_COMPARISON" "$TASK_REPORT"; then
  ok 'task-baseline evidence hashes, rows, simulations, and authority boundary are valid'
else
  no 'task-baseline evidence or policy boundary is invalid'
fi

if valid_snapshot "$CNSIC_SNAPSHOT" "$CNSIC_ROOT/openspec/config.yaml" "$(git -C "$CNSIC_ROOT" rev-parse HEAD)" "$(sha256sum "$CNSIC_ROOT/openspec/config.yaml" | awk '{print $1}')"; then
  ok 'CNSIC observed-output snapshot is a source-bound faithful display copy'
else
  no 'CNSIC observed-output snapshot drifted or lost its authority boundary'
fi

if valid_snapshot "$GENTLE_SNAPSHOT" "$GENTLE_ROOT/.rubric-eval/candidate-v2.yaml" "$(git -C "$GENTLE_ROOT" rev-parse HEAD)" "$(sha256sum "$GENTLE_ROOT/.rubric-eval/candidate-v2.yaml" | awk '{print $1}')"; then
  ok 'Gentle AI observed-output snapshot is a source-bound faithful display copy'
else
  no 'Gentle AI observed-output snapshot drifted or lost its authority boundary'
fi

if valid_primary_output "$PRIMARY_OUTPUT" "$PRIMARY_ROOT/openspec/config.yaml" "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" "$(git -C "$PRIMARY_ROOT" rev-parse HEAD)" "$(sha256sum "$PRIMARY_ROOT/openspec/config.yaml" | awk '{print $1}')" "$(sha256sum "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" | awk '{print $1}')"; then
  ok 'primary experiment output is a fresh source-bound faithful display copy'
else
  no 'primary experiment output drifted or lost its authority boundary'
fi

if valid_enriched_output "$ENRICHED_OUTPUT" "$ENRICHED_ROOT/openspec/config.yaml" "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" "$(git -C "$ENRICHED_ROOT" rev-parse HEAD)" "$(sha256sum "$ENRICHED_ROOT/openspec/config.yaml" | awk '{print $1}')" "$(sha256sum "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" | awk '{print $1}')"; then
  ok 'enriched experiment output is a fresh source-bound faithful display copy'
else
  no 'enriched experiment output drifted or lost its authority boundary'
fi

if valid_compiler_output "$COMPILER_OUTPUT" "$COMPILER_ROOT/.experiment-evidence/candidate/ir.json" "$COMPILER_ROOT/.experiment-evidence/manifest.txt"; then
  ok 'compiler-bound candidate is a fresh source-bound faithful display copy'
else
  no 'compiler-bound candidate drifted or lost its authority boundary'
fi

if valid_index "$INDEX"; then ok 'review index preserves source-to-evaluation order and decision state'; else no 'review index ordering or decision state is invalid'; fi

if valid_primary_decision "$PRIMARY_DECISION" "$PRIMARY_REPORT" "$PRIMARY_ROOT/openspec/config.yaml" "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" "$(git -C "$PRIMARY_ROOT" rev-parse HEAD)"; then
  ok 'primary experiment decision is maintainer-bound and prohibits activation'
else
  no 'primary experiment decision record is invalid or permits activation'
fi

if valid_comparison "$COMPARISON"; then ok 'CNSIC rubric comparison preserves source rows and two-axis assessments'; else no 'CNSIC rubric comparison is incomplete or invalid'; fi
if valid_primary_comparison "$PRIMARY_COMPARISON"; then ok 'primary comparison preserves source rows, bindings, and two-axis assessments'; else no 'primary comparison is incomplete or invalid'; fi
if valid_enriched_comparison "$ENRICHED_COMPARISON"; then ok 'enriched comparison preserves source rows, delta, and two-axis assessments'; else no 'enriched comparison is incomplete or invalid'; fi
if valid_compiler_comparison "$COMPILER_COMPARISON"; then ok 'compiler-bound comparison preserves matrix and v1-to-v3 delta'; else no 'compiler-bound comparison is incomplete or invalid'; fi

if bound_digest "$PRIMARY_REPORT" "$PRIMARY_ROOT/openspec/config.yaml" && \
  bound_digest "$PRIMARY_REPORT" "$PRIMARY_ROOT/.experiment-evidence/manifest.yaml" && \
  bound_digest "$PRIMARY_REPORT" "$PRIMARY_ROOT/AGENTS.md" && \
  bound_digest "$PRIMARY_REPORT" "$PRIMARY_ROOT/frontend/package.json" && \
  bound_digest "$PRIMARY_REPORT" "$PRIMARY_ROOT/tests/e2e/playwright/package.json"; then
  ok 'primary experiment report binds output, manifest, and cited evidence'
else
  no 'primary experiment report source binding drifted'
fi

if bound_digest "$COMPILER_REPORT" "$COMPILER_ROOT/.experiment-evidence/candidate/ir.json" && \
  bound_digest "$COMPILER_REPORT" "$COMPILER_ROOT/.experiment-evidence/manifest.txt" && \
  bound_digest "$COMPILER_REPORT" "$COMPILER_ROOT/AGENTS.md"; then
  ok 'compiler-bound experiment report binds candidate, manifest, and policy evidence'
else
  no 'compiler-bound experiment report source binding drifted'
fi

if bound_digest "$ENRICHED_REPORT" "$ENRICHED_ROOT/openspec/config.yaml" && \
  bound_digest "$ENRICHED_REPORT" "$ENRICHED_ROOT/.experiment-evidence/manifest.txt" && \
  bound_digest "$ENRICHED_REPORT" "$ENRICHED_ROOT/AGENTS.md" && \
  bound_digest "$ENRICHED_REPORT" "$ENRICHED_ROOT/frontend/package.json" && \
  bound_digest "$ENRICHED_REPORT" "$ENRICHED_ROOT/tests/e2e/playwright/package.json"; then
  ok 'enriched experiment report binds output, manifest, and cited evidence'
else
  no 'enriched experiment report source binding drifted'
fi

if bound_digest "$CNSIC_REPORT" "$CNSIC_ROOT/openspec/config.yaml" && \
  bound_digest "$CNSIC_REPORT" "$CNSIC_ROOT/AGENTS.md" && \
  bound_digest "$CNSIC_REPORT" "$CNSIC_ROOT/scripts/run_tests.sh"; then
  ok 'CNSIC report binds observed output and policy evidence'
else
  no 'CNSIC report source binding drifted'
fi

if bound_digest "$GENTLE_REPORT" "$GENTLE_ROOT/.rubric-eval/candidate-v2.yaml" && \
  bound_digest "$GENTLE_REPORT" "$GENTLE_ROOT/openspec/config.yaml" && \
  bound_digest "$GENTLE_REPORT" "$GENTLE_ROOT/CONTRIBUTING.md" && \
  bound_digest "$GENTLE_REPORT" "$GENTLE_ROOT/docs/trigger-rules.md" && \
  bound_digest "$GENTLE_REPORT" "$GENTLE_ROOT/docs/review-authority-threat-model.md"; then
  ok 'Gentle AI report binds observed output and repository evidence'
else
  no 'Gentle AI report source binding drifted'
fi

cp "$CNSIC_REPORT" "$TMP/self-approved.md"
sed -i 's/status: needs-human-approval/status: approved/' "$TMP/self-approved.md"
if ! valid_report "$TMP/self-approved.md"; then ok 'self-approved report rejects'; else no 'self-approved report was accepted'; fi

cp "$CNSIC_REPORT" "$TMP/missing-bindings.md"
sed -i '/^## Source Bindings$/,/^## Evaluation Dimensions$/d' "$TMP/missing-bindings.md"
if ! valid_report "$TMP/missing-bindings.md"; then ok 'report without source bindings rejects'; else no 'report without source bindings was accepted'; fi

cp "$CNSIC_REPORT" "$TMP/decision-conflated.md"
sed -i 's/decision: pending/decision: approve/' "$TMP/decision-conflated.md"
if ! valid_report "$TMP/decision-conflated.md"; then ok 'recommendation cannot become a maintainer decision'; else no 'conflated maintainer decision was accepted'; fi

cp "$CNSIC_REPORT" "$TMP/advisory-approve.md"
sed -i 's/recommendation: revise/recommendation: approve/' "$TMP/advisory-approve.md"
if valid_report "$TMP/advisory-approve.md"; then ok 'advisory approval remains pending human approval'; else no 'advisory recommendation handling is invalid'; fi

cp "$CNSIC_REPORT" "$TMP/conflated-axes.md"
printf '\nPlaywright evidence defines the implementation mode.\n' >> "$TMP/conflated-axes.md"
if ! valid_report "$TMP/conflated-axes.md"; then ok 'report conflating mode and visual evidence rejects'; else no 'report conflating mode and visual evidence was accepted'; fi

if grep -Fq 'Deterministic validation cannot validate semantic quality' "$EVAL/evaluation-schema.md" && \
  grep -Fq 'maintainer_decision: pending' "$EVAL/evaluation-schema.md" && \
  grep -Fq 'Playwright/E2E is validation evidence' "$EVAL/evaluation-schema.md" && \
  grep -Fq 'An advisory evaluation is immutable after review.' "$EVAL/evaluation-schema.md" && \
  grep -Fq "A \`reject\` decision prohibits activation and in-place revision" "$EVAL/evaluation-schema.md"; then
  ok 'schema documents semantic limits and maintainer authority'
else
  no 'schema overstates deterministic authority'
fi

snapshot "$CNSIC_ROOT" "$TMP/cnsic.after" || no 'CNSIC post-evaluation snapshot'
snapshot "$GENTLE_ROOT" "$TMP/gentle.after" || no 'Gentle AI post-evaluation snapshot'
snapshot "$PRIMARY_ROOT" "$TMP/primary.after" || no 'primary experiment post-evaluation snapshot'
snapshot "$ENRICHED_ROOT" "$TMP/enriched.after" || no 'enriched experiment post-evaluation snapshot'
snapshot "$COMPILER_ROOT" "$TMP/compiler.after" || no 'compiler-bound experiment post-evaluation snapshot'
if cmp -s "$TMP/cnsic.before" "$TMP/cnsic.after"; then ok 'CNSIC clone remained immutable'; else no 'CNSIC clone changed'; fi
if cmp -s "$TMP/gentle.before" "$TMP/gentle.after"; then ok 'Gentle AI clone remained immutable'; else no 'Gentle AI clone changed'; fi
if cmp -s "$TMP/primary.before" "$TMP/primary.after"; then ok 'primary experiment clone remained immutable'; else no 'primary experiment clone changed'; fi
if cmp -s "$TMP/enriched.before" "$TMP/enriched.after"; then ok 'enriched experiment clone remained immutable'; else no 'enriched experiment clone changed'; fi
if cmp -s "$TMP/compiler.before" "$TMP/compiler.after"; then ok 'compiler-bound experiment clone remained immutable'; else no 'compiler-bound experiment clone changed'; fi

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
