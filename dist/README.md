# Evaluation bundles (per platform)

Each `quantum-dist-<platform>-test-*.tar.gz` is a time-limited, qubit-capped
evaluation build (see ../LICENSE). Extract one and point the demos at it:

    tar xzf quantum-dist-<platform>-test-*.tar.gz
    export QUANTUM_DIST="$(pwd)/dist-<platform>-test"
    ../demo/run-all.sh

Provided here: macOS Apple-Silicon (`mac-cpu-test`, incl. QML/finance), Linux
x86-64 (`linux-amd64-cpu-test`) and Linux arm64 (`linux-arm64-cpu-test`) — the
two Linux bundles are reproducibly cross-built (the `quantum`/`quantum-server`/
`quantum-client` CLIs are libtorch-free and portable). The Linux x86-64 **+CUDA**
and **RISC-V** bundles are produced on their respective build machines.

These binaries are fully self-contained: `run.sh` and the demos drive the bundled
`quantum-client` binary directly, so **no python/jq/nc is needed on the host** —
verified end-to-end in a stock `debian:bookworm-slim` container with no packages.
