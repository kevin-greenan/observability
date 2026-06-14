# SIEM Production Milestones

This document tracks the remaining work to move the current LGTM-backed SIEM from a pilot-ready stack to a production-ready security platform.

Current baseline:

- Docker Compose LGTM stack with Grafana, Loki, Tempo, Mimir, Prometheus, Alloy, and Vector.
- Raw-first SIEM ingest through file drop, syslog, and token-authenticated HTTP events.
- Opportunistic JSON, CSV row, and key/value extraction.
- Static asset lookup enrichment from `config/vector/lookups/assets.csv`.
- Loki detection rules mounted from `detections/loki/`.
- Provisioned Grafana SIEM overview dashboard.
- Collector metrics exposed on Vector `9598` and scraped by Prometheus.
- End-to-end smoke test through `make siem-smoke-test`.

## Status Legend

| Status | Meaning |
| --- | --- |
| `planned` | Not started. |
| `design` | Requirements or architecture are being written. |
| `implementing` | Code/config changes are in progress. |
| `pilot` | Usable in a limited environment but not production complete. |
| `done` | Implemented, documented, and validated. |

## Milestone 0: Pilot Baseline

Status: `pilot`

Goal: Keep the current branch usable for a small/friendly security team pilot.

Already implemented:

- File, syslog, and HTTP event ingest.
- Raw-first event envelope.
- Basic parser strategy.
- Static lookup enrichment.
- Starter detections.
- SIEM Overview dashboard.
- Collector metrics scrape.
- `make siem-smoke-test`.

Exit criteria:

- `make validate` passes.
- `make siem-smoke-test` passes.
- Grafana dashboard `siem-overview` loads.
- Prometheus query `up{job="siem-collector"}` returns `1`.
- Loki ruler loads `detections/loki/security-rules.yaml`.

## Milestone 1: Security Boundary and TLS

Status: `planned`

Goal: Define and implement a safe network/security boundary for production-like use.

Why this matters:

The current Compose stack exposes backend ports directly and uses local credentials. This is acceptable for a lab but not for a security team handling sensitive logs.

Scope:

- Add a production network exposure model.
- Terminate TLS for Grafana and HTTP event ingest.
- Keep Loki, Mimir, Tempo, Prometheus, and Vector diagnostics private by default.
- Document firewall expectations for syslog and HTTP event senders.
- Decide whether to use a reverse proxy, Docker-only private network, or Kubernetes ingress in the next deployment target.

Candidate implementation:

- Add `docs/siem/security-model.md`.
- Add `docs/siem/production-architecture.md`.
- Add a `config/proxy/` example if staying on Docker Compose.
- Prefer exposing only:
  - Grafana UI.
  - HTTP event ingest endpoint.
  - Syslog listener, restricted to known sender networks.
- Keep direct Loki/Mimir/Tempo/Prometheus APIs internal.

Open decisions:

- Compose plus reverse proxy vs Kubernetes/ingress.
- Internal CA vs externally trusted certificates.
- Whether syslog TLS is required in the first production target.

Exit criteria:

- Documented network diagram.
- Documented exposed ports and trust zones.
- TLS path documented and tested.
- Default production guidance does not expose backend APIs directly.
- `SIEM_HTTP_EVENT_TOKEN` rotation instructions exist.

## Milestone 2: Identity, RBAC, and Secrets

Status: `planned`

Goal: Replace local/shared credentials with production-appropriate identity and secrets management.

Why this matters:

Security analysts, detection engineers, and administrators need separate access levels. Tokens and passwords should not live in `.env` for production.

Scope:

- Grafana SSO/OIDC/SAML design.
- Grafana role mapping for:
  - Analyst read-only users.
  - Detection engineers.
  - Platform administrators.
- Secret handling for:
  - Grafana admin bootstrap credentials.
  - SIEM HTTP event token.
  - Future notification webhooks.
  - Future object storage credentials.
- Audit expectations for auth and config changes.

Candidate implementation:

