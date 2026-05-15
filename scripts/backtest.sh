#!/usr/bin/env bash
# Run a Freqtrade backtest against locally downloaded OHLCV data.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ------------------------------------------------------------------ #
# Configuration (override via env vars)                               #
# ------------------------------------------------------------------ #
STRATEGY="${STRATEGY:-BaselineRsiEmaStrategy}"
TIMEFRAME="${TIMEFRAME:-1h}"

# Use all available downloaded data by default.
# Override with e.g. TIMERANGE=20250101-20251231 for a specific window.
TIMERANGE="${TIMERANGE:-}"

CONTAINER_CONFIG="/freqtrade/user_data/configs/config.binance.download.json"
DATA_DIR="$ROOT/user_data/data/binance"

# ------------------------------------------------------------------ #
# Pre-flight                                                          #
# ------------------------------------------------------------------ #
echo "==> Step 1: Static safety checks"
bash "$ROOT/scripts/check_safety.sh"
echo ""

if ! docker info &>/dev/null 2>&1; then
  echo "ERROR: Docker is not running or not reachable."
  exit 1
fi

# Check that at least some 1h data exists for the exchange
if [ ! -d "$DATA_DIR" ] || [ -z "$(find "$DATA_DIR" -name "*-${TIMEFRAME}.*" 2>/dev/null | head -1)" ]; then
  echo "ERROR: No ${TIMEFRAME} data found in user_data/data/binance/."
  echo "       Download data first:"
  echo "         bash scripts/download_data.sh"
  exit 1
fi

echo "==> Running backtest"
echo "    Strategy  : $STRATEGY"
echo "    Timeframe : $TIMEFRAME"
echo "    Data dir  : user_data/data/binance/"
if [ -n "$TIMERANGE" ]; then
  echo "    Timerange : $TIMERANGE"
else
  echo "    Timerange : all available data"
fi
echo "    Results   : user_data/backtest_results/"
echo ""

# Build the timerange flag only if TIMERANGE is set
TIMERANGE_FLAG=""
if [ -n "$TIMERANGE" ]; then
  TIMERANGE_FLAG="--timerange $TIMERANGE"
fi

docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
  backtesting \
  --config "$CONTAINER_CONFIG" \
  --strategy "$STRATEGY" \
  --timeframe "$TIMEFRAME" \
  --export trades \
  --export-filename "user_data/backtest_results/${STRATEGY}_$(date +%Y%m%d_%H%M%S).json" \
  ${TIMERANGE_FLAG:+$TIMERANGE_FLAG}

echo ""
echo "==> Backtest complete."
echo "    Results saved in: user_data/backtest_results/"
echo "    Review the output above before starting dry-run."
