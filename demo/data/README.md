# ⚠️ SYNTHETIC DATA — not real market data

`synthetic_daily.csv` is a **fake instrument ("SYNX")**, used only so the public demos have
something to chew on. It was produced by [`make-synthetic.sh`](make-synthetic.sh):

1. take a real daily OHLCV series,
2. **rescale** every price to an index starting at ~100 (so the magnitude reveals nothing about the
   underlying instrument — it is *not* ~4000, *not* any recognisable asset level), and
3. add small deterministic per-bar multiplicative noise (so the path is not the real one).

It is **not** real market data and must **not** be used for research, modelling, or trading — it
exists purely to demonstrate the toolkit's finance/QML pipelines end-to-end with reproducible
numbers. Regenerate with:

```bash
./make-synthetic.sh <your_real_input.csv> synthetic_daily.csv
```

Schema (semicolon-separated): `Date;Open;High;Low;Close;Adj_Close;Volume`. Deterministic
(fixed seed) ⇒ stable golden numbers in demos `06` and `08`.
