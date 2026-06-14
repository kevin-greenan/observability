# Backup and Restore

This stack currently stores runtime data in Docker volumes and configuration in Git. Production should use object storage for Loki, Mimir, and Tempo data; until then, treat Docker volume backups as pilot-only recovery.

## What to Back Up

| Artifact | Source | Backup method |
| --- | --- | --- |
| Grafana provisioning | `config/grafana/` | Git and release artifact. |
| Grafana dashboards | `dashboards/grafana/` | Git and release artifact. |
| Loki config and rules | `config/loki/`, `detections/loki/` | Git and release artifact. |
| Detection tests | `detections/tests/` | Git and release artifact. |
| Vector config and non-sensitive lookups | `config/vector/` | Git and release artifact. |
| Mimir, Tempo, Prometheus config | `config/mimir/`, `config/tempo/`, `config/prometheus/` | Git and release artifact. |
| Runtime Loki/Mimir/Tempo data | Docker volumes | Pilot-only volume snapshot or object storage replication. |
| Secrets | Secret manager | Never back up through this repository. |

## Config Backup

Create a portable config artifact:

```bash
tar -czf siem-config-backup.tgz \
  config dashboards detections docs/siem Makefile docker-compose.yml .env.example
```

Restore into a clean checkout:

```bash
tar -xzf siem-config-backup.tgz -C /path/to/clean/checkout
make validate
make identity-secrets-test
```

Run the included restore drill:

```bash
make restore-test
```

The drill creates a temporary config artifact, restores it into a temporary directory, and verifies key files and checksums.

## Docker Volume Backup

For pilot-only local recovery, stop writers and snapshot named volumes:

```bash
docker compose stop grafana loki mimir tempo prometheus siem-collector
docker run --rm -v observability_loki-data:/volume -v "$PWD/tmp/backups:/backup" busybox tar -czf /backup/loki-data.tgz -C /volume .
docker run --rm -v observability_mimir-data:/volume -v "$PWD/tmp/backups:/backup" busybox tar -czf /backup/mimir-data.tgz -C /volume .
docker run --rm -v observability_tempo-data:/volume -v "$PWD/tmp/backups:/backup" busybox tar -czf /backup/tempo-data.tgz -C /volume .
docker compose up -d
```

Restore a pilot volume only into a stopped stack:

```bash
docker compose stop loki
docker run --rm -v observability_loki-data:/volume -v "$PWD/tmp/backups:/backup" busybox sh -c 'rm -rf /volume/* && tar -xzf /backup/loki-data.tgz -C /volume'
docker compose up -d loki
```

## Restore Validation

After restoring:

1. Run `make validate`.
2. Start the stack.
3. Run `make siem-smoke-test`.
4. Run `make detection-test`.
5. Confirm Grafana dashboards load.
6. Query Loki for expected historical data if runtime volumes were restored.
7. Record restore duration, data loss window, and any failed checks.

## RTO and RPO Targets

Set target values before production use:

| Target | Pilot default | Production decision |
| --- | --- | --- |
| RTO | Best effort | Define by security operations requirement. |
| RPO for config | Last merged Git commit | Usually last merged Git commit. |
| RPO for events | Last volume snapshot | Object storage replication or managed backend SLA. |
| Restore test frequency | Manual per major change | At least quarterly. |

