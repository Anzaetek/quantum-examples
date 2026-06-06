# Demo 01 — Bell state: check a quantum circuit against the dist

**Model:** `bell.aria` (the Aria DSL model) and `bell.qasm` (the same circuit in OpenQASM 2.0).
**Harness:** `inspect.sh` — drives the **binary-only** `bin/quantum`. No toolkit source.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"   # see ../README.md §0
./inspect.sh
```

## What it shows — "how to check the circuits used"

1. **The model** — `bell.aria`, a 2-line human-readable circuit with proof obligations.
2. **Statistics** — `quantum info bell.qasm` → `Qubits: 2`, `H-count: 1`, `Gate count: 2`.
3. **Gate sequence** — `quantum compile bell.qasm --format qasm` round-trips the exact gates.
4. **Machine-checkable** — `quantum compile bell.qasm --format json` lists every gate (`H`, `CX`)
   with its qubits — diff-able, scriptable.
5. **Formal proof** — `quantum spec extract --aria bell.aria --instantiate "Bell()"` emits a **Lean 4**
   theorem file: the circuit isn't just run, it's *proven* to create `(|00>+|11>)/√2`.

Expected: `OK — 6 check(s) passed`.

## The circuit

```
q[0] ──H──●──  measure
          │
q[1] ─────X──  measure        ⇒  (|00> + |11>)/√2
```
