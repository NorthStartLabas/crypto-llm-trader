# Phases & Roadmap

Each phase builds on the previous one. A phase is only started after the previous phase is
validated (backtested, reviewed, and deliberately approved).

---

## Phase 0 — Repository foundation [DONE ✅]

Reproducible Freqtrade environment with no custom logic. Docker Compose wrapping
`freqtradeorg/freqtrade:2024.9`, `user_data/` volume, dry-run config for Kraken spot,
operational scripts, documentation skeleton.

---

## Phase 0.5 — Validation and hardening [DONE ✅]

Pinned Docker image, `FREQTRADE__` env var mechanism for all secrets, `check_safety.sh`
(11-point static battery), `list_kraken_markets.sh`, `run_dry.sh` with safety gate,
`validate_config.sh` using `show-config`, resolved `SampleStrategy` naming collision →
`DryRunPlaceholder`.

---

## Phase 1.1 — Baseline strategy and backtesting pipeline [DONE ✅]

`BaselineRsiEmaStrategy` v1 (RSI + EMA200, long-only spot). Download and backtest scripts.
Pipeline validated end-to-end: download → backtest → results file.

**Key finding:** EMA200 filter blocked nearly all entries during the 2025 bear market.
With only 2 pairs, the backtest produced 1 trade over 356 days — not a strategy failure
but a data/market regime mismatch that needed fixing.

---

## Phase 1.2 — Data pipeline rework [DONE ✅]

Switched data source from Kraken to Binance to fix chronic download timeouts.

- Kraken requires `--dl-trades` (raw trade resampling) — 365 days took 5+ hours and timed out.
- Binance serves OHLCV candles directly — 365 days of 30 pairs downloads in ~2 minutes.
- Pairs switched from `BTC/USD, ETH/USD` to top 30 Binance USDT pairs (static whitelist).
- Added `config.binance.download.json` for data/backtest; Kraken config unchanged for live use.
- `VolumePairList` cannot be used for `download-data` or `backtesting` — requires a live bot
  context. `StaticPairList` with an explicit 30-pair list is used instead.

---

## Phase 1.3 — Strategy iteration and Hyperopt [DONE ✅ / findings below]

Improved strategy to generate enough trades for meaningful backtesting, then ran Hyperopt.

**Strategy changes (v1.2 → v1.3):**
- Entry trend filter: EMA200 → EMA50 (EMA200 blocked entries in the 2025 bear market)
- RSI entry level: 35 → 40 (crossover still used; wider level fires more often)
- Exit: split into two separate tags (`rsi_overbought`, `ema_cross`) for per-exit analysis
- EMA cross exit: made optional via `BooleanParameter` — Hyperopt consistently disables it
- All key thresholds exposed as `IntParameter`/`BooleanParameter` for Hyperopt

**Custom loss function:** `MinTradesSharpeHyperOptLoss` — Sharpe ratio with hard floor of
30 trades. Prevents Hyperopt from finding degenerate "hold forever, 10 trades" solutions.

**Hyperopt findings (500 epochs, full year, 30-pair universe):**
- Best result: 187 trades, -2.48% total profit, negative Sharpe
- Hyperopt consistently chooses: disable EMA cross exit, RSI exit at 90 (rarely fires),
  wide stoploss (-26%), and large ROI tiers (hold for up to 75 days)
- **Root cause:** A long-only RSI crossover strategy cannot be tuned to profitability
  in a sustained bear market (-51% over the in-sample period). The Hyperopt is finding
  the least-bad parameters, not a profitable edge.

**Conclusion:** The entry signal (RSI crossover + EMA50 filter) finds real bounces but
cannot overcome a -51% downtrend. Strategy design must change before dry-run.

---

## Phase 1.4 — Strategy redesign and validation [NEXT]

**Goal:** Develop strategies that are robust across market regimes, not just in bull runs.

### Option A — Market regime filter (quick fix)
Add a BTC-based regime filter to `BaselineRsiEmaStrategy`: refuse all entries when
BTC is below its 200-day MA (sustained downtrend). Prevents entering long during bear markets.
This does not make the strategy profitable in bear markets — it makes it *inactive*, which is
correct behaviour for a long-only system.

### Option B — Second strategy: EMA crossover
A pure EMA20/EMA50 crossover strategy with no RSI. Entry: EMA20 crosses above EMA50.
Exit: EMA20 crosses below EMA50. Simpler, more trades, works across more market conditions.
Backtest on both the current dataset and a historical bull market period (2023–2024).

### Option C — Mean reversion strategy
Designed for choppy/ranging markets. Enter when price deviates significantly from a
moving average (Bollinger Bands). Profits from volatility without needing a directional trend.

**Acceptance criteria before moving to Phase 2:**
- At least one strategy with Sharpe > 0.5 and max drawdown < 20% over 90+ out-of-sample days
- At least 50 out-of-sample trades for statistical meaningfulness
- Results validated on a period Hyperopt has never seen

---

## FreqUI — Web dashboard [BEFORE DRY-RUN]

Set up FreqUI (the official Freqtrade React dashboard) before starting any dry-run.
Without it, monitoring paper trades requires reading logs manually.

FreqUI connects to the API server already enabled at `127.0.0.1:8080`. Setup requires
adding the FreqUI service to `docker-compose.yml` or running `freqtrade install-ui`.

---

## Dry-run on Kraken [AFTER PHASE 1.4 + FREQUI]

Paper trading with real market data, no real money. Requires:
- At least one strategy passing Phase 1.4 acceptance criteria
- FreqUI running for trade monitoring
- Kraken pair names validated (`bash scripts/list_kraken_markets.sh`)
- At least 2 weeks of dry-run before any live consideration

---

## More strategies + ongoing iteration [PARALLEL WITH DRY-RUN]

While dry-run runs, develop additional strategies for comparison:
- Each strategy gets its own `.py` file and its own Hyperopt run
- Compare strategies in backtest before switching dry-run to a new one
- A well-tested strategy beats several mediocre ones — quality over quantity

---

## Phase 2 — FreqAI integration [NOT STARTED]

Replace hand-coded indicator logic with an ML model via FreqAI. Train an initial
LightGBM or CatBoost model on the Phase 1 feature set. Compare ML strategy vs baseline.
Requires solid classical strategies working first — FreqAI needs meaningful features
to learn from, not just noise.

---

## Phase 3 — LLM signal layer [NOT STARTED]

LLM-generated market signals as additional features for FreqAI. The LLM is sandboxed
behind the feature pipeline — it has no exchange API access and cannot trigger trades.

---

## Phase 4 — Controlled live pilot [NOT STARTED]

Requirements before starting:
- Written sign-off that dry-run performance justifies live risk
- Real Kraken API keys with IP-whitelisted, trade-only permissions
- Hard daily loss limit enforced at the exchange level
- Runbook for emergency stop

This phase is deliberately not detailed yet.
