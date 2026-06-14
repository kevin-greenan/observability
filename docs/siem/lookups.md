# Static Lookups

Static lookups enrich events with non-changing reference data, such as asset ownership, criticality, site metadata, and known service mappings.

This stack supports static CSV lookups through Vector enrichment tables. The first lookup is `asset_inventory`, backed by:

```text
config/vector/lookups/assets.csv
```

Source ownership and freshness metadata is tracked separately in [Source inventory](source-inventory.md).

## Asset Inventory

Current columns:

| Column | Purpose |
| --- | --- |
| `ip` | Exact IP address match key |
| `asset_name` | Human-readable asset name |
| `owner` | Owning team or person |
| `environment` | Environment, such as `lab`, `dev`, or `prod` |
| `criticality` | Business/security criticality |

When an event has `source.ip`, `source_ip`, or `src_ip`, the collector attempts an exact match against `assets.csv`. Matching events receive:

```json
{
  "asset": {
    "ip": "10.0.1.20",
    "name": "linux-server-01",
    "owner": "platform-team",
    "environment": "lab",
    "criticality": "high"
  },
  "siem": {
    "enrichment_status": "asset_inventory"
  }
}
```

Events without a match keep `siem.enrichment_status="none"`.

## Query Examples

High-criticality assets:

```logql
{job="siem-file-collector"} | json | asset_criticality="high"
```

Events enriched from the asset inventory:

```logql
{job="siem-file-collector"} | json | siem_enrichment_status="asset_inventory"
```

## Maintenance

Edit `config/vector/lookups/assets.csv`, then restart the collector:

```bash
docker compose restart siem-collector
```

For production, keep lookup files in source control only if they do not contain sensitive inventory. Otherwise mount a private lookup directory into `/etc/vector/lookups`.
