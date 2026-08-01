# Blind Prediction Run V1

This is the first persisted blind run. It records the supplied raw predictions without altering labels or predictions to improve metrics.

## Source Bindings

| Input | SHA-256 |
|---|---|
| [tasks.tsv](tasks.tsv) | `2a08207c4a0bb299c702bba453326c9d4ca7beeee6ff20ef8a635f5e759d920b` |
| [predictions-v1.tsv](predictions-v1.tsv) | `2c1cd4c8f1611e5099ad8171432faf524fab8b3609e9e5a35275765ecea4e0fa` |
| [producer-cnsic-v1.tsv](producer-cnsic-v1.tsv) | `75ad2fc3dc1b956d16ccfe1e913063da1f5ae91946a9d42d492b30de906071ff` |
| [producer-gentle-v1.tsv](producer-gentle-v1.tsv) | `76674cb10cfceda29e99adf47f8604cb48c160f3522fcb3a4d850ecd0a3bedbd` |
| [labels.tsv](labels.tsv) | `cc80a990e18f0e41bc5610d3a0a49822bc99cf4603e0cf3c3e8710cfd37afa4a` |

Model: `openai/gpt-5.6-terra`.

Immutable project sources: CNSIC `repo-2703650a` with the task fixture's read-only historical commits; Gentle AI `repo-ffbcc12f` with the task fixture's public historical commits. The initial Gentle all-abstention output was an access failure from missing local historical objects and was neither persisted nor scored. This corrected Gentle run used read-only exact public commit API responses, recorded as `api-exact-commits` in `producer_input`.

`predictions-v1.tsv` is the ordered union of the two producer files under one header.

## Interpretation Limits

Provisional expected labels were suggested by `openai/gpt-5.6-terra` after read-only commit inspection, then reviewed and explicitly confirmed by the maintainer. Fresh blind predictions were also produced by `openai/gpt-5.6-terra` under blind producer inputs. Mode agreement is therefore descriptive and potentially assisted or anchored, not an independent model-versus-human ground-truth precision estimate. Evidence-set errors remain directly observable against the maintainer-confirmed labels.

## Scorer Output

```text
project: cnsic
  mode precision: 100.00% (6/6)
  mode recall: 100.00% (6/6)
  evidence precision: 100.00% (9/9)
  evidence recall: 81.82% (9/11)
  exact task match: 66.67% (4/6)
  unsupported-evidence FP rate: 0.00% (0/9)
  abstention rate: 0.00% (0/6)
  evidence-overlap tasks: 6
project: gentle
  mode precision: 100.00% (8/8)
  mode recall: 100.00% (8/8)
  evidence precision: 48.28% (14/29)
  evidence recall: 100.00% (14/14)
  exact task match: 0.00% (0/8)
  unsupported-evidence FP rate: 51.72% (15/29)
  abstention rate: 0.00% (0/8)
  evidence-overlap tasks: 7
project: pooled
  mode precision: 100.00% (14/14)
  mode recall: 100.00% (14/14)
  evidence precision: 60.53% (23/38)
  evidence recall: 92.00% (23/25)
  exact task match: 28.57% (4/14)
  unsupported-evidence FP rate: 39.47% (15/38)
  abstention rate: 0.00% (0/14)
  evidence-overlap tasks: 13
macro-by-class: N/A (insufficient defensible class support)
```

Metric definitions are in [README.md#metrics](README.md#metrics). This is one run with eight tasks per project and 14 eligible tasks after two ambiguous CNSIC rows are excluded; it is descriptive only and supports no general precision claim.
