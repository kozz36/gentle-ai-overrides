<!-- shape:skill -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Producer

- Before any project inspection whenever rubric generation is selected or a rubric candidate may be generated, including selected rubric re-init, MUST read `references/rubric-authoring.md`. It is the generic semantic-authoring method; do not replace it with capability-only inference.
- `sdd-init` is the single writer of project TDD policy. The orchestrator is read-only: it may relay a blocking envelope but must not select, generate, modify, or persist policy/rubric rows.
- The semantic producer emits only the existing canonical directory candidate bundle/IR (`schema: v1`, `candidate-schema: v1`) consumed by the embedded rubric validator and compiler gates. It MUST NOT hand-author OpenSpec policy shapes or active YAML. Every binding has a stable ID, canonical command context, declaration/tool-proof refs, scope/signature coverage, fact refs, and attestation refs; every row with disciplines or evidence references binding IDs.
- The installed `Task-Intent Policy Baseline v1` in `references/rubric-authoring.md` is versioned policy evidence for future task classes. Generate its prospective baseline rows even when the current repository has no instance; project evidence refines them and an equivalent manual/project row replaces, never co-matches with, the baseline row.
- Use the LLM-assisted producer as the primary semantic path. Only its pre-publication availability or execution failure may select the deterministic baseline fallback defined in `references/rubric-authoring.md`; observed canonical state remains fail-closed recovery.
- Detect testing capabilities and the CLOSED set of satisfiable evidence methods: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, and `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command.
- Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.
- Preserve the existing `strict_tdd` resolution when one binary policy is provably sufficient; otherwise generate a project-derived rubric candidate and block for `strict|rubric`. Before a valid answer, return the candidate but persist no selected policy or active rubric. Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric. Answer `rubric`: submit the candidate to the canonical compiler; only its verified activation may persist `strict_tdd: false` plus the active authoritative rubric. Do not choose or continue downstream while blocked.
- Rubric signatures are open and project-derived. Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs); test paths may supplement but cannot be the only production classification. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union evidence/discipline requirements.
- Only the canonical compiler serializer may serialize one active rubric in `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` with `Status: active/authoritative.`, mechanical matching, and `| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |`; Source is `generated` or `manual`. Mirror active/provenance semantics under OpenSpec `testing:`.
- Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric submits the candidate to compiler activation; only verified activation persists `strict_tdd: false` plus exactly one active rubric. Hybrid writes both; none returns inline.
- OpenSpec: `testing.rubric.active` is the only active OpenSpec path; parallel `testing.methods` authority is forbidden. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. Strict uses `rubric: absent (not active:false, not candidate, no rows)`. The canonical rubric fields are `mode_order: [skip, standard, strict-tdd]`, `matching: all-rows`, `bindings: [...]  # each has id, method, command context, scope/signature coverage, command_declaration, tool_proof`, and `rows: [...]      # each has signature, mode exact enum, binding IDs, source generated|manual`.
- The deterministic compiler is non-authoritative for semantic rows: it validates bindings, canonicalizes, persists, and fails closed, but never invents or upgrades a semantic row. Require structural validation, exact replay, canonical-model, serializer, and activation/readback gates before persistence. `active/authoritative` requires `ResolutionV1`, transaction, canonical-model digest, backend authority, and verified readback evidence; otherwise return only the pending candidate and existing typed blocked envelope. Structural validation is additive: it reports only `structure-valid/pending`, never executes candidate commands, and leaves proof semantics and activation to later units.
- Render every rubric candidate using the exact Result Contract in `references/rubric-authoring.md`: specific-row table, separate unmatched-only Default, bindings, orchestrator simulation, then questions/receipt state. This human-readable projection is not authority; the canonical candidate bundle/IR remains authoritative.
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:skill -->

<!-- shape:details -->
<!-- gentle-ai:sdd-init-rubric -->
## Project TDD Policy Details

### Detection And Resolution

Build a capability record containing the detected command for each satisfiable method in this closed vocabulary: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command. Do not emit an unavailable method, invent a command, or substitute a different method.

Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.

Generate a rubric candidate only when multiple distinct satisfiable evidence methods or scope-dependent gates make `strict_tdd` lossy. Before a valid answer, return the candidate but persist no selected policy or active rubric. Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric. Answer `rubric`: submit the candidate to the canonical compiler; only its verified activation may persist `strict_tdd: false` plus the active authoritative rubric. A discarded candidate may be diagnostic only, never consumer-visible as an active rubric.

Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs) derived from the project; test paths may supplement but cannot be the only production classification. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union their `discipline` and `evidence_methods`.

### Blocking Selection Envelope

When a candidate rubric is needed, return this complete blocking envelope and stop:

```yaml
headline: "Choose project TDD policy"
reason: "Detected capabilities make binary strict_tdd lossy; choose the policy representation before SDD can continue."
selection_mode: single
options:
  strict:
    description: "Use the existing binary strict_tdd policy and its default evidence requirements."
  rubric:
    description: "Use the generated project-specific rubric with strictest-wins matching and satisfiable evidence methods."
allowed_answers: strict|rubric
instruction: "STOP: do not continue to downstream phases. Do not choose on the user's behalf."
```

The orchestrator may relay this envelope unchanged, but remains read-only. Do not start downstream phases, persist a selected policy, or present a reduced prompt until the user answers exactly `strict` or `rubric`.

### Persistence And Re-init

- `engram`: persist selected policy in `sdd-init/{project}` and testing capabilities in `sdd/{project}/testing-capabilities`. In rubric mode, include this authoritative consumer contract:

```markdown
## TDD RUBRIC (per-work-type — AUTHORITATIVE)

Status: active/authoritative.

Match mechanically: `default` is selected ONLY when no non-default signature matches. Otherwise all matching non-default rows apply, strictest-wins, and evidence/discipline requirements union.

| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |
| --- | --- | --- | --- |
| project-derived specific signature | exact enum | only bound obligations | generated or manual |

## Default (unmatched-only)

Mode: project-derived conservative mode or pending blocking question. This metadata is selected only when no specific row matches, is not counted as a regular rubric row, and never unions all detected methods.
```

- `openspec`: mirror selected policy, scoped capability facts, and generated/manual provenance under `openspec/config.yaml` `testing:`. In rubric mode, `strict_tdd: false` and exactly one `rubric.active: true` carry the same rows/resolution; strict mode has `strict_tdd: true` and no active `rubric`.
- `hybrid`: write semantically equivalent data to both backends.
- `none`: return the complete policy, rubric, and capability facts inline without persistence.

OpenSpec writes this canonical active schema exactly; testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. The consumer stays path-agnostic and consumes active/authoritative data only.

```yaml
strict_tdd: false
testing:
  policy: rubric
  rubric:
    active: true
    authoritative: true
    mode_order: [skip, standard, strict-tdd]
    resolution:
      matching: all-rows
      mode: strictest-wins
      evidence: union
    bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof
    rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual
    default: {...}   # selective, exact enum, source
  detected_but_unsatisfied: [...]
```

Strict selection writes this exact shape, with no `rubric` key:

```yaml
strict_tdd: true
testing:
  policy: strict
  # rubric: absent (not active:false, not candidate, no rows)
```

On re-init, compare current facts against generated rows. Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric submits the candidate to compiler activation; only verified activation persists `strict_tdd: false` plus exactly one active rubric. With unchanged inputs, return the persisted policy unchanged.

### Structural Bundle Boundary

The v1 directory bundle validates only shape: exact one-line non-symlink scalars; contiguous numbered non-symlink lists; component-confined file locators with matching checksums; complete `untrusted`/`scope-only` CodeGraph observations; globally unique canonical IDs; deterministic order and fact fingerprints; normalized binding contexts; structural attestation links; mechanical triggers; questions, confirmation, and re-init records. No field named `provider` is accepted. Candidate commands are data and never execute. `skip` rows may have zero binding/attestation refs; other modes require both. A `preserved` re-init fingerprint equals current referenced facts; a mismatch is `stale` and requires the row's open blocking question.

