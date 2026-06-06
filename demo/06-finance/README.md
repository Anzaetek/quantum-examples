# Demo 06 — finance/trading on a synthetic daily series

**Data:** `../data/synthetic_daily.csv` — a **synthetic** instrument ("SYNX"), rescaled to a ~100
index + noise. **Not real market data** (see [`../data/README.md`](../data/README.md)).
**Harness:** `run.sh` → the bundled `bin/quantum-finance`. Needs the **libtorch runtime**
(`export LIBTORCH=/path/to/libtorch`).

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
export LIBTORCH=/path/to/libtorch
./run.sh
```

## What it shows

- **Regime labelling** — `quantum-finance regime-gen` fits a Gaussian HMM → 5438 rows, three
  volatility regimes.
- **Backtest** — an SMA-trend regime strategy over 5462 daily bars **cuts max-drawdown below
  buy-and-hold** on the synthetic series.

Deterministic golden anchors (the data is seeded synthetic). This is the kernel of the `sqetch`
trading product — demonstrated on fake data. Expected: `OK — 5 check(s) passed`.
