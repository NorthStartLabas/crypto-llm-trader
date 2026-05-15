#!/usr/bin/env bash
# Download historical OHLCV data from Binance for backtesting.
#
# Binance serves candles directly via its public API — no trade resampling
# needed. 365 days of 30 pairs downloads in ~1-2 minutes.
#
# Pairs are passed explicitly via --pairs because VolumePairList (used in the
# backtest config) requires a live bot context and cannot resolve pairs during
# download-data. The list below is the approximate Binance top 30 by USDT
# quote volume. Update it periodically as rankings shift.
#
# Live trading still runs against Kraken; this data is for backtesting only.
# No API key required.
#
# Usage:
#   bash scripts/download_data.sh               # 30 days, default
#   DAYS=365 bash scripts/download_data.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TIMEFRAME="${TIMEFRAME:-1h}"
DAYS="${DAYS:-30}"
CONTAINER_CONFIG="/freqtrade/user_data/configs/config.binance.download.json"

# Top ~30 Binance USDT pairs by quote volume.
# VolumePairList can't resolve pairs at download time, so we list them here.
PAIRS=(
  BTC/USDT ETH/USDT SOL/USDT XRP/USDT DOGE/USDT
  ADA/USDT AVAX/USDT LINK/USDT DOT/USDT LTC/USDT
  UNI/USDT ATOM/USDT NEAR/USDT APT/USDT OP/USDT
  ARB/USDT SUI/USDT TRX/USDT TON/USDT SHIB/USDT
  BCH/USDT ETC/USDT FIL/USDT ICP/USDT WIF/USDT
  PEPE/USDT HBAR/USDT SEI/USDT JUP/USDT ONDO/USDT
)

# macOS / Linux portable date arithmetic
date_offset() {
  local days=$1
  if date -v-1d +%Y%m%d &>/dev/null 2>&1; then
    date -v-"${days}"d +%Y%m%d
  else
    date -d "${days} days ago" +%Y%m%d
  fi
}

START_DATE=$(date_offset "$DAYS")
TIMERANGE="${TIMERANGE:-${START_DATE}-}"

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

echo "==> Downloading OHLCV data from Binance (public API, no key needed)"
echo "    Exchange  : binance"
echo "    Pairs     : ${#PAIRS[@]} pairs"
echo "    Timeframe : $TIMEFRAME"
echo "    Timerange : $TIMERANGE  (last $DAYS days)"
echo ""

docker compose -f "$ROOT/docker-compose.yml" run --rm \
  freqtrade \
  download-data \
  --config "$CONTAINER_CONFIG" \
  --timeframes "$TIMEFRAME" \
  --timerange "$TIMERANGE" \
  --pairs "${PAIRS[@]}"

echo ""
echo "==> Download complete."
echo "    Data stored in: user_data/data/binance/"
echo "    Run backtesting next: bash scripts/backtest.sh"
