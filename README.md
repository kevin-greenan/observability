# LGTM Observability Stack

Docker Compose stack for local logging, metrics, and tracing with the Grafana LGTM components:

- **Loki** for logs
- **Grafana** for dashboards and exploration
- **Tempo** for traces
- **Mimir** for Prometheus-compatible metrics

The stack also includes Prometheus for local scraping and remote write, Grafana Alloy for Docker log collection, a small log generator, and an OpenTelemetry trace generator so the environment has sample telemetry after startup.

It also includes a starter SIEM framework with raw-first security event onboarding. See [docs/siem/README.md](docs/siem/README.md).

## Quick Start

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Open Grafana at [http://localhost:3000](http://localhost:3000).

Default credentials:

- Username: `admin`
- Password: `admin`

Change `GRAFANA_ADMIN_PASSWORD` in `.env` before using this outside a local workstation.

## Ports

| Service | URL | Purpose |
| --- | --- | --- |
| Grafana | http://localhost:3000 | Explore logs, metrics, and traces |
| Loki | http://localhost:3100 | Log backend API |
| Tempo | http://localhost:3200 | Trace backend API |
| Tempo OTLP gRPC | localhost:4317 | Trace ingest |
| Tempo OTLP HTTP | localhost:4318 | Trace ingest |
| Mimir | http://localhost:9009 | Metrics backend API |
| Prometheus | http://localhost:9090 | Local scraper and remote write source |
| Alloy | http://localhost:12345 | Collector UI and diagnostics |
| SIEM Collector | http://localhost:8686 | File-based security event collector diagnostics |
| SIEM HTTP Event Collector | http://localhost:8088 | Token-authenticated HTTP event ingestion |
| SIEM Syslog | localhost:5514 | TCP/UDP syslog ingestion |

## Repository Layout

```text
.
├── docker-compose.yml
├── .env.example
├── Makefile
├── config/
│   ├── alloy/
│   ├── grafana/
│   ├── loki/
│   ├── mimir/
│   ├── prometheus/
│   ├── tempo/
│   └── vector/
├── detections/
├── examples/
│   └── ingest/
├── docs/
│   ├── architecture.md
│   ├── operations.md
│   └── siem/
├── ingest/
└── scripts/
    └── validate.sh
```

## Common Commands

```bash
make up          # start the stack
make ps          # show service status
make logs        # follow logs from all services
make validate    # validate docker-compose.yml
make down        # stop containers and keep volumes
make clean       # stop containers and remove volumes
```

## First Checks

In Grafana:

1. Open **Explore**.
2. Select **Loki** and run `{compose_service="log-generator"}`.
3. Select **Mimir** and run `up`.
4. Select **Tempo** and search recent traces from `telemetrygen`.

The data sources are provisioned from `config/grafana/provisioning/datasources/datasources.yaml`.
