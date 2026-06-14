# Secrets

Do not use `.env` as a production secret store. The file is useful for local labs, but production passwords, tokens, webhook URLs, OAuth client secrets, object storage credentials, and certificates must live in the approved secret manager.

## Secret Classes

| Secret | Local lab source | Production source | Rotation trigger |
| --- | --- | --- | --- |
| Grafana bootstrap admin password | `.env` placeholder | Secret manager or Docker/Kubernetes secret | After bootstrap, suspected exposure, staff change, scheduled rotation. |
| SIEM HTTP event token | `.env` placeholder | Secret manager or Docker/Kubernetes secret | Sender decommission, suspected exposure, scheduled rotation. |
| Grafana OAuth client secret | Not enabled by default | Secret manager | IdP client rotation, suspected exposure, scheduled rotation. |
| Alert webhook tokens | Local mock webhook has none | Secret manager | Destination rotation, suspected exposure, scheduled rotation. |
| Object storage credentials | Not enabled yet | Secret manager | Storage key rotation, suspected exposure, scheduled rotation. |
| TLS private keys | Caddy internal local CA | Certificate manager or secret manager | Certificate renewal, suspected exposure, hostname change. |

## Repository Rules

- Commit templates and examples only.
- Do not commit `.env`, `.env.production`, or files under `secrets/`.
- Do not place live tokens in lookup files, dashboards, rule annotations, runbooks, or screenshots.
- Use PR review for changes to secret names, mount paths, or rotation procedures.

The repository includes `secrets/README.md` and `.gitignore` rules so local secret files stay untracked.

## Docker Compose Secret Example

The example override lives at:

```text
deploy/compose/production/docker-compose.secrets.example.yml
```

It demonstrates:

- `GF_SECURITY_ADMIN_PASSWORD__FILE` for Grafana bootstrap admin password.
- `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET__FILE` for Grafana OAuth client secret.
- Loading `SIEM_HTTP_EVENT_TOKEN` from `/run/secrets/siem_http_event_token` before starting Vector.

Example local pilot command:

```bash
docker compose -f docker-compose.yml -f deploy/compose/production/docker-compose.secrets.example.yml up -d
```

Before running it locally, create untracked secret files under `secrets/`.

## Kubernetes Pattern

If the deployment moves to Kubernetes, use one of:

- External Secrets Operator synced from the approved secret manager.
- Sealed Secrets for GitOps environments.
- Native Kubernetes Secrets only when cluster access, encryption at rest, and RBAC are already approved.

Recommended secret names:

```text
grafana-admin-password
grafana-oauth-client-secret
siem-http-event-token
alert-webhook-url
object-storage-credentials
tls-edge-certificate
```

## Rotation Process

Use this process for any SIEM secret:

1. Identify the owner, consumers, and blast radius.
2. Generate the replacement secret in the approved system.
3. Deploy the new secret to the platform.
4. Restart or reload only the affected services.
5. Validate the dependent workflow.
6. Revoke the old secret.
7. Record date, owner, reason, validation evidence, and rollback notes.

Specific validation examples:

- Grafana admin password: sign in through break-glass only, then return to SSO.
- SIEM HTTP event token: send an event and confirm the old token is rejected.
- Alert webhook token: send a Grafana test notification.
- OAuth client secret: complete SSO login as each mapped persona.

## Audit Expectations

Secret changes should leave evidence in:

- Secret manager audit logs.
- Git PRs for configuration or mount path changes.
- Change tickets for production rotations.
- Incident records if rotation was caused by suspected exposure.
