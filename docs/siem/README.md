# SIEM Framework

This repository can use the LGTM stack as a lightweight SIEM foundation:

- **Loki** stores raw security events and supports fast search with LogQL.
- **Grafana** provides investigation, dashboards, and alerting workflows.
- **Mimir** stores security metrics and detection counters.
- **Tempo** stores traces when applications emit security-relevant spans.
- **Vector** provides a file-based data onboarding collector.

The guiding design is **raw first, normalize lightly, parse late**. Every event should be searchable even when its format is unknown. When data is JSON, CSV, or key/value, the collector extracts fields opportunistically. Syslog-like and custom text is still stored as raw searchable data and can be parsed at query time without maintaining a permanent parser.

## What This Is

This is a SIEM framework and local lab foundation, not a complete enterprise SIEM product. It gives you:

- A standard place to onboard data.
- A collector that accepts mixed event formats over files, syslog, and token-authenticated HTTP.
- A simple event envelope for source metadata.
- Static lookup enrichment for reference data like asset inventory.
- Mounted detection examples that run against raw events.
- A provisioned SIEM overview dashboard.
- A repeatable smoke test for core ingestion paths.
- Documentation for adding sources without creating long-lived parsers.

## Core Principle

Do not block ingestion on parsing.

Parsing should improve investigation quality, but it should not decide whether an event is kept. The collector preserves every original event in `event.original`, attaches stable labels like `job`, `source_type`, and `parse_status`, and keeps the source path in `siem.ingest_path`.

## Start

```bash
cp .env.example .env
docker compose up -d
```

Send events through one of the collector inputs:

- Drop files into `ingest/` or point `SIEM_INGEST_DIR` at another directory in `.env`.
- Send syslog to `localhost:5514` over TCP or UDP.
- Send HTTP collector events to `http://localhost:8088/event`.

Example:

```env
SIEM_INGEST_DIR=/var/log/security-ingest
SIEM_HTTP_EVENT_TOKEN=replace-with-a-real-token
```

HTTP collector example:

```bash
curl -s http://localhost:8088/event \
  -H 'Authorization: Bearer change-me' \
  -H 'Content-Type: application/json' \
  -d '{"event":{"source":"manual","event.action":"test","message":"hello from http collector"}}'
```

The event is labeled internally as `source_type="http_event_collector"`.

Syslog example:

```bash
bash -c 'printf "<34>1 %s lab-host app - - - hello from syslog user=alice action=login\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > /dev/tcp/127.0.0.1/5514'
```

## Explore

In Grafana Explore, select `Loki`.

All SIEM events:

```logql
{job="siem-file-collector"}
```

JSON-parsed events:

```logql
{job="siem-file-collector", parse_status="json"}
```

Raw fallback events:

```logql
{job="siem-file-collector", parse_status="raw"}
```

Search original text:

```logql
{job="siem-file-collector"} |= "powershell"
```

Parse JSON at query time:

```logql
{job="siem-file-collector"} | json
```

Parse key/value at query time:

```logql
{job="siem-file-collector"} | logfmt
```

Enriched events:

```logql
{job="siem-file-collector"} | json | asset_criticality="high"
```

More docs:

- [Data onboarding](onboarding.md)
- [Parser strategy](parser-strategy.md)
- [Static lookups](lookups.md)
- [Detections](detections.md)
- [Detection lifecycle](detection-lifecycle.md)
- [Production readiness](production-readiness.md)
- [Production milestones](milestones.md)
