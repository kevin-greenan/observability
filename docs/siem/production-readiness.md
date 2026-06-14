# Production Readiness

This stack is suitable for a local lab and a small security-team pilot. Treat it as a production-pilot foundation, not a highly available enterprise SIEM.

The remaining requirements for a fully production-ready security-team platform are tracked in [Production SIEM milestones](milestones.md).

## Ready for Pilot

- Raw-first event ingestion into Loki.
- File drop, syslog TCP/UDP, and token-authenticated HTTP event ingest.
- Automatic JSON, CSV row, and key/value extraction where safe.
- Static CSV lookup enrichment for asset inventory.
- Starter Loki detection rules mounted into the Loki ruler.
- Provisioned SIEM overview dashboard in Grafana.
- Collector health metrics exposed for Prometheus and Mimir.
- Repeatable smoke test through `make siem-smoke-test`.

## Required Before Production

### Network Security

- Put Grafana, Loki, Mimir, Tempo, Prometheus, and Vector behind TLS.
- Do not expose backend ports directly to untrusted networks.
- Rotate `SIEM_HTTP_EVENT_TOKEN` and keep it outside source control.
- Prefer a reverse proxy, service mesh, or private network for HTTP event ingest.
- Use firewall rules to restrict syslog and HTTP ingest to known senders.

### Identity and Access

- Replace local Grafana admin credentials with SSO or centrally managed users.
- Separate administrator, detection engineer, and analyst roles.
- Restrict direct Loki/Mimir/Tempo access if analysts should only use Grafana.

### Retention and Capacity

- Size Loki storage for expected daily ingest, retention, and query concurrency.
- Move Loki, Mimir, and Tempo from local filesystem storage to durable storage.
- Define retention by data class before onboarding regulated or high-volume sources.
- Monitor disk growth and compactor behavior.

### Alert Routing

- Configure Grafana contact points and notification policies.
- Route detection severities to the right team channels.
- Add runbooks for every high-signal detection.
- Test alert delivery after every rule change.

### Change Management

- Review detection rules before merge.
- Keep lookup files versioned only when they do not contain sensitive inventory.
- Use private mounts or a secret manager for sensitive enrichment data.
- Run `make validate` and `make siem-smoke-test` before merging SIEM changes.
- Run `make validate-all` before release, upgrade, production deployment, or governance changes.

## Operational SLOs

Recommended pilot targets:

| Area | Suggested target |
| --- | --- |
| Collector availability | 99% during pilot hours |
| Event search delay | Under 2 minutes for common sources |
| Dropped collector events | 0 known drops |
| Rule evaluation delay | Under 2 minutes |
| Lookup freshness | Updated within one business day for pilot assets |

## Go/No-Go Checklist

- [ ] TLS and network exposure reviewed.
- [ ] Default credentials changed.
- [ ] Ingest token rotated.
- [ ] Grafana users and roles configured.
- [ ] Retention period approved.
- [ ] Storage sizing documented.
- [ ] Alert contact points configured.
- [ ] Detection owners assigned.
- [ ] `make siem-smoke-test` passes.
- [ ] At least one real source onboarded and searchable.
- [ ] Analyst workflow tested in Grafana Explore and SIEM Overview.
