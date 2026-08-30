#!/usr/bin/env bash
# Demo 13 — Pauli propagation. A fourth simulation scheme (arXiv:2505.21606):
# evolve an OBSERVABLE backward through the circuit as a tree of weighted Pauli
# strings and read off ⟨O⟩ — exact and width-unbounded for Clifford circuits, a
# tunable approximation for non-Clifford ones. All through `quantum expect` on
# the binary-only dist. Numbers only.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 13: Pauli propagation — expectation values (quantum expect) =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The model (Aria), and the exporter REFUSING to lie about it:"
sed -n '15,33p' "$HERE/trotter_ising.aria" | sed 's/^/    /'
# This check used to assert that `spec extract` emitted a >=40-line
# TrotterIsing.lean. It has been failing since 2026-08-15, when 9bf2894 ("the
# exporter emitted proof obligations about a different circuit") taught the
# exporter to refuse a circuit containing gates with no Lean `Circuit`
# constructor. TrotterIsing uses RX. The exporter is right and the demo's claim
# was not achievable; nothing caught it for two weeks because no CI stage runs
# the demos (see ci.sh stage 11c).
#
# So the check now asserts the REFUSAL, by its reason. That is the stronger
# demonstration anyway: an exporter that silently dropped RX would emit a
# beautiful Lean theorem about a circuit the user did not write.
LEANDIR="$(mktemp -d)"
EXTRACT="$("$QBIN" spec extract --aria "$HERE/trotter_ising.aria" --all --out "$LEANDIR" 2>&1)"
EMITTED=$(ls "$LEANDIR" 2>/dev/null | wc -l | tr -d ' ')
echo "$EXTRACT" | sed 's/^/    /'
if echo "$EXTRACT" | grep -q "no Lean \`Circuit\` constructor and are dropped: RX" \
   && echo "$EXTRACT" | grep -q "Refusing to emit a proof obligation about a different circuit" \
   && [ "$EMITTED" = 0 ]; then
    ok "spec extract REFUSES TrotterIsing (RX has no Lean constructor) and emits 0 files"
else
    bad "spec extract did not refuse by the expected reason (emitted $EMITTED file(s))"
fi
rm -rf "$LEANDIR"

# Steps 2+ use `quantum expect`, which needs the native omega-sim backends. A
# cross-built (Linux) bundle ships them inert; finish cleanly after the Aria
# check there, like the libtorch demos.
PROBE="$("$QBIN" expect "$HERE/trotter_ising.qasm" --backend pauliprop --observable Z0 2>&1)"
if echo "$PROBE" | grep -qiE "requires the simulator backends|unknown command"; then
    note "  (skip) the expectation backend is inert in this bundle (cross/Linux core-CLI)."
    finish    # reports the Aria→Lean check; exits 1 if it failed
    exit 0
fi

say "\n2) ⟨O⟩ via Pauli propagation must equal the exact statevector (cross-check):"
OBS="Z0,Z2,Z0Z5,Z1Z2Z3"
PP="$("$QBIN" expect "$HERE/trotter_ising.qasm" --backend pauliprop  --observable "$OBS" 2>/dev/null | grep '^observable')"
SV="$("$QBIN" expect "$HERE/trotter_ising.qasm" --backend statevector --observable "$OBS" 2>/dev/null | grep '^observable')"
echo "$PP" | sed 's/^/    pp  /'
if [ "$PP" = "$SV" ]; then ok "pauliprop ⟨O⟩ == statevector for all of: $OBS"; else bad "pauliprop vs statevector mismatch"; fi

say "\n3) Truncation-error curve — drop Pauli terms below |coeff| < C (⟨Z2⟩):"
EXACT=$("$QBIN" expect "$HERE/trotter_ising.qasm" --backend pauliprop --observable "Z2" 2>/dev/null | awk '/^observable Z2/{print $4}')
note "    exact ⟨Z2⟩ = $EXACT"
echo "    C        value          dropped_mass    |err|     bounded  informative"
ALL_BOUNDED=1; PREV_DROP=""; ERR_LOOSE=""; ERR_TIGHT=""; DROP_MONO=1; INF_AT_TIGHTEST=0
for C in 1e-1 1e-2 1e-3; do
    OUT="$("$QBIN" expect "$HERE/trotter_ising.qasm" --backend pauliprop --observable "Z2" --truncate $C --max-dropped-mass inf 2>/dev/null)"
    V=$(echo "$OUT" | awk '/^observable Z2/{print $4}'); D=$(echo "$OUT" | awk '/^dropped_mass/{print $2}')
    read -r ERR BND <<<"$(awk -v v="$V" -v e="$EXACT" -v d="$D" 'BEGIN{er=v-e; if(er<0)er=-er; printf "%.6f %d", er, (er<=d+1e-9)?1:0}')"
    # Is the bound INFORMATIVE, i.e. does it exclude anything?
    #
    # The run asserts <O> in [v-m, v+m]; we already knew <O> in [-R, R], with
    # R = 1 for a single Pauli string. The bound teaches nothing exactly when
    # the first interval contains the second:
    #
    #   [v-m, v+m] ⊇ [-R, R]  <=>  v-m <= -R AND v+m >= R
    #                         <=>  m >= v+R AND m >= R-v
    #                         <=>  m >= R + |v|
    #
    # so informative <=> m < R + |v|. Derived rather than guessed, and verified
    # against a swept (v, m) grid before use — the aria-oss session and this
    # repo had independently picked m < R and m < 2R, two defensible thresholds
    # a factor of two apart, and neither is the condition. m < R is the v = 0
    # special case and over-refuses; m < 2R is the loosest and under-refuses.
    #
    # The two coincide at v = 0, which is the case that started this: an engine
    # that truncates every term and returns exactly 0.0.
    INF=$(awk -v d="$D" -v v="$V" 'BEGIN{R=1.0; av=(v<0?-v:v); print (d < R+av)?1:0}')
    printf "    %-8s %-14s %-15s %-9s %-8s %s\n" "$C" "$V" "$D" "$ERR" \
        "$([ "$BND" = 1 ] && echo yes || echo NO)" "$([ "$INF" = 1 ] && echo yes || echo NO)"
    [ "$BND" = 1 ] || ALL_BOUNDED=0
    INF_AT_TIGHTEST="$INF"
    [ -n "$PREV_DROP" ] && [ "$(awk -v a="$PREV_DROP" -v b="$D" 'BEGIN{print (b<a)?1:0}')" != 1 ] && DROP_MONO=0
    PREV_DROP="$D"
    [ -z "$ERR_LOOSE" ] && ERR_LOOSE="$ERR"; ERR_TIGHT="$ERR"
