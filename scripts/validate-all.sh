#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

require docker
require jq
require ruby

echo "validating Compose files"
docker compose config --quiet
docker compose --profile edge config --quiet
docker compose \
  --env-file deploy/compose/production/.env.production.example \
  -f docker-compose.yml \
  -f deploy/compose/production/docker-compose.production.example.yml \
  -f deploy/compose/production/docker-compose.secrets.example.yml \
  --profile edge \
  config --quiet

echo "validating production image pins"
ruby -e '
  env = File.read("deploy/compose/production/.env.production.example")
  image_lines = env.lines.grep(/_IMAGE=/)
  abort("no production image pins found") if image_lines.empty?
  bad = image_lines.reject { |line| line.include?("@sha256:") }
  abort("unpinned production images: #{bad.join}") unless bad.empty?
'

echo "validating dashboards"
find dashboards/grafana -name "*.json" -print0 | xargs -0 -n1 jq empty

echo "validating YAML files"
ruby -ryaml -e '
  files = Dir["config/**/*.y{a,}ml"] + Dir["detections/**/*.y{a,}ml"] + Dir["deploy/**/*.y{a,}ml"]
  files.each { |file| YAML.load_file(file) }
'

echo "validating Vector config"
docker run --rm \
  -e SIEM_HTTP_EVENT_TOKEN=validate-token \
  -v "${ROOT_DIR}/config/vector:/etc/vector:ro" \
  "${VECTOR_VALIDATE_IMAGE:-timberio/vector:0.49.0-debian}" \
  validate /etc/vector/vector.yaml

echo "validating Prometheus config"
docker run --rm \
  --entrypoint promtool \
  -v "${ROOT_DIR}/config/prometheus:/etc/prometheus:ro" \
  "${PROMETHEUS_VALIDATE_IMAGE:-prom/prometheus:latest}" \
  check config /etc/prometheus/prometheus.yaml

echo "validating Loki config"
docker run --rm \
  -v "${ROOT_DIR}/config/loki/loki.yaml:/etc/loki/loki.yaml:ro" \
  -v "${ROOT_DIR}/detections/loki:/loki/rules/fake:ro" \
  "${LOKI_VALIDATE_IMAGE:-grafana/loki:latest}" \
  -config.file=/etc/loki/loki.yaml -verify-config=true

echo "validating repository guardrails"
./scripts/docs-structure-test.sh
./scripts/identity-secrets-test.sh
./scripts/production-deployment-test.sh
./scripts/restore-test.sh
./scripts/auditability-test.sh

if [[ "${VALIDATE_ALL_LIVE:-0}" == "1" ]]; then
  echo "running live validation"
  ./scripts/siem-smoke-test.sh
  SIEM_LOAD_TEST_EVENTS="${SIEM_LOAD_TEST_EVENTS:-100}" SIEM_LOAD_TEST_TARGET_EPS="${SIEM_LOAD_TEST_TARGET_EPS:-50}" ./scripts/siem-load-test.sh
  ./scripts/detection-test.sh
  ./scripts/alert-routing-test.sh
  ./scripts/security-boundary-test.sh
else
  echo "skipping live validation; set VALIDATE_ALL_LIVE=1 to run smoke and routing tests"
fi

echo "validate-all passed"
