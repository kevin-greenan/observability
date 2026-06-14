# SIEM Runbooks

Runbooks describe the first-response workflow for provisioned detections. Each production detection should link to one of these files, or to an external runbook when that system is the approved operational source of truth.

## Current Runbooks

- [Critical source stale](critical-source-stale.md)
- [Inbound SSH denied](inbound-ssh-denied.md)
- [Multiple authentication failures](multiple-authentication-failures.md)
- [Suspicious PowerShell execution](suspicious-powershell-execution.md)

## Runbook Expectations

Each runbook should include:

- Initial triage steps.
- Common benign causes.
- Escalation criteria.
- Links to external response procedures when needed.
