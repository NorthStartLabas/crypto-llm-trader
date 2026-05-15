# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A thin wrapper around [Freqtrade 2024.9](https://github.com/freqtrade/freqtrade) (pinned). All trading logic runs inside Freqtrade; this repo contributes config, scripts, strategies, and custom Hyperopt loss functions mounted into the container via `./user_data → /freqtrade/user_data`. The Freqtrade image is never forked or patched.

Currently in **Phase 1.3** (strategy iteration + Hyperopt). Dry-run and backtest only — no live trading.

## Core workflow commands

Every script runs `scripts/check_safety.sh` first. All must pass before any operation continues.

```bash
# One-time setup
bash scripts/setup.sh

# Static safety checks (fast, no Docker)
bash scripts/check_safety.sh

# Download 365 days of OHLCV data from Binance (fast — no --dl-trades needed)
DAYS=365 bash scripts/download_data.sh

# Backtest (full data range by default)
bash scripts/backtest.sh

# Backtest a specific window
TIMERANGE=20260101- bash scripts/backtest.sh

# Hyperopt (500 epochs, MinTradesSharpeHyperOptLoss, full year)
bash scripts/hyperopt.sh

# Hyperopt with overrides
EPOCHS=1000 LOSS=SortinoHyperOptLoss bash scripts/hyperopt.sh

# Start dry-run paper trading (foreground)
bash scripts/run_dry.sh

# Start in background / stop
docker compose up -d
docker compose down
docker compose logs -f freqtrade
```

## Two-config architecture

There are two configs with distinct purposes — do not confuse them:

| Config | Exchange | Pairs | Used for |
|---|---|---|---|
| `config.kraken.dryrun.json` | Kraken | BTC/USD, ETH/USD | Dry-run (paper trading), safety checks |
| `config.binance.download.json` | Binance | 30 USDT pairs (static list) | Data download + backtesting |

**Why Binance for backtesting:** Kraken requires `--dl-trades` (raw trade download + local resampling) which takes hours for 365 days. Binance serves OHLCV candles directly; 30 pairs download in ~2 minutes. BTC/USDT ≈ BTC/USD for strategy validation purposes. Live trading on Kraken is unchanged.

**`check_safety.sh` always validates `config.kraken.dryrun.json`**, not the Binance config. This is intentional — the Kraken config is the one that controls the live bot.

## Pair list gotcha

`VolumePairList` **does not work with `download-data` or `backtesting`** — it requires a live bot context to query ticker volumes. Use `StaticPairList` in the Binance config. The download script passes `--pairs` explicitly with a hardcoded top-30 list for the same reason.

## Strategy patterns

Strategies live in `user_data/strategies/`. Key conventions:

- Use `talib.abstract` (not `talib` directly) — matches how indicators are imported across the codebase.
- Hyperopt parameters use `IntParameter` / `BooleanParameter` from `freqtrade.strategy`. Access via `.value` inside `populate_*` methods.
- EMA periods are **not** hyperopt parameters — recomputing them per trial is expensive. Only thresholds (RSI levels, exit enable flags) are tuned.
- Exit signals use **separate `dataframe.loc` blocks with distinct tags** (e.g. `rsi_overbought`, `ema_cross`) so backtest results show per-exit performance.
- `startup_candle_count = 200` — set to the longest EMA period used.

```python
# Correct hyperopt parameter pattern
buy_rsi_entry = IntParameter(20, 55, default=40, space="buy", optimize=True)

def populate_entry_trend(self, dataframe, metadata):
    dataframe.loc[
        (dataframe["rsi"] > self.buy_rsi_entry.value),  # use .value
        ["enter_long", "enter_tag"],
    ] = [1, "my_tag"]
```

## Custom Hyperopt loss function

`user_data/hyperopts/MinTradesSharpeHyperOptLoss.py` — Sharpe ratio with a hard floor of 30 trades. Any trial below the floor scores 999.0. Use this (not `SharpeHyperOptLoss`) to prevent Hyperopt from finding degenerate "hold forever, 10 trades" solutions. It's the default in `scripts/hyperopt.sh`.

## Secrets and environment

Freqtrade reads `FREQTRADE__<section>__<key>` env vars and overrides matching JSON config fields. All secrets live in `.env` only — JSON configs contain `change_me` placeholders. The `docker-compose.yml` passes these through via `env_file: .env`. Never put real keys in the JSON configs.

## Safety gates

`check_safety.sh` enforces 11 checks including: `DRY_RUN=true` in `.env`, `"dry_run": true` in config, `trading_mode: spot`, API server bound to `127.0.0.1`, exchange keys empty in config, `.env` not git-tracked. All scripts call it at startup and abort on failure.

## Roadmap (current state)

```
[✅] Phase 0   Docker + Freqtrade environment
[✅] Phase 0.5 Safety hardening
[🔄] Phase 1   Strategy iteration + Hyperopt (active)
[  ] FreqUI    Web dashboard (before dry-run)
[  ] Dry-run   Paper trading on Kraken
[  ] Phase 2   FreqAI (ML strategies)
[  ] Phase 3   LLM signal layer (features only, no order access)
[  ] Phase 4   Controlled live pilot
```

## Reference strategies

`vendor/freqtrade-strategies/` is a git submodule of the official community repo — for reference and learning only. No code from it is imported or run directly. Always independently backtest any logic taken from there.

## Freqtrade image

Pinned to `freqtradeorg/freqtrade:2024.9` in `docker-compose.yml`. Never point back to `stable` — the pin is intentional for reproducibility. To upgrade: check the release notes for breaking config changes, update the tag, run `docker compose pull`, then re-run `check_safety.sh` and `validate_config.sh`.
