#!/usr/bin/env bash
# Demo 05 — GHZ + a real optimizer reduction, via the binary-only dist.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 05: GHZ — the optimizer removes redundant gates =="
note "dist: $QUANTUM_DIST_ROOT"

say "\n1) The clean model (Aria):"
sed -n '/^circuit GHZ/,/^}/p' "$HERE/ghz.aria" | sed 's/^/    /'

say "\n2) A naively-written GHZ with redundant gates (ghz_naive.qasm):"
grep -vE '^(OPENQASM|include|qreg|creg|measure)' "$HERE/ghz_naive.qasm" | sed 's/^/    /'

gc() { "$QBIN" info "$1" 2>/dev/null | awk '/Gate count:/ {print $3}'; }
BEFORE=$(gc "$HERE/ghz_naive.qasm")
say "\n3) Gate count before optimization: $BEFORE"
[ "$BEFORE" = 7 ] && ok "naive circuit has 7 gates" || bad "expected 7, got $BEFORE"

OPT="$(mktemp -u /tmp/ghz-opt-XXXX.qasm)"
"$QBIN" optimize "$HERE/ghz_naive.qasm" --output "$OPT" >/dev/null 2>&1
AFTER=$(gc "$OPT")
say "4) After  optimization (quantum optimize): $AFTER"
"$QBIN" compile "$OPT" --format qasm 2>/dev/null | grep -vE '^(OPENQASM|include|qreg|creg|$)' | sed 's/^/    /'
[ "$AFTER" = 3 ] && ok "optimized to the minimal GHZ (3 gates: H, CX, CX)" || bad "expected 3, got $AFTER"
[ "$AFTER" -lt "$BEFORE" ] 2>/dev/null && ok "adjacent X·X and H·H pairs cancelled ($BEFORE → $AFTER)" || bad "no reduction"
rm -f "$OPT"

say "\n5) Formal proof of the clean model (Aria → Lean 4):"
OUT="$(mktemp -d)"
"$QBIN" spec extract --aria "$HERE/ghz.aria" --instantiate "GHZ()" --out "$OUT" >/dev/null 2>&1
ls "$OUT"/*.lean >/dev/null 2>&1 && ok "GHZ → Lean 4 theorem emitted" || note "    (Lean export optional here)"
rm -rf "$OUT"

finish
