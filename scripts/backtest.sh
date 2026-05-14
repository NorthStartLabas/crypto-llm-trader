#!/usr/bin/env bash
# Phase 1 placeholder — backtesting will be wired up once data is downloaded.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${CONFIG:-/freqtrade/user_data/configs/config.kraken.dryrun.json}"
STRATEGY="${STRATEGY:-DryRunPlaceholder}"
TIMERANGE="${TIMERANGE:-20240101-}"

echo "==> Backtesting strategy: $STRATEGY"
echo "    NOTE: This script is a Phase 1 placeholder."
echo "    Download data first (scripts/download_data.sh), then uncomment below."
echo ""

# docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
#   backtesting \
#   --config "$CONFIG" \
#   --strategy "$STRATEGY" \
#   --timerange "$TIMERANGE" \
#   --export trades

echo "==> No backtest run (Phase 0)."
