# Production Compose Deployment

This directory contains the selected production pilot deployment target for this repository: single-host Docker Compose with a TLS edge proxy, managed secret inputs, and documented durable storage migration.

This target is appropriate for:

- Local lab promotion into a small-team pilot.
- A single SIEM host with explicit firewall rules.
- Security teams validating sources, detections, dashboards, and alert flow before choosing a high-availability runtime.

This target is not:

- A high-availability production architecture.
- A substitute for object storage, managed secrets, SSO, host monitoring, and restore drills.
- A multi-tenant managed SIEM.

## Files

| File | Purpose |
| --- | --- |
| `.env.production.example` | Production-pilot environment template with public edge listener and private backend bindings. |
| `docker-compose.production.example.yml` | Production-pilot override for TLS edge, logging limits, and disabling lab generators unless explicitly requested. |
| `docker-compose.secrets.example.yml` | Secret-file override pattern for Compose pilots. |

## Start Pattern

Create environment-specific secret files outside Git, copy the example env file, then run:

```bash
docker compose \
  --env-file deploy/compose/production/.env.production.example \
  -f docker-compose.yml \
  -f deploy/compose/production/docker-compose.production.example.yml \
  -f deploy/compose/production/docker-compose.secrets.example.yml \
  --profile edge \
  up -d
```

For a real deployment, copy `.env.production.example` to an untracked file and replace defaults with environment-specific values. Do not commit the copied file.

## Required Before Production Data

- SSO configured and tested.
- Grafana bootstrap password stored outside Git.
- SIEM HTTP event token loaded from a secret.
- TLS certificate source selected.
- Host firewall allows only approved senders.
- Loki/Mimir/Tempo durable storage plan approved.
- `make security-boundary-test`, `make identity-secrets-test`, and `make restore-test` pass.

## Promotion Path

1. Run the local lab with `docker compose up -d`.
2. Enable the edge profile and validate TLS with `make security-boundary-test`.
3. Add production secret handling with `docker-compose.secrets.example.yml`.
4. Apply this production override.
5. Run smoke, detection, alert-routing, identity/secrets, and restore tests.
6. Move runtime data to object storage or a managed backend before retention requirements exceed a pilot.
