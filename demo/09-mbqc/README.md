# Demo 09 — Measurement-Based Quantum Computing (MBQC)

**Model:** `mbqc_bell.aria` (the graph-state + measurement-order model) + `bell.qasm` (the circuit).
**Harness:** `run.sh` → `quantum mbqc` on the binary-only dist.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./run.sh
```

## What it shows

`quantum mbqc bell.qasm` compiles the gate circuit into a **one-way measurement pattern**
(5 vertices / 4 edges / 3 measurements), **optimizes** it (Clifford reduction 5 → 3 vertices), and
**simulates** it — the pattern reproduces the circuit exactly (`output_norm = 1.000000`) and lays out
on a brickwork lattice (`ubqc_on_lattice = 3/3`). This is the resource model behind blind quantum
computing (demo 10). Expected: `OK — 4 check(s) passed`.
