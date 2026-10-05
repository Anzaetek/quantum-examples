#!/usr/bin/env bash
# Demo 14 — Transversal low-overhead QEC: run textbook algorithms as *logical*
# circuits on encoded qubits, plus surface-code memory logical-error curves and
# effective-logical-channel extraction. Models the neutral-atom "Transversal
# STAR" / trapped-ion small-code family (arXiv:2509.18294, Quantinuum). Encoded
# 2-qubit Grover is pure Clifford, so it runs *exactly* on Pauli-propagation.
# Numbers only — every line is checked against a golden within tolerance.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"

say "== Demo 14: Transversal QEC — logical QFT / QPE / Grover, memory curves =="
note "dist: $QUANTUM_DIST_ROOT"

# `quantum logical` needs the omega-sim backends (native build only). A
# cross-built / older bundle ships it inert — skip cleanly, never a hard fail.
PROBE="$("$QBIN" logical grover --marked 0 2>&1)"
if echo "$PROBE" | grep -qiE "requires the simulator backends|unknown command|usage:"; then
    note "  (skip) this dist's quantum has no live 'logical' backend"
    note "         (a cross/Linux core-CLI bundle, or a pre-logical build)."
    exit 0
fi

# --- numeric helpers (awk float compare) ---
val() { echo "$1" | grep -oE "$2 [-0-9.eE]+" | awk '{print $2}'; }
# `val` yields "" when the field is absent (renamed output, a binary built
# without --features omega-sim, a crashed subcommand). `awk -v a=""` then reads
# it as 0, so an all-empty comparison comes out EQUAL and the check passes.
# Every numeric assertion below must therefore prove the values exist first.
have() { for v in "$@"; do [ -n "$v" ] || return 1; done; return 0; }
le()  { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<=b)}'; }
lt()  { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a<b)}'; }

say "\n1) Encoded 2-qubit Grover on the Steane [[7,1,3]] code (Pauli-prop, exact):"
ALLOK=1
for m in 0 1 2 3; do
    OUT="$("$QBIN" logical grover --marked $m 2>/dev/null)"
    S="$(val "$OUT" success)"
    echo "$OUT" | sed 's/^/    /'
    [ "$S" = "1" ] || ALLOK=0
done
[ "$ALLOK" = "1" ] && ok "Grover recovers all 4 marked states exactly (⟨Z̄⟩=±1, success=1)" \
                    || bad "Grover failed to recover some marked state"

say "\n2) Encoded Grover — backend cross-check (Pauli-prop == statevector):"
PP="$("$QBIN" logical grover --marked 2 --backend pauliprop 2>/dev/null)"; PPZ="$(val "$PP" zbar1)"
SV="$("$QBIN" logical grover --marked 2 --backend statevector 2>/dev/null)"; SVZ="$(val "$SV" zbar1)"
awk -v a="$PPZ" -v b="$SVZ" 'BEGIN{exit !((a-b<1e-6)&&(b-a<1e-6))}' \
    && ok "⟨Z̄_1⟩ agrees: pauliprop=$PPZ statevector=$SVZ" || bad "backend mismatch $PPZ vs $SVZ"

say "\n2b) Same logical Grover on the triangular 6.6.6 COLOR code, d=3/5/7:"
note "    The colour code has a transversal FULL Clifford group (incl. S), which"
note "    the surface code does not — that is the architectural payoff, and it"
note "    needs d>3 to be real (Steane IS the d=3 colour code). Encoded Grover is"
note "    pure Clifford, so Pauli-propagation is exact at 74 physical qubits."
CC_OK=1
for d in 3 5 7; do
    OUT="$("$QBIN" logical grover --code color --distance $d --marked 2 2>/dev/null)"
    if [ -z "$OUT" ]; then
        note "  (skip) this dist's quantum has no --code color"
        CC_OK=skip
        break
    fi
    echo "$OUT" | sed 's/^/    /'
    NQ="$(echo "$OUT" | grep -oE 'data_qubits=[0-9]+' | cut -d= -f2)"
    [ "$(val "$OUT" success)" = "1" ] || CC_OK=0
    # Physical width must actually grow with d: 2 patches x (3d^2+1)/4.
    WANT=$(( 2 * (3 * d * d + 1) / 4 ))
    [ "$NQ" = "$WANT" ] || { bad "d=$d used $NQ data qubits, expected $WANT"; CC_OK=0; }
