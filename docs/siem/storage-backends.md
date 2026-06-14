# Storage Backends

The local stack uses filesystem storage because it is easy to run and inspect. Production security data should move to durable object storage or a managed backend.

## Current Local Storage

| Component | Current backend | Local path |
| --- | --- | --- |
| Loki | Filesystem TSDB | Docker volume `loki-data` mounted at `/loki` |
| Mimir | Filesystem blocks | Docker volume `mimir-data` mounted at `/data` |
| Tempo | Local blocks | Docker volume `tempo-data` mounted at `/var/tempo` |
| Grafana | SQLite and plugins | Docker volume `grafana-data` |
| Prometheus | Local TSDB | Docker volume `prometheus-data` |

## Object Storage Migration Path

1. Choose the deployment target and storage provider.
2. Create buckets/prefixes for Loki, Mimir, and Tempo.
3. Store credentials in the approved secret manager.
4. Update component configs in a production overlay.
5. Run config validation.
6. Start a clean environment and send test data.
7. Confirm data remains queryable after service restart.
8. Document rollback to the previous backend.

## Loki S3-Style Example

```yaml
common:
  storage:
    s3:
      endpoint: s3.example.com
      bucketnames: siem-loki
      region: us-east-1
      s3forcepathstyle: true
      insecure: false

schema_config:
  configs:
    - from: 2024-01-01
      store: tsdb
      object_store: s3
      schema: v13
      index:
        prefix: index_
        period: 24h

compactor:
  retention_enabled: true
  delete_request_store: s3
```

## Mimir S3-Style Example

```yaml
common:
  storage:
    backend: s3
    s3:
      endpoint: s3.example.com
      bucket_name: siem-mimir
      region: us-east-1
      insecure: false

blocks_storage:
  backend: s3

ruler_storage:
  backend: s3

alertmanager_storage:
  backend: s3
```

## Tempo S3-Style Example

```yaml
storage:
  trace:
    backend: s3
    s3:
      endpoint: s3.example.com
      bucket: siem-tempo
      region: us-east-1
      insecure: false
```

Exact field names vary by component version. Validate against the pinned image versions before promoting an overlay.

