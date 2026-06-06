# Aria — a tutorial for the quantum language

**Aria** is a small, readable DSL for writing quantum circuits with **built-in proof obligations**.
An Aria model is human-readable, parameterized, and exports to QASM, a Lean 4 theorem, an MBQC
pattern, and more — all through the `quantum` CLI. This tutorial takes you from a first circuit to
parameterized, formally-specified models.

> Editor support: install syntax highlighting (VS Code / Neovim / tree-sitter) from `editors/`
> (`./editors/install.sh`). `.aria` files then highlight nicely.

## 1. Your first circuit — a Bell state

```aria
-- Bell state: (|00> + |11>) / sqrt(2)
@assert unitary
@prove "bell_correct" equiv { creates (|00> + |11>)/sqrt(2) }
@bound gate_count = 2

circuit Bell {
    qreg q[2]          -- 2 qubits
    creg c[2]          -- 2 classical bits

    apply H on q[0]            -- superpose q[0]
    apply CX on q[0], q[1]     -- entangle q[1] with q[0]

    measure q -> c            -- measure all qubits into c
}
```

- **`circuit Name { ... }`** declares a circuit.
- **`qreg q[n]` / `creg c[n]`** declare quantum / classical registers.
- **`apply GATE on q[i]`** applies a gate; two-qubit gates take two wires (`apply CX on q[0], q[1]`).
- **`measure q -> c`** measures.
- Lines starting `--` are comments.

### Annotations (the proof obligations)
- **`@assert unitary`** — the circuit must be unitary.
- **`@prove "name" equiv { ... }`** — a semantic claim carried into the Lean 4 export.
- **`@bound metric = value`** — a resource bound (e.g. `gate_count`, `depth`).

## 2. Run it against the binaries

```bash
# Export to a Lean 4 theorem (with the proof obligation):
quantum spec extract --aria bell.aria --instantiate "Bell()" --out out/

# Inspect the circuit (via its QASM form):
quantum info bell.qasm            # Qubits: 2, H-count: 1, Gate count: 2
quantum compile bell.qasm --format json   # full gate list

# Compile to a measurement-based (MBQC) pattern:
quantum mbqc bell.qasm            # pattern vertices/edges + output_norm=1.0
```

## 3. Parameters and loops — the QFT

Circuits take integer parameters and use `repeat` loops:

```aria
@assert unitary
@prove "qft_equals_dft" equiv { denote(QFT) = DFT_matrix(2^n) }
@bound depth = n * (n + 1) / 2

circuit QFT(n: int) {
    qreg q[n]

    repeat i from 0 to n - 1 {
        apply H on q[i]
        repeat j from i + 1 to n - 1 {
            apply CP(pi / (2.0 ^ (j - i))) on q[j], q[i]   -- controlled phase
        }
    }
    repeat i from 0 to (n / 2) - 1 {
        apply SWAP on q[i], q[n - 1 - i]                   -- bit-reversal
    }
}
```

Instantiate at any size: `quantum spec extract --aria qft.aria --instantiate "QFT(n=3)"`.
`repeat i from a to b { ... }` is inclusive; `step -1` counts down. Angle expressions support
`pi`, `^`, `/`, `*`, `+`, `-`.

## 4. Symbolic (trainable) parameters — a QML model

Use `let x = symbolic[k]` for trainable angles (an optimizer binds them per step):

```aria
circuit QMLClassifier(L: int) {
    qreg q[1]
    let theta = symbolic[3 * L]              -- 3 trainable angles per layer

    repeat layer from 0 to L - 1 {
        apply RY(pi / 4) on q[0]             -- data-reuploading placeholder
        apply RZ(theta[3 * layer + 0]) on q[0]
        apply RY(theta[3 * layer + 1]) on q[0]
        apply RZ(theta[3 * layer + 2]) on q[0]
    }
}
```

The same model trains as a real QNN (`quantum-finance regime-classify --model qnn`).

## 5. Observables

Read-outs are declared separately and lowered alongside the circuit:

```aria
observable Representation {
    1.0 * Z(0)        -- <Z> on qubit 0
}
```

## 6. Gate vocabulary (common)

`H`, `X`, `Y`, `Z`, `S`, `T`, `RX(θ)`, `RY(θ)`, `RZ(θ)`, `P(λ)`/`CP(λ)`, `CX`, `CZ`, `SWAP`, `CCX`,
plus photonic elements. Multi-qubit gates list their wires in order.

## 7. Where to go next

- The `demo/` folder runs end-to-end Aria models against the binary distribution
  (`demo/01-bell`, `demo/02-qft`, `demo/07-qml-qcbm`, `demo/09-mbqc`, `demo/11-lean4`).
- `examples/aria/` has 36 worked models (Grover, Shor-ECDLP, QPE, teleport, MBQC, …).
- `docs/spec-extraction.md` documents the Aria → Lean 4 pipeline in depth.

Aria's point: a quantum model you can **read, parameterize, run, and prove** — from one source.
