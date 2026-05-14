#!/usr/bin/env bash
# List all available markets on Kraken via CCXT — no API key required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Listing Kraken markets (no API key needed)..."
echo ""
echo "    Look for BTC/USD or XBT/USD and ETH/USD in the output."
echo "    If Kraken uses XBT instead of BTC, update pair_whitelist in:"
echo "    user_data/configs/config.kraken.dryrun.json"
echo ""

docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
  list-markets \
  --exchange kraken \
  --config /freqtrade/user_data/configs/config.kraken.dryrun.json

echo ""
echo "==> Update pair_whitelist in user_data/configs/config.kraken.dryrun.json"
echo "    with the exact pair symbols shown above before starting the bot."
