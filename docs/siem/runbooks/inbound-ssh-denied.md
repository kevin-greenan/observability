# Inbound SSH Denied

## Triage

- Identify source IP, destination IP, and firewall rule if available.
- Check whether the destination is expected to expose SSH.
- Review event frequency and whether the source is scanning many hosts.
- Compare the source IP to threat intelligence or known scanner ranges if available.

## Common Benign Causes

- Internet background scanning.
- Approved vulnerability scans.
- Misconfigured automation.
- Connectivity testing.

## Escalation

Escalate when denied SSH traffic targets sensitive hosts, appears targeted, or is followed by successful access attempts.

