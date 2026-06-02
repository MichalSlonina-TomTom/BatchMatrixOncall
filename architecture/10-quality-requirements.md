# Section 10: Quality Requirements

## 10.1 Quality Requirements Overview

The quality tree below groups the top-level goals for the Batch&Matrix platform
(Batch Search API, Batch Routing API, Matrix Routing v1, Matrix Routing v2) into categories
from ISO 25010 and the arc42 Q42 model.

```
Quality
├── Performance Efficiency
│   ├── Throughput — process up to 10 000 items per submission
│   └── Time Behaviour — processing time scales linearly with client QPS quota
├── Reliability
│   ├── Fault Tolerance — tolerate transient 403/429 errors from underlying services
│   └── Recoverability — Pulsar message retry recovers from transient backend failures
├── Availability
│   └── Regional Failover — Azure Traffic Manager redirects traffic away from a failed region
├── Scalability
│   └── Resource Isolation — per-customer Pulsar topic prevents one customer from starving others
└── Operability
    ├── Monitorability — Grafana dashboards covering batch, APIM, and cloud logs
    └── Diagnosability — structured logs enable customer identification from batch ID,
                         tracking ID, API key, or customer token
```

## 10.2 Quality Scenarios

The table below makes each quality goal concrete and measurable. Each scenario describes how the system reacts to a stimulus at runtime; the response measure is the acceptance criterion.

| ID | Quality Goal | Source / Stimulus | Environment | Artifact | Response | Response Measure |
|----|---|---|---|---|---|---|
| QS-01 | **Throughput** | Client submits a 10 000-item batch using an API key with QPS quota 5 | Normal production operation | backend12 / backend13, underlying Routing API | Process all items at the full QPS quota without dropping messages | All 10 000 items complete within ~2 000 s (10 000 ÷ 5 QPS). Verify via the _Client Usage_ and _Quota Usage_ [Grafana](https://grafana.com/docs/) dashboards. No items lost. |
| QS-02 | **Availability — Regional Failover** | An Azure region hosting the Batch&Matrix cluster becomes unavailable | Region-level outage | [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/), front12 / front13 endpoints | Traffic Manager health probes detect the failure and redirect all inbound traffic to the healthy region | Client requests are accepted again within the Traffic Manager DNS TTL after the failed region is removed. Formal SLA: TBD — see [SLA documentation location]. |
| QS-03 | **Reliability — Pulsar Retry** | A backend12 / backend13 pod crashes while processing a batch message | Individual pod failure during normal load | [Apache Pulsar](https://pulsar.apache.org/docs/), backend pods | Pulsar re-delivers the unacknowledged message to another healthy consumer for reprocessing | No batch item is permanently lost from a single pod failure. The message appears in the _Number of unacked messages_ panel and is re-consumed without operator intervention. |
| QS-04 | **Reliability — 403 Tolerance** | [Apigee](https://cloud.google.com/apigee/docs)/APIM returns HTTP 403 to Batch&Matrix due to a momentary QPS over-count at a window boundary | Clock skew between Batch&Matrix and Apigee | backend12 rate-limiter, Apigee | backend12 treats the 403 as a known transient error, backs off, and retries the call in the next QPS window | The affected item is retried and eventually succeeds; the submission completes. 403s appear in APIM Grafana (_Call Volume vs Quota Breaches_) but cause no item loss. This is accepted behaviour. |
| QS-05 | **Scalability — Per-Customer Topic Isolation** | A high-volume customer submits a large backlog of matrices while other customers are actively processing | Normal multi-tenant production load | Apache Pulsar topic-per-customer architecture (SEARCH2 / ROUTING1 / MATRIX1 / LARGE_MATRIX1 topics) | Each customer's messages queue in a dedicated Pulsar topic; one customer's backlog cannot starve another's consumer threads | A new submission starts processing within the expected time regardless of a neighbour's backlog. Maximum parallelism per service is capped at 40 (Batch&Matrix 1.2) and visible in the _Number of Parallel Batch Processing_ panel. |
| QS-06 | **Operability — Grafana Observability** | An on-call engineer receives an alert about slow processing or elevated error rates | Incident response during production | Grafana (Batch), Grafana (APIM), Grafana Cloud Logs | Use Grafana dashboards and log queries to identify the affected customer, isolate the root cause (quota breach, stuck queue, storage latency, pod failure), and take corrective action | Identify the root cause within minutes of starting an investigation. Key dashboards: _Health Indicators_, _Quota Usage_, _Status Codes per Client_, _Blob Storage_, _Pulsar State Alerts_. Query logs by batch ID, tracking ID, or customer token to find the affected customer without direct cluster access. Formal MTTR SLA: TBD — see [SLA documentation location]. |

## Notes on SLAs

Formal numeric SLAs (uptime percentages, MTTR targets, RTO/RPO) are not recorded in the Confluence quota pages (233915849 and 287900086) consulted when writing this section. Where a response measure above says "TBD", source the value from the customer contract or the service's SLA documentation and fill it in here.

- Availability SLA (QS-02): TBD — see [SLA documentation location]
- MTTR target (QS-06): TBD — see [SLA documentation location]

## References

- Confluence: [Batch&Matrix 1.2 — Quotas, Processing Speed, Recommendations](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849)
- Confluence: [Matrix Routing v2 — Quotas, Processing Speed, Recommendations](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086)
- Grafana (Batch): https://grafana.prod.batch.tt4.nl
- Grafana (APIM): https://grafana.api-system.tomtom.com
- Grafana Cloud Logs: https://grafana.tomtomgroup.com
- arc42 Section 10 guidance: https://docs.arc42.org/section-10/
