# Syslog Source Template

Use syslog for network devices, appliances, Unix hosts, and products that already support RFC3164 or RFC5424 forwarding.

## Listener

| Protocol | Port |
| --- | --- |
| TCP | `5514` |
| UDP | `5514` |

## Local Smoke Test

```bash
bash -c 'printf "<34>1 %s lab-host vpn - - - login failed user=alice src_ip=203.0.113.10\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > /dev/tcp/127.0.0.1/5514'
```

## Query

```logql
{job="siem-file-collector", source_type="syslog"}
```

## Notes

- Prefer TCP for reliable delivery when the sender supports it.
- Keep original device timestamps; Loki stores the normalized event body for investigation.
- For privileged port `514`, map the host port to container port `5514` after reviewing host permissions.
