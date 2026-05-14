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
echo "  1. Review and edit .env (change all 'change_me' values)"
echo "  2. Run safety checks:                 bash scripts/check_safety.sh"
echo "  3. Validate Kraken pair names:        bash scripts/list_kraken_markets.sh"
echo "  4. Validate config against exchange:  bash scripts/validate_config.sh"
echo "  5. Start in dry-run mode:             bash scripts/run_dry.sh"
