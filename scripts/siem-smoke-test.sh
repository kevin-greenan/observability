#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

LOKI_INTERNAL_URL="${LOKI_INTERNAL_URL:-http://lgtm-loki:3100}"
HTTP_EVENT_INTERNAL_URL="${HTTP_EVENT_INTERNAL_URL:-http://lgtm-siem-collector:8088/event}"
HTTP_EVENT_TOKEN="${SIEM_HTTP_EVENT_TOKEN:-change-me}"
INGEST_DIR="${SIEM_INGEST_DIR:-./ingest}"
RUN_ID="siem-smoke-$(date +%Y%m%d%H%M%S)"
SMOKE_DIR="${INGEST_DIR%/}/smoke-test"

mkdir -p "${SMOKE_DIR}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

query_loki() {
  local query="$1"
  docker run --rm --network lgtm-observability curlimages/curl:latest -fsG "${LOKI_INTERNAL_URL}/loki/api/v1/query_range" \
    --data-urlencode "query=${query}" \
    --data-urlencode "limit=20"
}

wait_for_query() {
  local name="$1"
  local query="$2"
  local expected="$3"
  local body=""

  for _ in $(seq 1 30); do
    body="$(query_loki "${query}" || true)"
    if printf '%s' "${body}" | grep -q "${expected}"; then
      echo "ok: ${name}"
      return 0
    fi
    sleep 2
  done

  echo "failed: ${name}" >&2
  echo "query: ${query}" >&2
  echo "expected: ${expected}" >&2
  echo "last response: ${body}" >&2
  exit 1
}

post_http_event() {
  local payload="$1"

  for _ in $(seq 1 30); do
    if docker run --rm --network lgtm-observability curlimages/curl:latest -fsS "${HTTP_EVENT_INTERNAL_URL}" \
      -H "Authorization: Bearer ${HTTP_EVENT_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "${payload}" \
      >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  echo "failed: HTTP event endpoint did not accept test event" >&2
  echo "url: ${HTTP_EVENT_INTERNAL_URL}" >&2
  exit 1
}

require docker

echo "running SIEM smoke test ${RUN_ID}"

post_http_event "{\"event\":{\"source\":\"smoke\",\"event.action\":\"http-json\",\"message\":\"${RUN_ID} http event\",\"source.ip\":\"203.0.113.10\",\"user.name\":\"codex\"}}"

printf '{"source":"smoke","event.action":"file-json","message":"%s file json event","source.ip":"10.0.1.20"}\n' "${RUN_ID}" \
  > "${SMOKE_DIR}/${RUN_ID}.jsonl"

printf '%s,csv,login_failure,alice,203.0.113.10\n' "${RUN_ID}" \
  > "${SMOKE_DIR}/${RUN_ID}.csv"

printf '%s logfmt event action=login outcome=failure user=bob src_ip=203.0.113.10\n' "${RUN_ID}" \
  > "${SMOKE_DIR}/${RUN_ID}.log"

SYSLOG_TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '<34>1 %s smoke-host app - - - %s syslog event user=alice action=login outcome=failure\n' "${SYSLOG_TS}" "${RUN_ID}" \
  > /dev/tcp/127.0.0.1/${SIEM_SYSLOG_TCP_PORT:-5514}

wait_for_query "file JSON ingest" "{job=\"siem-file-collector\",source_type=\"file\"} |= \"${RUN_ID}\" |= \"file json\"" "${RUN_ID}"
wait_for_query "CSV file ingest" "{job=\"siem-file-collector\",source_type=\"file\",parse_status=\"csv\"} |= \"${RUN_ID}\"" "fields"
wait_for_query "key/value file ingest" "{job=\"siem-file-collector\",source_type=\"file\",parse_status=\"key_value\"} |= \"${RUN_ID}\"" "outcome"
wait_for_query "HTTP event ingest" "{job=\"siem-file-collector\",source_type=\"http_event_collector\"} |= \"${RUN_ID}\"" "http event"
wait_for_query "source inventory enrichment" "{job=\"siem-file-collector\",source_id=\"http-event\"} |= \"${RUN_ID}\"" "source_owner"
wait_for_query "lookup enrichment" "{job=\"siem-file-collector\",source_type=\"http_event_collector\"} |= \"${RUN_ID}\"" "asset_inventory"
wait_for_query "syslog ingest" "{job=\"siem-file-collector\",source_type=\"syslog\"} |= \"${RUN_ID}\"" "syslog event"

echo "SIEM smoke test passed: ${RUN_ID}"
