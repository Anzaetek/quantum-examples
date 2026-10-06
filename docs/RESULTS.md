# Results — what the evaluation bundle shows, and what the full build does

The binaries in `dist/` are a **deliberately limited evaluation build**. They are
limited in three ways, all baked in at build time:

| Limit | Evaluation bundle | Full build |
|---|---|---|
| **Expiry** | 90 days from the build moment; then the binaries refuse to run | none |
| **Qubit cap** | 12 qubits general · 64 for `ecc` / `expect` | unlimited |
| **Monte-Carlo shots** | tuned to the *statistical floor* (see below) | unlimited |

Everything in the right-hand column below was measured on this toolkit, on the
machine that produced the bundles. No entry is aspirational.

---

## Error correction — rotated surface code

The headline result: **the logical error rate falls ~3× for every step in code
distance**, at a fixed 1% physical error rate. That is the sub-threshold scaling
that makes error correction worth doing, and it is what the eval bundle lets you
watch happen at d=3→5→7.

| | Evaluation bundle | Full build |
|---|---|---|
| Largest code | `[[49,1,7]]` (d=7) — d=9 is refused at 81 qubits | **`[[169,1,13]]`** (d=13), 338/338 single-qubit X and Z errors corrected |
| Logical error rate @ p=0.01 | d=3 `0.0032` · d=5 `0.0010` · d=7 `0.0003` (`quantum ecc --distance N --p 0.01 --shots 8000 --seed 7`; 3.2× then 3.3× per step; d=7 is ~2 failures in 8000 shots) | same law, extended to larger distances |
| Backend agreement | statevector / stabilizer / MPS / Pauli-propagation agree bit-for-bit on the syndrome | same, at every distance the backend supports |
| Decoder | exact minimum-weight matching | same |

## Expectation values — Pauli propagation

Reads ⟨O⟩ in the Heisenberg picture: **exact** for Clifford circuits at any
width, and a coefficient-truncated approximation for non-Clifford ones with a
reported error budget that shrinks to the exact answer.

| | Evaluation bundle | Full build |
|---|---|---|
| Widest exact circuit | 64-qubit GHZ (128 is refused) | **256-qubit GHZ**, ⟨Z₀·Z₂₅₅⟩ = 1.0000000000 exactly |
| Truncation control | error budget reported and shrinking (C=1e-1 → 1e-3 drives \|err\| 5.8e-3 → 1.8e-4) | same |
| Where a statevector fails | a dense statevector cannot hold 24 qubits under the cap | Pauli propagation is the scalable path; no width limit for Clifford |

## Monte-Carlo shot floor

The shot count is capped rather than merely reduced, and the cap was **measured,
not chosen for looks**. Sweeping the d=3 surface code across 12 seeds:

| Shots | Worst-case 95% upper bound on logical rate | Verdict |
|---|---|---|
| 50–100 | 0.114 / 0.059 | **vacuous** — zero failures observed; proves only that the trial count was too small to see one |
| 200–400 | 0.030 / 0.022 | seed-dependent; some seeds report no suppression at all |
| 800–1600 | 0.014 / 0.010 | passes, but the bound still touches p=0.01 |
| **3200** | **0.0075** | floor — suppression is defensible at 95% for every seed tried |
| 8000 | 0.0058 | tightest measured in the sweep |

Below 3200 the claim "logical < physical" stops being statistically supportable.
This is why the eval bundle stops there rather than lower: a smaller number would
still *print* a pass while demonstrating nothing.

## Other capabilities

| Capability | Evaluation bundle | Full build |
|---|---|---|
| Circuit optimization | a naive 7-gate GHZ collapses to the minimal 3 (H, CX, CX) | same passes, no size limit |
| Aria → **Lean 4** theorem export | Bell, GHZ, QFT(n=3/4/5), QCBM circuits | any model; the whole proof root is **sorry-free** |
| MBQC / blind computation | circuit → measurement pattern, run on a server that stays blind | same |
| Quantum Oracle Sketching | infidelity falls ~4× per doubling of N (`error_ratio_2x 3.9999`) | same law to N=16384 (`3.178e-11`) |
| Transversal QEC | encoded Grover, logical QFT/QPE, Reed–Muller distillation, encoded QSP | same, at larger code distances |

---

## What these numbers are — and what they are not

Worth being direct, because the distinction decides whether any of this is
useful to you.

**These are correctness results, not speed results.** This toolkit *simulates*
quantum computation on a classical machine. Nothing here runs faster than a
classical algorithm for the same problem, and no number above should be read as
a quantum speed-up. What the numbers establish is that the algorithms,
error-correcting codes, and compiled circuits are **right** — verified against
independent routes: four simulator backends that must agree bit-for-bit, exact
closed forms, an external check against Qiskit at ~1e-13, and machine-checked
Lean 4 proofs.

**Where that is worth something.** If you intend to run on real quantum hardware,
the expensive mistakes are made long before the hardware: a mis-compiled circuit,
a code whose decoder does not actually correct the errors it claims, a resource
estimate off by an order of magnitude. Those are exactly what this verifies, at a
cost of seconds.

**Two claims we do not make.** The generative-model and trading components in the
bundle (demos 06–08) demonstrate that the pipelines train and run end-to-end;
they are **not** evidence that a quantum model beats a classical one on those
tasks, and the demos now print the full scorecard — including where a strategy
loses to buy-and-hold — rather than the flattering half. Separately, our
reproductions of published papers check each paper's *mechanism and mathematics*
against our implementation; they are not compared against the papers' published
numbers.

Ask for the technical note if you want the per-check breakdown of which results
are independent cross-certifications and which are convergence smoke tests. We
keep that distinction written down.
