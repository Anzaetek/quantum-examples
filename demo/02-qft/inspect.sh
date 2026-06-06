#!/usr/bin/env bash
# Demo 02 — parameterized QFT. A single Aria model instantiated at several sizes
# and exported to Lean 4, all through the binary-only dist.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 02: QFT — a parameterized quantum model, proven at each size =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The model (one Aria circuit, parameter n):"
sed -n '/^circuit QFT/,/^}/p' "$HERE/qft.aria" | sed 's/^/    /'

say "\n2) Instantiate + export to Lean 4 at several sizes:"
for n in 3 4 5; do
    OUT="$(mktemp -d)"
    "$QBIN" spec extract --aria "$HERE/qft.aria" --instantiate "QFT(n=$n)" --out "$OUT" >/dev/null 2>&1
    if ls "$OUT"/*.lean >/dev/null 2>&1; then
        LINES=$(cat "$OUT"/*.lean | wc -l | tr -d ' ')
        ok "QFT(n=$n) → Lean 4 theorem ($LINES lines)"
    else bad "QFT(n=$n) Lean export"; fi
    rm -rf "$OUT"
done

note "\nThe same model scales from 3 to 5+ qubits with one parameter, and each"
note "instantiation carries the proof obligation  denote(QFT) = DFT_matrix(2^n)."
finish
