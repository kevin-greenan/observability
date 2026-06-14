# Local Secret Files

This directory is ignored by Git except for this README.

Use it only for local experiments with Docker secret files. Do not commit real passwords, tokens, webhook URLs, object storage keys, certificates, or customer data.

Example local files:

```text
secrets/grafana_admin_password
secrets/siem_http_event_token
secrets/grafana_oauth_client_secret
```

Production secrets should live in the approved secret manager, not in this repository.
