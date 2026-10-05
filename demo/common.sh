# Shared helpers for the customer demos. Source this from a demo's script:
#   . "$(dirname "$0")/../common.sh"
#
# Resolves the binary-only distribution via $QUANTUM_DIST (the extracted dist
# root, containing bin/quantum). Falls back to a freshly-built dist in the repo
# if present. Exits with guidance if neither is found.

set -uo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; BLUE='\033[0;34m'; DIM='\033[2m'; NC='\033[0m'

resolve_dist() {
    if [ -n "${QUANTUM_DIST:-}" ] && [ -x "${QUANTUM_DIST}/bin/quantum" ]; then
        echo "$QUANTUM_DIST"; return 0
    fi
    # Fallback: newest extracted dist under /tmp/qdist.
    #
    # `ls -dt`, not `ls -d`: without -t this sorted ALPHABETICALLY while the
    # comment promised "newest", so with two extracted bundles it silently
    # picked by name. Combined with a stale bundle that is the whole
    # wrong-artefact hazard — a run that answers for a sha nobody chose.
    local cand n
    n=$(ls -d /tmp/qdist/dist-* 2>/dev/null | wc -l)
    cand=$(ls -dt /tmp/qdist/dist-* 2>/dev/null | head -1)
    if [ -n "$cand" ] && [ -x "$cand/bin/quantum" ]; then
        # Ambiguity is reported, not resolved silently. The chosen bundle's
        # git_sha goes in the notice, not just the count: a sha is actionable
        # (you can tell at a glance whether it is the build you meant), a count
        # is not. Strictly the ambiguous case -- one candidate, or an explicit
        # QUANTUM_DIST, says nothing at all.
        if [ "$n" -gt 1 ]; then
            local csha
            csha=$(awk '/^git_sha:/{print $2}' "$cand/MANIFEST.txt" 2>/dev/null)
            echo "auto-selected newest of $n extracted dists: $cand (git_sha ${csha:-unknown})" >&2
            echo "  (set QUANTUM_DIST to choose explicitly)" >&2
        fi
        echo "$cand"; return 0
    fi
    echo "" ; return 1
}

QUANTUM_DIST_ROOT="$(resolve_dist)"
if [ -z "$QUANTUM_DIST_ROOT" ]; then
    echo -e "${RED}No distribution found.${NC} Build + extract one, then export QUANTUM_DIST:" >&2
    echo '  QUANTUM_DIST=1 ./scripts/release/build-dist.sh cpu' >&2
    echo '  mkdir -p /tmp/qdist && tar xzf dist/quantum-dist-*.tar.gz -C /tmp/qdist' >&2
    # `ls -dt ... | head -1`, not `ls -d ...`: in the very multi-bundle case
    # the picker above handles, the bare glob expands to SEVERAL paths and
    # this guidance would set a broken space-separated QUANTUM_DIST. The
    # instructions for setting it manually were wrong in exactly the scenario
    # that makes setting it manually necessary.
    echo '  export QUANTUM_DIST="$(ls -dt /tmp/qdist/dist-* | head -1)"' >&2
    exit 2
fi
QBIN="$QUANTUM_DIST_ROOT/bin/quantum"
QSERVER="$QUANTUM_DIST_ROOT/bin/quantum-server"
QF="$QUANTUM_DIST_ROOT/bin/quantum-finance"        # libtorch-linked (finance/QML)
ARIA="$QUANTUM_DIST_ROOT/examples/aria"            # bundled Aria models
# Public demos use SYNTHETIC data shipped with the demo (see data/README.md) —
# never real market data.
SYNTH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/data/synthetic_daily.csv"

# The finance/QML binary needs the libtorch RUNTIME (a shared library, not
# toolkit source). Point $LIBTORCH at it; macOS SIP strips DYLD on exec so we
# (re-)export here. require_libtorch() prints guidance + exits 0 (skip, never a
# hard fail) when libtorch isn't available — the core demos still run without it.
if [ -n "${LIBTORCH:-}" ] && [ -d "$LIBTORCH" ]; then
    export LIBTORCH_BYPASS_VERSION_CHECK=1
    case "$(uname -s)" in
        Darwin) export DYLD_LIBRARY_PATH="$LIBTORCH/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" ;;
        Linux)  export LD_LIBRARY_PATH="$LIBTORCH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
    esac
fi
require_libtorch() {
    if [ -x "$QF" ] && [ -n "${LIBTORCH:-}" ] && [ -d "$LIBTORCH" ]; then return 0; fi
    echo "  (skip) this demo needs the libtorch runtime + bin/quantum-finance." >&2
    echo "        install libtorch and: export LIBTORCH=/path/to/libtorch" >&2
    exit 0
}

say()  { echo -e "${BLUE}$*${NC}"; }
note() { echo -e "${DIM}$*${NC}"; }
PASS=0; FAIL=0
ok()   { echo -e "  ${GREEN}✓${NC} $*"; PASS=$((PASS+1)); }
bad()  { echo -e "  ${RED}✗${NC} $*"; FAIL=$((FAIL+1)); }
finish() { echo; if [ "$FAIL" = 0 ]; then echo -e "${GREEN}OK — $PASS check(s) passed${NC}"; else echo -e "${RED}$FAIL check(s) failed${NC}"; exit 1; fi; }
