#!/usr/bin/env bash
# OptimiA staging smoke test — run ON the staging server after deploy
set -euo pipefail

STAGING_URL="${STAGING_URL:-https://staging.optimia.spectra-metrics.com}"
ACCOUNT_ID="${ACCOUNT_ID:-1}"
API_TOKEN="${CHATWOOT_API_TOKEN:-}"

echo "=== STAGING SMOKE TEST ==="

echo -n "[1/5] Health... "
code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 15 "${STAGING_URL}/health" || echo "000")
if [[ "$code" == "200" ]]; then echo "OK ($code)"; else echo "FAIL ($code)"; exit 1; fi

echo -n "[2/5] Evolution API... "
evo=$(curl -sS --max-time 15 "${EVOLUTION_API_URL:-https://evo-api.spectra-metrics.com}" | head -c 80)
echo "$evo"

echo -n "[3/5] Channel manager rake health... "
if command -v bundle >/dev/null 2>&1; then
  bundle exec rake optimia:channel_manager:health && echo "OK" || echo "FAIL"
else
  echo "SKIP (bundle not in PATH — run inside chatwoot container)"
fi

if [[ -n "$API_TOKEN" ]]; then
  echo -n "[4/5] List connections API... "
  resp=$(curl -sS --max-time 15 \
    -H "api_access_token: ${API_TOKEN}" \
    "${STAGING_URL}/api/v1/accounts/${ACCOUNT_ID}/optimia/whatsapp/connections")
  echo "$resp" | head -c 200
  echo ""
  echo -n "[5/5] Create connection (dry name)... "
  curl -sS --max-time 60 -X POST \
    -H "api_access_token: ${API_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"display_name":"Smoke Test WhatsApp"}' \
    "${STAGING_URL}/api/v1/accounts/${ACCOUNT_ID}/optimia/whatsapp/connections" | head -c 300
  echo ""
else
  echo "[4/5] List connections API... SKIP (set CHATWOOT_API_TOKEN)"
  echo "[5/5] Create connection... SKIP (set CHATWOOT_API_TOKEN)"
fi

echo "=== DONE ==="
