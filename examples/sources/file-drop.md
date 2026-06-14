# File Drop Source Template

Use file drop for exports, batch jobs, local tests, and products that can write JSON Lines, CSV, key/value, or plain text files.

## Default Drop Zone

```text
ingest/
```

For production-like pilots, keep data outside the repository:

```env
SIEM_INGEST_DIR=/srv/siem-ingest
```

## Suggested Layout

```text
/srv/siem-ingest/
├── identity/
├── endpoint/
├── network/
└── cloud/
```

## Supported Extensions

- `.json`
- `.jsonl`
- `.csv`
- `.log`
- `.txt`

## Query

```logql
{job="siem-file-collector", source_type="file"}
```

