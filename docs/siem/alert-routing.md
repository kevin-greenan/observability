# Alert Routing

This stack provisions a safe local alert-routing baseline for pilot use. The default contact point sends Grafana-managed alerts to a local webhook receiver:

```text
http://host.docker.internal:18080/siem-alerts
```

The endpoint is intentionally local and contains no third-party secrets. Replace it with your production notification target after choosing the destination platform.

## Provisioned Files

| File | Purpose |
| --- | --- |
| `config/grafana/provisioning/alerting/contact-points.yaml` | Defines the local SIEM webhook contact point. |
| `config/grafana/provisioning/alerting/notification-policies.yaml` | Routes alerts by severity and data-quality category. |
| `config/grafana/provisioning/alerting/templates.yaml` | Formats alert messages with owner, category, runbook, and false-positive context. |

Restart Grafana after editing alerting provisioning:

```bash
docker compose restart grafana
```

## Routing Model

| Match | Group wait | Repeat interval | Intended response |
| --- | --- | --- | --- |
| `severity=critical` | 10s | 30m | Immediate page or incident. |
| `severity=high` | 30s | 1h | Urgent analyst review. |
| `severity=medium` | 1m | 4h | Queue for triage. |
| `category=data-quality` | 5m | 8h | Platform/source owner review. |
| Default | 30s | 4h | Pilot fallback route. |

Production routing should replace the local webhook with the team-approved destination, such as email, Slack, Teams, PagerDuty, an incident platform, or ticket automation.

## Required Rule Metadata

Every routed rule must include:

- `id`
- `severity`
- `category`
- `owner`
- `status`
- `mitre_tactic`
- `mitre_technique`
- `summary`
- `description`
- `runbook_url`
- `false_positive_notes`

`make detection-test` validates this metadata for Loki rule files.

## Local Delivery Test

Run the local webhook delivery test:

```bash
make alert-routing-test
```

The test starts a temporary receiver on port `18080`, sends a Grafana-shaped alert payload through a container, and confirms the receiver captured the payload. On Linux hosts where `host.docker.internal` is unavailable, override the container-facing URL:

```bash
DOCKER_ALERT_WEBHOOK_URL=http://172.17.0.1:18080/siem-alerts make alert-routing-test
```

This validates the local delivery path. Before production use, send a real Grafana test notification to the final contact point and record the evidence in the PR or change ticket.

## Incident Handoff

When an alert fires:

1. Open the linked runbook.
2. Confirm the alert labels identify the owner, severity, and category.
3. Search Loki for the related source, user, host, IP, or process context.
4. Create an incident or ticket in the team system when the runbook escalation criteria are met.
5. Record false positives or tuning requests against the rule ID.

## Tuning Workflow

Treat alert tuning as code:

1. Capture the noisy alert examples and Loki query used for review.
2. Update the rule query, threshold, labels, annotations, or runbook.
3. Add or update detection fixtures when the behavior should be regression-tested.
4. Run `make detection-test`.
5. Run `make alert-routing-test` when routing metadata or contact point configuration changes.
6. Merge through PR review.

Promote a rule to `status=production` only after the destination contact point and response owner have been tested.
