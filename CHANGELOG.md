# Changelog — quantum-examples evaluation bundles

Every entry names the toolkit (`quantum`) and simulator (`omega`, Aria Quantum
OSS) revisions baked into the bundles; `dist/README.md` carries the per-bundle
sha256 and tour verdicts, `docs/RESULTS.md` the numbers.

## v2.0.0 — 2026-10-19

The first release whose six bundles all embed the **Aria Quantum OSS 2.0.0**
simulator backends (omega `5a15e73`), compiled with rustc 1.99.0.

- **Bundles** (`dist/`): `mac-cpu`, `mac-metal` (quantum `174f7242`, native on
  Apple Silicon); `linux-amd64-cpu`, `linux-amd64-gpu` (native), `linux-arm64-cpu`
  and — new — `linux-riscv-cpu` (cross-built; quantum `222aabae`). Every bundle
  ships `ecc` / `expect` / `logical` live; QML/finance (`quantum-finance`) ships
  in the four native bundles.
- **Limits proven from the binary, not from a text file.** Each bundle expires at
  unix `1801440000` (2027-02-01T00:00:00Z) and caps general circuits at 12
  qubits (64 for `ecc`/`expect`); the bundled `run.sh` and the toolkit's
  `verify-dist.sh` read the expiry back from the server's `ping` and have the
  CLI refuse a 13-qubit circuit. Added because the previous arm64 bundle
  (`8426b18`) was uncapped — the cross build had not seen the pins.
- **Reproducible archives.** Same inputs → same tarball sha256 (probed on
  mac-metal, linux-amd64-cpu, linux-arm64-cpu); tar entries equal unique paths
  (the earlier bundles stored every file several times).
- **New demo 15 — QAS** (`demo/15-qas`): quantum circuit-architecture search
  through the shipped `quantum-finance arch-search --model qnn` (TPE over
  encoding × ansatz × readout × width × depth, walk-forward macro-F1 on the
  synthetic labels): `best_macro_f1 0.7687` vs majority-class `0.2007`,
  `selected 1`, deterministic across runs. Needs the libtorch runtime like
  06–08.
- **New demo 16 — data provenance** (`demo/16-provenance`) and the **data
  pin** behind it: the eval `quantum-finance` embeds the shipped synthetic
  series at build time and only computes on it — a series is accepted iff its
  sha256 equals the embedded copy's, a `--data` label file iff it is
  byte-identical to what the same binary's `regime-gen` derives from the pin
  (regenerated on the spot). `data-pin` proves the state from the binary;
  `verify-dist.sh` gained a `pin:` line next to `cap:` and `expiry:`. Bundles
  built before 2026-10-19 (`222aabae`) have no pin; demo 16 skips on them.
- **Tour** (`demo/run-all.sh`, now 16 demos): the committed bundles' own
  `demo/` copies predate demo 15 and report `ran 14, ALL DEMOS PASSED` on
  mac-cpu, mac-metal and linux-amd64-gpu (demo 08 on `Cuda(0)`) and `ran 10`
  in stock Debian containers on linux/amd64, arm64 and riscv64 (03 needs
  cargo, 06–08 need libtorch); this repo's `demo/run-all.sh` adds 15-qas on
  the same binaries (see `dist/README.md`); 16-provenance needs a bundle built
  at or after the data pin.
- **Docs**: `docs/aria-tutorial.md` checked against the shipped binary (Bell,
  QFT and the symbolic-model refusal); README platform table and demo index
  brought in line with what the bundles contain.

## v1 — 2026-06 … 2026-10

Bundles at quantum `f5b7cfa` … `231b7c4` / omega `ed146b4` (Aria Quantum OSS
1.x): mac cpu/metal, linux-amd64 cpu/gpu, linux-arm64 cpu. Demos 01–14,
`docs/RESULTS.md`, the editors, the 3200-shot floor. Superseded by v2.0.0;
those tarballs are no longer in `dist/`.
