<!-- shape:block -->
## Model Assignments

Model routing for SDD/Judgment-Day phase agents is owned by `~/.pi/gentle-ai/models.json`,
which maps each phase to a concrete provider model and thinking level. That file is
authoritative. The orchestrator MUST NOT pass an explicit model alias when delegating a
phase agent: each phase inherits its model from that routing.

The table below is kept for phase intent only. The `Default Model` column is deliberately
`inherit` — this file stays host-agnostic and names no provider model.

| Phase | Default Model | Reason |
|-------|---------------|--------|
| sdd-explore | inherit | Reads code, structural - not architectural |
| sdd-propose | inherit | Architectural decisions |
| sdd-spec | inherit | Structured writing |
| sdd-design | inherit | Architecture decisions |
| sdd-tasks | inherit | Mechanical breakdown |
| sdd-apply | inherit | Implementation |
| sdd-verify | inherit | Validation against spec |
| sdd-archive | inherit | Copy and close |
| default | inherit | SDD/JD phase fallback |

If a phase is absent from `models.json`, pi applies its own default for that agent and
continues. Do not substitute a model alias here.
<!-- /shape:block -->

<!-- shape:skills-sentence -->
The orchestrator resolves skills from the registry ONCE (at session start or first delegation), caches the skill index, and passes matching `SKILL.md` paths into each sub-agent's prompt. It does NOT pass a model alias for SDD/Judgment-Day Agent calls: model routing is inherited from `~/.pi/gentle-ai/models.json`.
<!-- /shape:skills-sentence -->
