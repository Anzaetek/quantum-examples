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
| `linux-arm64-cpu-test` | Linux arm64 | core CLIs, **live `ecc`/`expect`**, **+ QML/finance on CPU** (built natively on an arm64 Linux container; needs the aarch64 libtorch 2.7.0 runtime on the host, see below) |
| `linux-riscv-cpu-test` | Linux RISC-V 64 | core CLIs, **live `ecc`/`expect`** (cross-built; no `quantum-finance`) |
| `linux-amd64-gpu-test` | Linux x86-64 + NVIDIA | core CLIs, live `ecc`/`expect`, **+ QML/finance with CUDA** — `quantum-finance` links `libtorch_cuda.so`, `--device cuda` trains on `Cuda(0)` |

### Provenance (five bundles at `983cff39`, refreshed 2026-10-19; riscv64 at `222aabae`, 2026-10-18)

Each bundle's `MANIFEST.txt` records its own `git_sha`, `omega_sha`,
`libtorch` and `rustc`; the table repeats them. "Tour" is `../demo/run-all.sh`
with `DEMO_REQUIRE_ALL=1`, judged on its per-demo verdict lines.

| Bundle | sha256 | quantum · omega · libtorch | rustc | Tour |
|---|---|---|---|---|
| `mac-cpu-test` | `b9af7741ec09fc1f00250a99f81625e5897075b64b643edbfba556c35d99d503` | 983cff39 · 5a15e73 · 2.7.0 (cpu) | 1.99.0 | **ran 16, skipped 0, ALL DEMOS PASSED**; `pin:` OK |
| `mac-metal-test` | `3eeb09f73d50cb93996e4057e4c80f753faf6253cc2e46294e34e2715a5bbfd8` | 983cff39 · 5a15e73 · 2.7.0 (metal) | 1.99.0 | **ran 16, skipped 0, ALL DEMOS PASSED**; `pin:` OK; `regime-classify train --model dnn --device metal` prints `device Mps`, val_acc `0.9412` |
| `linux-amd64-cpu-test` | `8b5e3dd0dea32f72d59adb4104165f619203605a304c2e0e09ec5a046391a7b3` | 983cff39 · 5a15e73 · 2.7.0+cu128 (cpu) | 1.99.0 | **ran 15, ALL DEMOS PASSED** with the host libtorch (skips only 08, whose GPU step wants `nvidia-smi`+cuda bundle); `pin:` OK; **ran 10** in a stock `debian:bookworm-slim` container (03 needs cargo; 06–08, 15, 16 need libtorch) |
| `linux-amd64-gpu-test` | `e9a6b326e4fa25a102562b803a51ae58cb2ead474fc35bc39a7b3f7e6c556666` | 983cff39 · 5a15e73 · 2.7.0+cu128 (cuda) | 1.99.0 | **ran 16, skipped 0, ALL DEMOS PASSED** (08 trains on `device Cuda(0)`); `pin:` OK |
| `linux-arm64-cpu-test` | `3b6ae3cacd1acc7114d776187c4222644335cab3b1c4a5a29470f2dff40997c6` | 983cff39 · 5a15e73 · 2.7.0 (cpu, aarch64) | 1.99.0 | **ran 16, skipped 0, ALL DEMOS PASSED** natively on arm64 Linux (colima/vz on Apple M4, `rust:1.99.0-slim-bookworm`); `pin:` OK |
| `linux-riscv-cpu-test` | `588cc0389db6de42edab94d1595e380df9c1efbb336220f6f43b90e374585a8d` | 222aabae · 5a15e73 · none | 1.99.0 | **ran 10, ALL DEMOS PASSED** under qemu in `riscv64/debian:sid-slim` (03 needs cargo; 06–08, 15, 16 need libtorch, which is not available for riscv64); no data pin (predates it) |

**Two quantum revisions, one omega revision, one toolchain.** Every bundle
embeds the **Aria Quantum OSS 2.0.0** simulator backends (omega `5a15e73`)
and was compiled with rustc 1.99.0 (b940084d7 2026-09-28). Five bundles are at
quantum `983cff39` — the data-pin revision (demo 16): the mac pair and the
native linux-arm64 bundle were built on the Apple-Silicon box, the linux-amd64
pair on the x86-64 Linux box, all with the same `SOURCE_DATE_EPOCH=1792242886`
and expiry pins. The riscv64 bundle stays at `222aabae` (the cross-build fix
revision): it has no `quantum-finance` and therefore nothing to pin, and the
code it does ship is unchanged between the two revisions.

