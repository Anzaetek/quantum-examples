# 16 — Data provenance: the eval binary is pinned to the series it ships with

The evaluation bundle limits **what** the binaries compute (12-qubit cap) and
**until when** (expiry). This demo shows the third limit, added 2026-10-19:
**which data** `bin/quantum-finance` computes on. The bundled synthetic daily
series is embedded in the binary at build time (`QUANTUM_TEST=1`, same switch
as the cap); at run time the binary accepts

* a **series** file only if its sha256 equals the embedded copy's — `xauusd`,
  `regime-gen`, and the in-memory label path of `regime-classify` /
  `arch-search` all go through this check;
* a **label file** (`--data`) only if it is byte-identical to what *this same
  binary's* `regime-gen` derives from the embedded series — regenerated on the
  spot (~0.3 s). No allow-list, no key, nothing to leak; a hand-edited label
  row is localised to its line and refused.

Refusals exit **3** and print both digests (or the first differing byte/line).
There is no runtime override. A source build has an empty pin and enforces
nothing — `data-pin` prints `pinned 0`, and this demo skips.

## What it runs (10 checks, ~5 s)

1. `data-pin` — `pinned 1`, `pin_sha256 d0d2e8ea…` (= `sha256sum demo/data/synthetic_daily.csv`), `pin_rows 5462`.
2. `data-pin --series <shipped>` — `series_match 1`.
3. One byte flipped in a copy: `xauusd` refuses (exit 3, "data pin", both
   digests), `data-pin --series` says `series_match 0`, `regime-gen` refuses.
4. `regime-gen` → label file → `data-pin --labels` says `labels_match 1`; one
   label changed on data row 100 → `labels_match 0`,
   `labels_first_diff_line 101`, exit 3; `regime-classify train --data` on it
   refuses (exit 3).
5. `data-pin --export` writes the embedded series back out, byte-identical to
   the shipped file.

## Why it matters

Every QML/finance number the bundle produces (demos 06–08, 15) is now
reproducible **and scoped**: it was computed on exactly this synthetic series,
and the eval binary cannot be pointed at a private dataset and have the result
attributed to the toolkit. The same property is checked by
`scripts/release/verify-dist.sh` (`pin:` line, next to `cap:` and `expiry:`)
on every shipped tarball.

Data is **synthetic** (see `../data/README.md`) — never real market data.
