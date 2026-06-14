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

require ruby

echo "validating identity and secrets documentation"
ruby -ryaml -e '
  required_files = %w[
    docs/siem/identity-rbac.md
    docs/siem/secrets.md
    deploy/compose/production/docker-compose.secrets.example.yml
    secrets/README.md
  ]
  missing = required_files.reject { |path| File.exist?(path) }
  abort("missing files: #{missing.join(", ")}") unless missing.empty?

  rbac = File.read("docs/siem/identity-rbac.md")
  %w[Security\ analyst Detection\ engineer Platform\ administrator Service\ account].each do |term|
    abort("missing RBAC persona: #{term}") unless rbac.include?(term.gsub("\\", ""))
  end
  %w[Viewer Editor Admin].each do |role|
    abort("missing Grafana role: #{role}") unless rbac.include?(role)
  end
  abort("identity doc must require centralized identity") unless rbac.include?("centralized identity")
  abort("identity doc must describe break-glass") unless rbac.include?("Break-Glass")

  secrets = File.read("docs/siem/secrets.md")
  %w[Grafana\ bootstrap\ admin\ password SIEM\ HTTP\ event\ token Grafana\ OAuth\ client\ secret Rotation\ Process].each do |term|
    abort("missing secrets guidance: #{term}") unless secrets.include?(term.gsub("\\", ""))
  end
  abort("secrets doc must forbid .env as production store") unless secrets.include?("Do not use `.env` as a production secret store")

  env = File.read(".env.example")
  abort(".env.example must label local lab defaults") unless env.include?("Local lab defaults only")
  abort(".env.example must mark SIEM token placeholder") unless env.include?("local-only placeholder")

  gitignore = File.read(".gitignore")
  abort(".gitignore must ignore .env.*") unless gitignore.include?(".env.*")
  abort(".gitignore must ignore local secret files") unless gitignore.include?("secrets/*")

  override = YAML.load_file("deploy/compose/production/docker-compose.secrets.example.yml")
  secrets_block = override.fetch("secrets")
  %w[grafana_admin_password grafana_oauth_client_secret siem_http_event_token].each do |name|
    abort("missing Compose secret: #{name}") unless secrets_block.key?(name)
  end
'

echo "identity and secrets test passed"
