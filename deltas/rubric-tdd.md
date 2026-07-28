<!-- shape:list-item -->
4. **Additional condition — per-work-type rubric (project-generated, this file stays project-agnostic).**
   Only consume an active/authoritative rubric; otherwise preserve binary `strict_tdd` behavior. Classify the
   change against ALL matching non-default rows, resolve the effective MODE by `skip < standard < strict-tdd`, union
   their evidence/discipline requirements, and forward one effective combined instruction to the sub-agent. `default`
   is selected ONLY when no non-default signature matches; it does not join a specific-row union. The rubric is
   project-generated; do NOT hardcode signatures or thresholds here.
<!-- /shape:list-item -->

<!-- shape:prose -->
Only consume an active/authoritative rubric; otherwise preserve binary `strict_tdd` behavior. Classify the change against ALL matching non-default rows, resolve the effective MODE by `skip < standard < strict-tdd`, union their evidence/discipline requirements, and forward one effective combined instruction to the sub-agent. `default` is selected ONLY when no non-default signature matches; it does not join a specific-row union. The rubric is project-generated; do NOT hardcode signatures or thresholds here.
<!-- /shape:prose -->

<!-- shape:cache-sentence -->
The orchestrator resolves the rubric + `strict_tdd` ONCE per session (at first apply/verify launch) and caches it, re-classifying each apply slice by its diff signature.
<!-- /shape:cache-sentence -->
