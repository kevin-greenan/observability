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

Tasks:

- Task: Select and document the production runtime target.
  Success criteria: `docs/siem/ha-architecture.md` names the selected target, explains rejected alternatives, defines ownership, and is linked from production architecture docs.
- Task: Define production network and failure-domain architecture.
  Success criteria: Documentation includes ingest, query, admin, storage, and integration paths plus availability zones, node placement, trust boundaries, and failover assumptions.
- Task: Add production deployment manifests or operator procedures.
  Success criteria: Repository contains deployable examples or step-by-step procedures for the selected runtime target, including upgrade and rollback commands.
- Task: Add production runtime validation.
  Success criteria: `make validate-all` or a dedicated validation target checks the production manifests/procedures for required files, private backend bindings, TLS ingress, and disabled lab-only services.

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

Tasks:

- Task: Select durable storage backends for Loki, Mimir, Tempo, Grafana, and case data.
  Success criteria: Storage documentation names the backend for each stateful component, defines ownership, and explains durability and availability expectations.
- Task: Map retention policy to technical configuration.
  Success criteria: Each log/data class has documented retention, storage location, enforcement mechanism, and exception process.
- Task: Add production storage configuration examples.
  Success criteria: Example configuration exists for object storage or durable databases, with placeholders for secrets and environment-specific values.
- Task: Expand backup and restore coverage.
  Success criteria: Restore procedures cover logs, dashboards, detections, lookups, admin API state, Terraform-managed assumptions, and case data.
- Task: Define legal hold and investigation preservation.
  Success criteria: Documentation explains how to preserve event data and case evidence without violating normal retention or privacy controls.

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

Tasks:

- Task: Define production roles and permissions.
  Success criteria: Roles for platform admin, security admin, detection engineer, analyst, responder, auditor, and break-glass admin are documented with allowed actions.
- Task: Document SSO integration.
  Success criteria: Identity documentation includes required IdP metadata, group claims, environment variables, secret references, and login validation steps.
- Task: Map identity groups to platform roles.
  Success criteria: Group-to-role mapping exists for Grafana, case management, admin API, Terraform provider access, and integration administration.
- Task: Define access review and offboarding process.
  Success criteria: Documentation includes review cadence, evidence requirements, temporary access expiration, and emergency revocation steps.
- Task: Add RBAC validation procedure.
  Success criteria: A repeatable manual or automated test verifies representative users can and cannot perform expected actions.

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

Tasks:

- Task: Select and document the production secret manager.
  Success criteria: Secrets documentation names the secret manager, access model, audit source, and runtime injection pattern.
- Task: Inventory production secret classes.
  Success criteria: Documentation lists every secret class, including admin API credentials, HTTP ingest tokens, SSO secrets, integration webhooks, storage credentials, Terraform provider credentials, and case-system credentials.
- Task: Add managed-secret deployment examples.
  Success criteria: Production examples reference managed secrets without committing secret values or sensitive fragments.
- Task: Define rotation workflows.
  Success criteria: Each secret class has owner, rotation cadence, validation step, rollback step, and evidence location.
- Task: Add secret age and access review.
  Success criteria: Documentation defines how stale secrets and excessive secret access are detected and remediated.

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

Tasks:

- Task: Define SIEM platform SLOs.
  Success criteria: SLOs exist for ingest freshness, query latency, alert delivery, detection evaluation, case availability, and storage capacity.
- Task: Add platform health dashboards.
  Success criteria: Dashboards show service health, ingest throughput, freshness, query errors, alert delivery failures, case-system status, and storage utilization.
- Task: Add platform health alerts.
  Success criteria: Alerts exist for critical platform failure modes and route to platform owners through production contact points.
- Task: Add operational runbooks.
  Success criteria: Runbooks exist for ingest down, source stale, storage full, query degraded, alert delivery failed, admin API down, and case system unavailable.
- Task: Validate monitoring content.
  Success criteria: Dashboard JSON, alert rules, and runbook links are validated by `make validate-all` or a dedicated target.

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

Tasks:

- Task: Select case-management system of record.
  Success criteria: `docs/siem/case-management.md` names the selected approach, explains alternatives, and defines whether external tools mirror or replace cases.
- Task: Define case data model and lifecycle.
  Success criteria: Case fields, statuses, severity model, assignment rules, timestamps, evidence fields, closure reasons, and audit events are documented.
- Task: Implement alert-to-case workflow.
  Success criteria: A test alert or fixture can create or link a case, preserve source alert context, and expose the case link to analysts.
