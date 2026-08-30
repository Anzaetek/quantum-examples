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

refuse() { # <aria> <instantiate> <n_unbound> — untrained QML models must be REFUSED
    local aria="$1" inst="$2" n="$3"
    local out err rc; out="$(mktemp -d)"
    err="$("$QBIN" spec extract --aria "$ARIA/$aria" --instantiate "$inst" --out "$out" 2>&1 >/dev/null)"; rc=$?
    if [ "$rc" -ne 0 ] && echo "$err" | grep -q "$n parameter(s) have no bound numeric value: theta_0," \
       && ! ls "$out"/*.lean >/dev/null 2>&1; then
        ok "$inst → REFUSED ($n symbolic angles named, nothing written)"
    else bad "$inst must be refused (rc=$rc)"; fi
    rm -rf "$out"
}

say "\nExtract several models to Lean 4 theorem files:"
extract bell.aria            "Bell()"
extract qft.aria             "QFT(n=3)"

say "\nUntrained QML models carry symbolic angles: a theorem about them would be"
say "about the identity circuit, so the exporter refuses by name instead:"
refuse qcbm_strongly_entangling.aria "QcbmStronglyEntangling(N=4,L=2)" 24
refuse qml_classifier.aria  "QMLClassifier(L=3)" 9

say "\nWith the MBQC pattern certificate (--mbqc emits a native_decide proof):"
extract bell.aria "Bell()" --mbqc

note "\nEach .lean carries the circuit + its proof obligations (e.g. denote(QFT)=DFT,"
note "Bell creates (|00>+|11>)/sqrt2) — the toolkit proves models, not just runs them."
finish
