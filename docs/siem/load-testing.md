# Load Testing

Use load testing to measure whether the single-host Compose pilot can handle expected security event volume before onboarding real sources at scale.

## Baseline Target

The default pilot target is intentionally modest:

| Target | Default |
| --- | ---: |
| Events per run | 500 |
| Target post rate | 100 events/second |
| Batch size | 50 events |
| Expected Loki visibility | Less than 2 minutes for all synthetic events |

Tune these with environment variables:

```bash
SIEM_LOAD_TEST_EVENTS=1000 SIEM_LOAD_TEST_TARGET_EPS=200 SIEM_LOAD_TEST_BATCH_SIZE=100 make siem-load-test
```

Results are written to:

```text
tmp/load-tests/<run_id>.json
```

## Running

Start the stack, then run:

```bash
make siem-load-test
```

The script sends synthetic HTTP event collector events, measures post throughput, waits for Loki visibility, and writes a JSON result containing:

- requested events
- observed events
- batch size
- target events per second
- actual post events per second
- post duration
- Loki visibility duration
- pass/fail status

## Dashboard Signals

The SIEM Overview dashboard includes:

- `SIEM Collector Ingest Rate`
- `SIEM Ingest Bytes by Source`
- `Loki Request Latency p95`
- `Vector Sink Errors`

Use these to compare load-test runs against normal source behavior.

## Known Single-Node Limits

The current production pilot target is a single-host Compose deployment. Treat these as review triggers, not hard universal limits:

| Signal | Review trigger |
| --- | --- |
| Load-test events not visible within 2 minutes | Investigate Vector and Loki ingest pressure. |
| Loki p95 request latency above 2 seconds for sustained periods | Reduce query range, add capacity, or move to a larger deployment target. |
| Vector sink errors greater than zero | Stop onboarding, inspect collector logs, and review Loki availability. |
| Host disk below 20% free | Pause onboarding and expand storage or reduce retention. |
| Sustained ingest above tested EPS | Run a larger load test before accepting the new source volume. |

## Production Evidence

Before using the platform for production security data, record:

- test date
- image digest set
- host CPU and memory
- storage type and free space
- requested event count and target EPS
- actual EPS and Loki visibility time
- dashboard screenshots or query results for latency and errors

Store the evidence in the change ticket or release notes.
