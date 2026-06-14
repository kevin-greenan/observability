# Multiple Authentication Failures

## Triage

- Identify the user and source IP from the matching events.
- Check whether the activity is isolated to one account or spread across many accounts.
- Review recent password reset, account lockout, and SSO events if available.
- Compare the source IP to known corporate/VPN ranges and asset lookups.

## Common Benign Causes

- User password change not updated on a device.
- Broken service credential.
- Approved password spray test.
- Account lockout testing.

## Escalation

Escalate when failures target privileged accounts, many accounts, or come from unfamiliar external infrastructure.

