# Strategy: BaselineRsiEmaStrategy

> **Not financial advice. Not production-ready.**
> This strategy exists to iterate toward a profitable signal, not to be used with real funds.
> Do not start live trading without independent review, proper risk sizing, and monitoring.

---

## Current version: Phase 1.3

### What changed from Phase 1.1

| | Phase 1.1 | Phase 1.3 |
|---|---|---|
| Entry trend filter | `close > EMA200` | `close > EMA50` |
| RSI entry level | 35 | 40 (Hyperopt-tunable) |
| Exit — RSI | `RSI > 70` as combined exit | Separate tag: `rsi_overbought` |
| Exit — trend | `close < EMA50` (immediate, fires on any dip) | EMA20 crosses below EMA50 (crossover only) |
| EMA cross exit | Always on | Hyperopt-controlled (`BooleanParameter`) |
| Hyperopt | Not set up | Full parameter search via `scripts/hyperopt.sh` |
| Pairs | BTC/USD, ETH/USD (Kraken) | 30 USDT pairs (Binance, for backtesting) |

**Why EMA50 instead of EMA200:** During the 2025 bear market, BTC and ETH spent most of the year
below EMA200. The EMA200 filter blocked nearly all entries, producing 1 trade in 356 days. EMA50
is a less restrictive trend filter that still avoids buying into the steepest downtrends.

**Why the EMA cross exit is disabled by Hyperopt:** The original `close < EMA50` exit fired
immediately after entry on any small pullback, cutting winners short. The EMA20/EMA50 crossover
version is better but Hyperopt still disables it — in a bear market, the crossover fires constantly.
Exits are now handled primarily by ROI tiers and the hard stoploss.

---

## Indicators

| Indicator | Period | Purpose |
|---|---|---|
| EMA200 | 200 | Computed but not currently used in entry logic — kept for future regime filter |
| EMA50 | 50 | Entry trend filter — only go long when price is above this |
| EMA20 | 20 | Fast EMA — used for optional exit crossover signal |
| RSI | 14 | Momentum oscillator — entry on oversold recovery crossover |

`startup_candle_count = 200` to ensure EMA200 is valid before signals fire.

---

## Entry logic

All conditions must be true simultaneously:

1. **`close > EMA50`** — medium-term uptrend filter. Avoids entering during sustained downtrends.

2. **RSI crossed above `buy_rsi_entry`** (default 40, Hyperopt range 20–55) — RSI was ≤ threshold
   on the previous candle and is > threshold now. Targets the *first bar of recovery* from oversold.

3. **`volume > 0`** — data sanity check.

---

## Exit logic

Two separate exit conditions, each with its own tag for backtest analysis:

**Exit 1 — `rsi_overbought`:**
RSI > `sell_rsi_exit` (default 70, Hyperopt range 60–90). Takes profit before an overbought
reversal. Hyperopt tends to push this toward 82–90, meaning it rarely fires — most exits happen
via ROI.

**Exit 2 — `ema_cross`** (controlled by `sell_ema_cross_enabled`):
EMA20 crosses below EMA50. Only fires on the crossover candle, not on every candle where EMA20
is below EMA50. **Hyperopt consistently disables this** — in bear markets, EMA crossovers fire
too frequently and cut trades at losses.

**Also exits via:**
- **Minimal ROI** — stepped profit targets (tuned by Hyperopt's `roi` space)
- **Hard stoploss** — fixed percentage below entry (tuned by Hyperopt's `stoploss` space)

---

## Hyperopt parameters

| Parameter | Space | Default | Range | Notes |
|---|---|---|---|---|
| `buy_rsi_entry` | buy | 40 | 20–55 | RSI crossover level for entry |
| `sell_rsi_exit` | sell | 70 | 60–90 | RSI overbought exit threshold |
| `sell_ema_cross_enabled` | sell | True | True/False | Hyperopt disables this in bear markets |
| `minimal_roi` | roi | stepped | — | Full table searched by Hyperopt |
| `stoploss` | stoploss | -0.05 | auto | Searched by Hyperopt |

Best parameters are saved automatically to `user_data/strategies/BaselineRsiEmaStrategy.json`
after each Hyperopt run and loaded automatically on the next backtest.

---

## Hyperopt findings (Phase 1.3)

Two full Hyperopt runs were completed. Key conclusions:

1. **EMA cross exit is net-negative** — Hyperopt disables it in every run.
2. **Wide stoploss (-20% to -27%) wins** — Hyperopt extends the stop to avoid getting shaken out
   of trades during volatile bounces. This is risky in a real sustained downtrend.
3. **High RSI exit (82–90) wins** — the strategy holds trades until ROI triggers rather than
   exiting on RSI overbought.
4. **Fundamental problem:** The best result across 500 epochs on the full year still showed
   negative Sharpe (-2.48% total profit). A long-only RSI crossover cannot be parameter-tuned
   to profitability in a -51% bear market. The entry signal finds real bounces but the market
   direction overwhelms the edge.

---

## Known weaknesses and next steps

1. **No market regime filter** — the strategy enters long regardless of the broader market trend.
   A BTC/200-day MA regime filter would make the strategy inactive (correctly) during bear markets
   rather than fighting the trend.

2. **Long-only in a bear market** — the 2025 dataset showed -51% market movement. Any long-only
   strategy will underperform in this regime regardless of tuning.

3. **Exit logic relies on ROI tiers** — after disabling the EMA cross exit, the strategy holds
   trades until a profit target or stoploss. In a ranging market this works; in a sharp downtrend
   the stoploss carries all the weight.

4. **Small sample size** — 187 trades over a year is meaningful but out-of-sample validation
   (Hyperopt-never-seen data) only produced 10 trades over 4.5 months. More data and longer
   out-of-sample windows are needed.

**Next step (Phase 1.4):** Add a BTC-based regime filter to disable entries during bear markets,
OR build a second strategy (EMA crossover or mean reversion) designed to work across market regimes.
See `docs/phases.md` for options.

---

## Reference strategies

`vendor/freqtrade-strategies/` is a git submodule of the official community repo — for reference
and learning only. No code from it is imported or used directly. Always independently backtest
any logic taken from there.
