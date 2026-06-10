#!/usr/bin/env bash
# Demo 08 — QML: a quantum neural-network classifier. Aria model + QNN training
# on SYNTHETIC data (HMM regime labels of the synthetic series).
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 08: QML — quantum neural-network regime classifier =="
note "dist: $QUANTUM_DIST_ROOT  ·  data: SYNTHETIC ($SYNTH)"

say "\n1) The QML model (Aria — angle-encoded variational classifier):"
sed -n '/^circuit/,/^}/p' "$HERE/classifier.aria" | sed 's/^/    /'

say "\n2) Export the QML circuit to Lean 4 (binary-only):"
OUT="$(mktemp -d)"
"$QBIN" spec extract --aria "$HERE/classifier.aria" --instantiate "QMLClassifier(L=3)" --out "$OUT" >/dev/null 2>&1
ls "$OUT"/*.lean >/dev/null 2>&1 && ok "classifier circuit → Lean 4 theorem emitted" || bad "Lean export"
rm -rf "$OUT"

say "\n3) Label the synthetic series (HMM) then train a QNN classifier on it:"
require_libtorch
note "    regime-gen → labels;  regime-classify --model qnn (parameter-shift, ~20s)"
LAB="$(mktemp /tmp/demo08-lab-XXXXXX.csv)"
"$QF" regime-gen "$SYNTH" "$LAB" >/dev/null 2>&1
CLF="$("$QF" regime-classify train --model qnn --data "$LAB" 2>/dev/null)"
echo "$CLF" | grep -E "^(n_train|val_acc|test_macro_f1) " | sed 's/^/    /'
VAL=$(echo "$CLF" | sed -n 's/^val_acc //p')
if echo "$CLF" | grep -q "^n_train 3806 n_val 544 n_test 1088$" && awk "BEGIN{exit !(${VAL:-0} >= 0.70)}"; then
    ok "QNN classifier trains on synthetic labels, val_acc=$VAL ≥ 0.70"
else bad "QNN classifier below floor (val=$VAL)"; fi

# 4) GPU bundle proof: on a CUDA host, a gpu-variant quantum-finance resolves
# `--device cuda` to Cuda(0) and trains the DNN head there. The cpu bundle
# falls back to CPU and this step skips (never fails); non-NVIDIA hosts skip.
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi -L >/dev/null 2>&1; then
    say "\n4) GPU (CUDA) training — the same labels through the DNN head on Cuda(0):"
    DNN="$("$QF" regime-classify train --model dnn --device cuda --data "$LAB" 2>/dev/null)"
    if echo "$DNN" | grep -q "^device Cuda(0)$"; then
        echo "$DNN" | grep -E "^(device|val_acc) " | sed 's/^/    /'
        DVAL=$(echo "$DNN" | sed -n 's/^val_acc //p')
        if awk "BEGIN{exit !(${DVAL:-0} >= 0.70)}"; then
            ok "DNN regime classifier trains on Cuda(0), val_acc=$DVAL ≥ 0.70"
        else bad "GPU DNN below floor (val=$DVAL)"; fi
    else
        note "    (skip) binary reports CPU — GPU training needs the gpu bundle (+ cu128 libtorch)"
    fi
fi
rm -f "$LAB"

finish
