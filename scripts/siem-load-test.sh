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

EVENTS="${SIEM_LOAD_TEST_EVENTS:-500}"
BATCH_SIZE="${SIEM_LOAD_TEST_BATCH_SIZE:-50}"
TARGET_EPS="${SIEM_LOAD_TEST_TARGET_EPS:-100}"
HTTP_EVENT_INTERNAL_URL="${HTTP_EVENT_INTERNAL_URL:-http://lgtm-siem-collector:8088/event}"
LOKI_INTERNAL_URL="${LOKI_INTERNAL_URL:-http://lgtm-loki:3100}"
HTTP_EVENT_TOKEN="${SIEM_HTTP_EVENT_TOKEN:-change-me}"
RUN_ID="siem-load-$(date +%Y%m%d%H%M%S)"
RESULT_DIR="${SIEM_LOAD_TEST_RESULT_DIR:-tmp/load-tests}"
RESULT_FILE="${RESULT_DIR}/${RUN_ID}.json"
WORK_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

now_ms() {
  ruby -e 'puts (Time.now.to_f * 1000).to_i'
}

post_batch() {
  local batch_start="$1"
  local batch_count="$2"
  local batch_file="${WORK_DIR}/batch-${batch_start}.jsonl"

  ruby -rjson -e '
    run_id = ENV.fetch("RUN_ID")
    start = ENV.fetch("BATCH_START").to_i
    count = ENV.fetch("BATCH_COUNT").to_i
    count.times do |offset|
      seq = start + offset
      event = {
        "source" => "load-test",
        "event.action" => "load_test",
        "event.outcome" => "success",
        "message" => "#{run_id} synthetic load event #{seq}",
        "source.ip" => "203.0.113.10",
        "load_test_run" => run_id,
        "load_test_sequence" => seq,
        "payload" => "x" * 256
      }
      puts JSON.generate({"event" => event})
    end
  ' > "${batch_file}"

  docker run --rm --network lgtm-observability \
    -v "${batch_file}:/payloads.jsonl:ro" \
    -e HTTP_EVENT_INTERNAL_URL="${HTTP_EVENT_INTERNAL_URL}" \
    -e HTTP_EVENT_TOKEN="${HTTP_EVENT_TOKEN}" \
    curlimages/curl:latest sh -ec '
      while IFS= read -r payload; do
        curl -fsS "${HTTP_EVENT_INTERNAL_URL}" \
          -H "Authorization: Bearer ${HTTP_EVENT_TOKEN}" \
          -H "Content-Type: application/json" \
          -d "${payload}" >/dev/null
      done < /payloads.jsonl
    '
}

query_loki_count() {
  docker run --rm --network lgtm-observability curlimages/curl:latest -fsG "${LOKI_INTERNAL_URL}/loki/api/v1/query" \
    --data-urlencode "query=sum(count_over_time({job=\"siem-file-collector\",source_type=\"http_event_collector\"} |= \"${RUN_ID}\" [15m]))" |
    ruby -rjson -e '
      data = JSON.parse(STDIN.read).fetch("data", {})
      result = data.fetch("result", [])
      if result.empty?
        puts 0
      else
        puts result.first.fetch("value").last.to_f.to_i
      end
    '
}

require docker
require ruby

mkdir -p "${RESULT_DIR}"

echo "running SIEM load test ${RUN_ID}"
echo "events=${EVENTS} batch_size=${BATCH_SIZE} target_eps=${TARGET_EPS}"

sent=0
post_start_ms="$(now_ms)"
while [[ "${sent}" -lt "${EVENTS}" ]]; do
  remaining=$((EVENTS - sent))
  current_batch="${BATCH_SIZE}"
  if [[ "${remaining}" -lt "${current_batch}" ]]; then
    current_batch="${remaining}"
  fi

  BATCH_START="${sent}" BATCH_COUNT="${current_batch}" RUN_ID="${RUN_ID}" post_batch "${sent}" "${current_batch}"
  sent=$((sent + current_batch))

  if [[ "${TARGET_EPS}" -gt 0 ]]; then
    ruby -e 'sleep(ARGV[0].to_f)' "$(ruby -e "puts (${current_batch}.to_f / ${TARGET_EPS}.to_f)")"
  fi
done
post_end_ms="$(now_ms)"

observed=0
query_start_ms="$(now_ms)"
for _ in $(seq 1 60); do
  observed="$(query_loki_count || echo 0)"
  if [[ "${observed}" -ge "${EVENTS}" ]]; then
    break
  fi
  sleep 2
done
query_end_ms="$(now_ms)"

post_duration_ms=$((post_end_ms - post_start_ms))
query_duration_ms=$((query_end_ms - query_start_ms))
actual_eps="$(ruby -e 'events=ARGV[0].to_f; ms=ARGV[1].to_f; puts(ms > 0 ? (events / (ms / 1000.0)).round(2) : events)' "${EVENTS}" "${post_duration_ms}")"

RUN_ID="${RUN_ID}" EVENTS="${EVENTS}" OBSERVED="${observed}" BATCH_SIZE="${BATCH_SIZE}" TARGET_EPS="${TARGET_EPS}" ACTUAL_EPS="${actual_eps}" POST_DURATION_MS="${post_duration_ms}" QUERY_DURATION_MS="${query_duration_ms}" RESULT_FILE="${RESULT_FILE}" ruby -rjson -e '
  result = {
    "run_id" => ENV.fetch("RUN_ID"),
    "events_requested" => ENV.fetch("EVENTS").to_i,
    "events_observed" => ENV.fetch("OBSERVED").to_i,
    "batch_size" => ENV.fetch("BATCH_SIZE").to_i,
    "target_eps" => ENV.fetch("TARGET_EPS").to_i,
    "actual_post_eps" => ENV.fetch("ACTUAL_EPS").to_f,
    "post_duration_ms" => ENV.fetch("POST_DURATION_MS").to_i,
    "loki_visibility_ms" => ENV.fetch("QUERY_DURATION_MS").to_i,
    "status" => ENV.fetch("OBSERVED").to_i >= ENV.fetch("EVENTS").to_i ? "pass" : "fail"
  }
  File.write(ENV.fetch("RESULT_FILE"), JSON.pretty_generate(result) + "\n")
  puts JSON.pretty_generate(result)
  exit(result["status"] == "pass" ? 0 : 1)
'
