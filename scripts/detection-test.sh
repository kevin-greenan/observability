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

HTTP_EVENT_INTERNAL_URL="${HTTP_EVENT_INTERNAL_URL:-http://lgtm-siem-collector:8088/event}"
LOKI_INTERNAL_URL="${LOKI_INTERNAL_URL:-http://lgtm-loki:3100}"
HTTP_EVENT_TOKEN="${SIEM_HTTP_EVENT_TOKEN:-change-me}"
TEST_FILE="${1:-detections/tests/detection-tests.yaml}"
RUN_ID="detection-test-$(date +%Y%m%d%H%M%S)"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

post_event() {
  local payload="$1"

  docker run --rm --network lgtm-observability curlimages/curl:latest -fsS "${HTTP_EVENT_INTERNAL_URL}" \
    -H "Authorization: Bearer ${HTTP_EVENT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}" >/dev/null
}

query_loki() {
  local query="$1"

  docker run --rm --network lgtm-observability curlimages/curl:latest -fsG "${LOKI_INTERNAL_URL}/loki/api/v1/query" \
    --data-urlencode "query=${query}"
}

wait_for_detection() {
  local id="$1"
  local alert="$2"
  local query="$3"
  local body=""

  for _ in $(seq 1 30); do
    body="$(query_loki "${query}" || true)"
    if printf '%s' "${body}" | ruby -rjson -e '
      data = JSON.parse(STDIN.read).fetch("data", {})
      result = data.fetch("result", [])
      exit(result.empty? ? 1 : 0)
    '; then
      echo "ok: ${alert} (${id})"
      return 0
    fi
    sleep 2
  done

  echo "failed: ${alert} (${id})" >&2
  echo "query: ${query}" >&2
  echo "last response: ${body}" >&2
  exit 1
}

validate_rule_metadata() {
  ruby -ryaml -e '
    rules = YAML.load_file("detections/loki/security-rules.yaml").fetch("groups").flat_map { |group| group.fetch("rules") }
    required_labels = %w[id severity category owner status mitre_tactic mitre_technique]
    required_annotations = %w[summary description runbook_url false_positive_notes]
    failed = false

    rules.each do |rule|
      missing_labels = required_labels.reject { |key| rule.fetch("labels", {}).key?(key) }
      missing_annotations = required_annotations.reject { |key| rule.fetch("annotations", {}).key?(key) }

      unless missing_labels.empty? && missing_annotations.empty?
        warn "#{rule.fetch("alert", "unknown")}: missing labels=#{missing_labels.join(",")} annotations=#{missing_annotations.join(",")}"
        failed = true
      end
    end

    exit(failed ? 1 : 0)
  '
}

run_tests() {
  ruby -ryaml -rjson -e '
    run_id = ENV.fetch("RUN_ID")
    test_file = ENV.fetch("TEST_FILE")
    tests = YAML.load_file(test_file).fetch("tests")

    tests.each do |test|
      fixture = test.fetch("fixture")
      File.foreach(fixture) do |line|
        next if line.strip.empty?
        event = JSON.parse(line)
        event["detection_test_run"] = run_id
        event["message"] = "#{run_id} #{event.fetch("message", "")}"
        puts JSON.generate({ "event" => event })
      end

      query = test.fetch("query").gsub("$RUN_ID", run_id)
      warn JSON.generate({
        "type" => "assertion",
        "id" => test.fetch("id"),
        "alert" => test.fetch("alert"),
        "query" => query
      })
    end
  ' 2> >(while IFS= read -r line; do printf '%s\n' "$line" >> "${ASSERTIONS_FILE}"; done) |
  while IFS= read -r payload; do
    post_event "${payload}"
  done
}

require docker
require ruby

ASSERTIONS_FILE="$(mktemp)"
trap 'rm -f "${ASSERTIONS_FILE}"' EXIT

echo "validating detection rule metadata"
validate_rule_metadata

echo "running detection tests ${RUN_ID}"
export RUN_ID TEST_FILE
run_tests

while IFS= read -r assertion; do
  id="$(printf '%s' "${assertion}" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("id")')"
  alert="$(printf '%s' "${assertion}" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("alert")')"
  query="$(printf '%s' "${assertion}" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("query")')"
  wait_for_detection "${id}" "${alert}" "${query}"
done < "${ASSERTIONS_FILE}"

echo "detection tests passed: ${RUN_ID}"
