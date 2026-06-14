# Detections

Detection content is managed as code.

| Path | Purpose |
| --- | --- |
| `loki/` | Loki ruler alert groups. |
| `tests/` | Detection test definitions and fixtures. |

Before merging detection changes:

- Review [docs/siem/detection-lifecycle.md](../docs/siem/detection-lifecycle.md).
- Run `make detection-test` against a started stack when rule behavior changes.
- Include owner, runbook, false-positive notes, and rollback details in the PR.
