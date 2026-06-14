## Source Onboarding

- Source name:
- Source owner:
- Source type:
- Environment:
- Criticality:
- Expected daily volume:
- Freshness target:

## Inventory

- [ ] `config/vector/lookups/sources.csv` updated, or private inventory mount documented.
- [ ] Parser expectation documented.
- [ ] Enrichment requirement documented.
- [ ] Expected volume and stale-after threshold documented.
- [ ] Source owner approval captured.
- [ ] SIEM/platform owner approval captured for production or high-criticality sources.

## Validation

- [ ] Test event sent successfully.
- [ ] Source appears in Loki with expected labels.
- [ ] Freshness or quality query reviewed.
- [ ] Rollback path documented.