done
if [ "$CC_OK" = "1" ]; then
    ok "Colour-code Grover exact at d=3/5/7 (14/38/74 physical qubits, ⟨Z̄⟩=±1)"
elif [ "$CC_OK" = "0" ]; then
    bad "colour-code logical Grover failed"
fi

say "\n2c) Encoded Grover across EVERY exact backend (sv / MPS / Pauli-prop / stabilizer):"
note "    Four structurally unrelated engines — dense amplitudes, a tensor train,"
note "    a Heisenberg Pauli tree, and a Clifford tableau. Agreement between two"
note "    could be a shared convention; between four it is evidence."
note "    ('stabilizer' was excluded until 2026-08-05: it reported <Z̄_0> = 0 where"
note "     the others reported ±1. That was an upstream defect in omega's"
note "     PauliBackend — a greedy non-pivoting reduction plus an inverted phase"
note "     table — now fixed, so it is back in the cross-check.)"
MB_OK=1
for be in statevector mps pauliprop stabilizer; do
    OUT="$("$QBIN" logical grover --code color --distance 3 --marked 2 --backend $be 2>/dev/null)"
    Z0="$(val "$OUT" zbar0)"; Z1="$(val "$OUT" zbar1)"; S="$(val "$OUT" success)"
    have "$Z0" "$Z1" "$S" || { bad "$be output missing zbar0/zbar1/success"; MB_OK=0; }
    printf '    %-12s zbar0 %s  zbar1 %s  success %s\n' "$be" "$Z0" "$Z1" "$S"
    [ "$S" = "1" ] || MB_OK=0
    # marked=2 -> logical |10>: <Z0> = +1, <Z1> = -1. Pin the VALUES, not just
    # the success flag, so a backend that agrees on the flag but not the number
    # cannot slip through.
    awk -v a="$Z0" 'BEGIN{exit !(a>0.999999)}' || MB_OK=0
    awk -v a="$Z1" 'BEGIN{exit !(a<-0.999999)}' || MB_OK=0
done
[ "$MB_OK" = "1" ] && ok "4 exact backends agree on the encoded Grover (⟨Z̄⟩ = +1/−1 to 1e-6)" \
                   || bad "backends disagree on the encoded Grover"

say "\n3) Logical QFT (n=4): QFT|input⟩ is uniform, QFT∘QFT⁻¹ = identity:"
OUT="$("$QBIN" logical qft --n 4 --input 5 2>/dev/null)"; echo "$OUT" | sed 's/^/    /'
MD="$(val "$OUT" qft_uniform_maxdev)"; RT="$(val "$OUT" roundtrip_recovered)"
le "$MD" "1e-9" && ok "QFT of a basis state is uniform (max deviation $MD ≤ 1e-9)" || bad "QFT not uniform ($MD)"
awk -v r="$RT" 'BEGIN{exit !(r>0.999999)}' && ok "QFT∘QFT⁻¹ recovers the input (prob $RT)" || bad "roundtrip $RT"

say "\n4) Logical QPE: φ = k/2^m recovered exactly (clean delta):"
QOK=1
for spec in "3 0.25" "3 0.75" "4 0.625"; do
    set -- $spec; M=$1; PH=$2
    OUT="$("$QBIN" logical qpe --counting $M --phase $PH 2>/dev/null)"
    echo "$OUT" | sed 's/^/    /'
    ERR="$(val "$OUT" phase_error)"; PK="$(val "$OUT" peak_prob)"
    le "$ERR" "1e-6" && awk -v p="$PK" 'BEGIN{exit !(p>0.999)}' || QOK=0
