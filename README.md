# crypto-llm-trader

An automated crypto trading research platform built on top of [Freqtrade](https://www.freqtrade.io/).

> **Phase 0.5 — Validation and hardening complete.**
> No live trading. No real API keys required. Dry-run mode only.
> FreqAI is planned for Phase 2. LLM signal layer is planned for Phase 3 and will never place orders directly.

---

## Goals

1. Wrap Freqtrade in a reproducible Docker Compose setup.
2. Iterate on strategies using backtesting and paper trading.
3. Gradually introduce ML-based strategies via FreqAI (future phase).
4. Experiment with LLM-assisted signal generation as features only (future phase — no direct order access).

## Safety-first approach

- `DRY_RUN=true` is the default and is enforced by `scripts/run_dry.sh` and `scripts/check_safety.sh`.
- No real API keys are committed or required for any Phase 0/0.5 operation.
- All sensitive values (API server credentials, exchange keys) live in `.env` only, passed to
  Freqtrade via the `FREQTRADE__` environment variable mechanism — never in the JSON config.
- The API server is bound to `127.0.0.1` only — never exposed publicly.
- Live trading requires an explicit, deliberate opt-in that is not implemented yet.
- Kraken pair names must be validated before first run (`bash scripts/list_kraken_markets.sh`).

---

## Stack

| Component | Role |
|---|---|
| [Freqtrade 2024.9](https://github.com/freqtrade/freqtrade) | Core trading engine (pinned version) |
| [FreqUI](https://github.com/freqtrade/frequi) | Local web dashboard (via API server) |
| Kraken | Target exchange (spot only) |
| Docker Compose | Reproducible runtime |
| FreqAI *(Phase 2, future)* | ML strategy experiments |
| LLM signal layer *(Phase 3, future)* | Feature generation only — no order access |

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

### 2. Edit `.env`

Open `.env` and change every `change_me` value:
- `FREQTRADE__api_server__password` — password for FreqUI login
- `FREQTRADE__api_server__jwt_secret_key` — long random string
- `DRY_RUN=true` — must remain `true`
- Exchange keys — leave empty for dry-run

### 3. Run safety checks

```bash
bash scripts/check_safety.sh
```

All checks must pass before proceeding.

### 4. Validate Kraken pair names

Freqtrade uses CCXT notation. Kraken sometimes lists pairs as `XBT/USD` rather than `BTC/USD`.
Always confirm the exact symbols:

```bash
bash scripts/list_kraken_markets.sh
```

Update `pair_whitelist` in `user_data/configs/config.kraken.dryrun.json` if the symbols differ.

### 5. Validate config

```bash
bash scripts/validate_config.sh
```

### 6. Start dry-run

```bash
bash scripts/run_dry.sh
```

FreqUI is available at <http://127.0.0.1:8080> once the container is healthy.

---

## Project layout

```
crypto-llm-trader/
  docker-compose.yml               # Freqtrade service (image pinned to 2024.9)
  .env.example                     # Template — copy to .env
  .gitignore
  user_data/
    configs/
      config.kraken.dryrun.json    # Main config (dry-run, spot, Kraken)
    strategies/                    # Custom strategy files go here (Phase 1+)
    data/                          # Downloaded OHLCV data (git-ignored)
    logs/                          # Runtime logs (git-ignored)
    backtest_results/              # Backtest output (git-ignored)
    freqaimodels/                  # FreqAI model files (git-ignored, Phase 2+)
  scripts/
    setup.sh                       # First-time setup
    check_safety.sh                # Static safety checks (run before anything else)
    list_kraken_markets.sh         # Validate Kraken pair symbols
    validate_config.sh             # Safety checks + Freqtrade config validation
    run_dry.sh                     # Start paper trading (enforces dry-run)
    download_data.sh               # OHLCV data download (Phase 1 placeholder)
    backtest.sh                    # Backtesting runner (Phase 1 placeholder)
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
