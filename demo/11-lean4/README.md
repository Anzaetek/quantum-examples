# Demo 11 — Aria → Lean 4 target extraction

**Harness:** `run.sh` → `quantum spec extract` on the bundled Aria models. Binary-only.

```bash
export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)"
./run.sh
```

## What it shows

The toolkit exports quantum models written in **Aria** straight to **Lean 4 theorem files** carrying
their proof obligations — via `quantum spec extract --aria MODEL --instantiate "Name(...)"`. The demo
extracts several (Bell, QFT(n=3), a QCBM, a QML classifier) and, with `--mbqc`, also emits the
**measurement-pattern certificate** (a `native_decide` circuit↔pattern proof).

Expected: `OK — 5 check(s) passed`. This is the differentiator: your quantum circuits are **formally
specified and machine-checkable**, not opaque.
