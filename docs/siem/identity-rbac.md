# Identity and RBAC

Production SIEM access should use centralized identity, not shared local accounts. The local `admin/admin` bootstrap credentials in `.env.example` are for lab startup only.

## Identity Provider Model

Preferred production pattern:

- Use Grafana SSO through OIDC or SAML.
- Require MFA at the identity provider.
- Disable shared day-to-day admin use after bootstrap.
- Keep emergency break-glass access documented, monitored, and rarely used.
- Review access at least quarterly or when team membership changes.

## Grafana Role Model

| Persona | Grafana role | Responsibilities | Notes |
| --- | --- | --- | --- |
| Security analyst | Viewer | Search logs, use dashboards, review alerts, follow runbooks. | No dashboard, rule, data source, or user administration. |
| Detection engineer | Editor | Create and tune dashboards and detection content in Git; validate changes in Grafana. | Production rule changes still go through PR review. |
| Platform administrator | Admin | Manage data sources, alerting contact points, provisioning, org settings, and emergency access. | Small trusted group only. |
| Service account | Least-privilege token or scoped integration account | Automation such as provisioning, export, or CI checks. | Rotate and audit separately from human users. |

Grafana OSS has coarse `Viewer`, `Editor`, and `Admin` roles. If the deployment needs finer permissions, use Grafana Enterprise/Cloud RBAC or move enforcement into Git review and deployment automation.

## Suggested OIDC Mapping

Use identity-provider groups and map them to Grafana roles:

| IdP group | Grafana role |
| --- | --- |
| `siem-analysts` | Viewer |
| `siem-detection-engineers` | Editor |
| `siem-platform-admins` | Admin |

Example Grafana environment settings for OIDC are documented here as a deployment pattern, not enabled by default:

```env
GF_AUTH_GENERIC_OAUTH_ENABLED=true
GF_AUTH_GENERIC_OAUTH_NAME=Corporate SSO
GF_AUTH_GENERIC_OAUTH_SCOPES=openid profile email groups
GF_AUTH_GENERIC_OAUTH_AUTH_URL=https://idp.example.com/oauth2/v1/authorize
GF_AUTH_GENERIC_OAUTH_TOKEN_URL=https://idp.example.com/oauth2/v1/token
GF_AUTH_GENERIC_OAUTH_API_URL=https://idp.example.com/oauth2/v1/userinfo
GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH=contains(groups[*], 'siem-platform-admins') && 'Admin' || contains(groups[*], 'siem-detection-engineers') && 'Editor' || 'Viewer'
```

Store the OAuth client secret through the secret manager or Docker secret override. Do not place it in `.env`.

## Bootstrap and Break-Glass

The Grafana admin account is only for initial bootstrap and emergency access.

1. Generate a unique bootstrap password.
2. Store it in the approved secret manager.
3. Enable SSO and validate role mapping.
4. Confirm at least two platform administrators can sign in through SSO.
5. Rotate or disable the bootstrap password where policy allows.
6. Record the break-glass owner, access procedure, and last test date.

## Access Review

Review access when:

- A user joins, leaves, or changes teams.
- Detection engineering ownership changes.
- Alert routing destinations change.
- A token, password, or client secret rotates.
- At least quarterly for production.

Record access reviews in the change or audit system.
