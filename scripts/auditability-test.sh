#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

require_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "missing required file: ${file}" >&2
    exit 1
  fi
}

require_text() {
  local file="$1"
  local pattern="$2"
  if ! grep -Eiq "${pattern}" "${file}"; then
    echo "missing expected text in ${file}: ${pattern}" >&2
    exit 1
  fi
}

require_file docs/siem/auditability.md
require_file .github/PULL_REQUEST_TEMPLATE.md
require_file .github/PULL_REQUEST_TEMPLATE/detection.md
require_file .github/PULL_REQUEST_TEMPLATE/source-onboarding.md
require_file .github/PULL_REQUEST_TEMPLATE/lookup-update.md

require_text docs/siem/auditability.md "Grafana OSS"
require_text docs/siem/auditability.md "Grafana Enterprise|Grafana Cloud"
require_text docs/siem/auditability.md "source onboarding"
require_text docs/siem/auditability.md "lookup"
require_text docs/siem/auditability.md "token rotation"
require_text docs/siem/auditability.md "pull requests|PR"

require_text .github/PULL_REQUEST_TEMPLATE.md "make validate-all"
require_text .github/PULL_REQUEST_TEMPLATE.md "Rollback"
require_text .github/PULL_REQUEST_TEMPLATE.md "Audit Evidence"

require_text .github/PULL_REQUEST_TEMPLATE/detection.md "Owner"
require_text .github/PULL_REQUEST_TEMPLATE/detection.md "Runbook"
require_text .github/PULL_REQUEST_TEMPLATE/detection.md "make detection-test"

require_text .github/PULL_REQUEST_TEMPLATE/source-onboarding.md "config/vector/lookups/sources.csv"
require_text .github/PULL_REQUEST_TEMPLATE/source-onboarding.md "Source owner"
require_text .github/PULL_REQUEST_TEMPLATE/source-onboarding.md "Expected daily volume|Freshness target"

require_text .github/PULL_REQUEST_TEMPLATE/lookup-update.md "Source of truth"
require_text .github/PULL_REQUEST_TEMPLATE/lookup-update.md "private storage"

echo "auditability-test passed"
