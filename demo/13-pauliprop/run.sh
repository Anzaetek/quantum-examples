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

say "\n1) The model (Aria) and its Lean 4 extraction:"
sed -n '15,33p' "$HERE/trotter_ising.aria" | sed 's/^/    /'
LEANDIR="$(mktemp -d)"
"$QBIN" spec extract --aria "$HERE/trotter_ising.aria" --all --out "$LEANDIR" >/dev/null 2>&1
LN=$(wc -l < "$LEANDIR/TrotterIsing.lean" 2>/dev/null || echo 0)
[ "${LN:-0}" -ge 40 ] && ok "Aria TrotterIsing → Lean 4 theorem ($LN lines)" || bad "aria→lean extraction"
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
echo "    C        value          dropped_mass    |err|     bounded"
ALL_BOUNDED=1; PREV_DROP=""; ERR_LOOSE=""; ERR_TIGHT=""; DROP_MONO=1
for C in 1e-1 1e-2 1e-3; do
    OUT="$("$QBIN" expect "$HERE/trotter_ising.qasm" --backend pauliprop --observable "Z2" --truncate $C 2>/dev/null)"
    V=$(echo "$OUT" | awk '/^observable Z2/{print $4}'); D=$(echo "$OUT" | awk '/^dropped_mass/{print $2}')
    read -r ERR BND <<<"$(awk -v v="$V" -v e="$EXACT" -v d="$D" 'BEGIN{er=v-e; if(er<0)er=-er; printf "%.6f %d", er, (er<=d+1e-9)?1:0}')"
    printf "    %-8s %-14s %-15s %-9s %s\n" "$C" "$V" "$D" "$ERR" "$([ "$BND" = 1 ] && echo yes || echo NO)"
    [ "$BND" = 1 ] || ALL_BOUNDED=0
    [ -n "$PREV_DROP" ] && [ "$(awk -v a="$PREV_DROP" -v b="$D" 'BEGIN{print (b<a)?1:0}')" != 1 ] && DROP_MONO=0
    PREV_DROP="$D"
    [ -z "$ERR_LOOSE" ] && ERR_LOOSE="$ERR"; ERR_TIGHT="$ERR"
done
[ "$ALL_BOUNDED" = 1 ] && ok "every truncated estimate is within its reported dropped_mass budget" || bad "a truncation exceeded its budget"
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
