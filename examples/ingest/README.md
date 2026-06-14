# SIEM Ingest Examples

Sample events for testing the SIEM collector.

These files are kept outside the default live `ingest/` drop zone so they do not create background noise every time the stack starts.

To try them, copy the sample tree into the ingest directory or point `SIEM_INGEST_DIR` at this folder:

```bash
cp -R examples/ingest/samples/* ingest/
```

Then query Loki:

```logql
{job="siem-file-collector"}
```