done
[ "$QOK" = "1" ] && ok "QPE phase_error ≤ 1e-6 and peak_prob > 0.999 for all cases" \
                 || bad "QPE failed an exact-phase case"

say "\n4b) The [[15,1,3]] Reed–Muller code: TRANSVERSAL T + derived distillation:"
note "    This is the code a stack switches into for a transversal T — the one"
note "    non-Clifford gate no 2D topological code gives you. Checked exactly on"
note "    the 2^15 statevector, and the 35 in p_out ≈ 35p³ is COUNTED from the"
note "    code (weight-3 undetected logical Z errors), not quoted."
MAGIC="$("$QBIN" logical magic --p 1e-3 2>/dev/null)"
if [ -z "$MAGIC" ]; then
    note "  (skip) this dist's quantum has no 'logical magic'"
else
    echo "$MAGIC" | sed 's/^/    /'
    MOK=1
    # |0>_L is 16 simplex codewords of weight 0 or 8 — that is *why* T^15 fixes it.
    echo "$MAGIC" | grep -q "logical_zero_codewords 16 weights \[0, 8\]" || MOK=0
    # Transversal T: |0>_L fixed, |1>_L picks up exactly -pi/4  =>  logical T†.
    P0="$(val "$MAGIC" phase0)"; P1="$(val "$MAGIC" phase1)"
    N0="$(val "$MAGIC" norm0)";  N1="$(val "$MAGIC" norm1)"
    have "$P0" "$P1" "$N0" "$N1" || { bad "magic output missing transversal_t fields"; MOK=0; }
    awk -v a="$P0" 'BEGIN{exit !(a<1e-6 && a>-1e-6)}' || MOK=0
    awk -v a="$P1" 'BEGIN{exit !(a<-0.785397 && a>-0.785399)}' || MOK=0
    awk -v a="$N0" -v b="$N1" 'BEGIN{exit !(a>0.999999 && b>0.999999)}' || MOK=0
    echo "$MAGIC" | grep -q "gate Tdg" || MOK=0
    # The distillation law, derived: exponent 3, coefficient 35, and the p^4
    # term EMPTY (so the next correction is p^5, not p^4).
    echo "$MAGIC" | grep -q "derived_exponent 3 derived_coeff 35 weight4_logical 0" || MOK=0
    # p_out = 35 * (1e-3)^3 = 3.5e-8, and it must beat p_in.
    echo "$MAGIC" | grep -q "p_out 3.500000e-8" || MOK=0
    # RUNNING the protocol (2e6 rounds at p=0.05) must match the EXACT
    # weight-enumerator theory, not the leading cubic term — the cubic law is
    # the p->0 limit and understates by ~17% at p=0.05, which the three numbers
    # below make visible rather than hiding behind a loose tolerance.
    MCA="$(val "$MAGIC" mc_accept)"; EXA="$(val "$MAGIC" exact_accept)"
    MCO="$(val "$MAGIC" mc_p_out)";  EXO="$(val "$MAGIC" exact_p_out)"
    CUB="$(val "$MAGIC" cubic_p_out)"
    have "$MCA" "$EXA" "$MCO" "$EXO" "$CUB" || { bad "magic output missing mc_/exact_ fields"; MOK=0; }
    awk -v a="$MCA" -v b="$EXA" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<0.002)}' || MOK=0
    awk -v a="$MCO" -v b="$EXO" 'BEGIN{d=(a-b)/b; if(d<0)d=-d; exit !(d<0.05)}' || MOK=0
    # And the cubic law really is the optimistic one.
    awk -v c="$CUB" -v e="$EXO" 'BEGIN{exit !(c < e)}' || MOK=0
    [ "$MOK" = "1" ] && ok "T^⊗15 = logical T† (phase −π/4 exactly); 35p³ derived from the code" \
                     || bad "[[15,1,3]] transversal-T / distillation numbers moved"
