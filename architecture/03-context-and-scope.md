# 3. Context and Scope

## Overview

Batch&Matrix is a TomTom platform service that accepts large batches of API queries (up to 10,000 per submission) from external API consumers, runs them against underlying TomTom services using a dedicated client API key, and returns aggregated results. It covers three product lines: **Batch Search API**, **Batch Routing API**, and **Matrix Routing v1** (repo: `batch-service2-1.2`), plus the separately architected **Matrix Routing v2** (repo: `batch-service2`). Submissions are processed in either synchronous or asynchronous mode.

---

## 3.1 Business Context

![Context Diagram](../diagrams/context-overview.png)

The diagram shows Batch&Matrix as a black box with all external actors and neighbouring systems around it. The table below describes each communication partner, what it sends to or receives from the system, and its business role.

| Communication Partner | Direction | Business Inputs / Outputs | Role |
|---|---|---|---|
| **External API Consumers** | → Batch&Matrix | Batch submission containing 1–10,000 queries (route calculations, search lookups, geocoding); poll requests for async job status | Third-party developers and partner systems calling the TomTom public API using their personal API key |
| **External API Consumers** | ← Batch&Matrix | Aggregated response containing one result per query; HTTP 202 Accepted + job ID (async); HTTP 200 + body (sync) | Receive final results after batch execution completes |
| **[Apigee](https://cloud.google.com/apigee/docs) / APIM** | → Batch&Matrix | Quota-validated and authenticated HTTP requests | API gateway that enforces per-key rate limits and quotas before traffic reaches the service; see Confluence page 233915849 for quota details |
| **[Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/)** | → Batch&Matrix | HTTP request routed to the nearest healthy regional endpoint | DNS-based multi-region load balancer; can be used to disable a region during an incident (runbook: Confluence page 233927941) |
| **TomTom Routing API** | ← Batch&Matrix | Individual route calculation requests executed on behalf of the consumer using a shared client API key | Underlying service for Batch Routing API and Matrix Routing products |
| **TomTom Search / Geocoding APIs** | ← Batch&Matrix | Individual search, geocoding, reverse-geocoding, and extended search requests | Underlying services for Batch Search API; includes standard Search API and extended search endpoints |
| **NOC (Network Operations Centre)** | ← Batch&Matrix | [Grafana](https://grafana.com/docs/) dashboards, [PagerDuty](https://support.pagerduty.com/) alerts, on-call notifications | Monitors system health, responds to incidents, escalates to the on-call engineer |
| **[Jenkins](https://www.jenkins.io/doc/) CI** | → Batch&Matrix | Built and tested artifacts deployed to all active regions | Continuous integration and deployment pipeline; hosted at https://ci.dev.batch.tt4.nl |

---

## 3.2 Technical Context

The table below maps each business interaction to the technical channel, protocol, and SDK used.

| Channel | Protocol / Technology | Connected Partners | Notes |
|---|---|---|---|
| **Public REST API (inbound)** | HTTPS / REST; JSON request and response bodies | External API Consumers → Apigee/APIM → Azure Traffic Manager → front12 | Consumers authenticate with a TomTom API key passed as a query parameter or header. [Apigee](https://cloud.google.com/apigee/docs) enforces quotas. Traffic Manager handles DNS-level regional failover. |
| **Internal HTTP frontend** | HTTPS / REST; JSON | front12 ↔ External API Consumers (sync result delivery) | front12 holds the synchronous connection open while backend12 processes the batch, or returns a job ID immediately for async submissions. |
| **[Apache Pulsar](https://pulsar.apache.org/docs/) message queue** | Pulsar binary protocol (TCP); persistent topics | front12 → Pulsar → backend12 | front12 publishes a batch job message to a Pulsar topic; backend12 subscribes and consumes it. Pulsar provides durable, ordered, at-least-once delivery. The Pulsar cluster is managed in the `batch-service2-pulsar` repo. |
| **[Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/)** | Azure Blob Storage SDK (REST under the hood); JSON blobs | backend12 writes results; front12 reads results for async polling | backend12 writes the aggregated result blob once all queries complete. front12 reads the blob when the consumer polls for the async result. Blob URLs are internal; consumers never access storage directly. |
| **Underlying service calls (outbound REST)** | HTTPS / REST; JSON | backend12 → Routing API / Search API / Geocoding API | backend12 fans out individual query requests to the relevant underlying service. Each request uses a dedicated client API key, not the consumer's key. QPS to underlying services is capped by max-qps limits; see the integration diagram in Confluence page 315602085. |
| **Monitoring / Observability** | [Grafana](https://grafana.com/docs/) HTTP API; [Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/) metrics; structured logs | Batch&Matrix → Grafana dashboards → NOC | Application metrics are published to Grafana at https://grafana.prod.batch.tt4.nl and APIM metrics at https://grafana.api-system.tomtom.com. Logs are centralised in Grafana Cloud Logs at https://grafana.tomtomgroup.com. |
| **CI/CD pipeline** | [Jenkins](https://www.jenkins.io/doc/); [Docker](https://docs.docker.com/) / [Kubernetes](https://kubernetes.io/docs/) manifests | Jenkins → Batch&Matrix deployments | Build, test, and deployment jobs run on Jenkins at https://ci.dev.batch.tt4.nl. Artifacts are deployed to all active regions using infrastructure definitions in the `batch-service2-infra` repo. |

### Input/Output to Channel Mapping

| Business Interaction | Channel |
|---|---|
| Consumer submits a batch job | Public REST API (inbound) over HTTPS |
| Consumer polls for async result | Public REST API (inbound) over HTTPS; front12 reads Azure Blob Storage |
| front12 hands off work to backend12 | Apache Pulsar topic message |
| backend12 executes individual queries | Outbound HTTPS to Routing API or Search/Geocoding APIs |
| backend12 stores aggregated results | Azure Blob Storage SDK write |
| NOC receives alert and views dashboards | Grafana metrics and logs |
| Engineer triggers deployment | Jenkins CI pipeline |
