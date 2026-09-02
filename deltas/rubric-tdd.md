<!-- shape:list-item -->
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate.
   The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols,
   reject incompatible intents, then forward its one combined row and canonical-model digest without downstream
   re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched
   state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever
   been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and
   Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
<!-- /shape:list-item -->

<!-- shape:prose -->
Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate. The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /gentle-sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
<!-- /shape:prose -->

<!-- shape:cache-sentence -->
The orchestrator consumes validated rubric state ONCE per session (at first apply/verify launch) and caches it, classifying each apply slice by declared intent corroborated by its diff.
<!-- /shape:cache-sentence -->

<!-- shape:pi-workflow -->
<!-- gentle-ai:pi-rubric-forwarding -->
### Project TDD Rubric Forwarding

For each actual `sdd-apply` or `sdd-verify` work slice, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate. Its project-generated policy must come from the canonical `sdd-init` context for the active artifact store: OpenSpec reads only `openspec/config.yaml` `testing.rubric.active: true`; Engram reads only the canonical `sdd-init/{project}` policy artifact carrying `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` and `Status: active/authoritative.`; hybrid requires semantically equivalent active/authoritative policy in its configured stores.

The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths or symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run /gentle-sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever been declared or observed.

Forward the envelope's one effective combined instruction to every `sdd-apply` and `sdd-verify` launch. When its effective MODE is `strict-tdd`, include `STRICT TDD MODE IS ACTIVE. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.` in that same combined instruction.

The orchestrator is read-only: never generate, mutate, broaden, infer, or select rubric rows, commands, bindings, or evidence. It only resolves and forwards the authoritative policy.
<!-- /gentle-ai:pi-rubric-forwarding -->
<!-- /shape:pi-workflow -->
