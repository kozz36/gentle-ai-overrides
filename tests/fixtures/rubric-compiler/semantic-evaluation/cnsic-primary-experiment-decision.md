---
schema: human-semantic-evaluation-decision-record/v1
subject: "CNSIC primary blind sdd-init experiment"
decision: reject
authority: maintainer
recorded_at: 2026-07-31T08:26:50Z
user_evidence: reject
evaluation_path: cnsic-primary-experiment-evaluation.md
evaluation_sha256: 4d9beea88e47729128753ac84c1a37b5c4aa42d760160d83a4ab97ac83819c50
source_head: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab
output_sha256: 6411df4b4b4ecb51f39319e58752da8bb9f5ff03937281f16baeec7eb0d7456b
manifest_sha256: c114ee522da87d2eb43f2efa981c30d2066828d5e4389c179480988ca1aaa222
---

# CNSIC Primary Blind Experiment Decision Record

This append-only record binds the maintainer decision to the immutable advisory
evaluation and the fresh blind experiment evidence.

## Decision

The maintainer decision is `reject`. The exact user evidence token is `reject`.

## Resolution Boundary

`cnsic-primary-experiment-evaluation.md` remains immutable with its
`needs-human-approval` envelope. This decision record resolves that envelope
externally; it does not alter the evaluation's findings, recommendation, or
advisory status.

## Effect

The output must not be activated or revised in place. Retain it as rejected
experiment evidence. Producer corrections require a new fresh blind run and a
new decision record.
