# Production SIEM Milestones

This document tracks the explicit requirements to move this repository from a production-pilot SIEM foundation to a platform that a real information security team can use as an authoritative operational SIEM.

The current repository is suitable for a controlled pilot. The milestones below describe what still needs to exist before this should be treated as a fully production-ready security platform.

## Status Legend

| Status | Meaning |
| --- | --- |
| `planned` | Requirement is known but not implemented. |
| `in_progress` | Implementation has started but exit criteria are not met. |
| `done` | Exit criteria are met and validation exists. |

## Milestone 1: Production Runtime Architecture

Status: `planned`

Goal: Replace the single-host pilot target with a production runtime architecture that can survive host, container, and storage failures.

Why this matters:

A real SIEM becomes operational infrastructure. Analysts, detections, incident response, and compliance workflows depend on it being available during exactly the moments when other systems may be unhealthy.

Scope:

- Select the production runtime target: Kubernetes, managed Grafana stack, hardened Docker hosts, or another supported deployment model.
- Define availability zones, node placement, network boundaries, and failure domains.
- Define upgrade and rollback mechanics for the runtime.
- Define operational ownership between platform, security engineering, and infrastructure teams.

Candidate implementation:

- Add `docs/siem/ha-architecture.md`.
- Add deploy manifests or examples for the selected target.
- Add environment diagrams for ingest, query, storage, and admin paths.
- Add validation for production manifests.

Exit criteria:

- Runtime target is explicitly selected.
- Architecture documents failure domains and recovery expectations.
- Deployment manifests or operator procedures exist.
- Validation runs in CI or through `make validate-all`.

## Milestone 2: Durable Storage and Data Lifecycle

Status: `planned`

Goal: Move log, metric, trace, dashboard, and case data onto durable production storage with clear retention, backup, and recovery controls.

Why this matters:

Security data must survive restarts, host loss, upgrades, and investigations that span weeks or months.

Scope:

- Loki object storage and retention by data class.
- Mimir and Tempo durable storage decisions.
- Grafana database persistence and backup.
- Case/incident database persistence and backup.
- Backup schedules, restore tests, and retention verification.
- Legal hold and investigation-preservation process.

Candidate implementation:

- Extend `docs/siem/storage-backends.md` with the selected production backend.
- Add production storage configuration examples.
- Add scheduled backup documentation for every stateful service.
- Add restore drill evidence requirements.

Exit criteria:

- Durable storage backend is selected and documented.
- Retention policy is mapped to storage configuration.
- Restore procedure covers logs, dashboards, rules, lookups, and cases.
- Restore validation is automated or routinely executable.

## Milestone 3: Identity, SSO, RBAC, and Access Reviews

Status: `planned`

Goal: Integrate platform access with centralized identity and enforce role-based access for administrators, detection engineers, analysts, and responders.

Why this matters:

Security teams need controlled access to sensitive events, cases, dashboards, alert routes, and administrative functions.

Scope:

- SSO integration for Grafana and any case-management component.
- Group-to-role mapping.
- Administrative break-glass process.
- Analyst, detection engineer, responder, and platform admin roles.
- Quarterly access review process.
- Offboarding and temporary access removal.

Candidate implementation:

- Extend `docs/siem/identity-rbac.md` with provider-specific examples.
- Add production environment variables or secret references for SSO.
- Add access review checklist.
- Add RBAC validation procedure.

Exit criteria:

- SSO path is documented and tested.
- Default local admin is not used for normal operations.
- Roles and groups are mapped.
- Access review and break-glass process exists.

## Milestone 4: Managed Secrets and Credential Rotation

Status: `planned`

Goal: Replace local secret-file patterns with managed secrets, rotation workflows, and audit records.

Why this matters:

Collector tokens, admin credentials, SSO secrets, webhook URLs, and storage credentials are high-value secrets in a SIEM environment.

Scope:

- Secret manager selection.
- Runtime injection pattern.
- HTTP event collector token rotation.
- Webhook/contact point secret handling.
- Storage credential rotation.
- Secret access audit records.

Candidate implementation:

- Extend `docs/siem/secrets.md` with the selected secret manager.
- Add deployment examples that reference managed secrets.
- Add token rotation checklist and validation steps.
- Add a secret age review process.

Exit criteria:

- No production secret depends on repository files.
- Rotation procedure exists for every secret class.
- Rotation evidence is recorded outside Git.
- Secret access audit logs are available to platform owners.

