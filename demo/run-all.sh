#!/usr/bin/env bash
# Run every customer demo against the binary-only dist. Numbers only.
#   export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)" ; ./run-all.sh
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RC=0
for d in 01-bell/inspect.sh 02-qft/inspect.sh 03-rust-harness/run.sh 04-qos/run.sh \
         05-optimizer/inspect.sh 06-finance/run.sh 07-qml-qcbm/run.sh 08-qml-classifier/run.sh \
         09-mbqc/run.sh 10-ubqc/run.sh 11-lean4/run.sh 12-ecc/run.sh 13-pauliprop/run.sh; do
    echo; echo "════════════════════════════════════════════════════════════"
    bash "$HERE/$d" || RC=1
done
echo; echo "════════════════════════════════════════════════════════════"
[ "$RC" = 0 ] && echo "ALL DEMOS PASSED" || { echo "SOME DEMOS FAILED"; exit 1; }
