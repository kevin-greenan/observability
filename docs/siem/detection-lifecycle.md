# Detection Lifecycle

Detection content is managed like code: every rule should be owned, reviewed, tested, and documented before it is relied on operationally.

## Lifecycle States

| Status | Meaning |
| --- | --- |
| `experimental` | Useful candidate rule. Expected to need tuning. |
| `pilot` | In use with a limited source set and known owner. |
| `production` | Routed to responders with a runbook and tested alert delivery. |
| `deprecated` | Kept temporarily for compatibility; should be removed. |

## Rule Metadata

Every Loki alert rule should include these labels:

| Label | Purpose |
| --- | --- |
| `id` | Stable rule ID, such as `siem-auth-001`. |
| `severity` | Routing severity: `low`, `medium`, `high`, or `critical`. |
| `category` | Security domain, such as `identity`, `endpoint`, or `network`. |
| `owner` | Team responsible for tuning and response quality. |
| `status` | Lifecycle state. |
| `mitre_tactic` | Lowercase ATT&CK tactic slug when applicable. |
| `mitre_technique` | Lowercase ATT&CK technique slug when applicable. |

Every rule should include these annotations:

| Annotation | Purpose |
| --- | --- |
| `summary` | Short alert title. |
| `description` | What the rule observed and why it matters. |
| `runbook_url` | Repository path or URL for triage guidance. |
| `false_positive_notes` | Known benign causes and tuning hints. |

## Review Checklist

Before merging a detection change:

- The query works in Grafana Explore or through `make detection-test`.
- The rule has a stable `id`.
- The rule has an owner.
- Severity and category are set.
- False-positive notes describe expected benign triggers.
- A runbook path is present.
- The rule can match raw events without requiring a fragile parser.
- Representative fixture events exist under `detections/tests/fixtures/`.
- `make detection-test` passes.

## Test Fixtures

Fixtures live under:

```text
detections/tests/fixtures/
```

Each fixture should be newline-delimited JSON. The detection test harness injects each fixture through the HTTP event collector and prefixes `message` with a unique run ID so tests do not depend on older events.

Test definitions live in:

```text
detections/tests/detection-tests.yaml
```

Each test definition includes:

- `id`: Rule ID under test.
- `alert`: Alert name.
- `fixture`: Fixture file to send.
- `query`: LogQL expression that should become true after fixture ingestion.

Use `$RUN_ID` in test queries. The harness replaces it with the unique run ID for the current execution.

## Running Tests

Start the stack, then run:

```bash
make detection-test
```

The test harness validates required rule metadata, sends fixture events, and queries Loki until each expected condition is true.

## Promotion Path

1. Start with an investigation query.
2. Add representative fixtures.
3. Add or update the Loki alert rule.
4. Run `make detection-test`.
5. Add or update the runbook.
6. Merge as `experimental`.
7. Tune during pilot use.
8. Run `make alert-routing-test` when routing configuration changes.
9. Promote to `production` only after alert routing and response ownership are tested.

## Rollback

If a rule is noisy or broken:

1. Revert the rule change or set status to `deprecated`.
2. Restart Loki or reload the stack so the mounted rule file is refreshed.
3. Record the reason in the PR or issue.
4. Keep fixture coverage for the corrected behavior.
