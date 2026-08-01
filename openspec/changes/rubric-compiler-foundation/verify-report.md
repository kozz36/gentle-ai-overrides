```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:c89bacf9c82025d29551f01cadab0c08608a7dd7ad9dfd0398afc6c2af339c20
verdict: fail
blockers: 1
critical_findings: 1
requirements: 0/9
scenarios: 0/17
test_command: "bash tests/rubric-compiler-structure.sh && bash tests/rubric-compiler-adapter-records.sh && bash tests/rubric-compiler-adapter-gate.sh && bash tests/rubric-compiler-activation.sh && bash tests/rubric-consumer-gate.sh && bash tests/rubric-compiler-benchmark.sh && bash tests/init-rubric-contract.sh && bash tests/run.sh"
test_exit_code: 125
test_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
build_command: "shellcheck --severity=warning apply.sh tests/run.sh tests/rubric-compiler-structure.sh tests/rubric-compiler-adapter-records.sh tests/rubric-compiler-adapter-gate.sh tests/rubric-compiler-activation.sh tests/rubric-consumer-gate.sh tests/rubric-compiler-benchmark.sh && bash -n apply.sh tests/run.sh tests/rubric-compiler-structure.sh tests/rubric-compiler-adapter-records.sh tests/rubric-compiler-adapter-gate.sh tests/rubric-compiler-activation.sh tests/rubric-consumer-gate.sh tests/rubric-compiler-benchmark.sh && git diff --check"
build_exit_code: 125
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
authority_only_failure: true
missing_review_authority: true
substantive_failure: false
command_failed: false
observed_authority_revision: sha256:15ccb6b54cbab90b74a5da9f0935791351df567d3870671041bd7743293604ed
```

## Verification Report

**Change**: rubric-compiler-foundation  
**Mode**: Standard (strict TDD inactive; no strict-TDD module loaded)  
**Scope**: Full artifacts retrieved; HYBRID planning store checked.  
**Authority state**: FAIL — native preflight denied independent runtime verification before command execution.

### Authoritative Preflight

- `gentle-ai sdd-attempt status --cwd /home/kozz36/gentle-ai-overrides --change rubric-compiler-foundation` reported ordinal 3 active at `sha256:15ccb6b54cbab90b74a5da9f0935791351df567d3870671041bd7743293604ed` for `final-requirements-runtime-verification`.
- `gentle-ai sdd-status rubric-compiler-foundation` reported `verify: blocked`: an explicit bounded `review/start(target)` transaction is missing.
- `gentle-ai review status --cwd /home/kozz36/gentle-ai-overrides` was authoritative and clean with `entries: []`.
- This is an authority-only preflight denial. The declared test and build commands were deliberately not executed; exit `125` and the SHA-256 of exact empty output are protocol values, not command failures.

### Completeness

| Metric | Value |
|---|---:|
| Tasks total | 9 |
| Tasks complete | 9 |
| Tasks incomplete | 0 |
| Requirements inspected | 9 |
| Scenarios inspected | 17 |
| Runtime-compliant requirements | 0/9 |
| Runtime-compliant scenarios | 0/17 |

### Build, Tests, and Coverage

| Check | Command | Exit | Output hash | Result |
|---|---|---:|---|---|
| Tests | `bash tests/rubric-compiler-structure.sh && bash tests/rubric-compiler-adapter-records.sh && bash tests/rubric-compiler-adapter-gate.sh && bash tests/rubric-compiler-activation.sh && bash tests/rubric-consumer-gate.sh && bash tests/rubric-compiler-benchmark.sh && bash tests/init-rubric-contract.sh && bash tests/run.sh` | 125 | `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | Not executed: authority-only denial |
| Build/static | `shellcheck --severity=warning apply.sh tests/run.sh tests/rubric-compiler-structure.sh tests/rubric-compiler-adapter-records.sh tests/rubric-compiler-adapter-gate.sh tests/rubric-compiler-activation.sh tests/rubric-consumer-gate.sh tests/rubric-compiler-benchmark.sh && bash -n apply.sh tests/run.sh tests/rubric-compiler-structure.sh tests/rubric-compiler-adapter-records.sh tests/rubric-compiler-adapter-gate.sh tests/rubric-compiler-activation.sh tests/rubric-consumer-gate.sh tests/rubric-compiler-benchmark.sh && git diff --check` | 125 | `sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | Not executed: authority-only denial |
| Coverage | N/A | N/A | N/A | No admitted runtime run |

