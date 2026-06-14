# Critical Source Stale

## Triage

- Identify the missing source from the alert labels or dashboard.
- Check whether the source owner announced maintenance.
- Verify the collector is running and healthy.
- Check whether events are arriving under another `source_id` or `source_type`.
- Review network connectivity from the source to the collector.

## Common Benign Causes

- Lab stack was stopped.
- Source is intentionally quiet in a low-volume environment.
- Source maintenance or network maintenance.
- Collector restart or local Docker networking issue.

## Escalation

Escalate when a production-critical source is quiet beyond its `stale_after_minutes` objective and there is no approved maintenance.

