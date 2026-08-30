#!/usr/bin/env bash
# Demo 07 — QML: a Quantum Circuit Born Machine. Aria model + real training via
# the bundled quantum-finance binary.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 07: QML — Quantum Circuit Born Machine (QCBM) =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The QML model (Aria — strongly-entangling Born machine):"
sed -n '/^circuit/,/^}/p' "$HERE/qcbm.aria" | sed 's/^/    /'

say "\n2) Lean 4 export of the UNTRAINED model is refused (binary-only):"
# The 24 angles are `symbolic[3*N*L]` until training binds them. Substituting
# 0.0 would state a theorem about the identity circuit, not the model, so the
# exporter refuses by name and writes nothing (ci stage 11f′ tests the same).
OUT="$(mktemp -d)"
ERR="$("$QBIN" spec extract --aria "$HERE/qcbm.aria" --instantiate "QcbmStronglyEntangling(N=4,L=2)" --out "$OUT" 2>&1 >/dev/null)"; RC=$?
if [ "$RC" -ne 0 ] && echo "$ERR" | grep -q "24 parameter(s) have no bound numeric value: theta_0," \
   && ! ls "$OUT"/*.lean >/dev/null 2>&1; then
    ok "untrained QCBM (24 symbolic angles) → export REFUSED by name, no .lean written"
else bad "Lean export gate (rc=$RC)"; fi
rm -rf "$OUT"

say "\n3) Train the QCBM on copula innovations (quantum-finance qcbm):"
require_libtorch
QCBM="$("$QF" qcbm 2>/dev/null)"; echo "$QCBM" | grep -E "^(rho|K|final_kl) " | sed 's/^/    /'
# `final_kl` is `final_loss - target_entropy` = KL(p_target || p_model) against
# the histogram the model was just trained on: a TRAINING loss, so this
# certifies the ansatz can EXPRESS the target, not that it generalises. The
# claim used to read "learns the distribution", which it does not support --
# the trained model reproduces the fitted histogram to 4e-4 and carries no
# information beyond it. It is still a real bar: a depth-1 ansatz leaves
# final_kl 0.309745, well over it (see qcbm.rs residual_kl_is_capacity_sensitive).
echo "$QCBM" | grep -q "^final_kl 0.000000$" && ok "Born machine expresses the target histogram, KL → 0 (expressivity, not generalisation)" || bad "final_kl"

finish
