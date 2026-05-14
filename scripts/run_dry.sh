#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$ROOT/.env" ]; then
  echo "ERROR: .env not found. Run scripts/setup.sh first."
  exit 1
fi

# Abort if someone accidentally set DRY_RUN=false
DRY_RUN_VALUE=$(grep -E '^DRY_RUN=' "$ROOT/.env" | cut -d= -f2 | tr -d '[:space:]')
if [ "$DRY_RUN_VALUE" != "true" ]; then
  echo "ERROR: DRY_RUN is not set to 'true' in .env."
  echo "       This project defaults to dry-run only. Set DRY_RUN=true to proceed."
  exit 1
fi

echo "==> Starting Freqtrade in DRY-RUN mode..."
echo "    FreqUI available at: http://127.0.0.1:8080"
echo "    Press Ctrl+C to stop."
echo ""

docker compose -f "$ROOT/docker-compose.yml" up freqtrade
