---
schema: human-semantic-evaluation-enriched-experiment-output/v1
experiment_path: /home/kozz36/cnsic-agent-init-primary-experiment-v2-20260731
source_head: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab
source_path: /home/kozz36/cnsic-agent-init-primary-experiment-v2-20260731/openspec/config.yaml
output_sha256: a072e4e8a7e817b099db9c6b186c6baf6bb6d12126c58f75abf38e6e05cb7b68
manifest_path: /home/kozz36/cnsic-agent-init-primary-experiment-v2-20260731/.experiment-evidence/manifest.txt
manifest_sha256: 16bd112257f1a330c281d2860c29422a352d112317a61f4804c0db422bbfa83a
reference_body_sha256: 06eb642b8f5d1a2789426ca19e96060881793b1d4e401bf5ff542ba622c45313
artifact_freshness: fresh-source-bound
display_kind: faithful-display-copy
---

# CNSIC Enriched Blind Experiment Output

This is a complete faithful display copy of the enriched blind experiment's
source output. It is experiment evidence, not activation authority.

```yaml
project: cnsic-agent
schema: sdd-init/v3
strict_tdd: false
testing:
  methods:
    - method: unit
      scope: backend
      signature_coverage: "**/*.py, tests/unit/**"
      command: "python -m pytest tests/unit/ -n 12 -q --basetemp /tmp/ci-pytest-backend"
      command_declaration: ".github/workflows/ci-backend.yml:76-98"
      tool_proof: "requirements.txt:62-67 (pytest, pytest-asyncio, pytest-xdist); .github/workflows/ci-backend.yml:71-74 installs requirements"
    - method: unit
      scope: frontend
      signature_coverage: "frontend/**"
      command: "npm test"
      command_declaration: ".github/workflows/ci-frontend.yml:49-53; frontend/package.json:12"
      tool_proof: "frontend/package.json:36-54 and frontend/package-lock.json (vitest, Vue test utilities)"
    - method: integration
      scope: backend integration
      signature_coverage: "tests/integration/**, agent and API flows"
      command: "python -m pytest tests/integration/agent/ -q --basetemp /tmp/ci-pytest-integration"
      command_declaration: ".github/workflows/full-integration.yml:51-55"
      tool_proof: "requirements.txt:62-67; .github/workflows/full-integration.yml:30-38"
    - method: integration
      scope: assistant endpoint
      signature_coverage: "assistant endpoint transport/runner changes"
      command: "python -m pytest tests/integration/test_assistant_endpoint_mock.py tests/integration/test_assistant_endpoint_runner.py -q --basetemp /tmp/ci-pytest-integration"
      command_declaration: ".github/workflows/full-integration.yml:57-62"
      tool_proof: "requirements.txt:62-67; .github/workflows/full-integration.yml:30-38"
    - method: e2e
      scope: frontend visible journeys
      signature_coverage: "frontend UI and cross-layer browser journeys"
      command: "npx playwright test"
      command_declaration: "tests/e2e/playwright/package.json:12-17; docs/CONTRIBUTING.md:288-297"
      tool_proof: "tests/e2e/playwright/package.json:6-10 and package-lock.json (@playwright/test, TypeScript)"
    - method: lint
      scope: frontend
      signature_coverage: "frontend/**"
      command: "npm run lint"
      command_declaration: "frontend/package.json:11"
      tool_proof: "frontend/package.json:36-45 and frontend/package-lock.json (eslint, eslint-plugin-vue)"
    - method: build
      scope: frontend
      signature_coverage: "frontend/**, Dockerfile frontend-builder stage"
      command: "npm run build"
      command_declaration: "frontend/package.json:9; .github/workflows/ci-frontend.yml:55-60"
      tool_proof: "frontend/package.json:36-54 (Vite/plugin Vue); .github/workflows/ci-frontend.yml:36-49 (Node 22.22.3 + npm ci)"
    - method: build
      scope: backend application wiring
      signature_coverage: "**/*.py, requirements.txt, Dockerfile"
      command: "python -c \"from main import create_app; app = create_app(); print(f'SMOKE_OK routes={len(app.routes)}')\""
      command_declaration: ".github/workflows/ci-backend.yml:104-132"
      tool_proof: "requirements.txt:1-67; .github/workflows/ci-backend.yml:121-124 installs requirements; setup-python 3.13:112-115"
  rubric:
    active:
      status: active/authoritative
      mode_order: [skip, standard, strict-tdd]
      matching: all-rows
      bindings: [unit-backend, unit-frontend, integration-agent, integration-assistant-endpoint, e2e-frontend, lint-frontend, build-frontend, build-backend]
      rows:
        - signature: "db/schema/migrations/** or db/schema.py migration registry"
          mode: strict-tdd
          disciplines: [unit, integration, build]
          source: generated
        - signature: "adapters/**, services/**, agent/**, llm/**, db/** Python behavior or API boundary changes"
          mode: strict-tdd
          disciplines: [unit, build]
          source: generated
        - signature: "authentication, authorization, secrets, state transitions, persistence, or audit behavior"
          mode: strict-tdd
          disciplines: [unit, integration, build]
          source: generated
        - signature: "frontend/** user-visible behavior, accessibility, client state, or UI"
          mode: strict-tdd
          disciplines: [unit, lint, build, e2e]
          source: generated
        - signature: "cross-layer assistant, transport, or integration boundary"
          mode: strict-tdd
          disciplines: [unit, integration, e2e, build]
          source: generated
        - signature: "behavior-preserving refactor of executable code"
          mode: strict-tdd
          disciplines: [unit, build]
          source: generated
        - signature: "docs/**, *.md, CHANGELOG.md, LICENSE"
          mode: skip
          disciplines: []
          source: generated
        - signature: "scripts/** utility/wrapper changes without dedicated tests"
          mode: skip
          disciplines: []
          source: generated
        - signature: "dependency-only, configuration-only, Docker/operations-only, prompt-only, or project-skill-only diffs"
          mode: skip
          disciplines: []
          source: generated
      default:
        mode: skip
        disciplines: []
        source: generated
        selection: unmatched-only
 status: active-authoritative
selection:
  maintainer: rubric
  active_policy_persisted: true
  reason: "The grouped skip answer and the unmatched-only default skip answer were each consumed exactly once; all active rows have closed modes."
```
