<!-- shape:list-item -->
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate.
   The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols,
   reject incompatible intents, then forward its one combined row and canonical-model digest without downstream
   re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched
   state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever
   been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and
   Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
<!-- /shape:list-item -->

<!-- shape:prose -->
Before classification, consume only a valid active/authoritative `RubricConsumerEnvelopeV1` from the state gate. The orchestrator is the sole resolution owner: classify declared task intent first, corroborate changed paths/symbols, reject incompatible intents, then forward its one combined row and canonical-model digest without downstream re-classification. Missing, malformed, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched state MUST block apply/verify with `RubricConsumerBlockedV1` and `recovery_action=run sdd-init recovery`; never fall back to rubric `default` or binary `strict_tdd`. Binary `strict_tdd` is permitted only when no rubric state has ever been declared or observed. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
<!-- /shape:prose -->

<!-- shape:cache-sentence -->
The orchestrator consumes validated rubric state ONCE per session (at first apply/verify launch) and caches it, classifying each apply slice by declared intent corroborated by its diff.
<!-- /shape:cache-sentence -->
