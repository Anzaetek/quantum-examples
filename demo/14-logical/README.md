# Demo 14 — Transversal low-overhead QEC: logical algorithms

Runs textbook quantum algorithms as **logical** circuits on the transversal
low-overhead QEC layer, and measures a surface-code memory's logical-error
scaling. Models the recent neutral-atom **Transversal STAR** architecture
([arXiv:2509.18294](https://arxiv.org/html/2509.18294v1), QuEra) and the
trapped-ion small-code family (Quantinuum: Steane `[[7,1,3]]`, color codes),
where a logical qubit is encoded in a *small* number of physical qubits and
logical gates are **transversal** (parallel physical operations, ~1 syndrome
round).

## What it shows (numbers only — `./run.sh`)

1. **Encoded 2-qubit Grover** on the Steane `[[7,1,3]]` code. Grover's oracle +
   diffuser are pure Clifford (H, X, CZ), so the algorithm runs **exactly** on
   the Pauli-propagation backend on encoded qubits. Every marked state is
   recovered (`⟨Z̄_i⟩ = ±1`, `success = 1`).
2. **Backend cross-check** — Pauli-propagation and the exact statevector agree on
   the logical observable, and §2c extends that to **all four** exact engines
   (dense amplitudes / tensor train / Heisenberg Pauli tree / Clifford tableau).
   The stabilizer backend was excluded until 2026-08-05: it reported
   `⟨Z̄_0⟩ = 0` where the other three reported `±1`, from an upstream defect in
   omega's `PauliBackend` (a greedy non-pivoting reduction plus an inverted
   `X·Z`/`Z·X` phase table). Fixed upstream, so it is back in the cross-check.
2b. **The same Grover on the triangular 6.6.6 colour code**, `d = 3/5/7`
   (`[[7,1,3]]`, `[[19,1,5]]`, `[[37,1,7]]`) — **14 / 38 / 74 physical qubits**,
   still exact. The colour code is the interesting vehicle because it has a
   transversal *full* Clifford group including **S**, which the surface code
   does not; Steane is just its `d = 3` instance, so `d > 3` is where that
   becomes a real claim. The check pins the physical width to `2·(3d²+1)/4` as
   well as the logical readout — a wrong code would still "succeed" on `⟨Z̄⟩` at
   the wrong size.

   Worth knowing: the transversal-S gadget here is **not** `S^⊗n`. The bulk
   faces have weight 6 and `i⁶ = −1`, so `S^⊗n` maps a stabilizer to *minus* a
   stabilizer — a valid gate at `d = 3` (all faces weight 4) and not a logical
   gate at all at `d = 5, 7`. It applies `S` on one lattice sublattice and `S†`
   on the other.
3. **Logical QFT** — `QFT|input⟩` is uniform and `QFT ∘ QFT⁻¹ = identity`.
4. **Logical QPE** — `φ = k/2ᵐ` is recovered as a clean delta (`phase_error ≤
   1e-6`, `peak_prob > 0.999`).
4b. **The `[[15,1,3]]` punctured Reed–Muller code — transversal T.** The one
   non-Clifford gate no 2D topological code gives you, which is why a stack
   switches into this code for `T`. Checked exactly on the 2¹⁵ statevector:
   `T^⊗15` leaves `|0⟩_L` fixed (its support is the 16 simplex codewords, all
   of weight 0 or 8, so the phases are `e^{i·0}` and `e^{i·2π}`) and multiplies
   `|1⟩_L` by exactly `e^{−iπ/4}` (coset weights 7 and 15, both `≡ 7π/4`).

   So it is logical **T†**, not T — and the sign is a trap worth naming:
   reading `⟨Y^⊗15⟩` gives `+1/√2` and the opposite conclusion, because the
   logical `Ȳ ≡ iX̄Z̄ = −Y^⊗15`. The demo measures the relative phase of the two
   logical amplitudes instead, which involves no Pauli convention at all.

   The distillation constant is **derived, not quoted**: `35` is the number of
   weight-3 Z-error patterns that pass all four X-checks *and* flip the logical
   qubit, counted over all 2¹⁵ patterns. The same count shows weight 4 is empty,
   so the next correction is `O(p⁵)` rather than the `O(p⁴)` one would assume.

4c. **QSP on an encoded qubit — the polynomial survives encoding.** Quantum
   Signal Processing alternates a signal rotation `W(x)` with phase rotations
   `S(φ)`. With **zero phases** the sequence collapses to `W^d`, whose top-left
   entry is exactly `cos(d·arccos x) = T_d(x)` — so the encoded `⟨Z̄⟩` must equal
   `2·T_d(x)² − 1`, and the Chebyshev three-term recurrence supplies that
   independently, sharing no code with the QSP path. `T_d` is the polynomial the
   sorry-free `QuantumProofs/QSP.lean` certifies.

   Sampled at **interior** `x` (0.3, 0.7, 0.9, −0.35), deliberately not at the
   extremal `cos(kπ/d)` where `T_d = ±1` and `⟨Z̄⟩ = ±1` for any implementation —
   the check would be free there. The demo also asserts `|⟨Z̄⟩| < 0.999` for the
   same reason.

5. **Surface-code memory** — under a hardware-flavored ZZ-biased (neutral-atom)
   noise model, the logical-error rate **suppresses with distance** (`d=5 <
   d=3`), the sub-threshold signature.
6. **Effective logical channel** — the extracted per-round logical Pauli channel
   is phase-dominated (`p_lz > p_lx`), reflecting the ZZ bias.

## Run

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"   # a build-dist.sh tarball root
./run.sh
```

Requires a native dist (the `omega-sim` simulator backends). A cross-built Linux
core-CLI bundle ships `quantum logical` inert and the demo skips cleanly.

The Rust twins are the `logical::` unit tests:
`cargo test -p quantum-core --features omega-sim --lib logical::`.
See `TESTING.md` §7.3a′ for the numeric golden table, and
[`docs/transversal-qec.md`](../../docs/transversal-qec.md) for a from-first-
principles explanation of how the whole logical layer works (the physics, the
per-module math, and the two simulation altitudes).
