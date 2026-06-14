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
require ruby

echo "validating production Compose deployment target"
docker compose \
  --env-file deploy/compose/production/.env.production.example \
  -f docker-compose.yml \
  -f deploy/compose/production/docker-compose.production.example.yml \
  -f deploy/compose/production/docker-compose.secrets.example.yml \
  --profile edge \
  config --quiet

echo "validating production deployment documentation"
ruby -ryaml -e '
  required_files = %w[
    deploy/compose/production/README.md
    deploy/compose/production/.env.production.example
    deploy/compose/production/docker-compose.production.example.yml
    deploy/compose/production/docker-compose.secrets.example.yml
    docs/siem/production-architecture.md
  ]
  missing = required_files.reject { |path| File.exist?(path) }
  abort("missing files: #{missing.join(", ")}") unless missing.empty?

  arch = File.read("docs/siem/production-architecture.md")
  abort("architecture must select single-host Docker Compose") unless arch.include?("single-host Docker Compose production pilot")
  abort("architecture must distinguish pilot from HA") unless arch.include?("not a highly available")
  %w[tls secrets storage upgrade].each do |term|
    abort("architecture missing #{term}") unless arch.downcase.include?(term)
  end

  env = File.read("deploy/compose/production/.env.production.example")
  abort("production env must bind edge publicly") unless env.include?("SIEM_EDGE_HTTPS_BIND_ADDRESS=0.0.0.0")
  abort("production env must keep Loki private") unless env.include?("LOKI_HTTP_BIND_ADDRESS=127.0.0.1")

  override = YAML.load_file("deploy/compose/production/docker-compose.production.example.yml")
  services = override.fetch("services")
  abort("edge proxy must be in edge profile") unless services.fetch("edge-proxy").fetch("profiles").include?("edge")
  abort("log generator must be gated") unless services.fetch("log-generator").fetch("profiles").include?("lab-generators")
'

echo "production deployment target test passed"
