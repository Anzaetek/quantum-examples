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
| `linux-amd64-cpu-test` | Linux x86-64 | core CLIs, **live `ecc`/`expect`** |
| `linux-arm64-cpu-test` | Linux arm64 | core CLIs, **live `ecc`/`expect`** |
| `linux-amd64-gpu-test` | Linux x86-64 + NVIDIA | core CLIs, live `ecc`/`expect`, **+ QML/finance with CUDA** — `quantum-finance` links `libtorch_cuda.so`, `--device cuda` trains on `Cuda(0)` |

> **The four CPU bundles above are pinned to the same source revision.** The
> `linux-amd64-gpu` bundle is older: a CUDA build has to be produced on the
> NVIDIA machine (libtorch is a native C++ library and cannot be cross-linked),
> so it is refreshed on its own cycle. Everything it demonstrates is also in
> `linux-amd64-cpu` except the CUDA training path.

The `quantum`/`quantum-server`/`quantum-client` CLIs are libtorch-free and
portable. Both Linux CPU bundles are **cross-built and reproducible**, and they
now carry the full simulator set — `quantum ecc` and `quantum expect` run live
on Linux, so the surface-code (12), Pauli-propagation (13) and transversal-QEC
(14) demos all execute rather than skipping. Demos 06–08 (QML/finance) still
need a paired libtorch runtime, which is why they run on the macOS and GPU
bundles only.

The **gpu** bundle's QML/finance demos additionally need an NVIDIA driver and
the **cu128 libtorch 2.7.0** runtime on the host:

    curl -LO https://download.pytorch.org/libtorch/cu128/libtorch-cxx11-abi-shared-with-deps-2.7.0%2Bcu128.zip
    unzip -q libtorch-*.zip && export LIBTORCH="$(pwd)/libtorch"
    ../demo/run-all.sh        # demos 06-08 now run; demo 08 checks `device Cuda(0)`

The **RISC-V** bundle is produced on its own build machine and is still pending.

These binaries are fully self-contained: `run.sh` and the demos drive the bundled
`quantum-client` binary directly, so **no python/jq/nc is needed on the host** —
verified end-to-end in a stock `debian:bookworm-slim` container with no packages,
on both `linux/amd64` and `linux/arm64`.
