# Suspicious PowerShell Execution

## Triage

- Review the full command line and parent process.
- Identify the host and user.
- Search for nearby process, network, and authentication events.
- Check whether the host is managed by an endpoint tool that commonly uses PowerShell.

## Common Benign Causes

- Endpoint management scripts.
- Software deployment jobs.
- Administrator troubleshooting.
- Approved red-team or validation activity.

## Escalation

Escalate when execution includes download, encoded command, execution policy bypass, suspicious parent process, or external network activity.

