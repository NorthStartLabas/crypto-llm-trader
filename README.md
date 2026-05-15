# crypto-llm-trader

An automated crypto trading research platform built on top of [Freqtrade](https://www.freqtrade.io/).

> **Phase 1.3 — Strategy iteration, Hyperopt, and pipeline hardening.**
> Dry-run and backtest only. No live trading. No real API keys required.
> FreqAI is planned for Phase 2. LLM signal layer is planned for Phase 3.

---

## Goals

1. Wrap Freqtrade in a reproducible Docker Compose setup.
2. Validate the full pipeline: data download → backtest → Hyperopt → paper trading.
3. Gradually introduce ML-based strategies via FreqAI (future phase).
4. Experiment with LLM-assisted signal generation as features only (future phase — no direct order access).

## Safety-first approach

- `DRY_RUN=true` is enforced by `scripts/run_dry.sh` and `scripts/check_safety.sh`.
- No real API keys are committed or required for any Phase 0–1 operation.
- All sensitive values live in `.env` only, via the `FREQTRADE__` env var mechanism.
- The API server is bound to `127.0.0.1` only — never exposed publicly.
- Live trading requires an explicit opt-in that is not implemented yet.
- **Backtesting and Hyperopt come before dry-run.** Do not start paper trading without reviewing results.

---

## Stack

| Component | Role |
|---|---|
| [Freqtrade 2024.9](https://github.com/freqtrade/freqtrade) | Core trading engine (pinned version) |
| Binance | Data source for backtesting (fast OHLCV, no API key needed) |
| Kraken | Target exchange for dry-run and live trading (spot only) |
| Docker Compose | Reproducible runtime |
| [freqtrade-strategies](https://github.com/freqtrade/freqtrade-strategies) | Reference/learning only (git submodule in `vendor/`) |
| FreqAI *(Phase 2, future)* | ML strategy experiments |
| LLM signal layer *(Phase 3, future)* | Feature generation only — no order access |

---

## Quick start

### Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- `bash`, `git`

### 1. Clone with submodule

```bash
git clone --recurse-submodules <this-repo>
cd crypto-llm-trader
```

If you already cloned without the flag:
```bash
git submodule update --init --recursive
```

### 2. Set up

```bash
bash scripts/setup.sh
```

Edit `.env`: change every `change_me` value before proceeding.

### 3. Run safety checks

```bash
bash scripts/check_safety.sh
```

All checks must pass.

### 4. Download historical data

```bash
DAYS=365 bash scripts/download_data.sh
```

Downloads 365 days of 1h OHLCV data from Binance (public API, no key needed) for 30 top USDT pairs. Takes ~2 minutes. Data is stored in `user_data/data/binance/`.

### 5. Run the backtest

```bash
bash scripts/backtest.sh
```

Review results before proceeding. See `docs/strategy-baseline.md` for what to look for.

### 6. Run Hyperopt (optional but recommended)

```bash
bash scripts/hyperopt.sh
```

Searches 500 parameter combinations. After completion, validate with:

```bash
bash scripts/backtest.sh
```

### 7. Start dry-run

```bash
bash scripts/run_dry.sh
```

FreqUI is available at <http://127.0.0.1:8080> once the container is healthy.

---

## Project layout

```
crypto-llm-trader/
  CLAUDE.md                                # Claude Code guidance for this repo
  docker-compose.yml                       # Freqtrade service (image: 2024.9)
  .env.example                             # Template — copy to .env
  vendor/
    freqtrade-strategies/                  # Reference only — do not import blindly
  user_data/
    configs/
      config.kraken.dryrun.json            # Kraken config — dry-run + safety checks
      config.binance.download.json         # Binance config — backtesting + data download
    strategies/
      DryRunPlaceholder.py                 # Fallback no-op strategy
      BaselineRsiEmaStrategy.py            # Phase 1.3 strategy (RSI + EMA, Hyperopt-ready)
      BaselineRsiEmaStrategy.json          # Best Hyperopt params (auto-saved by freqtrade)
    hyperopts/
      MinTradesSharpeHyperOptLoss.py       # Custom loss: Sharpe with 30-trade floor
    data/                                  # Downloaded OHLCV data (git-ignored)
    logs/                                  # Runtime logs (git-ignored)
    backtest_results/                      # Backtest output (git-ignored)
    hyperopt_results/                      # Hyperopt output (git-ignored)
    freqaimodels/                          # FreqAI model files (git-ignored, Phase 2+)
  scripts/
    setup.sh                               # First-time setup
    check_safety.sh                        # Static safety checks (11-point battery)
    download_data.sh                       # Download OHLCV data from Binance
    backtest.sh                            # Run backtest against downloaded data
    hyperopt.sh                            # Run Hyperopt parameter search
    run_dry.sh                             # Start paper trading on Kraken
    validate_config.sh                     # Safety checks + Freqtrade config parse
    list_kraken_markets.sh                 # Validate Kraken pair symbols
  docs/
    architecture.md                        # System design and config split rationale
    phases.md                              # Roadmap — current state and next steps
    operations.md                          # Day-to-day commands and runbook
    strategy-baseline.md                   # Strategy logic and Hyperopt documentation
```

---

## Two-config design

Data download and backtesting use **Binance** (`config.binance.download.json`), while dry-run and live trading use **Kraken** (`config.kraken.dryrun.json`). Binance is used for data because Kraken requires raw trade download (`--dl-trades`) which takes hours for 365 days; Binance serves OHLCV candles directly and completes in minutes. The Kraken config is unchanged for live operation. See `docs/architecture.md` for full rationale.

---

## Reference strategies

`vendor/freqtrade-strategies` is the official community strategies repository, included as a **git submodule for reference and learning only**. No code from it is imported or run directly. Independently backtest and review any logic before using it.

---

## Documentation

- [Architecture](docs/architecture.md)
- [Phases & Roadmap](docs/phases.md)
- [Strategy Documentation](docs/strategy-baseline.md)
- [Operations & Runbook](docs/operations.md)
