---
schema: human-semantic-evaluation-primary-experiment-output/v1
experiment: sdd-init-primary-blind
experiment_path: /home/kozz36/cnsic-agent-init-primary-experiment-20260730
source_head: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab
source_path: /home/kozz36/cnsic-agent-init-primary-experiment-20260730/openspec/config.yaml
output_sha256: 6411df4b4b4ecb51f39319e58752da8bb9f5ff03937281f16baeec7eb0d7456b
manifest_path: /home/kozz36/cnsic-agent-init-primary-experiment-20260730/.experiment-evidence/manifest.yaml
manifest_sha256: c114ee522da87d2eb43f2efa981c30d2066828d5e4389c179480988ca1aaa222
artifact_freshness: fresh-source-bound
display_kind: faithful-display-copy
---

# CNSIC Primary Blind Experiment Output

The fenced YAML below is a faithful display copy of the fresh, source-bound
experiment output. It is not activation authority, a maintainer decision, or a
replacement for the canonical reference.

```yaml
project: cnsic-agent
schema: openspec
testing:
  strict_tdd: false
  rubric:
    active:
      status: active/authoritative
      mode_order: [skip, standard, strict-tdd]
      matching: all-rows
      bindings:
        - id: backend-pytest
          method: unit
          scope: backend-python
          signature_coverage: [source, boundary/api, migration]
          command: python -m pytest tests/unit/ -x -q
          command_declaration: README.md:115-123; pytest.ini:1-9
          tool_proof: requirements.txt:62-67
        - id: backend-integration-pytest
          method: integration
          scope: backend-python
          signature_coverage: [boundary/api, migration]
          command: python -m pytest tests/integration/ -x -q
          command_declaration: README.md:115-123; .github/workflows/ci-backend.yml:76-98
          tool_proof: requirements.txt:62-67
        - id: frontend-vitest
          method: unit
          scope: frontend-vue
          signature_coverage: [ui]
          command: npm test (cwd tests/e2e/playwright)
          command_declaration: frontend/package.json:7-14; .github/workflows/ci-frontend.yml:49-53
          tool_proof: frontend/package.json:36-54; frontend/package-lock.json
        - id: frontend-eslint
          method: lint
          scope: frontend-vue
          signature_coverage: [ui]
          command: npm run lint
          command_declaration: frontend/package.json:7-14
          tool_proof: frontend/package.json:36-45; frontend/package-lock.json
        - id: frontend-build
          method: build
          scope: frontend-vue
          signature_coverage: [ui]
          command: npm run build
          command_declaration: frontend/package.json:7-10; .github/workflows/ci-frontend.yml:55-61
          tool_proof: frontend/package.json:36-54; frontend/package-lock.json
        - id: e2e-playwright
          method: e2e
          scope: browser-e2e
          signature_coverage: [boundary/api, ui]
          command: npm test
          command_declaration: tests/e2e/playwright/package.json:11-17
          tool_proof: tests/e2e/playwright/package.json:6-9; tests/e2e/playwright/package-lock.json
        - id: backend-container-build
          method: build
          scope: deploy-container
          signature_coverage: [source, boundary/api, migration]
          command: docker compose build cnsic-agent
          command_declaration: README.md:85-90; docker-compose.yml:68-79
          tool_proof: Dockerfile:7-18,24-35; docker-compose.yml:68-79
      rows:
        - signature: source
          mode: standard
          disciplines: [backend-pytest, backend-integration-pytest, backend-container-build]
          evidence: [unit, integration, build]
          source: generated
        - signature: boundary/api
          mode: standard
          disciplines: [backend-pytest, backend-integration-pytest, e2e-playwright, backend-container-build]
          evidence: [unit, integration, e2e, build]
          source: generated
        - signature: ui
          mode: standard
          disciplines: [frontend-vitest, frontend-eslint, frontend-build, e2e-playwright]
          evidence: [unit, lint, build, e2e]
          source: generated
        - signature: migration
          mode: standard
          disciplines: [backend-pytest, backend-integration-pytest, backend-container-build]
          evidence: [unit, integration, build]
          source: generated
        - signature: docs
          mode: skip
          disciplines: []
          evidence: []
          source: generated
        - signature: default
          mode: standard
          disciplines: [backend-pytest]
          evidence: [unit]
          source: generated
project_context:
  stack: Python 3.13/FastAPI backend, SQLite via aiosqlite, Vue 3/PrimeVue/Tailwind frontend, Docker Compose, WAHA, Ollama, telecom-vision
  architecture: Adapter/service/database layering with an agent core; Vue SPA served by FastAPI; external services compose-managed
  conventions: README governs release/testing discipline; pytest markers include slow; secrets and runtime data remain ignored
  unsatisfied:
    - method: coverage
      reason: no declared coverage command and no pytest-cov dependency/provider in tracked evidence
    - method: typecheck
      scope: frontend-vue
      reason: TypeScript is present but no typecheck command or vue-tsc provider is declared
    - method: format
      scope: frontend-vue
      reason: Prettier is present but no format command is declared
    - method: lint
      scope: backend-python
      reason: no backend lint command and reproducible linter provider are declared
  policy_questions:
    - Whether docs-only changes should remain skip or require a documentation review/checklist.
    - Whether backend smoke import should be a separate build or integration binding for boundary changes.
    - Whether the browser Playwright suite is intended for all UI changes or only selected flows.
```