fi

say "\n4c) QSP on an ENCODED qubit — the polynomial survives encoding:"
note "    Quantum Signal Processing alternates a signal rotation W(x) with phase"
note "    rotations S(φ). With zero phases the sequence is W^d, whose top-left"
note "    entry is exactly T_d(x) — so ⟨Z̄⟩ must equal 2·T_d(x)²−1, with the"
note "    Chebyshev recurrence as an INDEPENDENT oracle. x values are interior"
note "    points, not the extremal cos(kπ/d) where T_d = ±1 and the check is free."
QOK=1
for x in 0.3 0.7 0.9 -0.35; do
    OUT="$("$QBIN" logical qsp --degree 3 --x $x --backend statevector 2>/dev/null)"
    if [ -z "$OUT" ]; then note "  (skip) this dist's quantum has no 'logical qsp'"; QOK=skip; break; fi
    echo "$OUT" | tail -1 | sed 's/^/    /'
    Z="$(val "$OUT" zbar)"; C="$(val "$OUT" classical)"; CH="$(val "$OUT" cheb_2t2m1)"
    have "$Z" "$C" "$CH" || { bad "qsp output missing zbar/classical/cheb fields"; QOK=0; }
    awk -v a="$Z" -v b="$C" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<1e-9)}' || QOK=0
    awk -v a="$Z" -v b="$CH" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d<1e-9)}' || QOK=0
    # Non-degenerate: |<Z>| must be strictly inside (-1,1), or the encoded run
    # agreed with the oracle on a value the circuit could hit by accident.
    awk -v a="$Z" 'BEGIN{if(a<0)a=-a; exit !(a<0.999)}' || QOK=0
done
if [ "$QOK" = "1" ]; then
    ok "encoded QSP == classical == 2·T₃(x)²−1 to 1e-9 at 4 interior x"
elif [ "$QOK" = "0" ]; then
    bad "encoded QSP disagrees with the Chebyshev golden"
fi

say "\n5) Surface-code memory: distance suppresses logical error (neutral-atom noise):"
R3="$(val "$("$QBIN" logical memory --distance 3 --noise neutral-atom --p 0.06 --shots 40000 2>/dev/null)" logical_rate)"
M5="$("$QBIN" logical memory --distance 5 --noise neutral-atom --p 0.06 --shots 40000 2>/dev/null)"
R5="$(val "$M5" logical_rate)"
echo "    d=3 logical_rate $R3   d=5 logical_rate $R5"
lt "$R5" "$R3" && ok "d=5 ($R5) suppresses below d=3 ($R3) — below threshold" || bad "no suppression"

say "\n5b) COLOUR-code memory also suppresses with distance (BP+OSD decoder):"
note "    MWPM does not apply to colour codes, so this decodes with BP+OSD."
note "    Until now only the SURFACE family had distance-suppression evidence."
CM_OK=1; CM_PREV=""
for d in 3 5 7; do
    OUT="$("$QBIN" logical memory --code color --distance $d --noise depolarizing --p 0.02 --shots 4000 --seed 99 2>/dev/null)"
    if [ -z "$OUT" ]; then note "  (skip) this dist's quantum has no --code color memory"; CM_OK=skip; break; fi
    R="$(val "$OUT" logical_rate)"
    have "$R" || { bad "colour memory output missing logical_rate"; CM_OK=0; break; }
    printf '    d=%s logical_rate %s\n' "$d" "$R"
    if [ -n "$CM_PREV" ]; then
        lt "$R" "$CM_PREV" || CM_OK=0
    else
        awk -v a="$R" 'BEGIN{exit !(a>0.005)}' || CM_OK=0
    fi
    CM_PREV="$R"
