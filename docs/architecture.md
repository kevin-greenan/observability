# Architecture

This stack is designed for local development and repeatable observability experiments. It keeps each LGTM backend separate so configuration and failure modes are visible.

## Data Flow

```mermaid
flowchart LR
  docker["Docker containers"] --> alloy["Grafana Alloy"]
  files["SIEM file drop"] --> vector["Vector SIEM collector"]
  syslog["Syslog TCP/UDP"] --> vector
  http["HTTP Event Collector"] --> vector
  vector --> loki
  vector --> prometheus
  alloy --> loki["Loki"]
  prometheus["Prometheus"] --> mimir["Mimir"]
  telemetrygen["Telemetrygen"] --> tempo["Tempo"]
  grafana["Grafana"] --> loki
  grafana --> mimir
  grafana --> tempo
```

## Components

| Component | Role | Persistence |
| --- | --- | --- |
| Grafana | UI, data source provisioning, exploration | `grafana-data` |
| Loki | Log storage and query API | `loki-data` |
| Tempo | Trace storage and OTLP ingestion | `tempo-data` |
| Mimir | Prometheus-compatible long-term metrics backend | `mimir-data` |
| Prometheus | Scrapes local services and remote-writes to Mimir | `prometheus-data` |
| Alloy | Collects Docker container logs and its own metrics | `alloy-data` |
| Vector | Collects drop-zone SIEM files and forwards raw-first events to Loki | `vector-data` |

## Persistence Model

Docker named volumes hold service state. The Compose project can be stopped with `docker compose down` without deleting state. Use `make clean` when you intentionally want a fresh environment.

## Configuration Model

Runtime configuration is split by component under `config/`.

- `config/grafana/provisioning/datasources/datasources.yaml` wires Grafana to Loki, Mimir, and Tempo.
- `config/loki/loki.yaml` runs Loki in single-node filesystem mode with one week retention.
- `config/tempo/tempo.yaml` enables OTLP ingestion and local trace storage.
- `config/mimir/mimir.yaml` runs Mimir in single-binary filesystem mode.
- `config/prometheus/prometheus.yaml` scrapes stack metrics and remote-writes them to Mimir.
- `config/alloy/config.alloy` discovers Docker containers and forwards logs to Loki.
- `config/vector/vector.yaml` watches the SIEM ingest drop zone and forwards events to Loki.
- `detections/loki/security-rules.yaml` is mounted into Loki's local ruler path.
- `dashboards/grafana/siem-overview.json` is provisioned into Grafana.

## Local-Only Assumptions

This is not a full production deployment. It intentionally uses single replicas, filesystem storage, and local credentials. The optional `edge` profile provides a testable TLS boundary for Grafana and HTTP event ingest, but production still needs durable storage, identity integration, managed secrets, resource limits, and a high-availability topology.
