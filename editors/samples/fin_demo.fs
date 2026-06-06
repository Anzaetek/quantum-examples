-- aria: fin
-- Finesmith dialect — same surface syntax as fin_demo.aria, .fs extension.

contract Forward {
    let S = spot("EURUSD")
    let K = 1.10
    let T = 2026-12-31

    cash_flow(S - K, "USD") |> on(T)
}

contract RangeAccrual {
    let r       = rate("EUR-6M")
    let lo      = 0.02
    let hi      = 0.05
    let n       = 1000000.0
    let coupon  = 0.04
    let period  = 2026-01-01..2026-12-31

    schedule period {
        cond(r >= lo and r <= hi,
             cash_flow(n * coupon, "EUR"),
             zero)
    }
}
