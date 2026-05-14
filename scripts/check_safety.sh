#!/usr/bin/env bash
# Static safety checks — must all pass before any bot operation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$ROOT/user_data/configs/config.kraken.dryrun.json"
ERRORS=0

pass() { printf "  OK    %s\n" "$1"; }
fail() { printf "  FAIL  %s\n" "$1"; ERRORS=$((ERRORS + 1)); }
warn() { printf "  WARN  %s\n" "$1"; }

echo "==> Safety checks: $ROOT"
echo ""

# 1. .env exists
if [ -f "$ROOT/.env" ]; then
  pass ".env exists"
else
  fail ".env not found — run: bash scripts/setup.sh"
fi

# 2. DRY_RUN=true in .env
if [ -f "$ROOT/.env" ]; then
  DRY_RUN_VAL=$(grep -E '^DRY_RUN=' "$ROOT/.env" | cut -d= -f2 | tr -d '[:space:]')
  if [ "$DRY_RUN_VAL" = "true" ]; then
    pass "DRY_RUN=true in .env"
  elif [ -z "$DRY_RUN_VAL" ]; then
    fail "DRY_RUN not set in .env"
  else
    fail "DRY_RUN='$DRY_RUN_VAL' in .env — must be exactly 'true'"
  fi
fi

# 3. Config file exists
if [ -f "$CONFIG" ]; then
  pass "Config file found"
else
  fail "Config file missing: $CONFIG"
fi

if [ -f "$CONFIG" ]; then
  # 4. dry_run must be true
  if grep -q '"dry_run": true' "$CONFIG"; then
    pass '"dry_run": true in config'
  else
    fail '"dry_run": true NOT found in config — trading live is not allowed in this phase'
  fi

  # 5. trading_mode must be spot
  if grep -q '"trading_mode": "spot"' "$CONFIG"; then
    pass '"trading_mode": "spot" in config'
  else
    fail '"trading_mode": "spot" NOT found in config — futures/margin are not allowed'
  fi

  # 6. force_entry_enable must be false
  if grep -q '"force_entry_enable": false' "$CONFIG"; then
    pass '"force_entry_enable": false in config'
  else
    fail '"force_entry_enable": false NOT found in config'
  fi

  # 7. API server must be localhost only
  if grep -q '"listen_ip_address": "127.0.0.1"' "$CONFIG"; then
    pass 'API server bound to 127.0.0.1'
  else
    fail 'API server NOT bound to 127.0.0.1 — check listen_ip_address in config'
  fi

  # 8. Exchange key should be empty in config (real keys go in .env via FREQTRADE__ vars)
  if grep -qE '"key"[[:space:]]*:[[:space:]]*""' "$CONFIG"; then
    pass 'Exchange key is empty in config (correct — use FREQTRADE__exchange__key in .env)'
  else
    warn 'Exchange key may be non-empty in config — real credentials belong in .env, not config'
  fi

  # 9. Exchange secret should be empty in config
  if grep -qE '"secret"[[:space:]]*:[[:space:]]*""' "$CONFIG"; then
    pass 'Exchange secret is empty in config (correct — use FREQTRADE__exchange__secret in .env)'
  else
    warn 'Exchange secret may be non-empty in config — real credentials belong in .env, not config'
  fi
fi

# 10. No live config files
LIVE_CONFIGS=$(find "$ROOT/user_data/configs" -name "*live*" 2>/dev/null | head -5 || true)
if [ -z "$LIVE_CONFIGS" ]; then
  pass 'No live config files in user_data/configs/'
else
  fail "Live config file(s) detected: $LIVE_CONFIGS — remove before proceeding"
fi

# 11. .env is not staged or tracked in git
if git -C "$ROOT" rev-parse --git-dir &>/dev/null 2>&1; then
  if git -C "$ROOT" ls-files --error-unmatch "$ROOT/.env" &>/dev/null 2>&1; then
    fail ".env is tracked by git — this is a credentials leak risk; run: git rm --cached .env"
  else
    pass ".env is not tracked by git"
  fi
else
  warn "Not a git repository — skipping git tracking check"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "==> All safety checks passed."
  exit 0
else
  echo "==> $ERRORS safety check(s) FAILED. Fix the issues above before running the bot."
  exit 1
fi
