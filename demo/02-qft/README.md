# Demo 02 — parameterized QFT model

**Model:** `qft.aria` — a *single* Aria circuit `QFT(n: int)` (plus its inverse `IQFT`). One model,
any size. **Harness:** `inspect.sh` against the binary-only `bin/quantum`.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./inspect.sh
```

## What it shows

- A **parameterized** quantum model: the Cooley–Tukey QFT written once, instantiated at `n = 3, 4, 5`.
- Each instantiation is exported to a **Lean 4** theorem via
  `quantum spec extract --aria qft.aria --instantiate "QFT(n=N)"`, carrying the proof obligation
  `denote(QFT) = DFT_matrix(2^n)`.

Expected: `OK — 3 check(s) passed`.

This is the differentiator: your quantum models are **parameterized, inspectable, and formally
specified** — not opaque binaries.
