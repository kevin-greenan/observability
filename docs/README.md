# Documentation

This directory is the documentation entry point for the LGTM observability stack and SIEM framework.

## Core Stack

- [Architecture](architecture.md): component responsibilities, data flow, persistence, and configuration model.
- [Operations](operations.md): start, stop, validation, live tests, query examples, troubleshooting, and image upgrades.

## SIEM Framework

- [SIEM overview](siem/README.md): security event ingestion, investigation, and documentation map.
- [Production readiness](siem/production-readiness.md): pilot status, production prerequisites, and go/no-go checklist.
- [Production architecture](siem/production-architecture.md): selected single-host Compose pilot target and deployment modes.
- [Production SIEM milestones](siem/milestones.md): remaining requirements for a fully production-ready security-team platform.

## Operator Workflows

- [Data onboarding](siem/onboarding.md)
- [Parser strategy](siem/parser-strategy.md)
- [Field conventions](siem/field-conventions.md)
- [Static lookups](siem/lookups.md)
- [Source inventory](siem/source-inventory.md)
- [Detections](siem/detections.md)
- [Detection lifecycle](siem/detection-lifecycle.md)
- [Alert routing](siem/alert-routing.md)
- [Auditability](siem/auditability.md)
- [Production SIEM milestones](siem/milestones.md)
- [Backup and restore](siem/backup-restore.md)
- [Upgrades](siem/upgrades.md)
- [Capacity planning](siem/capacity-planning.md)

## Security Controls

- [Security model](siem/security-model.md)
- [Identity and RBAC](siem/identity-rbac.md)
- [Secrets](siem/secrets.md)
- [Storage backends](siem/storage-backends.md)

## Runbooks

Security runbooks live under [siem/runbooks](siem/runbooks/README.md).
