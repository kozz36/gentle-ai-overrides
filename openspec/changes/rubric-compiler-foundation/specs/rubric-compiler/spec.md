# Rubric Compiler Specification

## Requirements

### Requirement: Evidence

Facts MUST preserve source/provenance/status: unknown, absent, or unsatisfied.

#### Scenario: Normalization

- GIVEN command/tool evidence
- WHEN facts are normalized
- THEN provenance and status are retained without inferred policy

### Requirement: Candidates

Claims MUST fact-link; repository-only candidates MUST NOT activate; unsupported claims fail; unresolved rows block.

#### Scenario: Unresolved

- GIVEN an unresolved row
- WHEN validation runs
- THEN it returns candidate/question; no active write

### Requirement: Validation

The system MUST deterministically validate schema/provenance/bindings/runnability/conflicts/defaults/all-row resolution; invalid rubrics fail without partial activation.

#### Scenario: Repeat

- GIVEN identical facts and answers
- WHEN repeatedly validated
- THEN results are identical

### Requirement: Confirmation

The system MUST confirm rows/questions before activation. Re-init preserves unchanged manual rows; only stale/conflicting rows reconfirm.

#### Scenario: Re-init

- GIVEN unchanged confirmed manual evidence
- WHEN re-initialization runs
- THEN it is preserved; stale/conflicting rows require reconfirmation

### Requirement: Activation

The system MUST atomically activate confirmed rubrics. In hybrid, OpenSpec is authoritative and `sdd-init/{project}` the consumer-visible Engram mirror/canonical lookup; versions MUST NOT substitute. Mirror failure restores the prior selection/mirror.

#### Scenario: Hybrid

- GIVEN a confirmed rubric
- WHEN hybrid activation succeeds
- THEN OpenSpec and `sdd-init/{project}` are equivalent

#### Scenario: Mirror failure

- GIVEN an active selection and mirror
- WHEN hybrid cannot update or verify `sdd-init/{project}`
- THEN selection and mirror are preserved or restored

#### Scenario: OpenSpec

- GIVEN a valid OpenSpec policy
- WHEN OpenSpec activates it
- THEN atomic replacement preserves the prior file on failure

#### Scenario: Engram

- GIVEN canonical `sdd-init/{project}` revision
- WHEN Engram activates a rubric
- THEN it updates that topic and can recover revision

#### Scenario: None

- GIVEN mode `none`
- WHEN a candidate is produced
- THEN it returns inline and MUST NOT activate or persist policy

### Requirement: Binding Proof

Structural validation MUST NOT derive tool/provider semantics from caller booleans/free facts. A binding is satisfiable only with fixed, versioned proof-adapter attestation over exact observation/input digests matching executable/scope. Unsupported adapters are unknown/unsatisfied and block activation; LLM/`provider=true` never bypasses. CodeGraph MAY attest scope, never command declaration/tool proof. `skip` rows MAY omit automated bindings but retain fact/provenance; `standard`/`strict-tdd` MUST satisfy declared obligations. Root confinement MUST reject paths with intermediate symlinks.

#### Scenario: Provider

- GIVEN unrelated caller `provider=true`
- WHEN structurally validated
- THEN the binding is rejected

#### Scenario: Adapter

- GIVEN an unsupported evidence adapter
- WHEN validation runs
- THEN it is unknown/unsatisfied and activation blocks

#### Scenario: Skip

- GIVEN a `skip` row with provenance and no bindings
- WHEN validated
- THEN it is permitted

#### Scenario: Symlink

- GIVEN a root path with an intermediate symlink
- WHEN confined
- THEN it is rejected

### Requirement: Oracle Isolation

The CNSIC canonical policy MUST be scorer-only, unavailable to extraction, generation, validation, and confirmation.

#### Scenario: Isolation

- GIVEN a repository-only CNSIC run
- WHEN a candidate is generated
- THEN the canonical policy has not influenced it

### Requirement: Benchmarks

Repository-only CNSIC/Gentle AI MUST report unsupported claims/provenance, not parity. Post-confirmation CNSIC requires 16/16 signatures/policies and equality with every canonical binding identity in its scorer-only fixture; it defines the denominator and generation MUST NOT read it. Gentle AI MUST set deterministic safety/provenance baseline without parity.

#### Scenario: CNSIC score

- GIVEN confirmed CNSIC answers
- WHEN scored
- THEN it reports 16/16 signatures/policies and fixture-binding equality

#### Scenario: Baseline

- GIVEN a repository-only Gentle AI run
- WHEN benchmarked
- THEN safety/provenance metrics are reported without parity

### Requirement: State Gate

Active surface is activation safety, not work-unit classification/#262 evidence enforcement. On `staging` or `recovery-required`, apply/verify MUST block without legacy/default fallback. They MAY resume only after `sdd-init` verifies committed/restored canonical state.

#### Scenario: Blocked

- GIVEN active state `staging` or `recovery-required`
- WHEN apply or verify consumes policy
- THEN it blocks; consumption resumes after verified canonical state
