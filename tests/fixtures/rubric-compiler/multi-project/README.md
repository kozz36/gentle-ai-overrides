# Multi-Project Rubric Benchmark

This fixture scores fresh, blind producer predictions against maintainer-confirmed labels for 16 historical tasks. It does not claim precision until such predictions are supplied and scored.

## Quick Path

1. Give a producer only `tasks.tsv`.
2. Submit its TSV to `tests/rubric-compiler-multi-project-benchmark.sh --predictions FILE`.
3. Review the per-project and pooled metrics; the scorer never creates predictions.

## Recorded Run

The first persisted blind run is [predictions-v1.tsv](predictions-v1.tsv), scored in [results-v1.md](results-v1.md). It is a descriptive 8-task-per-project sample, not a general precision claim.

## Interpretation

Provisional expected labels were suggested by `openai/gpt-5.6-terra` after read-only commit inspection, then reviewed and explicitly confirmed by the maintainer. Fresh blind predictions were also produced by `openai/gpt-5.6-terra` under producer-facing inputs. Mode agreement is therefore descriptive and potentially assisted or anchored, not an independent model-versus-human ground-truth precision estimate. Evidence-set errors remain directly observable against the maintainer-confirmed labels.

## Schemas

`tasks.tsv` has task ID, project, neutral task text, sanitized provenance, commit, ISO date, and path category. `labels.tsv` is scorer-only and binds to the task fixture digest. Prediction rows are `task_id`, `predicted_mode`, `predicted_evidence`, `task_fixture_sha256`, and `producer_input`; a blank mode and evidence is an abstention.

Modes are `strict-tdd`, `standard`, `skip`, `not-applicable`, `ambiguous`, and `disputed`. Evidence must use the project vocabulary in the maintainer worksheet. Every prediction must declare the exact task-fixture SHA-256 and producer input must not name labels, oracles, semantic fixtures, benchmarks, or candidate outputs.

## Metrics

Mode precision is exact-mode TP divided by non-abstained mode predictions; recall is TP divided by eligible tasks. Evidence precision and recall use set-intersection TP, predicted-minus-expected FP, and expected-minus-predicted FN bindings. Exact task match requires both exact mode and exact evidence set. Unsupported-evidence FP rate is unsupported predicted bindings divided by predicted bindings. Abstention rate is abstained eligible tasks divided by eligible tasks. The scorer reports per-project and pooled micro metrics. Macro-by-class is N/A: 16 rows do not provide defensible class support.

Rows whose expected mode is `ambiguous`, `disputed`, or `not-applicable`, or whose label status is not `confirmed`, are excluded from metric denominators. The current labels are confirmed, while two CNSIC rows are mode-ambiguous.

## Boundary

`tasks.tsv` is the only producer-facing corpus. `labels.tsv` is read only by the scorer after a prediction file is explicitly supplied. No semantic evaluation, oracle, candidate output, or actual test result is a task source. The scorer uses temporary files only and performs no repository or HOME mutation.
