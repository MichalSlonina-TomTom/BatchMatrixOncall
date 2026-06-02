# Section 1: Introduction and Goals

## Requirements Overview

Batch&Matrix is TomTom's batch processing platform. API consumers submit large collections of queries against TomTom's underlying services in a single HTTP call. Instead of issuing thousands of individual requests, a client packages up to **10,000 queries** into one submission and receives a single aggregated response.

### Supported Products

The platform covers three distinct product surfaces:

| Product | API | Repo |
|---|---|---|
| **Batch Search API** | Submits batches of search / geocoding / reverse-geocoding / extended-search queries | `batch-service2-1.2` |
| **Batch Routing API** | Submits batches of point-to-point routing queries | `batch-service2-1.2` |
| **Matrix Routing v1** | Computes an N×M cost matrix (time / distance) between origin and destination sets | `batch-service2-1.2` |
| **Matrix Routing v2** | Next-generation matrix service with separate architecture and independent scaling | `batch-service2` |

### Underlying Services

Batch&Matrix does not compute routes or perform searches itself. It fans out each query to the appropriate TomTom service using the **client's API key**, then aggregates the results:

- TomTom Routing API (route calculations, turn-by-turn, reachable range)
- TomTom Search API (POI search, structured / fuzzy search)
- TomTom Geocoding API and Reverse Geocoding API
- Extended Search APIs

### Submission Modes

Batch&Matrix supports two execution modes:

- **Synchronous mode** — the client holds the HTTP connection open and receives the response in the same call once all queries complete. Use this for smaller batches where waiting is acceptable.
- **Asynchronous mode** — the client receives an immediate `202 Accepted` with a status URL. The job is queued in [Apache Pulsar](https://pulsar.apache.org/docs/), processed by the backend, and results are written to [Azure Blob Storage](https://learn.microsoft.com/azure/storage/blobs/). Poll the status URL and download results when ready.

### Key Constraints

- Maximum **10,000 queries** per submission.
- Quota enforcement at the API gateway layer ([Apigee](https://cloud.google.com/apigee/docs) / [Azure APIM](https://learn.microsoft.com/azure/api-management/)).
- Multi-region deployment behind [Azure Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/) for geographic failover.
- Results in async mode are stored in Azure Blob Storage and are available for a limited retention window.

![System Context](../diagrams/context-overview.png)

---

## Quality Goals

These quality goals drive the most important architectural decisions, listed in priority order.

| Priority | Quality Goal | Scenario / Motivation |
|---|---|---|
| 1 | **Throughput** | A single submission of 10,000 queries must complete within an acceptable wall-clock time. The system fans out queries in parallel and must sustain high aggregate RPS without becoming a bottleneck. |
| 2 | **High Availability** | Unplanned downtime directly blocks consumer workflows. Multi-region deployment behind Azure Traffic Manager, with per-region disablement runbooks, keeps the platform reachable during regional outages. |
| 3 | **Reliability / Result Integrity** | A completed batch must return results for every submitted query. Surface partial failures clearly on a per-query basis — never drop them silently — so consumers can detect and resubmit failed items. |
| 4 | **Scalability** | Customer load can spike unpredictably. The Pulsar-based async pipeline decouples ingestion from execution, letting backend12 scale independently of front12 and absorb bursts without dropping submissions. |
| 5 | **Observability** | Oncall engineers must determine the health, progress, and failure cause of any submission within minutes of an alert. [Grafana](https://grafana.com/docs/) dashboards, structured logs in Grafana Cloud Logs, and per-component metrics must cover the full request lifecycle from ingestion to result delivery. |

---

## Stakeholders

| Role | Where to Reach | Expectations |
|---|---|---|
| **External API Consumers** (third-party developers and enterprise customers) | TomTom Developer Portal; support tickets | Reliable, quota-enforced batch processing; predictable SLA for job completion; clear per-query error messages; stable API versioning. |
| **TomTom NOC** (Network Operations Center) | PagerDuty / on-call rotation | Immediate alerting on degradation; runbooks executable without deep product knowledge; Traffic Manager controls to reroute or disable regions. |
| **Oncall Engineers** (Batch&Matrix development team on-call) | PagerDuty rotation; `#batch-matrix` Slack | Full visibility into job queues, Pulsar lag, backend throughput, and Azure Blob Storage health; actionable runbooks for common failure modes; access to Grafana dashboards and Grafana Cloud Logs. |
| **Platform / Infrastructure Team** | `batch-service2-infra` repo; internal channels | Clear IaC boundaries in `batch-service2-infra`; documented quota configuration (Apigee / APIM); stable deployment pipeline (Jenkins at `ci.dev.batch.tt4.nl`); capacity planning inputs. |
| **TomTom Internal API Teams** (Routing API, Search API owners) | Internal Slack; Confluence | Predictable, bounded QPS from Batch&Matrix backends; adherence to per-key rate limits; advance notice of traffic spikes or load tests. |
