# Demo 13 — Pauli propagation (expectation values)

A **fourth simulation scheme** alongside statevector / stabilizer / MPS:
**Pauli propagation** (arXiv:[2505.21606](https://arxiv.org/abs/2505.21606),
the engine behind `PauliPropagation.jl`). Instead of a state, it evolves an
**observable** backward through the circuit as a tree of weighted Pauli strings
and reads off `⟨O⟩` — **exact and width-unbounded for Clifford** circuits, a
**tunable approximation** for non-Clifford ones. All through `quantum expect`
on the binary-only dist, numbers only.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./run.sh
```

## What it shows

| Step | Command | Numeric check |
|------|---------|---------------|
| Model | `quantum spec extract --aria trotter_ising.aria --all` | the Aria model → a **Lean 4** theorem (82 lines) — the circuit is the same one the QASM runs |
| Cross-check | `quantum expect trotter_ising.qasm --backend pauliprop` | `⟨O⟩` equals the exact **statevector** for `Z0,Z2,Z0Z5,Z1Z2Z3` (bit-identical) |
| Truncation curve | `… --backend pauliprop --truncate {1e-1,1e-2,1e-3}` | every estimate is within its reported **`dropped_mass`**; the budget **shrinks monotonically** and the estimate **converges** (\|err\| → 1.8e-4 at C=1e-3) |
| Scaling | `quantum expect ghz24.qasm --backend pauliprop` | `⟨Z0·Z23⟩ = 1`, `⟨Z0⟩ = 0` on a **24-qubit** GHZ, instantly |
| Cap | `… ghz24.qasm --backend statevector` | the dense statevector is **refused** at 24 qubits on the eval cap — pauliprop is the scalable path |

## The idea

For `U = G_L…G_1` on `|0…0⟩`, `⟨O⟩ = ⟨0…0| U† O U |0…0⟩` is computed by
conjugating the observable by each gate from last to first, then summing the
all-`I/Z` Pauli terms. A **Clifford** gate maps one Pauli to one Pauli (no
growth → exact at any width); a **Pauli rotation** (`Rz/Rx/Ry/T`, and `CRz` =
`Rz·Rzz`) splits one Pauli into two — the *tree*. Truncating low-coefficient
branches (`--truncate C`) gives an approximation with a reported L1 error
budget (`dropped_mass`).

It is **complementary** to the other backends: it returns expectation values
(not samples), shines where the dense statevector runs out of memory (wide
Clifford, or low-branching non-Clifford), and is the same engine that lifts
`quantum ecc` to distance 7+ (see demo 12).

Files: `trotter_ising.aria` (the Aria model, extractable to Lean 4),
`trotter_ising.qasm` (its runnable twin), `ghz24.qasm` (a 24-qubit GHZ),
`run.sh` (the numeric harness).
