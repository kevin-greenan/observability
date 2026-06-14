#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

LISTEN_HOST="${ALERT_WEBHOOK_LISTEN_HOST:-0.0.0.0}"
LISTEN_PORT="${ALERT_WEBHOOK_LISTEN_PORT:-18080}"
DOCKER_ALERT_WEBHOOK_URL="${DOCKER_ALERT_WEBHOOK_URL:-http://host.docker.internal:${LISTEN_PORT}/siem-alerts}"
PAYLOAD_FILE="$(mktemp)"
SERVER_LOG="$(mktemp)"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]]; then
    kill "${SERVER_PID}" >/dev/null 2>&1 || true
    wait "${SERVER_PID}" >/dev/null 2>&1 || true
  fi
  rm -f "${PAYLOAD_FILE}" "${SERVER_LOG}"
}
trap cleanup EXIT

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

validate_provisioning() {
  ruby -ryaml -e '
    contact_points = YAML.load_file("config/grafana/provisioning/alerting/contact-points.yaml")
    policies = YAML.load_file("config/grafana/provisioning/alerting/notification-policies.yaml")
    templates = YAML.load_file("config/grafana/provisioning/alerting/templates.yaml")

    receiver_names = contact_points.fetch("contactPoints").map { |point| point.fetch("name") }
    abort("missing siem-local-webhook contact point") unless receiver_names.include?("siem-local-webhook")

    root_policy = policies.fetch("policies").first
    abort("root policy must route to siem-local-webhook") unless root_policy.fetch("receiver") == "siem-local-webhook"

    severities = root_policy.fetch("routes").flat_map { |route| route.fetch("object_matchers", []) }
      .select { |matcher| matcher[0] == "severity" }
      .map { |matcher| matcher[2] }
    missing = %w[critical high medium] - severities
    abort("missing severity routes: #{missing.join(",")}") unless missing.empty?

    abort("missing SIEM alert template") unless templates.fetch("templates").any? { |template| template.fetch("name") == "siem-alert-templates" }
  '
}

start_receiver() {
  ruby -rwebrick -e '
    output = ENV.fetch("PAYLOAD_FILE")
    server = WEBrick::HTTPServer.new(
      BindAddress: ENV.fetch("LISTEN_HOST"),
      Port: ENV.fetch("LISTEN_PORT").to_i,
      AccessLog: [],
      Logger: WEBrick::Log.new(File::NULL)
    )
    server.mount_proc "/siem-alerts" do |request, response|
      File.write(output, request.body.to_s)
      response.status = 202
      response.body = "accepted"
    end
    trap("TERM") { server.shutdown }
    server.start
  ' >"${SERVER_LOG}" 2>&1 &
  SERVER_PID="$!"
  sleep 2
}

post_test_alert() {
  local payload
  payload='{"status":"firing","commonLabels":{"alertname":"AlertRoutingTest","severity":"medium","owner":"security-platform","category":"test"},"alerts":[{"status":"firing","labels":{"alertname":"AlertRoutingTest","severity":"medium","owner":"security-platform","category":"test"},"annotations":{"summary":"Alert routing test","description":"Synthetic alert routing delivery test","runbook_url":"docs/siem/alert-routing.md","false_positive_notes":"Synthetic test payload"}}]}'

  docker run --rm curlimages/curl:latest -fsS "${DOCKER_ALERT_WEBHOOK_URL}" \
    -H "Content-Type: application/json" \
    -d "${payload}" >/dev/null
}

assert_received() {
  ruby -rjson -e '
    payload = File.read(ENV.fetch("PAYLOAD_FILE"))
    abort("webhook receiver did not capture a payload") if payload.strip.empty?
    data = JSON.parse(payload)
    abort("unexpected alert name") unless data.fetch("commonLabels").fetch("alertname") == "AlertRoutingTest"
    abort("unexpected severity") unless data.fetch("commonLabels").fetch("severity") == "medium"
  '
}

require docker
require ruby

export PAYLOAD_FILE LISTEN_HOST LISTEN_PORT

echo "validating Grafana alerting provisioning"
validate_provisioning

echo "starting local SIEM alert webhook receiver on ${LISTEN_HOST}:${LISTEN_PORT}"
start_receiver

echo "sending test alert to ${DOCKER_ALERT_WEBHOOK_URL}"
post_test_alert

assert_received
echo "alert routing test passed"
