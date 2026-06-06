#!/usr/bin/env bash
# Demo 01 — Bell. Shows how to CHECK the quantum circuit used, against the
# binary-only dist (bin/quantum), and export the Aria model to a Lean 4 proof.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 01: Bell — inspect the circuit via the binary-only dist =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The model (Aria DSL — human-readable):"
sed 's/^/    /' "$HERE/bell.aria"

say "\n2) Circuit statistics  (quantum info):"
INFO="$("$QBIN" info "$HERE/bell.qasm")"; echo "$INFO" | sed 's/^/    /'
echo "$INFO" | grep -q "Qubits:          2" && ok "2 qubits" || bad "qubit count"
echo "$INFO" | grep -q "H-count:         1" && ok "1 Hadamard" || bad "H-count"
echo "$INFO" | grep -q "Gate count:      2" && ok "2 gates (H, CX)" || bad "gate count"

say "\n3) The exact gate sequence  (quantum compile --format qasm):"
"$QBIN" compile "$HERE/bell.qasm" --format qasm 2>/dev/null | sed 's/^/    /'

say "\n4) Machine-checkable gate list  (quantum compile --format json):"
JSON="$("$QBIN" compile "$HERE/bell.qasm" --format json 2>/dev/null)"
echo "$JSON" | grep -E '"kind"' | sed 's/^/    /'
echo "$JSON" | grep -q '"kind": "H"'  && ok "H gate present in JSON" || bad "H in json"
echo "$JSON" | grep -q '"kind": "CX"' && ok "CX gate present in JSON" || bad "CX in json"

say "\n5) Formal proof  (Aria → Lean 4 theorem):"
OUT="$(mktemp -d)"
"$QBIN" spec extract --aria "$HERE/bell.aria" --instantiate "Bell()" --out "$OUT" >/dev/null 2>&1
if ls "$OUT"/*.lean >/dev/null 2>&1; then
    note "    generated: $(ls "$OUT"/*.lean | xargs -n1 basename | tr '\n' ' ')"
    ok "Bell → Lean 4 theorem emitted"
else bad "Lean export"; fi
rm -rf "$OUT"

finish
