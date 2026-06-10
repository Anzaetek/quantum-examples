# Customer demo — run quantum models against the binary-only distribution

These are **self-contained demo subfolders**. Each carries a **quantum model** (Aria DSL + QASM) and
a **minimal harness** (shell or Rust) that runs/builds **against the shipped binary-only
distribution** — no toolkit source, no Rust workspace. This is how a customer consumes the system.

## 0. Get a distribution

Build one (on the matching machine), or use a release tarball:

```bash
# from the toolkit repo:
QUANTUM_DIST=1 ./scripts/release/build-dist.sh cpu      # or metal (mac) / cuda (linux)
mkdir -p /tmp/qdist && tar xzf dist/quantum-dist-*.tar.gz -C /tmp/qdist
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"         # points at the extracted dist root
```

`$QUANTUM_DIST` must contain `bin/quantum`, `bin/quantum-server`, `clients/`, `docs/`. Every demo
below resolves the binaries through `$QUANTUM_DIST` (see `common.sh`).

## The demos

| Folder | Model | Harness | Shows |
|---|---|---|---|
| [`01-bell/`](01-bell/) | Bell (Aria + QASM) | shell | **How to check the circuit** — `info`, `compile qasm/json`, `optimize`, and Aria→**Lean 4** proof |
| [`02-qft/`](02-qft/) | QFT (parameterized Aria) | shell | A **parameterized** model instantiated at n=3/4 and exported to a Lean 4 theorem |
| [`03-rust-harness/`](03-rust-harness/) | redundant 3-qubit circuit (QASM) | **standalone Rust crate** | Integrating the shipped `quantum-server` into your own Rust app over the AF_UNIX JSON-RPC socket |
| [`04-qos/`](04-qos/) | — | shell | **Quantum Oracle Sketching** through the stripped CLI (`quantum qos`) |
| [`05-optimizer/`](05-optimizer/) | GHZ (Aria + QASM) | shell | A **real optimizer reduction** — a naive 7-gate GHZ collapses to the minimal 3 gates |
| [`06-finance/`](06-finance/) | **synthetic** daily series | shell | **Trading pipeline** on `quantum-finance`: HMM regimes + backtest vs buy-and-hold (data is synthetic, see [`data/`](data/)) |
| [`07-qml-qcbm/`](07-qml-qcbm/) | `qcbm.aria` | shell | **QML** — a Quantum Circuit Born Machine model, trained (KL→0) via the binary |
| [`08-qml-classifier/`](08-qml-classifier/) | `classifier.aria` | shell | **QML** — a variational quantum **classifier** model, trained as a QNN (val≈0.80) |
| [`09-mbqc/`](09-mbqc/) | `mbqc_bell.aria` | shell | **MBQC** — compile a circuit to a one-way measurement pattern, optimize + simulate |
| [`10-ubqc/`](10-ubqc/) | — | shell | **Blind QC** (UBQC/BFK) — run a pattern on a remote server that stays blind |
| [`11-lean4/`](11-lean4/) | bundled `.aria` | shell | **Lean 4 extraction** — export Aria models to Lean 4 theorems (+ MBQC certificate) |
| [`12-ecc/`](12-ecc/) | `surface.aria` | shell | **Error correction** — rotated surface code `[[9,1,3]]`/`[[25,1,5]]`, multi-backend syndrome + MWPM decode; d=5 on the RAM-safe stabilizer/MPS backends |
| [`13-pauliprop/`](13-pauliprop/) | `trotter_ising.aria` | shell | **Pauli propagation** — `quantum expect` reads `⟨O⟩` via a Heisenberg Pauli-string tree; Aria→Lean model, exact non-Clifford cross-check, certified truncation-error curve, 24-qubit GHZ where the statevector can't fit |

> Demos 06–08 need the **libtorch runtime** (`export LIBTORCH=/path/to/libtorch`); they skip cleanly
> without it. Demos 01–05 + the Rust harness need only the toolkit binaries.

## How to check the quantum circuits used

Against `bin/quantum` alone (no source):

```bash
$QUANTUM_DIST/bin/quantum info     circuit.qasm            # qubits, gate count, depth, T/H-count
$QUANTUM_DIST/bin/quantum compile  circuit.qasm --format qasm   # the exact gate sequence
$QUANTUM_DIST/bin/quantum compile  circuit.qasm --format json   # full machine-checkable gate list
$QUANTUM_DIST/bin/quantum optimize circuit.qasm            # the optimized circuit
$QUANTUM_DIST/bin/quantum spec extract --aria model.aria --instantiate "Name()" --out OUT  # Lean 4 proof
```

Run everything: `./run-all.sh` (drives all four demos; numbers only, asserts each).
