#!/usr/bin/env bash
# Demo 09 — Measurement-Based Quantum Computing (MBQC). A gate circuit is
# compiled to a one-way measurement pattern, optimized, and simulated — all
# through the binary-only dist.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 09: MBQC — compile a circuit to a measurement pattern =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The MBQC model (Aria — explicit graph state + measurement order):"
sed -n '1,12p' "$HERE/mbqc_bell.aria" | sed 's/^/    /'

say "\n2) Compile the circuit to an MBQC pattern (quantum mbqc):"
OUT="$("$QBIN" mbqc "$HERE/bell.qasm" 2>/dev/null)"; echo "$OUT" | sed 's/^/    /'
echo "$OUT" | grep -q "vertices=5 edges=4"     && ok "pattern = 5 vertices, 4 edges, 3 measurements" || bad "pattern shape"
echo "$OUT" | grep -q "optimized vertices=3"   && ok "Clifford optimization: 5 → 3 vertices" || bad "optimization"
echo "$OUT" | grep -q "^MBQC imported: output_norm=1.000000$" && ok "pattern simulation is unitary (output_norm=1)" || bad "output_norm"
echo "$OUT" | grep -q "ubqc_on_lattice=3/3"    && ok "pattern runs on a brickwork lattice (3/3)" || bad "lattice"

note "\nMBQC computes by measuring a fixed entangled resource state in a chosen"
note "order — the basis for the blind protocol in demo 10."
finish
