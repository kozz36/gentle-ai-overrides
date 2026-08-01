---
schema: human-semantic-evaluation-compiler-bound-experiment-output/v1
experiment_path: /home/kozz36/cnsic-agent-init-primary-experiment-v3-20260731
source_head: 2703650aee7d7fcc7ccecefb7f9852f4cb1278ab
source_path: /home/kozz36/cnsic-agent-init-primary-experiment-v3-20260731/.experiment-evidence/candidate/ir.json
candidate_sha256: f36ddae7745fc3afae9c9d4e4d5458875b07305eea500b0926d7867931310d9f
manifest_path: /home/kozz36/cnsic-agent-init-primary-experiment-v3-20260731/.experiment-evidence/manifest.txt
manifest_sha256: 0e59e8fdd1bd4e02a6a1874e43229ed290539918fefa2b41299df484c117e470
reference_body_sha256: 12dcd0d071ced00134613b09aafd23b1d2c7faa64d234e69ee26b93d5c4f7d15
artifact_freshness: fresh-source-bound
display_kind: faithful-display-copy
---

# CNSIC Compiler-Bound Blind Experiment Candidate

This complete faithful display copy is a pending compiler input, not activation
authority. No active YAML or `ResolutionV1` was emitted.

```json
{
  "schema": "v1",
  "candidate-schema": "v1",
  "project": "cnsic-agent",
  "persistence": "openspec-experimental",
  "status": "pending",
  "strict_tdd": false,
  "mode_order": ["skip", "standard", "strict-tdd"],
  "matching": "all-rows",
  "bindings": [
    {
      "id": "backend-unit",
      "method": "unit",
      "context": {"executable": "python", "argv": ["-m", "pytest", "tests/unit/", "-q"], "workdir": ".", "env": [], "platforms": ["linux", "macos", "windows"], "requirements": ["python-venv"]},
      "declaration_ref": "AGENTS.md:18,62",
      "tool_proof_ref": "requirements.txt:63-67",
      "scope": "tests/unit/** and applicable Python production signatures",
      "signature_coverage": ["source", "api", "security", "state", "migration", "refactor"],
      "fact_refs": ["fact-validation-backend-unit"],
      "attestation_refs": ["attest-backend-unit-declared"]
    },
    {
      "id": "frontend-test",
      "method": "unit",
      "context": {"executable": "npm", "argv": ["test"], "workdir": "frontend", "env": [], "platforms": ["linux", "macos", "windows"], "requirements": ["node-22.22.3"]},
      "declaration_ref": "AGENTS.md:21,66",
      "tool_proof_ref": "frontend/package.json:36-54 and frontend/package-lock.json",
      "scope": "frontend/** unit/component signatures",
      "signature_coverage": ["ui", "source", "refactor"],
      "fact_refs": ["fact-validation-frontend-test"],
      "attestation_refs": ["attest-frontend-test-declared"]
    },
    {
      "id": "frontend-lint",
      "method": "lint",
      "context": {"executable": "npm", "argv": ["run", "lint"], "workdir": "frontend", "env": [], "platforms": ["linux", "macos", "windows"], "requirements": ["node-22.22.3"]},
      "declaration_ref": "frontend/package.json:11",
      "tool_proof_ref": "frontend/package.json:36-45 and frontend/package-lock.json",
      "scope": "frontend/**",
      "signature_coverage": ["ui", "source", "refactor"],
      "fact_refs": ["fact-validation-frontend-lint"],
      "attestation_refs": ["attest-frontend-lint-declared"]
    },
    {
      "id": "frontend-build",
      "method": "build",
      "context": {"executable": "npm", "argv": ["run", "build"], "workdir": "frontend", "env": [], "platforms": ["linux", "macos", "windows"], "requirements": ["node-22.22.3"]},
      "declaration_ref": "frontend/package.json:9",
      "tool_proof_ref": "frontend/package.json:36-54 and frontend/package-lock.json",
      "scope": "frontend/**",
      "signature_coverage": ["ui", "source", "refactor"],
      "fact_refs": ["fact-validation-frontend-build"],
      "attestation_refs": ["attest-frontend-build-declared"]
    }
  ],
  "rows": [
    {"id": "dependency-only", "signature": "dependency-only", "mode": "skip", "binding_refs": [], "disciplines": [], "source": "manual"},
    {"id": "configuration-only", "signature": "configuration-only", "mode": "skip", "binding_refs": [], "disciplines": [], "source": "manual"},
    {"id": "docker-operations-only", "signature": "docker-operations-only", "mode": "skip", "binding_refs": [], "disciplines": [], "source": "manual"},
    {"id": "prompt-only", "signature": "prompt-only", "mode": "skip", "binding_refs": [], "disciplines": [], "source": "manual"},
    {"id": "project-skill-only", "signature": "project-skill-only", "mode": "skip", "binding_refs": [], "disciplines": [], "source": "manual"},
    {"id": "default-unmatched", "signature": "default (unmatched-only)", "mode": "skip", "binding_refs": [], "disciplines": [], "source": "manual"}
  ]
}
```
