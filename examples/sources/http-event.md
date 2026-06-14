# HTTP Event Source Template

Use the HTTP event endpoint for tools that can send JSON over HTTPS through a proxy or directly to the collector in a trusted network.

## Endpoint

```text
POST http://<collector-host>:8088/event
Authorization: Bearer <token>
Content-Type: application/json
```

## Recommended Payload

```json
{
  "event": {
    "source": "example-product",
    "event.action": "login",
    "event.outcome": "failure",
    "message": "login failure for alice",
    "user.name": "alice",
    "source.ip": "203.0.113.10"
  }
}
```

## Smoke Test

```bash
curl -s http://localhost:8088/event \
  -H 'Authorization: Bearer change-me' \
  -H 'Content-Type: application/json' \
  -d '{"event":{"source":"manual","event.action":"test","message":"hello from http event","source.ip":"203.0.113.10"}}'
```

## Query

```logql
{job="siem-file-collector", source_type="http_event_collector"}
```