- Add `docs/siem/security-model.md`.
- Add `docs/siem/secrets.md`.
- Add Docker secrets examples if staying on Compose.
- Add Kubernetes Secret/ExternalSecrets examples if moving to Kubernetes.
- Update `.env.example` to clearly mark local-only defaults.

Open decisions:

- Which identity provider to target first.
- Whether Docker Compose remains supported for production or only pilot.
- Secret manager preference.

Exit criteria:

- No production docs recommend shared admin use.
- Secret rotation process documented.
- Token/password storage guidance documented.
- Grafana role model documented.

## Milestone 3: Durable Storage, Retention, and Backup

Status: `planned`

Goal: Make event storage durable, sized, and recoverable.

Why this matters:

Local Docker volumes are not enough for production log retention, audit needs, or recovery.

Scope:

- Define retention periods by data class.
- Define expected ingest volume model.
- Move Loki/Mimir/Tempo storage from local filesystem to durable storage.
- Add backup/restore guidance for:
  - Grafana dashboards and provisioning.
  - Loki data.
  - Mimir data.
  - Tempo data.
  - Detection rules.
  - Lookup files.
- Add disk/capacity monitoring.

Candidate implementation:

- Add `docs/siem/capacity-planning.md`.
- Add `docs/siem/backup-restore.md`.
- Add storage backend examples for object storage.
- Add dashboard panels for ingest volume and retention pressure.

Open decisions:

- Storage backend target.
- Retention by source class.
- Recovery time objective and recovery point objective.

Exit criteria:

- Capacity worksheet exists.
- Backup and restore procedure exists.
- Retention policy is documented.
- Storage backend migration path is documented.
- Restore procedure has been tested in a clean environment.

## Milestone 4: Alert Routing and Incident Workflow

Status: `planned`

Goal: Turn detections into actionable, routed alerts with ownership and response instructions.

Why this matters:

Rules that fire without ownership, routing, or runbooks become noise.

Scope:

- Grafana contact points.
- Notification policies by severity/category.
- Alert labels and annotations standard.
- Runbook links.
- Ownership metadata.
- Incident/ticket handoff path.

Candidate implementation:

- Add `docs/siem/alert-routing.md`.
- Add `docs/siem/runbooks/`.
- Extend detection rules with:
  - `owner`
  - `severity`
  - `category`
  - `runbook_url`
  - `mitre_tactic`
  - `mitre_technique`
- Add optional Grafana alerting provisioning under `config/grafana/provisioning/alerting/`.
- Add a mock/local contact point example that does not leak secrets.

Open decisions:

- Target alert destination: email, Slack, Teams, PagerDuty, ticketing system, or webhook.
- Whether alert routing should live in Grafana provisioning or external automation.

Exit criteria:

- Every production rule has an owner and runbook.
- Alert delivery has been tested.
- Severity routing is documented.
- Alert tuning workflow is documented.

## Milestone 5: Detection Lifecycle and Testing

Status: `planned`

Goal: Create a repeatable process for detection authoring, review, testing, deployment, and tuning.

Why this matters:

Detection content needs the same engineering discipline as code.

Scope:

- Rule metadata format.
- Detection review checklist.
- Rule test fixtures.
- Expected alert outcomes.
- False-positive documentation.
- Versioning and rollback.
- CI validation for rule syntax and smoke scenarios.

Candidate implementation:

- Add `docs/siem/detection-lifecycle.md`.
- Add `detections/tests/`.
- Add sample event fixtures for each detection.
- Add `scripts/detection-test.sh`.
- Add `make detection-test`.
- Use Loki/LogQL-compatible checks where practical.

Proposed rule metadata fields:

```yaml
metadata:
  id: siem-auth-001
  owner: security-detection-engineering
  severity: medium
  category: identity
  status: experimental
  runbook: docs/siem/runbooks/multiple-authentication-failures.md
  false_positive_notes: Expected during password spray tests and account lockout testing.
  mitre:
    tactic: Credential Access
    technique: Brute Force
```

Open decisions:

- Whether to keep metadata in Loki rule annotations or sidecar YAML.
- How far to go with ATT&CK mapping in early pilot.
- Whether to add CI now or after repository hosting workflow is settled.

