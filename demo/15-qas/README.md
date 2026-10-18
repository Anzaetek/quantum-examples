# Demo 15 — QAS: quantum circuit-architecture search

Searches the **architecture** of a variational quantum classifier — not its
angles — on the synthetic series' HMM regime labels, through the shipped
`bin/quantum-finance` (`arch-search finetune --model qnn`).

## What it shows (numbers only — `./run.sh`)

1. **Labels.** `regime-gen` labels the synthetic daily series with a Gaussian
   HMM: `n_rows 5438`, three volatility regimes (same labels as demos 06/08).
2. **The space.** Encoding (`AngleY`, `Amplitude`, `HadamardInit`,
   `LinearAngle`, `UnaryRy`) × ansatz (`StronglyEntangling`, `RotCnot`,
   `LowEntangleZ`, `RichZZ`, `Qcnn`, `BareRot`, `QcnnNeck`, `BasicEntangler`,
   `Rbs`) × readout (`ZAll`, `ZFirst`, `ZFirstLast`, `ZPlusZZ`, `Probs`) ×
   width × depth. Every point is a different circuit.
3. **The search.** A TPE sampler (the toolkit's own, no Optuna) proposes 6
   architectures; each is trained for 6 parameter-shift steps and scored by
   **macro-F1 on an expanding walk-forward split** of 195 time-ordered rows.
   Gates: `n_rows 195`, `best_arch` is a full `encoding|ansatz|readout|n|l`
   point, `baseline_macro_f1 0.2007` (majority class, exact),
   `best_macro_f1 ≥ 0.70` (measured `0.7687` on the `222aabae` linux-amd64
   bundle — `UnaryRy|LowEntangleZ{brickwall}|ZPlusZZ|n4|l2`, 19 parameters),
   `selected 1`.
4. **Determinism.** The identical search run again returns the identical
   `best_arch` and `best_macro_f1`.

7 checks, ~45 s (two searches). Needs `bin/quantum-finance` + the libtorch
runtime (`export LIBTORCH=…`); skips cleanly otherwise, like demos 06–08.

## Why this matters

For QML the expensive decision is the circuit, and it is usually made by hand.
Here it is made by the same hyperparameter machinery a classical model gets —
a sampler, an objective, a walk-forward split — and the result is a real QNN
(demo 08 trains the same family). The demo runs a CI-sized search; the score
is budget-bound, not model-bound — the same binary, more rows and steps
(measured 2026-10-19 on this synthetic series, one 32-core Linux box):

| `--n-trials` / `--walk-folds` / `--qnn-steps` / `--max-rows` | `best_macro_f1` | wall |
|---|---|---|
| 6 / 2 / 6 / 200 (this demo) | `0.7687` | 28 s |
| 6 / 2 / 12 / 400 | `0.7966` | 94 s |
| 8 / 2 / 20 / 400 | `0.8213` | 165 s |
| 10 / 2 / 30 / 400 | `0.8641` | 235 s |

Majority-class baseline `0.2007`; the classical GBDT arm reaches `0.91` on the
same labels — the point of QAS is the *automated circuit choice*, not beating
GBDT. The shipped binary runs every row above (within the qubit cap).

Data is **synthetic** (see `../data/README.md`) — never real market data.
