#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${1:-/freqtrade/user_data/configs/config.kraken.dryrun.json}"

echo "==> Validating config: $CONFIG"

docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
  check-exchange \
  --config "$CONFIG"

echo "==> Config validation complete."
