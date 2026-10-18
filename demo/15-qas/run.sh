#!/usr/bin/env bash
# Demo 15 — QAS: quantum circuit-ARCHITECTURE search (TPE over encoding ×
# ansatz × readout × width × depth), scored by walk-forward macro-F1 on
# SYNTHETIC regime labels. Everything runs through bin/quantum-finance.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
require_libtorch

say "== Demo 15: QAS — quantum circuit-architecture search (bin/quantum-finance arch-search) =="
note "dist: $QUANTUM_DIST_ROOT"
note "data: $SYNTH  — SYNTHETIC (rescaled + noised), NOT real market data (see data/README.md)"

say "\n1) Labels: HMM volatility regimes of the synthetic series (regime-gen):"
LAB="$(mktemp /tmp/demo15-lab-XXXXXX.csv)"
REG="$("$QF" regime-gen "$SYNTH" "$LAB" 2>/dev/null)"; echo "$REG" | grep -E "^(n_rows|regime[012]_frac) " | sed 's/^/    /'
echo "$REG" | grep -q "^n_rows 5438$" && ok "5438 labelled feature rows" || bad "n_rows"

say "\n2) The search space (what TPE picks from — every point is a different circuit):"
note "    encoding  AngleY | Amplitude | HadamardInit | LinearAngle | UnaryRy (Kerenidis unary loader)"
note "    ansatz    StronglyEntangling | RotCnot | LowEntangleZ | RichZZ | Qcnn | BareRot | QcnnNeck | BasicEntangler | Rbs"
note "    readout   ZAll | ZFirst | ZFirstLast | ZPlusZZ | Probs     width n, layers l"
note "    objective macro-F1 on an expanding walk-forward split; 6 trials × 6 QNN steps (~20 s)"

say "\n3) Search (arch-search finetune --model qnn):"
QAS_ARGS=(arch-search finetune --model qnn --n-trials 6 --walk-folds 2 --qnn-steps 6 --max-rows 200 --data "$LAB")
AS="$("$QF" "${QAS_ARGS[@]}" 2>/dev/null)"
echo "$AS" | grep -E "^(n_rows|n_trials|best_arch|best_arch_params|best_macro_f1|baseline_macro_f1|selected) " | sed 's/^/    /'
echo "$AS" | grep -q "^n_rows 195$" && ok "195 rows after the time-ordered stride subsample (--max-rows 200)" || bad "n_rows"
echo "$AS" | grep -qE '^best_arch [A-Za-z]+.*\|[A-Za-z]+.*\|[A-Za-z]+\|n[0-9]+\|l[0-9]+$' \
    && ok "best_arch is a full point of the space: encoding|ansatz|readout|n|l" || bad "best_arch shape"
echo "$AS" | grep -q "^baseline_macro_f1 0.2007$" && ok "majority-class baseline macro-F1 = 0.2007 (deterministic from the labels)" || bad "baseline"
BEST="$(echo "$AS" | sed -n 's/^best_macro_f1 //p')"
awk "BEGIN{exit !(${BEST:-0} >= 0.70)}" && ok "best architecture macro-F1 = $BEST ≥ 0.70 (3.5× the baseline)" || bad "best_macro_f1 below floor ($BEST)"
echo "$AS" | grep -q "^selected 1$" && ok "selected 1 — the search beat the majority-class baseline" || bad "selected"

say "\n4) Determinism — the same search again must choose the same circuit:"
AS2="$("$QF" "${QAS_ARGS[@]}" 2>/dev/null)"
A1="$(echo "$AS"  | grep -E '^(best_arch|best_macro_f1) ')"
A2="$(echo "$AS2" | grep -E '^(best_arch|best_macro_f1) ')"
[ -n "$A1" ] && [ "$A1" = "$A2" ] && ok "second run: identical best_arch and best_macro_f1" || bad "search is not deterministic"
rm -f "$LAB"

note "\nQAS treats the circuit itself — how data is loaded, which entangler, what is"
note "read out, how wide, how deep — as the hyperparameter. The TPE sampler is the"
note "toolkit's own (no Optuna), the objective is walk-forward macro-F1, and the"
note "winning circuit is a real QNN you could train further (demo 08)."
finish
