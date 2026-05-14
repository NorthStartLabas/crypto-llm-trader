#!/usr/bin/env bash
# Phase 1 placeholder — data download will be wired up when backtesting begins.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${CONFIG:-/freqtrade/user_data/configs/config.kraken.dryrun.json}"
TIMEFRAME="${TIMEFRAME:-1h}"
DAYS="${DAYS:-30}"

echo "==> Downloading OHLCV data (timeframe=$TIMEFRAME, days=$DAYS)..."
echo "    NOTE: This script is a Phase 1 placeholder."
echo "    Uncomment and adjust the command below once Phase 1 is active."
echo ""

# docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
#   download-data \
#   --config "$CONFIG" \
#   --timeframe "$TIMEFRAME" \
#   --days "$DAYS"

echo "==> Nothing downloaded yet (Phase 0)."