done
if [ "$CM_OK" = "1" ]; then
    ok "colour-code pL falls with distance (0.0140 → 0.0028 → 0.0008)"
elif [ "$CM_OK" = "0" ]; then
    bad "colour-code memory did not suppress with distance"
fi

say "\n5c) THE THROUGH-LINE: hardware noise → residual logical error → precision:"
note "    One command for the whole chain, with the encoded and unencoded answers"
note "    side by side at the SAME physical rate. Both rates are READOUT-relevant:"
note "    a logical Z failure does not flip a Z-basis measurement, and under the"
note "    neutral-atom preset the Z sector is dominant by design — so p_logical is"
note "    the X-sector rate and the bare baseline is p_bit, not p_bit+p_phase."
note "    Encoding wins exactly when p_logical < p_physical, so the last row"
note "    checks the crossover rather than assuming it."
PR_OK=1
for d in 3 5 7; do
    OUT="$("$QBIN" logical precision --distance $d --p 0.02 --algo grover 2>/dev/null)"
    if [ -z "$OUT" ]; then note "  (skip) this dist's quantum has no 'logical precision'"; PR_OK=skip; break; fi
    PL="$(val "$OUT" p_logical)"; EE="$(val "$OUT" error_encoded)"
    EU="$(val "$OUT" error_unencoded)"; PP="$(val "$OUT" p_physical)"
    have "$PL" "$EE" "$EU" "$PP" || { bad "precision output missing fields"; PR_OK=0; break; }
    printf '    d=%s  p_phys %s → p_logical %s → err encoded %s vs unencoded %s\n' \
        "$d" "$PP" "$PL" "$EE" "$EU"
    # Below threshold the residual must beat the physical rate, and the encoded
    # answer must beat the unencoded one.
    lt "$PL" "$PP" || PR_OK=0
    lt "$EE" "$EU" || PR_OK=0
done
# d=3 must show a NON-ZERO encoded error, or "encoding helped" is a comparison
# against a shot-floor zero. (d=7 legitimately reads 0.000000 at 4000 shots —
# that is the Monte-Carlo resolution, not an exact claim.)
D3="$("$QBIN" logical precision --distance 3 --p 0.02 --algo grover 2>/dev/null)"
awk -v a="$(val "$D3" error_encoded)" 'BEGIN{exit !(a>0.001)}' || PR_OK=0
# THE FALSIFIER: above threshold encoding must STOP helping.
HI="$("$QBIN" logical precision --distance 3 --p 0.30 --algo grover 2>/dev/null)"
if [ -n "$HI" ]; then
    printf '    above threshold (p=0.30): %s\n' "$(echo "$HI" | tail -1)"
    echo "$HI" | grep -q "encoding_helped 0" || PR_OK=0
fi
if [ "$PR_OK" = "1" ]; then
    ok "noise→residual→precision: encoding helps below threshold, stops above it"
elif [ "$PR_OK" = "0" ]; then
    bad "the noise→precision through-line did not behave"
fi

say "\n5d) The same chain with PER-GADGET circuit noise (--method circuit):"
note "    5c applies the residual logical rate ONCE, at readout. Every algorithm"
note "    there has a delta ideal, so its metric collapses to 1-(1-b)^n and qft"
note "    and qpe of equal width return the SAME number — that path restates the"
note "    memory rate and nothing more. Here the noise is applied at every"
note "    logical gadget and PROPAGATES through the rest of the circuit (a fault"
note "    before a CX flips two readout bits; one before an Rz(θ) conjugates to"
note "    Rz(-θ)), so depth and connectivity move the answer. The check is that"
note "    qft and qpe, both width 3, now DISAGREE — and that the crossover still"
note "    goes both ways."
PCQ="$("$QBIN" logical precision --method circuit --algo qft --distance 3 \
        --p 0.02 --shots 400 --seed 99 2>/dev/null)"
