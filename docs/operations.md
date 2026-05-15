# Operations

## Starting and stopping

```bash
# First-time setup
bash scripts/setup.sh

# Run static safety checks (fast, no Docker needed)
bash scripts/check_safety.sh

# Validate config (safety checks + freqtrade show-config)
bash scripts/validate_config.sh

# Start dry-run (foreground, Ctrl+C to stop) — run backtest first
bash scripts/run_dry.sh

# Start in background
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f freqtrade
# or: tail -f user_data/logs/freqtrade.log
```

---

## Data download

Data is downloaded from **Binance** (not Kraken). Binance serves OHLCV candles directly;
Kraken requires raw trade resampling which takes hours. Live trading on Kraken is unaffected.

```bash
# Download 365 days of 1h data for 30 top USDT pairs (recommended)
DAYS=365 bash scripts/download_data.sh

# Download a shorter window (faster, for quick iteration)
DAYS=90 bash scripts/download_data.sh

# Different timeframe
TIMEFRAME=4h DAYS=365 bash scripts/download_data.sh
```

Data is stored in `user_data/data/binance/`. Download takes ~2 minutes for 30 pairs.

**Updating the pair list:** The 30 pairs are hardcoded in `scripts/download_data.sh` (as `PAIRS=(...)`)
because `VolumePairList` cannot resolve pairs at download time. Update that list periodically
as market rankings shift.

---

## Backtesting

```bash
# Backtest using all available downloaded data
bash scripts/backtest.sh

# Backtest a specific time window
TIMERANGE=20260101- bash scripts/backtest.sh
TIMERANGE=20250601-20260101 bash scripts/backtest.sh

# Backtest a different strategy
STRATEGY=MyOtherStrategy bash scripts/backtest.sh
```

Backtest results are saved to `user_data/backtest_results/` as JSON files.
The backtest uses `config.binance.download.json` (30 USDT pairs, StaticPairList).

**Acceptance criteria before dry-run:**
- ≥ 50 trades over the backtest period
- Max drawdown < 20%
- Sharpe ratio > 0.5
- Results validated on an out-of-sample window (data Hyperopt never saw)

---

## Hyperopt

```bash
# Run with defaults (500 epochs, MinTradesSharpeHyperOptLoss, full year)
bash scripts/hyperopt.sh

# More epochs for a wider search (slower, better results)
EPOCHS=1000 bash scripts/hyperopt.sh

# Different loss function
LOSS=SortinoHyperOptLoss bash scripts/hyperopt.sh
LOSS=CalmarHyperOptLoss bash scripts/hyperopt.sh

# Specific time window
TIMERANGE=20250601-20260101 bash scripts/hyperopt.sh

# Tune only specific spaces
SPACES="buy sell" bash scripts/hyperopt.sh
```

**Available loss functions:**
| Function | Use when |
|---|---|
| `MinTradesSharpeHyperOptLoss` | Default — Sharpe with 30-trade floor (prevents degenerate solutions) |
| `SharpeHyperOptLoss` | Standard Sharpe (no trade floor) |
| `SortinoHyperOptLoss` | Penalises downside volatility more than Sharpe |
| `CalmarHyperOptLoss` | Balances CAGR against max drawdown |
| `OnlyProfitHyperOptLoss` | Raw profit only — overfits easily, avoid |

Best parameters are auto-saved to `user_data/strategies/<StrategyName>.json` and loaded
automatically on the next backtest or dry-run run.

**After Hyperopt:** always validate on an out-of-sample window:
```bash
TIMERANGE=<period-hyperopt-never-saw>- bash scripts/backtest.sh
```

---

## Kraken pair validation

Freqtrade uses CCXT pair notation (`BTC/USD`). Kraken sometimes uses non-standard symbols
(`XBT/USD` instead of `BTC/USD`). Validate before first dry-run:

```bash
bash scripts/list_kraken_markets.sh
```

Update `pair_whitelist` in `user_data/configs/config.kraken.dryrun.json` with the exact
symbols shown.

---

## Accessing FreqUI

With the container running, open <http://127.0.0.1:8080> in your browser.

Credentials are set in `.env` via the `FREQTRADE__api_server__*` variables.
The `.env.example` defaults are placeholders — change them before running.

---

## Secrets and environment variables

Freqtrade reads `FREQTRADE__<section>__<key>` env vars and overrides matching JSON config fields.
All secrets live in `.env` only — JSON configs contain `change_me` placeholders.

| `.env` variable | Overrides config field |
|---|---|
| `FREQTRADE__api_server__username` | `api_server.username` |
| `FREQTRADE__api_server__password` | `api_server.password` |
| `FREQTRADE__api_server__jwt_secret_key` | `api_server.jwt_secret_key` |
| `FREQTRADE__api_server__ws_token` | `api_server.ws_token` |
| `FREQTRADE__exchange__key` | `exchange.key` |
| `FREQTRADE__exchange__secret` | `exchange.secret` |

---

## Safety rules

- `DRY_RUN=true` must be in `.env` — `run_dry.sh` and `check_safety.sh` both enforce this
- Leave exchange key/secret empty for dry-run — not needed, increases risk surface
- `listen_ip_address` must stay `127.0.0.1` — never change to `0.0.0.0`
- Never commit `.env` — it is gitignored and `check_safety.sh` verifies this
- The SQLite trade database (`user_data/tradesv3.sqlite`) is local only — back it up manually

---

## Useful raw Freqtrade commands

```bash
# List available strategies
docker compose run --rm freqtrade list-strategies \
  --config /freqtrade/user_data/configs/config.binance.download.json

# Show current open trades
docker compose run --rm freqtrade show-trades \
  --db-url sqlite:////freqtrade/user_data/tradesv3.sqlite

# Show best Hyperopt results from a saved file
docker compose run --rm freqtrade hyperopt-show \
  --config /freqtrade/user_data/configs/config.binance.download.json \
  --best

# Validate pair symbols on Kraken
bash scripts/list_kraken_markets.sh
```

---

## Upgrading Freqtrade

The image is pinned to `2024.9` in `docker-compose.yml`. To upgrade:

1. Check [Freqtrade releases](https://github.com/freqtrade/freqtrade/releases) for breaking config changes.
2. Update the image tag in `docker-compose.yml`.
3. Pull and restart: `docker compose pull && docker compose up -d`
4. Run `bash scripts/check_safety.sh` and `bash scripts/validate_config.sh`.

Never revert to `stable` — the explicit version tag is intentional for reproducibility.
