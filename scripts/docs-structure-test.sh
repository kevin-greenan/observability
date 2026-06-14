#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

require_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    echo "missing required documentation file: ${file}" >&2
    exit 1
  fi
}

require_text() {
  local file="$1"
  local pattern="$2"
  if ! grep -Eiq "${pattern}" "${file}"; then
    echo "missing expected documentation text in ${file}: ${pattern}" >&2
    exit 1
  fi
}

require_absent_text() {
  local pattern="$1"
  shift
  if grep -Eirn "${pattern}" "$@" >/tmp/docs-structure-test.matches; then
    cat /tmp/docs-structure-test.matches >&2
    rm -f /tmp/docs-structure-test.matches
    echo "stale documentation reference found: ${pattern}" >&2
    exit 1
  fi
  rm -f /tmp/docs-structure-test.matches
}

require_file README.md
require_file docs/README.md
require_file docs/siem/README.md
require_file docs/siem/milestones.md
require_file docs/siem/runbooks/README.md
require_file config/README.md
require_file dashboards/README.md
require_file deploy/README.md
require_file detections/README.md

require_text README.md "docs/README.md"
require_text README.md "deploy/"
require_text README.md "detections/"
require_text docs/README.md "SIEM Framework"
require_text docs/siem/README.md "Operational workflows"
require_text docs/siem/README.md "Production and governance"
require_text docs/siem/milestones.md "On-Platform Case and Incident Management"
require_text docs/siem/milestones.md "SOC Tool Integrations"
require_text docs/siem/milestones.md "Jira"
require_text docs/siem/milestones.md "ServiceNow"
require_text docs/siem/milestones.md "PagerDuty"
require_text docs/siem/milestones.md "fully production-ready security platform"
require_text docs/siem/runbooks/README.md "Current Runbooks"

require_absent_text "initial milestones|codex/siem-" README.md docs .github

echo "docs-structure-test passed"
