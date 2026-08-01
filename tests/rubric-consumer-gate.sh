#!/usr/bin/env bash
# Hermetic consumer-state fixtures. The gate only validates persisted evidence.
set -uo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; TMP="$(mktemp -d "${TMPDIR:-/tmp}/gentle-ai-rubric-consumer.XXXXXX")"; trap 'rm -rf -- "$TMP"' EXIT
PASS=0; FAIL=0
ok() { printf 'PASS: %s\n' "$1"; PASS=$((PASS+1)); }
no() { printf 'FAIL: %s\n' "$1" >&2; FAIL=$((FAIL+1)); }
need() { "$@" && ok "$1" || no "$1"; }
extract() { awk '$0=="<!-- shape:details -->"{s=1;next}$0=="<!-- /shape:details -->"{exit}s&&$0=="<!-- rubric-consumer-gate:start -->"{g=1;next}s&&$0=="<!-- rubric-consumer-gate:end -->"{exit}g{print}' "$ROOT/deltas/sdd-init-rubric.md" > "$TMP/gate"; awk '$0=="<!-- shape:pi -->"{s=1;next}$0=="<!-- /shape:pi -->"{exit}s&&$0=="<!-- rubric-consumer-gate:start -->"{g=1;next}s&&$0=="<!-- rubric-consumer-gate:end -->"{exit}g{print}' "$ROOT/deltas/sdd-init-rubric.md" > "$TMP/pi-gate"; [ -s "$TMP/gate" ] && cmp -s "$TMP/gate" "$TMP/pi-gate" && chmod +x "$TMP/gate"; }
dig() { cksum "$1" | awk '{print $1":"$2}'; }
field() { awk -F= -v k="$2" '$1==k{n++;v=substr($0,length(k)+2)}END{if(n==1)print v;else exit 1}' "$1"; }
run() { "$TMP/gate" consume "$@" > "$TMP/out" 2>/dev/null; }
blocked() { ! run "$1" "$2" "$3" "$4" "$5" && grep -Fxq 'schema=RubricConsumerBlockedV1' "$TMP/out" && grep -Fxq "backend=$6" "$TMP/out" && grep -Fxq "mismatch=$7" "$TMP/out" && grep -Fxq 'recovery_action=run sdd-init recovery' "$TMP/out"; }
active() { run "$@" && grep -Fxq 'schema=RubricConsumerEnvelopeV1' "$TMP/out" && grep -Fxq 'resolution_owner=orchestrator' "$TMP/out"; }
printf 'CanonicalPolicyModelV1\nrow=unit\n' > "$TMP/model"; MD="$(dig "$TMP/model")"
os() { local d=$1 state=${2-active} txn=${3-txn-1} model=${4-$MD}; mkdir -p "$d"; cat > "$d/config" <<EOF
testing:
  policy: "rubric"
  rubric:
    active: true
    authoritative: true
    schema: "ResolutionV1"
    state: "$state"
    txn_id: "$txn"
    authority: "openspec"
    canonical_model_digest: "$model"
EOF
  cat > "$d/resolution" <<EOF
schema=ResolutionV1
state=$state
txn_id=$txn
authority=openspec
canonical_model_digest=$model
backend_config_digest=$(dig "$d/config")
readback=verified
EOF
  sed -i "s/^'txn_id=/txn_id=/;s/'$//" "$d/resolution"; }
