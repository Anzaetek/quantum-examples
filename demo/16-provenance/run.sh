#!/usr/bin/env bash
# Demo 16 — DATA PROVENANCE: the evaluation build of bin/quantum-finance is
# pinned to the bundled SYNTHETIC series. The pin is embedded in the binary at
# build time; this demo proves it FROM the binary — the way the qubit cap and
# the expiry are proven — by flipping one byte and one label and watching the
# refusals. A source build (MIT) has no pin and runs on any data.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
require_libtorch

say "== Demo 16: data provenance — the eval binary only computes on the series it ships with =="
note "dist: $QUANTUM_DIST_ROOT"
note "data: $SYNTH  — SYNTHETIC (rescaled + noised), NOT real market data (see data/README.md)"

PIN_SHA=d0d2e8eafc2b462f55091366af79dfaa58d23c89d30bba0a8d42d34eea927212

say "\n1) What is pinned (data-pin, no arguments):"
DP="$("$QF" data-pin 2>/dev/null)"; echo "$DP" | sed 's/^/    /'
if echo "$DP" | grep -q "^pinned 0$"; then
    echo "  (skip) this quantum-finance is a source build — no data pin to demonstrate" >&2
    exit 0
fi
echo "$DP" | grep -q "^pin_sha256 $PIN_SHA$" && ok "embedded series sha256 = $PIN_SHA (the committed demo/data file)" || bad "pin_sha256"
echo "$DP" | grep -q "^pin_rows 5462$" && ok "5462 pinned daily bars" || bad "pin_rows"

say "\n2) The shipped series matches the pin:"
"$QF" data-pin --series "$SYNTH" 2>/dev/null | grep -E "^series_" | sed 's/^/    /'
"$QF" data-pin --series "$SYNTH" >/dev/null 2>&1 && ok "data-pin --series: series_match 1 (exit 0)" || bad "shipped series rejected"

say "\n3) Flip ONE byte of a copy — every series entry point refuses it (exit 3):"
TMP="$(mktemp -d /tmp/demo16-XXXXXX)"; trap 'rm -rf "$TMP"' EXIT
cp "$SYNTH" "$TMP/tampered.csv"
# Byte 40 is inside the first data row's Open price; '5' -> '6'.
printf '6' | dd of="$TMP/tampered.csv" bs=1 seek=40 conv=notrunc 2>/dev/null
XO="$("$QF" xauusd "$TMP/tampered.csv" 2>&1)"; rc=$?
echo "$XO" | head -3 | sed 's/^/    /'
[ "$rc" = 3 ] && echo "$XO" | grep -q "data pin" && ok "xauusd on the tampered copy: refused, exit $rc, both digests printed" || bad "xauusd accepted tampered data (rc=$rc)"
{ "$QF" data-pin --series "$TMP/tampered.csv" 2>/dev/null || true; } | grep -q "^series_match 0$" && ok "data-pin --series on the copy: series_match 0" || bad "data-pin missed the flipped byte"
"$QF" regime-gen "$TMP/tampered.csv" >/dev/null 2>&1; [ $? = 3 ] && ok "regime-gen on the copy: refused (exit 3)" || bad "regime-gen accepted tampered data"

say "\n4) Label files: accepted only if THIS binary's regime-gen derives them from the pin:"
"$QF" regime-gen "$SYNTH" "$TMP/labels.csv" >/dev/null 2>&1
"$QF" data-pin --labels "$TMP/labels.csv" 2>/dev/null | grep -E "^labels_" | sed 's/^/    /'
"$QF" data-pin --labels "$TMP/labels.csv" >/dev/null 2>&1 && ok "regime-gen's own label file: labels_match 1 (regenerated and compared byte-for-byte)" || bad "own labels rejected"
# Change one label on data row 100 (field 6, 'regime'): whatever it is, make it different.
awk -F, 'BEGIN{OFS=","} NR==101{$6=($6+1)%3} {print}' "$TMP/labels.csv" > "$TMP/edited.csv"
EO="$("$QF" data-pin --labels "$TMP/edited.csv" 2>/dev/null)"; rc=$?
echo "$EO" | grep -E "^labels_" | sed 's/^/    /'
[ "$rc" = 3 ] && echo "$EO" | grep -q "^labels_first_diff_line 101$" && ok "one edited label: labels_match 0 at line 101, exit 3" || bad "edited label not localised (rc=$rc)"
"$QF" regime-classify train --model gbdt --data "$TMP/edited.csv" >/dev/null 2>&1; [ $? = 3 ] && ok "regime-classify --data on the edited file: refused (exit 3)" || bad "training accepted edited labels"

say "\n5) The pin is exportable and round-trips:"
"$QF" data-pin --export "$TMP/exported.csv" >/dev/null 2>&1
"$QF" data-pin --series "$TMP/exported.csv" 2>/dev/null | grep -q "^series_match 1$" && cmp -s "$TMP/exported.csv" "$SYNTH" && ok "data-pin --export = the shipped file, byte for byte" || bad "export round-trip"

note "\nWhy this matters: the eval bundle's QML/finance numbers are reproducible AND"
note "scoped — nobody can run the eval binary on a private dataset and attribute the"
note "result to the toolkit. Build from source (MIT, QUANTUM_TEST unset) for your own data."
finish
