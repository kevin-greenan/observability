# Detections

Detection examples live in `detections/loki/security-rules.yaml`.

They are intentionally simple and raw-event friendly. A detection should not require a custom parser unless it is worth maintaining.

For authoring, metadata, review, and testing expectations, see [Detection lifecycle](detection-lifecycle.md).

## Example Queries

Authentication failures:

```logql
{job="siem-file-collector"} |= "failure"
```

Suspicious PowerShell:

```logql
{job="siem-file-collector"} |= "powershell" |= "Bypass"
```

Denied SSH:

```logql
{job="siem-file-collector"} |= "deny" |= "dst_port=22"
```

## Promotion Path

1. Start with search queries in Grafana Explore.
2. Convert useful searches into dashboard panels.
3. Convert high-signal searches into Loki alert rules.
4. Only add parser logic when multiple detections need the same extracted fields.

## Rule Loading

The rule file is mounted into Loki at `/loki/rules/fake/security-rules.yaml`.

Grafana alert contact points and notification policies are still environment-specific. Configure them before relying on these rules operationally.

## Testing

After the stack is running, validate detection fixtures with:

```bash
make detection-test
```
