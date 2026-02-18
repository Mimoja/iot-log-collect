#!/bin/sh
# -------------------------------------------------------------------
# Kibana setup script
# Runs as a one-shot init container to import pre-built saved objects
# (index patterns, saved searches, visualizations, dashboard).
# Authenticates as the elastic superuser.
# -------------------------------------------------------------------

set -e

KIBANA_URL="http://kibana:5601"
NDJSON_FILE="/kibana/saved-objects.ndjson"
MAX_RETRIES=60
RETRY_INTERVAL=5

# Credentials from environment (set via docker-compose .env)
AUTH_USER="elastic"
AUTH_PASS="${ELASTIC_PASSWORD}"

echo "==> Waiting for Kibana to become available at ${KIBANA_URL}..."

attempt=0
while [ "$attempt" -lt "$MAX_RETRIES" ]; do
  status=$(curl -s -o /dev/null -w '%{http_code}' -u "${AUTH_USER}:${AUTH_PASS}" "${KIBANA_URL}/api/status" 2>/dev/null || true)
  if [ "$status" = "200" ]; then
    echo "==> Kibana is ready (HTTP ${status})."
    break
  fi
  attempt=$((attempt + 1))
  echo "    Kibana not ready yet (HTTP ${status}), retrying in ${RETRY_INTERVAL}s... (${attempt}/${MAX_RETRIES})"
  sleep "$RETRY_INTERVAL"
done

if [ "$attempt" -ge "$MAX_RETRIES" ]; then
  echo "==> ERROR: Kibana did not become ready after $((MAX_RETRIES * RETRY_INTERVAL))s. Aborting."
  exit 1
fi

# Give Kibana a moment to finish internal initialization after /api/status returns 200
sleep 5

echo "==> Importing saved objects from ${NDJSON_FILE}..."

response=$(curl -s -w '\n%{http_code}' \
  -u "${AUTH_USER}:${AUTH_PASS}" \
  -X POST "${KIBANA_URL}/api/saved_objects/_import?overwrite=true" \
  -H "kbn-xsrf: true" \
  -F "file=@${NDJSON_FILE}")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

echo "==> Import response (HTTP ${http_code}):"
echo "$body"

if [ "$http_code" = "200" ]; then
  echo ""
  echo "==> Setting default data view to 'logs-edge-*'..."
  curl -s -u "${AUTH_USER}:${AUTH_PASS}" \
    -X POST "${KIBANA_URL}/api/data_views/default" \
    -H "kbn-xsrf: true" \
    -H "Content-Type: application/json" \
    -d '{"data_view_id": "logs-edge-index-pattern", "force": true}'
  echo ""
  echo ""
  echo "============================================"
  echo "  Kibana setup complete!"
  echo "  URL:       http://localhost:5601"
  echo "  Login:     elastic / <ELASTIC_PASSWORD>"
  echo ""
  echo "  Dashboards:"
  echo "    Fleet Overview: http://localhost:5601/app/dashboards#/view/fleet-overview-dashboard"
  echo "    Device Logs:    http://localhost:5601/app/dashboards#/view/edge-device-dashboard"
  echo "============================================"
else
  echo "==> WARNING: Import may have failed (HTTP ${http_code})."
  exit 1
fi
