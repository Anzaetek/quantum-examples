# Demo 07 — QML: Quantum Circuit Born Machine (Aria model + training)

**Model:** `qcbm.aria` — a strongly-entangling **Quantum Circuit Born Machine** (the QML generative
circuit). **Harness:** `run.sh` against the binary-only dist.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
export LIBTORCH=/path/to/libtorch     # for the training step
./run.sh
```

## What it shows

A genuine **QML example** runnable on the binaries:
1. The **Aria QML model** (`qcbm.aria`) — a parameterized Born-machine circuit.
2. The circuit exported to a **Lean 4** theorem (`quantum spec extract`, libtorch-free).
3. **Training** the QCBM via `quantum-finance qcbm` — it learns the joint copula-innovation
   distribution, **KL → 0**.

Expected: `OK — 2 check(s) passed`. (Step 3 skips cleanly if libtorch isn't installed.)
