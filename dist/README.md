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
| `linux-arm64-cpu-test` | Linux arm64 | core CLIs, **live `ecc`/`expect`** |
| `linux-amd64-gpu-test` | Linux x86-64 + NVIDIA | core CLIs, live `ecc`/`expect`, **+ QML/finance with CUDA** — `quantum-finance` links `libtorch_cuda.so`, `--device cuda` trains on `Cuda(0)` |

### Provenance (linux-amd64 pair refreshed 2026-10-17; mac pair 2026-10-06)

Each bundle's `MANIFEST.txt` records its own `git_sha`, `omega_sha`,
`libtorch` and `rustc`; the table repeats them. "Tour" is `../demo/run-all.sh`
with `DEMO_REQUIRE_ALL=1`, judged on its per-demo verdict lines.

| Bundle | sha256 | quantum · omega · libtorch | rustc | Tour |
|---|---|---|---|---|
| `mac-cpu-test` | `55a139ad7b21ae733df551f0cdd7869f2640f71330a4afdb94725de4063fbd27` | 174f7242 · 5a15e73 · 2.7.0 (cpu) | 1.99.0 | **ran 14, ALL DEMOS PASSED** |
| `mac-metal-test` | `81e50b8c12a9f374c87551468eb4e56087c39a136548889d7329dfd46a75260f` | 174f7242 · 5a15e73 · 2.7.0 (metal) | 1.99.0 | **ran 14, ALL DEMOS PASSED**; `regime-classify train --model dnn --device metal` prints `device Mps` |
| `linux-amd64-cpu-test` | `760d2294bb37de8f9e76247fbe324efa48ffd9d265098b145effce98b2d93bc5` | 174f7242 · 5a15e73 · 2.7.0+cu128 (cpu) | 1.99.0 | ran 13, every pin met (12-ecc=19, 13-pauliprop=9, 14-logical=15). Demo 08 takes its named skip ("binary reports CPU") because the test host has a GPU; on a GPU-less host it runs. |
| `linux-amd64-gpu-test` | `0da137272df2b7f750d8e5df6e7d0e8199565b62dbfdaa6d5c49cc4c5bd4c480` | 174f7242 · 5a15e73 · 2.7.0+cu128 (cuda) | 1.99.0 | **ran 14, ALL DEMOS PASSED** (08 trains on `device Cuda(0)`) |
| `linux-arm64-cpu-test` | `d5f04a118bf6a10fe14ec9916369cd18160a532a83a84a6103256bf9857e4a0a` (unchanged) | **8426b18** · — · none | — | **Older revision, not refreshed.** It cannot be executed on the build host, so it was not toured. The same-revision amd64 bundle failed demos 07, 08, 11 and 13 against the current `demo/` (those checks need a newer binary), so expect the same here. |

**Two source revisions, one toolchain.** The linux-amd64 pair is at
(174f7242, 5a15e73): the omega simulator backends compiled in are the
**Aria Quantum OSS 2.0.0** crates. The mac pair is still at (231b7c4, ed146b4)
and will move when it is next rebuilt on the mac box. Every bundle was
compiled with rustc 1.99.0 (b940084d7 2026-09-28).

The linux-amd64 pair is **sha-reproducible**: `MANIFEST.txt` carries
`source_date_epoch: 1792242886` (the commit time) and
`timebomb: absolute unix=1801440000` (expires 2027-02-01T00:00:00Z), and a
second build from the same inputs after a forced `build.rs` re-run gave the
same tarball sha256. The 231b7c4 Linux bundles they replace carried a
`relative +90d` timebomb and were not reproducible across build-script
re-runs. The 231b7c4 mac pair is still relative.

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
cpu and the gpu bundle). The `linux-arm64` bundle is cross-built, has no
`quantum-finance`, and is at an older revision (see Provenance).

The **gpu** bundle's QML/finance demos additionally need an NVIDIA driver and
the **cu128 libtorch 2.7.0** runtime on the host:

    curl -LO https://download.pytorch.org/libtorch/cu128/libtorch-cxx11-abi-shared-with-deps-2.7.0%2Bcu128.zip
    unzip -q libtorch-*.zip && export LIBTORCH="$(pwd)/libtorch"
    ../demo/run-all.sh        # demos 06-08 now run; demo 08 checks `device Cuda(0)`

The **RISC-V** bundle is produced on its own build machine and is still pending.

These binaries are fully self-contained: `run.sh` and the demos drive the bundled
`quantum-client` binary directly, so **no python/jq/nc is needed on the host** —
verified end-to-end in a stock `debian:bookworm-slim` container with no packages:
`linux-amd64-cpu-test` at 174f7242 gives `ran 10`, `ALL DEMOS PASSED`, with the
four named skips that a bare container must take (03 needs cargo; 06–08 need a
libtorch runtime). The `linux/arm64` run of the same check was measured on the
older 8426b18 bundle and has not been repeated.