done
[ "$ALL_BOUNDED" = 1 ] && ok "every truncated estimate is within its reported dropped_mass budget" || bad "a truncation exceeded its budget"
# The fourth assertion, added 2026-08-27 at the aria-oss session's suggestion,
# and it closes a real hole in the three above.
#
# Those three only exercise "is the bound HONOURED", never "is the bound WORTH
# READING". |<P>| <= 1 for a Pauli string, so a dropped_mass >= 1 admits every
# value the observable can take and tells the caller nothing — while remaining
# formally correct, and while satisfying assertion 1 trivially. Measured by the
# aria-oss session at depth 16: pauliprop returns EXACTLY 0.0, every term
# truncated away, presented as an ordinary expectation value with a budget of
# +/-144 around it. That is not an approximate answer with a loose error bar,
# it is the absence of an answer wearing one.
#
# What this run measures (real numbers, this circuit, 2026-08-27):
#
#   C      value         dropped_mass   |err|        bounded  informative
#   1e-1   0.7054827807  2.0611179454   0.005777135  yes      NO
#   1e-2   0.6945467372  0.4700564981   0.016713179  yes      yes
#   1e-3   0.7114403392  0.0799793417   0.000180423  yes      yes
#
# So the loosest cutoff here ALREADY produces an uninformative bound (2.06 on a
# quantity in [-1,1]) and the three original assertions passed it happily. That
# is the hole, present in this demo at the first cutoff it tests, not only at
# depth.
#
# The assertion is therefore on the TIGHTEST cutoff, not on all of them:
# requiring every C to be informative would pin a transition that is expected
# and healthy — a loose cutoff SHOULD have a loose budget. What must never
# happen is that tightening the cutoff fails to buy information, which is
# exactly the depth-16 failure mode, where even the tightest C reports 1413.
[ "$INF_AT_TIGHTEST" = 1 ] && ok "at the tightest cutoff the bound is INFORMATIVE (dropped_mass < R+|v|, so it excludes something)" || bad "even at the tightest cutoff dropped_mass >= R+|v| — a correct bound that excludes nothing"
[ "$DROP_MONO" = 1 ]   && ok "the error budget (dropped_mass) shrinks monotonically as C tightens" || bad "dropped_mass not monotone"
CONV=$(awk -v t="$ERR_TIGHT" -v l="$ERR_LOOSE" 'BEGIN{print (t<l && t<1e-3)?1:0}')
[ "$CONV" = 1 ] && ok "the estimate converges: |err| $ERR_TIGHT at C=1e-3 < $ERR_LOOSE at C=1e-1 (and < 1e-3)" || bad "no convergence"

say "\n4) Scaling — a 24-qubit GHZ where a dense statevector can't fit on the eval cap:"
G="$("$QBIN" expect "$HERE/ghz24.qasm" --backend pauliprop --observable "Z0Z23,Z0" 2>/dev/null)"
echo "$G" | grep '^observable' | sed 's/^/    /'
echo "$G" | grep -q "^observable Z0Z23 = 1.0000000000$" && ok "pauliprop ⟨Z0·Z23⟩ = 1 on a 24-qubit GHZ (exact, instant)" || bad "GHZ ZZ"
echo "$G" | grep -q "^observable Z0 = 0.0000000000$"     && ok "pauliprop ⟨Z0⟩ = 0 on the GHZ" || bad "GHZ Z0"
SVG="$("$QBIN" expect "$HERE/ghz24.qasm" --backend statevector --observable "Z0Z23" 2>&1)"; SVC=$?
if [ "$SVC" != 0 ] && echo "$SVG" | grep -qi "limited to"; then
    ok "dense statevector refused at 24 qubits (eval cap) — pauliprop is the scalable path"
elif echo "$SVG" | grep -q "^observable Z0Z23 = 1.0000000000$"; then
    ok "dense statevector agrees (⟨Z0·Z23⟩ = 1) on this uncapped build"
else
    bad "unexpected statevector result at 24 qubits"
fi

note "\nPauli propagation reads ⟨O⟩ in the Heisenberg picture: exact for Clifford"
note "circuits at any width, and a coefficient-truncated approximation for"
note "non-Clifford ones — with a reported error budget that shrinks to the exact"
note "answer. Complementary to the statevector / stabilizer / MPS backends."
finish
