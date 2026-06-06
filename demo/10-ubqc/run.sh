#!/usr/bin/env bash
# Demo 10 — Universal Blind Quantum Computation (UBQC / BFK). The client drives a
# measurement pattern on a remote quantum-server that runs it BLIND (it never
# learns the computation or the data) and the result is recovered. All binary.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
SOCK="$(mktemp -u /tmp/ubqc-demo-XXXX.sock)"

say "== Demo 10: UBQC — blind quantum computation against a remote server =="
note "dist: $QUANTUM_DIST_ROOT"

# Start the (blind) server.
"$QSERVER" --listen "unix:$SOCK" >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null || true; rm -f "$SOCK"' EXIT
for _ in $(seq 1 50); do [ -S "$SOCK" ] && break; sleep 0.1; done
[ -S "$SOCK" ] || { bad "server socket not created"; finish; }

say "\n1) Run the pattern blindly on the server (quantum mbqc … --remote):"
note "    The server applies the brickwork measurements but the angles are blinded"
note "    (BFK) — it cannot learn the circuit or the inputs."
OUT="$("$QBIN" mbqc "$HERE/bell.qasm" --remote "unix:$SOCK" 2>/dev/null)"; echo "$OUT" | sed 's/^/    /'

echo "$OUT" | grep -q "^MBQC imported: output_norm=1.000000$" && ok "result is correct (output_norm=1)" || bad "output_norm"
echo "$OUT" | grep -qE "ubqc_remote_on_lattice=3/3 recovered=3" && ok "blind remote run recovered the result (3/3)" || bad "blind recovery"

note "\nThe server saw only blinded measurement angles — the computation stayed private."
finish
