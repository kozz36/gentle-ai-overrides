<!-- shape:list-item -->
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   For each `sdd-apply` or `sdd-verify` work slice, read the canonical `sdd-init` authoritative policy directly for the active artifact store.
   The orchestrator caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules.
   Corroborate changed paths/symbols only where that policy declares them relevant, and stop for clarification when declared intent conflicts with that evidence.
   Select `default` ONLY when no non-default row matches; otherwise apply strictest MODE precedence and union only applicable non-default rows' obligations.
   Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths without substituting downstream matching rules or policy rewriting.
   Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy. Producer and activation semantics remain owned by `sdd-init`.
   Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification; do not fabricate runtime recovery dispatch.
   Binary `strict_tdd` fallback is permitted ONLY when no rubric exists. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
<!-- /shape:list-item -->

<!-- shape:prose -->
For each `sdd-apply` or `sdd-verify` work slice, read the canonical `sdd-init` authoritative policy directly for the active artifact store. The orchestrator caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; corroborate changed paths/symbols only where that policy declares them relevant, and stop for clarification when declared intent conflicts with that evidence. Select `default` ONLY when no non-default row matches; otherwise apply strictest MODE precedence and union only applicable non-default rows' obligations. Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths without substituting downstream matching rules or policy rewriting. Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy. Producer and activation semantics remain owned by `sdd-init`. Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification; do not fabricate runtime recovery dispatch. Binary `strict_tdd` fallback is permitted ONLY when no rubric exists. Managed forwarding surfaces are Claude Code lazy prose; Pi, Cursor, VS Code Copilot, Gemini CLI, and Antigravity lists; and OpenCode JSON. Codex is `rubric-none`; Kimi is explicitly current-scope unmanaged.
<!-- /shape:prose -->

<!-- shape:cache-sentence -->
The orchestrator reads the canonical `sdd-init` authoritative policy directly from the active artifact store and caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; producer and activation semantics remain owned by `sdd-init`.
<!-- /shape:cache-sentence -->

<!-- shape:pi-workflow -->
<!-- gentle-ai:pi-rubric-forwarding -->
### Project TDD Rubric Forwarding

Compatibility is verified with official Gentle AI 2.6.0 with `gentle-pi@2.4.0`. Pi preservation boundary: this forwarding block owns only this package workflow; APPEND_SYSTEM.md remains installer-managed and untouched. Do not read, transform, back up, or write it.

For each actual `sdd-apply` or `sdd-verify` work slice, read the canonical `sdd-init` authoritative policy directly for the active artifact store. The orchestrator caches the canonical policy ONCE per session, but must resolve every distinct apply/verify work slice AFRESH using its own declared task intent and the policy-defined matching rules; corroborate changed paths or symbols only where that policy declares them relevant, and stop for clarification when declared intent conflicts with that evidence. OpenSpec reads only `openspec/config.yaml` `testing.rubric.active: true`; Engram reads only the canonical `sdd-init/{project}` policy artifact carrying `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` and `Status: active/authoritative.`; hybrid requires semantically equivalent active/authoritative policy in its configured stores.

Select `default` ONLY when no non-default row matches; otherwise apply strictest MODE precedence and union only applicable non-default rows' obligations. Forward the effective MODE and the policy's exact declared commands, disciplines/evidence, and skill paths to every `sdd-apply` and `sdd-verify` launch without substituting downstream matching rules or policy rewriting. Consumer-envelope or compiler diagnostics MUST NOT supersede a valid canonical policy. Producer and activation semantics remain owned by `sdd-init`. Missing, ambiguous, or conflicting canonical policy MUST stop apply/verify for human clarification; do not fabricate runtime recovery dispatch. Binary `strict_tdd` fallback is permitted ONLY when no rubric exists.

When the effective MODE is `strict-tdd`, include `STRICT TDD MODE IS ACTIVE. Follow RED, GREEN, TRIANGULATE, REFACTOR. Record evidence.` with the policy's forwarded obligations.

The orchestrator is read-only: never author, generate, mutate, broaden, infer, alter, or rewrite the authoritative policy's rows, commands, bindings, or evidence. It may mechanically match existing policy rows using only those declared rules and must never invent commands or evidence.
<!-- /gentle-ai:pi-rubric-forwarding -->
<!-- /shape:pi-workflow -->
