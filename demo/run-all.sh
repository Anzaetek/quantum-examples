#!/usr/bin/env bash
# Run every customer demo against the binary-only dist. Numbers only.
#   export QUANTUM_DIST="$(ls -d /tmp/qdist/dist-*)" ; ./run-all.sh
#
# Each demo must end in a VERDICT, and the verdict has a SHAPE:
#   * any "✗" line                        -> the demo failed
#   * "OK — N check(s) passed"            -> N must be >= MIN[demo] (pinned below)
#   * "(skip)" (no OK line)               -> allowed ONLY for demos with a real
#                                            skip path, and only after PRESKIP[demo] ✓
#   * neither                             -> failed ("ended without a verdict")
# "ALL DEMOS PASSED" used to mean "no script returned non-zero" — a demo whose
# checks silently stopped running, or a skip on a host that could have run it,
# still printed it. Now the banner is preceded by the ran/skipped roll-call and
# a demo that loses checks (N below its pin) fails the run.
# DEMO_REQUIRE_ALL=1 turns every skip into a failure (hosts that have cargo +
# libtorch + a native bundle, i.e. the CI boxes, run all 14 live).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Minimum "OK — N" per demo when it runs to completion (mac + Linux/CUDA,
# 2026-08-29). 08 reports 3 on a CUDA host (extra GPU-DNN check); the floor is
# the CPU shape. Raising a demo's check count is fine; losing one is a failure.
# 14 reports 15 against a binary built from HEAD and 13 against an older dist
# (its §5d needs `logical precision --method circuit`, added 2026-09-03, and
# skips without it) — so the floor STAYS 13 rather than tracking the new count.
# (case functions, not `declare -A`: macOS ships bash 3.2 and customers run
# this with it.)
min_checks() {
    case "$1" in
        01-bell) echo 6 ;;  02-qft) echo 3 ;;   03-rust-harness) echo 1 ;;
        04-qos) echo 3 ;;   05-optimizer) echo 4 ;; 06-finance) echo 5 ;;
        07-qml-qcbm) echo 2 ;; 08-qml-classifier) echo 2 ;; 09-mbqc) echo 4 ;;
        10-ubqc) echo 2 ;;  11-lean4) echo 5 ;;  12-ecc) echo 19 ;;
        13-pauliprop) echo 9 ;; 14-logical) echo 13 ;;
        *) echo "run-all.sh: no pinned check count for $1" >&2; exit 2 ;;
    esac
}
# Demos allowed to "(skip)", with the number of ✓ that must land BEFORE the
# skip: 03 needs cargo (no toolchain on customer hosts); 06/07/08 need the
# libtorch runtime + bin/quantum-finance (07/08 still prove the untrained
# Lean-export refusal first); 12/13/14 need a native bundle (ecc/expect/
# logical are inert in a cross-built core-CLI bundle; 13 proves Aria→Lean first).
# Prints nothing for demos that have no skip path.
preskip_checks() {
    case "$1" in
        03-rust-harness|06-finance|12-ecc|14-logical) echo 0 ;;
        07-qml-qcbm|08-qml-classifier|13-pauliprop) echo 1 ;;
    esac
}

RC=0; RAN=(); SKIPPED=(); FAILED=()
for d in 01-bell/inspect.sh 02-qft/inspect.sh 03-rust-harness/run.sh 04-qos/run.sh \
         05-optimizer/inspect.sh 06-finance/run.sh 07-qml-qcbm/run.sh 08-qml-classifier/run.sh \
         09-mbqc/run.sh 10-ubqc/run.sh 11-lean4/run.sh 12-ecc/run.sh 13-pauliprop/run.sh \
         14-logical/run.sh; do
    name="${d%%/*}"
    echo; echo "════════════════════════════════════════════════════════════"
    out="$(bash "$HERE/$d" 2>&1)"; rc=$?
    printf '%s\n' "$out"
    plain="$(printf '%s\n' "$out" | sed 's/\x1b\[[0-9;]*m//g')"
    nbad=$(printf '%s\n' "$plain" | grep -c '^  ✗')
    nok=$(printf '%s\n' "$plain" | grep -c '^  ✓')
    n=$(printf '%s\n' "$plain" | sed -n 's/^OK — \([0-9][0-9]*\) check(s) passed$/\1/p' | tail -1)
    verdict=""
    if [ "$rc" -ne 0 ] || [ "$nbad" -ne 0 ]; then
        verdict="FAILED (rc=$rc, ${nbad} ✗)"
    elif printf '%s\n' "$plain" | grep -q '(skip)'; then
        pre="$(preskip_checks "$name")"
        if [ -z "$pre" ]; then
            verdict="FAILED (skipped, but $name has no skip path)"
        elif [ "$nok" -lt "$pre" ]; then
            verdict="FAILED (skipped after $nok ✓, expected ≥ $pre before the skip)"
        elif [ "${DEMO_REQUIRE_ALL:-0}" = "1" ]; then
            verdict="FAILED (skipped, DEMO_REQUIRE_ALL=1)"
        else
            SKIPPED+=("$name"); echo "  ⊘ $name skipped ($nok ✓ before the skip)"
        fi
    elif [ -z "$n" ]; then
        verdict="FAILED (ended without a verdict: no 'OK — N check(s) passed' line)"
    elif [ "$n" -lt "$(min_checks "$name")" ]; then
        verdict="FAILED (shape drift: OK — $n, pinned minimum $(min_checks "$name"))"
    else
        RAN+=("$name=$n")
    fi
    if [ -n "$verdict" ]; then
        echo "  ✗ $name $verdict"; FAILED+=("$name"); RC=1
    fi
done
echo; echo "════════════════════════════════════════════════════════════"
echo "ran ${#RAN[@]}: ${RAN[*]:-}"
echo "skipped ${#SKIPPED[@]}: ${SKIPPED[*]:-none}"
[ "${#FAILED[@]}" -gt 0 ] && echo "failed ${#FAILED[@]}: ${FAILED[*]}"
[ "$RC" = 0 ] && echo "ALL DEMOS PASSED" || { echo "SOME DEMOS FAILED"; exit 1; }
