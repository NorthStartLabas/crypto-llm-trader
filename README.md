# crypto-llm-trader

An automated crypto trading research platform built on top of [Freqtrade](https://www.freqtrade.io/).

> **Phase 0 — Repository foundation only.**
> No live trading. No real API keys. Dry-run mode by default.

---

## Goals

1. Wrap Freqtrade in a reproducible Docker Compose setup.
2. Iterate on strategies using backtesting and paper trading.
3. Gradually introduce ML-based strategies via FreqAI (future phase).
4. Experiment with LLM-assisted signal generation (future phase).

## Safety-first approach

- `DRY_RUN=true` is the hardcoded default and is enforced by `scripts/run_dry.sh`.
- No real API keys are committed or required for any Phase 0 operation.
- The API server is bound to `127.0.0.1` only — never exposed publicly.
- Live trading requires an explicit, deliberate opt-in that is not implemented yet.

---

## Stack

| Component | Role |
|---|---|
| [Freqtrade](https://github.com/freqtrade/freqtrade) | Core trading engine |
| [FreqUI](https://github.com/freqtrade/frequi) | Local web dashboard (via API server) |
| Kraken | Target exchange (spot only) |
| Docker Compose | Reproducible runtime |
| FreqAI *(future)* | ML strategy experiments |

---

## Quick start

### Prerequisites

- Docker Desktop (or Docker Engine + Compose plugin)
- `bash`

### 1. Clone and set up

```bash
git clone <this-repo>
cd crypto-llm-trader
bash scripts/setup.sh
```

`setup.sh` creates the `user_data` directories and copies `.env.example` → `.env`.

### 2. Review `.env`

Open `.env` and confirm:
- `DRY_RUN=true`
- API credentials are set to safe placeholder values
- Exchange API keys are blank (not needed for dry-run)

### 3. Validate Kraken pair names

Freqtrade uses CCXT pair notation. Verify that the pairs in the config exist on Kraken:

```bash
docker compose run --rm freqtrade list-markets --exchange kraken
```

> The config ships with `BTC/USD` and `ETH/USD`. Some Kraken pairs use `XBT` instead of `BTC` —
> confirm the exact symbols before running.

### 4. Start dry-run

```bash
bash scripts/run_dry.sh
```

FreqUI is available at <http://127.0.0.1:8080> once the container is healthy.

---

## Project layout

```
crypto-llm-trader/
  docker-compose.yml          # Freqtrade service definition
  .env.example                # Template — copy to .env
  .gitignore
  user_data/
    configs/
      config.kraken.dryrun.json   # Main config (dry-run, spot, Kraken)
    strategies/               # Custom strategy files go here
    data/                     # Downloaded OHLCV data (git-ignored)
    logs/                     # Runtime logs (git-ignored)
    backtest_results/         # Backtest output (git-ignored)
    freqaimodels/             # FreqAI model files (git-ignored, future)
  scripts/
    setup.sh                  # First-time setup
    validate_config.sh        # Config validation via Docker
    download_data.sh          # OHLCV data download (Phase 1)
    backtest.sh               # Backtesting runner (Phase 1)
    run_dry.sh                # Start paper trading
  docs/
    architecture.md
    phases.md
    operations.md
```

---

## Documentation

- [Architecture](docs/architecture.md)
- [Phases & Roadmap](docs/phases.md)
- [Operations & Safety](docs/operations.md)
