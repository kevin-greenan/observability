# Field Conventions

This SIEM stays raw-first: ingestion should not depend on a source-specific parser. Field conventions exist to make common searches and detections easier when generic parsing already exposes obvious aliases.

The collector preserves the original event in `event.original` and keeps vendor fields whenever possible. Canonical fields are added as literal dotted keys, such as `source.ip` and `user.name`, so analysts can query consistent names without forcing every payload into a nested schema.

## Canonical Fields

| Canonical field | Meaning | Common aliases |
| --- | --- | --- |
| `event.action` | Activity or operation name | `event_action`, `action` |
| `event.outcome` | Result of the activity | `event_outcome`, `outcome`, `result` |
| `user.name` | Primary user or account | `user_name`, `username`, `user` |
| `source.ip` | Source IP address | `source_ip`, `src_ip`, `client_ip` |
| `destination.ip` | Destination IP address | `destination_ip`, `dest_ip`, `dst_ip` |
| `destination.port` | Destination network port | `destination_port`, `dest_port`, `dst_port` |
| `host.name` | Host, device, or workload name | `host_name`, `hostname`, `host` |
| `process.name` | Process image or executable name | `process_name`, `process` |
| `process.command_line` | Full process command line | `process_command_line`, `command_line`, `cmdline`, `cmd`, `command` |
| `network.transport` | Network transport protocol | `network_transport`, `transport`, `proto`, `protocol` |

## Normalization Rules

- Preserve `event.original` for every event.
- Preserve source-provided fields unless a later, source-specific parser is intentionally reviewed and tested.
- Add canonical fields only from broadly common aliases.
- Keep canonical fields out of Loki labels by default. Usernames, IPs, hostnames, process names, and command lines are too high-cardinality for labels.
- Prefer query-time parsing for source-specific meaning that only one detection or dashboard needs.
- Add a source-specific parser only when the source is long-lived, high-value, covered by fixtures, and reused by multiple detections or dashboards.

## Examples

Key/value input:

```text
action=login outcome=failure user=alice src_ip=203.0.113.10 dst_ip=10.0.1.20 dst_port=443 proto=tcp
```

Canonical fields added by the collector:

```json
{
  "event.action": "login",
  "event.outcome": "failure",
  "user.name": "alice",
  "source.ip": "203.0.113.10",
  "destination.ip": "10.0.1.20",
  "destination.port": "443",
  "network.transport": "tcp"
}
```

JSON input that already uses canonical fields keeps those values:

```json
{
  "event.action": "process_start",
  "process.name": "powershell.exe",
  "process.command_line": "powershell.exe -NoProfile"
}
```

## Query Examples

Find failed logins regardless of whether the source used `user`, `username`, or `user.name`:

```logql
{job="siem-file-collector"} | json | event_action="login" | event_outcome="failure"
```

Find traffic to SSH from sources that use `dst_ip`, `destination_ip`, or `destination.ip`:

```logql
{job="siem-file-collector"} | json | destination_port="22"
```

Find suspicious process commands:

```logql
{job="siem-file-collector"} | json | process_command_line=~".*(?i)(encodedcommand|downloadstring|bypass).*"
```

Grafana and Loki flatten dotted JSON keys for query fields, so `event.action` appears as `event_action` after `| json`.

## Parser Debt Guardrail

If a proposed change adds a new vendor-specific parser, include:

- Representative sample events.
- Expected normalized output.
- Detection or dashboard consumers.
- A rollback note for disabling the parser without dropping raw ingestion.

If those artifacts do not exist, onboard the source raw-first and document query-time parsing instead.
