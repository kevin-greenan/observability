#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

WORK_DIR="$(mktemp -d)"
BACKUP_FILE="${WORK_DIR}/siem-config-backup.tgz"
RESTORE_DIR="${WORK_DIR}/restore"
MANIFEST="${WORK_DIR}/manifest.sha256"

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

require tar
require shasum

echo "creating config backup artifact"
tar -czf "${BACKUP_FILE}" config dashboards detections docs/siem Makefile docker-compose.yml .env.example

echo "recording backup manifest"
shasum -a 256 config/loki/loki.yaml config/mimir/mimir.yaml config/tempo/tempo.yaml detections/loki/security-rules.yaml dashboards/grafana/siem-overview.json > "${MANIFEST}"

echo "restoring config artifact"
mkdir -p "${RESTORE_DIR}"
tar -xzf "${BACKUP_FILE}" -C "${RESTORE_DIR}"

echo "validating restored files"
(
  cd "${RESTORE_DIR}"
  shasum -a 256 -c "${MANIFEST}"
  test -f docs/siem/backup-restore.md
  test -f docs/siem/capacity-planning.md
  test -f docs/siem/storage-backends.md
)

echo "restore test passed"
