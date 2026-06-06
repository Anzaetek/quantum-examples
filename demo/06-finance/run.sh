#!/usr/bin/env bash
# Demo 06 — finance/trading on a SYNTHETIC daily series, via quantum-finance.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
require_libtorch

say "== Demo 06: quant pipeline on a SYNTHETIC daily series (bin/quantum-finance) =="
note "dist: $QUANTUM_DIST_ROOT"
note "data: $SYNTH  — SYNTHETIC (rescaled + noised), NOT real market data (see data/README.md)"

say "\n1) Regime labelling with a Gaussian HMM (quantum-finance regime-gen):"
REG="$("$QF" regime-gen "$SYNTH" 2>/dev/null)"; echo "$REG" | grep -E "^(n_rows|regime[012]_frac) " | sed 's/^/    /'
echo "$REG" | grep -q "^n_rows 5438$"         && ok "5438 feature rows" || bad "n_rows"
echo "$REG" | grep -q "^regime0_frac 0.3617$" && ok "three volatility regimes labelled" || bad "regime fractions"

say "\n2) SMA-trend regime backtest vs buy-and-hold (quantum-finance trend backtest):"
BT="$("$QF" xauusd "$SYNTH" 2>/dev/null)"; echo "$BT" | grep -E "^(n_bars|close_last|strat_max_dd|strat_lower_dd) " | sed 's/^/    /'
echo "$BT" | grep -q "^n_bars 5462$"          && ok "5462 daily bars" || bad "n_bars"
echo "$BT" | grep -q "^close_last 1114.222$"  && ok "synthetic index last value 1114.222 (deterministic)" || bad "close_last"
echo "$BT" | grep -q "^strat_lower_dd 1$"     && ok "trend strategy cuts max-drawdown below buy-and-hold" || bad "drawdown"

finish
