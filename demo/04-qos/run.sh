#!/usr/bin/env bash
# Demo 04 — Quantum Oracle Sketching through the stripped CLI (no libtorch).
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"

say "== Demo 04: Quantum Oracle Sketching (Babbush et al. 2026, emulated) =="
note "dist: $QUANTUM_DIST_ROOT — runs in the libtorch-free 'quantum' binary."

say "\nBuild a query oracle from random samples; the infidelity to the exact"
say "oracle obeys the O(1/N^2) sample-complexity law (ratio ~4 per doubling)."
OUT="$("$QBIN" qos)"; echo "$OUT" | sed 's/^/    /'

echo "$OUT" | grep -q "^n_qubits 10$"            && ok "10 index qubits for a 1024-dim oracle (polylog)" || bad "n_qubits"
echo "$OUT" | grep -q "^error_ratio_2x 3.9999$"  && ok "O(1/N^2) law: infidelity falls ~4x per doubling" || bad "sample-complexity law"
echo "$OUT" | grep -q "^block_encoding_err 0.00e0$" && ok "Halmos block-encoding round-trips exactly" || bad "block-encoding"

note "\nTry: $QBIN qos --dim 4096   (12 index qubits)"
finish
