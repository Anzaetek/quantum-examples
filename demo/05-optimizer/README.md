# Demo 05 — GHZ and a real optimizer reduction

**Model:** `ghz.aria` (clean 3-qubit GHZ) + `ghz_naive.qasm` (the same circuit written with redundant
`X·X` and `H·H` pairs). **Harness:** `inspect.sh` against the binary-only `bin/quantum`.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./inspect.sh
```

## What it shows

The optimizer is real, not cosmetic: `quantum optimize ghz_naive.qasm` collapses the naive
**7-gate** circuit to the minimal **3-gate** GHZ (`H, CX, CX`) by cancelling the adjacent `X·X` and
`H·H` pairs — verified by `quantum info` before/after (`7 → 3`). The clean model also exports to a
Lean 4 theorem.

Expected: `OK — 4 check(s) passed`.
