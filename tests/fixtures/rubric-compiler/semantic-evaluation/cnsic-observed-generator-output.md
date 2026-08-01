---
schema: human-semantic-evaluation-observed-output/v1
subject: "CNSIC observed generator output"
source_path: /home/kozz36/cnsic-agent-init-validation/openspec/config.yaml
repository_head: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab
source_sha256: 5f510a8f37d388e08c73f95cac2f2d2d3a9067e42e4e1afefa1283efad566c13
artifact_freshness: stale-unbound
display_kind: faithful-display-copy
---

# CNSIC Observed Generator Output

The fenced YAML below is a faithful display copy of the source bytes bound
above. It is not activation authority, a fresh generation receipt, or a
maintainer decision.

```yaml
schema: spec-driven

context: |
  Stack: Python FastAPI backend with pytest/pytest-asyncio; Vue 3/Vite frontend with Vitest and ESLint.
  Architecture: modular backend (adapters, services, db, agent) plus Vue SPA served at /app/.
  Build/runtime: Docker Compose; frontend build uses Node 22.22.3 and Vite.
  Conventions: AGENTS.md and CLAUDE.md; backend tests use disposable SQLite fixtures and frontend UI uses Playwright evidence.
  Persistence: OpenSpec artifacts only.

strict_tdd: false
testing:
  policy: rubric
  rubric:
    active: true
    authoritative: true
    mode_order: [skip, standard, strict-tdd]
    resolution:
      matching: all-rows
      mode: strictest-wins
      evidence: union
    bindings:
      - id: backend-unit
        method: unit
        scope: backend production Python and backend tests
        command: python -m pytest tests/unit/ -n auto -q
        command_declaration: AGENTS.md:18,62
        tool_proof: requirements.txt:62-66 (pytest, pytest-asyncio, pytest-xdist)
      - id: backend-integration
        method: integration
        scope: backend integration tests and cross-layer Python changes
        command: python -m pytest tests/ -n auto -q
        command_declaration: pytest.ini:3 and AGENTS.md:18,24
        tool_proof: requirements.txt:62-67 (pytest, pytest-asyncio, asgi-lifespan)
      - id: frontend-unit
        method: unit
        scope: frontend source and component tests
        command: cd frontend && npm test
        command_declaration: frontend/package.json:12
        tool_proof: frontend/package-lock.json and frontend/package.json:54 (vitest)
      - id: frontend-lint
        method: lint
        scope: frontend source
        command: cd frontend && npm run lint
        command_declaration: frontend/package.json:11
        tool_proof: frontend/package-lock.json and frontend/package.json:43 (eslint)
      - id: frontend-build
        method: build
        scope: frontend source and frontend production assets
        command: cd frontend && npm run build
        command_declaration: frontend/package.json:9
        tool_proof: frontend/package-lock.json and frontend/package.json:53 (vite)
      - id: frontend-e2e
        method: e2e
        scope: browser-visible frontend and cross-layer UI changes
        command: cd tests/e2e/playwright && npm test
        command_declaration: tests/e2e/playwright/package.json:13
        tool_proof: tests/e2e/playwright/package-lock.json and package.json:7 (@playwright/test)
      - id: container-build
        method: build
        scope: Dockerfile, docker-compose.yml, backend runtime image, and production wiring
        command: docker compose build cnsic-agent
        command_declaration: AGENTS.md:17 and docker-compose.yml:68-80
        tool_proof: Dockerfile and docker-compose.yml:69-79 (pinned build context and named submodule context)
    rows:
      - signature: backend-source
        mode: standard
        disciplines: [unit]
        evidence_bindings: [backend-unit]
        source: generated
      - signature: boundary-api
        mode: strict-tdd
        disciplines: [unit, integration]
        evidence_bindings: [backend-unit, backend-integration]
        source: generated
      - signature: ui-visible
        mode: strict-tdd
        disciplines: [unit, lint, build, e2e]
        evidence_bindings: [frontend-unit, frontend-lint, frontend-build, frontend-e2e]
        source: generated
      - signature: migration
        mode: strict-tdd
        disciplines: [unit, integration, build]
        evidence_bindings: [backend-unit, backend-integration, container-build]
        source: generated
      - signature: docs
        mode: skip
        disciplines: []
        evidence_bindings: []
        source: generated
      - signature: default
        mode: standard
        disciplines: []
        evidence_bindings: []
        source: generated
    default:
      mode: standard
      source: generated
  detected_but_unsatisfied:
    - method: coverage
      reason: no declared coverage command or reproducible coverage provider
    - method: typecheck
      reason: no declared typecheck command
    - method: format
      reason: Prettier is present as a dependency, but no declared format command exists

rules:
  proposal:
    - Include rollback plan for risky changes.
  specs:
    - Use Given/When/Then scenarios and RFC 2119 keywords.
  design:
    - Document architecture decisions with rationale.
  tasks:
    - Group tasks by phase and keep them completable in one session.
  apply:
    guidelines:
      - Follow AGENTS.md and CLAUDE.md project conventions.
    tdd: rubric
  verify:
    test_command: python -m pytest tests/unit/ -n auto -q
    build_command: cd frontend && npm run build
  archive:
    - Warn before merging destructive deltas.
```
