# Production Architecture

The selected deployment target for this repository is a single-host Docker Compose production pilot with a TLS edge proxy, secret-file override pattern, and documented durable storage migration path.

It is suitable for a small-team pilot after the security boundary, identity, secrets, retention, and restore controls are in place. It is not a highly available production platform.

## Selected Runtime Target

The selected runtime target is:

- Single-host Docker Compose production pilot.
- Backend APIs bound to loopback by default.
- Optional Caddy TLS edge proxy for Grafana and HTTP event ingest.
- SSO and managed secrets required before production security data.
- Syslog exposed only when the host firewall restricts sender networks.
- Direct Loki, Mimir, Tempo, Prometheus, Alloy, and Vector diagnostic access kept private.

Kubernetes ingress or managed Grafana/Loki/Mimir/Tempo remain later scale-out targets, not the current repo target.

## Deployment Modes

| Mode | Command | Purpose |
| --- | --- | --- |
| Local lab | `docker compose up -d` | All service APIs available on `localhost` only. |
| Security-boundary pilot | `docker compose --profile edge up -d` | Adds TLS edge proxy on `8443`. |
| Production Compose pilot | `docker compose --env-file deploy/compose/production/.env.production.example -f docker-compose.yml -f deploy/compose/production/docker-compose.production.example.yml -f deploy/compose/production/docker-compose.secrets.example.yml --profile edge up -d` | Single-host pilot with TLS edge, secret files, logging limits, and lab generators disabled. |
| Future HA production | To be designed later | Kubernetes, managed Grafana stack, or another HA runtime. |

## Deployment Layout

Production-pilot files live under:

```text
deploy/compose/production/
```

| File | Purpose |
| --- | --- |
| `.env.production.example` | Environment template with private backend binds and public edge bind. |
| `docker-compose.production.example.yml` | Production-pilot Compose override. |
| `docker-compose.secrets.example.yml` | Secret-file override pattern. |
| `README.md` | Operator start pattern and promotion checklist. |

## External Surfaces

For the security-boundary pilot, expose only:

- `8443/tcp` for Grafana and HTTP event ingest through TLS.
- `5514/tcp` and/or `5514/udp` only for approved syslog senders.

Everything else should remain bound to `127.0.0.1`, accessible only from the SIEM host or containers on the Compose network.

## TLS

The included Caddy config uses `tls internal` for a testable local TLS path. Production should use one of:

- Organization internal CA certificate.
- Public CA certificate for an externally resolvable endpoint.
- Managed load balancer or ingress TLS if the deployment moves off single-host Compose.

Run:

```bash
make security-boundary-test
```

This starts the edge proxy, checks Grafana through HTTPS, and sends a bearer-token HTTP event through the HTTPS route.

## Production Gaps

Before using this with sensitive production security data, complete and routinely run:

- `make security-boundary-test`
- `make identity-secrets-test`
- `make restore-test`
- `make production-deployment-test`

Remaining production hardening is tracked by the upgrade/release, capacity/load, and auditability milestones.
