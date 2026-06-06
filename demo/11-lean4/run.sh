#!/usr/bin/env bash
# Demo 11 — Lean 4 target extraction. Export Aria quantum models to Lean 4
# theorem files (with proof obligations), straight from the binary-only dist.
. "$(cd "$(dirname "$0")/.." && pwd)/common.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

say "== Demo 11: Aria → Lean 4 theorem extraction =="
note "dist: $QUANTUM_DIST_ROOT  ·  models: bundled examples/aria/"

extract() { # <aria> <instantiate> [--mbqc]
    local aria="$1" inst="$2"; shift 2
    local out; out="$(mktemp -d)"
    "$QBIN" spec extract --aria "$ARIA/$aria" --instantiate "$inst" --out "$out" "$@" >/dev/null 2>&1
    if ls "$out"/*.lean >/dev/null 2>&1; then
        local files lines
        files="$(ls "$out"/*.lean | xargs -n1 basename | tr '\n' ' ')"
        lines="$(cat "$out"/*.lean | wc -l | tr -d ' ')"
        ok "$inst → $files($lines lines)"
    else bad "$inst extraction"; fi
    rm -rf "$out"
}

say "\nExtract several models to Lean 4 theorem files:"
extract bell.aria            "Bell()"
extract qft.aria             "QFT(n=3)"
extract qcbm_strongly_entangling.aria "QcbmStronglyEntangling(N=4,L=2)"
extract qml_classifier.aria  "QMLClassifier(L=3)"

say "\nWith the MBQC pattern certificate (--mbqc emits a native_decide proof):"
extract bell.aria "Bell()" --mbqc

note "\nEach .lean carries the circuit + its proof obligations (e.g. denote(QFT)=DFT,"
note "Bell creates (|00>+|11>)/sqrt2) — the toolkit proves models, not just runs them."
finish