- Task: Implement case persistence and backup coverage.
  Success criteria: Case data storage is durable and included in backup and restore documentation.
- Task: Add case audit and evidence handling.
  Success criteria: Case actions, notes, evidence links, external references, and closure changes are auditable and retained according to policy.
- Task: Add case workflow validation.
  Success criteria: A smoke test or documented drill covers create, assign, update, escalate, link external record, and close.

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

Tasks:

- Task: Define integration architecture and supported patterns.
  Success criteria: `docs/siem/integrations.md` explains notification, ticket creation, incident escalation, SOAR handoff, webhook, retry, and failure handling patterns.
- Task: Add notification destination examples.
  Success criteria: Slack, Teams, email, PagerDuty/Opsgenie, and generic webhook examples exist with required fields and secret references.
- Task: Add Jira and ServiceNow ticket contracts.
  Success criteria: Example payloads define summary, severity, source, rule ID, entities, runbook, case link, deduplication key, and external record ID handling.
- Task: Define integration credential handling.
  Success criteria: Integration credentials are documented as managed secrets with owners, rotation expectations, and audit evidence.
- Task: Add integration contract validation.
  Success criteria: `make integration-contract-test` or equivalent validates required payload fields and sample configurations.
- Task: Add delivery health visibility.
  Success criteria: Delivery failures, retries, dropped notifications, and downstream rate-limit events are visible in dashboards or logs.

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

Tasks:

- Task: Define admin API resource model and boundaries.
  Success criteria: `docs/siem/admin-api.md` lists supported resources, native component boundaries, unsupported operations, and whether each resource is Git-backed, live-applied, or both.
- Task: Scaffold the admin API service.
  Success criteria: `services/admin-api/` exposes health, version, OpenAPI schema, and Swagger UI through a documented local run command.
- Task: Implement authentication and authorization.
  Success criteria: API requests require authentication, enforce role-based scopes, and include tests for allowed and denied actions.
- Task: Implement validate/apply/status/rollback workflow.
  Success criteria: At least one resource supports dry-run validation, apply, operation status, and rollback reference.
- Task: Add component adapters.
  Success criteria: API code has clear adapters for Grafana, Loki rules, Vector configuration/lookups, deployment config, and future case-management APIs.
- Task: Add API audit logging.
  Success criteria: Every mutating request records actor, resource, request ID, validation result, outcome, and rollback reference.
- Task: Add admin API tests and validation target.
  Success criteria: `make admin-api-test` validates schema generation, auth checks, and one sample workflow.

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

Tasks:

- Task: Scaffold Terraform provider project.
  Success criteria: Provider source lives under the selected directory, builds locally, and uses the Terraform Plugin Framework.
- Task: Implement provider authentication and client configuration.
  Success criteria: Provider accepts admin API endpoint and credentials through documented environment variables or provider config, and never calls backend component APIs directly.
- Task: Implement first managed resource.
  Success criteria: One realistic resource, such as `observability_siem_source` or `observability_alert_route`, supports create, read, update, delete, import, and drift detection through the admin API.
- Task: Add plan-time validation.
  Success criteria: Provider calls admin API dry-run endpoints during planning or validation and returns actionable diagnostics.
- Task: Add sensitive state handling.
  Success criteria: Sensitive attributes are marked, examples avoid storing secrets in plain text, and documentation explains state security responsibilities.
- Task: Add provider tests and examples.
  Success criteria: `make terraform-provider-test` runs unit/schema tests and examples under `examples/terraform/` show a SOC onboarding workflow.
- Task: Define provider release process.
  Success criteria: Documentation covers versioning, changelog, compatibility with admin API versions, and internal or registry distribution.

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

Tasks:

- Task: Build production detection coverage map.
  Success criteria: Coverage documentation maps detections to ATT&CK or an internal threat model, identifies gaps, and assigns owners.
- Task: Add detection quality metadata.
  Success criteria: Production rules include owner, status, severity, category, runbook, review date, confidence, expected volume, and false-positive notes.
- Task: Add CI-friendly detection tests.
  Success criteria: Detection fixtures and tests can run in CI or a documented test environment without relying on stale local data.
- Task: Add detection quality dashboards.
  Success criteria: Dashboards show alert volume, noisy rules, false-positive indicators, rule health, and stale review dates.
- Task: Define tuning and retirement workflow.
  Success criteria: Documentation explains promotion, tuning, suppression, deprecation, rollback, and periodic review.

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

Tasks:

