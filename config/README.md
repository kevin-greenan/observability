# Configuration

Runtime configuration is grouped by service:

| Path | Purpose |
| --- | --- |
| `alloy/` | Grafana Alloy Docker log collection. |
| `grafana/` | Grafana data source, dashboard, plugin, and alerting provisioning. |
| `loki/` | Loki storage, query, retention, and ruler configuration. |
| `mimir/` | Mimir single-binary metrics backend configuration. |
| `prometheus/` | Prometheus scraping and remote-write configuration. |
| `proxy/` | Optional Caddy TLS edge proxy configuration. |
| `tempo/` | Tempo trace backend configuration. |
| `vector/` | SIEM collector pipelines, source inventory, and lookup enrichment. |

Run `make validate-all` after configuration changes.
