---
schema: human-semantic-evaluation-reference/v1
project: cnsic-agent
source_observation: "#3351"
supersedes_observation: "#305"
captured_date: 2026-07-30
reference_kind: faithful-behavioral-snapshot
reference_body_sha256: d59aae4225db04fc2ac2932e4981faff09cad5f75a1fac83ddb14db14504150e
---

# CNSIC Canonical Init Reference

This is a faithful behavioral snapshot of the known-good CNSIC init recorded in
Engram observation #3351. It preserves the supplied behavioral content, but is
not claimed to be byte-identical to the complete original observation prose.

<!-- canonical-reference:start -->
# sdd-init/cnsic-agent — project context + testing capabilities

Canonical/default-loaded init (supersedes stale #305). SDD-mature project. TDD is RUBRIC-DRIVEN. The orchestrator MUST read the rubric, classify each apply slice by diff signature, and forward the matching MODE. Strict TDD means the full SAFETY NET → RED → GREEN → TRIANGULATE → REFACTOR cycle from `~/.claude/skills/sdd-apply/strict-tdd.md`, including path injection and TDD Cycle Evidence. The legacy `strict_tdd` binary is subordinate while the rubric exists.

Stack: Python 3.13, FastAPI, hexagonal adapters/ports/services/db/agent/llm; Vue 3 SPA; SQLite WAL; Docker Compose.

Test command: `bash scripts/run_tests.sh tests/unit/ -q` using Docker mutex, `-n 6`, and `CNSIC_AUTH_ENABLED=false`. Mounted paths: tests/, db/queries/, agent/ports/, scripts/, services/, utils/, adapters/api/. Changes to agent/core.py, agent/pipelines/, config.py, db root, or llm/ require `docker compose build` first. Windows twin: `pwsh scripts/run_tests.ps1`.

Smoke: `docker compose run --rm --no-deps --build cnsic-agent python -c "from main import create_app; create_app()"`; `--build` mandatory.

Capabilities: pytest unit, httpx/TestClient integration, Playwright frontend E2E, pytest-cov coverage, Vitest frontend.

## TDD RUBRIC
Resolution:
1. Match every row whose signature triggers.
2. Forward resulting mode and disciplines. If test-first, inject strict-tdd.md and require the complete cycle/evidence.
3. Strict-TDD wins if any matching row triggers. Pure frontend/src diff uses Playwright SA-5. Otherwise choose the lowest-rigor matched row. Code beats docs/infra. SD-1 Judgment Day fires whenever a matching row requires it.

Rows:
- New endpoint or new domain function in services/agent/llm implementing behavior → Strict TDD; add smoke for adapters/api or main.py.
- Bug fix → Strict TDD with reproducing test first.
- db/schema/migrations/** → Strict TDD; Migration Twin + smoke --build; ordering inversion or completeness; Judgment Day for non-append.
- db/rbac_catalog_v50.py or require_capability → Strict TDD; backend/frontend 200/403 + Twin; frozen-set no-access; update telecom-rbac-matrix.
- New cross-bounded-context SELECT/JOIN in services or db/queries → Strict TDD with real dataclasses; Judgment Day on first new sanctioned read.
- agent/tools/** → Strict TDD with real-SQL boundary; Judgment Day mandatory.
- Egress chokepoint semantic change → Strict TDD; Judgment Day mandatory, excluding parameter tuning.
- LLM/Runner/transport wired to existing port → acceptance test with self-regression and resolution; Judgment Day mandatory.
- frontend/src/** → Playwright SA-5, not unit TDD; npm test + committed spec + FINDINGS PASS; partial until evidence.
- Behavior-preserving refactor → regression + test migration/approval tests, not test-first; build first if unmounted.
- prompt or work_phases.py → telecom-field-ops validation; characterization only for logic branches.
- config.py → smoke --build, no new test.
- Infra Docker/env files → smoke --build, no pytest.
- scripts/** → no pytest unless dedicated tests.
- docs/CHANGELOG/runbooks → skip test gate.
- Dependency bump → full suite, no new test.

Universal all-mode disciplines: TS-1..8, SA-1..8, SD-1..5. RBAC endpoints require capability + Twin. Chokepoints are adapters/whatsapp/outbound.py::send and llm/tool_exec/_dispatch.py::execute_tool.

Persistence: hybrid OpenSpec + Engram. Archive uses committed git mv under openspec/changes/archive. Skill registry: `.atl/skill-registry.md`.

Anti-godfile thresholds (soft/hard): services 300/500; db/queries 400/700; router 250/400; outbound 400/800; Vue view 400/800; agent flow 300/600; port/util 150/300; test 800/1500; migration tuple 100/300.
<!-- canonical-reference:end -->
