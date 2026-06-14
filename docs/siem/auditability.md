# SIEM Auditability

Auditability is the evidence trail for administrative and content changes that affect SIEM coverage, routing, access, enrichment, and operational behavior.

The default system of record is Git for files that are safe to store in this repository. Do not put secrets, private token values, sensitive infrastructure inventories, or confidential lookup contents in Git. Store those records in the approved ticketing system, secret manager, or private evidence repository and link to the record from the PR when appropriate.

## Audit Model

| Change type | System of record | Required evidence |
| --- | --- | --- |
| Detection rule | Git PR | Rule owner, rule ID, status, test result, runbook, rollback path |
| Dashboard | Git PR | Dashboard purpose, affected audience, screenshot or panel summary, rollback path |
| Alert routing | Git PR | Owner, destination, severity impact, `make alert-routing-test` result |
| Source onboarding | Git PR plus source owner approval | Source owner, source inventory row, expected volume, parser expectation, freshness target |
| Lookup update | Git PR when non-sensitive; ticket/private repository when sensitive | Lookup owner, source of truth, validation method, approval |
| Token rotation | Secret manager plus ticket or PR note | Token name, owner, rotation date, validation evidence, next review date |
| Access/RBAC change | Identity provider or Grafana admin records | Requester, approver, role/group, business justification, removal date if temporary |

## Repository Changes

Use pull requests for changes to:

- `detections/`
- `dashboards/`
- `config/grafana/`
- `config/loki/`
- `config/vector/`
- `config/proxy/`
- `config/*/lookups/`
- `docs/siem/`

Each PR should include:

- Operational reason for the change.
- Owner for the affected content or source.
- Tests run and their result.
- Rollback plan.
- Any external ticket, incident, approval, or secret-manager reference.

## Detection Rule Ownership

Detection changes must use the detection PR checklist when possible. Every production candidate should have:

- A stable rule ID.
- A named owning team.
- A runbook path.
- Fixtures or representative test events.
- `make detection-test` evidence for rule behavior.
- False-positive notes and tuning expectations.

Experimental rules can merge with narrower evidence, but they still need an owner and a path to promotion or removal.

## Source Onboarding Approvals

Source onboarding changes should use the source onboarding PR checklist. Production or high-criticality sources require approval from:

- The source system owner.
- The SIEM/platform owner.
- The detection or response owner when the source feeds production alerting.

The PR must document whether source metadata can safely live in `config/vector/lookups/sources.csv`. If the inventory would expose sensitive infrastructure, keep the private inventory outside this repository and document where it is mounted from.

## Lookup Updates

Lookup files are commonly used for static enrichment, such as asset criticality, business unit mapping, allowlists, or application ownership.

For non-sensitive lookup data:

1. Update the lookup in Git.
2. Identify the source of truth.
3. Include the validation method in the PR.
4. Restart or reload the affected collector after merge.

For sensitive lookup data:

1. Store the lookup in an approved private location.
2. Keep only schema, mount path, and operating instructions in this repository.
3. Record update evidence in the ticketing or audit system.
4. Reference the evidence ID in the PR when safe.

## Token Rotation Records

Never commit token values or token fragments. For token-authenticated inputs such as the HTTP event collector:

1. Rotate the token in the secret manager or deployment secret source.
2. Update the runtime environment.
3. Validate ingestion with a test event.
4. Record the token name, owner, rotation date, validation result, and next review date in the secret-manager audit log or change ticket.

If token naming or ownership changes require repository updates, include the external evidence reference in the PR.

## Grafana Audit Logging

Grafana OSS does not provide full administrative audit logging suitable for production accountability. For production SIEM use, prefer Grafana Enterprise or Grafana Cloud audit logs for user login, dashboard, data source, alerting, and administrative activity.

When using Grafana OSS:

- Keep dashboards, data sources, alerting rules, and contact point configuration in provisioned files where possible.
- Review those files through Git PRs.
- Restrict direct UI edits to break-glass or lab use.
- Export and commit durable UI-created content before treating it as production content.
- Use reverse proxy, identity provider, and host logs as supplemental evidence, not as a complete Grafana audit trail.

## Minimum Review Checklist

Before merging a SIEM change, confirm:

- The affected owner is identified.
- The change has a rollback path.
- Required tests are documented.
- Sensitive data is not committed.
- External approvals or change records are linked when needed.
- The correct specialized PR checklist was used for detections or source onboarding.

Run the static auditability guardrail after changing this workflow:

```bash
make auditability-test
```
