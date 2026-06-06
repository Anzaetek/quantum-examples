# Demo 03 — a standalone Rust harness against the shipped server

A minimal **Rust crate** (its own `Cargo.toml`, **not** part of the toolkit workspace, **no**
toolkit-source dependency) that integrates the binary-only distribution by talking to
`quantum-server` over the **AF_UNIX JSON-RPC** socket. This is how a customer embeds the system in
their own Rust app.

**Model:** `circuit.qasm` — a 3-qubit circuit with two adjacent Hadamards (redundant on purpose).

## Run

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"

# 1. start the shipped server (separate shell, or backgrounded):
"$QUANTUM_DIST/bin/quantum-server" --listen unix:/tmp/quantum-demo.sock &

# 2. build + run the harness against it:
QUANTUM_SOCKET=/tmp/quantum-demo.sock cargo run
```

(Or just run `./run.sh`, which starts the server, runs the harness, and cleans up.)

## What it shows

- **Protocol** (`docs/SERVER.md`): 4-byte big-endian length + UTF-8 JSON body; methods `ping`,
  `info`, `optimize`, `compile`, `parse`.
- The harness calls `info` (asserts **3 qubits, 4 gates**) then `optimize` (asserts the optimizer
  **removes the redundant Hadamard pair**, 4 → **2** gates) — all numerically checked.

Expected: `OK — harness verified the shipped server numerically`.

> The harness links **nothing** from the toolkit — only `serde_json` and `std`. The quantum work
> lives entirely in the shipped `quantum-server` binary.
