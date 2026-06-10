#!/usr/bin/env bash
# Demo 12 — Surface-code quantum error correction. A rotated [[9,1,3]] surface
# code is built, a Pauli error is injected, the stabilizer syndrome is extracted
# on three different simulator backends (statevector / stabilizer / MPS), and a
# minimum-weight (MWPM) decoder corrects it. We then scale up to a distance-5
# [[25,1,5]] code, where the dense statevector is too large (2^37 amplitudes ~
# 2 TB) and only the stabilizer + MPS simulators are feasible. Numbers only.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 12: Surface-code error correction (MWPM, multi-backend) =="
note "dist: $QUANTUM_DIST_ROOT"

# `quantum ecc` needs the omega-sim simulator backends, which only link in a
# native build. A cross-built (e.g. Linux) eval bundle ships `ecc` inert, and an
# older bundle may predate the subcommand entirely — skip cleanly in both cases
# (like the libtorch demos), never a hard fail.
ECC_PROBE="$("$QBIN" ecc --distance 3 --backend stabilizer 2>&1)"
if echo "$ECC_PROBE" | grep -qiE "requires the simulator backends|unknown command"; then
    note "  (skip) this dist's quantum has no live 'ecc' backend"
    note "         (a cross/Linux core-CLI bundle, or a pre-ecc build). Build natively for ecc."
    exit 0
fi

say "\n1) The code & syndrome circuit (Aria — bit-flip sector, d=3):"
sed -n '1,12p' "$HERE/surface.aria" | sed 's/^/    /'

say "\n2) Run error correction on the default (stabilizer) backend (quantum ecc):"
OUT="$("$QBIN" ecc --distance 3 --backend stabilizer 2>/dev/null)"; echo "$OUT" | sed 's/^/    /'
echo "$OUT" | grep -qE "^ecc surface d=3 \[\[9,1,3\]\] data=9 x_checks=4 z_checks=4" && ok "code = 9 data + 4+4 checks (13-qubit syndrome sector)" || bad "circuit shape"
echo "$OUT" | grep -q "^clean_syndrome_weight 0$"        && ok "clean codestate has empty syndrome (weight 0)" || bad "clean syndrome"
echo "$OUT" | grep -q "^z_syndrome 1,1,0,0$"             && ok "injected X@4 lights Z-checks 0,1 -> syndrome 1,1,0,0" || bad "syndrome bits"
echo "$OUT" | grep -q "^correction_x 4$"                 && ok "MWPM decodes the syndrome back to X on qubit 4" || bad "decode"
echo "$OUT" | grep -q "^residual_syndrome_weight 0$"     && ok "after correction the residual syndrome is 0" || bad "residual"
echo "$OUT" | grep -q "^logical_failure 0$"              && ok "no logical error (single error is correctable)" || bad "logical"
echo "$OUT" | grep -q "^backend_agreement 1$"            && ok "statevector = stabilizer = MPS syndromes agree exactly" || bad "backend agreement"
echo "$OUT" | grep -q "^single_error_decode 18/18$"      && ok "all 18 single-qubit (X & Z) errors corrected" || bad "single-error battery"

say "\n3) Same error, exact statevector backend — must give the same syndrome:"
SV="$("$QBIN" ecc --distance 3 --backend statevector 2>/dev/null)"
echo "$SV" | grep "^z_syndrome" | sed 's/^/    /'
echo "$SV" | grep -q "^z_syndrome 1,1,0,0$"              && ok "statevector reproduces syndrome 1,1,0,0" || bad "statevector syndrome"

say "\n4) Logical error rate vs physical error rate (stabilizer Monte-Carlo):"
MC="$("$QBIN" ecc --distance 3 --backend stabilizer --p 0.01 --shots 8000 --seed 7 2>/dev/null)"
echo "$MC" | grep -E "^(physical_rate|logical_rate|suppressed)" | sed 's/^/    /'
echo "$MC" | grep -q "^suppressed 1$"                    && ok "logical error rate < physical rate (below pseudo-threshold)" || bad "suppression"

