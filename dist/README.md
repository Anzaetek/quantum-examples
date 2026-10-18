# Evaluation bundles (per platform)

Each `quantum-dist-<platform>-test-*.tar.gz` is a time-limited, qubit-capped
evaluation build (see ../LICENSE). Extract one and point the demos at it:

    tar xzf quantum-dist-<platform>-test-*.tar.gz
    export QUANTUM_DIST="$(pwd)/dist-<platform>-test"
    ../demo/run-all.sh

See [`../docs/RESULTS.md`](../docs/RESULTS.md) for what these bundles show
numerically, beside what the unrestricted build does.

Provided here:

| Bundle | Platform | Contents |
|---|---|---|
| `mac-cpu-test` | macOS Apple-Silicon | core CLIs, live `ecc`/`expect` **+ QML/finance** |
| `mac-metal-test` | macOS Apple-Silicon + Metal | as above, **with Metal** — `quantum-finance` links the Metal libtorch and `--device metal` trains on the Apple GPU (prints `device Mps`) |
| `linux-amd64-cpu-test` | Linux x86-64 | core CLIs, **live `ecc`/`expect`**, **+ QML/finance on CPU** (needs a libtorch 2.7.0 runtime on the host, see below) |
| `linux-arm64-cpu-test` | Linux arm64 | core CLIs, **live `ecc`/`expect`** (cross-built; no `quantum-finance`) |
| `linux-riscv-cpu-test` | Linux RISC-V 64 | core CLIs, **live `ecc`/`expect`** (cross-built; no `quantum-finance`) |
| `linux-amd64-gpu-test` | Linux x86-64 + NVIDIA | core CLIs, live `ecc`/`expect`, **+ QML/finance with CUDA** — `quantum-finance` links `libtorch_cuda.so`, `--device cuda` trains on `Cuda(0)` |

### Provenance (Linux bundles refreshed 2026-10-18; mac pair 2026-10-18)

Each bundle's `MANIFEST.txt` records its own `git_sha`, `omega_sha`,
`libtorch` and `rustc`; the table repeats them. "Tour" is `../demo/run-all.sh`
with `DEMO_REQUIRE_ALL=1`, judged on its per-demo verdict lines.

| Bundle | sha256 | quantum · omega · libtorch | rustc | Tour |
|---|---|---|---|---|
| `mac-cpu-test` | `55a139ad7b21ae733df551f0cdd7869f2640f71330a4afdb94725de4063fbd27` | 174f7242 · 5a15e73 · 2.7.0 (cpu) | 1.99.0 | **ran 14, ALL DEMOS PASSED** |
| `mac-metal-test` | `81e50b8c12a9f374c87551468eb4e56087c39a136548889d7329dfd46a75260f` | 174f7242 · 5a15e73 · 2.7.0 (metal) | 1.99.0 | **ran 14, ALL DEMOS PASSED**; `regime-classify train --model dnn --device metal` prints `device Mps` |
| `linux-amd64-cpu-test` | `f09336c93fcfa1e0d4b5d4a724db9bcc25a8ab0f6e0e01be772a06bfb3dc9058` | 222aabae · 5a15e73 · 2.7.0+cu128 (cpu) | 1.99.0 | **ran 10, ALL DEMOS PASSED** in a stock `debian:bookworm-slim` container (03 needs cargo, 06–08 need a libtorch runtime: the four named skips); 12-ecc=19, 13-pauliprop=9, 14-logical=15 |
| `linux-amd64-gpu-test` | `b16109d871241a27ed8e5f9d28de3a0f8eab294fcd51f70c43ebcb59920fa5f7` | 222aabae · 5a15e73 · 2.7.0+cu128 (cuda) | 1.99.0 | **ran 14, ALL DEMOS PASSED** (08 trains on `device Cuda(0)`) |
| `linux-arm64-cpu-test` | `583cfb456b0a53122c92f18644601128f571f7b8e296ce405534932927703cfb` | 222aabae · 5a15e73 · none | 1.99.0 | **ran 10, ALL DEMOS PASSED** under qemu in `arm64v8/debian:bookworm-slim` (same four skips); 12-ecc=19, 13-pauliprop=9, 14-logical=15 |
| `linux-riscv-cpu-test` | `588cc0389db6de42edab94d1595e380df9c1efbb336220f6f43b90e374585a8d` | 222aabae · 5a15e73 · none | 1.99.0 | **ran 10, ALL DEMOS PASSED** under qemu in `riscv64/debian:sid-slim` (same four skips); 12-ecc=19, 13-pauliprop=9, 14-logical=15 |

