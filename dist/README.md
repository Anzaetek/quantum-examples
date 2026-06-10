# Evaluation bundles (per platform)

Each `quantum-dist-<platform>-test-*.tar.gz` is a time-limited, qubit-capped
evaluation build (see ../LICENSE). Extract one and point the demos at it:

    tar xzf quantum-dist-<platform>-test-*.tar.gz
    export QUANTUM_DIST="$(pwd)/dist-<platform>-test"
    ../demo/run-all.sh

Provided here:

| Bundle | Platform | Contents |
|---|---|---|
| `mac-cpu-test` | macOS Apple-Silicon | core CLIs **+ QML/finance** |
| `linux-amd64-cpu-test` | Linux x86-64 | core CLIs, live `ecc`/`expect` backends (built natively on the Linux box) |
| `linux-amd64-gpu-test` | Linux x86-64 + NVIDIA | core CLIs, live `ecc`/`expect`, **+ QML/finance with CUDA** — `quantum-finance` links `libtorch_cuda.so`, `--device cuda` trains on `Cuda(0)` |
| `linux-arm64-cpu-test` | Linux arm64 | core CLIs (reproducibly cross-built; `ecc`/`expect` inert) |

The `quantum`/`quantum-server`/`quantum-client` CLIs are libtorch-free and
portable. The **gpu** bundle's QML/finance demos (06–08) additionally need an
NVIDIA driver and the **cu128 libtorch 2.7.0** runtime on the host:

    curl -LO https://download.pytorch.org/libtorch/cu128/libtorch-cxx11-abi-shared-with-deps-2.7.0%2Bcu128.zip
    unzip -q libtorch-*.zip && export LIBTORCH="$(pwd)/libtorch"
    ../demo/run-all.sh        # demos 06-08 now run; demo 08 checks `device Cuda(0)`

The **RISC-V** bundle is produced on its own build machine and is still pending.

These binaries are fully self-contained: `run.sh` and the demos drive the bundled
`quantum-client` binary directly, so **no python/jq/nc is needed on the host** —
verified end-to-end in a stock `debian:bookworm-slim` container with no packages.
