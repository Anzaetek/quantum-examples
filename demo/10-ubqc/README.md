# Demo 10 — Universal Blind Quantum Computation (UBQC / BFK)

**Harness:** `run.sh` — starts the bundled `quantum-server`, then drives a blind measurement pattern
against it with `quantum mbqc … --remote`. All against the binary-only dist.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./run.sh
```

## What it shows

**Blind quantum computing** (Broadbent–Fitzsimons–Kashefi): the client compiles a circuit to a
measurement pattern and runs it on a remote `quantum-server`, but the measurement angles are
**blinded** — the server performs the entanglement + measurements **without learning the computation
or the inputs**. The client de-blinds the outcomes and recovers the correct result:
`ubqc_remote_on_lattice = 3/3 recovered = 3`, `output_norm = 1.000000`.

Expected: `OK — 2 check(s) passed`. This is delegated quantum computing with privacy — run your
circuit on someone else's quantum computer without revealing it.
