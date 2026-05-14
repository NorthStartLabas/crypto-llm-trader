# Operations

## Starting and stopping

```bash
# First-time setup
bash scripts/setup.sh

# Run static safety checks (fast, no Docker needed)
bash scripts/check_safety.sh

# Validate Kraken pair symbols (Docker required, no API key needed)
bash scripts/list_kraken_markets.sh

# Validate config (runs safety checks then freqtrade show-config to parse and resolve)
bash scripts/validate_config.sh

# Start dry-run (foreground, Ctrl+C to stop)
bash scripts/run_dry.sh

# Start in background
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f freqtrade
# or: tail -f user_data/logs/freqtrade.log
```

## Accessing FreqUI

With the container running, open <http://127.0.0.1:8080> in your browser.

Credentials are set in `.env` via the `FREQTRADE__api_server__*` variables.
The `.env.example` defaults are placeholders — change them before running.

## Checking available Kraken pairs

Freqtrade uses CCXT pair notation (`BTC/USD`, `ETH/USD`). Kraken sometimes uses
non-standard symbols (e.g. `XBT/USD` instead of `BTC/USD`). Always validate:

```bash
bash scripts/list_kraken_markets.sh
```

Update `pair_whitelist` in `user_data/configs/config.kraken.dryrun.json` with the
exact symbols shown by that command before running the bot for the first time.

---

## Secrets and environment variables

Freqtrade supports environment variable overrides using the `FREQTRADE__<section>__<key>`
naming convention. Any such variable set in the container environment takes precedence
over the matching field in the JSON config file.

All sensitive values in this project use this mechanism:

| .env variable | Overrides config field |
|---|---|
| `FREQTRADE__api_server__username` | `api_server.username` |
| `FREQTRADE__api_server__password` | `api_server.password` |
| `FREQTRADE__api_server__jwt_secret_key` | `api_server.jwt_secret_key` |
| `FREQTRADE__api_server__ws_token` | `api_server.ws_token` |
| `FREQTRADE__exchange__key` | `exchange.key` |
| `FREQTRADE__exchange__secret` | `exchange.secret` |

The JSON config contains only `change_me` placeholders. Real values live exclusively
in `.env`, which is gitignored.

---

## Safety warnings

### DRY_RUN must be true
`.env` must have `DRY_RUN=true`. `run_dry.sh` and `check_safety.sh` both enforce this.

### API keys are not needed for dry-run
Leave `FREQTRADE__exchange__key` and `FREQTRADE__exchange__secret` empty. Adding real
keys while in dry-run is unnecessary and increases risk surface.

### API server is localhost-only
`listen_ip_address` in the config is `127.0.0.1`. Do not change it to `0.0.0.0`.

### Do not commit .env
The `.gitignore` excludes `.env`. `check_safety.sh` also verifies this when run
inside a git repository.

### Database is not backed up automatically
The SQLite trade database (`user_data/tradesv3.sqlite`) is local only. Back it up
manually if the trade history matters.

---

## Useful Freqtrade commands (via Docker)

```bash
# List available strategies
docker compose run --rm freqtrade list-strategies \
  --config /freqtrade/user_data/configs/config.kraken.dryrun.json

# Show current open trades
docker compose run --rm freqtrade show-trades \
  --db-url sqlite:////freqtrade/user_data/tradesv3.sqlite

# Download data (Phase 1 — uncomment scripts/download_data.sh)
docker compose run --rm freqtrade download-data \
  --config /freqtrade/user_data/configs/config.kraken.dryrun.json \
  --timeframe 1h --days 30

# Backtesting (Phase 1 — uncomment scripts/backtest.sh)
docker compose run --rm freqtrade backtesting \
  --config /freqtrade/user_data/configs/config.kraken.dryrun.json \
  --strategy DryRunPlaceholder
```

---

## Upgrading Freqtrade

The image is pinned to `2024.9` in `docker-compose.yml`. This was the stable release
current at project initialisation. To upgrade to a newer version:

1. Check the [Freqtrade releases page](https://github.com/freqtrade/freqtrade/releases)
   for the target version tag and any breaking config schema changes.
2. Update the image tag in `docker-compose.yml`:
   ```
   image: freqtradeorg/freqtrade:<new-version>
   ```
3. Pull and restart:
   ```bash
   docker compose pull
   docker compose up -d
   ```
4. Run `bash scripts/check_safety.sh` and `bash scripts/validate_config.sh` after upgrading.

Never revert to `stable` — the explicit version tag is intentional for reproducibility.
