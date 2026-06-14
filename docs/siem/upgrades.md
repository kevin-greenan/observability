# Upgrades and Change Management

Production-pilot deployments must use pinned image references and repeatable validation. Local lab defaults may still use easy tags such as `latest`, but `deploy/compose/production/.env.production.example` pins every image to an immutable digest.

## Version Matrix

| Component | Local default | Production-pilot pin source |
| --- | --- | --- |
| Grafana | `GRAFANA_IMAGE` in `.env.example` | `GRAFANA_IMAGE` digest in `deploy/compose/production/.env.production.example` |
| Loki | `LOKI_IMAGE` in `.env.example` | `LOKI_IMAGE` digest in production env template |
| Tempo | `TEMPO_IMAGE` in `.env.example` | `TEMPO_IMAGE` digest in production env template |
| Mimir | `MIMIR_IMAGE` in `.env.example` | `MIMIR_IMAGE` digest in production env template |
| Prometheus | `PROMETHEUS_IMAGE` in `.env.example` | `PROMETHEUS_IMAGE` digest in production env template |
| Alloy | `ALLOY_IMAGE` in `.env.example` | `ALLOY_IMAGE` digest in production env template |
| Vector | `VECTOR_IMAGE` in `.env.example` | `VECTOR_IMAGE` digest in production env template |
| Caddy | `CADDY_IMAGE` in `.env.example` | `CADDY_IMAGE` digest in production env template |
| BusyBox | `BUSYBOX_IMAGE` in `.env.example` | `BUSYBOX_IMAGE` digest in production env template |
| Telemetry generator | `TELEMETRYGEN_IMAGE` in `.env.example` | `TELEMETRYGEN_IMAGE` digest in production env template |

Use digests for production so rebuilds and restarts do not silently move to a newer image.

## Upgrade Cadence

- Review upstream releases monthly.
- Patch critical security fixes as soon as practical.
- Batch routine upgrades into one PR when possible.
- Upgrade one storage backend family at a time when release notes mention schema, retention, compactor, ruler, or object storage changes.

## Changelog Review

For every upgrade PR, review release notes for:

- Breaking configuration changes.
- Storage schema or retention changes.
- Alerting and ruler behavior.
- Dashboard or provisioning changes.
- Authentication, authorization, and secret handling changes.
- Known data loss, query correctness, or ingestion issues.

Record reviewed links and decisions in the PR description.

## Validation

Run static validation:

```bash
make validate-all
```

Run live validation against a started stack:

```bash
VALIDATE_ALL_LIVE=1 make validate-all
```

Live validation runs smoke, detection, alert-routing, security-boundary, and production deployment tests. Use it before merging image upgrades.

## Upgrade Procedure

1. Create a branch from current `main`.
2. Update image digests in `deploy/compose/production/.env.production.example`.
3. If needed, update local lab defaults in `.env.example`.
4. Review upstream changelogs and document notable changes in the PR.
5. Run `make validate-all`.
6. Start the stack and run `VALIDATE_ALL_LIVE=1 make validate-all`.
7. Confirm Grafana dashboards load and Loki detection rules evaluate.
8. Merge only after validation evidence is attached to the PR.

## Rollback Procedure

1. Identify the last known-good commit or image digest set.
2. Revert the upgrade commit or restore the prior production env template.
3. Recreate affected services:

```bash
docker compose --profile edge up -d --force-recreate
```

4. Run `make validate-all`.
5. Run targeted live checks for the affected component.
6. Record the rollback reason, impact window, and follow-up owner.

If storage schema changes were applied, confirm rollback compatibility before restarting older binaries.

## Change Types

| Change | Required validation |
| --- | --- |
| Image digest update | `make validate-all`, live validation, changelog review |
| Loki rule change | `make detection-test` |
| Grafana dashboard change | `jq`/`validate-all`, Grafana provisioning check |
| Vector config change | Vector validate and `make siem-smoke-test` |
| Alert routing change | `make alert-routing-test` |
| TLS/proxy change | `make security-boundary-test` |
| Secret handling change | `make identity-secrets-test` |
| Backup/restore change | `make restore-test` |