**Every bundle is sha-reproducible and its limits are proven from the
binaries.** `MANIFEST.txt` carries `source_date_epoch` (the commit time) and
`timebomb: absolute unix=1801440000` (expires 2027-02-01T00:00:00Z); a second
build after a forced `build.rs` re-run gave the same tarball sha256 (probed at
`983cff39` on mac-metal, linux-amd64-cpu and linux-arm64-cpu). The bundled
`run.sh` and `verify-dist.sh` additionally read the build stamp and expiry back
out of the server's `ping` reply, have the shipped CLI refuse a 13-qubit
circuit, and (with `LIBTORCH` set) have `quantum-finance data-pin` refuse a
one-byte-different copy of the bundled series, so "qubit-capped, expires
2027-02-01, computes only on the shipped synthetic data" is checked against
the binary, not against this file. That check exists because the previous arm64 bundle (`8426b18`,
and a never-shipped `174f7242` one) was **uncapped**: `cross` does not forward
the build environment into its container, `build.rs` never saw the pins, and
the binary accepted 13 qubits and expired on its own +90-day clock while
`TEST-BUILD.txt` said otherwise. Native builds (mac, linux-amd64) were never
affected.

**Running demos 06–08, 15 and 16 needs libtorch at run time too, not only in
the bundle.** Each bundle above carries `bin/quantum-finance`, but it links
libtorch dynamically. On Linux, `export LIBTORCH=<libtorch dir>` is enough;
setting only `LD_LIBRARY_PATH` is not. On macOS, export **both** `LIBTORCH`
and `DYLD_LIBRARY_PATH="$LIBTORCH/lib"`. Without them the five demos print
"(skip) this demo needs the libtorch runtime" even when libtorch is installed
and the binary is present. On arm64 Linux the aarch64 libtorch comes from the
PyTorch wheel (`torch-2.7.0+cpu-…-manylinux_2_28_aarch64.whl`): unzip it,
point `LIBTORCH` at its `torch/` directory and put **both** `torch/lib` and the
wheel's `torch.libs/` (OpenBLAS, Arm Compute Library, gfortran, gomp) on
`LD_LIBRARY_PATH` — the linker does not follow the second hop by RPATH.

The `quantum`/`quantum-server`/`quantum-client` CLIs are libtorch-free and
portable, and every bundle carries the full simulator set — `quantum ecc` and
`quantum expect` run live, so the surface-code (12), Pauli-propagation (13) and
transversal-QEC (14) demos execute rather than skipping. The `linux-amd64`
bundles are built natively on the x86-64 Linux machine and the `linux-arm64`
bundle natively in an arm64 Linux container, so all three include
`quantum-finance` and demos 06–08, 15 and 16 (QML/finance/QAS/provenance) run
on Linux too, given a libtorch 2.7.0 runtime on the host (the cu128 download
below serves both amd64 bundles). The `linux-riscv` bundle is cross-built and
has no `quantum-finance` (there is no libtorch for riscv64); everything else
in it, including the simulator backends, is the same code.

The **gpu** bundle's QML/finance demos additionally need an NVIDIA driver and
the **cu128 libtorch 2.7.0** runtime on the host:

    curl -LO https://download.pytorch.org/libtorch/cu128/libtorch-cxx11-abi-shared-with-deps-2.7.0%2Bcu128.zip
    unzip -q libtorch-*.zip && export LIBTORCH="$(pwd)/libtorch"
    ../demo/run-all.sh        # demos 06-08 now run; demo 08 checks `device Cuda(0)`

These binaries are fully self-contained: `run.sh` and the demos drive the bundled
`quantum-client` binary directly, so **no python/jq/nc is needed on the host** —
verified end-to-end in stock Debian containers with no packages:
`linux-amd64-cpu-test` (`983cff39`) in `debian:bookworm-slim`, and at
`222aabae` `linux-arm64-cpu-test` in `arm64v8/debian:bookworm-slim` and
`linux-riscv-cpu-test` in `riscv64/debian:sid-slim` (the latter two under qemu
user emulation on the x86-64 build box) each give `ran 10`, `ALL DEMOS PASSED`,
with the six named skips a bare container must take (03 needs cargo; 06–08, 15,
16 need a libtorch runtime). glibc floors, from the binaries: amd64 2.35,
arm64 2.36 (native bookworm build; the earlier cross build floored at 2.18),
riscv 2.27.