A prior exploratory invocation with an extra `--help` argument occurred before the preflight result returned. It is excluded from this report, does not satisfy either declared command, and is not used as compliance evidence.

### Spec Compliance Matrix

| Requirement | Scenario | Covering runtime test | Result |
|---|---|---|---|
| Evidence | Normalization | `rubric-compiler-structure.sh` | ❌ UNTESTED — authority-only denial |
| Candidates | Unresolved | `rubric-compiler-structure.sh` | ❌ UNTESTED — authority-only denial |
| Validation | Repeat | `rubric-compiler-adapter-gate.sh` | ❌ UNTESTED — authority-only denial |
| Confirmation | Re-init | `rubric-compiler-structure.sh`, `rubric-compiler-adapter-gate.sh` | ❌ UNTESTED — authority-only denial |
| Activation | Hybrid | `rubric-compiler-activation.sh` | ❌ UNTESTED — authority-only denial |
| Activation | Mirror failure | `rubric-compiler-activation.sh` | ❌ UNTESTED — authority-only denial |
| Activation | OpenSpec | `rubric-compiler-activation.sh` | ❌ UNTESTED — authority-only denial |
| Activation | Engram | `rubric-compiler-activation.sh` | ❌ UNTESTED — authority-only denial |
| Activation | None | `rubric-compiler-activation.sh` | ❌ UNTESTED — authority-only denial |
| Binding Proof | Provider | `rubric-compiler-structure.sh` | ❌ UNTESTED — authority-only denial |
| Binding Proof | Adapter | `rubric-compiler-adapter-records.sh`, `rubric-compiler-adapter-gate.sh` | ❌ UNTESTED — authority-only denial |
| Binding Proof | Skip | `rubric-compiler-structure.sh` | ❌ UNTESTED — authority-only denial |
| Binding Proof | Symlink | `rubric-compiler-structure.sh`, `rubric-compiler-adapter-gate.sh` | ❌ UNTESTED — authority-only denial |
| Oracle Isolation | Isolation | `rubric-compiler-benchmark.sh` | ❌ UNTESTED — authority-only denial |
| Benchmarks | CNSIC score | `rubric-compiler-benchmark.sh` | ❌ UNTESTED — authority-only denial |
| Benchmarks | Baseline | `rubric-compiler-benchmark.sh` | ❌ UNTESTED — authority-only denial |
| State Gate | Blocked | `rubric-consumer-gate.sh` | ❌ UNTESTED — authority-only denial |

**Compliance summary**: 0/17 scenarios compliant. Source inspection identifies intended coverage only; it cannot establish compliance.

### Correctness (Static Evidence Only)

| Requirement | Inspection result | Source evidence |
|---|---|---|
| Evidence | Present, runtime unverified | `factrec` retains provenance/status and rejects `provider`. |
| Candidates | Present, runtime unverified | Rows/questions are fact-linked and unresolved states require blocking questions. |
| Validation | Present, runtime unverified | Structural validator enforces deterministic IDs, bindings, resolution, and no candidate execution. |
| Confirmation | Present, runtime unverified | Confirmed rows require answers; preserved/stale re-init records are checked. |
| Activation | Present, runtime unverified | OpenSpec, Engram, hybrid compensation/read-back, and none flows are defined. |
| Binding Proof | Present, runtime unverified | Fixed proof adapters, digest binding, unknown/unsatisfied handling, and symlink confinement are defined. |
| Oracle Isolation | Present, runtime unverified | Repository-only benchmark rejects oracle terms and reads only clone candidates/evidence. |
| Benchmarks | Present, runtime unverified | Scorer checks two 16-row inputs, exact seven-binding equality, provenance/safety, and clone snapshots. |
| State Gate | Present, runtime unverified | Consumer gate blocks invalid/staging/recovery states and emits one producer-resolved envelope. |

### Design Coherence

