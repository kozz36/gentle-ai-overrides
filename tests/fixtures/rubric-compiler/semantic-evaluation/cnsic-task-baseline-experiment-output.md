---
schema: human-semantic-evaluation-task-baseline-output/v1
experiment_path: /home/kozz36/cnsic-agent-init-primary-experiment-v4-20260731
source_commit: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab
candidate_path: .experiment-evidence/candidate-ir.json
candidate_sha256: af00ca093c2e49c6ec05c3fea20a0efffcfbc294dcb59d3e1a4c1527c8691a6f
result_path: .experiment-evidence/result.md
result_sha256: a8ee263b7cd85548c82462d8979786f6cf61ddb940c790d4d18db77bd662269c
manifest_sha256: fa57e0962dabae5897af0bd2ffccf852f21c6be315d4d22268b9d96143c7b63c
manifest_companion_sha256: 2ba5520823981fbf24665453d889c30434cef611bd9fa71c1b0eb4368bca5ff3
reference_body_sha256: bdde1d2d2c3d8e264946af2e5cc2f0635e16a9aa3de461f95ab9d68a6074f152
artifact_freshness: fresh-source-bound
---

# CNSIC Task-Intent Baseline Candidate Projection

The candidate/result projection is pending and has no activation authority. The
complete source files are bound above and verified by the manifest companion.

| Candidate property | Faithful projection |
| --- | --- |
| Status and baseline | `pending`; `task-intent-policy-baseline/v1`; all-rows; skip < standard < strict-tdd |
| Bindings | `b-unit`, `b-smoke`, `b-fe-unit`, `b-fe-build`, `b-fe-lint`, `b-changelog` |
| Visible rows | 13: strict new behavior/bug/security/migration/UI behavior; standard refactor/UI-style/port/prompt/config/script/dependency; one docs skip |
| Default | separate unmatched-only `standard`, no borrowed binding |
| Result projection | 13 visible rows; all simulation cases resolve intent-first; activation/readback forbidden and compiler pending |
