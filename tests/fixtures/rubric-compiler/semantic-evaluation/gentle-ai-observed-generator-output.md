---
schema: human-semantic-evaluation-observed-output/v1
subject: "Gentle AI observed generator output"
source_path: /home/kozz36/gentle-ai-upstream-986-review/.rubric-eval/candidate-v2.yaml
repository_head: ffbcc12fad5594a7c5186614341d490f0440c110
source_sha256: d2cc840d1b2946beb40836c01f79196a35e9bae3a342675a7fbdd05d98ea4564
artifact_freshness: stale-unbound
display_kind: faithful-display-copy
---

# Gentle AI Observed Generator Output

The fenced YAML below is a faithful display copy of the source bytes bound
above. It is not activation authority, a fresh generation receipt, or a
maintainer decision.

```yaml
version: 2
project: gentle-ai
policy_questions:
  - "Does the maintainer require a local CI-equivalent release gate before tagging?"
  - "Should Windows full-suite and Darwin release-blocker CI-only lanes be mirrored locally?"
detected_but_unsatisfied:
  - method: lint
    reason: "No project-local linter command and no linter dependency/provider; gofmtcheck is format validation, not lint."
  - method: typecheck
    reason: "Go compiler checks are available through build/test, but no separately declared typecheck command exists."
  - method: coverage
    reason: "No declared coverage command or coverage threshold."
  - method: format
    scope: local
    reason: "CI declares go run ./internal/gofmtcheck, but the repository does not declare a local format command; CI binding is retained separately."
inference_limits:
  - "CodeGraph establishes boundaries, fan-out, and generated propagation only; it does not establish mode or runnable commands."
  - "CI matrix expressions, secrets, runner.temp, and GitHub event conditionals are not executable local bindings."
  - "No explicit test-first or regression-first rule was found; strict-tdd is therefore not inferred."
bindings:
  - id: go-unit
    method: unit
    scope: "all Go packages"
    command: "go test ./..."
    workdir: "."
    shell: bash
    platform: [linux, macos, windows]
    env: {}
    requires: [Go 1.25.10+]
    command_kind: local
    command_declaration: "CONTRIBUTING.md:103-109; docs/architecture.md:45-50"
    tool_proof: "go.mod:3 declares go 1.25.10"
    provenance: [project-local, referenced-project-doc]
  - id: go-build
    method: build
    scope: "Go production code"
    command: "go build ./..."
    workdir: "."
    shell: bash
    platform: [linux, macos, windows]
    env: {}
    requires: [Go 1.25.10+]
    command_kind: local
    command_declaration: "CONTRIBUTING.md:85-91 (go build -o gga .); normalized package build"
    tool_proof: "go.mod:3 declares go 1.25.10"
    provenance: [project-local]
  - id: go-e2e-docker
    method: e2e
    scope: "e2e Docker installer tiers"
    command: "./docker-test.sh"
    workdir: "e2e"
    shell: bash
    platform: [linux]
    env: {RUN_FULL_E2E: "1", RUN_BACKUP_TESTS: "1"}
    requires: [Docker]
    command_kind: local
    command_declaration: "CONTRIBUTING.md:123-133; docs/architecture.md:52"
    tool_proof: "e2e/Dockerfile.ubuntu; e2e/Dockerfile.arch; e2e/Dockerfile.fedora"
    provenance: [project-local, referenced-project-doc]
  - id: go-format-ci
    method: format
    scope: "Go source in CI"
    command: "go run ./internal/gofmtcheck"
    workdir: "."
    shell: bash
    platform: [linux]
    env: {}
    requires: [Go 1.25.10+]
    command_kind: ci
    command_declaration: ".github/workflows/ci.yml:28-29"
    tool_proof: "go.mod:3 declares Go toolchain"
    provenance: [CI]
  - id: go-vet-ci
    method: typecheck
    scope: "release preflight Go code"
    command: "go vet ./..."
    workdir: "."
    shell: bash
    platform: [linux]
    env: {}
    requires: [Go 1.25.10+]
    command_kind: ci
    command_declaration: ".github/workflows/release.yml:85-86"
    tool_proof: "go.mod:3 declares Go toolchain"
    provenance: [CI]
  - id: organic-e2e-ci
    method: e2e
    scope: "e2e/organicruntime"
    command: "go test -v ./e2e/organicruntime -count=1 -timeout=15m"
    workdir: "."
    shell: bash
    platform: [linux, windows]
    env: {GENTLE_AI_REAL_AGENT_E2E: "1"}
    requires: [Go 1.25.10+, Node 24, opencode-ai 1.18.4]
    command_kind: ci
    command_declaration: ".github/workflows/ci.yml:183-202"
    tool_proof: "go.mod:3; workflow setup-node and npm install --global opencode-ai@1.18.4"
    provenance: [CI]
  - id: windows-release-blockers-ci
    method: integration
    scope: "Windows release-blocker test manifest"
    command: "go test -v ./internal/cli ./internal/reviewtransaction ./internal/sddstatus -run '<manifest>' -count=1 -timeout=8m"
    workdir: "."
    shell: pwsh
    platform: [windows]
    env: {GENTLE_AI_REQUIRE_DISTINCT_WINDOWS_TOKEN_OWNER: "1"}
    requires: [Go 1.25.10+]
    command_kind: ci
    command_declaration: ".github/workflows/ci.yml:94-100"
    tool_proof: "go.mod:3; actions/setup-go with go.mod"
    provenance: [CI]
  - id: darwin-release-blockers-ci
    method: integration
    scope: "Darwin release-blocker manifest"
    command: "./scripts/darwin-release-blockers.sh run"
    workdir: "."
    shell: bash
    platform: [macos]
    env: {}
    requires: [Go 1.25.10+]
    command_kind: ci
    command_declaration: ".github/workflows/ci.yml:144-153"
    tool_proof: "go.mod:3; actions/setup-go with go.mod"
    provenance: [CI]
rows:
  - id: default
    any_paths: []
    otherwise: true
    mode: standard
    evidence: [go-unit]
    source: generated
  - id: go-production
    any_paths: ["**/*.go"]
    exclude_paths: ["**/*_test.go", "e2e/**"]
    mode: standard
    evidence: [go-unit, go-build]
    source: generated
  - id: go-tests
    any_paths: ["**/*_test.go"]
    mode: standard
    evidence: [go-unit]
    source: generated
  - id: e2e-organic
    any_paths: ["e2e/organicruntime/**"]
    mode: standard
    evidence: [go-unit, organic-e2e-ci]
    source: generated
  - id: e2e-docker
    any_paths: ["e2e/**"]
    exclude_paths: ["e2e/organicruntime/**"]
    mode: standard
    evidence: [go-unit, go-e2e-docker]
    source: generated
  - id: scripts
    any_paths: ["scripts/**"]
    mode: standard
    evidence: [go-unit]
    source: generated
  - id: release
    any_paths: [".goreleaser.yaml", "scripts/release-*.sh", "scripts/verify-release-*.sh", ".github/workflows/release.yml"]
    mode: standard
    evidence: [go-unit, go-format-ci, go-vet-ci]
    source: generated
  - id: docs
    any_paths: ["docs/**", "README.md", "CONTRIBUTING.md"]
    mode: skip
    evidence: []
    source: generated
  - id: dependency
    any_paths: ["go.mod", "go.sum", "package.json", "renovate.json"]
    mode: standard
    evidence: [go-unit, go-build]
    source: generated
  - id: platform-windows
    any_paths: ["**/*_windows.go", "scripts/install.ps1", "docs/platforms.md"]
    mode: standard
    evidence: [go-unit, windows-release-blockers-ci]
    source: generated
  - id: platform-darwin
    any_paths: ["**/*_darwin.go", "scripts/darwin-release-blockers.*"]
    mode: standard
    evidence: [go-unit, darwin-release-blockers-ci]
    source: generated
  - id: generated-assets
    any_paths: ["internal/assets/**", "internal/components/**", "testdata/**"]
    mode: standard
    evidence: [go-unit, go-build]
    source: generated
compiler_checks:
  binding_context: "Every binding has method, scope, command, workdir, shell, platform, env, requires, command_kind, command_declaration, and independent tool_proof; CI-only expressions are not local commands."
  provenance: "Each binding identifies project-local docs, referenced docs, or CI; CI evidence is not relabeled as a local command."
  overlap_conflict: "Non-default rows use all matching rows, strictest mode wins (skip < standard < strict-tdd), and evidence is unioned; default applies only via otherwise."
  inventory_coverage: "Inventory covers Go behavior, tests, state/review authority, installer/sync, adapters/platforms, generated assets/golden data, E2E/release, scripts, dependencies, docs, and CI; unsupported methods are listed above."
```