## Milestone 5: Platform Monitoring, SLOs, and Operations

Status: `planned`

Goal: Monitor the SIEM platform itself with production SLOs, paging rules, dashboards, and operational runbooks.

Why this matters:

A SIEM must detect when its own ingest, search, alerting, storage, or case-management workflows are degraded.

Scope:

- Ingest availability and freshness SLOs.
- Query latency and error-rate SLOs.
- Detection evaluation health.
- Alert delivery health.
- Storage capacity and compactor health.
- Case-management service health.
- On-call routing and platform runbooks.

Candidate implementation:

- Add platform health dashboard panels.
- Add Loki/Mimir/Grafana/Vector/incident-system alert rules.
- Add runbooks for ingest down, storage full, query degraded, alert delivery failed, and case system unavailable.
- Add SLO documentation and burn-rate alerts.

Exit criteria:

- Production SLOs are documented.
- Platform health alerts route to platform owners.
- Runbooks exist for critical failure modes.
- `make validate-all` validates alert and dashboard content.

## Milestone 6: On-Platform Case and Incident Management

Status: `planned`

Goal: Provide an on-platform workflow for turning alerts and investigations into tracked cases or incidents.

Why this matters:

Analysts need somewhere inside or directly attached to the SIEM workflow to triage alerts, assign ownership, record investigation notes, preserve evidence, escalate incidents, and track closure. Without case management, the platform can detect activity but cannot reliably manage response work.

Scope:

- Case object model: title, severity, status, owner, assignee, source alert, entities, timestamps, notes, evidence, tags, and closure reason.
- Alert-to-case creation workflow.
- Case deduplication or correlation policy.
- Incident escalation workflow for high-severity cases.
- Evidence retention and immutable audit trail.
- Case search and reporting.
- Integration with external ticketing, ITSM, SOAR, paging, and collaboration tools when those are the operational systems of record.
- Analyst workflow documentation.

Candidate implementation:

- Choose case-management approach:
  - Integrated open-source case platform.
  - External ticketing system integration.
  - Custom lightweight case service backed by durable storage.
- Add `docs/siem/case-management.md`.
- Add deployment configuration for the selected case-management component.
- Add alert webhook or API integration to create/update cases.
- Add dashboard links from alerts to cases.
- Add outbound links from cases to Jira, ServiceNow, PagerDuty, Slack, Teams, email threads, or SOAR records when those systems are used.
- Add case lifecycle validation or smoke test.

Open decisions:

- Whether cases should live in Grafana, a dedicated incident-response platform, or an external ticketing system.
- Whether case notes and evidence are stored in the SIEM environment or a separate system of record.
- Whether every alert creates a case or only analyst-promoted alerts do.
- Whether external Jira/ServiceNow/PagerDuty records mirror every case or only escalated incidents.

Exit criteria:

- Case-management system of record is selected.
- Alert-to-case workflow is documented and tested.
- Case lifecycle states are defined.
- Case data is backed up and included in restore drills.
- Case actions are auditable.
- External tool links are preserved with case evidence.
- Analysts can search, assign, update, escalate, and close cases.

## Milestone 7: SOC Tool Integrations

Status: `planned`

Goal: Provide supported integration paths for enterprise SOC-adjacent tools without rebuilding ticketing, paging, chat, email, or ITSM platforms inside this repository.

Why this matters:

Security teams rarely operate from one product. A production SIEM must fit the surrounding workflow: Jira tasks, ServiceNow incidents, Slack or Teams channels, email distribution lists, PagerDuty or Opsgenie on-call, SOAR playbooks, and evidence systems.

Scope:

- Outbound alert notification destinations: Slack, Microsoft Teams, email, PagerDuty, Opsgenie, generic webhook, and HTTP API.
- Ticket and incident creation: Jira issue, ServiceNow incident, external SOAR case, or another approved case/ticket system.
- Bidirectional references between SIEM cases and external records.
- Integration ownership, credential storage, retry behavior, and failure visibility.
- Payload templates for severity, source, rule ID, entities, runbook, dashboard link, case link, and deduplication key.
- Integration test procedure using non-production endpoints.
- Rate limiting and noise controls to avoid overwhelming downstream tools.

Candidate implementation:

- Add `docs/siem/integrations.md`.
- Extend Grafana contact point examples for Slack, Teams, email, PagerDuty, and generic webhook.
- Add a generic outbound webhook contract for ticket/case automation.
- Document Jira and ServiceNow payload examples without requiring either platform.
- Add secret-manager requirements for integration credentials.
- Add `make integration-contract-test` to validate sample payloads and required fields.
- Add integration health checks or dashboard panels for delivery failures.

