#!/usr/bin/env bash
# Generate a SYNTHETIC daily OHLCV series for the public demos.
#
# Method (intentionally simple): take a real daily series, (1) RESCALE every
# price to a synthetic index starting at ~100 — so the magnitude reveals nothing
# about the underlying instrument — and (2) add small deterministic per-bar
# multiplicative noise so the path is not the real one. The result is a
# plausible-looking but FAKE instrument ("SYNX"), for demonstration only.
#
# Deterministic (fixed Park–Miller seed, pure-integer arithmetic that stays
# within double precision ⇒ portable awk) so the demo golden numbers are stable.
#
# Usage: ./make-synthetic.sh <real_input.csv> <synthetic_output.csv>
set -euo pipefail
IN="${1:?usage: make-synthetic.sh <input.csv> <output.csv>}"
OUT="${2:?usage: make-synthetic.sh <input.csv> <output.csv>}"

awk -F';' -v OFS=';' -v seed=987654321 -v amp=0.012 '
NR==1 { header=$0; next }
{ rows[++n]=$0; if (n==1) { split($0,f0,";"); first_close=f0[5]; first_vol=f0[7] } }
END {
    print header
    pfactor = 100.0 / first_close          # price index: first close -> ~100
    vfactor = 1000.0 / first_vol           # volume index: first volume -> ~1000
    state = seed % 2147483647; if (state==0) state=1
    for (i=1; i<=n; i++) {
        state = (16807 * state) % 2147483647        # Park–Miller, no overflow
        u = state / 2147483647.0
        g = 1.0 + (u - 0.5) * 2.0 * amp              # per-bar factor in [1-amp,1+amp]
        split(rows[i], f, ";")
        printf "%s", f[1]                            # Date
        for (c=2; c<=6; c++) printf ";%.4f", f[c]*pfactor*g   # O,H,L,C,Adj_Close
        printf ";%.1f\n", f[7]*vfactor*g            # Volume (synthetic index)
    }
}
' "$IN" > "$OUT"

echo "wrote $(wc -l < "$OUT") lines (incl. header) to $OUT"