<!-- rubric-validator:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL
b=${1-}; [ "$#" = 1 ] && [ -d "$b" ] || exit 2
bad() { printf '%s\n' "invalid rubric structure: $*" >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad scalar; awk 'END { exit NR != 1 }' "$1" || bad scalar; IFS= read -r _one < "$1" || :; [ -n "${_one-}" ] || bad scalar; printf %s "$_one"; }
v() { one "$1/$2"; }
has() { case " $1 " in *" $2 "*) return 0;; *) return 1;; esac; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad path;; esac; }
walk() { _walk_p=; _walk_rest=${1#/}; while [ -n "$_walk_rest" ]; do _walk_part=${_walk_rest%%/*}; case "$_walk_rest" in */*) _walk_rest=${_walk_rest#*/};; *) _walk_rest=;; esac; _walk_p=$_walk_p/$_walk_part; [ ! -L "$_walk_p" ] || bad symlink; done; }
confine() { _conf_rel=$1; _conf_type=$2; safe "$_conf_rel"; walk "$root"; _conf_p=$root; _conf_rest=$_conf_rel; while [ -n "$_conf_rest" ]; do _conf_part=${_conf_rest%%/*}; case "$_conf_rest" in */*) _conf_rest=${_conf_rest#*/};; *) _conf_rest=;; esac; _conf_p=$_conf_p/$_conf_part; [ ! -L "$_conf_p" ] || bad symlink; done; case "$_conf_type" in f) [ -f "$_conf_p" ];; d) [ -d "$_conf_p" ];; esac || bad target; }
list() { _list_d=$1; _list_min=${2-1}; [ -d "$_list_d" ] && [ ! -L "$_list_d" ] || bad list; _list_n=0; for _list_f in "$_list_d"/*; do [ -e "$_list_f" ] || continue; [ -f "$_list_f" ] && [ ! -L "$_list_f" ] || bad list; [ "$(basename "$_list_f")" = "$(printf %03d "$_list_n")" ] || bad order; one "$_list_f" >/dev/null; _list_n=$((_list_n+1)); done; [ "$_list_n" -ge "$_list_min" ] || bad list; n=$_list_n; }
refs() { _refs_d=$1; _refs_all=$2; list "$_refs_d" "${3-1}"; for _refs_f in "$_refs_d"/*; do [ -e "$_refs_f" ] || continue; has "$_refs_all" "$(one "$_refs_f")" || bad "reference:$_refs_d"; done; }
inlist() { for _in_f in "$1"/*; do [ -e "$_in_f" ] && [ "$(one "$_in_f")" = "$2" ] && return 0; done; return 1; }
id() { _id_d=$1; _id_k=$(v "$_id_d" kind); case "$_id_k" in ''|*[!a-z-]*) bad kind;; esac; set -- $(cksum "$_id_d/identity"); _id_want="v1:$_id_k:$1:$2"; [ "$(v "$_id_d" id)" = "$_id_want" ] || bad id; printf %s "$_id_want"; }
fp() { (cd "$1" && find . -type f ! -name id ! -name identity ! -name fingerprint -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1 ":" $2}'; }
fps() { for f in "$1"/*; do [ -e "$f" ] || continue; x=$(one "$f"); for d in "$b/facts/"*; do [ "$(v "$d" id)" = "$x" ] && printf '%s:%s\n' "$x" "$(fp "$d")"; done; done | cksum | awk '{print $1 ":" $2}'; }
uniq() { has "$seen" "$1" && bad duplicate; seen="$seen $1"; all="$all $1"; }
records() { _rec_top=$1; _rec_min=$2; _rec_fn=$3; [ -d "$_rec_top" ] && [ ! -L "$_rec_top" ] || bad records; _rec_n=0; for _rec_d in "$_rec_top"/*; do [ -e "$_rec_d" ] || continue; [ -d "$_rec_d" ] && [ ! -L "$_rec_d" ] || bad records; "$_rec_fn" "$_rec_d"; _rec_n=$((_rec_n+1)); done; [ "$_rec_n" -ge "$_rec_min" ] || bad records; }
[ "$(v "$b" schema)" = v1 ] && [ "$(v "$b" candidate-schema)" = v1 ] || bad schema
find "$b" -name provider -print | grep . >/dev/null && bad provider
root=$(v "$b" root); case "$root" in /*) ;; *) bad root;; esac; case "$root" in *'*'*|*'?'*|*'['*) bad root;; esac; [ -d "$root" ] && [ ! -L "$root" ] || bad root; walk "$root"
[ "$(v "$b/resolution" matching)" = all-rows ] && [ "$(v "$b/resolution" mode)" = strictest-wins ] && [ "$(v "$b/resolution" default)" = unmatched-only ] || bad resolution
seen= all= obs= facts= bindings= attestations= rows= defaults=0
obsrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" channel)" in file) loc=$(v "$d" locator); confine "$loc" f; set -- $(cksum "$root/$loc"); [ "$(v "$d" checksum)" = "$1 $2" ] || bad checksum;; codegraph) [ "$(v "$d" status)" = untrusted ] && [ "$(v "$d" scope)" = scope-only ] || bad codegraph; v "$d" query >/dev/null; v "$d" index-revision >/dev/null; v "$d" symbol >/dev/null; safe "$(v "$d" repo-path)";; *) bad observation;; esac; v "$d" source >/dev/null; v "$d" provenance >/dev/null; obs="$obs $x"; }
factrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" status)" in known|unknown|absent|unsatisfied) ;; *) bad fact;; esac; [ ! -e "$d/provider" ] || bad provider; v "$d" source >/dev/null; v "$d" provenance >/dev/null; v "$d" source-path >/dev/null; v "$d" evidence-kind >/dev/null; v "$d" adapter >/dev/null; refs "$d/observation-refs" "$obs"; [ "$(v "$d" fingerprint)" = "$(fp "$d")" ] || bad fingerprint; facts="$facts $x"; }
attrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" schema)" = v1 ] && [ "$(v "$d" attestation-id)" = "$x" ] || bad attestation; for k in adapter-id adapter-version adapter-bytes-digest input-digest status claim-kind executable method scope; do v "$d" "$k" >/dev/null; done; oi=$(v "$d" observation-id); [ ! -e "$d/observation-refs" ] && [ -n "$oi" ] && has "$obs" "$oi" || bad reference; safe "$(v "$d" source-locator)"; attestations="$attestations $x"; }
bindrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" method)" in unit|integration|e2e|coverage|lint|typecheck|format|build) ;; *) bad method;; esac; v "$d" scope >/dev/null; v "$d" signature-coverage >/dev/null; [ -d "$d/context" ] && [ ! -L "$d/context" ] || bad context; [ "$(v "$d/context" root)" = "$root" ] || bad root; [ "$(v "$d/context" workdir)" = . ] || confine "$(v "$d/context" workdir)" d; v "$d/context" executable >/dev/null; list "$d/context/argv"; list "$d/platforms"; list "$d/env" 0; list "$d/requirements" 0; refs "$d/fact-refs" "$facts"; dr=$(v "$d" declaration-ref); tr=$(v "$d" tool-proof-ref); [ "$dr" != "$tr" ] && inlist "$d/fact-refs" "$dr" && inlist "$d/fact-refs" "$tr" || bad reference; refs "$d/attestation-refs" "$attestations" 0; bindings="$bindings $x"; }
bindpath() { for _bind_d in "$b/bindings/"*; do [ "$(v "$_bind_d" id)" = "$1" ] && { printf %s "$_bind_d"; return; }; done; bad reference; }
linked() { _link_row=$1; _link_kind=$2; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); for _link_item in "$_link_bind/$_link_kind/"*; do [ -e "$_link_item" ] && inlist "$_link_row/$_link_kind" "$(one "$_link_item")" || bad link; done; done; for _link_item in "$_link_row/$_link_kind/"*; do [ -e "$_link_item" ] || continue; _link_found=; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); inlist "$_link_bind/$_link_kind" "$(one "$_link_item")" && _link_found=1; done; [ -n "$_link_found" ] || bad link; done; }
rowrec() { d=$1; x=$(id "$d"); uniq "$x"; m=$(v "$d" mode); case "$m" in skip|standard|strict-tdd) ;; *) bad mode;; esac; st=$(v "$d" state); case "$st" in pending|confirmed|rejected|stale|conflict) ;; *) bad state;; esac; case "$(v "$d" source)" in generated|manual) ;; *) bad source;; esac; sel=$(v "$d" selection); list "$d/trigger-paths" 0; if [ "$sel" = unmatched-only ]; then [ "$(v "$d" signature)" = default ] && [ "$(v "$d" trigger-kind)" = unmatched ] && [ "$n" = 0 ] || bad default; defaults=$((defaults+1)); else [ "$sel" = specific ] && [ "$(v "$d" trigger-kind)" = path ] && [ "$n" -gt 0 ] || bad trigger; fi; refs "$d/fact-refs" "$facts"; [ "$(v "$d" fact-fingerprint)" = "$(fps "$d/fact-refs")" ] || bad fingerprint; list "$d/disciplines" 0; refs "$d/binding-refs" "$bindings" 0; bn=$n; refs "$d/attestation-refs" "$attestations" 0; an=$n; [ "$m" = skip ] || { [ "$bn" -gt 0 ] && [ "$an" -gt 0 ] && linked "$d" fact-refs && linked "$d" attestation-refs; } || bad attestation; [ "$st" != confirmed ] || { v "$d" confirmation-answer >/dev/null; v "$d" confirmer >/dev/null; }; rows="$rows $x"; }
qrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" kind)" = question ] && [ "$(v "$d" blocking)" = true ] || bad question; v "$d" prompt >/dev/null; case "$(v "$d" state)" in open|answered|rejected) ;; *) bad question;; esac; refs "$d/fact-refs" "$facts"; list "$d/allowed-answers"; has "$rows" "$(v "$d" row-ref)" || bad reference; }
rowpath() { for _row_d in "$b/rows/"*; do [ "$(v "$_row_d" id)" = "$1" ] && { printf %s "$_row_d"; return; }; done; bad reference; }
reinitrec() { d=$1; rr=$(v "$d" row-ref); rd=$(rowpath "$rr"); prior=$(v "$d" prior-fingerprint); now=$(fps "$rd/fact-refs"); case "$(v "$d" state)" in preserved) [ "$prior" = "$now" ] || bad reinit;; stale) [ "$prior" != "$now" ] && [ "$(v "$rd" state)" = stale ] || bad reinit;; *) bad reinit;; esac; }
records "$b/observations" 1 obsrec; records "$b/facts" 1 factrec; records "$b/attestations" 0 attrec; records "$b/bindings" 0 bindrec; records "$b/rows" 1 rowrec; [ "$defaults" = 1 ] || bad default; records "$b/questions" 0 qrec
for d in "$b/rows"/*; do [ -e "$d" ] || continue; st=$(v "$d" state); case "$st" in pending|stale|conflict) found=; for q in "$b/questions"/*; do [ -d "$q" ] && [ "$(v "$q" row-ref)" = "$(v "$d" id)" ] && [ "$(v "$q" state)" = open ] && [ "$(v "$q" blocking)" = true ] && found=1; done; [ -n "$found" ] || bad question;; esac; done
records "$b/reinit" 0 reinitrec; refs "$b/record-order" "$all"; [ "$n" = "$(set -- $all; printf %s "$#")" ] || bad order; prev=; for f in "$b/record-order"/*; do [ -e "$f" ] || continue; x=$(one "$f"); [ -z "$prev" ] || [ "$prev" \< "$x" ] || bad order; prev=$x; done
printf 'structure-valid/pending\n'
<!-- rubric-validator:end -->
<!-- rubric-adapter-records:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL; umask 077
bad() { printf '%s\n' 'invalid adapter record input' >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad; [ "$(awk 'END { print NR }' "$1")" = 1 ] || bad; x=$(awk 'NR == 1 { print; exit }' "$1"); [ -n "$x" ] || bad; printf %s "$x"; }
v() { one "$1/$2"; }
digest() { cksum "$1" | awk '{print $1 ":" $2}'; }
graphdigest() { for k in status scope query index-revision symbol repo-path source provenance; do printf '%s=' "$k"; v "$1" "$k"; printf '\n'; done | cksum | awk '{print $1 ":" $2}'; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad;; esac; }
walk() { p=; rest=${1#/}; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
confine() { safe "$1"; walk "$root"; p=$root; rest=$1; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; [ -f "$p" ] && [ ! -L "$p" ] || bad; printf %s "$p"; }
findid() { for d in "$1"/*; do [ -d "$d" ] && [ "$(v "$d" id)" = "$2" ] && { printf %s "$d"; return; }; done; bad; }
argvdigest() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] || continue; one "$f"; printf '\n'; done | cksum | awk '{print $1 ":" $2}'; }
emptylist() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] && return 1; done; return 0; }
sourcefact() { for rf in "$1/fact-refs"/*; do [ -f "$rf" ] || continue; fd=$(findid "$b/facts" "$(one "$rf")"); [ "$(v "$fd" adapter)" = "$2" ] && [ "$(v "$fd" evidence-kind)" = "$3" ] || continue; oid=$(one "$fd/observation-refs/000"); [ ! -e "$fd/observation-refs/001" ] || continue; od=$(findid "$b/observations" "$oid"); [ "$(v "$od" channel)" = file ] && [ "$(v "$od" locator)" = "$4" ] || continue; input=$(confine "$4"); [ "$(v "$od" checksum)" = "$(cksum "$input" | awk '{print $1 " " $2}')" ] || continue; printf %s "$input"; return; done; return 1; }
pair() { [ "$(argvdigest "$1/context/argv")" = "$5" ] && [ "$(v "$1/context" executable)" = "$6" ] && [ "$(v "$1" method)" = unit ] && [ "$(v "$1" scope)" = "$7" ] && [ "$(v "$1/context" workdir)" = . ] && emptylist "$1/context/env"; }
profile() { case "$2" in shell-v1) e=bash; s=project-root; a=3407402481:13; st=proven;; cnsic-python-v1) e=python; s=path-prefix:tests/unit; a=4044348251:33; st=proven;; gentle-ai-go-v1) e=go; s=module-root; a=272758782:11; st=proven;; codegraph-v1) printf '%s' 'unknown unknown scope-only none unknown'; return;; *) printf '%s' 'unknown unknown unknown none unknown'; return;; esac; pair "$1" "$2" x x "$a" "$e" "$s" || st=unknown; printf '%s %s %s %s %s' "$e" unit "$s" "$a" "$st"; }
worker() { wd=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-record.XXXXXX") || bad; chmod 700 "$wd" || bad; w=$wd/reviewed; cat > "$w" <<'EOF'
#!/bin/sh
set -eu
case "$1:$2:$3" in
shell-v1:command-declaration:README.md) grep -Fxq 'bash tests/run.sh' "$4" ;;
shell-v1:tool-proof:shell/.github/workflows/test.yml) awk 'NR==1&&$0=="      strategy:"{a=1} NR==2&&$0=="        matrix:"{b=1} NR==3&&$0=="          os: [ubuntu-latest, macos-latest]"{c=1} NR==4&&$0=="      runs-on: ${{ matrix.os }}"{d=1} NR==5&&$0=="      - name: Run regression tests"{e=1} NR==6&&$0=="        run: bash tests/run.sh"{f=1} END{exit !(NR==6&&a&&b&&c&&d&&e&&f)}' "$4" ;;
cnsic-python-v1:command-declaration:AGENTS.md) grep -Fxq 'Pre-deploy: python -m pytest tests/unit/ -n auto -q' "$4" ;;
cnsic-python-v1:tool-proof:requirements.txt) grep -Eq '^pytest[<>=!~]' "$4" && grep -Eq '^pytest-xdist[<>=!~]' "$4" ;;
gentle-ai-go-v1:command-declaration:CONTRIBUTING.md) grep -Fxq 'go test ./...' "$4" ;;
gentle-ai-go-v1:tool-proof:go.mod) awk 'NR==1&&$0=="module github.com/gentleman-programming/gentle-ai/v2"{a=1} NR==2&&$0=="go 1.25.10"{b=1} END{exit !(NR==2&&a&&b)}' "$4" ;;
codegraph-v1:scope-only:*) [ -d "$4" ] && [ ! -L "$4" ] || exit 1; for k in status scope query index-revision symbol repo-path source provenance; do [ -f "$4/$k" ] && [ ! -L "$4/$k" ] && [ "$(awk 'END { print NR }' "$4/$k")" = 1 ] && [ -n "$(awk 'NR == 1 { print; exit }' "$4/$k")" ] || exit 1; done; [ "$(awk 'NR == 1 { print; exit }' "$4/status")" = untrusted ] && [ "$(awk 'NR == 1 { print; exit }' "$4/scope")" = scope-only ] && [ "$(awk 'NR == 1 { print; exit }' "$4/repo-path")" = "$3" ] ;;
*) exit 1 ;;
esac
EOF
chmod 700 "$w" || bad; [ "$(digest "$w")" = '3823195233:1516' ] || bad; }
emit() { d=$stage/records/$(printf %03d "$n"); mkdir "$d" || bad; for pair in "schema:v1" "kind:attestation" "adapter-id:$adapter_id" "adapter-version:$adapter_version" "adapter-bytes-digest:$adapter_bytes_digest" "binding-id:$binding_id" "evidence-fact-id:$evidence_fact_id" "observation-id:$observation_id" "observation-digest:$observation_digest" "input-digest:$input_digest" "status:$status" "claim-kind:$claim_kind" "executable:$executable" "argv-digest:$argv_digest" "method:$method" "scope:$scope" "source-locator:$source_locator"; do k=${pair%%:*}; z=${pair#*:}; printf '%s\n' "$z" > "$d/$k" || bad; done; { printf 'adapter-bytes-digest=%s\n' "$adapter_bytes_digest"; printf 'adapter-id=%s\n' "$adapter_id"; printf 'adapter-version=%s\n' "$adapter_version"; printf 'argv-digest=%s\n' "$argv_digest"; printf 'binding-id=%s\n' "$binding_id"; printf 'claim-kind=%s\n' "$claim_kind"; printf 'evidence-fact-id=%s\n' "$evidence_fact_id"; printf 'executable=%s\n' "$executable"; printf 'input-digest=%s\n' "$input_digest"; printf 'method=%s\n' "$method"; printf 'observation-digest=%s\n' "$observation_digest"; printf 'observation-id=%s\n' "$observation_id"; printf 'schema=v1\n'; printf 'scope=%s\n' "$scope"; printf 'source-locator=%s\n' "$source_locator"; printf 'status=%s\n' "$status"; } > "$d/identity" || bad; id="v1:attestation:$(digest "$d/identity")"; printf '%s\n' "$id" > "$d/id"; printf '%s\n' "$id" > "$d/attestation-id"; n=$((n+1)); }
[ "$#" = 3 ] && [ "$1" = records ] || exit 2
b=$2; out=$3; [ -d "$b" ] && [ ! -L "$b" ] && [ ! -e "$out" ] && [ ! -L "$out" ] || bad
parent=$(dirname "$out"); name=$(basename "$out"); [ -d "$parent" ] && [ ! -L "$parent" ] || bad; case "$name" in ''|.*|*[!A-Za-z0-9_-]*) bad;; esac
root=$(v "$b" root); case "$root" in /*) ;; *) bad;; esac; [ -d "$root" ] && [ ! -L "$root" ] || bad
stage=$parent/.${name}.stage.$$; wd=; trap 'rm -rf "$stage" "${wd:-}"' EXIT HUP INT TERM; mkdir -m 700 "$stage" "$stage/records" || bad; n=0
worker
for bd in "$b/bindings"/*; do [ -d "$bd" ] || continue; binding_id=$(v "$bd" id); for rf in "$bd/fact-refs"/*; do [ -f "$rf" ] || continue; evidence_fact_id=$(one "$rf"); fd=$(findid "$b/facts" "$evidence_fact_id"); adapter_id=$(v "$fd" adapter); claim_kind=$(v "$fd" evidence-kind); observation_id=$(one "$fd/observation-refs/000"); [ ! -e "$fd/observation-refs/001" ] || bad; od=$(findid "$b/observations" "$observation_id"); adapter_version=v1; adapter_bytes_digest=$(digest "$w"); set -- $(profile "$bd" "$adapter_id" || printf '%s' 'unknown unknown unknown none unknown'); executable=$1; method=$2; scope=$3; argv_digest=$4; status=$5
[ -e "$fd/adapter-version" ] && [ "$(v "$fd" adapter-version)" != v1 ] && adapter_version=unknown
case "$(v "$od" channel)" in file) source_locator=$(v "$od" locator); input=$(confine "$source_locator"); set -- $(cksum "$input"); [ "$(v "$od" checksum)" = "$1 $2" ] || bad; observation_digest=$(digest "$input"); input_digest=$observation_digest; if [ "$status" = proven ] && ! "$w" "$adapter_id" "$claim_kind" "$source_locator" "$input"; then status=unknown; elif [ "$status" = proven ] && [ "$adapter_id:$claim_kind:$source_locator" = gentle-ai-go-v1:tool-proof:go.mod ]; then status=unsatisfied; fi;; codegraph) for k in status scope query index-revision symbol repo-path source provenance; do v "$od" "$k" >/dev/null; done; source_locator=$(v "$od" repo-path); safe "$source_locator"; observation_digest=$(graphdigest "$od"); input_digest=$observation_digest; executable=unknown; method=unknown; scope=scope-only; argv_digest=none; status=unknown;; *) bad;; esac
[ "$adapter_version" = v1 ] || status=unknown; case "$adapter_id" in shell-v1|cnsic-python-v1|gentle-ai-go-v1|codegraph-v1) ;; *) adapter_version=unknown; adapter_bytes_digest=none; status=unknown;; esac; emit; done; done
[ "$n" -gt 0 ] || bad; mv "$stage" "$out"; trap - EXIT HUP INT TERM
<!-- rubric-adapter-records:end -->
<!-- rubric-adapter-gate:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL; umask 077
bad() { printf '%s\n' 'invalid adapter gate input' >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad; [ "$(awk 'END {print NR}' "$1")" = 1 ] || bad; LC_ALL=C tr -d '\000' < "$1" | cmp -s "$1" - || bad; x=$(awk 'NR==1{print;exit}' "$1"); [ -n "$x" ] || bad; printf %s "$x"; }
v() { one "$1/$2"; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
hex() { od -An -v -tx1 "$1" | tr -d ' \n'; }
bundle_digest() { (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad;; esac; }
walk() { p=; rest=${1#/}; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
guard_dir() { walk "$1"; [ -d "$1" ] && [ ! -L "$1" ] || bad; }
guard_file() { walk "$1"; [ -f "$1" ] && [ ! -L "$1" ] || bad; }
guard_tree() { guard_dir "$1"; [ -z "$(find "$1" -type l -print -quit)" ] || bad; }
empty() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] && return 1; done; return 0; }
snapshot_metadata() { snap=$1; mkdir "$snap" || bad; top=; case "$root" in "$b"/*) top=${root#"$b"/}; top=${top%%/*};; esac; for e in "$b"/* "$b"/.[!.]* "$b"/..?*; do [ -e "$e" ] || continue; [ -n "$top" ] && [ "$(basename "$e")" = "$top" ] && continue; cp -a "$e" "$snap/" || bad; done; }
snapshot_records() { snap=$1; mkdir "$snap" || bad; cp -a "$rs/records" "$snap/records" || bad; }
evidence_guard() { for od in "$b/observations"/*; do [ -d "$od" ] && [ ! -L "$od" ] || bad; [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); safe "$loc"; guard_file "$live_root/$loc"; done; }
snapshot_evidence() { mkdir "$evidence" || bad; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); want=$(v "$od" checksum); src=$live_root/$loc; [ "$(cksum "$src" | awk '{print $1" "$2}')" = "$want" ] || bad; mkdir -p "$evidence/$(dirname "$loc")" || bad; cp -p "$src" "$evidence/$loc" || bad; [ "$(cksum "$evidence/$loc" | awk '{print $1" "$2}')" = "$want" ] || bad; done; }
verify_live() { evidence_guard; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); [ "$(cksum "$live_root/$loc" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] || bad; done; }
fid() { found=; for d in "$1"/*; do [ -d "$d" ] && [ "$(v "$d" id)" = "$2" ] || continue; [ -z "$found" ] || bad; found=$d; done; [ -n "$found" ] || bad; printf %s "$found"; }
argv() { for f in "$1"/*; do [ -f "$f" ] && one "$f" && printf '\n'; done | cksum | awk '{print $1":"$2}'; }
source_ok() { case "$1:$2:$3" in cnsic-python-v1:command-declaration:AGENTS.md) grep -Fxq 'Pre-deploy: python -m pytest tests/unit/ -n auto -q' "$4";; cnsic-python-v1:tool-proof:requirements.txt) grep -Eq '^pytest[<>=!~]' "$4" && grep -Eq '^pytest-xdist[<>=!~]' "$4";; shell-v1:command-declaration:README.md) grep -Fxq 'bash tests/run.sh' "$4";; shell-v1:tool-proof:shell/.github/workflows/test.yml) awk 'NR==1&&$0=="      strategy:"{a=1} NR==2&&$0=="        matrix:"{b=1} NR==3&&$0=="          os: [ubuntu-latest, macos-latest]"{c=1} NR==4&&$0=="      runs-on: ${{ matrix.os }}"{d=1} NR==5&&$0=="      - name: Run regression tests"{e=1} NR==6&&$0=="        run: bash tests/run.sh"{f=1} END{exit !(NR==6&&a&&b&&c&&d&&e&&f)}' "$4";; gentle-ai-go-v1:command-declaration:CONTRIBUTING.md) grep -Fxq 'go test ./...' "$4";; gentle-ai-go-v1:tool-proof:go.mod) awk 'NR==1&&$0=="module github.com/gentleman-programming/gentle-ai/v2"{a=1} NR==2&&$0=="go 1.25.10"{b=1} END{exit !(NR==2&&a&&b)}' "$4";; *) return 1;; esac; }
profile() { case "$1" in shell-v1) printf '%s\n' 'bash unit project-root 3407402481:13 proven .';; cnsic-python-v1) printf '%s\n' 'python unit path-prefix:tests/unit 4044348251:33 proven tests/unit';; gentle-ai-go-v1) printf '%s\n' 'go unit module-root 272758782:11';; *) bad;; esac; }
# shellcheck disable=SC2046
record() { f=$1; bd=$2; oid=$(one "$f/observation-refs/000"); [ ! -e "$f/observation-refs/001" ] && [ "$(v "$f" status)" = known ] || bad; od=$(fid "$b/observations" "$oid"); [ "$(v "$od" channel)" = file ] || bad; loc=$(v "$od" locator); input=$root/$loc; [ -f "$input" ] && [ ! -L "$input" ] && [ "$(cksum "$input" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] && source_ok "$(v "$f" adapter)" "$(v "$f" evidence-kind)" "$loc" "$input" || bad; set -- $(profile "$(v "$f" adapter)"); exe=$1 method=$2 scope=$3 ad=$4; status=${5-unsatisfied}; coverage=${6-.}; [ "$(v "$bd/context" executable)" = "$exe" ] && [ "$(v "$bd" method)" = "$method" ] && [ "$(v "$bd" scope)" = "$scope" ] && [ "$(v "$bd" signature-coverage)" = "$coverage" ] && [ "$(argv "$bd/context/argv")" = "$ad" ] || bad; found=; for r in "$rs/records"/*; do [ -d "$r" ] && [ ! -L "$r" ] || bad; [ "$(v "$r" binding-id)" = "$(v "$bd" id)" ] && [ "$(v "$r" evidence-fact-id)" = "$(v "$f" id)" ] || continue; [ -z "$found" ] || bad; found=$r; done; [ -n "$found" ] || bad; dg=$(dig "$input"); [ "$(v "$found" schema)" = v1 ] && [ "$(v "$found" kind)" = attestation ] && [ "$(v "$found" adapter-id)" = "$(v "$f" adapter)" ] && [ "$(v "$found" adapter-version)" = v1 ] && [ "$(v "$found" adapter-bytes-digest)" = 3823195233:1516 ] && [ "$(v "$found" observation-id)" = "$oid" ] && [ "$(v "$found" observation-digest)" = "$dg" ] && [ "$(v "$found" input-digest)" = "$dg" ] && [ "$(v "$found" source-locator)" = "$loc" ] && [ "$(v "$found" claim-kind)" = "$(v "$f" evidence-kind)" ] && [ "$(v "$found" executable)" = "$exe" ] && [ "$(v "$found" argv-digest)" = "$ad" ] && [ "$(v "$found" method)" = "$method" ] && [ "$(v "$found" scope)" = "$scope" ] && [ "$(v "$found" status)" = "$status" ] || bad; { for k in adapter-bytes-digest adapter-id adapter-version argv-digest binding-id claim-kind evidence-fact-id executable input-digest method observation-digest observation-id; do printf '%s=%s\n' "$k" "$(v "$found" "$k")"; done; printf 'schema=v1\nscope=%s\nsource-locator=%s\nstatus=%s\n' "$scope" "$loc" "$status"; } > "$wd/identity"; id="v1:attestation:$(dig "$wd/identity")"; cmp -s "$found/identity" "$wd/identity" && [ "$(v "$found" id)" = "$id" ] && [ "$(v "$found" attestation-id)" = "$id" ] || bad; [ "$status" = proven ] || bad; printf %s "$found"; }
v() { one "$1/$2"; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
hex() { od -An -v -tx1 "$1" | tr -d ' \n'; }
bundle_digest() { (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad;; esac; }
walk() { p=; rest=${1#/}; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
guard_dir() { walk "$1"; [ -d "$1" ] && [ ! -L "$1" ] || bad; }
guard_file() { walk "$1"; [ -f "$1" ] && [ ! -L "$1" ] || bad; }
guard_tree() { guard_dir "$1"; [ -z "$(find "$1" -type l -print -quit)" ] || bad; }
empty() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] && return 1; done; return 0; }
snapshot_metadata() { snap=$1; mkdir "$snap" || bad; top=; case "$root" in "$b"/*) top=${root#"$b"/}; top=${top%%/*};; esac; for e in "$b"/* "$b"/.[!.]* "$b"/..?*; do [ -e "$e" ] || continue; [ -n "$top" ] && [ "$(basename "$e")" = "$top" ] && continue; cp -a "$e" "$snap/" || bad; done; }
snapshot_records() { snap=$1; mkdir "$snap" || bad; cp -a "$rs/records" "$snap/records" || bad; }
evidence_guard() { for od in "$b/observations"/*; do [ -d "$od" ] && [ ! -L "$od" ] || bad; [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); safe "$loc"; guard_file "$live_root/$loc"; done; }
snapshot_evidence() { mkdir "$evidence" || bad; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); want=$(v "$od" checksum); src=$live_root/$loc; [ "$(cksum "$src" | awk '{print $1" "$2}')" = "$want" ] || bad; mkdir -p "$evidence/$(dirname "$loc")" || bad; cp -p "$src" "$evidence/$loc" || bad; [ "$(cksum "$evidence/$loc" | awk '{print $1" "$2}')" = "$want" ] || bad; done; }
verify_live() { evidence_guard; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); [ "$(cksum "$live_root/$loc" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] || bad; done; }
fid() { found=; for d in "$1"/*; do [ -d "$d" ] && [ "$(v "$d" id)" = "$2" ] || continue; [ -z "$found" ] || bad; found=$d; done; [ -n "$found" ] || bad; printf %s "$found"; }
argv() { for f in "$1"/*; do [ -f "$f" ] && one "$f" && printf '\n'; done | cksum | awk '{print $1":"$2}'; }
source_ok() { case "$1:$2:$3" in cnsic-python-v1:command-declaration:AGENTS.md) grep -Fxq 'Pre-deploy: python -m pytest tests/unit/ -n auto -q' "$4";; cnsic-python-v1:tool-proof:requirements.txt) grep -Eq '^pytest[<>=!~]' "$4" && grep -Eq '^pytest-xdist[<>=!~]' "$4";; shell-v1:command-declaration:README.md) grep -Fxq 'bash tests/run.sh' "$4";; shell-v1:tool-proof:shell/.github/workflows/test.yml) awk 'NR==1&&$0=="      strategy:"{a=1} NR==2&&$0=="        matrix:"{b=1} NR==3&&$0=="          os: [ubuntu-latest, macos-latest]"{c=1} NR==4&&$0=="      runs-on: ${{ matrix.os }}"{d=1} NR==5&&$0=="      - name: Run regression tests"{e=1} NR==6&&$0=="        run: bash tests/run.sh"{f=1} END{exit !(NR==6&&a&&b&&c&&d&&e&&f)}' "$4";; gentle-ai-go-v1:command-declaration:CONTRIBUTING.md) grep -Fxq 'go test ./...' "$4";; gentle-ai-go-v1:tool-proof:go.mod) awk 'NR==1&&$0=="module github.com/gentleman-programming/gentle-ai/v2"{a=1} NR==2&&$0=="go 1.25.10"{b=1} END{exit !(NR==2&&a&&b)}' "$4";; *) return 1;; esac; }
profile() { case "$1" in shell-v1) printf '%s\n' 'bash unit project-root 3407402481:13 proven .';; cnsic-python-v1) printf '%s\n' 'python unit path-prefix:tests/unit 4044348251:33 proven tests/unit';; gentle-ai-go-v1) printf '%s\n' 'go unit module-root 272758782:11';; *) bad;; esac; }
# shellcheck disable=SC2046
record() { f=$1; bd=$2; oid=$(one "$f/observation-refs/000"); [ ! -e "$f/observation-refs/001" ] && [ "$(v "$f" status)" = known ] || bad; od=$(fid "$b/observations" "$oid"); [ "$(v "$od" channel)" = file ] || bad; loc=$(v "$od" locator); input=$root/$loc; [ -f "$input" ] && [ ! -L "$input" ] && [ "$(cksum "$input" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] && source_ok "$(v "$f" adapter)" "$(v "$f" evidence-kind)" "$loc" "$input" || bad; set -- $(profile "$(v "$f" adapter)"); exe=$1 method=$2 scope=$3 ad=$4; status=${5-unsatisfied}; coverage=${6-.}; [ "$(v "$bd/context" executable)" = "$exe" ] && [ "$(v "$bd" method)" = "$method" ] && [ "$(v "$bd" scope)" = "$scope" ] && [ "$(v "$bd" signature-coverage)" = "$coverage" ] && [ "$(argv "$bd/context/argv")" = "$ad" ] || bad; found=; for r in "$rs/records"/*; do [ -d "$r" ] && [ ! -L "$r" ] || bad; [ "$(v "$r" binding-id)" = "$(v "$bd" id)" ] && [ "$(v "$r" evidence-fact-id)" = "$(v "$f" id)" ] || continue; [ -z "$found" ] || bad; found=$r; done; [ -n "$found" ] || bad; dg=$(dig "$input"); [ "$(v "$found" schema)" = v1 ] && [ "$(v "$found" kind)" = attestation ] && [ "$(v "$found" adapter-id)" = "$(v "$f" adapter)" ] && [ "$(v "$found" adapter-version)" = v1 ] && [ "$(v "$found" adapter-bytes-digest)" = 3823195233:1516 ] && [ "$(v "$found" observation-id)" = "$oid" ] && [ "$(v "$found" observation-digest)" = "$dg" ] && [ "$(v "$found" input-digest)" = "$dg" ] && [ "$(v "$found" source-locator)" = "$loc" ] && [ "$(v "$found" claim-kind)" = "$(v "$f" evidence-kind)" ] && [ "$(v "$found" executable)" = "$exe" ] && [ "$(v "$found" argv-digest)" = "$ad" ] && [ "$(v "$found" method)" = "$method" ] && [ "$(v "$found" scope)" = "$scope" ] && [ "$(v "$found" status)" = "$status" ] || bad; { for k in adapter-bytes-digest adapter-id adapter-version argv-digest binding-id claim-kind evidence-fact-id executable input-digest method observation-digest observation-id; do printf '%s=%s\n' "$k" "$(v "$found" "$k")"; done; printf 'schema=v1\nscope=%s\nsource-locator=%s\nstatus=%s\n' "$scope" "$loc" "$status"; } > "$wd/identity"; id="v1:attestation:$(dig "$wd/identity")"; cmp -s "$found/identity" "$wd/identity" && [ "$(v "$found" id)" = "$id" ] && [ "$(v "$found" attestation-id)" = "$id" ] || bad; [ "$status" = proven ] || bad; printf %s "$found"; }
ms() { _ms_n=$(printf %s "$1" | wc -c | tr -d ' '); printf 'S%08d' "$_ms_n"; printf %s "$1"; }
mval() { one "$1" >/dev/null; LC_ALL=C tr -d '\000' < "$1" | cmp -s "$1" - || bad; one "$1"; }
mf() { printf F; ms "$1"; ms "$2"; }
mr() { printf R; ms "$1"; ms "$2"; }
ml() { _ml_k=$1; _ml_d=$2; _ml_o=$3; _ml_t=$wd/model-list.$$; : > "$_ml_t"; for _ml_f in "$_ml_d"/*; do [ -e "$_ml_f" ] || continue; mval "$_ml_f" >> "$_ml_t"; printf '\n' >> "$_ml_t"; done; [ "$_ml_o" != set ] || LC_ALL=C sort -o "$_ml_t" "$_ml_t"; _ml_n=$(awk 'END {print NR+0}' "$_ml_t"); printf A; ms "$_ml_k"; printf '%08d' "$_ml_n"; while IFS= read -r _ml_x; do ms "$_ml_x"; done < "$_ml_t"; rm -f "$_ml_t"; }
mvs() { _mvs_k=$1; shift; printf A; ms "$_mvs_k"; printf '%08d' "$#"; for _mvs_x; do ms "$_mvs_x"; done; }
mid() { for _mid_d in "$b/$1"/*; do [ -d "$_mid_d" ] && mval "$_mid_d/id"; printf '\n'; done | LC_ALL=C sort; }
mrefs() { _mr_g=$1; _mr_d=$2; for _mr_f in "$_mr_d"/*; do [ -e "$_mr_f" ] || continue; fid "$b/$_mr_g" "$(mval "$_mr_f")" >/dev/null; done; }
mobs() { _mo_d=$1; _mo_id=$2; mr observation "$_mo_id"; mf id "$_mo_id"; mf channel "$(mval "$_mo_d/channel")"; case "$(mval "$_mo_d/channel")" in file) mf locator "$(mval "$_mo_d/locator")"; mf checksum "$(mval "$_mo_d/checksum")";; codegraph) for _mo_k in query index-revision symbol repo-path; do mf "$_mo_k" "$(mval "$_mo_d/$_mo_k")"; done;; *) bad;; esac; mf source "$(mval "$_mo_d/source")"; mf provenance "$(mval "$_mo_d/provenance")"; [ "$(mval "$_mo_d/channel")" != codegraph ] || { mf status "$(mval "$_mo_d/status")"; mf scope "$(mval "$_mo_d/scope")"; }; }
mfact() { _mf_d=$1; _mf_id=$2; mr fact "$_mf_id"; mf id "$_mf_id"; for _mf_k in status source provenance source-path evidence-kind adapter; do mf "$_mf_k" "$(mval "$_mf_d/$_mf_k")"; done; mrefs observations "$_mf_d/observation-refs"; ml observation_refs "$_mf_d/observation-refs" set; }
matt() { _ma_d=$1; _ma_id=$2; mr attestation "$_ma_id"; mf id "$_ma_id"; for _ma_k in status adapter-id adapter-version adapter-bytes-digest claim-kind executable argv-digest method scope source-locator observation-id observation-digest input-digest binding-id evidence-fact-id; do mf "$_ma_k" "$(mval "$_ma_d/$_ma_k")"; done; fid "$b/observations" "$(mval "$_ma_d/observation-id")" >/dev/null; fid "$b/bindings" "$(mval "$_ma_d/binding-id")" >/dev/null; fid "$b/facts" "$(mval "$_ma_d/evidence-fact-id")" >/dev/null; }
mbind() { _mb_d=$1; _mb_id=$2; mr binding "$_mb_id"; mf id "$_mb_id"; for _mb_k in method scope signature-coverage; do mf "$_mb_k" "$(mval "$_mb_d/$_mb_k")"; done; printf C; ms command; ms "$(mval "$_mb_d/context/executable")"; ml argv "$_mb_d/context/argv" ordered; mf executable "$(mval "$_mb_d/context/executable")"; mf workdir "$(mval "$_mb_d/context/workdir")"; ml argv "$_mb_d/context/argv" ordered; ml env "$_mb_d/context/env" set; ml platforms "$_mb_d/platforms" set; ml requirements "$_mb_d/requirements" set; mf declaration_ref "$(mval "$_mb_d/declaration-ref")"; mf tool_proof_ref "$(mval "$_mb_d/tool-proof-ref")"; fid "$b/facts" "$(mval "$_mb_d/declaration-ref")" >/dev/null; fid "$b/facts" "$(mval "$_mb_d/tool-proof-ref")" >/dev/null; mrefs facts "$_mb_d/fact-refs"; mrefs attestations "$_mb_d/attestation-refs"; ml fact_refs "$_mb_d/fact-refs" set; ml attestation_refs "$_mb_d/attestation-refs" set; }
mrow() { _mw_d=$1; _mw_id=$2; mr row "$_mw_id"; mf id "$_mw_id"; for _mw_k in state source signature mode selection trigger-kind fact-fingerprint confirmation-answer confirmer; do mf "$_mw_k" "$(mval "$_mw_d/$_mw_k")"; done; mrefs bindings "$_mw_d/binding-refs"; mrefs facts "$_mw_d/fact-refs"; mrefs attestations "$_mw_d/attestation-refs"; ml trigger_paths "$_mw_d/trigger-paths" set; ml disciplines "$_mw_d/disciplines" set; ml evidence_binding_refs "$_mw_d/binding-refs" set; ml fact_refs "$_mw_d/fact-refs" set; ml attestation_refs "$_mw_d/attestation-refs" set; }
model() { _m_out=$1; { mf schema CanonicalPolicyModelV1; mr policy policy; mf selection rubric; mf active true; mf authoritative true; mvs mode_order skip standard strict-tdd; mr resolution resolution; for _m_k in matching mode default; do mf "$_m_k" "$(mval "$b/resolution/$_m_k")"; done; mf evidence union; for _m_g in observations facts attestations bindings rows; do for _m_id in $(mid "$_m_g"); do _m_d=$(fid "$b/$_m_g" "$_m_id"); case "$_m_g" in observations) mobs "$_m_d" "$_m_id";; facts) mfact "$_m_d" "$_m_id";; attestations) matt "$_m_d" "$_m_id";; bindings) mbind "$_m_d" "$_m_id";; rows) mrow "$_m_d" "$_m_id";; esac; done; done; } > "$_m_out" || bad; }
# canonical model command dispatch
cmd=${1-}; case "$cmd" in gate|integrate) [ "$#" = 4 ] || exit 2; b=$2; rs=$3; out=$4;; verify-integrated) [ "$#" = 3 ] || exit 2; b=$2; out=$3; rs=;; *) exit 2;; esac
guard_tree "$b"; [ "$cmd" != verify-integrated ] && { guard_tree "$rs"; [ -d "$rs/records" ] && [ ! -L "$rs/records" ]; } || [ "$cmd" = verify-integrated ] || bad; [ ! -e "$out" ] && [ ! -L "$out" ] || bad; parent=$(dirname "$out"); name=$(basename "$out"); guard_dir "$parent"; case "$name" in ''|.*|*[!A-Za-z0-9_-]*) bad;; esac
lock=$parent/.${name}.lock; mkdir "$lock" || bad; root=$(v "$b" root); guard_dir "$root"; wd=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-gate.XXXXXX") || bad; chmod 700 "$wd" || bad; receipt=$parent/.${name}.receipt.$$; trap 'rm -rf "${wd:-}" "${receipt:-}"; rmdir "${lock:-}" 2>/dev/null || :' EXIT HUP INT TERM; snapshot_metadata "$wd/candidate"; if [ "$cmd" = verify-integrated ]; then mkdir "$wd/record-set" || bad; cp -a "$b/attestations" "$wd/record-set/records" || bad; else snapshot_records "$wd/record-set"; fi; b=$wd/candidate; rs=$wd/record-set; validator=$wd/rubric-validator
  cat > "$validator" <<'EOF'
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL
b=${1-}; [ "$#" = 1 ] && [ -d "$b" ] || exit 2
bad() { printf '%s\n' "invalid rubric structure: $*" >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad scalar; awk 'END { exit NR != 1 }' "$1" || bad scalar; IFS= read -r _one < "$1" || :; [ -n "${_one-}" ] || bad scalar; printf %s "$_one"; }
v() { one "$1/$2"; }
has() { case " $1 " in *" $2 "*) return 0;; *) return 1;; esac; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad path;; esac; }
walk() { _walk_p=; _walk_rest=${1#/}; while [ -n "$_walk_rest" ]; do _walk_part=${_walk_rest%%/*}; case "$_walk_rest" in */*) _walk_rest=${_walk_rest#*/};; *) _walk_rest=;; esac; _walk_p=$_walk_p/$_walk_part; [ ! -L "$_walk_p" ] || bad symlink; done; }
confine() { _conf_rel=$1; _conf_type=$2; safe "$_conf_rel"; walk "$root"; _conf_p=$root; _conf_rest=$_conf_rel; while [ -n "$_conf_rest" ]; do _conf_part=${_conf_rest%%/*}; case "$_conf_rest" in */*) _conf_rest=${_conf_rest#*/};; *) _conf_rest=;; esac; _conf_p=$_conf_p/$_conf_part; [ ! -L "$_conf_p" ] || bad symlink; done; case "$_conf_type" in f) [ -f "$_conf_p" ];; d) [ -d "$_conf_p" ];; esac || bad target; }
list() { _list_d=$1; _list_min=${2-1}; [ -d "$_list_d" ] && [ ! -L "$_list_d" ] || bad list; _list_n=0; for _list_f in "$_list_d"/*; do [ -e "$_list_f" ] || continue; [ -f "$_list_f" ] && [ ! -L "$_list_f" ] || bad list; [ "$(basename "$_list_f")" = "$(printf %03d "$_list_n")" ] || bad order; one "$_list_f" >/dev/null; _list_n=$((_list_n+1)); done; [ "$_list_n" -ge "$_list_min" ] || bad list; n=$_list_n; }
refs() { _refs_d=$1; _refs_all=$2; list "$_refs_d" "${3-1}"; for _refs_f in "$_refs_d"/*; do [ -e "$_refs_f" ] || continue; has "$_refs_all" "$(one "$_refs_f")" || bad "reference:$_refs_d"; done; }
inlist() { for _in_f in "$1"/*; do [ -e "$_in_f" ] && [ "$(one "$_in_f")" = "$2" ] && return 0; done; return 1; }
id() { _id_d=$1; _id_k=$(v "$_id_d" kind); case "$_id_k" in ''|*[!a-z-]*) bad kind;; esac; set -- $(cksum "$_id_d/identity"); _id_want="v1:$_id_k:$1:$2"; [ "$(v "$_id_d" id)" = "$_id_want" ] || bad id; printf %s "$_id_want"; }
fp() { (cd "$1" && find . -type f ! -name id ! -name identity ! -name fingerprint -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1 ":" $2}'; }
fps() { for f in "$1"/*; do [ -e "$f" ] || continue; x=$(one "$f"); for d in "$b/facts/"*; do [ "$(v "$d" id)" = "$x" ] && printf '%s:%s\n' "$x" "$(fp "$d")"; done; done | cksum | awk '{print $1 ":" $2}'; }
uniq() { has "$seen" "$1" && bad duplicate; seen="$seen $1"; all="$all $1"; }
records() { _rec_top=$1; _rec_min=$2; _rec_fn=$3; [ -d "$_rec_top" ] && [ ! -L "$_rec_top" ] || bad records; _rec_n=0; for _rec_d in "$_rec_top"/*; do [ -e "$_rec_d" ] || continue; [ -d "$_rec_d" ] && [ ! -L "$_rec_d" ] || bad records; "$_rec_fn" "$_rec_d"; _rec_n=$((_rec_n+1)); done; [ "$_rec_n" -ge "$_rec_min" ] || bad records; }
[ "$(v "$b" schema)" = v1 ] && [ "$(v "$b" candidate-schema)" = v1 ] || bad schema
find "$b" -name provider -print | grep . >/dev/null && bad provider
root=$(v "$b" root); case "$root" in /*) ;; *) bad root;; esac; case "$root" in *'*'*|*'?'*|*'['*) bad root;; esac; [ -d "$root" ] && [ ! -L "$root" ] || bad root; walk "$root"
[ "$(v "$b/resolution" matching)" = all-rows ] && [ "$(v "$b/resolution" mode)" = strictest-wins ] && [ "$(v "$b/resolution" default)" = unmatched-only ] || bad resolution
seen= all= obs= facts= bindings= attestations= rows= defaults=0
obsrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" channel)" in file) loc=$(v "$d" locator); confine "$loc" f; set -- $(cksum "$root/$loc"); [ "$(v "$d" checksum)" = "$1 $2" ] || bad checksum;; codegraph) [ "$(v "$d" status)" = untrusted ] && [ "$(v "$d" scope)" = scope-only ] || bad codegraph; v "$d" query >/dev/null; v "$d" index-revision >/dev/null; v "$d" symbol >/dev/null; safe "$(v "$d" repo-path)";; *) bad observation;; esac; v "$d" source >/dev/null; v "$d" provenance >/dev/null; obs="$obs $x"; }
factrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" status)" in known|unknown|absent|unsatisfied) ;; *) bad fact;; esac; [ ! -e "$d/provider" ] || bad provider; v "$d" source >/dev/null; v "$d" provenance >/dev/null; v "$d" source-path >/dev/null; v "$d" evidence-kind >/dev/null; v "$d" adapter >/dev/null; refs "$d/observation-refs" "$obs"; [ "$(v "$d" fingerprint)" = "$(fp "$d")" ] || bad fingerprint; facts="$facts $x"; }
attrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" schema)" = v1 ] && [ "$(v "$d" attestation-id)" = "$x" ] || bad attestation; for k in adapter-id adapter-version adapter-bytes-digest input-digest status claim-kind executable method scope; do v "$d" "$k" >/dev/null; done; oi=$(v "$d" observation-id); [ ! -e "$d/observation-refs" ] && [ -n "$oi" ] && has "$obs" "$oi" || bad reference; safe "$(v "$d" source-locator)"; attestations="$attestations $x"; }
bindrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" method)" in unit|integration|e2e|coverage|lint|typecheck|format|build) ;; *) bad method;; esac; v "$d" scope >/dev/null; v "$d" signature-coverage >/dev/null; [ -d "$d/context" ] && [ ! -L "$d/context" ] || bad context; [ "$(v "$d/context" root)" = "$root" ] || bad root; [ "$(v "$d/context" workdir)" = . ] || confine "$(v "$d/context" workdir)" d; v "$d/context" executable >/dev/null; list "$d/context/argv"; list "$d/platforms"; list "$d/env" 0; list "$d/requirements" 0; refs "$d/fact-refs" "$facts"; dr=$(v "$d" declaration-ref); tr=$(v "$d" tool-proof-ref); [ "$dr" != "$tr" ] && inlist "$d/fact-refs" "$dr" && inlist "$d/fact-refs" "$tr" || bad reference; refs "$d/attestation-refs" "$attestations" 0; bindings="$bindings $x"; }
bindpath() { for _bind_d in "$b/bindings/"*; do [ "$(v "$_bind_d" id)" = "$1" ] && { printf %s "$_bind_d"; return; }; done; bad reference; }
linked() { _link_row=$1; _link_kind=$2; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); for _link_item in "$_link_bind/$_link_kind/"*; do [ -e "$_link_item" ] && inlist "$_link_row/$_link_kind" "$(one "$_link_item")" || bad link; done; done; for _link_item in "$_link_row/$_link_kind/"*; do [ -e "$_link_item" ] || continue; _link_found=; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); inlist "$_link_bind/$_link_kind" "$(one "$_link_item")" && _link_found=1; done; [ -n "$_link_found" ] || bad link; done; }
rowrec() { d=$1; x=$(id "$d"); uniq "$x"; m=$(v "$d" mode); case "$m" in skip|standard|strict-tdd) ;; *) bad mode;; esac; st=$(v "$d" state); case "$st" in pending|confirmed|rejected|stale|conflict) ;; *) bad state;; esac; case "$(v "$d" source)" in generated|manual) ;; *) bad source;; esac; sel=$(v "$d" selection); list "$d/trigger-paths" 0; if [ "$sel" = unmatched-only ]; then [ "$(v "$d" signature)" = default ] && [ "$(v "$d" trigger-kind)" = unmatched ] && [ "$n" = 0 ] || bad default; defaults=$((defaults+1)); else [ "$sel" = specific ] && [ "$(v "$d" trigger-kind)" = path ] && [ "$n" -gt 0 ] || bad trigger; fi; refs "$d/fact-refs" "$facts"; [ "$(v "$d" fact-fingerprint)" = "$(fps "$d/fact-refs")" ] || bad fingerprint; list "$d/disciplines" 0; refs "$d/binding-refs" "$bindings" 0; bn=$n; refs "$d/attestation-refs" "$attestations" 0; an=$n; [ "$m" = skip ] || { [ "$bn" -gt 0 ] && [ "$an" -gt 0 ] && linked "$d" fact-refs && linked "$d" attestation-refs; } || bad attestation; [ "$st" != confirmed ] || { v "$d" confirmation-answer >/dev/null; v "$d" confirmer >/dev/null; }; rows="$rows $x"; }
qrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" kind)" = question ] && [ "$(v "$d" blocking)" = true ] || bad question; v "$d" prompt >/dev/null; case "$(v "$d" state)" in open|answered|rejected) ;; *) bad question;; esac; refs "$d/fact-refs" "$facts"; list "$d/allowed-answers"; has "$rows" "$(v "$d" row-ref)" || bad reference; }
rowpath() { for _row_d in "$b/rows/"*; do [ "$(v "$_row_d" id)" = "$1" ] && { printf %s "$_row_d"; return; }; done; bad reference; }
reinitrec() { d=$1; rr=$(v "$d" row-ref); rd=$(rowpath "$rr"); prior=$(v "$d" prior-fingerprint); now=$(fps "$rd/fact-refs"); case "$(v "$d" state)" in preserved) [ "$prior" = "$now" ] || bad reinit;; stale) [ "$prior" != "$now" ] && [ "$(v "$rd" state)" = stale ] || bad reinit;; *) bad reinit;; esac; }
records "$b/observations" 1 obsrec; records "$b/facts" 1 factrec; records "$b/attestations" 0 attrec; records "$b/bindings" 0 bindrec; records "$b/rows" 1 rowrec; [ "$defaults" = 1 ] || bad default; records "$b/questions" 0 qrec
for d in "$b/rows"/*; do [ -e "$d" ] || continue; st=$(v "$d" state); case "$st" in pending|stale|conflict) found=; for q in "$b/questions"/*; do [ -d "$q" ] && [ "$(v "$q" row-ref)" = "$(v "$d" id)" ] && [ "$(v "$q" state)" = open ] && [ "$(v "$q" blocking)" = true ] && found=1; done; [ -n "$found" ] || bad question;; esac; done
records "$b/reinit" 0 reinitrec; refs "$b/record-order" "$all"; [ "$n" = "$(set -- $all; printf %s "$#")" ] || bad order; prev=; for f in "$b/record-order"/*; do [ -e "$f" ] || continue; x=$(one "$f"); [ -z "$prev" ] || [ "$prev" \< "$x" ] || bad order; prev=$x; done
printf 'structure-valid/pending\n'
EOF
chmod 700 "$validator" || bad; [ "$(dig "$validator")" = 4105381479:9297 ] || bad; "$validator" "$b" >/dev/null || bad
live_root=$(v "$b" root); evidence=$wd/evidence; evidence_guard; snapshot_evidence; root=$evidence; n=0; for bd in "$b/bindings"/*; do [ -d "$bd" ] || continue; [ "$(v "$bd/context" workdir)" = . ] && empty "$bd/context/env" || bad; dr=$(fid "$b/facts" "$(v "$bd" declaration-ref)"); pr=$(fid "$b/facts" "$(v "$bd" tool-proof-ref)"); [ "$dr" != "$pr" ] && [ "$(v "$dr" evidence-kind)" = command-declaration ] && [ "$(v "$pr" evidence-kind)" = tool-proof ] && [ "$(v "$dr" adapter)" = "$(v "$pr" adapter)" ] || bad; d=$(record "$dr" "$bd"); p=$(record "$pr" "$bd"); [ "$d" != "$p" ] && [ "$(v "$d" observation-id)" != "$(v "$p" observation-id)" ] && [ "$(v "$d" source-locator)" != "$(v "$p" source-locator)" ] || bad; n=$((n+2)); done
 [ "$n" -gt 0 ] && [ "$(find "$rs/records" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = "$n" ] || bad
 verify_live; [ ! -e "$out" ] && [ ! -L "$out" ] || bad; [ "$cmd" = gate ] && { printf 'semantic-valid/pending\n' > "$receipt" || bad; mv "$receipt" "$out" || bad; rm -rf "$wd"; rmdir "$lock" || bad; trap - EXIT HUP INT TERM; exit 0; }
 if [ "$cmd" = verify-integrated ]; then [ ! -e "$b/activation/unit1a-result" ] && [ ! -e "$b/activation/semantic-result" ] || bad; for d in "$b"/rows/*; do [ "$(v "$d" state)" = confirmed ] && v "$d" confirmation-answer >/dev/null && v "$d" confirmer >/dev/null || bad; done; for d in "$b"/questions/*; do [ "$(v "$d" state)" = answered ] || bad; done; for d in "$b"/facts/*; do [ "$(v "$d" status)" = known ] || bad; done; for d in "$b"/attestations/*; do [ "$(v "$d" status)" = proven ] || bad; done; model=$wd/canonical-model; model "$model"; bd=$(bundle_digest "$b"); sd=$(for g in facts attestations bindings rows questions; do for d in "$b/$g"/*; do v "$d" id; printf '\n'; done; done | LC_ALL=C sort | cksum | awk '{print $1":"$2}'); md=$(dig "$model"); printf 'schema=IntegratedValidationV1\nstate=verified\ngate_version=v1\ngate_digest=%s\nintegrated_bundle_digest=%s\nsemantic_digest=%s\ncanonical_model_bytes=hex:%s\ncanonical_model_digest=%s\ncommits=none\n' "$(dig "$0")" "$bd" "$sd" "$(hex "$model")" "$md" > "$receipt" || bad; mv "$receipt" "$out" || bad; rm -rf "$wd"; rmdir "$lock" || bad; trap - EXIT HUP INT TERM; exit 0; fi
 stage=$parent/.${name}.stage.$$; trap 'rm -rf "${wd:-}" "${receipt:-}" "${stage:-}"; rmdir "${lock:-}" 2>/dev/null || :' EXIT HUP INT TERM; mkdir -m 700 "$stage" || bad; cp -a "$b"/. "$stage"/. || bad; chmod 700 "$stage" || bad
 put() { printf '%s\n' "$2" > "$1" || bad; }
 reset() { _reset_d=$1; shift; rm -rf "$_reset_d"; mkdir "$_reset_d" || bad; _reset_i=0; for _reset_x; do put "$_reset_d/$(printf '%03d' "$_reset_i")" "$_reset_x"; _reset_i=$((_reset_i+1)); done; }
  cid() { d=$1; t=$2; (cd "$d" && find . -type f ! -name id ! -name identity ! -name fingerprint ! -name attestation-id -print | LC_ALL=C sort | while IFS= read -r f; do case "$t:$f" in binding:./attestation-refs/*) continue;; esac; printf '%s=' "$f"; cat "$f"; done) > "$d/identity" || bad; k=$(v "$d" kind); put "$d/id" "v1:$k:$(dig "$d/identity")"; [ ! -e "$d/attestation-id" ] || put "$d/attestation-id" "$(v "$d" id)"; }
  attid() { d=$1; { for k in adapter-bytes-digest adapter-id adapter-version argv-digest binding-id claim-kind evidence-fact-id executable input-digest method observation-digest observation-id schema scope source-locator status; do printf '%s=%s\n' "$k" "$(v "$d" "$k")"; done; } > "$d/identity" || bad; x="v1:attestation:$(dig "$d/identity")"; put "$d/id" "$x"; put "$d/attestation-id" "$x"; }
 finger() { (cd "$1" && find . -type f ! -name id ! -name identity ! -name fingerprint -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
 rowfp() { for f in "$1"/*; do [ -e "$f" ] || continue; x=$(one "$f"); for d in "$stage/facts"/*; do [ "$(v "$d" id)" = "$x" ] && printf '%s:%s\n' "$x" "$(finger "$d")"; done; done | cksum | awk '{print $1":"$2}'; }
 rm -rf "$stage/attestations"; mkdir "$stage/attestations" || bad; i=0; for d in "$rs/records"/*; do [ -d "$d" ] && [ ! -L "$d" ] || bad; cp -a "$d" "$stage/attestations/$(printf '%03d' "$i")" || bad; i=$((i+1)); done
 map=$wd/bindings; : > "$map"; for d in "$stage/bindings"/*; do old=$(v "$d" id); cid "$d" binding; printf '%s %s\n' "$old" "$(v "$d" id)" >> "$map"; done
  for d in "$stage/attestations"/*; do old=$(v "$d" binding-id); new=$(awk -v x="$old" '$1==x{print $2}' "$map"); [ -n "$new" ] || bad; put "$d/binding-id" "$new"; attid "$d"; done
 for d in "$stage/bindings"/*; do set --; for a in "$stage/attestations"/*; do [ "$(v "$a" binding-id)" = "$(v "$d" id)" ] && set -- "$@" "$(v "$a" id)"; done; [ "$#" -gt 0 ] || bad; reset "$d/attestation-refs" "$@"; done
 rmap=$wd/rows; : > "$rmap"; for d in "$stage/rows"/*; do for f in "$d/binding-refs"/*; do [ -e "$f" ] || continue; old=$(one "$f"); new=$(awk -v x="$old" '$1==x{print $2}' "$map"); [ -n "$new" ] || bad; put "$f" "$new"; done; set --; for f in "$d/binding-refs"/*; do [ -e "$f" ] || continue; bd=$(fid "$stage/bindings" "$(one "$f")"); for a in "$bd/attestation-refs"/*; do set -- "$@" "$(one "$a")"; done; done; reset "$d/attestation-refs" "$@"; put "$d/fact-fingerprint" "$(rowfp "$d/fact-refs")"; old=$(v "$d" id); cid "$d" row; printf '%s %s\n' "$old" "$(v "$d" id)" >> "$rmap"; done
 for d in "$stage/questions"/*; do old=$(v "$d" row-ref); new=$(awk -v x="$old" '$1==x{print $2}' "$rmap"); [ -n "$new" ] || bad; put "$d/row-ref" "$new"; cid "$d" question; done
 for d in "$stage/reinit"/*; do old=$(v "$d" row-ref); new=$(awk -v x="$old" '$1==x{print $2}' "$rmap"); [ -n "$new" ] || bad; put "$d/row-ref" "$new"; done
 for d in "$stage/facts"/*; do put "$d/fingerprint" "$(finger "$d")"; done; for d in "$stage/rows"/*; do put "$d/fact-fingerprint" "$(rowfp "$d/fact-refs")"; done
 rm -rf "$stage/record-order"; mkdir "$stage/record-order" || bad; (for g in observations facts attestations bindings rows questions; do for d in "$stage/$g"/*; do v "$d" id; printf '\n'; done; done) | LC_ALL=C sort | { i=0; while IFS= read -r x; do put "$stage/record-order/$(printf '%03d' "$i")" "$x"; i=$((i+1)); done; }
  semantic=$stage/semantic-records; mkdir "$semantic" || bad; cp -a "$stage/attestations" "$semantic/records" || bad; b=$stage; rs=$semantic; root=$evidence; n=0; for bd in "$b/bindings"/*; do [ -d "$bd" ] || continue; [ "$(v "$bd/context" workdir)" = . ] && empty "$bd/context/env" || bad; dr=$(fid "$b/facts" "$(v "$bd" declaration-ref)"); pr=$(fid "$b/facts" "$(v "$bd" tool-proof-ref)"); [ "$dr" != "$pr" ] && [ "$(v "$dr" evidence-kind)" = command-declaration ] && [ "$(v "$pr" evidence-kind)" = tool-proof ] && [ "$(v "$dr" adapter)" = "$(v "$pr" adapter)" ] || bad; d=$(record "$dr" "$bd"); p=$(record "$pr" "$bd"); [ "$d" != "$p" ] && [ "$(v "$d" observation-id)" != "$(v "$p" observation-id)" ] && [ "$(v "$d" source-locator)" != "$(v "$p" source-locator)" ] || bad; n=$((n+2)); done; [ "$n" -gt 0 ] && [ "$(find "$rs/records" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = "$n" ] || bad
  verify_live; "$validator" "$stage" >/dev/null || bad; [ ! -e "$out" ] && [ ! -L "$out" ] || bad; mv "$stage" "$out" || bad; rm -rf "$wd" "$receipt"; rmdir "$lock" || bad; trap - EXIT HUP INT TERM
<!-- rubric-adapter-gate:end -->
<!-- rubric-consumer-gate:start -->
#!/bin/sh
# Validates persisted activation evidence before one orchestrator resolution.
set -eu
LC_ALL=C; export LC_ALL
dig() { cksum "$1" | awk '{print $1":"$2}'; }
count() { awk -v p="$2" '$0 ~ p{n++}END{print n+0}' "$1"; }
kv() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1)print v;else exit 1}' "$1"; }
yv() { awk -v k="$2" '$0 ~ "^    " k ": \"" {n++;v=$0;sub("^    " k ": \\\"","",v);sub("\\\"$","",v)}END{if(n==1)print v;else exit 1}' "$1"; }
safe() { case "$1" in ''|*[!A-Za-z0-9._:-]*) return 1;; esac; }
out() { printf 'schema=RubricConsumerEnvelopeV1\nbackend=%s\nmode=%s\nstate=%s\ntxn_id=%s\ncanonical_model_digest=%s\nresolution_owner=orchestrator\n' "$1" "$mode" "$2" "$3" "$4"; }
blocked() { printf 'schema=RubricConsumerBlockedV1\nbackend=%s\nobserved_state=%s\nmismatch=%s\nrecovery_action=run sdd-init recovery\n' "$1" "$2" "$3"; exit 1; }
obs() { x=${1-none}; safe "$x" && printf %s "$x" || printf none; }
needkv() { [ "$(count "$1" "^$2=")" = 1 ] || return 1; kv "$1" "$2"; }
needyaml() { [ "$(awk -v k="$2" '$0 ~ "^    " k ": \""{n++}END{print n+0}' "$1")" = 1 ] || return 1; yv "$1" "$2"; }
oscheck() {
  c=$1/config r=$1/resolution; [ -f "$c" ] && [ -f "$r" ] || blocked openspec none outage
  [ "$(count "$c" '^  policy: "rubric"$')" = 1 ] || blocked openspec none absent
  [ "$(count "$c" '^  methods:')" = 0 ] || blocked openspec active parallel-methods
  n=$(count "$c" '^    schema: "'); [ "$n" = 1 ] || { [ "$n" = 0 ] && blocked openspec none malformed || blocked openspec none duplicate; }
  st=$(needyaml "$c" state 2>/dev/null || :); case "$st" in staging|recovery-required) blocked openspec "$st" "$st";; esac
  for k in schema state txn_id authority canonical_model_digest; do v=$(needyaml "$c" "$k" 2>/dev/null || :); [ -n "$v" ] && safe "$v" || blocked openspec "$(obs "$st")" malformed; case "$k" in schema) o_schema=$v;; state) o_state=$v;; txn_id) o_txn_id=$v;; authority) o_authority=$v;; canonical_model_digest) o_canonical_model_digest=$v;; esac; done
  [ "$o_schema:$o_state:$o_authority" = ResolutionV1:active:openspec ] || blocked openspec "$(obs "$o_state")" state-mismatch
  for k in schema state txn_id authority canonical_model_digest backend_config_digest readback; do v=$(needkv "$r" "$k" 2>/dev/null || :); [ -n "$v" ] && safe "$v" || blocked openspec "$(obs "$o_state")" malformed; case "$k" in schema) r_schema=$v;; state) r_state=$v;; txn_id) r_txn_id=$v;; authority) r_authority=$v;; canonical_model_digest) r_canonical_model_digest=$v;; backend_config_digest) r_backend_config_digest=$v;; readback) r_readback=$v;; esac; done
  [ "$r_schema:$r_state:$r_authority" = ResolutionV1:active:openspec ] || blocked openspec "$(obs "$r_state")" state-mismatch
  [ "$o_txn_id" = "$r_txn_id" ] || blocked openspec "$(obs "$o_state")" txn-mismatch
  [ "$o_canonical_model_digest" = "$r_canonical_model_digest" ] || blocked openspec "$(obs "$o_state")" model-mismatch
  [ "$r_backend_config_digest" = "$(dig "$c")" ] || blocked openspec "$(obs "$o_state")" backend-mismatch
  [ "$r_readback" = verified ] || blocked openspec "$(obs "$o_state")" readback-invalid
  TX=$o_txn_id MD=$o_canonical_model_digest
}
echeck() {
  f=$1 auth=$2 backend=$3; [ -f "$f" ] || blocked "$backend" none outage
  n=$(count "$f" '^schema=ActivationStateV1$'); [ "$n" = 1 ] || { [ "$n" = 0 ] && blocked "$backend" none malformed || blocked "$backend" none duplicate; }
  st=$(needkv "$f" state 2>/dev/null || :); case "$st" in staging|recovery-required) blocked "$backend" "$st" "$st";; esac
  for k in schema state txn_id authority canonical_model_digest backend_payload_digest committed_revision backend_revision readback; do v=$(needkv "$f" "$k" 2>/dev/null || :); [ -n "$v" ] && safe "$v" || blocked "$backend" "$(obs "$st")" malformed; case "$k" in schema) e_schema=$v;; state) e_state=$v;; txn_id) e_txn_id=$v;; authority) e_authority=$v;; canonical_model_digest) e_canonical_model_digest=$v;; backend_payload_digest) e_backend_payload_digest=$v;; committed_revision) e_committed_revision=$v;; backend_revision) e_backend_revision=$v;; readback) e_readback=$v;; esac; done
  [ "$e_schema:$e_state:$e_authority" = "ActivationStateV1:active:$auth" ] || blocked "$backend" "$(obs "$e_state")" state-mismatch
  [ "$e_committed_revision" = "$e_backend_revision" ] && [ "$e_readback" = verified ] || blocked "$backend" "$(obs "$e_state")" readback-invalid
  awk '/^```text$/{p=1;next}p&&/^```$/{exit}p{print}' "$f" > "$tmp/model"
  [ "$(dig "$tmp/model")" = "$e_backend_payload_digest" ] && [ "$e_canonical_model_digest" = "$e_backend_payload_digest" ] || blocked "$backend" "$(obs "$e_state")" model-mismatch
  TX=$e_txn_id MD=$e_canonical_model_digest
}
cmd=${1-}; phase=${2-}; mode=${3-}; od=${4-}; ef=${5-}; sf=${6-}; [ "$cmd" = consume ] && [ "$#" = 6 ] || exit 2
case "$phase:$mode" in apply:openspec|verify:openspec|apply:engram|verify:engram|apply:hybrid|verify:hybrid|apply:none|verify:none|apply:legacy|verify:legacy) ;; *) exit 2;; esac
tmp=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-consumer.XXXXXX") || exit 1; trap 'rm -rf "$tmp"' EXIT HUP INT TERM
case "$mode" in
  openspec) oscheck "$od"; out openspec active "$TX" "$MD";;
  engram) echeck "$ef" engram engram; out engram active "$TX" "$MD";;
  hybrid) oscheck "$od"; ot=$TX om=$MD; echeck "$ef" openspec both; [ "$ot:$om" = "$TX:$MD" ] || blocked both active "$( [ "$ot" = "$TX" ] && printf model-mismatch || printf txn-mismatch )"; out both active "$TX" "$MD";;
  none) [ -f "$sf" ] || blocked session none outage; for k in schema state commits current_session txn_id canonical_model_digest; do needkv "$sf" "$k" >/dev/null 2>&1 || blocked session none malformed; done; [ "$(kv "$sf" schema):$(kv "$sf" state):$(kv "$sf" commits):$(kv "$sf" current_session)" = IntegratedValidationV1:verified:none:true ] || blocked session "$(obs "$(kv "$sf" state 2>/dev/null || :)")" state-mismatch; out session candidate none "$(kv "$sf" canonical_model_digest)";;
  legacy) seen=; [ -f "$od/config" ] && grep -Eq 'policy: "rubric"|ResolutionV1' "$od/config" && seen=1; [ -f "$ef" ] && grep -q 'ActivationStateV1' "$ef" && seen=1; [ -z "$seen" ] || blocked legacy none absent; mode=binary; out legacy legacy none none;;
esac
<!-- rubric-consumer-gate:end -->
<!-- rubric-activation:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL; umask 077
PINNED_GATE_DIGEST=2444152548:34834
committed=0; target=; old=
restore() { [ "$committed" = 1 ] || return 0; cp -- "$old" "$target" && cmp -s "$old" "$target"; }
bad() { [ "$committed" != 1 ] || restore || :; printf '%s\n' 'invalid rubric activation input' >&2; exit 1; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
walk() { p=; r=${1#/}; while [ -n "$r" ]; do x=${r%%/*}; case "$r" in */*) r=${r#*/};; *) r=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
reg() { walk "$1"; [ -f "$1" ] && [ ! -L "$1" ] || bad; }
dir() { walk "$1"; [ -d "$1" ] && [ ! -L "$1" ] || bad; }
one() { reg "$1"; [ "$(awk 'END{print NR}' "$1")" = 1 ] || bad; x=$(awk 'NR==1{print;exit}' "$1"); [ -n "$x" ] || bad; printf %s "$x"; }
field() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1)print v;else exit 1}' "$1" || bad; }
bundle_digest() { (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
path() { g=$1; id=$2; found=; for d in "$b/$g"/*; do [ -d "$d" ] && [ "$(one "$d/id")" = "$id" ] || continue; [ -z "$found" ] || bad; found=$d; done; [ -n "$found" ] || bad; printf %s "$found"; }
ids() { for d in "$b/$1"/*; do [ -d "$d" ] && one "$d/id"; printf '\n'; done | LC_ALL=C sort; }
q() { one "$1" >/dev/null; printf '"'; one "$1" | od -An -v -tx1 | while IFS= read -r h; do for x in $h; do case "$x" in 22) printf '\\"';; 5c) printf '\\\\';; 08) printf '\\b';; 09) printf '\\t';; 0[0-7]|0[be-f]|1[0-9a-f]) printf '\\u00%s' "$x";; 20|2[1-9a-f]|[3-7][0-9a-f]) printf "$(printf '\\%03o' "0x$x")";; *) bad;; esac; done; done; printf '"'; }
kv() { printf '%s%s: ' "$1" "$2"; q "$3"; printf '\n'; }
seq() { printf '%s%s:\n' "$1" "$2"; for f in "$3"/*; do [ -e "$f" ] || continue; printf '%s- ' "$1  "; q "$f"; printf '\n'; done; }
yaml() { y=$1; { printf 'testing:\n  # gentle-ai:managed-testing:start\n  policy: "rubric"\n  rubric:\n    active: true\n    authoritative: true\n    mode_order:\n      - "skip"\n      - "standard"\n      - "strict-tdd"\n    resolution:\n'; kv '      ' matching "$b/resolution/matching"; kv '      ' mode "$b/resolution/mode"; printf '      evidence: "union"\n'; kv '      ' default "$b/resolution/default"; printf '    bindings:\n'; for id in $(ids bindings); do d=$(path bindings "$id"); printf '      - id: '; q "$d/id"; printf '\n'; for k in method scope signature-coverage; do kv '        ' "$k" "$d/$k"; done; printf '        command:\n          executable: '; q "$d/context/executable"; printf '\n          argv:\n'; for f in "$d/context/argv"/*; do [ -e "$f" ] || continue; printf '            - '; q "$f"; printf '\n'; done; kv '          ' workdir "$d/context/workdir"; printf '          env:\n'; for f in "$d/context/env"/*; do [ -e "$f" ] || continue; printf '            - '; q "$f"; printf '\n'; done; for k in declaration-ref tool-proof-ref; do kv '        ' "$k" "$d/$k"; done; for k in fact-refs attestation-refs; do seq '        ' "$k" "$d/$k"; done; done; printf '    rows:\n'; for id in $(ids rows); do d=$(path rows "$id"); printf '      - id: '; q "$d/id"; printf '\n'; for k in signature mode selection trigger-kind source; do kv '        ' "$k" "$d/$k"; done; for k in trigger-paths disciplines binding-refs fact-refs attestation-refs; do seq '        ' "$k" "$d/$k"; done; done; printf '  # gentle-ai:managed-testing:end\n'; } > "$y" || bad; }
scan() { reg "$1"; LC_ALL=C grep -q "$(printf '\r')" "$1" && bad; grep -q "$(printf '\t')" "$1" && bad; [ "$(tail -c 1 "$1" | od -An -tx1 | tr -d ' \n')" = 0a ] || bad; grep -Eq '^(---|\.\.\.)$|(^|[[:space:]])(&|!|\*|<<:)' "$1" && bad || :; t=$(awk '/^testing:[[:space:]]*$/{n++;x=NR}END{if(n==1)print x;else exit 1}' "$1") || bad; s=$(awk '/^strict_tdd:[[:space:]]+false[[:space:]]*$/{n++;x=NR}END{if(n==1)print x;else exit 1}' "$1") || bad; e=$(awk -v n="$t" 'NR>n&&/^[A-Za-z_][A-Za-z0-9_-]*:/{print NR;exit}' "$1"); [ -n "$e" ] && [ "$s" -ne "$t" ] || bad; awk -v a="$t" -v z="$e" 'NR>=a&&NR<z&&/[>|][+-]?[[:space:]]*($|#)/{bad=1}END{exit !bad}' "$1" && bad || :; ms=$(grep -c '^  # gentle-ai:managed-testing:start$' "$1" || :); me=$(grep -c '^  # gentle-ai:managed-testing:end$' "$1" || :); { [ "$ms:$me" = 0:0 ] || { [ "$ms:$me" = 1:1 ] && awk -v a="$t" -v z="$e" '/^  # gentle-ai:managed-testing:start$/{s=NR}/^  # gentle-ai:managed-testing:end$/{e=NR}END{exit !(s>a&&s<z&&e>s&&e<z)}' "$1"; }; } || bad; }
emit() { printf 'schema=ResolutionV1\nproject=%s\nmode=%s\nstate=%s\ntxn_id=%s\ngate_digest=%s\nintegrated_bundle_digest=%s\ncanonical_model_digest=%s\nbackend_config_digest=%s\ncommits=%s\n' "$project" "$mode" "$state" "$txn" "$gd" "$bd" "$md" "$backend" "$commits"; }
verify_gate() { reg "$gate"; [ "$(dig "$gate")" = "$PINNED_GATE_DIGEST" ] || bad; cp -- "$gate" "$w/gate" || bad; chmod 700 "$w/gate"; cp -a "$bundle" "$w/candidate" || bad; "$w/gate" verify-integrated "$w/candidate" "$w/integrated" || bad; gd=$(field "$w/integrated" gate_digest); bd=$(field "$w/integrated" integrated_bundle_digest); md=$(field "$w/integrated" canonical_model_digest); [ "$gd" = "$PINNED_GATE_DIGEST" ] && [ "$bd" = "$(bundle_digest "$w/candidate")" ] || bad; b=$w/candidate; }
 # EngramAdapterV1 production mapping: lookup-canonical performs MCP
 # mem_search(topic) then mem_get_observation for every candidate and exact-filters;
 # compare-put-canonical fresh-prechecks then uses mem_save or mem_update. Their
 # responses are never proof: only the separate fixed lookup below is proof.
 PINNED_ENGRAM_ADAPTER_DIGEST=1850954017:5640
 efield() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1&&v!="")print v;else exit 1}' "$1" || bad; }
 exact() { f=$1; shift; [ "$(awk 'NF{n++}END{print n+0}' "$f")" = "$#" ] || bad; for k; do efield "$f" "$k" >/dev/null; done; }
 scalar() { case "$1" in ''|*[!A-Za-z0-9._:-]*) bad;; esac; }
 hexok() { case "$1" in ''|*[!0123456789abcdef]*) bad;; esac; [ $(( ${#1} % 2 )) = 0 ] || bad; }
 digok() { case "$1" in *:*) a=${1%%:*}; z=${1#*:}; case "$a:$z" in *[!0123456789:]*|*:*:*) bad;; esac;; *) bad;; esac; }
 adapter_call() { "$w/adapter" "$store" "$w/request" "$w/response" || bad; }
 lookup() { rid=$1; printf 'schema=EngramAdapterV1\nverb=lookup-canonical\nrequest_id=%s\nproject=%s\ntopic=%s\n' "$rid" "$project" "$topic" > "$w/request"; adapter_call; [ "$(efield "$w/response" schema)" = EngramAdapterV1 ] && [ "$(efield "$w/response" request_id)" = "$rid" ] && [ "$(efield "$w/response" topic)" = "$topic" ] || bad; status=$(efield "$w/response" status); case "$status" in absent) exact "$w/response" schema request_id status topic;; found) exact "$w/response" schema request_id status topic observation_id store_revision content_hex content_digest; scalar "$(efield "$w/response" observation_id)"; case "$(efield "$w/response" store_revision)" in ''|*[!0-9]*) bad;; esac; hexok "$(efield "$w/response" content_hex)"; digok "$(efield "$w/response" content_digest)";; conflict|error) bad;; *) bad;; esac; }
 readback() { want=$1; wantstate=$2; lookup "${txn}:read-${wantstate}"; [ "$status" = found ] || bad; rh=$(efield "$w/response" content_hex); rd=$(efield "$w/response" content_digest); printf %s "$rh" | xxd -r -p > "$w/read" || bad; [ "$(dig "$w/read")" = "$rd" ] && [ "$(dig "$w/read")" = "$want" ] || bad; grep -Fxq "state=$wantstate" "$w/read" && grep -Fxq 'schema=ActivationStateV1' "$w/read" && grep -Fxq 'authority=engram' "$w/read" && grep -Fxq "txn_id=$txn" "$w/read" && grep -Fxq "canonical_model_digest=$md" "$w/read" && grep -Fxq "backend_payload_digest=$(dig "$w/model")" "$w/read" && grep -Fxq "predecessor_revision=$prior" "$w/read" && grep -Fxq "committed_revision=$(efield "$w/response" store_revision)" "$w/read" && grep -Fxq "backend_revision=$(efield "$w/response" store_revision)" "$w/read" || bad; awk '/^```text$/{p=1;next}p&&/^```$/{sub(/\n$/, "", x);printf "%s",x;exit}p{x=x $0 "\n"}' "$w/read" | cmp -s - "$w/model" || bad; }
 put_engram() { content=$1; presence=$2; oid=$3; rev=$4; pd=$5; printf 'schema=EngramAdapterV1\nverb=compare-put-canonical\nrequest_id=%s\nproject=%s\ntopic=%s\nexpected_presence=%s\nexpected_observation_id=%s\nexpected_store_revision=%s\nexpected_content_digest=%s\ncontent_hex=%s\ncontent_digest=%s\n' "${txn}:put" "$project" "$topic" "$presence" "$oid" "$rev" "$pd" "$(od -An -v -tx1 "$content" | tr -d ' \n')" "$(dig "$content")" > "$w/request"; adapter_call; exact "$w/response" schema request_id status; [ "$(efield "$w/response" schema)" = EngramAdapterV1 ] && [ "$(efield "$w/response" request_id)" = "${txn}:put" ] && [ "$(efield "$w/response" status)" = written ] || bad; }
  markdown() { state=$1; prior=$2; newrev=$3; out=$4; authority=${5-engram}; { printf '# SDD Init Canonical Policy\n\nschema=ActivationStateV1\nstate=%s\ntxn_id=%s\nauthority=%s\ncanonical_model_digest=%s\nbackend_payload_digest=%s\npredecessor_revision=%s\ncommitted_revision=%s\nbackend_revision=%s\nreadback=verified\n\n## CanonicalPolicyModelV1\n\n```text\n' "$state" "$txn" "$authority" "$md" "$(dig "$w/model")" "$prior" "$newrev" "$newrev"; cat "$w/model"; printf '\n```\n'; } > "$out" || bad; }
  hatomic() { _hf=$1; _hs=$2; _hp=$(dirname "$_hf"); _ht=$(mktemp "$_hp/.$(basename "$_hf").hybrid.XXXXXX") || return 1; cp -- "$_hs" "$_ht" && mv -- "$_ht" "$_hf" && cmp -s "$_hs" "$_hf"; }
  hfile() { printf %s "$1" | xxd -r -p > "$2" && [ "$(dig "$2")" = "$3" ]; }
  hmeta() { _hf=$1; _hs=$2; scan "$_hf"; cmp -s "$_hf" "$3" && grep -Fxq "    schema: \"ResolutionV1\"" "$_hf" && grep -Fxq "    state: \"$_hs\"" "$_hf" && grep -Fxq "    txn_id: \"$txn\"" "$_hf" && grep -Fxq '    authority: "openspec"' "$_hf" && grep -Fxq "    canonical_model_digest: \"$md\"" "$_hf"; }
  hyaml() { _hy=$1; _hs=$2; _ht=$t; _he=$e; yaml "$w/hybrid-base"; awk -v s="$_hs" -v t="$txn" -v m="$md" '/^    authoritative: true$/{print;print "    schema: \"ResolutionV1\"";print "    state: \"" s "\"";print "    txn_id: \"" t "\"";print "    authority: \"openspec\"";print "    canonical_model_digest: \"" m "\"";next}{print}' "$w/hybrid-base" > "$w/hybrid-testing" || bad; awk -v a="$_ht" -v z="$_he" -v y="$w/hybrid-testing" 'NR==a{while((getline x<y)>0)print x;next}NR>=a&&NR<z{next}{print}' "$target" > "$_hy" || bad; scan "$_hy"; t=$_ht; e=$_he; }
  hread() { _hh=$1; _hs=$2; lookup "${txn}:read-${_hs}"; [ "$status" = found ] || return 1; _hx=$(efield "$w/response" content_hex); _hd=$(efield "$w/response" content_digest); hfile "$_hx" "$w/hread" "$_hd" && cmp -s "$w/hread" "$_hh" && grep -Fxq 'schema=ActivationStateV1' "$w/hread" && grep -Fxq "state=$_hs" "$w/hread" && grep -Fxq 'authority=openspec' "$w/hread" && grep -Fxq "txn_id=$txn" "$w/hread" && grep -Fxq "canonical_model_digest=$md" "$w/hread"; }
   hraw() { _hr=$1; lookup "${txn}:raw"; [ "$status" = found ] && hfile "$(efield "$w/response" content_hex)" "$w/hraw" "$(efield "$w/response" content_digest)" && cmp -s "$w/hraw" "$_hr"; }
   # ResolutionV1 is a write-ahead journal.  Test runners inject crashes only at
   # the stable comments in hybrid2; production has no fault-control input.
   jcanon() { grep -v '^step_digest=' "$1" | cksum | awk '{print $1":"$2}'; }
   jload() { hload || return 1; jgen=$(field "$journal" generation); jprev=$(field "$journal" previous_step_digest); jstep=$(field "$journal" step_digest); jintent=$(field "$journal" current_intent); jverified=$(field "$journal" verified_step); jtopic=$(field "$journal" topic); jotarget=$(field "$journal" openspec_target_hex); jsid=$(field "$journal" engram_staging_observation_id); jsrev=$(field "$journal" engram_staging_revision); jaid=$(field "$journal" engram_active_observation_id); jarev=$(field "$journal" engram_active_revision); crev=$(field "$journal" engram_restore_revision); estage=$jsrev; eactive=$jarev; epath=$([ "$epres" = absent ] && printf absent || printf '%s' "$w/epre"); case "$jgen:$estage:$eactive" in *[!0-9:]*|:*|*:) return 1;; esac; case "$epres:$crev" in absent:none|found:[0-9]*) ;; *) return 1;; esac; [ "$jstep" = "$(jcanon "$journal")" ] && [ "$jtopic" = "$topic" ] && [ "$jotarget" = "$otarget" ] && [ "$jsid:$jsrev" = "obs-1:$estage" ] && [ "$jaid:$jarev" = "obs-1:$eactive" ]; }
   jwrite() { _js=$1 _ji=$2 _jv=$3 _jr=$4 _jg=$5 _jp=$6; _jt=$(mktemp "$hparent/.$(basename "$journal").intent.XXXXXX") || return 1; { printf 'schema=ResolutionV1\nproject=%s\nmode=hybrid\nstate=%s\ntxn_id=%s\ngate_digest=%s\nintegrated_bundle_digest=%s\ncanonical_model_digest=%s\nstep=%s\nrecovery_step=%s\nopenspec_preimage_hex=%s\nopenspec_preimage_digest=%s\nopenspec_staging_hex=%s\nopenspec_staging_digest=%s\nopenspec_active_hex=%s\nopenspec_active_digest=%s\nengram_preimage_presence=%s\nengram_preimage_observation_id=%s\nengram_preimage_revision=%s\nengram_preimage_hex=%s\nengram_preimage_digest=%s\nengram_staging_hex=%s\nengram_staging_digest=%s\nengram_active_hex=%s\nengram_active_digest=%s\nengram_restore_revision=%s\ngeneration=%s\nprevious_step_digest=%s\ncurrent_intent=%s\nverified_step=%s\ntopic=%s\nopenspec_target_hex=%s\nengram_staging_observation_id=obs-1\nengram_staging_revision=%s\nengram_active_observation_id=obs-1\nengram_active_revision=%s\n' "$project" "$_js" "$txn" "$gd" "$bd" "$md" "$_ji" "$_jr" "$ophex" "$opdig" "$oshex" "$osdig" "$oahex" "$oadig" "$epres" "$eoid" "$erev" "$ehex" "$edig" "$eshex" "$esdig" "$eahex" "$eadig" "$crev" "$_jg" "$_jp" "$_ji" "$_jv" "$topic" "$otarget" "$estage" "$eactive"; } > "$_jt" || return 1; _jd=$(jcanon "$_jt") || return 1; printf 'step_digest=%s\n' "$_jd" >> "$_jt" || return 1; mv -- "$_jt" "$journal" && jload && [ "$jgen:$jprev:$jintent:$jstep" = "$_jg:$_jp:$_ji:$_jd" ]; }
   jcreate() { [ ! -e "$journal" ] && [ ! -L "$journal" ] && jwrite staging F1-intent-openspec-staging none none 1 none; }
   jcas() { _jg=$1 _jd=$2 _jp=$3 _js=$4 _ji=$5 _jv=$6 _jr=$7; jload && [ "$jgen:$jstep:$jprev" = "$_jg:$_jd:$_jp" ] && jwrite "$_js" "$_ji" "$_jv" "$_jr" $((_jg+1)) "$_jd"; }
   jadvance() { _from=$1 _next=$2 _state=$3; jload && [ "$jintent" = "$_from" ] && jcas "$jgen" "$jstep" "$jprev" "$_state" "$_next" "${_from%%-intent-*}" none; }
   jrecover() { jload && jcas "$jgen" "$jstep" "$jprev" recovery-required "$jintent" "$jverified" "$jintent"; }
   jcompensate() { jload && jcas "$jgen" "$jstep" "$jprev" recovery-required "$jintent" compensate "$jintent"; }
   jrestore() { _jr=$1 _jv=$2; jload || return 1; crev=$_jr; jwrite staging "$jintent" "$_jv" none $((jgen+1)) "$jstep"; }
   oclass() { cmp -s "$target" "$1" && printf retry || { cmp -s "$target" "$2" && printf advance || printf conflict; }; }
   ematch() { _em=$1 _ei=$2 _er=$3; [ "$status" = found ] || return 1; hfile "$(efield "$w/response" content_hex)" "$w/ematch" "$(efield "$w/response" content_digest)" && cmp -s "$w/ematch" "$_em" && [ "$(efield "$w/response" observation_id):$(efield "$w/response" store_revision)" = "$_ei:$_er" ]; }
   eclass() { _ep=$1 _ei=$2 _er=$3 _en=$4 _ni=$5 _nr=$6; lookup "${txn}:class-${jintent}"; case "$status" in absent) [ "$_ep" = absent ] && printf retry || printf conflict;; found) { [ "$_ep" != absent ] && ematch "$_ep" "$_ei" "$_er"; } && printf retry || { ematch "$_en" "$_ni" "$_nr" && printf advance || printf conflict; };; esac; }
   ewrite() { _ep=$1 _ei=$2 _er=$3 _en=$4 _tag=$5; lookup "${txn}:before-${_tag}"; if [ "$_ep" = absent ]; then [ "$status" = absent ] || return 1; put_engram "$_en" absent none none none; else ematch "$_ep" "$_ei" "$_er" || return 1; put_engram "$_en" found "$_ei" "$_er" "$(dig "$_ep")"; fi; }
   eread() { _en=$1 _ei=$2 _er=$3 _state=$4; lookup "${txn}:read-${_state}"; ematch "$_en" "$_ei" "$_er" && hread "$_en" "$_state"; }
   f1() { case "$(oclass "$w/opre" "$w/os")" in retry) # crash:F1-before-write
       hatomic "$target" "$w/os" || return 1
       # crash:F1-after-write
       # crash:F1-before-readback
       hmeta "$target" staging "$w/os" || return 1
       # crash:F1-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:F2-before-intent
     # fault:F1-before-F2
     jadvance F1-intent-openspec-staging F2-intent-engram-staging staging || return 1
     # fault:F1-completed
     # crash:F2-after-intent
   }
   f2() { case "$(eclass "${epath}" "$eoid" "$erev" "$w/es" obs-1 "$estage")" in retry) # crash:F2-before-write
       ewrite "${epath}" "$eoid" "$erev" "$w/es" F2 || return 1
       # crash:F2-after-write
       # crash:F2-before-readback
       eread "$w/es" obs-1 "$estage" staging || return 1
       # crash:F2-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:F3-before-intent
     jadvance F2-intent-engram-staging F3-intent-engram-active staging || return 1
     # fault:F2-completed
     # crash:F3-after-intent
   }
   f3() { case "$(eclass "$w/es" obs-1 "$estage" "$w/ea" obs-1 "$eactive")" in retry) # crash:F3-before-write
       ewrite "$w/es" obs-1 "$estage" "$w/ea" F3 || return 1
       # crash:F3-after-write
       # crash:F3-before-readback
       eread "$w/ea" obs-1 "$eactive" active || return 1
       # crash:F3-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:F4-before-intent
     jadvance F3-intent-engram-active F4-intent-openspec-active staging || return 1
     # fault:F3-completed
     # crash:F4-after-intent
   }
   f4() { case "$(oclass "$w/os" "$w/oa")" in retry) # crash:F4-before-write
       hatomic "$target" "$w/oa" || return 1
       # crash:F4-after-write
       # crash:F4-before-readback
       hmeta "$target" active "$w/oa" || return 1
       # crash:F4-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     hmeta "$target" active "$w/oa" && eread "$w/ea" obs-1 "$eactive" active || { jrecover || :; return 1; }
     # fault:F4-before-terminal
     jadvance F4-intent-openspec-active active active
     # fault:F4-completed
   }
   cintent() { _cf=$1 _cn=$2 _cv=$3 _cr=${4-}; jload && [ "$jintent" = "$_cf" ] || return 1; [ -z "$_cr" ] || crev=$_cr; jcas "$jgen" "$jstep" "$jprev" staging "$_cn" "$_cv" none; }
   eraw() { _ef=$1 _ei=$2 _er=$3; lookup "${txn}:raw-${jintent}"; [ "$status" = found ] && hfile "$(efield "$w/response" content_hex)" "$w/eraw" "$(efield "$w/response" content_digest)" && cmp -s "$w/eraw" "$_ef" && [ "$(efield "$w/response" observation_id):$(efield "$w/response" store_revision)" = "$_ei:$_er" ]; }
   cengram() { _ce=$1 _cr=$2 _ct=$3; _cn=$crev; [ "$_cn" = "$((_cr+1))" ] || return 1; case "$(eclass "$_ce" obs-1 "$_cr" "$w/epre" "$eoid" "$_cn")" in retry) case "$_ct" in C2) # crash:C2-before-write
         ewrite "$_ce" obs-1 "$_cr" "$w/epre" C2 || return 1
         # crash:C2-after-write
         # crash:C2-before-readback
         eraw "$w/epre" "$eoid" "$_cn" || return 1
         # crash:C2-after-readback
         ;;
       C3) # crash:C3-before-write
         ewrite "$_ce" obs-1 "$_cr" "$w/epre" C3 || return 1
         # crash:C3-after-write
         # crash:C3-before-readback
         eraw "$w/epre" "$eoid" "$_cn" || return 1
         # crash:C3-after-readback
         ;;
       *) return 1;; esac; crev=$_cn;; advance) crev=$_cn;; *) jrecover || :; return 1;; esac; }
   c1() { case "$(oclass "$w/os" "$w/opre")" in retry) # crash:C1-before-write
       hatomic "$target" "$w/opre" || return 1
       # crash:C1-after-write
       # crash:C1-before-readback
       cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] || return 1
       # crash:C1-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     if [ "$epres" = absent ]; then lookup "${txn}:prior-absent" && [ "$status" = absent ] || { jrecover || :; return 1; }; else eraw "$w/epre" "$eoid" "$crev" || { jrecover || :; return 1; }; fi
     jload && jcas "$jgen" "$jstep" "$jprev" prior-active prior-active C1-verified none; }
   c2() { lookup "${txn}:C2-class" || return 1; if [ "$status" = found ] && ematch "$w/epre" "$eoid" "$erev"; then # crash:C2-before-intent
       cintent C2-intent-engram-preimage C1-intent-openspec-preimage C2-skipped || return 1
       # crash:C2-after-intent
       return
     fi; jrestore $((estage+1)) C2-restore-intent || return 1; cengram "$w/es" "$estage" C2 || return 1; # crash:C2-before-intent
     cintent C2-intent-engram-preimage C1-intent-openspec-preimage C2-verified "$crev" || return 1
     # crash:C2-after-intent
   }
   c3() { lookup "${txn}:C3-class" || return 1; if [ "$status" = found ] && ematch "$w/epre" "$eoid" "$erev"; then # crash:C3-before-intent
       cintent C3-intent-engram-preimage C1-intent-openspec-preimage C3-skipped || return 1
       # crash:C3-after-intent
       return
     elif [ "$status" = found ] && ematch "$w/es" obs-1 "$estage"; then # crash:C3-before-intent
       cintent C3-intent-engram-preimage C2-intent-engram-preimage C3-skipped || return 1
       # crash:C3-after-intent
       return
     fi; jrestore $((eactive+1)) C3-restore-intent || return 1; cengram "$w/ea" "$eactive" C3 || return 1; # crash:C3-before-intent
     cintent C3-intent-engram-preimage C1-intent-openspec-preimage C2-skipped "$crev" || return 1
     # crash:C3-after-intent
   }
   c4() { if cmp -s "$target" "$w/os"; then # crash:C4-before-intent
       cintent C4-intent-openspec-preimage C3-intent-engram-preimage C4-skipped || return 1
       # crash:C4-after-intent
       return
     fi; case "$(oclass "$w/oa" "$w/opre")" in retry) # crash:C4-before-write
       hatomic "$target" "$w/opre" || return 1
       # crash:C4-after-write
       # crash:C4-before-readback
       cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] || return 1
       # crash:C4-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:C4-before-intent
     cintent C4-intent-openspec-preimage C3-intent-engram-preimage C4-verified || return 1
     # crash:C4-after-intent
   }
   compensate() { jload || return 1; case "$jintent" in F1-intent-openspec-staging) # crash:C1-before-intent
       cintent F1-intent-openspec-staging C1-intent-openspec-preimage F1-verified || return 1
       # crash:C1-after-intent
       ;;
     F2-intent-engram-staging) # crash:C2-before-intent
       cintent F2-intent-engram-staging C2-intent-engram-preimage F2-verified || return 1
       # crash:C2-after-intent
       ;;
     F3-intent-engram-active) # crash:C3-before-intent
       cintent F3-intent-engram-active C3-intent-engram-preimage F3-verified || return 1
       # crash:C3-after-intent
       ;;
     F4-intent-openspec-active) # crash:C4-before-intent
       cintent F4-intent-openspec-active C4-intent-openspec-preimage F4-verified || return 1
       # crash:C4-after-intent
       ;;
     esac
     case "$jintent" in C4-intent-openspec-preimage) c4;; C3-intent-engram-preimage) c3;; C2-intent-engram-preimage) c2;; C1-intent-openspec-preimage) c1;; *) return 1;; esac; }
   hybrid2() { reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || return 1; cp -- "$adapter" "$w/adapter" && chmod 700 "$w/adapter" || return 1; topic="sdd-init/$project"; field "$w/integrated" canonical_model_bytes | sed 's/^hex://' | xxd -r -p > "$w/model" || return 1; [ "$(dig "$w/model")" = "$md" ] || return 1; scan "$target"; hparent=$(dirname "$journal"); dir "$hparent"; otarget=$(printf %s "$target" | od -An -v -tx1 | tr -d ' \n'); if [ -e "$journal" ]; then jload || return 1; [ "$hstate:$jintent" = active:active ] && { hmeta "$target" active "$w/oa" && eread "$w/ea" obs-1 "$eactive" active; return; }; [ "$hstate:$jintent" = prior-active:prior-active ] && { cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] && { [ "$epres" = absent ] && lookup "${txn}:prior-absent" && [ "$status" = absent ] || eraw "$w/epre" "$eoid" "$crev"; }; return; }; else cp -p "$target" "$w/opre" || return 1; lookup "${txn}:preimage" || return 1; case "$status" in absent) epres=absent; eoid=none; erev=none; ehex=none; edig=none; epath=absent; prior=absent; enext=1;; found) epres=found; eoid=$(efield "$w/response" observation_id); erev=$(efield "$w/response" store_revision); ehex=$(efield "$w/response" content_hex); edig=$(efield "$w/response" content_digest); hfile "$ehex" "$w/epre" "$edig" || return 1; epath=$w/epre; prior=$erev; enext=$((erev+1));; *) return 1;; esac; hyaml "$w/os" staging; hyaml "$w/oa" active; markdown staging "$prior" "$enext" "$w/es" openspec; markdown active "$prior" $((enext+1)) "$w/ea" openspec; ophex=$(od -An -v -tx1 "$w/opre" | tr -d ' \n'); opdig=$(dig "$w/opre"); oshex=$(od -An -v -tx1 "$w/os" | tr -d ' \n'); osdig=$(dig "$w/os"); oahex=$(od -An -v -tx1 "$w/oa" | tr -d ' \n'); oadig=$(dig "$w/oa"); eshex=$(od -An -v -tx1 "$w/es" | tr -d ' \n'); esdig=$(dig "$w/es"); eahex=$(od -An -v -tx1 "$w/ea" | tr -d ' \n'); eadig=$(dig "$w/ea"); estage=$enext; eactive=$((enext+1)); crev=$erev; # crash:F1-before-intent
     jcreate || return 1
     # crash:F1-after-intent
   fi; case "$jintent" in F1-intent-openspec-staging) f1;; F2-intent-engram-staging) f2;; F3-intent-engram-active) f3;; F4-intent-openspec-active) f4;; *) return 1;; esac; }
  hput() { _he=$1; _hn=$2; _hs=$3; lookup "${txn}:before-${_hs}"; if [ "$_he" = absent ]; then [ "$status" = absent ] || return 1; _ho=none _hr=none _hp=none; else [ "$status" = found ] || return 1; hfile "$(efield "$w/response" content_hex)" "$w/hcurrent" "$(efield "$w/response" content_digest)" && cmp -s "$w/hcurrent" "$_he" || return 1; _ho=$(efield "$w/response" observation_id); _hr=$(efield "$w/response" store_revision); _hp=$(efield "$w/response" content_digest); fi; put_engram "$_hn" "$([ "$_he" = absent ] && printf absent || printf found)" "$_ho" "$_hr" "$_hp"; hread "$_hn" "$_hs"; }
  hjournal() { _hstate=$1; _hstep=$2; _hrec=$3; _ht=$hparent/.$(basename "$journal").stage.$$; { printf 'schema=ResolutionV1\nproject=%s\nmode=hybrid\nstate=%s\ntxn_id=%s\ngate_digest=%s\nintegrated_bundle_digest=%s\ncanonical_model_digest=%s\nstep=%s\nrecovery_step=%s\nopenspec_preimage_hex=%s\nopenspec_preimage_digest=%s\nopenspec_staging_hex=%s\nopenspec_staging_digest=%s\nopenspec_active_hex=%s\nopenspec_active_digest=%s\nengram_preimage_presence=%s\nengram_preimage_observation_id=%s\nengram_preimage_revision=%s\nengram_preimage_hex=%s\nengram_preimage_digest=%s\nengram_staging_hex=%s\nengram_staging_digest=%s\nengram_active_hex=%s\nengram_active_digest=%s\n' "$project" "$_hstate" "$txn" "$gd" "$bd" "$md" "$_hstep" "$_hrec" "$ophex" "$opdig" "$oshex" "$osdig" "$oahex" "$oadig" "$epres" "$eoid" "$erev" "$ehex" "$edig" "$eshex" "$esdig" "$eahex" "$eadig"; } > "$_ht" && mv -- "$_ht" "$journal" && reg "$journal"; }
  hload() { reg "$journal"; [ "$(field "$journal" schema)" = ResolutionV1 ] && [ "$(field "$journal" project)" = "$project" ] && [ "$(field "$journal" mode)" = hybrid ] && [ "$(field "$journal" txn_id)" = "$txn" ] && [ "$(field "$journal" gate_digest)" = "$gd" ] && [ "$(field "$journal" integrated_bundle_digest)" = "$bd" ] && [ "$(field "$journal" canonical_model_digest)" = "$md" ] || return 1; hstep=$(field "$journal" step); hstate=$(field "$journal" state); for k in openspec_preimage_hex openspec_preimage_digest openspec_staging_hex openspec_staging_digest openspec_active_hex openspec_active_digest engram_preimage_presence engram_preimage_observation_id engram_preimage_revision engram_preimage_hex engram_preimage_digest engram_staging_hex engram_staging_digest engram_active_hex engram_active_digest; do eval "v=\$(field \"$journal\" $k)"; case "$k" in openspec_preimage_hex) ophex=$v;; openspec_preimage_digest) opdig=$v;; openspec_staging_hex) oshex=$v;; openspec_staging_digest) osdig=$v;; openspec_active_hex) oahex=$v;; openspec_active_digest) oadig=$v;; engram_preimage_presence) epres=$v;; engram_preimage_observation_id) eoid=$v;; engram_preimage_revision) erev=$v;; engram_preimage_hex) ehex=$v;; engram_preimage_digest) edig=$v;; engram_staging_hex) eshex=$v;; engram_staging_digest) esdig=$v;; engram_active_hex) eahex=$v;; engram_active_digest) eadig=$v;; esac; done; hfile "$ophex" "$w/opre" "$opdig" && hfile "$oshex" "$w/os" "$osdig" && hfile "$oahex" "$w/oa" "$oadig" && { [ "$epres" = absent ] || hfile "$ehex" "$w/epre" "$edig"; } && hfile "$eshex" "$w/es" "$esdig" && hfile "$eahex" "$w/ea" "$eadig"; }
  hcheck() { case "$hstep" in journal) cmp -s "$target" "$w/opre" && { [ "$epres" = absent ] && lookup "${txn}:check-pre" && [ "$status" = absent ] || hraw "$w/epre"; };; openspec-staging) hmeta "$target" staging "$w/os" && { [ "$epres" = absent ] && lookup "${txn}:check-pre" && [ "$status" = absent ] || hraw "$w/epre"; };; engram-staging) hmeta "$target" staging "$w/os" && hread "$w/es" staging;; engram-active) hmeta "$target" staging "$w/os" && hread "$w/ea" active;; openspec-active) hmeta "$target" active "$w/oa" && hread "$w/ea" active;; *) return 1;; esac; }
  hrecover() { hload || return 1; case "$hstep" in engram-staging|engram-active|openspec-active) if [ "$epres" = absent ]; then hjournal recovery-required "$hstep" delete-new-canonical; return 1; fi; _hc=$w/ea; [ "$hstep" = engram-staging ] && _hc=$w/es; hput "$_hc" "$w/epre" active || { hjournal recovery-required "$hstep" restore-engram || :; return 1; };; esac; case "$hstep" in openspec-staging|engram-staging|engram-active|openspec-active) hatomic "$target" "$w/opre" && cmp -s "$target" "$w/opre" || { hjournal recovery-required "$hstep" restore-openspec || :; return 1; };; esac; hjournal prior-active compensated none; }
  hybrid() { reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || return 1; cp -- "$adapter" "$w/adapter" && chmod 700 "$w/adapter" || return 1; topic="sdd-init/$project"; field "$w/integrated" canonical_model_bytes | sed 's/^hex://' | xxd -r -p > "$w/model" || return 1; [ "$(dig "$w/model")" = "$md" ] || return 1; scan "$target"; hparent=$(dirname "$journal"); dir "$hparent"; if [ -e "$journal" ]; then hload && hcheck || return 1; [ "$hstate" = active ] && { [ "$hstep" = openspec-active ] || return 1; return 0; }; else cp -p "$target" "$w/opre" || return 1; lookup "${txn}:preimage" || return 1; case "$status" in absent) epres=absent; eoid=none; erev=none; ehex=none; edig=none; prior=absent; enext=1;; found) epres=found; eoid=$(efield "$w/response" observation_id); erev=$(efield "$w/response" store_revision); ehex=$(efield "$w/response" content_hex); edig=$(efield "$w/response" content_digest); hfile "$ehex" "$w/epre" "$edig" || return 1; prior=$erev; enext=$((erev+1));; *) return 1;; esac; hyaml "$w/os" staging; hyaml "$w/oa" active; markdown staging "$prior" "$enext" "$w/es" openspec; markdown active "$prior" $((enext+1)) "$w/ea" openspec; ophex=$(od -An -v -tx1 "$w/opre" | tr -d ' \n'); opdig=$(dig "$w/opre"); oshex=$(od -An -v -tx1 "$w/os" | tr -d ' \n'); osdig=$(dig "$w/os"); oahex=$(od -An -v -tx1 "$w/oa" | tr -d ' \n'); oadig=$(dig "$w/oa"); eshex=$(od -An -v -tx1 "$w/es" | tr -d ' \n'); esdig=$(dig "$w/es"); eahex=$(od -An -v -tx1 "$w/ea" | tr -d ' \n'); eadig=$(dig "$w/ea"); hjournal staging journal none || return 1; hstep=journal; fi; case "$hstep" in journal) hatomic "$target" "$w/os" && hmeta "$target" staging "$w/os" && hjournal staging openspec-staging none || return 1; hstep=openspec-staging;; esac; case "$hstep" in openspec-staging) hput "$([ "$epres" = absent ] && printf absent || printf '%s' "$w/epre")" "$w/es" staging && hjournal staging engram-staging none || return 1; hstep=engram-staging;; esac; case "$hstep" in engram-staging) hput "$w/es" "$w/ea" active && hjournal staging engram-active none || return 1; hstep=engram-active;; esac; case "$hstep" in engram-active) hatomic "$target" "$w/oa" && hmeta "$target" active "$w/oa" && hjournal staging openspec-active none || return 1; hstep=openspec-active;; esac; hjournal active openspec-active none; }
   terminal() { jload || return 1; case "$hstate:$jintent" in active:active) hmeta "$target" active "$w/oa" && eread "$w/ea" obs-1 "$eactive" active;; prior-active:prior-active) cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] && { if [ "$epres" = absent ]; then lookup "${txn}:prior-absent" && [ "$status" = absent ]; else eraw "$w/epre" "$eoid" "$crev"; fi; };; *) return 1;; esac; }
   hybrid3() { reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || return 1; cp -- "$adapter" "$w/adapter" && chmod 700 "$w/adapter" || return 1; topic="sdd-init/$project"; otarget=$(printf %s "$target" | od -An -v -tx1 | tr -d ' \n'); hparent=$(dirname "$journal"); dir "$hparent"; lock=$hparent/.$(basename "$journal").resolution-lock; mkdir "$lock" || return 1; while :; do if [ -e "$journal" ] && jload && [ "$hstate:$jverified" = recovery-required:compensate ]; then compensate || return 1; continue; fi; if hybrid2; then jload || return 1; case "$jintent" in active|prior-active) terminal && return 0 || { jrecover || :; return 1; };; esac; else rc=$?; jload || return 1; case "$jintent" in active|prior-active) terminal && return 0 || { jrecover || :; return 1; };; C*-intent-*) compensate || return 1; continue;; esac; [ "$rc" = 77 ] || return 1; jcompensate || return 1; compensate || return 1; fi; done; }
   cmd=${1-}; shift || :; case "$cmd" in activate-openspec) [ "$#" = 5 ] || exit 2; project=$1; bundle=$2; target=$3; resolution=$4; gate=$5; mode=openspec;; activate-engram) [ "$#" = 5 ] || exit 2; project=$1; bundle=$2; adapter=$3; store=$4; gate=$5; mode=engram;; activate-hybrid) [ "$#" = 7 ] || exit 2; project=$1; bundle=$2; target=$3; journal=$4; adapter=$5; store=$6; gate=$7; mode=hybrid;; evaluate-none) [ "$#" = 3 ] || exit 2; project=$1; bundle=$2; gate=$3; mode=none;; *) exit 2;; esac
case "$project" in ''|*[!A-Za-z0-9._-]*) bad;; esac; dir "$bundle"; w=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-activation.XXXXXX") || bad; chmod 700 "$w"; trap 'rm -rf "${w:-}" "${stage:-}" "${old:-}" "${out:-}"; rmdir "${lock:-}" 2>/dev/null || :' EXIT HUP INT TERM; verify_gate; [ "$(bundle_digest "$bundle")" = "$bd" ] || bad; txn=$(printf '%s\n%s\n%s\n%s\n%s\n' "$project" "$mode" "$gd" "$bd" "$md" | cksum | awk '{print "v1:"$1":"$2}'); crev=none
  if [ "$mode" = none ]; then state=candidate; backend=none; commits=none; emit; exit 0; fi
  if [ "$mode" = hybrid ]; then hybrid3 || { jrecover || :; bad; }; cat "$journal"; exit 0; fi
 if [ "$mode" = engram ]; then reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || bad; cp -- "$adapter" "$w/adapter"; chmod 700 "$w/adapter"; topic="sdd-init/$project"; cp "$w/integrated" "$w/receipt"; field "$w/receipt" canonical_model_bytes | sed 's/^hex://' | xxd -r -p > "$w/model" || bad; [ "$(dig "$w/model")" = "$md" ] || bad; lookup "${txn}:preimage"; case "$status" in absent) prior=absent; oid=none; rev=none; pd=none; expected=1;; found) oid=$(efield "$w/response" observation_id); rev=$(efield "$w/response" store_revision); pd=$(efield "$w/response" content_digest); prior=$rev; expected=$((rev+1)); prehex=$(efield "$w/response" content_hex);; *) bad;; esac; preoid=$oid; prerev=$rev; predigest=$pd; markdown staging "$prior" "$expected" "$w/staging"; put_engram "$w/staging" "$([ "$prior" = absent ] && printf absent || printf found)" "$oid" "$rev" "$pd"; readback "$(dig "$w/staging")" staging; oid=$(efield "$w/response" observation_id); rev=$(efield "$w/response" store_revision); markdown active "$prior" $((rev+1)) "$w/active"; put_engram "$w/active" found "$oid" "$rev" "$(efield "$w/response" content_digest)"; readback "$(dig "$w/active")" active; { printf 'schema=ResolutionV1\nproject=%s\nmode=engram\nstate=active\ntxn_id=%s\ncanonical_model_digest=%s\nengram_preimage_presence=%s\nengram_preimage_observation_id=%s\nengram_preimage_revision=%s\nengram_preimage_digest=%s\nengram_preimage_hex=%s\nengram_committed_revision=%s\ncommits=engram:staging:verified,engram:active:verified\n' "$project" "$txn" "$md" "$([ "$prior" = absent ] && printf absent || printf found)" "$preoid" "$prior" "$predigest" "${prehex-}" "$(efield "$w/response" store_revision)"; } ; exit 0; fi
scan "$target"; parent=$(dirname "$target"); dir "$parent"; [ ! -e "$resolution" ] && [ ! -L "$resolution" ] || bad; rparent=$(dirname "$resolution"); dir "$rparent"; lock=$parent/.$(basename "$target").rubric-lock; mkdir "$lock" || bad; old=$w/preimage; cp -p "$target" "$old" || bad; yaml "$w/yaml"; awk -v t="$txn" -v m="$md" '/^    authoritative: true$/{print;print "    schema: \"ResolutionV1\"";print "    state: \"active\"";print "    txn_id: \"" t "\"";print "    authority: \"openspec\"";print "    canonical_model_digest: \"" m "\"";next}{print}' "$w/yaml" > "$w/yaml.active" && mv -- "$w/yaml.active" "$w/yaml" || bad; stage=$(mktemp "$parent/.$(basename "$target").stage.XXXXXX") || bad; awk -v a="$t" -v z="$e" -v y="$w/yaml" 'NR==a{while((getline x<y)>0)print x;next}NR>=a&&NR<z{next}{print}' "$target" > "$stage" || bad; cmp -s "$target" "$old" && [ "$(bundle_digest "$bundle")" = "$bd" ] || bad; scan "$stage"; mv -- "$stage" "$target" || bad; committed=1; scan "$target"; backend=$(dig "$target"); state=active; commits=openspec:atomic-splice; out=$rparent/.$(basename "$resolution").stage.$$; emit > "$out" || bad; printf 'authority=openspec\nreadback=verified\n' >> "$out" || bad; [ "$(field "$out" canonical_model_digest)" = "$md" ] && [ "$(field "$out" backend_config_digest)" = "$backend" ] && [ "$(dig "$target")" = "$backend" ] || bad; mv -- "$out" "$resolution" || bad; committed=0; rmdir "$lock" || bad; trap - EXIT HUP INT TERM
<!-- rubric-activation:end -->
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:details -->

<!-- shape:pi -->
<!-- gentle-ai:sdd-init-rubric -->
<!-- rubric-consumer-gate:start -->
#!/bin/sh
# Validates persisted activation evidence before one orchestrator resolution.
set -eu
LC_ALL=C; export LC_ALL
dig() { cksum "$1" | awk '{print $1":"$2}'; }
count() { awk -v p="$2" '$0 ~ p{n++}END{print n+0}' "$1"; }
kv() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1)print v;else exit 1}' "$1"; }
yv() { awk -v k="$2" '$0 ~ "^    " k ": \"" {n++;v=$0;sub("^    " k ": \\\"","",v);sub("\\\"$","",v)}END{if(n==1)print v;else exit 1}' "$1"; }
safe() { case "$1" in ''|*[!A-Za-z0-9._:-]*) return 1;; esac; }
out() { printf 'schema=RubricConsumerEnvelopeV1\nbackend=%s\nmode=%s\nstate=%s\ntxn_id=%s\ncanonical_model_digest=%s\nresolution_owner=orchestrator\n' "$1" "$mode" "$2" "$3" "$4"; }
blocked() { printf 'schema=RubricConsumerBlockedV1\nbackend=%s\nobserved_state=%s\nmismatch=%s\nrecovery_action=run sdd-init recovery\n' "$1" "$2" "$3"; exit 1; }
obs() { x=${1-none}; safe "$x" && printf %s "$x" || printf none; }
needkv() { [ "$(count "$1" "^$2=")" = 1 ] || return 1; kv "$1" "$2"; }
needyaml() { [ "$(awk -v k="$2" '$0 ~ "^    " k ": \""{n++}END{print n+0}' "$1")" = 1 ] || return 1; yv "$1" "$2"; }
oscheck() {
  c=$1/config r=$1/resolution; [ -f "$c" ] && [ -f "$r" ] || blocked openspec none outage
  [ "$(count "$c" '^  policy: "rubric"$')" = 1 ] || blocked openspec none absent
  [ "$(count "$c" '^  methods:')" = 0 ] || blocked openspec active parallel-methods
  n=$(count "$c" '^    schema: "'); [ "$n" = 1 ] || { [ "$n" = 0 ] && blocked openspec none malformed || blocked openspec none duplicate; }
  st=$(needyaml "$c" state 2>/dev/null || :); case "$st" in staging|recovery-required) blocked openspec "$st" "$st";; esac
  for k in schema state txn_id authority canonical_model_digest; do v=$(needyaml "$c" "$k" 2>/dev/null || :); [ -n "$v" ] && safe "$v" || blocked openspec "$(obs "$st")" malformed; case "$k" in schema) o_schema=$v;; state) o_state=$v;; txn_id) o_txn_id=$v;; authority) o_authority=$v;; canonical_model_digest) o_canonical_model_digest=$v;; esac; done
  [ "$o_schema:$o_state:$o_authority" = ResolutionV1:active:openspec ] || blocked openspec "$(obs "$o_state")" state-mismatch
  for k in schema state txn_id authority canonical_model_digest backend_config_digest readback; do v=$(needkv "$r" "$k" 2>/dev/null || :); [ -n "$v" ] && safe "$v" || blocked openspec "$(obs "$o_state")" malformed; case "$k" in schema) r_schema=$v;; state) r_state=$v;; txn_id) r_txn_id=$v;; authority) r_authority=$v;; canonical_model_digest) r_canonical_model_digest=$v;; backend_config_digest) r_backend_config_digest=$v;; readback) r_readback=$v;; esac; done
  [ "$r_schema:$r_state:$r_authority" = ResolutionV1:active:openspec ] || blocked openspec "$(obs "$r_state")" state-mismatch
  [ "$o_txn_id" = "$r_txn_id" ] || blocked openspec "$(obs "$o_state")" txn-mismatch
  [ "$o_canonical_model_digest" = "$r_canonical_model_digest" ] || blocked openspec "$(obs "$o_state")" model-mismatch
  [ "$r_backend_config_digest" = "$(dig "$c")" ] || blocked openspec "$(obs "$o_state")" backend-mismatch
  [ "$r_readback" = verified ] || blocked openspec "$(obs "$o_state")" readback-invalid
  TX=$o_txn_id MD=$o_canonical_model_digest
}
echeck() {
  f=$1 auth=$2 backend=$3; [ -f "$f" ] || blocked "$backend" none outage
  n=$(count "$f" '^schema=ActivationStateV1$'); [ "$n" = 1 ] || { [ "$n" = 0 ] && blocked "$backend" none malformed || blocked "$backend" none duplicate; }
  st=$(needkv "$f" state 2>/dev/null || :); case "$st" in staging|recovery-required) blocked "$backend" "$st" "$st";; esac
  for k in schema state txn_id authority canonical_model_digest backend_payload_digest committed_revision backend_revision readback; do v=$(needkv "$f" "$k" 2>/dev/null || :); [ -n "$v" ] && safe "$v" || blocked "$backend" "$(obs "$st")" malformed; case "$k" in schema) e_schema=$v;; state) e_state=$v;; txn_id) e_txn_id=$v;; authority) e_authority=$v;; canonical_model_digest) e_canonical_model_digest=$v;; backend_payload_digest) e_backend_payload_digest=$v;; committed_revision) e_committed_revision=$v;; backend_revision) e_backend_revision=$v;; readback) e_readback=$v;; esac; done
  [ "$e_schema:$e_state:$e_authority" = "ActivationStateV1:active:$auth" ] || blocked "$backend" "$(obs "$e_state")" state-mismatch
  [ "$e_committed_revision" = "$e_backend_revision" ] && [ "$e_readback" = verified ] || blocked "$backend" "$(obs "$e_state")" readback-invalid
  awk '/^```text$/{p=1;next}p&&/^```$/{exit}p{print}' "$f" > "$tmp/model"
  [ "$(dig "$tmp/model")" = "$e_backend_payload_digest" ] && [ "$e_canonical_model_digest" = "$e_backend_payload_digest" ] || blocked "$backend" "$(obs "$e_state")" model-mismatch
  TX=$e_txn_id MD=$e_canonical_model_digest
}
cmd=${1-}; phase=${2-}; mode=${3-}; od=${4-}; ef=${5-}; sf=${6-}; [ "$cmd" = consume ] && [ "$#" = 6 ] || exit 2
case "$phase:$mode" in apply:openspec|verify:openspec|apply:engram|verify:engram|apply:hybrid|verify:hybrid|apply:none|verify:none|apply:legacy|verify:legacy) ;; *) exit 2;; esac
tmp=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-consumer.XXXXXX") || exit 1; trap 'rm -rf "$tmp"' EXIT HUP INT TERM
case "$mode" in
  openspec) oscheck "$od"; out openspec active "$TX" "$MD";;
  engram) echeck "$ef" engram engram; out engram active "$TX" "$MD";;
  hybrid) oscheck "$od"; ot=$TX om=$MD; echeck "$ef" openspec both; [ "$ot:$om" = "$TX:$MD" ] || blocked both active "$( [ "$ot" = "$TX" ] && printf model-mismatch || printf txn-mismatch )"; out both active "$TX" "$MD";;
  none) [ -f "$sf" ] || blocked session none outage; for k in schema state commits current_session txn_id canonical_model_digest; do needkv "$sf" "$k" >/dev/null 2>&1 || blocked session none malformed; done; [ "$(kv "$sf" schema):$(kv "$sf" state):$(kv "$sf" commits):$(kv "$sf" current_session)" = IntegratedValidationV1:verified:none:true ] || blocked session "$(obs "$(kv "$sf" state 2>/dev/null || :)")" state-mismatch; out session candidate none "$(kv "$sf" canonical_model_digest)";;
  legacy) seen=; [ -f "$od/config" ] && grep -Eq 'policy: "rubric"|ResolutionV1' "$od/config" && seen=1; [ -f "$ef" ] && grep -q 'ActivationStateV1' "$ef" && seen=1; [ -z "$seen" ] || blocked legacy none absent; mode=binary; out legacy legacy none none;;
esac
<!-- rubric-consumer-gate:end -->
## Project TDD Policy Producer

Before any project inspection whenever rubric generation is selected or a rubric candidate may be generated, including selected rubric re-init, MUST read `references/rubric-authoring.md`. It is the generic semantic-authoring method; do not replace it with capability-only inference.

You are the single writer of project TDD policy; the parent/orchestrator is read-only and may only relay this blocking envelope. Detect runnable testing capabilities and use only this closed evidence-method vocabulary: `unit`, `integration`, `e2e`, `coverage`, `lint`, `typecheck`, `format`, `build`. A method is satisfiable when the project declares/configures a concrete command and its reproducible environment or dependency manifest provides the tool (package dependency, lockfile, container/CI image, or equivalent). It MUST NOT depend solely on whether the binary/dependencies happen to be installed in the current interactive host shell. A config section naming a framework without a declared dependency/environment/command is insufficient. Capability facts bind evidence_method + project scope/signature coverage + concrete command + reproducible proof. A method satisfiable in one scope is not satisfiable globally. A generated row may require a method only when its bound command applies to that row's complete signature/scope. When commands differ by scope, persist scoped command bindings so apply/verify executes the correct one. If a row has no satisfiable binding, omit/degrade that method for the row; never borrow another scope's command.

Emit only the existing canonical directory candidate bundle/IR (`schema: v1`, `candidate-schema: v1`) for the embedded rubric validator and compiler gates. Never hand-author `openspec/config.yaml`, `testing.methods`, or active YAML. Each binding needs a stable ID; executable, argv, workdir, env, platform/requirements where supported; declaration/tool-proof refs; scope/signature coverage; fact refs; and attestation refs. Every row with disciplines or evidence names binding IDs. The compiler alone serializes `testing.rubric` and may activate only after structural, exact-replay, canonical-model, serializer, and activation/readback gates. Without those gates, return the pending candidate and the typed blocked envelope.

Mandatory validation gate: Every candidate capability binding records separate command_declaration and tool_proof fields. command_declaration identifies where the exact command is declared. tool_proof identifies an independent manifest dependency, lockfile package, container/CI image/tool installation, or equivalent reproducible provider for the executable. The command/script text itself can NEVER satisfy tool_proof. An npm script `lint: eslint .` without an eslint dependency or environment provisioning proof is unsatisfiable and must be omitted. Before generating rows, audit every binding and discard any with missing/identical/circular tool proof; report it as detected-but-unsatisfied.

Keep the existing `strict_tdd` result if one binary policy is provably sufficient. If multiple distinct satisfiable methods or scope-dependent gates make that binary lossy, derive open project-specific signatures, generate a rubric candidate, and return exactly this blocking envelope:

```yaml
headline: "Choose project TDD policy"
reason: "Detected capabilities make binary strict_tdd lossy; choose the policy representation before SDD can continue."
selection_mode: single
options:
  strict:
    description: "Use the existing binary strict_tdd policy and its default evidence requirements."
  rubric:
    description: "Use the generated project-specific rubric with strictest-wins matching and satisfiable evidence methods."
allowed_answers: strict|rubric
instruction: "STOP: do not continue to downstream phases. Do not choose on the user's behalf."
```

STOP: do not continue to downstream phases. Before a valid answer, return the candidate but persist no selected policy or active rubric. Answer `strict`: persist `strict_tdd: true` and no consumer-visible active rubric. Answer `rubric`: submit the candidate to the canonical compiler; only its verified activation may persist `strict_tdd: false` plus the active authoritative rubric.

Signatures classify production implementation/work-type diffs (source, boundary/API, UI, migration, docs); test paths only supplement. MODE enum: `skip < standard < strict-tdd`. `strict-tdd` means a full test-first cycle; `standard` requires evidence without mandatory test-first ordering; `skip` has no automated test gate unless another matching row unions evidence. `default` is selected ONLY when no non-default signature matches. Never populate `default` by unioning all detected methods. When any non-default row matches, default does not join the union; all matching non-default rows use mechanical strictest-wins MODE precedence and union evidence/discipline requirements. The compiler serializes exactly one rubric-mode Engram section `## TDD RUBRIC (per-work-type — AUTHORITATIVE)` with `Status: active/authoritative.` and table `| Signature (detectable trigger in the diff) | MODE | Disciplines / evidence | Source |`; Source is `generated` or `manual`. OpenSpec `testing:` mirrors active/provenance semantics. Re-init with rubric selected preserves manual rows exactly and replaces generated rows deterministically. Upsert the canonical `sdd-init/{project}` policy artifact; never append a second rubric. Selecting strict after an existing rubric requires a visible destructive diff and explicit confirmation; then upsert `strict_tdd: true` with no active rubric (Engram revisions recover history). Selecting rubric submits the candidate to compiler activation; only verified activation persists `strict_tdd: false` plus exactly one active rubric; hybrid writes both and none returns inline.

OpenSpec writes this canonical active schema exactly; testing.rubric.active is the only active OpenSpec path. Reject alternate active keys such as `rubric_status`; Re-init reads only `testing.rubric.active`. The consumer stays path-agnostic and consumes active/authoritative data only.

```yaml
strict_tdd: false
testing:
  policy: rubric
  rubric:
    active: true
    authoritative: true
    mode_order: [skip, standard, strict-tdd]
    resolution:
      matching: all-rows
      mode: strictest-wins
      evidence: union
    bindings: [...]  # each has method, scope/signature coverage, command, command_declaration, tool_proof
    rows: [...]      # each has signature, mode exact enum, disciplines/evidence binding refs, source generated|manual
    default: {...}   # selective, exact enum, source
  detected_but_unsatisfied: [...]
```

```yaml
strict_tdd: true
testing:
  policy: strict
  # rubric: absent (not active:false, not candidate, no rows)
```

Structural validator directive: preserve the producer contract above; validate only structural bundle integrity and return `structure-valid/pending`. Candidate commands are data and never execute. No field named `provider` is accepted; semantic proof and activation remain later-unit work.

<!-- rubric-validator:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL
b=${1-}; [ "$#" = 1 ] && [ -d "$b" ] || exit 2
bad() { printf '%s\n' "invalid rubric structure: $*" >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad scalar; awk 'END { exit NR != 1 }' "$1" || bad scalar; IFS= read -r _one < "$1" || :; [ -n "${_one-}" ] || bad scalar; printf %s "$_one"; }
v() { one "$1/$2"; }
has() { case " $1 " in *" $2 "*) return 0;; *) return 1;; esac; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad path;; esac; }
walk() { _walk_p=; _walk_rest=${1#/}; while [ -n "$_walk_rest" ]; do _walk_part=${_walk_rest%%/*}; case "$_walk_rest" in */*) _walk_rest=${_walk_rest#*/};; *) _walk_rest=;; esac; _walk_p=$_walk_p/$_walk_part; [ ! -L "$_walk_p" ] || bad symlink; done; }
confine() { _conf_rel=$1; _conf_type=$2; safe "$_conf_rel"; walk "$root"; _conf_p=$root; _conf_rest=$_conf_rel; while [ -n "$_conf_rest" ]; do _conf_part=${_conf_rest%%/*}; case "$_conf_rest" in */*) _conf_rest=${_conf_rest#*/};; *) _conf_rest=;; esac; _conf_p=$_conf_p/$_conf_part; [ ! -L "$_conf_p" ] || bad symlink; done; case "$_conf_type" in f) [ -f "$_conf_p" ];; d) [ -d "$_conf_p" ];; esac || bad target; }
list() { _list_d=$1; _list_min=${2-1}; [ -d "$_list_d" ] && [ ! -L "$_list_d" ] || bad list; _list_n=0; for _list_f in "$_list_d"/*; do [ -e "$_list_f" ] || continue; [ -f "$_list_f" ] && [ ! -L "$_list_f" ] || bad list; [ "$(basename "$_list_f")" = "$(printf %03d "$_list_n")" ] || bad order; one "$_list_f" >/dev/null; _list_n=$((_list_n+1)); done; [ "$_list_n" -ge "$_list_min" ] || bad list; n=$_list_n; }
refs() { _refs_d=$1; _refs_all=$2; list "$_refs_d" "${3-1}"; for _refs_f in "$_refs_d"/*; do [ -e "$_refs_f" ] || continue; has "$_refs_all" "$(one "$_refs_f")" || bad "reference:$_refs_d"; done; }
inlist() { for _in_f in "$1"/*; do [ -e "$_in_f" ] && [ "$(one "$_in_f")" = "$2" ] && return 0; done; return 1; }
id() { _id_d=$1; _id_k=$(v "$_id_d" kind); case "$_id_k" in ''|*[!a-z-]*) bad kind;; esac; set -- $(cksum "$_id_d/identity"); _id_want="v1:$_id_k:$1:$2"; [ "$(v "$_id_d" id)" = "$_id_want" ] || bad id; printf %s "$_id_want"; }
fp() { (cd "$1" && find . -type f ! -name id ! -name identity ! -name fingerprint -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1 ":" $2}'; }
fps() { for f in "$1"/*; do [ -e "$f" ] || continue; x=$(one "$f"); for d in "$b/facts/"*; do [ "$(v "$d" id)" = "$x" ] && printf '%s:%s\n' "$x" "$(fp "$d")"; done; done | cksum | awk '{print $1 ":" $2}'; }
uniq() { has "$seen" "$1" && bad duplicate; seen="$seen $1"; all="$all $1"; }
records() { _rec_top=$1; _rec_min=$2; _rec_fn=$3; [ -d "$_rec_top" ] && [ ! -L "$_rec_top" ] || bad records; _rec_n=0; for _rec_d in "$_rec_top"/*; do [ -e "$_rec_d" ] || continue; [ -d "$_rec_d" ] && [ ! -L "$_rec_d" ] || bad records; "$_rec_fn" "$_rec_d"; _rec_n=$((_rec_n+1)); done; [ "$_rec_n" -ge "$_rec_min" ] || bad records; }
[ "$(v "$b" schema)" = v1 ] && [ "$(v "$b" candidate-schema)" = v1 ] || bad schema
find "$b" -name provider -print | grep . >/dev/null && bad provider
root=$(v "$b" root); case "$root" in /*) ;; *) bad root;; esac; case "$root" in *'*'*|*'?'*|*'['*) bad root;; esac; [ -d "$root" ] && [ ! -L "$root" ] || bad root; walk "$root"
[ "$(v "$b/resolution" matching)" = all-rows ] && [ "$(v "$b/resolution" mode)" = strictest-wins ] && [ "$(v "$b/resolution" default)" = unmatched-only ] || bad resolution
seen= all= obs= facts= bindings= attestations= rows= defaults=0
obsrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" channel)" in file) loc=$(v "$d" locator); confine "$loc" f; set -- $(cksum "$root/$loc"); [ "$(v "$d" checksum)" = "$1 $2" ] || bad checksum;; codegraph) [ "$(v "$d" status)" = untrusted ] && [ "$(v "$d" scope)" = scope-only ] || bad codegraph; v "$d" query >/dev/null; v "$d" index-revision >/dev/null; v "$d" symbol >/dev/null; safe "$(v "$d" repo-path)";; *) bad observation;; esac; v "$d" source >/dev/null; v "$d" provenance >/dev/null; obs="$obs $x"; }
factrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" status)" in known|unknown|absent|unsatisfied) ;; *) bad fact;; esac; [ ! -e "$d/provider" ] || bad provider; v "$d" source >/dev/null; v "$d" provenance >/dev/null; v "$d" source-path >/dev/null; v "$d" evidence-kind >/dev/null; v "$d" adapter >/dev/null; refs "$d/observation-refs" "$obs"; [ "$(v "$d" fingerprint)" = "$(fp "$d")" ] || bad fingerprint; facts="$facts $x"; }
attrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" schema)" = v1 ] && [ "$(v "$d" attestation-id)" = "$x" ] || bad attestation; for k in adapter-id adapter-version adapter-bytes-digest input-digest status claim-kind executable method scope; do v "$d" "$k" >/dev/null; done; oi=$(v "$d" observation-id); [ ! -e "$d/observation-refs" ] && [ -n "$oi" ] && has "$obs" "$oi" || bad reference; safe "$(v "$d" source-locator)"; attestations="$attestations $x"; }
bindrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" method)" in unit|integration|e2e|coverage|lint|typecheck|format|build) ;; *) bad method;; esac; v "$d" scope >/dev/null; v "$d" signature-coverage >/dev/null; [ -d "$d/context" ] && [ ! -L "$d/context" ] || bad context; [ "$(v "$d/context" root)" = "$root" ] || bad root; [ "$(v "$d/context" workdir)" = . ] || confine "$(v "$d/context" workdir)" d; v "$d/context" executable >/dev/null; list "$d/context/argv"; list "$d/platforms"; list "$d/env" 0; list "$d/requirements" 0; refs "$d/fact-refs" "$facts"; dr=$(v "$d" declaration-ref); tr=$(v "$d" tool-proof-ref); [ "$dr" != "$tr" ] && inlist "$d/fact-refs" "$dr" && inlist "$d/fact-refs" "$tr" || bad reference; refs "$d/attestation-refs" "$attestations" 0; bindings="$bindings $x"; }
bindpath() { for _bind_d in "$b/bindings/"*; do [ "$(v "$_bind_d" id)" = "$1" ] && { printf %s "$_bind_d"; return; }; done; bad reference; }
linked() { _link_row=$1; _link_kind=$2; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); for _link_item in "$_link_bind/$_link_kind/"*; do [ -e "$_link_item" ] && inlist "$_link_row/$_link_kind" "$(one "$_link_item")" || bad link; done; done; for _link_item in "$_link_row/$_link_kind/"*; do [ -e "$_link_item" ] || continue; _link_found=; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); inlist "$_link_bind/$_link_kind" "$(one "$_link_item")" && _link_found=1; done; [ -n "$_link_found" ] || bad link; done; }
rowrec() { d=$1; x=$(id "$d"); uniq "$x"; m=$(v "$d" mode); case "$m" in skip|standard|strict-tdd) ;; *) bad mode;; esac; st=$(v "$d" state); case "$st" in pending|confirmed|rejected|stale|conflict) ;; *) bad state;; esac; case "$(v "$d" source)" in generated|manual) ;; *) bad source;; esac; sel=$(v "$d" selection); list "$d/trigger-paths" 0; if [ "$sel" = unmatched-only ]; then [ "$(v "$d" signature)" = default ] && [ "$(v "$d" trigger-kind)" = unmatched ] && [ "$n" = 0 ] || bad default; defaults=$((defaults+1)); else [ "$sel" = specific ] && [ "$(v "$d" trigger-kind)" = path ] && [ "$n" -gt 0 ] || bad trigger; fi; refs "$d/fact-refs" "$facts"; [ "$(v "$d" fact-fingerprint)" = "$(fps "$d/fact-refs")" ] || bad fingerprint; list "$d/disciplines" 0; refs "$d/binding-refs" "$bindings" 0; bn=$n; refs "$d/attestation-refs" "$attestations" 0; an=$n; [ "$m" = skip ] || { [ "$bn" -gt 0 ] && [ "$an" -gt 0 ] && linked "$d" fact-refs && linked "$d" attestation-refs; } || bad attestation; [ "$st" != confirmed ] || { v "$d" confirmation-answer >/dev/null; v "$d" confirmer >/dev/null; }; rows="$rows $x"; }
qrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" kind)" = question ] && [ "$(v "$d" blocking)" = true ] || bad question; v "$d" prompt >/dev/null; case "$(v "$d" state)" in open|answered|rejected) ;; *) bad question;; esac; refs "$d/fact-refs" "$facts"; list "$d/allowed-answers"; has "$rows" "$(v "$d" row-ref)" || bad reference; }
rowpath() { for _row_d in "$b/rows/"*; do [ "$(v "$_row_d" id)" = "$1" ] && { printf %s "$_row_d"; return; }; done; bad reference; }
reinitrec() { d=$1; rr=$(v "$d" row-ref); rd=$(rowpath "$rr"); prior=$(v "$d" prior-fingerprint); now=$(fps "$rd/fact-refs"); case "$(v "$d" state)" in preserved) [ "$prior" = "$now" ] || bad reinit;; stale) [ "$prior" != "$now" ] && [ "$(v "$rd" state)" = stale ] || bad reinit;; *) bad reinit;; esac; }
records "$b/observations" 1 obsrec; records "$b/facts" 1 factrec; records "$b/attestations" 0 attrec; records "$b/bindings" 0 bindrec; records "$b/rows" 1 rowrec; [ "$defaults" = 1 ] || bad default; records "$b/questions" 0 qrec
for d in "$b/rows"/*; do [ -e "$d" ] || continue; st=$(v "$d" state); case "$st" in pending|stale|conflict) found=; for q in "$b/questions"/*; do [ -d "$q" ] && [ "$(v "$q" row-ref)" = "$(v "$d" id)" ] && [ "$(v "$q" state)" = open ] && [ "$(v "$q" blocking)" = true ] && found=1; done; [ -n "$found" ] || bad question;; esac; done
records "$b/reinit" 0 reinitrec; refs "$b/record-order" "$all"; [ "$n" = "$(set -- $all; printf %s "$#")" ] || bad order; prev=; for f in "$b/record-order"/*; do [ -e "$f" ] || continue; x=$(one "$f"); [ -z "$prev" ] || [ "$prev" \< "$x" ] || bad order; prev=$x; done
printf 'structure-valid/pending\n'
<!-- rubric-validator:end -->
<!-- rubric-adapter-records:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL; umask 077
bad() { printf '%s\n' 'invalid adapter record input' >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad; [ "$(awk 'END { print NR }' "$1")" = 1 ] || bad; x=$(awk 'NR == 1 { print; exit }' "$1"); [ -n "$x" ] || bad; printf %s "$x"; }
v() { one "$1/$2"; }
digest() { cksum "$1" | awk '{print $1 ":" $2}'; }
graphdigest() { for k in status scope query index-revision symbol repo-path source provenance; do printf '%s=' "$k"; v "$1" "$k"; printf '\n'; done | cksum | awk '{print $1 ":" $2}'; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad;; esac; }
walk() { p=; rest=${1#/}; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
confine() { safe "$1"; walk "$root"; p=$root; rest=$1; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; [ -f "$p" ] && [ ! -L "$p" ] || bad; printf %s "$p"; }
findid() { for d in "$1"/*; do [ -d "$d" ] && [ "$(v "$d" id)" = "$2" ] && { printf %s "$d"; return; }; done; bad; }
argvdigest() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] || continue; one "$f"; printf '\n'; done | cksum | awk '{print $1 ":" $2}'; }
emptylist() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] && return 1; done; return 0; }
sourcefact() { for rf in "$1/fact-refs"/*; do [ -f "$rf" ] || continue; fd=$(findid "$b/facts" "$(one "$rf")"); [ "$(v "$fd" adapter)" = "$2" ] && [ "$(v "$fd" evidence-kind)" = "$3" ] || continue; oid=$(one "$fd/observation-refs/000"); [ ! -e "$fd/observation-refs/001" ] || continue; od=$(findid "$b/observations" "$oid"); [ "$(v "$od" channel)" = file ] && [ "$(v "$od" locator)" = "$4" ] || continue; input=$(confine "$4"); [ "$(v "$od" checksum)" = "$(cksum "$input" | awk '{print $1 " " $2}')" ] || continue; printf %s "$input"; return; done; return 1; }
pair() { [ "$(argvdigest "$1/context/argv")" = "$5" ] && [ "$(v "$1/context" executable)" = "$6" ] && [ "$(v "$1" method)" = unit ] && [ "$(v "$1" scope)" = "$7" ] && [ "$(v "$1/context" workdir)" = . ] && emptylist "$1/context/env"; }
profile() { case "$2" in shell-v1) e=bash; s=project-root; a=3407402481:13; st=proven;; cnsic-python-v1) e=python; s=path-prefix:tests/unit; a=4044348251:33; st=proven;; gentle-ai-go-v1) e=go; s=module-root; a=272758782:11; st=proven;; codegraph-v1) printf '%s' 'unknown unknown scope-only none unknown'; return;; *) printf '%s' 'unknown unknown unknown none unknown'; return;; esac; pair "$1" "$2" x x "$a" "$e" "$s" || st=unknown; printf '%s %s %s %s %s' "$e" unit "$s" "$a" "$st"; }
worker() { wd=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-record.XXXXXX") || bad; chmod 700 "$wd" || bad; w=$wd/reviewed; cat > "$w" <<'EOF'
#!/bin/sh
set -eu
case "$1:$2:$3" in
shell-v1:command-declaration:README.md) grep -Fxq 'bash tests/run.sh' "$4" ;;
shell-v1:tool-proof:shell/.github/workflows/test.yml) awk 'NR==1&&$0=="      strategy:"{a=1} NR==2&&$0=="        matrix:"{b=1} NR==3&&$0=="          os: [ubuntu-latest, macos-latest]"{c=1} NR==4&&$0=="      runs-on: ${{ matrix.os }}"{d=1} NR==5&&$0=="      - name: Run regression tests"{e=1} NR==6&&$0=="        run: bash tests/run.sh"{f=1} END{exit !(NR==6&&a&&b&&c&&d&&e&&f)}' "$4" ;;
cnsic-python-v1:command-declaration:AGENTS.md) grep -Fxq 'Pre-deploy: python -m pytest tests/unit/ -n auto -q' "$4" ;;
cnsic-python-v1:tool-proof:requirements.txt) grep -Eq '^pytest[<>=!~]' "$4" && grep -Eq '^pytest-xdist[<>=!~]' "$4" ;;
gentle-ai-go-v1:command-declaration:CONTRIBUTING.md) grep -Fxq 'go test ./...' "$4" ;;
gentle-ai-go-v1:tool-proof:go.mod) awk 'NR==1&&$0=="module github.com/gentleman-programming/gentle-ai/v2"{a=1} NR==2&&$0=="go 1.25.10"{b=1} END{exit !(NR==2&&a&&b)}' "$4" ;;
codegraph-v1:scope-only:*) [ -d "$4" ] && [ ! -L "$4" ] || exit 1; for k in status scope query index-revision symbol repo-path source provenance; do [ -f "$4/$k" ] && [ ! -L "$4/$k" ] && [ "$(awk 'END { print NR }' "$4/$k")" = 1 ] && [ -n "$(awk 'NR == 1 { print; exit }' "$4/$k")" ] || exit 1; done; [ "$(awk 'NR == 1 { print; exit }' "$4/status")" = untrusted ] && [ "$(awk 'NR == 1 { print; exit }' "$4/scope")" = scope-only ] && [ "$(awk 'NR == 1 { print; exit }' "$4/repo-path")" = "$3" ] ;;
*) exit 1 ;;
esac
EOF
chmod 700 "$w" || bad; [ "$(digest "$w")" = '3823195233:1516' ] || bad; }
emit() { d=$stage/records/$(printf %03d "$n"); mkdir "$d" || bad; for pair in "schema:v1" "kind:attestation" "adapter-id:$adapter_id" "adapter-version:$adapter_version" "adapter-bytes-digest:$adapter_bytes_digest" "binding-id:$binding_id" "evidence-fact-id:$evidence_fact_id" "observation-id:$observation_id" "observation-digest:$observation_digest" "input-digest:$input_digest" "status:$status" "claim-kind:$claim_kind" "executable:$executable" "argv-digest:$argv_digest" "method:$method" "scope:$scope" "source-locator:$source_locator"; do k=${pair%%:*}; z=${pair#*:}; printf '%s\n' "$z" > "$d/$k" || bad; done; { printf 'adapter-bytes-digest=%s\n' "$adapter_bytes_digest"; printf 'adapter-id=%s\n' "$adapter_id"; printf 'adapter-version=%s\n' "$adapter_version"; printf 'argv-digest=%s\n' "$argv_digest"; printf 'binding-id=%s\n' "$binding_id"; printf 'claim-kind=%s\n' "$claim_kind"; printf 'evidence-fact-id=%s\n' "$evidence_fact_id"; printf 'executable=%s\n' "$executable"; printf 'input-digest=%s\n' "$input_digest"; printf 'method=%s\n' "$method"; printf 'observation-digest=%s\n' "$observation_digest"; printf 'observation-id=%s\n' "$observation_id"; printf 'schema=v1\n'; printf 'scope=%s\n' "$scope"; printf 'source-locator=%s\n' "$source_locator"; printf 'status=%s\n' "$status"; } > "$d/identity" || bad; id="v1:attestation:$(digest "$d/identity")"; printf '%s\n' "$id" > "$d/id"; printf '%s\n' "$id" > "$d/attestation-id"; n=$((n+1)); }
[ "$#" = 3 ] && [ "$1" = records ] || exit 2
b=$2; out=$3; [ -d "$b" ] && [ ! -L "$b" ] && [ ! -e "$out" ] && [ ! -L "$out" ] || bad
parent=$(dirname "$out"); name=$(basename "$out"); [ -d "$parent" ] && [ ! -L "$parent" ] || bad; case "$name" in ''|.*|*[!A-Za-z0-9_-]*) bad;; esac
root=$(v "$b" root); case "$root" in /*) ;; *) bad;; esac; [ -d "$root" ] && [ ! -L "$root" ] || bad
stage=$parent/.${name}.stage.$$; wd=; trap 'rm -rf "$stage" "${wd:-}"' EXIT HUP INT TERM; mkdir -m 700 "$stage" "$stage/records" || bad; n=0
worker
for bd in "$b/bindings"/*; do [ -d "$bd" ] || continue; binding_id=$(v "$bd" id); for rf in "$bd/fact-refs"/*; do [ -f "$rf" ] || continue; evidence_fact_id=$(one "$rf"); fd=$(findid "$b/facts" "$evidence_fact_id"); adapter_id=$(v "$fd" adapter); claim_kind=$(v "$fd" evidence-kind); observation_id=$(one "$fd/observation-refs/000"); [ ! -e "$fd/observation-refs/001" ] || bad; od=$(findid "$b/observations" "$observation_id"); adapter_version=v1; adapter_bytes_digest=$(digest "$w"); set -- $(profile "$bd" "$adapter_id" || printf '%s' 'unknown unknown unknown none unknown'); executable=$1; method=$2; scope=$3; argv_digest=$4; status=$5
[ -e "$fd/adapter-version" ] && [ "$(v "$fd" adapter-version)" != v1 ] && adapter_version=unknown
case "$(v "$od" channel)" in file) source_locator=$(v "$od" locator); input=$(confine "$source_locator"); set -- $(cksum "$input"); [ "$(v "$od" checksum)" = "$1 $2" ] || bad; observation_digest=$(digest "$input"); input_digest=$observation_digest; if [ "$status" = proven ] && ! "$w" "$adapter_id" "$claim_kind" "$source_locator" "$input"; then status=unknown; elif [ "$status" = proven ] && [ "$adapter_id:$claim_kind:$source_locator" = gentle-ai-go-v1:tool-proof:go.mod ]; then status=unsatisfied; fi;; codegraph) for k in status scope query index-revision symbol repo-path source provenance; do v "$od" "$k" >/dev/null; done; source_locator=$(v "$od" repo-path); safe "$source_locator"; observation_digest=$(graphdigest "$od"); input_digest=$observation_digest; executable=unknown; method=unknown; scope=scope-only; argv_digest=none; status=unknown;; *) bad;; esac
[ "$adapter_version" = v1 ] || status=unknown; case "$adapter_id" in shell-v1|cnsic-python-v1|gentle-ai-go-v1|codegraph-v1) ;; *) adapter_version=unknown; adapter_bytes_digest=none; status=unknown;; esac; emit; done; done
[ "$n" -gt 0 ] || bad; mv "$stage" "$out"; trap - EXIT HUP INT TERM
<!-- rubric-adapter-records:end -->
<!-- rubric-adapter-gate:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL; umask 077
bad() { printf '%s\n' 'invalid adapter gate input' >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad; [ "$(awk 'END {print NR}' "$1")" = 1 ] || bad; LC_ALL=C tr -d '\000' < "$1" | cmp -s "$1" - || bad; x=$(awk 'NR==1{print;exit}' "$1"); [ -n "$x" ] || bad; printf %s "$x"; }
v() { one "$1/$2"; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
hex() { od -An -v -tx1 "$1" | tr -d ' \n'; }
bundle_digest() { (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad;; esac; }
walk() { p=; rest=${1#/}; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
guard_dir() { walk "$1"; [ -d "$1" ] && [ ! -L "$1" ] || bad; }
guard_file() { walk "$1"; [ -f "$1" ] && [ ! -L "$1" ] || bad; }
guard_tree() { guard_dir "$1"; [ -z "$(find "$1" -type l -print -quit)" ] || bad; }
empty() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] && return 1; done; return 0; }
snapshot_metadata() { snap=$1; mkdir "$snap" || bad; top=; case "$root" in "$b"/*) top=${root#"$b"/}; top=${top%%/*};; esac; for e in "$b"/* "$b"/.[!.]* "$b"/..?*; do [ -e "$e" ] || continue; [ -n "$top" ] && [ "$(basename "$e")" = "$top" ] && continue; cp -a "$e" "$snap/" || bad; done; }
snapshot_records() { snap=$1; mkdir "$snap" || bad; cp -a "$rs/records" "$snap/records" || bad; }
evidence_guard() { for od in "$b/observations"/*; do [ -d "$od" ] && [ ! -L "$od" ] || bad; [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); safe "$loc"; guard_file "$live_root/$loc"; done; }
snapshot_evidence() { mkdir "$evidence" || bad; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); want=$(v "$od" checksum); src=$live_root/$loc; [ "$(cksum "$src" | awk '{print $1" "$2}')" = "$want" ] || bad; mkdir -p "$evidence/$(dirname "$loc")" || bad; cp -p "$src" "$evidence/$loc" || bad; [ "$(cksum "$evidence/$loc" | awk '{print $1" "$2}')" = "$want" ] || bad; done; }
verify_live() { evidence_guard; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); [ "$(cksum "$live_root/$loc" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] || bad; done; }
fid() { found=; for d in "$1"/*; do [ -d "$d" ] && [ "$(v "$d" id)" = "$2" ] || continue; [ -z "$found" ] || bad; found=$d; done; [ -n "$found" ] || bad; printf %s "$found"; }
argv() { for f in "$1"/*; do [ -f "$f" ] && one "$f" && printf '\n'; done | cksum | awk '{print $1":"$2}'; }
source_ok() { case "$1:$2:$3" in cnsic-python-v1:command-declaration:AGENTS.md) grep -Fxq 'Pre-deploy: python -m pytest tests/unit/ -n auto -q' "$4";; cnsic-python-v1:tool-proof:requirements.txt) grep -Eq '^pytest[<>=!~]' "$4" && grep -Eq '^pytest-xdist[<>=!~]' "$4";; shell-v1:command-declaration:README.md) grep -Fxq 'bash tests/run.sh' "$4";; shell-v1:tool-proof:shell/.github/workflows/test.yml) awk 'NR==1&&$0=="      strategy:"{a=1} NR==2&&$0=="        matrix:"{b=1} NR==3&&$0=="          os: [ubuntu-latest, macos-latest]"{c=1} NR==4&&$0=="      runs-on: ${{ matrix.os }}"{d=1} NR==5&&$0=="      - name: Run regression tests"{e=1} NR==6&&$0=="        run: bash tests/run.sh"{f=1} END{exit !(NR==6&&a&&b&&c&&d&&e&&f)}' "$4";; gentle-ai-go-v1:command-declaration:CONTRIBUTING.md) grep -Fxq 'go test ./...' "$4";; gentle-ai-go-v1:tool-proof:go.mod) awk 'NR==1&&$0=="module github.com/gentleman-programming/gentle-ai/v2"{a=1} NR==2&&$0=="go 1.25.10"{b=1} END{exit !(NR==2&&a&&b)}' "$4";; *) return 1;; esac; }
profile() { case "$1" in shell-v1) printf '%s\n' 'bash unit project-root 3407402481:13 proven .';; cnsic-python-v1) printf '%s\n' 'python unit path-prefix:tests/unit 4044348251:33 proven tests/unit';; gentle-ai-go-v1) printf '%s\n' 'go unit module-root 272758782:11';; *) bad;; esac; }
# shellcheck disable=SC2046
record() { f=$1; bd=$2; oid=$(one "$f/observation-refs/000"); [ ! -e "$f/observation-refs/001" ] && [ "$(v "$f" status)" = known ] || bad; od=$(fid "$b/observations" "$oid"); [ "$(v "$od" channel)" = file ] || bad; loc=$(v "$od" locator); input=$root/$loc; [ -f "$input" ] && [ ! -L "$input" ] && [ "$(cksum "$input" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] && source_ok "$(v "$f" adapter)" "$(v "$f" evidence-kind)" "$loc" "$input" || bad; set -- $(profile "$(v "$f" adapter)"); exe=$1 method=$2 scope=$3 ad=$4; status=${5-unsatisfied}; coverage=${6-.}; [ "$(v "$bd/context" executable)" = "$exe" ] && [ "$(v "$bd" method)" = "$method" ] && [ "$(v "$bd" scope)" = "$scope" ] && [ "$(v "$bd" signature-coverage)" = "$coverage" ] && [ "$(argv "$bd/context/argv")" = "$ad" ] || bad; found=; for r in "$rs/records"/*; do [ -d "$r" ] && [ ! -L "$r" ] || bad; [ "$(v "$r" binding-id)" = "$(v "$bd" id)" ] && [ "$(v "$r" evidence-fact-id)" = "$(v "$f" id)" ] || continue; [ -z "$found" ] || bad; found=$r; done; [ -n "$found" ] || bad; dg=$(dig "$input"); [ "$(v "$found" schema)" = v1 ] && [ "$(v "$found" kind)" = attestation ] && [ "$(v "$found" adapter-id)" = "$(v "$f" adapter)" ] && [ "$(v "$found" adapter-version)" = v1 ] && [ "$(v "$found" adapter-bytes-digest)" = 3823195233:1516 ] && [ "$(v "$found" observation-id)" = "$oid" ] && [ "$(v "$found" observation-digest)" = "$dg" ] && [ "$(v "$found" input-digest)" = "$dg" ] && [ "$(v "$found" source-locator)" = "$loc" ] && [ "$(v "$found" claim-kind)" = "$(v "$f" evidence-kind)" ] && [ "$(v "$found" executable)" = "$exe" ] && [ "$(v "$found" argv-digest)" = "$ad" ] && [ "$(v "$found" method)" = "$method" ] && [ "$(v "$found" scope)" = "$scope" ] && [ "$(v "$found" status)" = "$status" ] || bad; { for k in adapter-bytes-digest adapter-id adapter-version argv-digest binding-id claim-kind evidence-fact-id executable input-digest method observation-digest observation-id; do printf '%s=%s\n' "$k" "$(v "$found" "$k")"; done; printf 'schema=v1\nscope=%s\nsource-locator=%s\nstatus=%s\n' "$scope" "$loc" "$status"; } > "$wd/identity"; id="v1:attestation:$(dig "$wd/identity")"; cmp -s "$found/identity" "$wd/identity" && [ "$(v "$found" id)" = "$id" ] && [ "$(v "$found" attestation-id)" = "$id" ] || bad; [ "$status" = proven ] || bad; printf %s "$found"; }
v() { one "$1/$2"; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
hex() { od -An -v -tx1 "$1" | tr -d ' \n'; }
bundle_digest() { (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad;; esac; }
walk() { p=; rest=${1#/}; while [ -n "$rest" ]; do x=${rest%%/*}; case "$rest" in */*) rest=${rest#*/};; *) rest=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
guard_dir() { walk "$1"; [ -d "$1" ] && [ ! -L "$1" ] || bad; }
guard_file() { walk "$1"; [ -f "$1" ] && [ ! -L "$1" ] || bad; }
guard_tree() { guard_dir "$1"; [ -z "$(find "$1" -type l -print -quit)" ] || bad; }
empty() { [ -d "$1" ] && [ ! -L "$1" ] || bad; for f in "$1"/*; do [ -e "$f" ] && return 1; done; return 0; }
snapshot_metadata() { snap=$1; mkdir "$snap" || bad; top=; case "$root" in "$b"/*) top=${root#"$b"/}; top=${top%%/*};; esac; for e in "$b"/* "$b"/.[!.]* "$b"/..?*; do [ -e "$e" ] || continue; [ -n "$top" ] && [ "$(basename "$e")" = "$top" ] && continue; cp -a "$e" "$snap/" || bad; done; }
snapshot_records() { snap=$1; mkdir "$snap" || bad; cp -a "$rs/records" "$snap/records" || bad; }
evidence_guard() { for od in "$b/observations"/*; do [ -d "$od" ] && [ ! -L "$od" ] || bad; [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); safe "$loc"; guard_file "$live_root/$loc"; done; }
snapshot_evidence() { mkdir "$evidence" || bad; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); want=$(v "$od" checksum); src=$live_root/$loc; [ "$(cksum "$src" | awk '{print $1" "$2}')" = "$want" ] || bad; mkdir -p "$evidence/$(dirname "$loc")" || bad; cp -p "$src" "$evidence/$loc" || bad; [ "$(cksum "$evidence/$loc" | awk '{print $1" "$2}')" = "$want" ] || bad; done; }
verify_live() { evidence_guard; for od in "$b/observations"/*; do [ "$(v "$od" channel)" = file ] || continue; loc=$(v "$od" locator); [ "$(cksum "$live_root/$loc" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] || bad; done; }
fid() { found=; for d in "$1"/*; do [ -d "$d" ] && [ "$(v "$d" id)" = "$2" ] || continue; [ -z "$found" ] || bad; found=$d; done; [ -n "$found" ] || bad; printf %s "$found"; }
argv() { for f in "$1"/*; do [ -f "$f" ] && one "$f" && printf '\n'; done | cksum | awk '{print $1":"$2}'; }
source_ok() { case "$1:$2:$3" in cnsic-python-v1:command-declaration:AGENTS.md) grep -Fxq 'Pre-deploy: python -m pytest tests/unit/ -n auto -q' "$4";; cnsic-python-v1:tool-proof:requirements.txt) grep -Eq '^pytest[<>=!~]' "$4" && grep -Eq '^pytest-xdist[<>=!~]' "$4";; shell-v1:command-declaration:README.md) grep -Fxq 'bash tests/run.sh' "$4";; shell-v1:tool-proof:shell/.github/workflows/test.yml) awk 'NR==1&&$0=="      strategy:"{a=1} NR==2&&$0=="        matrix:"{b=1} NR==3&&$0=="          os: [ubuntu-latest, macos-latest]"{c=1} NR==4&&$0=="      runs-on: ${{ matrix.os }}"{d=1} NR==5&&$0=="      - name: Run regression tests"{e=1} NR==6&&$0=="        run: bash tests/run.sh"{f=1} END{exit !(NR==6&&a&&b&&c&&d&&e&&f)}' "$4";; gentle-ai-go-v1:command-declaration:CONTRIBUTING.md) grep -Fxq 'go test ./...' "$4";; gentle-ai-go-v1:tool-proof:go.mod) awk 'NR==1&&$0=="module github.com/gentleman-programming/gentle-ai/v2"{a=1} NR==2&&$0=="go 1.25.10"{b=1} END{exit !(NR==2&&a&&b)}' "$4";; *) return 1;; esac; }
profile() { case "$1" in shell-v1) printf '%s\n' 'bash unit project-root 3407402481:13 proven .';; cnsic-python-v1) printf '%s\n' 'python unit path-prefix:tests/unit 4044348251:33 proven tests/unit';; gentle-ai-go-v1) printf '%s\n' 'go unit module-root 272758782:11';; *) bad;; esac; }
# shellcheck disable=SC2046
record() { f=$1; bd=$2; oid=$(one "$f/observation-refs/000"); [ ! -e "$f/observation-refs/001" ] && [ "$(v "$f" status)" = known ] || bad; od=$(fid "$b/observations" "$oid"); [ "$(v "$od" channel)" = file ] || bad; loc=$(v "$od" locator); input=$root/$loc; [ -f "$input" ] && [ ! -L "$input" ] && [ "$(cksum "$input" | awk '{print $1" "$2}')" = "$(v "$od" checksum)" ] && source_ok "$(v "$f" adapter)" "$(v "$f" evidence-kind)" "$loc" "$input" || bad; set -- $(profile "$(v "$f" adapter)"); exe=$1 method=$2 scope=$3 ad=$4; status=${5-unsatisfied}; coverage=${6-.}; [ "$(v "$bd/context" executable)" = "$exe" ] && [ "$(v "$bd" method)" = "$method" ] && [ "$(v "$bd" scope)" = "$scope" ] && [ "$(v "$bd" signature-coverage)" = "$coverage" ] && [ "$(argv "$bd/context/argv")" = "$ad" ] || bad; found=; for r in "$rs/records"/*; do [ -d "$r" ] && [ ! -L "$r" ] || bad; [ "$(v "$r" binding-id)" = "$(v "$bd" id)" ] && [ "$(v "$r" evidence-fact-id)" = "$(v "$f" id)" ] || continue; [ -z "$found" ] || bad; found=$r; done; [ -n "$found" ] || bad; dg=$(dig "$input"); [ "$(v "$found" schema)" = v1 ] && [ "$(v "$found" kind)" = attestation ] && [ "$(v "$found" adapter-id)" = "$(v "$f" adapter)" ] && [ "$(v "$found" adapter-version)" = v1 ] && [ "$(v "$found" adapter-bytes-digest)" = 3823195233:1516 ] && [ "$(v "$found" observation-id)" = "$oid" ] && [ "$(v "$found" observation-digest)" = "$dg" ] && [ "$(v "$found" input-digest)" = "$dg" ] && [ "$(v "$found" source-locator)" = "$loc" ] && [ "$(v "$found" claim-kind)" = "$(v "$f" evidence-kind)" ] && [ "$(v "$found" executable)" = "$exe" ] && [ "$(v "$found" argv-digest)" = "$ad" ] && [ "$(v "$found" method)" = "$method" ] && [ "$(v "$found" scope)" = "$scope" ] && [ "$(v "$found" status)" = "$status" ] || bad; { for k in adapter-bytes-digest adapter-id adapter-version argv-digest binding-id claim-kind evidence-fact-id executable input-digest method observation-digest observation-id; do printf '%s=%s\n' "$k" "$(v "$found" "$k")"; done; printf 'schema=v1\nscope=%s\nsource-locator=%s\nstatus=%s\n' "$scope" "$loc" "$status"; } > "$wd/identity"; id="v1:attestation:$(dig "$wd/identity")"; cmp -s "$found/identity" "$wd/identity" && [ "$(v "$found" id)" = "$id" ] && [ "$(v "$found" attestation-id)" = "$id" ] || bad; [ "$status" = proven ] || bad; printf %s "$found"; }
ms() { _ms_n=$(printf %s "$1" | wc -c | tr -d ' '); printf 'S%08d' "$_ms_n"; printf %s "$1"; }
mval() { one "$1" >/dev/null; LC_ALL=C tr -d '\000' < "$1" | cmp -s "$1" - || bad; one "$1"; }
mf() { printf F; ms "$1"; ms "$2"; }
mr() { printf R; ms "$1"; ms "$2"; }
ml() { _ml_k=$1; _ml_d=$2; _ml_o=$3; _ml_t=$wd/model-list.$$; : > "$_ml_t"; for _ml_f in "$_ml_d"/*; do [ -e "$_ml_f" ] || continue; mval "$_ml_f" >> "$_ml_t"; printf '\n' >> "$_ml_t"; done; [ "$_ml_o" != set ] || LC_ALL=C sort -o "$_ml_t" "$_ml_t"; _ml_n=$(awk 'END {print NR+0}' "$_ml_t"); printf A; ms "$_ml_k"; printf '%08d' "$_ml_n"; while IFS= read -r _ml_x; do ms "$_ml_x"; done < "$_ml_t"; rm -f "$_ml_t"; }
mvs() { _mvs_k=$1; shift; printf A; ms "$_mvs_k"; printf '%08d' "$#"; for _mvs_x; do ms "$_mvs_x"; done; }
mid() { for _mid_d in "$b/$1"/*; do [ -d "$_mid_d" ] && mval "$_mid_d/id"; printf '\n'; done | LC_ALL=C sort; }
mrefs() { _mr_g=$1; _mr_d=$2; for _mr_f in "$_mr_d"/*; do [ -e "$_mr_f" ] || continue; fid "$b/$_mr_g" "$(mval "$_mr_f")" >/dev/null; done; }
mobs() { _mo_d=$1; _mo_id=$2; mr observation "$_mo_id"; mf id "$_mo_id"; mf channel "$(mval "$_mo_d/channel")"; case "$(mval "$_mo_d/channel")" in file) mf locator "$(mval "$_mo_d/locator")"; mf checksum "$(mval "$_mo_d/checksum")";; codegraph) for _mo_k in query index-revision symbol repo-path; do mf "$_mo_k" "$(mval "$_mo_d/$_mo_k")"; done;; *) bad;; esac; mf source "$(mval "$_mo_d/source")"; mf provenance "$(mval "$_mo_d/provenance")"; [ "$(mval "$_mo_d/channel")" != codegraph ] || { mf status "$(mval "$_mo_d/status")"; mf scope "$(mval "$_mo_d/scope")"; }; }
mfact() { _mf_d=$1; _mf_id=$2; mr fact "$_mf_id"; mf id "$_mf_id"; for _mf_k in status source provenance source-path evidence-kind adapter; do mf "$_mf_k" "$(mval "$_mf_d/$_mf_k")"; done; mrefs observations "$_mf_d/observation-refs"; ml observation_refs "$_mf_d/observation-refs" set; }
matt() { _ma_d=$1; _ma_id=$2; mr attestation "$_ma_id"; mf id "$_ma_id"; for _ma_k in status adapter-id adapter-version adapter-bytes-digest claim-kind executable argv-digest method scope source-locator observation-id observation-digest input-digest binding-id evidence-fact-id; do mf "$_ma_k" "$(mval "$_ma_d/$_ma_k")"; done; fid "$b/observations" "$(mval "$_ma_d/observation-id")" >/dev/null; fid "$b/bindings" "$(mval "$_ma_d/binding-id")" >/dev/null; fid "$b/facts" "$(mval "$_ma_d/evidence-fact-id")" >/dev/null; }
mbind() { _mb_d=$1; _mb_id=$2; mr binding "$_mb_id"; mf id "$_mb_id"; for _mb_k in method scope signature-coverage; do mf "$_mb_k" "$(mval "$_mb_d/$_mb_k")"; done; printf C; ms command; ms "$(mval "$_mb_d/context/executable")"; ml argv "$_mb_d/context/argv" ordered; mf executable "$(mval "$_mb_d/context/executable")"; mf workdir "$(mval "$_mb_d/context/workdir")"; ml argv "$_mb_d/context/argv" ordered; ml env "$_mb_d/context/env" set; ml platforms "$_mb_d/platforms" set; ml requirements "$_mb_d/requirements" set; mf declaration_ref "$(mval "$_mb_d/declaration-ref")"; mf tool_proof_ref "$(mval "$_mb_d/tool-proof-ref")"; fid "$b/facts" "$(mval "$_mb_d/declaration-ref")" >/dev/null; fid "$b/facts" "$(mval "$_mb_d/tool-proof-ref")" >/dev/null; mrefs facts "$_mb_d/fact-refs"; mrefs attestations "$_mb_d/attestation-refs"; ml fact_refs "$_mb_d/fact-refs" set; ml attestation_refs "$_mb_d/attestation-refs" set; }
mrow() { _mw_d=$1; _mw_id=$2; mr row "$_mw_id"; mf id "$_mw_id"; for _mw_k in state source signature mode selection trigger-kind fact-fingerprint confirmation-answer confirmer; do mf "$_mw_k" "$(mval "$_mw_d/$_mw_k")"; done; mrefs bindings "$_mw_d/binding-refs"; mrefs facts "$_mw_d/fact-refs"; mrefs attestations "$_mw_d/attestation-refs"; ml trigger_paths "$_mw_d/trigger-paths" set; ml disciplines "$_mw_d/disciplines" set; ml evidence_binding_refs "$_mw_d/binding-refs" set; ml fact_refs "$_mw_d/fact-refs" set; ml attestation_refs "$_mw_d/attestation-refs" set; }
model() { _m_out=$1; { mf schema CanonicalPolicyModelV1; mr policy policy; mf selection rubric; mf active true; mf authoritative true; mvs mode_order skip standard strict-tdd; mr resolution resolution; for _m_k in matching mode default; do mf "$_m_k" "$(mval "$b/resolution/$_m_k")"; done; mf evidence union; for _m_g in observations facts attestations bindings rows; do for _m_id in $(mid "$_m_g"); do _m_d=$(fid "$b/$_m_g" "$_m_id"); case "$_m_g" in observations) mobs "$_m_d" "$_m_id";; facts) mfact "$_m_d" "$_m_id";; attestations) matt "$_m_d" "$_m_id";; bindings) mbind "$_m_d" "$_m_id";; rows) mrow "$_m_d" "$_m_id";; esac; done; done; } > "$_m_out" || bad; }
# canonical model command dispatch
cmd=${1-}; case "$cmd" in gate|integrate) [ "$#" = 4 ] || exit 2; b=$2; rs=$3; out=$4;; verify-integrated) [ "$#" = 3 ] || exit 2; b=$2; out=$3; rs=;; *) exit 2;; esac
guard_tree "$b"; [ "$cmd" != verify-integrated ] && { guard_tree "$rs"; [ -d "$rs/records" ] && [ ! -L "$rs/records" ]; } || [ "$cmd" = verify-integrated ] || bad; [ ! -e "$out" ] && [ ! -L "$out" ] || bad; parent=$(dirname "$out"); name=$(basename "$out"); guard_dir "$parent"; case "$name" in ''|.*|*[!A-Za-z0-9_-]*) bad;; esac
lock=$parent/.${name}.lock; mkdir "$lock" || bad; root=$(v "$b" root); guard_dir "$root"; wd=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-gate.XXXXXX") || bad; chmod 700 "$wd" || bad; receipt=$parent/.${name}.receipt.$$; trap 'rm -rf "${wd:-}" "${receipt:-}"; rmdir "${lock:-}" 2>/dev/null || :' EXIT HUP INT TERM; snapshot_metadata "$wd/candidate"; if [ "$cmd" = verify-integrated ]; then mkdir "$wd/record-set" || bad; cp -a "$b/attestations" "$wd/record-set/records" || bad; else snapshot_records "$wd/record-set"; fi; b=$wd/candidate; rs=$wd/record-set; validator=$wd/rubric-validator
  cat > "$validator" <<'EOF'
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL
b=${1-}; [ "$#" = 1 ] && [ -d "$b" ] || exit 2
bad() { printf '%s\n' "invalid rubric structure: $*" >&2; exit 1; }
one() { [ -f "$1" ] && [ ! -L "$1" ] || bad scalar; awk 'END { exit NR != 1 }' "$1" || bad scalar; IFS= read -r _one < "$1" || :; [ -n "${_one-}" ] || bad scalar; printf %s "$_one"; }
v() { one "$1/$2"; }
has() { case " $1 " in *" $2 "*) return 0;; *) return 1;; esac; }
safe() { case "$1" in ''|/*|.|..|*/.|*/..|../*|*'/../'*|*'//'*|*'*'*|*'?'*|*'['*) bad path;; esac; }
walk() { _walk_p=; _walk_rest=${1#/}; while [ -n "$_walk_rest" ]; do _walk_part=${_walk_rest%%/*}; case "$_walk_rest" in */*) _walk_rest=${_walk_rest#*/};; *) _walk_rest=;; esac; _walk_p=$_walk_p/$_walk_part; [ ! -L "$_walk_p" ] || bad symlink; done; }
confine() { _conf_rel=$1; _conf_type=$2; safe "$_conf_rel"; walk "$root"; _conf_p=$root; _conf_rest=$_conf_rel; while [ -n "$_conf_rest" ]; do _conf_part=${_conf_rest%%/*}; case "$_conf_rest" in */*) _conf_rest=${_conf_rest#*/};; *) _conf_rest=;; esac; _conf_p=$_conf_p/$_conf_part; [ ! -L "$_conf_p" ] || bad symlink; done; case "$_conf_type" in f) [ -f "$_conf_p" ];; d) [ -d "$_conf_p" ];; esac || bad target; }
list() { _list_d=$1; _list_min=${2-1}; [ -d "$_list_d" ] && [ ! -L "$_list_d" ] || bad list; _list_n=0; for _list_f in "$_list_d"/*; do [ -e "$_list_f" ] || continue; [ -f "$_list_f" ] && [ ! -L "$_list_f" ] || bad list; [ "$(basename "$_list_f")" = "$(printf %03d "$_list_n")" ] || bad order; one "$_list_f" >/dev/null; _list_n=$((_list_n+1)); done; [ "$_list_n" -ge "$_list_min" ] || bad list; n=$_list_n; }
refs() { _refs_d=$1; _refs_all=$2; list "$_refs_d" "${3-1}"; for _refs_f in "$_refs_d"/*; do [ -e "$_refs_f" ] || continue; has "$_refs_all" "$(one "$_refs_f")" || bad "reference:$_refs_d"; done; }
inlist() { for _in_f in "$1"/*; do [ -e "$_in_f" ] && [ "$(one "$_in_f")" = "$2" ] && return 0; done; return 1; }
id() { _id_d=$1; _id_k=$(v "$_id_d" kind); case "$_id_k" in ''|*[!a-z-]*) bad kind;; esac; set -- $(cksum "$_id_d/identity"); _id_want="v1:$_id_k:$1:$2"; [ "$(v "$_id_d" id)" = "$_id_want" ] || bad id; printf %s "$_id_want"; }
fp() { (cd "$1" && find . -type f ! -name id ! -name identity ! -name fingerprint -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1 ":" $2}'; }
fps() { for f in "$1"/*; do [ -e "$f" ] || continue; x=$(one "$f"); for d in "$b/facts/"*; do [ "$(v "$d" id)" = "$x" ] && printf '%s:%s\n' "$x" "$(fp "$d")"; done; done | cksum | awk '{print $1 ":" $2}'; }
uniq() { has "$seen" "$1" && bad duplicate; seen="$seen $1"; all="$all $1"; }
records() { _rec_top=$1; _rec_min=$2; _rec_fn=$3; [ -d "$_rec_top" ] && [ ! -L "$_rec_top" ] || bad records; _rec_n=0; for _rec_d in "$_rec_top"/*; do [ -e "$_rec_d" ] || continue; [ -d "$_rec_d" ] && [ ! -L "$_rec_d" ] || bad records; "$_rec_fn" "$_rec_d"; _rec_n=$((_rec_n+1)); done; [ "$_rec_n" -ge "$_rec_min" ] || bad records; }
[ "$(v "$b" schema)" = v1 ] && [ "$(v "$b" candidate-schema)" = v1 ] || bad schema
find "$b" -name provider -print | grep . >/dev/null && bad provider
root=$(v "$b" root); case "$root" in /*) ;; *) bad root;; esac; case "$root" in *'*'*|*'?'*|*'['*) bad root;; esac; [ -d "$root" ] && [ ! -L "$root" ] || bad root; walk "$root"
[ "$(v "$b/resolution" matching)" = all-rows ] && [ "$(v "$b/resolution" mode)" = strictest-wins ] && [ "$(v "$b/resolution" default)" = unmatched-only ] || bad resolution
seen= all= obs= facts= bindings= attestations= rows= defaults=0
obsrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" channel)" in file) loc=$(v "$d" locator); confine "$loc" f; set -- $(cksum "$root/$loc"); [ "$(v "$d" checksum)" = "$1 $2" ] || bad checksum;; codegraph) [ "$(v "$d" status)" = untrusted ] && [ "$(v "$d" scope)" = scope-only ] || bad codegraph; v "$d" query >/dev/null; v "$d" index-revision >/dev/null; v "$d" symbol >/dev/null; safe "$(v "$d" repo-path)";; *) bad observation;; esac; v "$d" source >/dev/null; v "$d" provenance >/dev/null; obs="$obs $x"; }
factrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" status)" in known|unknown|absent|unsatisfied) ;; *) bad fact;; esac; [ ! -e "$d/provider" ] || bad provider; v "$d" source >/dev/null; v "$d" provenance >/dev/null; v "$d" source-path >/dev/null; v "$d" evidence-kind >/dev/null; v "$d" adapter >/dev/null; refs "$d/observation-refs" "$obs"; [ "$(v "$d" fingerprint)" = "$(fp "$d")" ] || bad fingerprint; facts="$facts $x"; }
attrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" schema)" = v1 ] && [ "$(v "$d" attestation-id)" = "$x" ] || bad attestation; for k in adapter-id adapter-version adapter-bytes-digest input-digest status claim-kind executable method scope; do v "$d" "$k" >/dev/null; done; oi=$(v "$d" observation-id); [ ! -e "$d/observation-refs" ] && [ -n "$oi" ] && has "$obs" "$oi" || bad reference; safe "$(v "$d" source-locator)"; attestations="$attestations $x"; }
bindrec() { d=$1; x=$(id "$d"); uniq "$x"; case "$(v "$d" method)" in unit|integration|e2e|coverage|lint|typecheck|format|build) ;; *) bad method;; esac; v "$d" scope >/dev/null; v "$d" signature-coverage >/dev/null; [ -d "$d/context" ] && [ ! -L "$d/context" ] || bad context; [ "$(v "$d/context" root)" = "$root" ] || bad root; [ "$(v "$d/context" workdir)" = . ] || confine "$(v "$d/context" workdir)" d; v "$d/context" executable >/dev/null; list "$d/context/argv"; list "$d/platforms"; list "$d/env" 0; list "$d/requirements" 0; refs "$d/fact-refs" "$facts"; dr=$(v "$d" declaration-ref); tr=$(v "$d" tool-proof-ref); [ "$dr" != "$tr" ] && inlist "$d/fact-refs" "$dr" && inlist "$d/fact-refs" "$tr" || bad reference; refs "$d/attestation-refs" "$attestations" 0; bindings="$bindings $x"; }
bindpath() { for _bind_d in "$b/bindings/"*; do [ "$(v "$_bind_d" id)" = "$1" ] && { printf %s "$_bind_d"; return; }; done; bad reference; }
linked() { _link_row=$1; _link_kind=$2; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); for _link_item in "$_link_bind/$_link_kind/"*; do [ -e "$_link_item" ] && inlist "$_link_row/$_link_kind" "$(one "$_link_item")" || bad link; done; done; for _link_item in "$_link_row/$_link_kind/"*; do [ -e "$_link_item" ] || continue; _link_found=; for _link_ref in "$_link_row/binding-refs/"*; do [ -e "$_link_ref" ] || continue; _link_bind=$(bindpath "$(one "$_link_ref")"); inlist "$_link_bind/$_link_kind" "$(one "$_link_item")" && _link_found=1; done; [ -n "$_link_found" ] || bad link; done; }
rowrec() { d=$1; x=$(id "$d"); uniq "$x"; m=$(v "$d" mode); case "$m" in skip|standard|strict-tdd) ;; *) bad mode;; esac; st=$(v "$d" state); case "$st" in pending|confirmed|rejected|stale|conflict) ;; *) bad state;; esac; case "$(v "$d" source)" in generated|manual) ;; *) bad source;; esac; sel=$(v "$d" selection); list "$d/trigger-paths" 0; if [ "$sel" = unmatched-only ]; then [ "$(v "$d" signature)" = default ] && [ "$(v "$d" trigger-kind)" = unmatched ] && [ "$n" = 0 ] || bad default; defaults=$((defaults+1)); else [ "$sel" = specific ] && [ "$(v "$d" trigger-kind)" = path ] && [ "$n" -gt 0 ] || bad trigger; fi; refs "$d/fact-refs" "$facts"; [ "$(v "$d" fact-fingerprint)" = "$(fps "$d/fact-refs")" ] || bad fingerprint; list "$d/disciplines" 0; refs "$d/binding-refs" "$bindings" 0; bn=$n; refs "$d/attestation-refs" "$attestations" 0; an=$n; [ "$m" = skip ] || { [ "$bn" -gt 0 ] && [ "$an" -gt 0 ] && linked "$d" fact-refs && linked "$d" attestation-refs; } || bad attestation; [ "$st" != confirmed ] || { v "$d" confirmation-answer >/dev/null; v "$d" confirmer >/dev/null; }; rows="$rows $x"; }
qrec() { d=$1; x=$(id "$d"); uniq "$x"; [ "$(v "$d" kind)" = question ] && [ "$(v "$d" blocking)" = true ] || bad question; v "$d" prompt >/dev/null; case "$(v "$d" state)" in open|answered|rejected) ;; *) bad question;; esac; refs "$d/fact-refs" "$facts"; list "$d/allowed-answers"; has "$rows" "$(v "$d" row-ref)" || bad reference; }
rowpath() { for _row_d in "$b/rows/"*; do [ "$(v "$_row_d" id)" = "$1" ] && { printf %s "$_row_d"; return; }; done; bad reference; }
reinitrec() { d=$1; rr=$(v "$d" row-ref); rd=$(rowpath "$rr"); prior=$(v "$d" prior-fingerprint); now=$(fps "$rd/fact-refs"); case "$(v "$d" state)" in preserved) [ "$prior" = "$now" ] || bad reinit;; stale) [ "$prior" != "$now" ] && [ "$(v "$rd" state)" = stale ] || bad reinit;; *) bad reinit;; esac; }
records "$b/observations" 1 obsrec; records "$b/facts" 1 factrec; records "$b/attestations" 0 attrec; records "$b/bindings" 0 bindrec; records "$b/rows" 1 rowrec; [ "$defaults" = 1 ] || bad default; records "$b/questions" 0 qrec
for d in "$b/rows"/*; do [ -e "$d" ] || continue; st=$(v "$d" state); case "$st" in pending|stale|conflict) found=; for q in "$b/questions"/*; do [ -d "$q" ] && [ "$(v "$q" row-ref)" = "$(v "$d" id)" ] && [ "$(v "$q" state)" = open ] && [ "$(v "$q" blocking)" = true ] && found=1; done; [ -n "$found" ] || bad question;; esac; done
records "$b/reinit" 0 reinitrec; refs "$b/record-order" "$all"; [ "$n" = "$(set -- $all; printf %s "$#")" ] || bad order; prev=; for f in "$b/record-order"/*; do [ -e "$f" ] || continue; x=$(one "$f"); [ -z "$prev" ] || [ "$prev" \< "$x" ] || bad order; prev=$x; done
printf 'structure-valid/pending\n'
EOF
chmod 700 "$validator" || bad; [ "$(dig "$validator")" = 4105381479:9297 ] || bad; "$validator" "$b" >/dev/null || bad
live_root=$(v "$b" root); evidence=$wd/evidence; evidence_guard; snapshot_evidence; root=$evidence; n=0; for bd in "$b/bindings"/*; do [ -d "$bd" ] || continue; [ "$(v "$bd/context" workdir)" = . ] && empty "$bd/context/env" || bad; dr=$(fid "$b/facts" "$(v "$bd" declaration-ref)"); pr=$(fid "$b/facts" "$(v "$bd" tool-proof-ref)"); [ "$dr" != "$pr" ] && [ "$(v "$dr" evidence-kind)" = command-declaration ] && [ "$(v "$pr" evidence-kind)" = tool-proof ] && [ "$(v "$dr" adapter)" = "$(v "$pr" adapter)" ] || bad; d=$(record "$dr" "$bd"); p=$(record "$pr" "$bd"); [ "$d" != "$p" ] && [ "$(v "$d" observation-id)" != "$(v "$p" observation-id)" ] && [ "$(v "$d" source-locator)" != "$(v "$p" source-locator)" ] || bad; n=$((n+2)); done
 [ "$n" -gt 0 ] && [ "$(find "$rs/records" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = "$n" ] || bad
 verify_live; [ ! -e "$out" ] && [ ! -L "$out" ] || bad; [ "$cmd" = gate ] && { printf 'semantic-valid/pending\n' > "$receipt" || bad; mv "$receipt" "$out" || bad; rm -rf "$wd"; rmdir "$lock" || bad; trap - EXIT HUP INT TERM; exit 0; }
 if [ "$cmd" = verify-integrated ]; then [ ! -e "$b/activation/unit1a-result" ] && [ ! -e "$b/activation/semantic-result" ] || bad; for d in "$b"/rows/*; do [ "$(v "$d" state)" = confirmed ] && v "$d" confirmation-answer >/dev/null && v "$d" confirmer >/dev/null || bad; done; for d in "$b"/questions/*; do [ "$(v "$d" state)" = answered ] || bad; done; for d in "$b"/facts/*; do [ "$(v "$d" status)" = known ] || bad; done; for d in "$b"/attestations/*; do [ "$(v "$d" status)" = proven ] || bad; done; model=$wd/canonical-model; model "$model"; bd=$(bundle_digest "$b"); sd=$(for g in facts attestations bindings rows questions; do for d in "$b/$g"/*; do v "$d" id; printf '\n'; done; done | LC_ALL=C sort | cksum | awk '{print $1":"$2}'); md=$(dig "$model"); printf 'schema=IntegratedValidationV1\nstate=verified\ngate_version=v1\ngate_digest=%s\nintegrated_bundle_digest=%s\nsemantic_digest=%s\ncanonical_model_bytes=hex:%s\ncanonical_model_digest=%s\ncommits=none\n' "$(dig "$0")" "$bd" "$sd" "$(hex "$model")" "$md" > "$receipt" || bad; mv "$receipt" "$out" || bad; rm -rf "$wd"; rmdir "$lock" || bad; trap - EXIT HUP INT TERM; exit 0; fi
 stage=$parent/.${name}.stage.$$; trap 'rm -rf "${wd:-}" "${receipt:-}" "${stage:-}"; rmdir "${lock:-}" 2>/dev/null || :' EXIT HUP INT TERM; mkdir -m 700 "$stage" || bad; cp -a "$b"/. "$stage"/. || bad; chmod 700 "$stage" || bad
 put() { printf '%s\n' "$2" > "$1" || bad; }
 reset() { _reset_d=$1; shift; rm -rf "$_reset_d"; mkdir "$_reset_d" || bad; _reset_i=0; for _reset_x; do put "$_reset_d/$(printf '%03d' "$_reset_i")" "$_reset_x"; _reset_i=$((_reset_i+1)); done; }
  cid() { d=$1; t=$2; (cd "$d" && find . -type f ! -name id ! -name identity ! -name fingerprint ! -name attestation-id -print | LC_ALL=C sort | while IFS= read -r f; do case "$t:$f" in binding:./attestation-refs/*) continue;; esac; printf '%s=' "$f"; cat "$f"; done) > "$d/identity" || bad; k=$(v "$d" kind); put "$d/id" "v1:$k:$(dig "$d/identity")"; [ ! -e "$d/attestation-id" ] || put "$d/attestation-id" "$(v "$d" id)"; }
  attid() { d=$1; { for k in adapter-bytes-digest adapter-id adapter-version argv-digest binding-id claim-kind evidence-fact-id executable input-digest method observation-digest observation-id schema scope source-locator status; do printf '%s=%s\n' "$k" "$(v "$d" "$k")"; done; } > "$d/identity" || bad; x="v1:attestation:$(dig "$d/identity")"; put "$d/id" "$x"; put "$d/attestation-id" "$x"; }
 finger() { (cd "$1" && find . -type f ! -name id ! -name identity ! -name fingerprint -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
 rowfp() { for f in "$1"/*; do [ -e "$f" ] || continue; x=$(one "$f"); for d in "$stage/facts"/*; do [ "$(v "$d" id)" = "$x" ] && printf '%s:%s\n' "$x" "$(finger "$d")"; done; done | cksum | awk '{print $1":"$2}'; }
 rm -rf "$stage/attestations"; mkdir "$stage/attestations" || bad; i=0; for d in "$rs/records"/*; do [ -d "$d" ] && [ ! -L "$d" ] || bad; cp -a "$d" "$stage/attestations/$(printf '%03d' "$i")" || bad; i=$((i+1)); done
 map=$wd/bindings; : > "$map"; for d in "$stage/bindings"/*; do old=$(v "$d" id); cid "$d" binding; printf '%s %s\n' "$old" "$(v "$d" id)" >> "$map"; done
  for d in "$stage/attestations"/*; do old=$(v "$d" binding-id); new=$(awk -v x="$old" '$1==x{print $2}' "$map"); [ -n "$new" ] || bad; put "$d/binding-id" "$new"; attid "$d"; done
 for d in "$stage/bindings"/*; do set --; for a in "$stage/attestations"/*; do [ "$(v "$a" binding-id)" = "$(v "$d" id)" ] && set -- "$@" "$(v "$a" id)"; done; [ "$#" -gt 0 ] || bad; reset "$d/attestation-refs" "$@"; done
 rmap=$wd/rows; : > "$rmap"; for d in "$stage/rows"/*; do for f in "$d/binding-refs"/*; do [ -e "$f" ] || continue; old=$(one "$f"); new=$(awk -v x="$old" '$1==x{print $2}' "$map"); [ -n "$new" ] || bad; put "$f" "$new"; done; set --; for f in "$d/binding-refs"/*; do [ -e "$f" ] || continue; bd=$(fid "$stage/bindings" "$(one "$f")"); for a in "$bd/attestation-refs"/*; do set -- "$@" "$(one "$a")"; done; done; reset "$d/attestation-refs" "$@"; put "$d/fact-fingerprint" "$(rowfp "$d/fact-refs")"; old=$(v "$d" id); cid "$d" row; printf '%s %s\n' "$old" "$(v "$d" id)" >> "$rmap"; done
 for d in "$stage/questions"/*; do old=$(v "$d" row-ref); new=$(awk -v x="$old" '$1==x{print $2}' "$rmap"); [ -n "$new" ] || bad; put "$d/row-ref" "$new"; cid "$d" question; done
 for d in "$stage/reinit"/*; do old=$(v "$d" row-ref); new=$(awk -v x="$old" '$1==x{print $2}' "$rmap"); [ -n "$new" ] || bad; put "$d/row-ref" "$new"; done
 for d in "$stage/facts"/*; do put "$d/fingerprint" "$(finger "$d")"; done; for d in "$stage/rows"/*; do put "$d/fact-fingerprint" "$(rowfp "$d/fact-refs")"; done
 rm -rf "$stage/record-order"; mkdir "$stage/record-order" || bad; (for g in observations facts attestations bindings rows questions; do for d in "$stage/$g"/*; do v "$d" id; printf '\n'; done; done) | LC_ALL=C sort | { i=0; while IFS= read -r x; do put "$stage/record-order/$(printf '%03d' "$i")" "$x"; i=$((i+1)); done; }
  semantic=$stage/semantic-records; mkdir "$semantic" || bad; cp -a "$stage/attestations" "$semantic/records" || bad; b=$stage; rs=$semantic; root=$evidence; n=0; for bd in "$b/bindings"/*; do [ -d "$bd" ] || continue; [ "$(v "$bd/context" workdir)" = . ] && empty "$bd/context/env" || bad; dr=$(fid "$b/facts" "$(v "$bd" declaration-ref)"); pr=$(fid "$b/facts" "$(v "$bd" tool-proof-ref)"); [ "$dr" != "$pr" ] && [ "$(v "$dr" evidence-kind)" = command-declaration ] && [ "$(v "$pr" evidence-kind)" = tool-proof ] && [ "$(v "$dr" adapter)" = "$(v "$pr" adapter)" ] || bad; d=$(record "$dr" "$bd"); p=$(record "$pr" "$bd"); [ "$d" != "$p" ] && [ "$(v "$d" observation-id)" != "$(v "$p" observation-id)" ] && [ "$(v "$d" source-locator)" != "$(v "$p" source-locator)" ] || bad; n=$((n+2)); done; [ "$n" -gt 0 ] && [ "$(find "$rs/records" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" = "$n" ] || bad
  verify_live; "$validator" "$stage" >/dev/null || bad; [ ! -e "$out" ] && [ ! -L "$out" ] || bad; mv "$stage" "$out" || bad; rm -rf "$wd" "$receipt"; rmdir "$lock" || bad; trap - EXIT HUP INT TERM
<!-- rubric-adapter-gate:end -->
<!-- rubric-activation:start -->
#!/bin/sh
set -eu
LC_ALL=C; export LC_ALL; umask 077
PINNED_GATE_DIGEST=2444152548:34834
committed=0; target=; old=
restore() { [ "$committed" = 1 ] || return 0; cp -- "$old" "$target" && cmp -s "$old" "$target"; }
bad() { [ "$committed" != 1 ] || restore || :; printf '%s\n' 'invalid rubric activation input' >&2; exit 1; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
walk() { p=; r=${1#/}; while [ -n "$r" ]; do x=${r%%/*}; case "$r" in */*) r=${r#*/};; *) r=;; esac; p=$p/$x; [ ! -L "$p" ] || bad; done; }
reg() { walk "$1"; [ -f "$1" ] && [ ! -L "$1" ] || bad; }
dir() { walk "$1"; [ -d "$1" ] && [ ! -L "$1" ] || bad; }
one() { reg "$1"; [ "$(awk 'END{print NR}' "$1")" = 1 ] || bad; x=$(awk 'NR==1{print;exit}' "$1"); [ -n "$x" ] || bad; printf %s "$x"; }
field() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1)print v;else exit 1}' "$1" || bad; }
bundle_digest() { (cd "$1" && find . -type f -print | LC_ALL=C sort | while IFS= read -r f; do printf '%s ' "$f"; cksum "$f"; done) | cksum | awk '{print $1":"$2}'; }
path() { g=$1; id=$2; found=; for d in "$b/$g"/*; do [ -d "$d" ] && [ "$(one "$d/id")" = "$id" ] || continue; [ -z "$found" ] || bad; found=$d; done; [ -n "$found" ] || bad; printf %s "$found"; }
ids() { for d in "$b/$1"/*; do [ -d "$d" ] && one "$d/id"; printf '\n'; done | LC_ALL=C sort; }
q() { one "$1" >/dev/null; printf '"'; one "$1" | od -An -v -tx1 | while IFS= read -r h; do for x in $h; do case "$x" in 22) printf '\\"';; 5c) printf '\\\\';; 08) printf '\\b';; 09) printf '\\t';; 0[0-7]|0[be-f]|1[0-9a-f]) printf '\\u00%s' "$x";; 20|2[1-9a-f]|[3-7][0-9a-f]) printf "$(printf '\\%03o' "0x$x")";; *) bad;; esac; done; done; printf '"'; }
kv() { printf '%s%s: ' "$1" "$2"; q "$3"; printf '\n'; }
seq() { printf '%s%s:\n' "$1" "$2"; for f in "$3"/*; do [ -e "$f" ] || continue; printf '%s- ' "$1  "; q "$f"; printf '\n'; done; }
yaml() { y=$1; { printf 'testing:\n  # gentle-ai:managed-testing:start\n  policy: "rubric"\n  rubric:\n    active: true\n    authoritative: true\n    mode_order:\n      - "skip"\n      - "standard"\n      - "strict-tdd"\n    resolution:\n'; kv '      ' matching "$b/resolution/matching"; kv '      ' mode "$b/resolution/mode"; printf '      evidence: "union"\n'; kv '      ' default "$b/resolution/default"; printf '    bindings:\n'; for id in $(ids bindings); do d=$(path bindings "$id"); printf '      - id: '; q "$d/id"; printf '\n'; for k in method scope signature-coverage; do kv '        ' "$k" "$d/$k"; done; printf '        command:\n          executable: '; q "$d/context/executable"; printf '\n          argv:\n'; for f in "$d/context/argv"/*; do [ -e "$f" ] || continue; printf '            - '; q "$f"; printf '\n'; done; kv '          ' workdir "$d/context/workdir"; printf '          env:\n'; for f in "$d/context/env"/*; do [ -e "$f" ] || continue; printf '            - '; q "$f"; printf '\n'; done; for k in declaration-ref tool-proof-ref; do kv '        ' "$k" "$d/$k"; done; for k in fact-refs attestation-refs; do seq '        ' "$k" "$d/$k"; done; done; printf '    rows:\n'; for id in $(ids rows); do d=$(path rows "$id"); printf '      - id: '; q "$d/id"; printf '\n'; for k in signature mode selection trigger-kind source; do kv '        ' "$k" "$d/$k"; done; for k in trigger-paths disciplines binding-refs fact-refs attestation-refs; do seq '        ' "$k" "$d/$k"; done; done; printf '  # gentle-ai:managed-testing:end\n'; } > "$y" || bad; }
scan() { reg "$1"; LC_ALL=C grep -q "$(printf '\r')" "$1" && bad; grep -q "$(printf '\t')" "$1" && bad; [ "$(tail -c 1 "$1" | od -An -tx1 | tr -d ' \n')" = 0a ] || bad; grep -Eq '^(---|\.\.\.)$|(^|[[:space:]])(&|!|\*|<<:)' "$1" && bad || :; t=$(awk '/^testing:[[:space:]]*$/{n++;x=NR}END{if(n==1)print x;else exit 1}' "$1") || bad; s=$(awk '/^strict_tdd:[[:space:]]+false[[:space:]]*$/{n++;x=NR}END{if(n==1)print x;else exit 1}' "$1") || bad; e=$(awk -v n="$t" 'NR>n&&/^[A-Za-z_][A-Za-z0-9_-]*:/{print NR;exit}' "$1"); [ -n "$e" ] && [ "$s" -ne "$t" ] || bad; awk -v a="$t" -v z="$e" 'NR>=a&&NR<z&&/[>|][+-]?[[:space:]]*($|#)/{bad=1}END{exit !bad}' "$1" && bad || :; ms=$(grep -c '^  # gentle-ai:managed-testing:start$' "$1" || :); me=$(grep -c '^  # gentle-ai:managed-testing:end$' "$1" || :); { [ "$ms:$me" = 0:0 ] || { [ "$ms:$me" = 1:1 ] && awk -v a="$t" -v z="$e" '/^  # gentle-ai:managed-testing:start$/{s=NR}/^  # gentle-ai:managed-testing:end$/{e=NR}END{exit !(s>a&&s<z&&e>s&&e<z)}' "$1"; }; } || bad; }
emit() { printf 'schema=ResolutionV1\nproject=%s\nmode=%s\nstate=%s\ntxn_id=%s\ngate_digest=%s\nintegrated_bundle_digest=%s\ncanonical_model_digest=%s\nbackend_config_digest=%s\ncommits=%s\n' "$project" "$mode" "$state" "$txn" "$gd" "$bd" "$md" "$backend" "$commits"; }
verify_gate() { reg "$gate"; [ "$(dig "$gate")" = "$PINNED_GATE_DIGEST" ] || bad; cp -- "$gate" "$w/gate" || bad; chmod 700 "$w/gate"; cp -a "$bundle" "$w/candidate" || bad; "$w/gate" verify-integrated "$w/candidate" "$w/integrated" || bad; gd=$(field "$w/integrated" gate_digest); bd=$(field "$w/integrated" integrated_bundle_digest); md=$(field "$w/integrated" canonical_model_digest); [ "$gd" = "$PINNED_GATE_DIGEST" ] && [ "$bd" = "$(bundle_digest "$w/candidate")" ] || bad; b=$w/candidate; }
 # EngramAdapterV1 production mapping: lookup-canonical performs MCP
 # mem_search(topic) then mem_get_observation for every candidate and exact-filters;
 # compare-put-canonical fresh-prechecks then uses mem_save or mem_update. Their
 # responses are never proof: only the separate fixed lookup below is proof.
 PINNED_ENGRAM_ADAPTER_DIGEST=1850954017:5640
 efield() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1&&v!="")print v;else exit 1}' "$1" || bad; }
 exact() { f=$1; shift; [ "$(awk 'NF{n++}END{print n+0}' "$f")" = "$#" ] || bad; for k; do efield "$f" "$k" >/dev/null; done; }
 scalar() { case "$1" in ''|*[!A-Za-z0-9._:-]*) bad;; esac; }
 hexok() { case "$1" in ''|*[!0123456789abcdef]*) bad;; esac; [ $(( ${#1} % 2 )) = 0 ] || bad; }
 digok() { case "$1" in *:*) a=${1%%:*}; z=${1#*:}; case "$a:$z" in *[!0123456789:]*|*:*:*) bad;; esac;; *) bad;; esac; }
 adapter_call() { "$w/adapter" "$store" "$w/request" "$w/response" || bad; }
 lookup() { rid=$1; printf 'schema=EngramAdapterV1\nverb=lookup-canonical\nrequest_id=%s\nproject=%s\ntopic=%s\n' "$rid" "$project" "$topic" > "$w/request"; adapter_call; [ "$(efield "$w/response" schema)" = EngramAdapterV1 ] && [ "$(efield "$w/response" request_id)" = "$rid" ] && [ "$(efield "$w/response" topic)" = "$topic" ] || bad; status=$(efield "$w/response" status); case "$status" in absent) exact "$w/response" schema request_id status topic;; found) exact "$w/response" schema request_id status topic observation_id store_revision content_hex content_digest; scalar "$(efield "$w/response" observation_id)"; case "$(efield "$w/response" store_revision)" in ''|*[!0-9]*) bad;; esac; hexok "$(efield "$w/response" content_hex)"; digok "$(efield "$w/response" content_digest)";; conflict|error) bad;; *) bad;; esac; }
 readback() { want=$1; wantstate=$2; lookup "${txn}:read-${wantstate}"; [ "$status" = found ] || bad; rh=$(efield "$w/response" content_hex); rd=$(efield "$w/response" content_digest); printf %s "$rh" | xxd -r -p > "$w/read" || bad; [ "$(dig "$w/read")" = "$rd" ] && [ "$(dig "$w/read")" = "$want" ] || bad; grep -Fxq "state=$wantstate" "$w/read" && grep -Fxq 'schema=ActivationStateV1' "$w/read" && grep -Fxq 'authority=engram' "$w/read" && grep -Fxq "txn_id=$txn" "$w/read" && grep -Fxq "canonical_model_digest=$md" "$w/read" && grep -Fxq "backend_payload_digest=$(dig "$w/model")" "$w/read" && grep -Fxq "predecessor_revision=$prior" "$w/read" && grep -Fxq "committed_revision=$(efield "$w/response" store_revision)" "$w/read" && grep -Fxq "backend_revision=$(efield "$w/response" store_revision)" "$w/read" || bad; awk '/^```text$/{p=1;next}p&&/^```$/{sub(/\n$/, "", x);printf "%s",x;exit}p{x=x $0 "\n"}' "$w/read" | cmp -s - "$w/model" || bad; }
 put_engram() { content=$1; presence=$2; oid=$3; rev=$4; pd=$5; printf 'schema=EngramAdapterV1\nverb=compare-put-canonical\nrequest_id=%s\nproject=%s\ntopic=%s\nexpected_presence=%s\nexpected_observation_id=%s\nexpected_store_revision=%s\nexpected_content_digest=%s\ncontent_hex=%s\ncontent_digest=%s\n' "${txn}:put" "$project" "$topic" "$presence" "$oid" "$rev" "$pd" "$(od -An -v -tx1 "$content" | tr -d ' \n')" "$(dig "$content")" > "$w/request"; adapter_call; exact "$w/response" schema request_id status; [ "$(efield "$w/response" schema)" = EngramAdapterV1 ] && [ "$(efield "$w/response" request_id)" = "${txn}:put" ] && [ "$(efield "$w/response" status)" = written ] || bad; }
  markdown() { state=$1; prior=$2; newrev=$3; out=$4; authority=${5-engram}; { printf '# SDD Init Canonical Policy\n\nschema=ActivationStateV1\nstate=%s\ntxn_id=%s\nauthority=%s\ncanonical_model_digest=%s\nbackend_payload_digest=%s\npredecessor_revision=%s\ncommitted_revision=%s\nbackend_revision=%s\nreadback=verified\n\n## CanonicalPolicyModelV1\n\n```text\n' "$state" "$txn" "$authority" "$md" "$(dig "$w/model")" "$prior" "$newrev" "$newrev"; cat "$w/model"; printf '\n```\n'; } > "$out" || bad; }
  hatomic() { _hf=$1; _hs=$2; _hp=$(dirname "$_hf"); _ht=$(mktemp "$_hp/.$(basename "$_hf").hybrid.XXXXXX") || return 1; cp -- "$_hs" "$_ht" && mv -- "$_ht" "$_hf" && cmp -s "$_hs" "$_hf"; }
  hfile() { printf %s "$1" | xxd -r -p > "$2" && [ "$(dig "$2")" = "$3" ]; }
  hmeta() { _hf=$1; _hs=$2; scan "$_hf"; cmp -s "$_hf" "$3" && grep -Fxq "    schema: \"ResolutionV1\"" "$_hf" && grep -Fxq "    state: \"$_hs\"" "$_hf" && grep -Fxq "    txn_id: \"$txn\"" "$_hf" && grep -Fxq '    authority: "openspec"' "$_hf" && grep -Fxq "    canonical_model_digest: \"$md\"" "$_hf"; }
  hyaml() { _hy=$1; _hs=$2; _ht=$t; _he=$e; yaml "$w/hybrid-base"; awk -v s="$_hs" -v t="$txn" -v m="$md" '/^    authoritative: true$/{print;print "    schema: \"ResolutionV1\"";print "    state: \"" s "\"";print "    txn_id: \"" t "\"";print "    authority: \"openspec\"";print "    canonical_model_digest: \"" m "\"";next}{print}' "$w/hybrid-base" > "$w/hybrid-testing" || bad; awk -v a="$_ht" -v z="$_he" -v y="$w/hybrid-testing" 'NR==a{while((getline x<y)>0)print x;next}NR>=a&&NR<z{next}{print}' "$target" > "$_hy" || bad; scan "$_hy"; t=$_ht; e=$_he; }
  hread() { _hh=$1; _hs=$2; lookup "${txn}:read-${_hs}"; [ "$status" = found ] || return 1; _hx=$(efield "$w/response" content_hex); _hd=$(efield "$w/response" content_digest); hfile "$_hx" "$w/hread" "$_hd" && cmp -s "$w/hread" "$_hh" && grep -Fxq 'schema=ActivationStateV1' "$w/hread" && grep -Fxq "state=$_hs" "$w/hread" && grep -Fxq 'authority=openspec' "$w/hread" && grep -Fxq "txn_id=$txn" "$w/hread" && grep -Fxq "canonical_model_digest=$md" "$w/hread"; }
   hraw() { _hr=$1; lookup "${txn}:raw"; [ "$status" = found ] && hfile "$(efield "$w/response" content_hex)" "$w/hraw" "$(efield "$w/response" content_digest)" && cmp -s "$w/hraw" "$_hr"; }
   # ResolutionV1 is a write-ahead journal.  Test runners inject crashes only at
   # the stable comments in hybrid2; production has no fault-control input.
   jcanon() { grep -v '^step_digest=' "$1" | cksum | awk '{print $1":"$2}'; }
   jload() { hload || return 1; jgen=$(field "$journal" generation); jprev=$(field "$journal" previous_step_digest); jstep=$(field "$journal" step_digest); jintent=$(field "$journal" current_intent); jverified=$(field "$journal" verified_step); jtopic=$(field "$journal" topic); jotarget=$(field "$journal" openspec_target_hex); jsid=$(field "$journal" engram_staging_observation_id); jsrev=$(field "$journal" engram_staging_revision); jaid=$(field "$journal" engram_active_observation_id); jarev=$(field "$journal" engram_active_revision); crev=$(field "$journal" engram_restore_revision); estage=$jsrev; eactive=$jarev; epath=$([ "$epres" = absent ] && printf absent || printf '%s' "$w/epre"); case "$jgen:$estage:$eactive" in *[!0-9:]*|:*|*:) return 1;; esac; case "$epres:$crev" in absent:none|found:[0-9]*) ;; *) return 1;; esac; [ "$jstep" = "$(jcanon "$journal")" ] && [ "$jtopic" = "$topic" ] && [ "$jotarget" = "$otarget" ] && [ "$jsid:$jsrev" = "obs-1:$estage" ] && [ "$jaid:$jarev" = "obs-1:$eactive" ]; }
   jwrite() { _js=$1 _ji=$2 _jv=$3 _jr=$4 _jg=$5 _jp=$6; _jt=$(mktemp "$hparent/.$(basename "$journal").intent.XXXXXX") || return 1; { printf 'schema=ResolutionV1\nproject=%s\nmode=hybrid\nstate=%s\ntxn_id=%s\ngate_digest=%s\nintegrated_bundle_digest=%s\ncanonical_model_digest=%s\nstep=%s\nrecovery_step=%s\nopenspec_preimage_hex=%s\nopenspec_preimage_digest=%s\nopenspec_staging_hex=%s\nopenspec_staging_digest=%s\nopenspec_active_hex=%s\nopenspec_active_digest=%s\nengram_preimage_presence=%s\nengram_preimage_observation_id=%s\nengram_preimage_revision=%s\nengram_preimage_hex=%s\nengram_preimage_digest=%s\nengram_staging_hex=%s\nengram_staging_digest=%s\nengram_active_hex=%s\nengram_active_digest=%s\nengram_restore_revision=%s\ngeneration=%s\nprevious_step_digest=%s\ncurrent_intent=%s\nverified_step=%s\ntopic=%s\nopenspec_target_hex=%s\nengram_staging_observation_id=obs-1\nengram_staging_revision=%s\nengram_active_observation_id=obs-1\nengram_active_revision=%s\n' "$project" "$_js" "$txn" "$gd" "$bd" "$md" "$_ji" "$_jr" "$ophex" "$opdig" "$oshex" "$osdig" "$oahex" "$oadig" "$epres" "$eoid" "$erev" "$ehex" "$edig" "$eshex" "$esdig" "$eahex" "$eadig" "$crev" "$_jg" "$_jp" "$_ji" "$_jv" "$topic" "$otarget" "$estage" "$eactive"; } > "$_jt" || return 1; _jd=$(jcanon "$_jt") || return 1; printf 'step_digest=%s\n' "$_jd" >> "$_jt" || return 1; mv -- "$_jt" "$journal" && jload && [ "$jgen:$jprev:$jintent:$jstep" = "$_jg:$_jp:$_ji:$_jd" ]; }
   jcreate() { [ ! -e "$journal" ] && [ ! -L "$journal" ] && jwrite staging F1-intent-openspec-staging none none 1 none; }
   jcas() { _jg=$1 _jd=$2 _jp=$3 _js=$4 _ji=$5 _jv=$6 _jr=$7; jload && [ "$jgen:$jstep:$jprev" = "$_jg:$_jd:$_jp" ] && jwrite "$_js" "$_ji" "$_jv" "$_jr" $((_jg+1)) "$_jd"; }
   jadvance() { _from=$1 _next=$2 _state=$3; jload && [ "$jintent" = "$_from" ] && jcas "$jgen" "$jstep" "$jprev" "$_state" "$_next" "${_from%%-intent-*}" none; }
   jrecover() { jload && jcas "$jgen" "$jstep" "$jprev" recovery-required "$jintent" "$jverified" "$jintent"; }
   jcompensate() { jload && jcas "$jgen" "$jstep" "$jprev" recovery-required "$jintent" compensate "$jintent"; }
   jrestore() { _jr=$1 _jv=$2; jload || return 1; crev=$_jr; jwrite staging "$jintent" "$_jv" none $((jgen+1)) "$jstep"; }
   oclass() { cmp -s "$target" "$1" && printf retry || { cmp -s "$target" "$2" && printf advance || printf conflict; }; }
   ematch() { _em=$1 _ei=$2 _er=$3; [ "$status" = found ] || return 1; hfile "$(efield "$w/response" content_hex)" "$w/ematch" "$(efield "$w/response" content_digest)" && cmp -s "$w/ematch" "$_em" && [ "$(efield "$w/response" observation_id):$(efield "$w/response" store_revision)" = "$_ei:$_er" ]; }
   eclass() { _ep=$1 _ei=$2 _er=$3 _en=$4 _ni=$5 _nr=$6; lookup "${txn}:class-${jintent}"; case "$status" in absent) [ "$_ep" = absent ] && printf retry || printf conflict;; found) { [ "$_ep" != absent ] && ematch "$_ep" "$_ei" "$_er"; } && printf retry || { ematch "$_en" "$_ni" "$_nr" && printf advance || printf conflict; };; esac; }
   ewrite() { _ep=$1 _ei=$2 _er=$3 _en=$4 _tag=$5; lookup "${txn}:before-${_tag}"; if [ "$_ep" = absent ]; then [ "$status" = absent ] || return 1; put_engram "$_en" absent none none none; else ematch "$_ep" "$_ei" "$_er" || return 1; put_engram "$_en" found "$_ei" "$_er" "$(dig "$_ep")"; fi; }
   eread() { _en=$1 _ei=$2 _er=$3 _state=$4; lookup "${txn}:read-${_state}"; ematch "$_en" "$_ei" "$_er" && hread "$_en" "$_state"; }
   f1() { case "$(oclass "$w/opre" "$w/os")" in retry) # crash:F1-before-write
       hatomic "$target" "$w/os" || return 1
       # crash:F1-after-write
       # crash:F1-before-readback
       hmeta "$target" staging "$w/os" || return 1
       # crash:F1-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:F2-before-intent
     # fault:F1-before-F2
     jadvance F1-intent-openspec-staging F2-intent-engram-staging staging || return 1
     # fault:F1-completed
     # crash:F2-after-intent
   }
   f2() { case "$(eclass "${epath}" "$eoid" "$erev" "$w/es" obs-1 "$estage")" in retry) # crash:F2-before-write
       ewrite "${epath}" "$eoid" "$erev" "$w/es" F2 || return 1
       # crash:F2-after-write
       # crash:F2-before-readback
       eread "$w/es" obs-1 "$estage" staging || return 1
       # crash:F2-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:F3-before-intent
     jadvance F2-intent-engram-staging F3-intent-engram-active staging || return 1
     # fault:F2-completed
     # crash:F3-after-intent
   }
   f3() { case "$(eclass "$w/es" obs-1 "$estage" "$w/ea" obs-1 "$eactive")" in retry) # crash:F3-before-write
       ewrite "$w/es" obs-1 "$estage" "$w/ea" F3 || return 1
       # crash:F3-after-write
       # crash:F3-before-readback
       eread "$w/ea" obs-1 "$eactive" active || return 1
       # crash:F3-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:F4-before-intent
     jadvance F3-intent-engram-active F4-intent-openspec-active staging || return 1
     # fault:F3-completed
     # crash:F4-after-intent
   }
   f4() { case "$(oclass "$w/os" "$w/oa")" in retry) # crash:F4-before-write
       hatomic "$target" "$w/oa" || return 1
       # crash:F4-after-write
       # crash:F4-before-readback
       hmeta "$target" active "$w/oa" || return 1
       # crash:F4-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     hmeta "$target" active "$w/oa" && eread "$w/ea" obs-1 "$eactive" active || { jrecover || :; return 1; }
     # fault:F4-before-terminal
     jadvance F4-intent-openspec-active active active
     # fault:F4-completed
   }
   cintent() { _cf=$1 _cn=$2 _cv=$3 _cr=${4-}; jload && [ "$jintent" = "$_cf" ] || return 1; [ -z "$_cr" ] || crev=$_cr; jcas "$jgen" "$jstep" "$jprev" staging "$_cn" "$_cv" none; }
   eraw() { _ef=$1 _ei=$2 _er=$3; lookup "${txn}:raw-${jintent}"; [ "$status" = found ] && hfile "$(efield "$w/response" content_hex)" "$w/eraw" "$(efield "$w/response" content_digest)" && cmp -s "$w/eraw" "$_ef" && [ "$(efield "$w/response" observation_id):$(efield "$w/response" store_revision)" = "$_ei:$_er" ]; }
   cengram() { _ce=$1 _cr=$2 _ct=$3; _cn=$crev; [ "$_cn" = "$((_cr+1))" ] || return 1; case "$(eclass "$_ce" obs-1 "$_cr" "$w/epre" "$eoid" "$_cn")" in retry) case "$_ct" in C2) # crash:C2-before-write
         ewrite "$_ce" obs-1 "$_cr" "$w/epre" C2 || return 1
         # crash:C2-after-write
         # crash:C2-before-readback
         eraw "$w/epre" "$eoid" "$_cn" || return 1
         # crash:C2-after-readback
         ;;
       C3) # crash:C3-before-write
         ewrite "$_ce" obs-1 "$_cr" "$w/epre" C3 || return 1
         # crash:C3-after-write
         # crash:C3-before-readback
         eraw "$w/epre" "$eoid" "$_cn" || return 1
         # crash:C3-after-readback
         ;;
       *) return 1;; esac; crev=$_cn;; advance) crev=$_cn;; *) jrecover || :; return 1;; esac; }
   c1() { case "$(oclass "$w/os" "$w/opre")" in retry) # crash:C1-before-write
       hatomic "$target" "$w/opre" || return 1
       # crash:C1-after-write
       # crash:C1-before-readback
       cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] || return 1
       # crash:C1-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     if [ "$epres" = absent ]; then lookup "${txn}:prior-absent" && [ "$status" = absent ] || { jrecover || :; return 1; }; else eraw "$w/epre" "$eoid" "$crev" || { jrecover || :; return 1; }; fi
     jload && jcas "$jgen" "$jstep" "$jprev" prior-active prior-active C1-verified none; }
   c2() { lookup "${txn}:C2-class" || return 1; if [ "$status" = found ] && ematch "$w/epre" "$eoid" "$erev"; then # crash:C2-before-intent
       cintent C2-intent-engram-preimage C1-intent-openspec-preimage C2-skipped || return 1
       # crash:C2-after-intent
       return
     fi; jrestore $((estage+1)) C2-restore-intent || return 1; cengram "$w/es" "$estage" C2 || return 1; # crash:C2-before-intent
     cintent C2-intent-engram-preimage C1-intent-openspec-preimage C2-verified "$crev" || return 1
     # crash:C2-after-intent
   }
   c3() { lookup "${txn}:C3-class" || return 1; if [ "$status" = found ] && ematch "$w/epre" "$eoid" "$erev"; then # crash:C3-before-intent
       cintent C3-intent-engram-preimage C1-intent-openspec-preimage C3-skipped || return 1
       # crash:C3-after-intent
       return
     elif [ "$status" = found ] && ematch "$w/es" obs-1 "$estage"; then # crash:C3-before-intent
       cintent C3-intent-engram-preimage C2-intent-engram-preimage C3-skipped || return 1
       # crash:C3-after-intent
       return
     fi; jrestore $((eactive+1)) C3-restore-intent || return 1; cengram "$w/ea" "$eactive" C3 || return 1; # crash:C3-before-intent
     cintent C3-intent-engram-preimage C1-intent-openspec-preimage C2-skipped "$crev" || return 1
     # crash:C3-after-intent
   }
   c4() { if cmp -s "$target" "$w/os"; then # crash:C4-before-intent
       cintent C4-intent-openspec-preimage C3-intent-engram-preimage C4-skipped || return 1
       # crash:C4-after-intent
       return
     fi; case "$(oclass "$w/oa" "$w/opre")" in retry) # crash:C4-before-write
       hatomic "$target" "$w/opre" || return 1
       # crash:C4-after-write
       # crash:C4-before-readback
       cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] || return 1
       # crash:C4-after-readback
       ;; advance) ;; *) jrecover || :; return 1;; esac
     # crash:C4-before-intent
     cintent C4-intent-openspec-preimage C3-intent-engram-preimage C4-verified || return 1
     # crash:C4-after-intent
   }
   compensate() { jload || return 1; case "$jintent" in F1-intent-openspec-staging) # crash:C1-before-intent
       cintent F1-intent-openspec-staging C1-intent-openspec-preimage F1-verified || return 1
       # crash:C1-after-intent
       ;;
     F2-intent-engram-staging) # crash:C2-before-intent
       cintent F2-intent-engram-staging C2-intent-engram-preimage F2-verified || return 1
       # crash:C2-after-intent
       ;;
     F3-intent-engram-active) # crash:C3-before-intent
       cintent F3-intent-engram-active C3-intent-engram-preimage F3-verified || return 1
       # crash:C3-after-intent
       ;;
     F4-intent-openspec-active) # crash:C4-before-intent
       cintent F4-intent-openspec-active C4-intent-openspec-preimage F4-verified || return 1
       # crash:C4-after-intent
       ;;
     esac
     case "$jintent" in C4-intent-openspec-preimage) c4;; C3-intent-engram-preimage) c3;; C2-intent-engram-preimage) c2;; C1-intent-openspec-preimage) c1;; *) return 1;; esac; }
   hybrid2() { reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || return 1; cp -- "$adapter" "$w/adapter" && chmod 700 "$w/adapter" || return 1; topic="sdd-init/$project"; field "$w/integrated" canonical_model_bytes | sed 's/^hex://' | xxd -r -p > "$w/model" || return 1; [ "$(dig "$w/model")" = "$md" ] || return 1; scan "$target"; hparent=$(dirname "$journal"); dir "$hparent"; otarget=$(printf %s "$target" | od -An -v -tx1 | tr -d ' \n'); if [ -e "$journal" ]; then jload || return 1; [ "$hstate:$jintent" = active:active ] && { hmeta "$target" active "$w/oa" && eread "$w/ea" obs-1 "$eactive" active; return; }; [ "$hstate:$jintent" = prior-active:prior-active ] && { cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] && { [ "$epres" = absent ] && lookup "${txn}:prior-absent" && [ "$status" = absent ] || eraw "$w/epre" "$eoid" "$crev"; }; return; }; else cp -p "$target" "$w/opre" || return 1; lookup "${txn}:preimage" || return 1; case "$status" in absent) epres=absent; eoid=none; erev=none; ehex=none; edig=none; epath=absent; prior=absent; enext=1;; found) epres=found; eoid=$(efield "$w/response" observation_id); erev=$(efield "$w/response" store_revision); ehex=$(efield "$w/response" content_hex); edig=$(efield "$w/response" content_digest); hfile "$ehex" "$w/epre" "$edig" || return 1; epath=$w/epre; prior=$erev; enext=$((erev+1));; *) return 1;; esac; hyaml "$w/os" staging; hyaml "$w/oa" active; markdown staging "$prior" "$enext" "$w/es" openspec; markdown active "$prior" $((enext+1)) "$w/ea" openspec; ophex=$(od -An -v -tx1 "$w/opre" | tr -d ' \n'); opdig=$(dig "$w/opre"); oshex=$(od -An -v -tx1 "$w/os" | tr -d ' \n'); osdig=$(dig "$w/os"); oahex=$(od -An -v -tx1 "$w/oa" | tr -d ' \n'); oadig=$(dig "$w/oa"); eshex=$(od -An -v -tx1 "$w/es" | tr -d ' \n'); esdig=$(dig "$w/es"); eahex=$(od -An -v -tx1 "$w/ea" | tr -d ' \n'); eadig=$(dig "$w/ea"); estage=$enext; eactive=$((enext+1)); crev=$erev; # crash:F1-before-intent
     jcreate || return 1
     # crash:F1-after-intent
   fi; case "$jintent" in F1-intent-openspec-staging) f1;; F2-intent-engram-staging) f2;; F3-intent-engram-active) f3;; F4-intent-openspec-active) f4;; *) return 1;; esac; }
  hput() { _he=$1; _hn=$2; _hs=$3; lookup "${txn}:before-${_hs}"; if [ "$_he" = absent ]; then [ "$status" = absent ] || return 1; _ho=none _hr=none _hp=none; else [ "$status" = found ] || return 1; hfile "$(efield "$w/response" content_hex)" "$w/hcurrent" "$(efield "$w/response" content_digest)" && cmp -s "$w/hcurrent" "$_he" || return 1; _ho=$(efield "$w/response" observation_id); _hr=$(efield "$w/response" store_revision); _hp=$(efield "$w/response" content_digest); fi; put_engram "$_hn" "$([ "$_he" = absent ] && printf absent || printf found)" "$_ho" "$_hr" "$_hp"; hread "$_hn" "$_hs"; }
  hjournal() { _hstate=$1; _hstep=$2; _hrec=$3; _ht=$hparent/.$(basename "$journal").stage.$$; { printf 'schema=ResolutionV1\nproject=%s\nmode=hybrid\nstate=%s\ntxn_id=%s\ngate_digest=%s\nintegrated_bundle_digest=%s\ncanonical_model_digest=%s\nstep=%s\nrecovery_step=%s\nopenspec_preimage_hex=%s\nopenspec_preimage_digest=%s\nopenspec_staging_hex=%s\nopenspec_staging_digest=%s\nopenspec_active_hex=%s\nopenspec_active_digest=%s\nengram_preimage_presence=%s\nengram_preimage_observation_id=%s\nengram_preimage_revision=%s\nengram_preimage_hex=%s\nengram_preimage_digest=%s\nengram_staging_hex=%s\nengram_staging_digest=%s\nengram_active_hex=%s\nengram_active_digest=%s\n' "$project" "$_hstate" "$txn" "$gd" "$bd" "$md" "$_hstep" "$_hrec" "$ophex" "$opdig" "$oshex" "$osdig" "$oahex" "$oadig" "$epres" "$eoid" "$erev" "$ehex" "$edig" "$eshex" "$esdig" "$eahex" "$eadig"; } > "$_ht" && mv -- "$_ht" "$journal" && reg "$journal"; }
  hload() { reg "$journal"; [ "$(field "$journal" schema)" = ResolutionV1 ] && [ "$(field "$journal" project)" = "$project" ] && [ "$(field "$journal" mode)" = hybrid ] && [ "$(field "$journal" txn_id)" = "$txn" ] && [ "$(field "$journal" gate_digest)" = "$gd" ] && [ "$(field "$journal" integrated_bundle_digest)" = "$bd" ] && [ "$(field "$journal" canonical_model_digest)" = "$md" ] || return 1; hstep=$(field "$journal" step); hstate=$(field "$journal" state); for k in openspec_preimage_hex openspec_preimage_digest openspec_staging_hex openspec_staging_digest openspec_active_hex openspec_active_digest engram_preimage_presence engram_preimage_observation_id engram_preimage_revision engram_preimage_hex engram_preimage_digest engram_staging_hex engram_staging_digest engram_active_hex engram_active_digest; do eval "v=\$(field \"$journal\" $k)"; case "$k" in openspec_preimage_hex) ophex=$v;; openspec_preimage_digest) opdig=$v;; openspec_staging_hex) oshex=$v;; openspec_staging_digest) osdig=$v;; openspec_active_hex) oahex=$v;; openspec_active_digest) oadig=$v;; engram_preimage_presence) epres=$v;; engram_preimage_observation_id) eoid=$v;; engram_preimage_revision) erev=$v;; engram_preimage_hex) ehex=$v;; engram_preimage_digest) edig=$v;; engram_staging_hex) eshex=$v;; engram_staging_digest) esdig=$v;; engram_active_hex) eahex=$v;; engram_active_digest) eadig=$v;; esac; done; hfile "$ophex" "$w/opre" "$opdig" && hfile "$oshex" "$w/os" "$osdig" && hfile "$oahex" "$w/oa" "$oadig" && { [ "$epres" = absent ] || hfile "$ehex" "$w/epre" "$edig"; } && hfile "$eshex" "$w/es" "$esdig" && hfile "$eahex" "$w/ea" "$eadig"; }
  hcheck() { case "$hstep" in journal) cmp -s "$target" "$w/opre" && { [ "$epres" = absent ] && lookup "${txn}:check-pre" && [ "$status" = absent ] || hraw "$w/epre"; };; openspec-staging) hmeta "$target" staging "$w/os" && { [ "$epres" = absent ] && lookup "${txn}:check-pre" && [ "$status" = absent ] || hraw "$w/epre"; };; engram-staging) hmeta "$target" staging "$w/os" && hread "$w/es" staging;; engram-active) hmeta "$target" staging "$w/os" && hread "$w/ea" active;; openspec-active) hmeta "$target" active "$w/oa" && hread "$w/ea" active;; *) return 1;; esac; }
  hrecover() { hload || return 1; case "$hstep" in engram-staging|engram-active|openspec-active) if [ "$epres" = absent ]; then hjournal recovery-required "$hstep" delete-new-canonical; return 1; fi; _hc=$w/ea; [ "$hstep" = engram-staging ] && _hc=$w/es; hput "$_hc" "$w/epre" active || { hjournal recovery-required "$hstep" restore-engram || :; return 1; };; esac; case "$hstep" in openspec-staging|engram-staging|engram-active|openspec-active) hatomic "$target" "$w/opre" && cmp -s "$target" "$w/opre" || { hjournal recovery-required "$hstep" restore-openspec || :; return 1; };; esac; hjournal prior-active compensated none; }
  hybrid() { reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || return 1; cp -- "$adapter" "$w/adapter" && chmod 700 "$w/adapter" || return 1; topic="sdd-init/$project"; field "$w/integrated" canonical_model_bytes | sed 's/^hex://' | xxd -r -p > "$w/model" || return 1; [ "$(dig "$w/model")" = "$md" ] || return 1; scan "$target"; hparent=$(dirname "$journal"); dir "$hparent"; if [ -e "$journal" ]; then hload && hcheck || return 1; [ "$hstate" = active ] && { [ "$hstep" = openspec-active ] || return 1; return 0; }; else cp -p "$target" "$w/opre" || return 1; lookup "${txn}:preimage" || return 1; case "$status" in absent) epres=absent; eoid=none; erev=none; ehex=none; edig=none; prior=absent; enext=1;; found) epres=found; eoid=$(efield "$w/response" observation_id); erev=$(efield "$w/response" store_revision); ehex=$(efield "$w/response" content_hex); edig=$(efield "$w/response" content_digest); hfile "$ehex" "$w/epre" "$edig" || return 1; prior=$erev; enext=$((erev+1));; *) return 1;; esac; hyaml "$w/os" staging; hyaml "$w/oa" active; markdown staging "$prior" "$enext" "$w/es" openspec; markdown active "$prior" $((enext+1)) "$w/ea" openspec; ophex=$(od -An -v -tx1 "$w/opre" | tr -d ' \n'); opdig=$(dig "$w/opre"); oshex=$(od -An -v -tx1 "$w/os" | tr -d ' \n'); osdig=$(dig "$w/os"); oahex=$(od -An -v -tx1 "$w/oa" | tr -d ' \n'); oadig=$(dig "$w/oa"); eshex=$(od -An -v -tx1 "$w/es" | tr -d ' \n'); esdig=$(dig "$w/es"); eahex=$(od -An -v -tx1 "$w/ea" | tr -d ' \n'); eadig=$(dig "$w/ea"); hjournal staging journal none || return 1; hstep=journal; fi; case "$hstep" in journal) hatomic "$target" "$w/os" && hmeta "$target" staging "$w/os" && hjournal staging openspec-staging none || return 1; hstep=openspec-staging;; esac; case "$hstep" in openspec-staging) hput "$([ "$epres" = absent ] && printf absent || printf '%s' "$w/epre")" "$w/es" staging && hjournal staging engram-staging none || return 1; hstep=engram-staging;; esac; case "$hstep" in engram-staging) hput "$w/es" "$w/ea" active && hjournal staging engram-active none || return 1; hstep=engram-active;; esac; case "$hstep" in engram-active) hatomic "$target" "$w/oa" && hmeta "$target" active "$w/oa" && hjournal staging openspec-active none || return 1; hstep=openspec-active;; esac; hjournal active openspec-active none; }
   terminal() { jload || return 1; case "$hstate:$jintent" in active:active) hmeta "$target" active "$w/oa" && eread "$w/ea" obs-1 "$eactive" active;; prior-active:prior-active) cmp -s "$target" "$w/opre" && [ "$(dig "$target")" = "$opdig" ] && { if [ "$epres" = absent ]; then lookup "${txn}:prior-absent" && [ "$status" = absent ]; else eraw "$w/epre" "$eoid" "$crev"; fi; };; *) return 1;; esac; }
   hybrid3() { reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || return 1; cp -- "$adapter" "$w/adapter" && chmod 700 "$w/adapter" || return 1; topic="sdd-init/$project"; otarget=$(printf %s "$target" | od -An -v -tx1 | tr -d ' \n'); hparent=$(dirname "$journal"); dir "$hparent"; lock=$hparent/.$(basename "$journal").resolution-lock; mkdir "$lock" || return 1; while :; do if [ -e "$journal" ] && jload && [ "$hstate:$jverified" = recovery-required:compensate ]; then compensate || return 1; continue; fi; if hybrid2; then jload || return 1; case "$jintent" in active|prior-active) terminal && return 0 || { jrecover || :; return 1; };; esac; else rc=$?; jload || return 1; case "$jintent" in active|prior-active) terminal && return 0 || { jrecover || :; return 1; };; C*-intent-*) compensate || return 1; continue;; esac; [ "$rc" = 77 ] || return 1; jcompensate || return 1; compensate || return 1; fi; done; }
   cmd=${1-}; shift || :; case "$cmd" in activate-openspec) [ "$#" = 5 ] || exit 2; project=$1; bundle=$2; target=$3; resolution=$4; gate=$5; mode=openspec;; activate-engram) [ "$#" = 5 ] || exit 2; project=$1; bundle=$2; adapter=$3; store=$4; gate=$5; mode=engram;; activate-hybrid) [ "$#" = 7 ] || exit 2; project=$1; bundle=$2; target=$3; journal=$4; adapter=$5; store=$6; gate=$7; mode=hybrid;; evaluate-none) [ "$#" = 3 ] || exit 2; project=$1; bundle=$2; gate=$3; mode=none;; *) exit 2;; esac
case "$project" in ''|*[!A-Za-z0-9._-]*) bad;; esac; dir "$bundle"; w=$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-activation.XXXXXX") || bad; chmod 700 "$w"; trap 'rm -rf "${w:-}" "${stage:-}" "${old:-}" "${out:-}"; rmdir "${lock:-}" 2>/dev/null || :' EXIT HUP INT TERM; verify_gate; [ "$(bundle_digest "$bundle")" = "$bd" ] || bad; txn=$(printf '%s\n%s\n%s\n%s\n%s\n' "$project" "$mode" "$gd" "$bd" "$md" | cksum | awk '{print "v1:"$1":"$2}'); crev=none
  if [ "$mode" = none ]; then state=candidate; backend=none; commits=none; emit; exit 0; fi
  if [ "$mode" = hybrid ]; then hybrid3 || { jrecover || :; bad; }; cat "$journal"; exit 0; fi
 if [ "$mode" = engram ]; then reg "$adapter"; dir "$store"; [ "$(dig "$adapter")" = "$PINNED_ENGRAM_ADAPTER_DIGEST" ] || bad; cp -- "$adapter" "$w/adapter"; chmod 700 "$w/adapter"; topic="sdd-init/$project"; cp "$w/integrated" "$w/receipt"; field "$w/receipt" canonical_model_bytes | sed 's/^hex://' | xxd -r -p > "$w/model" || bad; [ "$(dig "$w/model")" = "$md" ] || bad; lookup "${txn}:preimage"; case "$status" in absent) prior=absent; oid=none; rev=none; pd=none; expected=1;; found) oid=$(efield "$w/response" observation_id); rev=$(efield "$w/response" store_revision); pd=$(efield "$w/response" content_digest); prior=$rev; expected=$((rev+1)); prehex=$(efield "$w/response" content_hex);; *) bad;; esac; preoid=$oid; prerev=$rev; predigest=$pd; markdown staging "$prior" "$expected" "$w/staging"; put_engram "$w/staging" "$([ "$prior" = absent ] && printf absent || printf found)" "$oid" "$rev" "$pd"; readback "$(dig "$w/staging")" staging; oid=$(efield "$w/response" observation_id); rev=$(efield "$w/response" store_revision); markdown active "$prior" $((rev+1)) "$w/active"; put_engram "$w/active" found "$oid" "$rev" "$(efield "$w/response" content_digest)"; readback "$(dig "$w/active")" active; { printf 'schema=ResolutionV1\nproject=%s\nmode=engram\nstate=active\ntxn_id=%s\ncanonical_model_digest=%s\nengram_preimage_presence=%s\nengram_preimage_observation_id=%s\nengram_preimage_revision=%s\nengram_preimage_digest=%s\nengram_preimage_hex=%s\nengram_committed_revision=%s\ncommits=engram:staging:verified,engram:active:verified\n' "$project" "$txn" "$md" "$([ "$prior" = absent ] && printf absent || printf found)" "$preoid" "$prior" "$predigest" "${prehex-}" "$(efield "$w/response" store_revision)"; } ; exit 0; fi
scan "$target"; parent=$(dirname "$target"); dir "$parent"; [ ! -e "$resolution" ] && [ ! -L "$resolution" ] || bad; rparent=$(dirname "$resolution"); dir "$rparent"; lock=$parent/.$(basename "$target").rubric-lock; mkdir "$lock" || bad; old=$w/preimage; cp -p "$target" "$old" || bad; yaml "$w/yaml"; awk -v t="$txn" -v m="$md" '/^    authoritative: true$/{print;print "    schema: \"ResolutionV1\"";print "    state: \"active\"";print "    txn_id: \"" t "\"";print "    authority: \"openspec\"";print "    canonical_model_digest: \"" m "\"";next}{print}' "$w/yaml" > "$w/yaml.active" && mv -- "$w/yaml.active" "$w/yaml" || bad; stage=$(mktemp "$parent/.$(basename "$target").stage.XXXXXX") || bad; awk -v a="$t" -v z="$e" -v y="$w/yaml" 'NR==a{while((getline x<y)>0)print x;next}NR>=a&&NR<z{next}{print}' "$target" > "$stage" || bad; cmp -s "$target" "$old" && [ "$(bundle_digest "$bundle")" = "$bd" ] || bad; scan "$stage"; mv -- "$stage" "$target" || bad; committed=1; scan "$target"; backend=$(dig "$target"); state=active; commits=openspec:atomic-splice; out=$rparent/.$(basename "$resolution").stage.$$; emit > "$out" || bad; printf 'authority=openspec\nreadback=verified\n' >> "$out" || bad; [ "$(field "$out" canonical_model_digest)" = "$md" ] && [ "$(field "$out" backend_config_digest)" = "$backend" ] && [ "$(dig "$target")" = "$backend" ] || bad; mv -- "$out" "$resolution" || bad; committed=0; rmdir "$lock" || bad; trap - EXIT HUP INT TERM
<!-- rubric-activation:end -->
<!-- /gentle-ai:sdd-init-rubric -->
<!-- /shape:pi -->

<!-- shape:reference -->
# Rubric Authoring Method

Use this reference whenever rubric generation is selected or a rubric candidate may be generated, including rubric re-init. Read it before inspecting the project. It supplies the versioned global baseline for future task intent and the method for project refinements.

## Role Boundary

`sdd-init` is the semantic producer and the only policy writer. The deterministic compiler validates bindings, canonicalizes, persists, and fails closed; it never authors, broadens, or upgrades semantic rows. The orchestrator is read-only: it forwards a blocking selection or consumes resolved policy without inventing rows.

## Task-Intent Policy Baseline v1

This versioned Task-Intent Policy Baseline is global policy evidence, not advisory-only guidance. Record `baseline_version: task-intent-policy-baseline/v1` and `baseline_source_digest` from the installed reference bytes in canonical IR provenance. Baseline rows are prospective rules for future work, not claims that a task class currently exists in the repository.

| Task-intent class | Baseline mode | Validation minimum | Escalation |
| --- | --- | --- | --- |
| `new-observable-behavior` | `strict-tdd` | unit plus applicable integration/acceptance evidence | Require a selective behavior intent and boundary; ask when behavior is untestable |
| `bug-fix` | `strict-tdd` | reproducer first plus regression evidence | Ask when no reproducible behavior or boundary is known |
| `security-state-data-mutation` | `strict-tdd` | boundary and integration evidence | Escalate irreversible, cross-service, or unsafe-fixture changes |
| `migration-schema` | `strict-tdd` | migration, integration, build, and smoke evidence when available | Ask for destructive/non-append or ordering uncertainty |
| `behavior-preserving-refactor` | `standard` | regression, approval, or characterization evidence | Escalate when preservation or public behavior is uncertain |
| `ui-layout-style-only` | `standard` | visual and Playwright/E2E evidence when available | Do not require unit-TDD solely for layout; reclassify behavioral changes |
| `ui-behavior-or-bug` | `strict-tdd` | behavioral unit/reproducer plus visual/E2E evidence | Require behavioral intent; layout-only is not this class |
| `cross-layer-port-wiring` | `standard` | acceptance or integration evidence | Reclassify to new behavior when new domain behavior is introduced |
| `prompt-model-policy` | `standard` | characterization or domain validation | Escalate safety-sensitive or unbounded behavior changes |
| `config-infra-operations` | `standard` | smoke, build, and rollback evidence | Escalate security posture or state transition changes |
| `executable-script` | `standard` | dedicated test or smoke where available | Escalate state, credential, or production-data effects |
| `docs-runbook-metadata` | `skip` | optional format/link evidence | Reclassify executable examples or operational changes |
| `dependency-bump` | `standard` | relevant/full regression and build evidence | Escalate security-sensitive, breaking, or runtime-critical upgrades |
| `default` | conservative `standard` | only applicable bound evidence | Unmatched-only; never implicit `skip` or `strict-tdd` |

## Deterministic Baseline Fallback Producer

The LLM-assisted producer is primary. Fallback is eligible only before a valid candidate is published and only when that producer is unavailable or fails execution: `provider-unconfigured`, `provider-unavailable`, `provider-timeout`, `primary-output-malformed`, or `primary-output-structurally-invalid`. These are the complete `fallback_reason` enum; any other condition fails closed.

A valid existing rubric is preserved; fallback never replaces it. An invalid, duplicate, staging, recovery-required, conflicted, unavailable, or mismatched observed canonical state remains recovery-blocked; fallback MUST NOT overwrite or bypass it. When primary output is malformed or structurally invalid before canonical state publication, discard it and invoke fallback only as a pending candidate. After canonical state is observed, malformed primary output remains recovery-blocked and never invokes fallback.

Emit every Task-Intent Policy Baseline v1 row in baseline-table order, with its required baseline version and digest provenance. Bind only detected project capabilities that are satisfiable for the row scope; omit unavailable evidence rather than borrowing another scope. Do not infer external or project-specific policy, commands, evidence, or local rules. Record candidate provenance as `producer: deterministic-baseline-fallback` and `fallback_reason: one admitted enum value above`.

The fallback output is candidate/IR input only: it cannot write active YAML or Engram policy directly and cannot mint `ResolutionV1`. The canonical compiler validates and publishes primary and fallback candidates through exactly one shared path: structural validation, exact replay, canonical-model verification, canonical serialization, activation, and readback.

## Layered Policy And Selective Matching

Resolve policy in this order: global baseline, project evidence refinement, then manual project replacement. Project evidence may narrow a signature and enrich commands, validation evidence, paths, or symbols; it may replace baseline mode for an equivalent task class. An explicit project/manual row replaces the equivalent generated baseline row before runtime matching; never rely on strictest-wins between duplicate baseline and override rows. Preserve manual rows exactly. If explicit project policy contradicts the baseline but cannot be mapped to an equivalent task class, ask one granular blocking question for that class.

Absent project policy does not erase the baseline. A broad directory or path family alone cannot select `strict-tdd`; it must not override task intent. Under `all-rows + strictest-wins`, a strict row needs a selective task-intent class, corroborating path or symbol boundary, and exclusions where needed.

Runtime classification is intent-first: classify declared task intent, corroborate it with changed paths/symbols, reject ambiguous or multiple incompatible intents, then select specific rows. Apply strictest-wins only across genuinely orthogonal matches and union their evidence. The orchestrator consumes this resolved policy and forwards the selected combined row; it does not invent semantic rows.

## Granular Questions

Preserve the exact Lossless Blocking Prompt selection semantics: the policy representation question remains `allowed_answers: strict|rubric` and stops downstream work. When policy choices differ by task category, present distinct questions in one grouped prompt rather than one atomic question. Dependency, config, Docker, operations, prompt/model, and project-skill categories MUST remain separate questions; each category question uses only the existing mode domain `skip|standard|strict-tdd` and records its own evidence, rationale, and escalation.

## Canonical Compiler Handoff

Emit only the existing canonical directory candidate bundle/IR (`schema: v1`, `candidate-schema: v1`) consumed by the embedded rubric validator, adapter records/gate, canonical model, serializer, and activation functions. Do not write `openspec/config.yaml` or any active YAML directly. The compiler, not the semantic producer, serializes the canonical `testing.rubric` schema.

Each binding MUST have a stable ID and canonical command context: `executable`, ordered `argv`, `workdir`, `env`, supported `platforms` and `requirements`, declaration ref, independent tool-proof ref, scope/signature coverage, fact refs, and attestation refs. A row with disciplines or evidence MUST reference binding IDs; a method name or discipline name never substitutes for an ID. A `skip` row has no evidence claim and therefore carries an explicit empty binding-ref list.

`testing.methods` is not an authority namespace and is forbidden beside `testing.rubric`. Before persistence, require the existing structural validator, exact replay through adapter records/gate, canonical-model verification, canonical serializer, and activation/readback gates. If that deterministic pipeline cannot run, return only a pending candidate and the existing typed blocked envelope; never hand-author active YAML. `active/authoritative` is forbidden without `ResolutionV1`, transaction, canonical-model digest, backend authority, and verified readback evidence.

## Evidence First

Build two independent inventories before proposing any row.

| Inventory | Record | It may establish |
| --- | --- | --- |
| Implementation mode | Baseline version/digest or exact project/manual policy, source location, scope, affected work type, confidence | `skip`, `standard`, or `strict-tdd` when baseline or explicit policy establishes it |
| Validation evidence | Method, exact command, declaration, independent tool proof, cwd, environment, platform, scope/signature coverage, limits | A row's unit/integration/E2E/visual/build/smoke/coverage/lint/typecheck/format or local discipline requirements |

Test capability does not establish implementation mode. A test command, test directory, framework configuration, or CI test job proves only possible validation evidence until the versioned baseline, project policy, or manual policy establishes mode. Playwright/E2E is evidence, not a mode. A `strict-tdd` token invokes the full workflow through orchestrator forwarding and need not duplicate that workflow prose in every row.

For every command, verify its executable independently of the command text. Record wrappers, mutexes, required environment variables, cwd and platform constraints, mounted or unmounted paths, build-before-test requirements, CI-only execution, and command/proof mismatches. A command with an incompatible cwd, missing tool proof, inaccessible mount, wrong platform, or missing wrapper prerequisite is unavailable for that row.

## Project Inspection

Inspect and record every considered source, including sources that produced no usable fact:

- Root and nested `AGENTS.md`, `CLAUDE.md`, contributor guides, and local instructions.
- CI workflows, task runners, package or build manifests, lockfiles, and scripts.
- Architecture, security, state-management, migration, and operations documents.
- The installed skill registry and project-local skills.

For each considered source, record its path, purpose, scope, facts found, and why it did not support a claimed mode or evidence method. Inspect nested instructions before assigning a mode to the paths they govern.

## Semantic Classification

Classify observed project work, not only file extensions. Look for implementation modes and evidence obligations across:

- Domain/source behavior, APIs, adapters, architecture boundaries, and cross-module contracts.
- Authentication, authorization, secrets, state transitions, persistence, migrations, and data access.
- UI-visible behavior, accessibility, visual regression, client state, and end-to-end journeys.
- Behavior-preserving refactors and compatibility boundaries.
- Prompts, model configuration, infrastructure, deployment, scripts, runbooks, documentation, and dependency changes.

Emit every baseline task class prospectively, then apply project refinements and manual replacements. A broad `source` or `default` row is not a substitute for intent-first classification. If explicit policy cannot map to an equivalent baseline class, preserve the uncertainty as a blocking question; a project-specific manual seed may be necessary.

## Derivation Procedure

1. Build the two inventories independently and reject unsupported bindings before row design.
2. Materialize every versioned baseline task class with baseline provenance, even when repository inspection has no current instance. Apply equivalent project/manual replacement before matching.
3. Map validation evidence separately. Bind each method only to the scope, command context, and proof it actually covers.
4. Create project refinements for evidenced work types and preserve manual rows exactly on re-init. Do not emit a baseline row beside its equivalent replacement.
5. Model runtime matching mechanically: intent first, corroborating path/symbol evidence second, reject incompatible intent, then strictest-wins only for orthogonal matches and evidence union. Select `default` only for unmatched work; never use it to absorb every discovered method.
6. Close every binding ID and row binding reference against the candidate bundle. Verify command context closure, including wrappers, cwd, env, platform, mounts, and build prerequisites.
7. Simulate representative orchestrator resolution against the candidate before persistence. Fail if broad overlap makes unrelated work strict or skip, or if an equivalent baseline and override co-match.
8. Merge specific rows only when trigger semantics, mode, evidence, source, and selection behavior are identical. Prefer one compact specific skip row for non-executable documentation or metadata when evidence supports it. Utility scripts are not automatically skip.
9. Keep a candidate pending when any claimed mode or evidence lacks project evidence, the canonical schema is incomplete, or activation authority is unavailable. Do not persist or activate a guess.

## Generic Examples

These examples demonstrate separate axes. The placeholders are not reusable policy.

| Detectable trigger | Mode and its evidence | Validation evidence and its evidence |
| --- | --- | --- |
| `services/**` behavior change | `strict-tdd` from `[policy-source]: test-first behavior changes` | `unit` from `[task-declaration]` plus `[dependency-proof]`; `integration` only for the covered boundary |
| `web/**` user-visible behavior | `standard` from `[contributor-policy]: verification required before merge` | `unit`, `visual`, `e2e`, and `build` from their separately scoped commands and proofs |
| `schema/migrations/**` | `standard` from `[migration-policy]: review and verification requirement` | `integration`, `smoke`, and `build` only when each command supports migration scope |
| `docs/**` | `skip` only from `[documentation-policy]: no automated gate` | `format` or link checking only when independently declared and proven |

The E2E entry in the UI example does not determine `standard`; the policy source does. If either placeholder lacks equivalent project evidence, omit that claim and ask a blocking question instead.

## Canonical Handoff Example

This compact example is structural, not a project policy:

```text
binding id: ui-unit
  context: executable=task-runner; argv=[test, unit]; workdir=web; env=[]
  refs: declaration=fac-command; tool-proof=fac-tool; scope=path-prefix:web; attestations=[att-ui-unit]
row: ui-visible
  mode: standard; binding_refs=[ui-unit]; disciplines=[unit]
serializer output: testing.rubric.bindings[id=ui-unit] -> rows[binding_refs=[ui-unit]]
activation receipt: ResolutionV1 + txn_id + canonical_model_digest + authority + readback=verified
```

There is no `testing.methods` parallel namespace and no direct active YAML in this handoff.

## Result Contract

Return this human-readable projection in this exact order. It is a projection only; canonical IR preserves equivalent fields and remains authoritative.

## 1. Complete Rubric Table

| # | Detectable signature | Implementation mode | Disciplines/evidence | Binding refs | Source | Rationale/policy evidence |
| --- | --- | --- | --- | --- | --- | --- |

Render only specific rows here. Do not count or render `default` as a regular rubric row.

## 2. Default

Mode: `<pending question or conservative standard>`

Selection: `unmatched-only`

Evidence: `<only universally applicable bound evidence>`

Source: `<generated or manual>`

Rationale: `<why this applies only when no specific row matches>`

## 3. Complete Validation Bindings Table

| # | ID | Method | Scope | Executable/argv | Workdir | Env/platform/requirements | Declaration | Tool proof |
| --- | --- | --- | --- | --- | --- | --- | --- |

## 4. Orchestrator Resolution Simulation Table

| Case | Selected rows | Effective mode | Unioned evidence | Expected forwarding |
| --- | --- | --- | --- | --- |
| New endpoint | `new-observable-behavior` | `strict-tdd` | unit, integration | Intent-first strict workflow with bound API evidence |
| Bug fix | `bug-fix` | `strict-tdd` | reproducing unit, regression | Forward strict workflow with reproducing test first |
| Behavior-preserving refactor | `behavior-preserving-refactor` | `standard` | regression, approval | Forward standard workflow; no strict by broad source match |
| UI layout-only | `ui-layout-style-only` | `standard` | visual, e2e | Forward standard workflow with visual proof |
| UI behavioral bug | `bug-fix`, `ui-behavior-or-bug` | `strict-tdd` | reproducing unit, e2e | Intent-first strict workflow and union Playwright/E2E evidence |
| Migration | `migration-schema` | `strict-tdd` | migration integration, smoke, build | Forward strict baseline with migration-specific proof |
| Config-only | `config-infra-operations` | `standard` | smoke, rollback | Forward standard baseline; no strict path overlap |
| Docker-only | `config-infra-operations` | `standard` | build, smoke, rollback | Forward standard baseline; no strict path overlap |
| Prompt-only | `prompt-model-policy` | `standard` | characterization, domain validation | Forward standard baseline; no strict path overlap |
| Script-only | `executable-script` | `standard` | dedicated test or smoke | Forward standard baseline; never automatic skip |
| Docs-only | `docs-runbook-metadata` | `skip` | optional format/link | Forward one prospective docs/metadata skip baseline |
| Dependency-only | `dependency-bump` | `standard` | relevant/full regression, build | Forward standard baseline; no strict path overlap |
| Unmatched production file | `default` | pending or conservative `standard` | universal bound evidence only | Ask the default question or forward conservative standard |
| Overlapping security + API change | `new-observable-behavior`, `security-state-data-mutation` | `strict-tdd` | unit, integration, authorization boundary | Forward strict workflow with unioned API and security evidence |

## 5. Pending Questions And Activation/Receipt State

List every unresolved category question separately, then state candidate status and gate evidence: structural, exact replay, canonical model, serializer, and activation/readback. Active state is forbidden until the canonical receipt exists.

## Semantic Self-Audit

Before candidate persistence, answer all of these from recorded evidence:

- Does the candidate cover every observed semantic work type, including architecture, security/state, migration, UI, refactor, prompts/config/infra/scripts/docs/dependencies?
- Does each row's command agree with its declaration, cwd, wrapper, environment, platform, mount state, proof, and scope? Flag any command/cwd/proof contradiction.
- Is every mode supported by baseline provenance or explicit project/manual policy? Flag all-standard output when no policy evidence supports `standard`.
- Did the candidate miss mandatory policy, a nested instruction, or a project-local discipline?
- Are all matching specific rows modeled with strictest-wins mode and evidence union, while `default` remains unmatched-only?
- Does every strict row include selective task intent, boundary, and exclusions as needed, rather than only a broad path family?
- Does every baseline row bind `task-intent-policy-baseline/v1` and the installed-reference digest as policy provenance, while project/manual equivalents replace rather than co-match?
- Does runtime classification begin with declared intent, corroborate paths/symbols, and reject incompatible intents before strictest-wins?
- Does the required orchestrator simulation show selected rows, effective mode, unioned evidence, and forwarding for every Result Contract case without unrelated strict/skip overlap?
- Are skip rows compacted only when trigger semantics, mode, evidence, source, and selection behavior are identical, with Default shown separately and excluded from row count?
- Do binding IDs resolve, rows reference only those IDs, and every command has complete context and applicable wrapper/cwd/env/platform/mount/build constraints?
- Does the candidate use only the canonical schema, with no `testing.methods` authority or hand-authored active YAML?
- Has the required structural, replay, canonical-model, serializer, and activation/readback pipeline produced the `ResolutionV1` authority evidence required for active state?
- Are manual rows preserved and generated rows replaced deterministically on re-init?
- What confidence or uncertainty remains, and which blocking questions prevent a safe candidate?

Fail closed when a claimed mode or evidence lacks project evidence. Never collapse to six generic rows merely because capabilities are known.
<!-- /shape:reference -->