Open decisions:

- Whether Grafana contact points are sufficient for notifications or whether a routing/orchestration layer is needed.
- Whether Jira/ServiceNow creation should happen directly from alerts, from cases, or from analyst action.
- Which external system is the incident system of record when an on-platform case also exists.
- Whether integrations should be synchronous, queued, or retried through an intermediate worker.

Exit criteria:

- Supported integration patterns are documented.
- Slack/Teams/email/PagerDuty-style notifications have tested configuration examples or templates.
- Jira/ServiceNow-style ticket creation has a documented webhook/API contract.
- Integration credentials are handled through managed secrets.
- Delivery failures are visible to platform owners.
- SIEM cases preserve links to external tasks, incidents, chats, and pages.

## Milestone 8: Consolidated Administrative API

Status: `planned`

Goal: Provide a single modern administrative API for managing SIEM platform configuration and orchestrating changes across stack components.

Why this matters:

Loki, Grafana, Mimir, Tempo, Vector, and supporting services each expose their own APIs or file-based configuration patterns. Administrators should not need to script every backend differently for common platform operations. A consolidated API can become the supported control plane for safe, auditable changes while still delegating to the native component APIs underneath.

Scope:

- Modern API framework with OpenAPI/Swagger documentation, such as FastAPI.
- Authentication, authorization, and role-based scopes for administrative actions.
- CRUD workflows for managed configuration: sources, lookups, detection metadata, routing destinations, case integrations, dashboards, retention profiles, and deployment settings.
- Safe orchestration over native APIs and Git-backed configuration.
- Change preview, validation, apply, rollback, and status tracking.
- Audit log for every API action, including actor, request, affected resource, validation result, and rollback reference.
- Versioned API contracts and client examples.
- Guardrails for dangerous operations such as deleting sources, changing retention, rotating tokens, or disabling alerts.

Candidate implementation:

- Add `services/admin-api/` with a FastAPI service.
- Add `docs/siem/admin-api.md`.
- Add OpenAPI schema generation and Swagger UI.
- Generate or maintain an API client suitable for automation tooling, including the Terraform provider.
- Add typed resource models for sources, lookups, detections, alert routes, integrations, cases, and platform settings.
- Add adapters for Grafana, Loki ruler files, Vector configuration/lookups, deployment configuration, and future case-management APIs.
- Add dry-run validation that calls existing repository checks before applying changes.
- Add `make admin-api-test` for contract tests, authorization checks, and sample API workflows.
- Add Docker Compose wiring for local development and a production deployment pattern.

Open decisions:

- Whether the API writes directly to backend component APIs, writes Git changes for review, or supports both modes.
- Whether all production changes require pull-request approval, or whether some low-risk changes can be applied live by authorized users.
- Whether the API owns configuration state or acts as an orchestrator over Git and native component state.
- How long to retain API audit records and where to store them.
- Which resources are allowed in the first production version.

Exit criteria:

- Administrative API service exists with OpenAPI/Swagger documentation.
- Authentication and authorization are enforced.
- API can perform at least one complete safe workflow, such as onboarding a source or updating a lookup through validate/apply/status steps.
- API actions are audited.
- Dangerous operations have explicit guardrails.
- API contract tests run in validation.
- Documentation explains supported resources, unsupported operations, rollback behavior, and native component API boundaries.

## Milestone 9: Terraform Provider

Status: `planned`

Goal: Provide a Terraform provider that manages SIEM platform resources through the consolidated administrative API.

Why this matters:

Production administrators should be able to manage repeatable SIEM configuration through infrastructure as code. The provider should not talk directly to Grafana, Loki, Vector, or other stack components. It should use the consolidated API as the supported control plane so validation, authorization, audit logging, and rollback semantics stay consistent.

Scope:

- Terraform provider implemented with the modern Terraform Plugin Framework.
- Provider authentication against the consolidated administrative API.
- Resources and data sources for supported SIEM objects.
- Import support for existing platform configuration where safe.
- Plan-time validation using API dry-run endpoints.
- Drift detection against API-managed state.
- Acceptance tests against a local stack or test admin API.
- Provider documentation and examples.

Candidate implementation:

