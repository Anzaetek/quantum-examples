#!/usr/bin/env bash
# Starts the shipped quantum-server, builds + runs the Rust harness against it,
# then cleans up. Self-contained.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
SOCK="$(mktemp -u /tmp/quantum-demo-XXXX.sock)"

say "== Demo 03: standalone Rust harness ⇄ shipped quantum-server =="
note "dist server: $QSERVER"

"$QSERVER" --listen "unix:$SOCK" >/dev/null 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null || true; rm -f "$SOCK"' EXIT
for _ in $(seq 1 50); do [ -S "$SOCK" ] && break; sleep 0.1; done
[ -S "$SOCK" ] || { bad "server socket not created"; finish; }

QUANTUM_SOCKET="$SOCK" cargo run --quiet --manifest-path "$HERE/Cargo.toml"
RC=$?
[ "$RC" = 0 ] && ok "Rust harness verified the shipped server" || bad "harness exit $RC"
finish
