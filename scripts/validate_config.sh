#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${1:-/freqtrade/user_data/configs/config.kraken.dryrun.json}"

echo "==> Step 1: Static safety checks"
bash "$ROOT/scripts/check_safety.sh"

echo ""
echo "==> Step 2: Freqtrade config parse (show-config)"
echo "    Config: $CONFIG"
echo ""

# show-config parses the JSON, resolves env var overrides, and prints the merged
# configuration. It exits non-zero on any parse or schema error.
docker compose -f "$ROOT/docker-compose.yml" run --rm freqtrade \
  show-config \
  --config "$CONFIG"

echo ""
echo "==> Config validation complete."
echo ""
echo "    Optional: to also validate the pairlist against the live Kraken exchange"
echo "    (public endpoint, no API key needed), run:"
echo "      bash scripts/list_kraken_markets.sh"
