# Operations

## Starting and stopping

```bash
# First-time setup
bash scripts/setup.sh

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

Credentials are set in `.env` (`FT_API_USERNAME` / `FT_API_PASSWORD`).
Change the defaults from `change_me` before running.

## Config validation

```bash
bash scripts/validate_config.sh
```

## Checking available Kraken pairs

Freqtrade uses CCXT pair notation (`BTC/USD`, `ETH/USD`). Kraken sometimes uses
non-standard symbols (e.g. `XBT/USD` instead of `BTC/USD`). Always validate:

```bash
docker compose run --rm freqtrade list-markets --exchange kraken
```

Update `pair_whitelist` in `user_data/configs/config.kraken.dryrun.json` accordingly.

---

## Safety warnings

### DRY_RUN must be true
The `.env` file must have `DRY_RUN=true`. The `run_dry.sh` script enforces this and will
refuse to start if the value is anything else.

### API keys are not needed for dry-run
Leave `KRAKEN_API_KEY` and `KRAKEN_API_SECRET` empty. Adding real keys while in dry-run
is harmless, but unnecessary and increases risk surface.

### API server is localhost-only
`listen_ip_address` in the config is `127.0.0.1`. Do not change it to `0.0.0.0` unless
you understand the security implications and have a firewall in place.

### Do not commit .env
The `.gitignore` excludes `.env`. Double-check with `git status` before every commit.

### Database is not backed up automatically
The SQLite trade database (`user_data/tradesv3.sqlite`) is local only. Back it up manually
if the trade history matters to you.

---

## Useful Freqtrade commands (via Docker)

```bash
# List all available strategies in user_data/strategies/
docker compose run --rm freqtrade list-strategies

# Show current open trades
docker compose run --rm freqtrade show-trades --db-url sqlite:////freqtrade/user_data/tradesv3.sqlite

# Download data (Phase 1)
docker compose run --rm freqtrade download-data \
  --config /freqtrade/user_data/configs/config.kraken.dryrun.json \
  --timeframe 1h --days 30

# Backtesting (Phase 1)
docker compose run --rm freqtrade backtesting \
  --config /freqtrade/user_data/configs/config.kraken.dryrun.json \
  --strategy SampleStrategy
```

---

## Upgrading Freqtrade

Change the image tag in `docker-compose.yml` from `stable` to a specific version, then:

```bash
docker compose pull
docker compose up -d
```

Review the [Freqtrade changelog](https://github.com/freqtrade/freqtrade/releases) before
upgrading — config schema changes are common between minor versions.