- Task: Define required production source catalog.
  Success criteria: Source inventory documentation lists required identity, endpoint, network, cloud, application, infrastructure, and case-management sources by tier.
- Task: Add source onboarding workflow.
  Success criteria: Onboarding template captures owner, criticality, expected volume, parser expectation, enrichment requirement, retention class, and approval evidence.
- Task: Add source offboarding workflow.
  Success criteria: Offboarding procedure checks detection impact, retention/legal hold, lookup cleanup, dashboards, alerts, and external integrations.
- Task: Add critical source freshness monitoring.
  Success criteria: Critical sources have freshness queries or alert rules with documented thresholds.
- Task: Add source quality visibility.
  Success criteria: Dashboards or reports show parse status, enrichment coverage, volume anomalies, stale sources, and unknown sources.

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

Tasks:

- Task: Define data classification model.
  Success criteria: Governance documentation defines classification levels, examples, owners, and required handling for each class.
- Task: Extend source inventory for governance fields.
  Success criteria: Source inventory supports retention class, sensitivity, regulatory scope, masking requirement, and evidence-export eligibility.
- Task: Document masking and minimization patterns.
  Success criteria: Documentation explains where masking happens, which fields are masked, and how raw preservation is handled for investigations.
- Task: Define evidence export and legal hold procedures.
  Success criteria: Procedures include request approval, export scope, integrity evidence, storage location, retention exception, and closure.
- Task: Add access logging expectations for sensitive investigations.
  Success criteria: Documentation identifies which audit sources prove who accessed sensitive data or case evidence.

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

Tasks:

- Task: Select administrative audit sources.
  Success criteria: Auditability documentation identifies audit logs for Grafana, case management, admin API, Terraform provider workflows, secret manager, identity provider, and integrations.
- Task: Onboard audit logs into the SIEM.
  Success criteria: Administrative audit sources are ingested, searchable, labeled, and covered by source inventory.
- Task: Add audit dashboards and queries.
  Success criteria: Dashboards or saved queries show rule changes, source changes, lookup changes, access changes, integration changes, admin API actions, and failed deliveries.
- Task: Define audit evidence retention.
  Success criteria: Retention and backup docs specify how long audit evidence is kept and how it is restored.
- Task: Add audit validation.
  Success criteria: A test or documented drill proves representative administrative actions are captured and searchable.

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

Tasks:

- Task: Add CI workflow for repository validation.
  Success criteria: Pull requests run static validation, docs-structure test, YAML/JSON checks, and feasible Compose/config checks.
- Task: Add security scanning.
  Success criteria: Container images and dependencies are scanned, with documented severity thresholds and exception handling.
- Task: Add release checklist and versioning.
  Success criteria: Release docs include versioning, changelog, validation evidence, rollback plan, and approval requirements.
- Task: Add deployment promotion gates.
  Success criteria: Production promotion requires approval, validation evidence, owner signoff, and rollback instructions.
- Task: Add Terraform provider release workflow.
  Success criteria: Provider builds, tests, compatibility checks, and release artifact generation run in CI or documented release automation.

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

Tasks:

- Task: Define SIEM RTO and RPO.
  Success criteria: DR documentation states recovery targets for ingest, search, alerting, case management, admin API, and integrations.
- Task: Expand restore drills.
  Success criteria: Restore drills cover logs, metrics, traces, dashboards, detections, lookups, admin API state, Terraform assumptions, integration config, and cases.
- Task: Add backup monitoring.
  Success criteria: Backup success, age, size, and restore-test results are monitored and alert on failure.
- Task: Define degraded-mode operations.
  Success criteria: Documentation explains how analysts continue triage when Grafana, case management, admin API, or integrations are unavailable.
- Task: Add DR evidence process.
  Success criteria: Every drill records date, operator, scope, result, gaps, and remediation items.

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

Tasks:

- Task: Document alert-to-case triage workflow.
  Success criteria: Analyst workflow documentation shows how to open an alert, inspect evidence, create or link a case, escalate, and close.
- Task: Define entity pivot workflows.
  Success criteria: User, host, IP, application, cloud account, source, and detection pivots are documented with LogQL examples or dashboard links.
- Task: Add case note and evidence templates.
  Success criteria: Templates exist for initial triage, escalation, false positive, containment, handoff, and closure.
- Task: Add analyst onboarding guide.
  Success criteria: New analysts can run a guided exercise using sample data, dashboard links, detections, runbooks, and case workflow.
- Task: Validate representative investigation.
  Success criteria: A documented drill proves an analyst can complete a representative investigation without platform-owner help.

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
