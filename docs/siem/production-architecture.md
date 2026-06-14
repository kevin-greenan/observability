# Production Architecture

The current deployment target is a single-host Docker Compose pilot with a production-like security boundary. It is suitable for lab and small-team pilot use after the security boundary is enabled, but it is not a highly available production platform.

## Selected Boundary Pattern

For this milestone, the selected pattern is:

- Docker Compose single-host runtime.
- Backend APIs bound to loopback by default.
- Optional Caddy TLS edge proxy for Grafana and HTTP event ingest.
- Syslog exposed only when the host firewall restricts sender networks.
- Direct Loki, Mimir, Tempo, Prometheus, Alloy, and Vector diagnostic access kept private.

Kubernetes ingress or managed Grafana/Loki/Mimir/Tempo remain future deployment targets.

## Deployment Modes

| Mode | Command | Purpose |
| --- | --- | --- |
| Local lab | `docker compose up -d` | All service APIs available on `localhost` only. |
| Security-boundary pilot | `docker compose --profile edge up -d` | Adds TLS edge proxy on `8443`. |
| Future production | To be defined | HA runtime, managed secrets, durable object storage, and identity provider integration. |

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

Before using this with sensitive production security data, complete the later milestones for:

- Identity, RBAC, and secrets.
- Durable storage, retention, and backup.
- Upgrade and release management.
- Capacity and load testing.
- Auditability.

