# Source Inventory and Data Quality

Source inventory tracks which data sources are expected, who owns them, and how the SIEM should judge their freshness and quality.

The first inventory is backed by:

```text
config/vector/lookups/sources.csv
```

The collector enriches every event with `siem.source_*` fields by matching the normalized `source_type`.

## Inventory Fields

| Field | Purpose |
| --- | --- |
| `source_type` | Normalized collector source type used as the lookup key. |
| `source_id` | Stable low-cardinality source identifier promoted to a Loki label. |
| `display_name` | Human-readable source name. |
| `owner` | Team responsible for source health and onboarding. |
| `environment` | Environment name, such as `lab`, `dev`, or `prod`. |
| `criticality` | Source criticality for alerting and freshness expectations. |
| `expected_daily_events` | Planning estimate for normal event volume. |
| `stale_after_minutes` | Expected maximum quiet period before investigation. |
| `parser_expectation` | Expected parser mode or acceptable fallback behavior. |
| `enrichment_required` | Whether matching asset or contextual enrichment is expected. |

## Event Fields

Matching events receive fields like:

```json
{
  "siem": {
    "source_id": "http-event",
    "source_name": "HTTP Event Collector",
    "source_owner": "security-platform",
    "source_environment": "lab",
    "source_criticality": "high",
    "source_expected_daily_events": "100",
    "source_stale_after_minutes": "30",
    "source_parser_expectation": "json_or_raw",
    "source_enrichment_required": "true"
  }
}
```

The Loki sink promotes `siem.source_id` as the `source_id` label. Keep this value low-cardinality. Do not use hostnames, usernames, filenames, or device serial numbers as `source_id`.

## Query Examples

Events by inventory source:

```logql
sum by (source_id) (count_over_time({job="siem-file-collector", source_id!=""}[15m]))
```

Parser status by source:

```logql
sum by (source_id, parse_status) (count_over_time({job="siem-file-collector", source_id!=""}[1h]))
```

Events that failed source inventory lookup:

```logql
{job="siem-file-collector"} | json | siem_source_owner="unknown"
```

Lookup enrichment coverage:

```logql
{job="siem-file-collector"} | json | siem_enrichment_status="asset_inventory"
```

## Maintenance

Edit `config/vector/lookups/sources.csv`, then restart the collector:

```bash
docker compose restart siem-collector
```

For production, keep source ownership metadata in source control if it does not reveal sensitive infrastructure. If it does, mount a private inventory file into `/etc/vector/lookups/sources.csv`.