say "\n5) Scale up to a distance-5 [[25,1,5]] code (the RAM-safe path):"
note "    d=5 sectors are 37 qubits; a dense statevector is 2^37 ~ 2 TB, so only"
note "    the stabilizer (O(n^2) Clifford tableau) and MPS backends are feasible."
D5="$("$QBIN" ecc --distance 5 --backend stabilizer 2>/dev/null)"
echo "$D5" | grep -E "^(ecc surface|z_syndrome|backend_agreement|backends_checked|single_error_decode)" | sed 's/^/    /'
echo "$D5" | grep -q "^ecc surface d=5 \[\[25,1,5\]\]" && ok "rotated surface code [[25,1,5]] built (25 data + 12+12 checks)" || bad "d=5 code"
echo "$D5" | grep -q "^backend_agreement 1$"           && ok "stabilizer & MPS agree on the d=5 syndrome bit-for-bit" || bad "d=5 agreement"
echo "$D5" | grep -q "^backends_checked stabilizer,mps,pauliprop$" && ok "statevector skipped (too large); stabilizer+mps+pauliprop agree" || bad "d=5 backends checked"
echo "$D5" | grep -q "^single_error_decode 50/50$"     && ok "all 50 single-qubit (X & Z) errors corrected at d=5" || bad "d=5 single-error battery"

# The dense statevector must REFUSE d=5 (exit 2) rather than exhaust RAM.
SVERR="$("$QBIN" ecc --distance 5 --backend statevector 2>&1)"; SVCODE=$?
echo "$SVERR" | grep "infeasible for distance 5" | sed 's/^/    /'
{ [ "$SVCODE" = 2 ] && echo "$SVERR" | grep -q "infeasible for distance 5 (37 qubits)"; } \
    && ok "statevector backend refuses d=5 cleanly (exit 2, no OOM)" || bad "d=5 statevector refusal"

say "\n6) Distance 7 [[49,1,7]] via Pauli propagation (the only backend that fits):"
note "    pauliprop reads each check's expectation value <C>=+-1 instead of a"
note "    projective shot, so it has no 64-qubit measurement-key cap and stays"
note "    exact + O(MB) for the Clifford syndrome at any distance."
D7="$("$QBIN" ecc --distance 7 --backend pauliprop 2>/dev/null)"
echo "$D7" | grep -E "^(ecc surface|syndrome_weight|logical_failure|backends_checked|single_error_decode)" | sed 's/^/    /'
echo "$D7" | grep -q "^ecc surface d=7 \[\[49,1,7\]\]"  && ok "distance-7 surface code [[49,1,7]] built (49 data qubits)" || bad "d=7 code"
echo "$D7" | grep -q "^backends_checked pauliprop$"     && ok "pauliprop is the sole feasible backend at d=7" || bad "d=7 backend"
echo "$D7" | grep -q "^single_error_decode 98/98$"      && ok "all 98 single-qubit (X & Z) errors corrected at d=7" || bad "d=7 battery"
# Measurement backends must refuse d=7 (64-bit key cap), pointing at pauliprop.
SREF="$("$QBIN" ecc --distance 7 --backend stabilizer 2>&1)"; SREFC=$?
{ [ "$SREFC" = 2 ] && echo "$SREF" | grep -q "pauliprop"; } \
    && ok "stabilizer refuses d=7 and points to pauliprop (exit 2)" || bad "d=7 stabilizer refusal"

note "\nThe surface code turns a 1% physical error rate into a sub-1% logical rate,"
note "independent simulators agree on the syndrome to the bit, distance-5 scales"
note "on stabilizer/MPS where a dense statevector cannot, and Pauli propagation"
note "(a Heisenberg-picture Pauli-string tree) carries error correction to d=7+."
finish
