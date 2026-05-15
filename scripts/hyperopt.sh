#!/usr/bin/env bash
# Run Freqtrade Hyperopt to find optimal strategy parameters.
#
# Uses the in-sample period (20250524–20260101) for search, leaving the
# remaining months as an out-of-sample validation window.
#
# After this completes:
#   1. Freqtrade prints the best parameters — apply them with:
#        bash scripts/apply_hyperopt.sh   (or copy manually)
#   2. Validate on out-of-sample data:
#        bash scripts/backtest.sh
#
# Tuning:
#   EPOCHS=300  bash scripts/hyperopt.sh   # more search = better result, slower
#   LOSS=SortinoHyperOptLoss bash scripts/hyperopt.sh
#
# Available loss functions:
#   SharpeHyperOptLoss        — maximize Sharpe ratio (default)
#   SortinoHyperOptLoss       — maximize Sortino (penalises downside more)
#   ProfitDrawDownHyperOptLoss — balance profit vs drawdown
#   OnlyProfitHyperOptLoss    — raw profit only (overfits easily)
#   CalmarHyperOptLoss        — maximize Calmar ratio
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STRATEGY="${STRATEGY:-BaselineRsiEmaStrategy}"
EPOCHS="${EPOCHS:-500}"
LOSS="${LOSS:-MinTradesSharpeHyperOptLoss}"
SPACES="${SPACES:-buy sell roi stoploss}"
# Full available history — we have enough data and the previous in-sample
# split produced too few trades (10) for the out-of-sample to be meaningful.
TIMERANGE="${TIMERANGE:-20250524-}"
CONTAINER_CONFIG="/freqtrade/user_data/configs/config.binance.download.json"

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

echo "==> Running Hyperopt"
echo "    Strategy   : $STRATEGY"
echo "    Epochs     : $EPOCHS"
echo "    Loss fn    : $LOSS"
echo "    Spaces     : $SPACES"
echo "    Timerange  : $TIMERANGE  (in-sample only)"
echo ""
echo "    After completion, validate with:"
echo "      bash scripts/backtest.sh"
echo ""

# shellcheck disable=SC2086
docker compose -f "$ROOT/docker-compose.yml" run --rm \
  freqtrade \
  hyperopt \
  --config "$CONTAINER_CONFIG" \
  --strategy "$STRATEGY" \
  --hyperopt-loss "$LOSS" \
  --spaces $SPACES \
  --timerange "$TIMERANGE" \
  --epochs "$EPOCHS"

echo ""
echo "==> Hyperopt complete."
echo "    Best parameters saved to: user_data/strategies/.hyperopt/"
echo ""
echo "    Next steps:"
echo "      1. Review best params printed above"
echo "      2. Validate: bash scripts/backtest.sh"
