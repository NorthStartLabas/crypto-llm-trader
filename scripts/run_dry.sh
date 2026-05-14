#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/user_data/configs/config.kraken.dryrun.json"

# --- Fast pre-flight checks (before calling check_safety.sh) ---

if [ ! -f "$ROOT/.env" ]; then
  echo "ERROR: .env not found. Run: bash scripts/setup.sh"
  exit 1
fi

DRY_RUN_VAL=$(grep -E '^DRY_RUN=' "$ROOT/.env" | cut -d= -f2 | tr -d '[:space:]')
if [ "$DRY_RUN_VAL" != "true" ]; then
  echo "ERROR: DRY_RUN is not 'true' in .env (got: '$DRY_RUN_VAL')."
  echo "       This project is dry-run only. Set DRY_RUN=true to proceed."
  exit 1
fi

if [ ! -f "$CONFIG" ]; then
  echo "ERROR: Config file not found: $CONFIG"
  exit 1
fi

if grep -q '"dry_run": false' "$CONFIG"; then
  echo "ERROR: Config file contains \"dry_run\": false."
  echo "       Live trading is not enabled in this phase. Refusing to start."
  exit 1
fi

# --- Full static safety battery ---
bash "$ROOT/scripts/check_safety.sh"

# --- Start ---
echo ""
echo "==> Starting Freqtrade in DRY-RUN mode..."
echo "    FreqUI available at: http://127.0.0.1:8080"
echo "    Press Ctrl+C to stop."
echo ""

docker compose -f "$ROOT/docker-compose.yml" up freqtrade
