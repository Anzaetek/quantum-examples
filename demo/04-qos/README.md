# Demo 04 — Quantum Oracle Sketching

**Harness:** `run.sh` → `quantum qos` (in the **libtorch-free** dist binary).

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./run.sh
```

## What it shows

Quantum Oracle Sketching (Babbush/Huang/Zhao 2026, arXiv:2604.07639), **emulated**: build a query
oracle for a 1024-dim data vector **from random samples** (no QRAM). The qubit count is
`⌈log₂ dim⌉ = 10` (polylog in the dataset), and the infidelity to the exact oracle obeys the
**O(1/N²) sample-complexity law** — `error_ratio_2x ≈ 4` (it falls ~4× each time the sample count
doubles). The Halmos block-encoding round-trips exactly.

Expected: `OK — 3 check(s) passed`. Try `quantum qos --dim 4096` for 12 index qubits.

> This is the scaling-QML highlight shipping in the stripped binary — verified by the dist's own
> `run.sh` smoke too.
