# SIEM Ingest Drop Zone

Drop files here to onboard local SIEM data without changing collector code.

Supported default extensions:

- `.log`
- `.json`
- `.jsonl`
- `.csv`
- `.txt`

The collector stores the original event in `event.original`, then opportunistically extracts JSON, CSV row fields, or key/value fields when it can do so safely. Unknown formats are still ingested as raw events.

Suggested folder layout:

```text
ingest/
├── endpoint/
├── identity/
├── network/
└── cloud/
```

Keep production secrets and regulated data out of this repository. For real deployments, point `SIEM_INGEST_DIR` in `.env` at an external directory.
