#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Creating user_data directories..."
mkdir -p \
  "$ROOT/user_data/configs" \
  "$ROOT/user_data/strategies" \
  "$ROOT/user_data/data" \
  "$ROOT/user_data/logs" \
  "$ROOT/user_data/backtest_results" \
  "$ROOT/user_data/freqaimodels"

echo "==> Checking for .env file..."
if [ ! -f "$ROOT/.env" ]; then
  cp "$ROOT/.env.example" "$ROOT/.env"
  echo ""
  echo "  .env created from .env.example."
  echo "  IMPORTANT: open .env and review every value before starting the bot."
  echo "  DRY_RUN must remain 'true' until live trading is explicitly approved."
  echo ""
else
  echo "  .env already exists — not overwriting."
fi

echo "==> Setup complete."
echo ""
echo "Next steps:"
echo "  1. Review and edit .env"
echo "  2. Validate your Kraken pair names:  docker compose run --rm freqtrade list-markets --exchange kraken"
echo "  3. Start in dry-run mode:             bash scripts/run_dry.sh"