- Add `terraform-provider-observability/` or `providers/terraform/`.
- Add `docs/siem/terraform-provider.md`.
- Add provider resources for initial API-backed objects:
  - `observability_siem_source`
  - `observability_siem_lookup`
  - `observability_detection_rule`
  - `observability_alert_route`
  - `observability_integration`
  - `observability_case_workflow`
- Add data sources for existing sources, detections, integrations, and platform capabilities.
- Add example Terraform modules under `examples/terraform/`.
- Add `make terraform-provider-test` for unit, schema, and acceptance-test entry points.
- Add release and versioning guidance for provider binaries.

Open decisions:

- Which resources are safe to manage declaratively in the first provider release.
- Whether the provider supports live apply only, Git-backed change requests only, or both through API modes.
- How Terraform state should handle sensitive values, external ticket IDs, and generated tokens.
- Whether provider releases are published to the Terraform Registry or distributed internally.

Exit criteria:

- Provider can configure at least one end-to-end resource through the admin API, such as a SIEM source or alert route.
- Provider schema is documented.
- Provider uses admin API authentication and does not bypass the consolidated API.
- Plan/apply behavior uses API validation and returns actionable errors.
- Sensitive values are marked and documented.
- Tests run through a local validation command.
- Example Terraform configuration exists for a realistic SOC onboarding workflow.

## Milestone 10: Detection Engineering at Production Scale

Status: `planned`

Goal: Mature detections from starter examples into a governed production detection program.

Why this matters:

Production SIEM value depends on high-quality detections that are owned, tested, tuned, reviewed, and measured.

Scope:

- Detection coverage map aligned to ATT&CK or internal threat model.
- Rule quality scoring.
- False-positive tracking.
- Detection ownership and review cadence.
- Rule promotion and deprecation process.
- Detection-as-code testing in CI.
- Detection performance and cost review.

Candidate implementation:

- Extend `docs/siem/detection-lifecycle.md`.
- Add coverage matrix documentation.
- Add CI-friendly detection tests.
- Add dashboards for alert volume, false positives, and rule health.
- Add template fields for detection quality metrics.

Exit criteria:

- Coverage map exists.
- Production rules have owners, runbooks, test fixtures, and review dates.
- Detection tests run automatically.
- Alert quality is measured and reviewed.

## Milestone 11: Data Source Coverage and Ingest Governance

Status: `planned`

Goal: Define required production data sources, onboarding approvals, health checks, and freshness objectives.

Why this matters:

A SIEM is only useful if critical telemetry is present, searchable, fresh, and understood.

Scope:

- Required source list for identity, endpoint, network, cloud, application, and infrastructure logs.
- Source criticality and freshness objectives.
- Source owner approvals.
- Ingest health alerting.
- Parser expectation and normalization review.
- Data quality and enrichment coverage.
- Source offboarding process.

Candidate implementation:

- Extend `docs/siem/source-inventory.md`.
- Add production source tiers.
- Add source freshness alerts for critical sources.
- Add onboarding and offboarding templates.
- Add source quality dashboard panels.

Exit criteria:

- Required source catalog exists.
- Critical sources have freshness alerts.
- Onboarding approval workflow is documented.
- Source health is visible to analysts and platform owners.

## Milestone 12: Compliance, Privacy, and Data Governance

Status: `planned`

Goal: Define how the platform handles regulated data, sensitive fields, privacy boundaries, retention, and evidence requests.

Why this matters:

Security logs often contain user activity, host identifiers, IP addresses, authentication records, and sensitive application data.

Scope:

- Data classification for log sources.
- Retention by data class.
- Privacy review for sensitive fields.
- Masking or filtering strategy where required.
- Legal hold process.
- Evidence export process.
- Access logging for sensitive investigations.

Candidate implementation:

- Add `docs/siem/data-governance.md`.
- Add source classification fields to source inventory.
- Document field masking patterns.
- Add evidence export checklist.

Exit criteria:

- Data classification model exists.
- Regulated source handling is documented.
- Evidence export and legal hold procedures exist.
- Retention is technically enforced or tracked as an explicit external control.

## Milestone 13: Production Auditability and Administrative Audit Logs

Status: `planned`

Goal: Capture administrative actions, case actions, rule changes, lookup changes, source changes, and access changes in an auditable system of record.

Why this matters:

Security teams need accountability for changes that affect detection, response, evidence, and access.

Scope:

- Grafana Enterprise/Cloud audit log decision or equivalent external audit strategy.
- Case-management audit logs.
- Integration configuration and delivery audit logs.
- Administrative API and Terraform provider audit logs.
- Rule and dashboard changes through Git.
- Lookup update records.
- Source onboarding approvals.
- Token rotation records.
- Access review evidence.

