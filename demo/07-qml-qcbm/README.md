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
3. **Training** the QCBM via `quantum-finance qcbm` — the Born machine **expresses** the joint
   copula-innovation histogram, **KL → 0**.

> Read `final_kl` precisely. It is `final_loss − target_entropy` = `KL(p_target ‖ p_model)`
> against the histogram the model was just trained on, so it is a **training** loss and an
> **expressivity** result — not a held-out score. This step used to claim the model "learns the
> distribution"; it does not support that. The trained model reproduces the fitted histogram to
> `4e-4` (`KL(p_test‖model) 0.920710` vs `KL(p_test‖p_train) 0.921123`) and carries no
> information beyond it. The bar is still real — a depth-1 ansatz leaves `final_kl 0.309745`,
> far over it — it just certifies capacity, not generalisation.

Expected: `OK — 2 check(s) passed`. (Step 3 skips cleanly if libtorch isn't installed.)
