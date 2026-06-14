# Parser Strategy

The goal is to avoid long-term parser maintenance.

Traditional SIEM setups often accumulate one parser per vendor, product, version, and log flavor. That creates hidden operational drag. This stack uses a different rule:

> Store the raw event, extract fields only when extraction is generic and safe, and push source-specific interpretation to query packs or dashboards.

## Event Envelope

Every event should keep:

| Field | Purpose |
| --- | --- |
| `event.original` | The exact original event string |
| `event.kind` | Broad event type, default `event` |
| `event.category` | Broad category, default `security` |
| `observer.type` | Collector identity |
| `siem.parse_status` | `json`, `csv`, `key_value`, or `raw` |
| `siem.ingest_path` | Source file path |

## Lightweight Normalization

After automatic extraction, the collector adds canonical aliases for common fields when obvious source fields already exist. For example, `src_ip` becomes `source.ip`, `user` becomes `user.name`, and `cmd` becomes `process.command_line`.

This is not a source-specific parser layer. It is a small compatibility layer for common security concepts that keeps `event.original` and the original fields intact. See [Field conventions](field-conventions.md).

## Automatic Extraction

The default collector accepts files, syslog, and token-authenticated HTTP events. After ingest, it tries:

1. JSON object parsing.
2. Key/value parsing.
3. Raw fallback.

It intentionally does not reject events that fail parsing.

## CSV

CSV rows from `.csv` files are split into `csv.fields` automatically. The collector does not assign semantic column names by default because headers, delimiters, quoting, and field meanings vary by product. If a source must be deeply normalized, prefer changing the upstream export to JSON Lines instead of adding a custom parser here.

## Query-Time Parsing

Use LogQL when investigation needs fields:

```logql
{job="siem-file-collector"} | json
```

```logql
{job="siem-file-collector"} | logfmt
```

```logql
{job="siem-file-collector"} | pattern `<ts> <level> <message>`
```

This keeps source-specific interpretation close to the detection or dashboard that needs it.

## When To Add A Parser

Add source-specific parsing only when all are true:

- The source is high-value and long-lived.
- Generic extraction is not enough.
- The parser can be tested with representative samples.
- The normalized fields are used by multiple detections or dashboards.

Otherwise, keep the source raw-first.