PCP="$("$QBIN" logical precision --method circuit --algo qpe --distance 3 \
        --p 0.02 --shots 400 --seed 99 2>/dev/null)"
if [ -z "$PCQ" ] || [ -z "$PCP" ]; then
    note "  (skip) this dist's quantum has no 'logical precision --method circuit'"
else
    PC_OK=1
    QEE="$(val "$PCQ" error_encoded)"; QEU="$(val "$PCQ" error_unencoded)"
    QCF="$(val "$PCQ" clean_frac_encoded)"; QEX="$(val "$PCQ" exposures)"
    PEE="$(val "$PCP" error_encoded)"; PEU="$(val "$PCP" error_unencoded)"
    PCF="$(val "$PCP" clean_frac_encoded)"; PEX="$(val "$PCP" exposures)"
    have "$QEE" "$QEU" "$QCF" "$QEX" "$PEE" "$PEU" "$PCF" "$PEX" \
        || { bad "circuit-precision output missing fields"; PC_OK=0; }
    if [ "$PC_OK" = "1" ]; then
        printf '    qft  exposures %s  encoded %s vs unencoded %s (clean %s)\n' \
            "$QEX" "$QEE" "$QEU" "$QCF"
        printf '    qpe  exposures %s  encoded %s vs unencoded %s (clean %s)\n' \
            "$PEX" "$PEE" "$PEU" "$PCF"
        # Encoding wins, the run resolved something (encoded error is not a
        # shot-floor zero and not every shot was fault-free), and the two
        # algorithms disagree — which the readout-flip path cannot produce.
        lt "$QEE" "$QEU" || PC_OK=0
        lt "$PEE" "$PEU" || PC_OK=0
        awk -v a="$QEE" -v b="$PEE" 'BEGIN{exit !(a>0.01 && b>0.01)}' || PC_OK=0
        lt "$QCF" "1" || PC_OK=0
        lt "$PCF" "1" || PC_OK=0
        awk -v a="$QEE" -v b="$PEE" 'BEGIN{d=a-b; if(d<0)d=-d; exit !(d>0.01)}' || PC_OK=0
    fi
    if [ "$PC_OK" = "1" ]; then
        ok "circuit-level precision: qft ≠ qpe at equal width, encoding wins below threshold"
    else
        bad "circuit-level precision did not behave below threshold"
    fi
    # THE FALSIFIER, at the one p where it is testable: at 0.15 the per-round
    # rates have genuinely crossed (pL 0.083-0.087 across seeds/shots vs p_bit
    # 0.075) AND the bare run is still under this metric's own 0.75 ceiling.
    # Stable there: encoding_helped reads 0 for 20/20 seeds. At 0.10 the rates
    # have NOT crossed (0.0465 vs 0.05) even though the verdict already reads 0
    # — the metric saturates first, so a pass would not be about the crossover.
    # At 0.25 both sides sit on the ceiling and the verdict flips with the seed.
    PCH="$("$QBIN" logical precision --method circuit --algo grover --distance 3 \
            --p 0.15 --shots 2000 --seed 99 2>/dev/null)"
    HEU="$(val "$PCH" error_unencoded)"
    printf '    above the crossover (p=0.15): %s\n' "$(echo "$PCH" | tail -1)"
    if have "$HEU" && echo "$PCH" | grep -q "encoding_helped 0" && lt "$HEU" "0.72"; then
        ok "circuit-level falsifier: encoding stops helping at p=0.15, unsaturated"
    else
        bad "circuit-level crossover did not reverse (or both sides saturated)"
    fi
fi

say "\n6) Extracted effective logical channel is ZZ-biased (neutral-atom):"
echo "$M5" | sed 's/^/    /'
PLX="$(val "$M5" p_lx)"; PLZ="$(val "$M5" p_lz)"
lt "$PLX" "$PLZ" && ok "logical phase error dominates: p_lz ($PLZ) > p_lx ($PLX)" || bad "channel not phase-biased"

finish
