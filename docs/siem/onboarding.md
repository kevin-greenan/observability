# Data Onboarding

The collector supports three easy onboarding paths:

- File drop
- Syslog TCP/UDP
- Token-authenticated HTTP Event Collector

## File Drop

The simplest local path is a file drop:

1. Create a folder under `ingest/` for the source family.
2. Copy or stream events into that folder.
3. Query `{job="siem-file-collector"}` in Grafana.

Example:

```text
ingest/
├── identity/okta.jsonl
├── network/firewall.log
├── endpoint/edr.jsonl
└── cloud/aws-cloudtrail.json
```

Sample events live under `examples/ingest/samples/` so the default drop zone stays quiet until you intentionally add data.

## Supported Inputs

The default collector watches:

- `*.log`
- `*.json`
- `*.jsonl`
- `*.csv`
- `*.txt`

Use newline-delimited events when possible. For JSON, prefer one event per line.

## Labels

The collector sends these Loki labels:

| Label | Meaning |
| --- | --- |
| `job` | Always `siem-file-collector` |
| `source_type` | Defaults to `auto` |
| `parse_status` | `json`, `csv`, `key_value`, or `raw` |

The source file path is stored in `siem.ingest_path` inside the event body, not as a Loki label.

Keep labels low-cardinality. Do not promote usernames, IP addresses, process IDs, hostnames, filenames, request IDs, or other high-cardinality values to labels by default. Query them from event fields or raw text instead.

## Format Handling

The collector does not require source-specific parsers.

- JSON: extracted automatically.
- CSV: split automatically into `csv.fields` when the event came from a `.csv` file.
- Key/value and logfmt-like data: extracted automatically when possible.
- Unknown text: stored raw.

This mirrors the useful part of search-first SIEM onboarding: collect first, search immediately, improve interpretation later.

After generic parsing, the collector adds canonical aliases for common analyst fields such as `event.action`, `event.outcome`, `user.name`, `source.ip`, `destination.ip`, `host.name`, `process.name`, and `process.command_line`. See [Field conventions](field-conventions.md).

## Production Pattern

For real sources, keep data outside the repository and point `.env` at that path:

```env
SIEM_INGEST_DIR=/srv/siem-ingest
```

Then create source folders:

```bash
mkdir -p /srv/siem-ingest/{identity,network,endpoint,cloud}
```

Avoid writing regulated data, credentials, or customer logs into the Git worktree.

## Syslog

Send RFC3164 or RFC5424 syslog to the collector:

| Protocol | Address |
| --- | --- |
| TCP | `localhost:5514` |
| UDP | `localhost:5514` |

Local smoke-test example:

```bash
bash -c 'printf "<34>1 %s lab-host vpn - - - login failed user=alice src_ip=203.0.113.10\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > /dev/tcp/127.0.0.1/5514'
```

For appliances, point the device's syslog destination at the host running Docker and port `5514`. If you need privileged port `514`, map host port `514` to container port `5514` in `.env` or Compose after deciding how you want to handle host-level permissions.

## HTTP Event Collector

The collector exposes a token-authenticated HTTP event endpoint:

```text
http://localhost:8088/event
```

The default token is `change-me`. Set a real token in `.env`:

```env
SIEM_HTTP_EVENT_TOKEN=replace-with-a-long-random-token
```

Send an event:

```bash
curl -s http://localhost:8088/event \
  -H 'Authorization: Bearer change-me' \
  -H 'Content-Type: application/json' \
  -d '{"event":{"event.action":"login","event.outcome":"failure","user.name":"alice","source.ip":"203.0.113.10"}}'
```

Send plain text:

```bash
curl -s http://localhost:8088/event \
  -H 'Authorization: Bearer change-me' \
  -H 'Content-Type: application/json' \
  -d '{"event":"raw text event user=alice action=login outcome=failure"}'
```

Events are normalized under the source type `http_event_collector`.
The source inventory enriches these events with `source_id="http-event"`.

Query HTTP collector events:

```logql
{job="siem-file-collector", source_type="http_event_collector"}
```

## Input Ports

| Environment variable | Default | Purpose |
| --- | --- | --- |
| `SIEM_COLLECTOR_HTTP_BIND_ADDRESS` | `127.0.0.1` | Vector diagnostics bind address |
| `SIEM_COLLECTOR_HTTP_PORT` | `8686` | Vector diagnostics API |
| `SIEM_COLLECTOR_METRICS_BIND_ADDRESS` | `127.0.0.1` | Vector metrics bind address |
| `SIEM_COLLECTOR_METRICS_PORT` | `9598` | Vector Prometheus metrics |
| `SIEM_HTTP_EVENT_BIND_ADDRESS` | `127.0.0.1` | HTTP event ingest bind address |
| `SIEM_HTTP_EVENT_PORT` | `8088` | Token-authenticated HTTP event ingest |
| `SIEM_SYSLOG_TCP_BIND_ADDRESS` | `127.0.0.1` | Syslog TCP bind address |
| `SIEM_SYSLOG_TCP_PORT` | `5514` | Syslog over TCP |
| `SIEM_SYSLOG_UDP_BIND_ADDRESS` | `127.0.0.1` | Syslog UDP bind address |
| `SIEM_SYSLOG_UDP_PORT` | `5514` | Syslog over UDP |
| `SIEM_EDGE_HTTPS_BIND_ADDRESS` | `0.0.0.0` | Optional TLS edge proxy bind address |
| `SIEM_EDGE_HTTPS_PORT` | `8443` | Optional TLS edge proxy port |

Keep backend and diagnostics ports bound to `127.0.0.1` unless you have a firewall rule and owner for the exposure. See [Security model](security-model.md).

## Source Inventory

After adding a new source family, update `config/vector/lookups/sources.csv` so events carry ownership, criticality, parser expectations, and freshness metadata. See [Source inventory](source-inventory.md).