Candidate implementation:

- Extend `docs/siem/auditability.md`.
- Add audit log collection for Grafana and the case system.
- Add audit coverage for integration credential changes, routing changes, administrative API actions, Terraform-managed changes, and failed delivery handling.
- Add dashboards or queries for administrative activity.
- Add audit evidence retention requirements.

Exit criteria:

- Administrative audit source is selected and onboarded.
- Case-management actions are auditable.
- Integration routing, administrative API actions, Terraform-managed changes, and delivery changes are auditable.
- Change evidence is retained.
- Access and token events can be reviewed.

## Milestone 14: CI/CD, Release Management, and Change Gates

Status: `planned`

Goal: Move validation from local-only commands into a repeatable CI/CD process with release gates.

Why this matters:

Production platform changes should not depend on a single operator remembering which local commands to run.

Scope:

- CI workflow for static validation.
- Optional integration test environment.
- Image pin review.
- Dependency and container vulnerability scanning.
- Terraform provider test and release workflow.
- Release notes and rollback plan.
- Approval gates for production deployment.

Candidate implementation:

- Add GitHub Actions or another CI workflow.
- Run `make validate-all` in CI where feasible.
- Add container image scanning.
- Add PR labels or templates for release risk.
- Add release checklist.
- Add Terraform provider release workflow and compatibility checks.

Exit criteria:

- Validation runs automatically on PRs.
- Release process is documented.
- Production promotion has approvals and rollback steps.
- Dependency and image risk is visible.
- Terraform provider changes are tested and versioned.

## Milestone 15: Disaster Recovery and Business Continuity

Status: `planned`

Goal: Define and test recovery from host failure, storage loss, bad deployment, data corruption, and case-management outage.

Why this matters:

Security operations must continue during incidents, outages, and failed upgrades.

Scope:

- Recovery time objective and recovery point objective.
- Restore drills for logs, metrics, traces, dashboards, detections, lookups, administrative API state, Terraform-managed state assumptions, and cases.
- Backup integrity checks.
- Alternate access path during Grafana or case-system outage.
- Communications plan for SIEM degradation.

Candidate implementation:

- Extend `docs/siem/backup-restore.md`.
- Add DR drill checklist.
- Add restore-test coverage for case data once case management exists.
- Add backup monitoring alerts.

Exit criteria:

- RTO/RPO targets are documented.
- Restore drills are scheduled and evidenced.
- Backups are monitored.
- Case data is included in DR testing.

## Milestone 16: Analyst Experience and Investigation Workflow

Status: `planned`

Goal: Make common analyst workflows efficient, documented, and measurable.

Why this matters:

Production readiness is not only infrastructure. Analysts need reliable workflows for search, triage, enrichment, case creation, escalation, and closure.

Scope:

- Standard triage flow from alert to case.
- Investigation dashboard links.
- Entity pivot patterns for user, host, IP, application, and cloud account.
- Saved searches or dashboard panels.
- Case note and evidence conventions.
- Analyst onboarding guide.

Candidate implementation:

- Add `docs/siem/analyst-workflows.md`.
- Add dashboard links for common pivots.
- Add case note templates.
- Add analyst onboarding checklist.

Exit criteria:

- Analyst workflow guide exists.
- Alert-to-case-to-closure process is documented.
- Common pivots are documented or built into dashboards.
- Analysts can complete a representative investigation without platform-owner help.

## Suggested Implementation Order

1. Production runtime architecture.
2. Durable storage and data lifecycle.
3. Managed secrets and identity integration.
4. Platform monitoring and SLOs.
5. On-platform case and incident management.
6. SOC tool integrations.
7. Consolidated administrative API.
8. Terraform provider.
9. Data source coverage and ingest governance.
10. Detection engineering at production scale.
11. Production auditability and administrative audit logs.
12. CI/CD, release management, and change gates.
13. Disaster recovery and business continuity.
14. Compliance, privacy, and data governance.
15. Analyst experience and investigation workflow.

The order intentionally puts runtime, identity, secrets, and storage before deep analyst workflow work. Case management, SOC tool integrations, the consolidated administrative API, and the Terraform provider are early because they become the system of record, handoff paths, control plane, and infrastructure-as-code interface for response work, and must be included in backup, RBAC, audit, notification, and operational monitoring decisions.
