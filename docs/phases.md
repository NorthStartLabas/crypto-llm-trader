# Phases & Roadmap

Each phase builds on the previous one. A phase is only started after the previous phase is
validated (backtested, reviewed, and deliberately approved).

---

## Phase 0 — Repository foundation [ACTIVE]

**Goal:** Reproducible Freqtrade environment with no custom logic.

Deliverables:
- Docker Compose wrapping `freqtradeorg/freqtrade:stable`
- `user_data/` volume with configs, strategies, data, logs
- Dry-run config for Kraken spot
- Operational scripts (setup, validate, run)
- Documentation skeleton

Exit criteria:
- `bash scripts/run_dry.sh` starts the bot in dry-run
- FreqUI accessible at `127.0.0.1:8080`
- No real API keys required
- All data directories exist and are gitignored

---

## Phase 1 — Strategy baseline [NOT STARTED]

**Goal:** Implement and backtest a minimal classical strategy.

Planned work:
- Download historical OHLCV data via `scripts/download_data.sh`
- Port or write a simple RSI/EMA strategy into `user_data/strategies/`
- Run `scripts/backtest.sh` and review results
- Add `freqtrade hyperopt` support for parameter tuning
- Review [freqtrade-strategies](https://github.com/freqtrade/freqtrade-strategies) for reference

Exit criteria:
- At least one custom strategy backtested over 90 days of Kraken data
- Documented Sharpe ratio, max drawdown, win rate in backtest results
- Strategy passes `validate_config.sh`

---

## Phase 2 — FreqAI integration [NOT STARTED]

**Goal:** Replace hand-coded indicator logic with an ML model via FreqAI.

Planned work:
- Enable FreqAI in config
- Train an initial LightGBM or CatBoost model on the Phase 1 feature set
- Compare ML strategy performance against baseline via backtest
- Store trained models in `user_data/freqaimodels/`

Exit criteria:
- FreqAI strategy backtests without errors
- Model retraining is reproducible

---

## Phase 3 — LLM signal layer [NOT STARTED]

**Goal:** Introduce LLM-generated market signals as additional features for FreqAI.

Planned work:
- Define a sidecar service that produces a JSON signal file
- LLM reads news or on-chain data and outputs a sentiment score
- FreqAI strategy ingests the signal as an extra feature column
- LLM never places orders — it only contributes features

Safety requirement: The LLM is sandboxed behind the feature pipeline. It has no access to the
exchange API and cannot trigger trades.

---

## Phase 4 — Controlled live pilot [NOT STARTED]

**Goal:** Move a small allocation to live trading after Phase 3 is validated.

Requirements before starting:
- Written sign-off that dry-run performance justifies live risk
- Real Kraken API keys with IP-whitelisted, trade-only permissions
- Hard daily loss limit enforced at the exchange level
- Runbook for emergency stop

This phase is deliberately not detailed yet to avoid premature implementation.
