# Demo 08 — QML: quantum neural-network classifier (Aria model + training)

**Model:** `classifier.aria` — an angle-encoded variational **quantum classifier** circuit.
**Data:** `../data/synthetic_daily.csv` (**synthetic**, not real market data — see
[`../data/README.md`](../data/README.md)). **Harness:** `run.sh` against the binary-only dist.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
export LIBTORCH=/path/to/libtorch
./run.sh
```

## What it shows

1. The **Aria QML model** (`classifier.aria`) — a parameterized variational classifier.
2. The circuit exported to a **Lean 4** theorem (libtorch-free).
3. The synthetic series is HMM-labelled (`regime-gen`), then a **QNN** is trained on those labels
   (`regime-classify train --model qnn`) — a variational quantum circuit trained by parameter-shift;
   reports val accuracy + macro-F1.

The QNN reaches val_acc ≈ 0.90 on the synthetic labels. Expected: `OK — 2 check(s) passed`. (~20s;
step 3 skips cleanly without libtorch.)
