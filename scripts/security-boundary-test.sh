#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

EDGE_URL="${SIEM_EDGE_INTERNAL_URL:-https://lgtm-edge-proxy:8443}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

require docker

echo "validating Docker Compose configuration"
docker compose --profile edge config --quiet

echo "starting TLS edge proxy"
docker compose --profile edge up -d --force-recreate edge-proxy

echo "checking Grafana through TLS edge proxy"
docker run --rm --network lgtm-observability curlimages/curl:latest -kfsS "${EDGE_URL}/api/health" | ruby -rjson -e '
  data = JSON.parse(STDIN.read)
  abort("unexpected Grafana health response") unless data.fetch("database") == "ok"
'

echo "checking HTTP event collector through TLS edge proxy"
docker run --rm --network lgtm-observability curlimages/curl:latest -kfsS "${EDGE_URL}/event" \
  -H "Authorization: Bearer ${SIEM_HTTP_EVENT_TOKEN:-change-me}" \
  -H "Content-Type: application/json" \
  -d '{"event":{"source":"security-boundary-test","message":"tls edge proxy test"}}' >/dev/null

echo "security boundary test passed"
