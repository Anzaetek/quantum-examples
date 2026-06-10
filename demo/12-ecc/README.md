# Demo 12 — Surface-code quantum error correction

Builds a **rotated surface code `[[9,1,3]]`** (distance 3, one logical qubit in
nine physical ones), injects a Pauli error, extracts the stabilizer **syndrome
on three different simulator backends**, corrects it with a **minimum-weight
(MWPM) decoder**, and then **scales to a distance-5 `[[25,1,5]]` code** on the
backends that fit in RAM — all through the binary-only dist, numbers only.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./run.sh
```

## What it shows

| Step | Command | Numeric check |
|------|---------|---------------|
| Code | `quantum ecc --distance 3` header | `data=9 x_checks=4 z_checks=4` (13-qubit syndrome sector) |
| Decode | `quantum ecc --backend stabilizer` | clean syndrome **0**; X@4 → syndrome **1,1,0,0**; correction **X on qubit 4**; residual **0**; **no** logical error |
| Cross-check | `quantum ecc --backend statevector` / `mps` | all three backends agree on the syndrome **bit-for-bit** (`backend_agreement 1`) |
| Coverage | (single-error battery) | **18/18** single-qubit X and Z errors corrected |
| Threshold | `quantum ecc --p 0.01 --shots 8000` | logical error rate **< 1%** physical (`suppressed 1`) |
| **Scale** | `quantum ecc --distance 5 --backend stabilizer` | `[[25,1,5]]`; stabilizer + MPS agree (`backend_agreement 1`, `backends_checked stabilizer,mps`); **50/50** single errors corrected |
| **Refusal** | `quantum ecc --distance 5 --backend statevector` | exits **2** (`infeasible for distance 5 (37 qubits)`) — refuses rather than exhausting RAM |
| **d=7** | `quantum ecc --distance 7 --backend pauliprop` | `[[49,1,7]]`; **98/98** single errors corrected in ~MB; stabilizer/mps/statevector all refuse (64-bit key cap), pauliprop alone reaches it |

## The idea

A surface code is a CSS stabilizer code on a `d×d` grid. Half the checks are
products of `Z` (they catch `X`/bit-flip errors), half are products of `X` (they
catch `Z`/phase-flip errors). To keep the syndrome **deterministic** — so every
simulator must return the same answer — the two sectors are run separately:

* **bit-flip sector** — data in `|0…0⟩`, measure the Z-checks (diagonal, hence
  deterministic), inject and decode `X` errors;
* **phase-flip sector** — the Hadamard dual on `|+…+⟩`, for `Z` errors.

Because each prepared state is a stabilizer eigenstate, one projective shot
fixes the whole syndrome, and the **exact statevector**, the **MPS
tensor-network** and the **stabilizer/Clifford tableau** simulators agree
exactly. The MWPM decoder then returns the minimum-weight error consistent with
the syndrome; for `d=3` every single-qubit error is corrected, and below the
pseudo-threshold the logical error rate is suppressed (∝ `p²`).

## Why distance 5 needs the right backend

Each CSS sector of a distance-`d` code is a `d² + checks`-qubit circuit. At
`d=5` that is **37 qubits**, and a *dense statevector* is `2³⁷ ≈ 1.37 × 10¹¹`
complex amplitudes ≈ **2 TB** — it exhausts RAM and the process is OOM-killed.
`quantum ecc` therefore **refuses** the statevector backend past 26 qubits and
runs only the simulators that scale:

* **stabilizer** (`stabilizer`/`pauli`) — an Aaronson–Gottesman Clifford tableau,
  `O(n²)`; exact for these stabilizer-eigenstate syndromes;
* **mps** — a bond-capped matrix-product-state tensor network.

Both finish `d=5` in a few **megabytes** and agree on the syndrome bit-for-bit.

For `--distance 7` and beyond, the 73-qubit measurement sector exceeds the
64-bit `Counts` key, so the measurement backends refuse cleanly. The
**`pauliprop`** backend (Pauli propagation — a Heisenberg-picture tree of
weighted Pauli strings, arXiv:2505.21606) sidesteps this entirely: it reads
each check's *expectation value* `⟨C⟩ = ±1` on the bare data state (no ancilla,
no measurement key), staying exact and `O(MB)` for the Clifford syndrome at any
distance. It carries the demo to `[[49,1,7]]` (`98/98`) and `[[81,1,9]]`.

Files: `surface.aria` (the model), `surface.qasm` (the syndrome circuit),
`run.sh` (the numeric harness).