engram() { local f=$1 state=${2-active} txn=${3-txn-1} model=${4-$MD} auth=${5-engram}; cat > "$f" <<EOF
# SDD Init Canonical Policy

schema=ActivationStateV1
state=$state
txn_id=$txn
authority=$auth
canonical_model_digest=$model
backend_payload_digest=$(dig "$TMP/model")
committed_revision=4
backend_revision=4
readback=verified

## CanonicalPolicyModelV1

\`\`\`text
$(cat "$TMP/model")
\`\`\`
EOF
}
session() { cat > "$1" <<EOF
schema=IntegratedValidationV1
state=verified
commits=none
current_session=true
txn_id=none
canonical_model_digest=$MD
EOF
}
extract || { printf 'FAIL: consumer gate was not installed\n'; exit 1; }
os "$TMP/os"; engram "$TMP/engram"; session "$TMP/session"
active apply openspec "$TMP/os" - - && ok 'OpenSpec active forwards one orchestrator envelope' || no 'OpenSpec active forwards one orchestrator envelope'
# shellcheck disable=SC2100 # Literal '-' values are the consumer gate's absent-backend sentinels.
for kind in absent malformed duplicate staging recovery-required conflict outage backend readback; do cp -a "$TMP/os" "$TMP/$kind"; case "$kind" in absent) : > "$TMP/$kind/config";; malformed) sed -i '/txn_id/d' "$TMP/$kind/config";; duplicate) sed -i '/schema:/a\    schema: "ResolutionV1"' "$TMP/$kind/config";; staging|recovery-required) sed -i "s/state=active/state=$kind/;s/state: \"active\"/state: \"$kind\"/" "$TMP/$kind"/{config,resolution};; conflict) sed -i 's/txn_id=txn-1/txn_id=other/' "$TMP/$kind/resolution";; outage) rm "$TMP/$kind/resolution";; backend) sed -i 's/backend_config_digest=.*/backend_config_digest=0:0/' "$TMP/$kind/resolution";; readback) sed -i 's/readback=verified/readback=missing/' "$TMP/$kind/resolution";; esac; reason=$kind; [ "$kind" = conflict ] && reason=txn-mismatch; [ "$kind" = backend ] && reason=backend-mismatch; [ "$kind" = readback ] && reason=readback-invalid; blocked apply openspec "$TMP/$kind" - - openspec "$reason" && ok "OpenSpec $kind blocks" || no "OpenSpec $kind blocks"; done
cp -a "$TMP/os" "$TMP/parallel-methods"; printf '%s\n' '  methods:' '    unit: "ad-hoc"' >> "$TMP/parallel-methods/config"; sed -i "s/backend_config_digest=.*/backend_config_digest=$(dig "$TMP/parallel-methods/config")/" "$TMP/parallel-methods/resolution"; blocked apply openspec "$TMP/parallel-methods" - - openspec parallel-methods && ok 'parallel testing.methods authority blocks' || no 'parallel testing.methods authority was accepted'
cp -a "$TMP/os" "$TMP/direct-active"; rm "$TMP/direct-active/resolution"; blocked apply openspec "$TMP/direct-active" - - openspec outage && ok 'direct active YAML without activation authority blocks' || no 'direct active YAML was accepted'
cp -a "$TMP/os" "$TMP/pending-active"; sed -i 's/state: "active"/state: "pending"/' "$TMP/pending-active/config"; sed -i 's/state=active/state=pending/' "$TMP/pending-active/resolution"; sed -i "s/backend_config_digest=.*/backend_config_digest=$(dig "$TMP/pending-active/config")/" "$TMP/pending-active/resolution"; blocked apply openspec "$TMP/pending-active" - - openspec state-mismatch && ok 'pending active rubric blocks' || no 'pending active rubric was accepted'
# shellcheck disable=SC2100 # Literal '-' values are the consumer gate's absent-backend sentinels.
for kind in malformed duplicate staging recovery-required outage txn model revision readback; do cp "$TMP/engram" "$TMP/e-$kind"; case "$kind" in malformed) sed -i '/txn_id/d' "$TMP/e-$kind";; duplicate) sed -i '/schema=/a schema=ActivationStateV1' "$TMP/e-$kind";; staging|recovery-required) sed -i "s/state=active/state=$kind/" "$TMP/e-$kind";; outage) rm "$TMP/e-$kind";; txn) sed -i 's/txn_id=txn-1/txn_id=bad;data/' "$TMP/e-$kind";; model) sed -i 's/^canonical_model_digest=.*/canonical_model_digest=0:0/' "$TMP/e-$kind";; revision) sed -i 's/backend_revision=4/backend_revision=5/' "$TMP/e-$kind";; readback) sed -i 's/readback=verified/readback=missing/' "$TMP/e-$kind";; esac; reason=$kind; case "$kind" in txn) reason=malformed;; model) reason=model-mismatch;; revision|readback) reason=readback-invalid;; esac; blocked verify engram - "$TMP/e-$kind" - engram "$reason" && ok "Engram $kind blocks" || no "Engram $kind blocks"; done
active verify engram - "$TMP/engram" - && ok 'Engram active forwards exact canonical state' || no 'Engram active forwards exact canonical state'
cp "$TMP/engram" "$TMP/hybrid"; sed -i 's/authority=engram/authority=openspec/' "$TMP/hybrid"; active apply hybrid "$TMP/os" "$TMP/hybrid" - && ok 'hybrid equivalent active surfaces forward' || no 'hybrid equivalent active surfaces forward'
for kind in txn model outage; do cp -a "$TMP/os" "$TMP/h-$kind"; cp "$TMP/hybrid" "$TMP/hybrid-$kind"; case "$kind" in txn) sed -i 's/txn_id=txn-1/txn_id=other/' "$TMP/hybrid-$kind";; model) sed -i 's/^canonical_model_digest=.*/canonical_model_digest=0:0/' "$TMP/hybrid-$kind";; outage) rm "$TMP/hybrid-$kind";; esac; reason=$kind-mismatch; [ "$kind" = outage ] && reason=outage; blocked apply hybrid "$TMP/h-$kind" "$TMP/hybrid-$kind" - both "$reason" && ok "hybrid $kind blocks" || no "hybrid $kind blocks"; done
active apply none - - "$TMP/session" && grep -Fxq 'state=candidate' "$TMP/out" && ok 'none forwards only a nonpersistent candidate' || no 'none forwards only a nonpersistent candidate'
sed 's/state=verified/state=pending/' "$TMP/session" > "$TMP/session-bad"; blocked apply none - - "$TMP/session-bad" session state-mismatch && ok 'none without verified receipt blocks' || no 'none without verified receipt blocks'
mkdir "$TMP/legacy"; active apply legacy "$TMP/legacy" - - && grep -Fxq 'mode=binary' "$TMP/out" && ok 'legacy binary remains only without rubric observation' || no 'legacy binary remains only without rubric observation'
blocked apply legacy "$TMP/os" - - legacy absent && ok 'observed rubric suppresses legacy fallback' || no 'observed rubric suppresses legacy fallback'
cp -a "$TMP/os" "$TMP/recovered"; sed -i 's/state=active/state=recovery-required/;s/state: "active"/state: "recovery-required"/' "$TMP/recovered"/{config,resolution}; blocked apply openspec "$TMP/recovered" - - openspec recovery-required && sed -i 's/recovery-required/active/g' "$TMP/recovered"/{config,resolution} && sed -i "s/backend_config_digest=.*/backend_config_digest=$(dig "$TMP/recovered/config")/" "$TMP/recovered/resolution" && active apply openspec "$TMP/recovered" - - && ok 'recovery resumes only after active readback' || no 'recovery resumes only after active readback'
marker="$TMP/executed"; cp -a "$TMP/os" "$TMP/injection"; printf 'txn_id=txn;$(touch %s)\n' "$marker" >> "$TMP/injection/resolution"; blocked apply openspec "$TMP/injection" - - openspec malformed && [ ! -e "$marker" ] && ok 'fixture data is never executed' || no 'fixture data is never executed'
checkline() { grep -Fxq "$1" "$TMP/out" && ok "envelope contains $1" || no "envelope lacks $1"; }
active apply openspec "$TMP/os" - -; for x in schema=RubricConsumerEnvelopeV1 backend=openspec mode=openspec state=active txn_id=txn-1; do checkline "$x"; done
active verify engram - "$TMP/engram" -; for x in schema=RubricConsumerEnvelopeV1 backend=engram mode=engram state=active txn_id=txn-1; do checkline "$x"; done
active apply hybrid "$TMP/os" "$TMP/hybrid" -; for x in schema=RubricConsumerEnvelopeV1 backend=both mode=hybrid state=active txn_id=txn-1; do checkline "$x"; done
active apply none - - "$TMP/session"; for x in schema=RubricConsumerEnvelopeV1 backend=session mode=none state=candidate txn_id=none; do checkline "$x"; done
! run apply openspec "$TMP/staging" - -; for x in schema=RubricConsumerBlockedV1 backend=openspec observed_state=staging mismatch=staging 'recovery_action=run sdd-init recovery'; do checkline "$x"; done
! grep -Eq 'strict_tdd|default|eval' "$TMP/gate" && ok 'gate contains no forbidden fallback policy or evaluator' || no 'gate contains forbidden fallback policy or evaluator'
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"; [ "$FAIL" -eq 0 ]
