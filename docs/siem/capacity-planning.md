# Capacity Planning

This worksheet sizes a single-host pilot and gives the inputs needed before moving to durable object storage or a larger deployment target.

## Retention Policy

| Data class | Default pilot retention | Production starting point | Notes |
| --- | --- | --- | --- |
| Security events in Loki | 7 days | 30-90 days hot, archive as required | Driven by source criticality and investigation needs. |
| Metrics in Mimir | 7 days | 30-180 days | Useful for source health, capacity, and alert history. |
| Traces in Tempo | Local blocks only | 7-30 days | Increase only when traces support incident response. |
| Grafana dashboards/provisioning | Git history | Git plus backup artifact | Treat as configuration, not runtime data. |
| Detection rules and tests | Git history | Git plus release artifact | Restore from Git first. |
| Lookup files | Git for non-sensitive lookups | Git or private artifact store | Sensitive enrichment data belongs in a secret manager or private storage. |

## Inputs

Fill this table for each onboarded source family:

| Source ID | Owner | Events/day | Avg event bytes | Daily GB | Retention days | Hot storage GB | Growth note |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| `http-event` | security-platform | 100 | 750 | 0.000075 | 30 | 0.00225 | Lab default. |
| `syslog` | network-security | 100 | 500 | 0.00005 | 30 | 0.0015 | Lab default. |
| `file-drop` | security-platform | 100 | 750 | 0.000075 | 30 | 0.00225 | Lab default. |

Formula:

```text
daily_gb = events_per_day * average_event_bytes / 1,000,000,000
hot_storage_gb = daily_gb * retention_days * compression_factor
```

Use `compression_factor=0.5` for a rough Loki estimate until measured with real data. Use `1.0` for conservative planning.

## Capacity Signals

The SIEM Overview dashboard includes:

- `SIEM Ingest Bytes by Source`: LogQL `bytes_over_time` estimate by `source_id`.
- `SIEM Collector Ingest Rate`: Vector source receive rate from Prometheus/Mimir.
- `Loki Request Latency p95`: backend query/request latency.
- `Vector Sink Errors`: collector delivery errors to downstream sinks.

Watch these with:

```logql
sum by (source_id) (bytes_over_time({job="siem-file-collector", source_id!=""}[1h]))
```

```promql
sum(rate(vector_component_received_events_total{component_id=~"siem_.*"}[5m]))
```

Run a synthetic load test before increasing expected source volume:

```bash
make siem-load-test
```

## Sizing Thresholds

For a single-host Compose pilot, set review thresholds before ingest grows:

| Signal | Review threshold | Action |
| --- | --- | --- |
| Loki hot data estimate | 50% of allocated disk | Add storage, reduce retention, or move to object storage. |
| Sustained collector ingest | Above expected source inventory rate for 30 minutes | Confirm source behavior or data loop. |
| Parser status `raw` spike | More than 25% above baseline | Review source format drift. |
| Backend disk free | Less than 20% | Stop onboarding new sources until storage is expanded. |

Docker Compose does not include host disk metrics by default. For production, add node-level filesystem monitoring or a managed host metric integration.

## Object Storage Trigger

Move Loki, Mimir, and Tempo data to durable object storage when any are true:

- Retention requirement exceeds what local disks can safely hold.
- Recovery requires restoring data after host loss.
- Multiple analysts depend on historical search.
- Compliance requires evidence retention.
- The deployment target moves beyond a lab or small pilot.
