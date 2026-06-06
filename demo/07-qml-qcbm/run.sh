#!/usr/bin/env bash
# Demo 07 — QML: a Quantum Circuit Born Machine. Aria model + real training via
# the bundled quantum-finance binary.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 07: QML — Quantum Circuit Born Machine (QCBM) =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The QML model (Aria — strongly-entangling Born machine):"
sed -n '/^circuit/,/^}/p' "$HERE/qcbm.aria" | sed 's/^/    /'

say "\n2) Export the QML circuit to a Lean 4 theorem (binary-only):"
OUT="$(mktemp -d)"
"$QBIN" spec extract --aria "$HERE/qcbm.aria" --instantiate "QcbmStronglyEntangling(N=4,L=2)" --out "$OUT" >/dev/null 2>&1
ls "$OUT"/*.lean >/dev/null 2>&1 && ok "QCBM circuit → Lean 4 theorem emitted" || bad "Lean export"
rm -rf "$OUT"

say "\n3) Train the QCBM on copula innovations (quantum-finance qcbm):"
require_libtorch
QCBM="$("$QF" qcbm 2>/dev/null)"; echo "$QCBM" | grep -E "^(rho|K|final_kl) " | sed 's/^/    /'
echo "$QCBM" | grep -q "^final_kl 0.000000$" && ok "Born machine converges, KL → 0 (learns the distribution)" || bad "final_kl"

finish