**Two quantum revisions, one omega revision, one toolchain.** Every bundle
embeds the **Aria Quantum OSS 2.0.0** simulator backends (omega `5a15e73`)
and was compiled with rustc 1.99.0 (b940084d7 2026-09-28). The mac pair is at
quantum `174f7242`; the four Linux bundles are at `222aabae`, which differs
from `174f7242` only in the release scripts — it is the commit that fixed the
cross-build defect described next, so the arm64/riscv bundles *had* to be
rebuilt at it, and the amd64 pair was rebuilt alongside so every Linux
`run.sh` carries the same self-check.

**Every bundle is sha-reproducible and its limits are proven from the
binaries.** `MANIFEST.txt` carries `source_date_epoch` (the commit time) and
`timebomb: absolute unix=1801440000` (expires 2027-02-01T00:00:00Z); a second
build after a forced `build.rs` re-run gave the same tarball sha256 (probed on
mac-metal, linux-amd64-cpu and linux-arm64-cpu). The bundled `run.sh` and
`verify-dist.sh` additionally read the build stamp and expiry back out of the
server's `ping` reply and have the shipped CLI refuse a 13-qubit circuit, so
"qubit-capped, expires 2027-02-01" is checked against the binary, not against
this file. That check exists because the previous arm64 bundle (`8426b18`,
and a never-shipped `174f7242` one) was **uncapped**: `cross` does not forward
the build environment into its container, `build.rs` never saw the pins, and
the binary accepted 13 qubits and expired on its own +90-day clock while
`TEST-BUILD.txt` said otherwise. Native builds (mac, linux-amd64) were never
affected.

**Running demos 06–08 needs libtorch at run time too, not only in the
bundle.** Each bundle above carries `bin/quantum-finance`, but it links
libtorch dynamically. On Linux, `export LIBTORCH=<libtorch dir>` is enough;
setting only `LD_LIBRARY_PATH` is not. On macOS, export **both** `LIBTORCH`
and `DYLD_LIBRARY_PATH="$LIBTORCH/lib"`. Without them the three demos print
"(skip) this demo needs the libtorch runtime" even when libtorch is installed
and the binary is present.

The `quantum`/`quantum-server`/`quantum-client` CLIs are libtorch-free and
portable, and every bundle carries the full simulator set — `quantum ecc` and
`quantum expect` run live, so the surface-code (12), Pauli-propagation (13) and
transversal-QEC (14) demos execute rather than skipping. The `linux-amd64`
bundles are built natively on the x86-64 Linux machine and both now include
`quantum-finance`, so demos 06–08 (QML/finance) run on Linux too, given a
libtorch 2.7.0 runtime on the host (the cu128 download below serves both the
cpu and the gpu bundle). The `linux-arm64` and `linux-riscv` bundles are
cross-built and have no `quantum-finance` (libtorch is native-only); everything
else in them, including the simulator backends, is the same code.

The **gpu** bundle's QML/finance demos additionally need an NVIDIA driver and
the **cu128 libtorch 2.7.0** runtime on the host:

    curl -LO https://download.pytorch.org/libtorch/cu128/libtorch-cxx11-abi-shared-with-deps-2.7.0%2Bcu128.zip
    unzip -q libtorch-*.zip && export LIBTORCH="$(pwd)/libtorch"
    ../demo/run-all.sh        # demos 06-08 now run; demo 08 checks `device Cuda(0)`

These binaries are fully self-contained: `run.sh` and the demos drive the bundled
`quantum-client` binary directly, so **no python/jq/nc is needed on the host** —
verified end-to-end in stock Debian containers with no packages, at `222aabae`:
`linux-amd64-cpu-test` in `debian:bookworm-slim`, `linux-arm64-cpu-test` in
`arm64v8/debian:bookworm-slim` and `linux-riscv-cpu-test` in
`riscv64/debian:sid-slim` (the latter two under qemu user emulation on the
x86-64 build box) each give `ran 10`, `ALL DEMOS PASSED`, with the four named
skips a bare container must take (03 needs cargo; 06–08 need a libtorch
runtime). glibc floors, from the binaries: amd64 2.35, arm64 2.18, riscv 2.27.