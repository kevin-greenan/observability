# Operations

## Start

```bash
cp .env.example .env
docker compose up -d
```

## Stop

```bash
docker compose down
```

## Reset All Data

```bash
make clean
```

This removes the containers and named volumes.

## Validate Configuration

```bash
make validate
```

The validation script runs `docker compose config --quiet`.

## Query Examples

### Logs

In Grafana Explore, select `Loki`:

```logql
{compose_service="log-generator"}
```

### Metrics

In Grafana Explore, select `Mimir`:

```promql
up
```

Useful stack metrics:

```promql
prometheus_remote_storage_samples_total
tempo_distributor_spans_received_total
loki_request_duration_seconds_count
```

### Traces

In Grafana Explore, select `Tempo` and search recent traces. The `trace-generator` container continuously emits synthetic traces to Tempo through OTLP gRPC.

## Troubleshooting

### Grafana Cannot Reach a Data Source

Check service health from the Compose network:

```bash
docker compose ps
docker compose logs grafana loki tempo mimir
```

### No Logs in Loki

Verify Alloy can read Docker metadata and push to Loki:

```bash
docker compose logs alloy
docker compose logs log-generator
```

The Alloy container mounts `/var/run/docker.sock` read-only. If Docker socket access is blocked by your environment, container log discovery will not work.

### No Metrics in Mimir

Check Prometheus remote write status:

```bash
docker compose logs prometheus
```

Open Prometheus at http://localhost:9090 and check **Status > Targets**.

### No Traces in Tempo

Check the trace generator and Tempo distributor logs:

```bash
docker compose logs trace-generator tempo
```

Tempo receives OTLP on `4317` for gRPC and `4318` for HTTP.

## Upgrading Images

The image tags are centralized in `.env`. For reproducible environments, replace `latest` with pinned versions after testing:

```env
GRAFANA_VERSION=<tested-version>
LOKI_VERSION=<tested-version>
TEMPO_VERSION=<tested-version>
MIMIR_VERSION=<tested-version>
PROMETHEUS_VERSION=<tested-version>
ALLOY_VERSION=<tested-version>
```

Run `make validate` and restart the stack after changing tags.
