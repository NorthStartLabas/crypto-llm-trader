# Architecture

## Overview

`crypto-llm-trader` is a thin wrapper around Freqtrade. All trading logic lives inside Freqtrade;
this project contributes configuration, operational scripts, custom strategies, and custom Hyperopt
loss functions mounted into the container at runtime.

```
┌─────────────────────────────────────────────────────────────┐
│  Host machine                                               │
│                                                             │
│  .env ──────────────────────────────────────────────────┐  │
│  user_data/ (mounted volume) ───────────────────────┐   │  │
│                                                     │   │  │
│  ┌──────────────────────────────────────────────────┼───┼─┐│
│  │  Docker Compose                                  │   │  ││
│  │                                                  │   │  ││
│  │  ┌─────────────────────────────────────────────┐ │   │  ││
│  │  │  freqtrade (freqtradeorg/freqtrade:2024.9)  │◄┘   │  ││
│  │  │                                             │◄────┘  ││
│  │  │  - strategy engine                          │        ││
│  │  │  - order management (dry-run)               │        ││
│  │  │  - REST API  ──► 127.0.0.1:8080             │        ││
│  │  │  - SQLite trade DB                          │        ││
│  │  └─────────────────────────────────────────────┘        ││
│  └──────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
         │
         │ CCXT (HTTP)
         ▼
    Kraken API (public endpoints only in dry-run)
```

## Key design decisions

### No upstream modifications
Freqtrade is consumed as a pre-built Docker image. We never fork or patch it. Custom strategies
and Hyperopt loss functions are dropped into `user_data/` and picked up at runtime.

### Mounted volume
`./user_data` on the host is mounted to `/freqtrade/user_data` inside the container. Configs,
strategies, logs, and Hyperopt results are all version-controllable (with appropriate gitignore
rules). The container is ephemeral; all persistent state is on the host.

### Two-config split

There are two configs with distinct purposes:

| Config | Exchange | Pairs | Used by |
|---|---|---|---|
| `config.kraken.dryrun.json` | Kraken | BTC/USD, ETH/USD | Dry-run, safety checks, `run_dry.sh` |
| `config.binance.download.json` | Binance | 30 USDT pairs | Data download, backtesting, Hyperopt |

**Why Binance for backtesting:** Kraken requires `--dl-trades` (download raw trades, resample
locally) because it does not expose a public OHLCV API. 365 days of two pairs on Kraken takes
5+ hours and is prone to timeouts. Binance serves OHLCV candles directly; 30 pairs download in
~2 minutes. BTC/USDT ≈ BTC/USD for strategy validation purposes.

**Why keep Kraken for dry-run:** Live trading targets Kraken (spot, no leverage). The dry-run
config mirrors exactly what a live config would look like.

**`check_safety.sh` always validates `config.kraken.dryrun.json`** — this is the config that
controls the live bot. The Binance config is not safety-checked because it is never used for
live trading.

### VolumePairList limitation
`VolumePairList` queries live exchange ticker data and cannot resolve pairs during
`download-data` or `backtesting`. Both commands require `StaticPairList`. The top-30 Binance
USDT pair list is hardcoded in `scripts/download_data.sh` and `config.binance.download.json`.
Update it periodically as market rankings shift.

### API server
The Freqtrade REST API is enabled and bound to `127.0.0.1:8080`. FreqUI (the official React
dashboard) connects to this endpoint. The port is never published to `0.0.0.0`.

### Dry-run enforcement
`dry_run: true` is set in the JSON config. `run_dry.sh` additionally checks the `.env` file and
refuses to start if `DRY_RUN` is not `true`. Belt-and-suspenders.

### Secrets injection
All exchange credentials and API server passwords live in `.env` only. Freqtrade reads
`FREQTRADE__<section>__<key>` env vars at startup and overrides the matching JSON config fields.
JSON configs contain only `change_me` placeholders. This keeps secrets out of version control
while still being compatible with Freqtrade's standard config format.

---

## Strategy architecture

```
user_data/strategies/
  BaselineRsiEmaStrategy.py     — active strategy (Phase 1.3)
  BaselineRsiEmaStrategy.json   — best Hyperopt params (auto-saved, auto-loaded)
  DryRunPlaceholder.py          — no-op fallback used in early phases

user_data/hyperopts/
  MinTradesSharpeHyperOptLoss.py — custom loss function (Sharpe + min-trade floor)
```

Strategies follow the Freqtrade `IStrategy` interface:
- `populate_indicators` — compute all technical indicators on the OHLCV dataframe
- `populate_entry_trend` — set `enter_long = 1` rows where entry conditions are met
- `populate_exit_trend` — set `exit_long = 1` rows where exit conditions are met

Hyperopt parameters (`IntParameter`, `BooleanParameter`) are class-level attributes.
Their `.value` property is accessed inside `populate_*` methods. Indicator periods are
**not** hyperopt parameters — recomputing EMAs per trial is expensive and thresholds
are what matter.

Exit signals use **separate `dataframe.loc` blocks with distinct tags** so backtest output
shows per-exit performance (e.g. `rsi_overbought` vs `ema_cross`).

---

## Future layers (not implemented yet)

```
Phase 2 — FreqAI
  user_data/freqaimodels/     ← trained model artifacts
  Custom strategy calling FreqAI prediction API internally

Phase 3 — LLM signal layer
  Optional sidecar service
  Writes signals to a shared file or lightweight queue
  FreqAI/strategy reads signals as features — no direct order execution by LLM

Phase 4 — Live trading
  Real Kraken API keys (IP-whitelisted, trade-only permissions)
  Hard daily loss limits at the exchange level
  Full monitoring runbook
```

The LLM layer will never place orders directly. It produces features that a deterministic
Freqtrade strategy uses to make entry/exit decisions.
