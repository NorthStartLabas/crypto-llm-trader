#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${1:-/freqtrade/user_data/configs/config.kraken.dryrun.json}"

echo "==> Step 1: Static safety checks"
bash "$ROOT/scripts/check_safety.sh"

echo ""
echo "==> Step 2: Freqtrade config validation (check-exchange)"
echo "    Config: $CONFIG"
echo ""

docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
  check-exchange \
  --config "$CONFIG"

echo ""
echo "==> Config validation complete."