Exit criteria:

- Rule review checklist exists.
- Rule test fixtures exist.
- At least one detection has a passing automated test.
- Rule ownership is visible in the rule file or sidecar metadata.

## Milestone 6: Source Inventory and Data Quality

Status: `planned`

Goal: Track onboarded data sources, expected behavior, and data quality signals.

Why this matters:

A SIEM is only useful if the team knows which sources are present, fresh, complete, and searchable.

Scope:

- Source inventory template.
- Source owner tracking.
- Expected event volume.
- Expected parser status.
- Enrichment expectations.
- Stale source detection.
- Volume drop/spike dashboards.
- Parser failure dashboards.
- Lookup enrichment coverage.

Candidate implementation:

- Add `docs/siem/source-inventory.md`.
- Add `config/vector/lookups/sources.csv` or `docs/siem/sources.yaml`.
- Add dashboard panels:
  - Events by source over time.
  - Parse status by source.
  - Enrichment status by source.
  - No events from expected source in N minutes.
  - Event volume anomaly candidates.
- Add starter rules for stale critical sources.

Example source inventory fields:

```yaml
sources:
  - id: firewall-lab
    owner: network-security
    ingest_method: syslog
    expected_source_type: syslog
    expected_daily_events: 100000
    criticality: high
    parser_expectation: key_value_or_raw
    enrichment_required: false
    stale_after_minutes: 30
```

Open decisions:

- YAML inventory vs CSV lookup.
- Whether source inventory should feed Vector enrichment.
- How to handle expected event volume thresholds for small environments.

Exit criteria:

- Source inventory format exists.
- At least one source is represented.
- Dashboard shows source freshness and parser status.
- Stale-source rule exists for critical sources.

## Milestone 7: Normalization Standard

Status: `planned`

Goal: Define a lightweight field convention that improves search and detection without creating parser maintenance debt.

Why this matters:

Raw-first search avoids brittle onboarding, but analysts still need stable fields for common concepts like user, source IP, action, outcome, host, process, and cloud account.

Scope:

- Decide field naming convention.
- Document canonical fields.
- Map common source fields opportunistically.
- Avoid requiring source-specific parser files unless there is repeated detection value.

Candidate implementation:

- Add `docs/siem/field-conventions.md`.
- Use ECS/OCSF-inspired names where they are already natural:
  - `event.action`
  - `event.outcome`
  - `user.name`
  - `source.ip`
  - `destination.ip`
  - `host.name`
  - `process.name`
  - `process.command_line`
- Add Vector remap aliases only for broadly common fields:
  - `src_ip` to `source.ip`
  - `dst_ip` to `destination.ip`
  - `user` to `user.name`
- Keep original fields and `event.original`.

Open decisions:

- ECS vs OCSF vs local minimal schema.
- Whether dotted fields should remain as literal keys or nested objects.
- How much normalization should happen at ingest vs query time.

Exit criteria:

- Field convention doc exists.
- Common fields are documented.
- Normalization behavior is covered by smoke or fixture tests.
- Parser strategy remains raw-first.

## Milestone 8: Production Deployment Target

Status: `planned`

Goal: Decide and document the production runtime target.

Why this matters:

Docker Compose is excellent for a local lab and pilot, but high availability, secret integration, TLS automation, and persistent storage are easier to manage in an orchestrated environment.

Options:

- Keep Docker Compose for a single-host pilot only.
- Add a production Compose profile with reverse proxy, TLS, and durable mounts.
- Add Kubernetes manifests or Helm/Kustomize layout.
- Use managed Grafana/Loki/Mimir/Tempo where available and keep only collectors self-hosted.

Candidate implementation:

- Add `docs/siem/production-architecture.md`.
- Add `deploy/compose/production/` if keeping Compose.
- Add `deploy/kubernetes/` if moving to Kubernetes.
- Add environment-specific overlays.

Open decisions:

- Target infrastructure.
- HA requirement.
- Object storage availability.
- Identity provider availability.

