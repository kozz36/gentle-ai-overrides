# Human Semantic Evaluation Schema

This package records advisory semantic evaluations of observed rubric-generator
artifacts. It is not a scorer and cannot grant approval.

## Report Envelope

Every report starts with this YAML front matter:

```yaml
schema: human-semantic-evaluation/v1
subject: <evaluated generator output>
status: needs-human-approval
recommendation: approve | revise | reject
confidence: low | medium | high
```

Every report contains these sections in this order:

1. `Source Bindings`
2. `Evaluation Dimensions`
3. `Similarities`
4. `Differences`
5. `Behavioral Impact`
6. `Unsupported Or Missing Claims`
7. `Recommendation`
8. `Maintainer Decision`

`Source Bindings` identifies every evaluated artifact and evidence source with
its read-only path, repository revision where available, and SHA-256 digest.
An unbound artifact has no reproducible generation receipt or invocation and
must be labelled `stale-unbound`, not treated as fresh output.

## Evaluation Dimensions

The evaluator records evidence and uncertainty for:

| Dimension | Question |
| --- | --- |
| Stack/capability detection | Does the output recognize the relevant stack and runnable capabilities? |
| Implementation mode fidelity | Does each work type select `skip`, `standard`, or `strict-tdd` at the intended implementation rigor? |
| Test-authoring discipline/forwarding fidelity | When a row selects `strict-tdd`, does the active orchestrator contract forward that token to the test-first workflow rather than requiring duplicated prose in every row? |
| Functional validation evidence | Do unit, integration, build, smoke, typecheck, and other non-visual requirements apply to the relevant work types? |
| Visual/E2E validation evidence | Do observable visual behaviors receive Playwright/E2E evidence where unit tests are insufficient, independently of implementation mode? |
| Command/harness fidelity | Does each selected validation requirement preserve required wrappers, environment, platform, and build constraints? |
| Work-type coverage | Are project-specific work types represented without unsafe overgeneralization? |
| Multi-match resolution | Are overlapping rows, default selection, and precedence stated coherently? |
| Coverage and other evidence | Are declared coverage and other non-test evidence requirements preserved or explicitly justified as unsupported? |
| Fail-closed uncertainty | Are unsupported or ambiguous states surfaced instead of inferred? |
| Orchestrator forwarding behavior | Can the orchestrator forward an actionable rule without inventing policy? |
| Project-specific policy gaps | What local/manual rules still require a maintained seed or human decision? |

`strict-tdd` is an implementation/test-authoring workflow mode. `standard` can
still require selected evidence without test-first ordering. `skip` has no
automated gate unless another matching row unions evidence. Disciplines and
evidence bindings are separate validation requirements unioned across matching
rows. Playwright/E2E is validation evidence for observable behavior; it does
not set implementation mode or imply/rewrite `strict-tdd`.

The dimensions are an inference aid. Deterministic validation cannot validate semantic quality, correctness, completeness, or recommendation quality.

## Human Decision Envelope

The evaluator may recommend `approve`, `revise`, or `reject`. This is advisory.
The report always remains in the following envelope until a maintainer records a
decision outside this package:

```yaml
status: needs-human-approval
recommendation: <advisory value>
maintainer_decision: pending
decision_authority: maintainer
allowed_maintainer_actions: [approve, revise, reject]
```

An orchestrator must present the recommendation, confidence, evidence summary,
and the three maintainer actions. It must not convert a recommendation into a
decision, mutate repository policy, or continue as though approval occurred.

## Decision Record Transition

An advisory evaluation is immutable after review. A maintainer decision is
recorded separately in an append-only, source-bound decision record with the
following fields:

```yaml
schema: human-semantic-evaluation-decision-record/v1
decision: approve | revise | reject
authority: maintainer
recorded_at: <UTC timestamp>
user_evidence: <exact maintainer answer token>
evaluation_path: <immutable evaluation path>
evaluation_sha256: <pre-record SHA-256>
source_head: <evaluated source HEAD>
output_sha256: <evaluated output SHA-256>
manifest_sha256: <evaluated manifest SHA-256>
```

The decision record resolves the evaluation's `needs-human-approval` envelope
externally without rewriting the evaluation's advisory status, findings, or
recommendation. A `reject` decision prohibits activation and in-place revision;
retain the output as rejected evidence. Any producer correction requires a new
fresh blind run and a new decision record.
