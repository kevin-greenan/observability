# Deployment

Deployment overlays and operator examples live here.

| Path | Purpose |
| --- | --- |
| `compose/production/` | Single-host Docker Compose production-pilot example with TLS edge and secret-file override patterns. |

The repository's default `docker-compose.yml` is optimized for local lab use. Use the production Compose overlay only after reviewing [docs/siem/production-architecture.md](../docs/siem/production-architecture.md).