Exit criteria:

- Production deployment target is selected.
- Architecture document names what is production vs pilot.
- Deployment path includes TLS, secrets, storage, and upgrade guidance.

## Milestone 9: Upgrade, Release, and Change Management

Status: `planned`

Goal: Make stack upgrades and configuration changes safe.

Why this matters:

The stack currently uses several `latest` image tags. Production should use pinned versions, tested upgrade paths, and rollback instructions.

Scope:

- Pin image versions.
- Add version matrix.
- Add upgrade checklist.
- Add rollback steps.
- Add changelog review process.
- Add compatibility checks for Loki ruler, Grafana provisioning, Vector config, and dashboard JSON.

Candidate implementation:

- Update `.env.example` with tested pinned versions.
- Add `docs/siem/upgrades.md`.
- Add `make validate-all`.
- Extend validation to include:
  - Docker Compose config.
  - Vector config.
  - Prometheus config.
  - Loki config.
  - Dashboard JSON.
  - Smoke test.

Open decisions:

- Exact tested version pins.
- How often to upgrade.
- Whether to use Renovate/Dependabot.

Exit criteria:

- Image versions are pinned for production.
- Upgrade procedure exists.
- Rollback procedure exists.
- Validation command covers all major config types.

## Milestone 10: Capacity and Load Testing

Status: `planned`

Goal: Measure ingestion and query behavior under expected security event load.

Why this matters:

A SIEM that works with smoke tests can still fail under endpoint, firewall, or cloud audit volume.

Scope:

- Generate synthetic event load.
- Measure Vector throughput.
- Measure Loki ingest and query latency.
- Measure disk growth.
- Measure dashboard responsiveness.
- Identify limits for single-node Compose.

Candidate implementation:

- Add `scripts/siem-load-test.sh`.
- Add `docs/siem/load-testing.md`.
- Add optional synthetic event generator container.
- Add dashboard panels for:
  - Ingest rate.
  - Loki request latency.
  - Vector sink errors.
  - Disk growth.

Open decisions:

- Target events per second for pilot.
- Target daily ingest volume.
- Acceptable search latency.

Exit criteria:

- Load-test script exists.
- Baseline capacity numbers are documented.
- Known limits are documented.

## Milestone 11: Auditability

Status: `planned`

Goal: Track meaningful administrative and content changes.

Why this matters:

Security platforms need accountability for rule, dashboard, source, lookup, access, and routing changes.

Scope:

- Repository change audit through Git.
- Grafana audit logging strategy.
- Detection rule change ownership.
- Lookup update process.
- Source onboarding approvals.
- Token rotation records.

Candidate implementation:

- Add `docs/siem/auditability.md`.
- Add PR templates for detection and source onboarding changes.
- Document Grafana Enterprise/Cloud audit log options if relevant.
- Keep rule/dashboard/lookup changes in Git where safe.

Open decisions:

- Whether Grafana OSS audit capabilities are enough.
- Where to store sensitive lookup update records.
- Whether source onboarding requires approvals.

Exit criteria:

- Auditability doc exists.
- Change process is documented.
- Rule/source onboarding PR checklist exists.

## Suggested Implementation Order

1. Milestone 5: Detection lifecycle and testing.
2. Milestone 6: Source inventory and data quality.
3. Milestone 7: Normalization standard.
4. Milestone 4: Alert routing and incident workflow.
5. Milestone 1: Security boundary and TLS.
6. Milestone 2: Identity, RBAC, and secrets.
7. Milestone 3: Durable storage, retention, and backup.
8. Milestone 9: Upgrade, release, and change management.
9. Milestone 10: Capacity and load testing.
10. Milestone 8: Production deployment target.
11. Milestone 11: Auditability.

Rationale:

- Detection lifecycle, source inventory, and field conventions improve the current pilot immediately.
- Alert routing should follow once rules have owners and runbooks.
- TLS, identity, secrets, durable storage, and deployment target become mandatory before real production data.
- Capacity, upgrade, and auditability harden the platform for sustained use.