| Design decision | Followed by inspected source? | Notes |
|---|---|---|
| Fail-closed pre-resolution authority | Yes, static only | Consumer gate blocks absent, malformed, duplicate, staging, recovery-required, conflict, outage, and mismatch states. |
| One resolver; strictest-wins/evidence union | Yes, static only | Delta and consumer wording retain one orchestrator resolution owner. |
| Mode-specific activation and read-back | Yes, static only | Activation fixtures cover OpenSpec, Engram, hybrid, none, recovery, and compensation paths. |
| Unit3 read-only isolation | Yes, static only | Benchmark snapshots fixed CNSIC/Gentle clones, keeps oracle scorer-only, and has no repository-parity assertion. |
| Unit3 scope amendment | Yes, static only | The amended design explicitly makes Unit3 final scope read-only and excludes clone mutation, resolving the prior scope contradiction. |

### HYBRID Artifact Parity

- Proposal `#7114`, specification `#7115`, and amended design `#7116` match their OpenSpec counterparts in substance; design revision is 18.
- Tasks are semantically aligned at 9/9 checked, but not byte-identical: OpenSpec retains the stale Unit3 heading `(pending)` and more detailed Unit2 wording while Engram `#7145` says Unit3 completed. This is a warning for archive hygiene, not accepted runtime evidence.
- Apply progress `#7153` reports Unit1A/1B, Unit2A/2B/2C, and Unit3 evidence, including read-only CNSIC/Gentle provenance/safety, post-confirmation 16/16 equality, seven binding identities, and clone snapshots. It is historical apply evidence and is not substituted for this independent runtime verification.

### Unit Coverage Inventory

| Unit | Intended focused evidence | Independent runtime status |
|---|---|---|
| Unit1A | `rubric-compiler-structure.sh` | Not executed |
| Unit1B | `rubric-compiler-adapter-records.sh`, `rubric-compiler-adapter-gate.sh` | Not executed |
| Unit2A/2B | `rubric-compiler-activation.sh` | Not executed |
| Unit2C | `rubric-consumer-gate.sh`, `init-rubric-contract.sh` | Not executed |
| Unit3 | `rubric-compiler-benchmark.sh`, `tests/run.sh` | Not executed |

### Canonical Verification Evidence

The exact preimage is the following text block, including its terminal LF; the fence is not part of the preimage. Its SHA-256 is `sha256:c89bacf9c82025d29551f01cadab0c08608a7dd7ad9dfd0398afc6c2af339c20`.

```text
schema=gentle-ai.verification-evidence/v1
change=rubric-compiler-foundation
verification_ordinal=3
runtime_revision=sha256:15ccb6b54cbab90b74a5da9f0935791351df567d3870671041bd7743293604ed
preflight=sdd-status:blocked:missing-bounded-review-start
review_authority=clean:entries-0
test_command=bash tests/rubric-compiler-structure.sh && bash tests/rubric-compiler-adapter-records.sh && bash tests/rubric-compiler-adapter-gate.sh && bash tests/rubric-compiler-activation.sh && bash tests/rubric-consumer-gate.sh && bash tests/rubric-compiler-benchmark.sh && bash tests/init-rubric-contract.sh && bash tests/run.sh
test_exit_code=125
test_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
build_command=shellcheck --severity=warning apply.sh tests/run.sh tests/rubric-compiler-structure.sh tests/rubric-compiler-adapter-records.sh tests/rubric-compiler-adapter-gate.sh tests/rubric-compiler-activation.sh tests/rubric-consumer-gate.sh tests/rubric-compiler-benchmark.sh && bash -n apply.sh tests/run.sh tests/rubric-compiler-structure.sh tests/rubric-compiler-adapter-records.sh tests/rubric-compiler-adapter-gate.sh tests/rubric-compiler-activation.sh tests/rubric-consumer-gate.sh tests/rubric-compiler-benchmark.sh && git diff --check
build_exit_code=125
build_output_hash=sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
requirements=0/9
scenarios=0/17
verdict=fail
```

### Issues Found

**CRITICAL**
- Native authority preflight denied final verification because no bounded review/start transaction exists. No requirement scenario can be marked compliant without admitted runtime evidence.

**WARNING**
- HYBRID tasks artifacts are not byte-identical despite agreeing on 9/9 completed checkboxes; reconcile the stale OpenSpec Unit3 heading before archive.

**SUGGESTION**
- After an authorized bounded review transaction exists, use the native dispatcher for the next permitted route rather than reusing this completed ordinal.

### Verdict

**FAIL** — authority-only preflight denial; 0/17 scenarios have admissible independent runtime evidence.
