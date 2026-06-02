# Section 4: Solution Strategy

This section summarises the key architectural decisions that shape Batch&Matrix. Each decision targets one or more quality goals: throughput, isolation, resilience, and fair resource allocation across customers.

---

## 4.1 Async Queue via Apache Pulsar

The core architectural decision is to decouple batch submission from batch execution using [Apache Pulsar](https://pulsar.apache.org/docs/) as the message queue.

When a client submits a batch, the front12 HTTP frontend validates the request and publishes one message per submission to a Pulsar topic. The backend12 processors subscribe to those topics and execute the underlying API calls independently of the HTTP connection. The client then polls a download endpoint to retrieve results once processing is complete.

This decoupling provides several benefits:

- The frontend can return an HTTP 202 immediately, freeing the client connection.
- Backlog accumulates safely in Pulsar; clients with large queues are paced by their quota, not by connection timeouts.
- Backend scaling is independent of frontend scaling — add or restart backends without affecting in-flight submissions.
- Pulsar's acknowledgement model ensures a batch message is not removed from the queue until the backend has successfully stored the result in [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/), providing at-least-once delivery.

The parallel processing limit is currently set to 40 concurrent submissions per service (Batch Search / Batch Routing / Matrix Routing v1), enforced via Pulsar consumer configuration.

---

## 4.2 Client API Key Reuse for Underlying Services

Batch&Matrix does not call downstream services (Routing API, Search API, Geocoding API, etc.) with a shared service account. Instead, it reuses the **client's own API key** when making HTTP requests to those APIs on the customer's behalf.

This ties downstream quota consumption directly to the customer's contract:

- A customer with a 50 QPS Routing API quota will have their batch processed at up to 50 QPS — no more, no less.
- Quota enforcement happens in [Apigee](https://docs.cloud.google.com/apigee/docs)/[APIM](https://learn.microsoft.com/en-us/azure/api-management/), the authoritative source for all quota limits. Batch&Matrix needs no quota store of its own.
- Customers with different contracts get different processing speeds automatically, with no per-customer configuration in the Batch&Matrix codebase.

Processing speed is proportional to the QPS the customer's key allows. To increase processing speed for a customer, raise their downstream API quota in Apigee (or APIM) — do not modify Batch&Matrix configuration.

---

## 4.3 Two Processing Modes: Sync and Async

Batch&Matrix exposes two modes to cover different latency needs:

**Synchronous (online) mode** — the HTTP connection stays open while the batch executes. Use this for small, time-critical batches where the client cannot implement a polling loop. Results are returned directly in the HTTP response. Apigee enforces a separate QPS quota for sync submission endpoints (`OnlineRoutingBatch_quotaPerSecond`, `OnlineBatchSearchGeneral_quotaPerSecond`).

**Asynchronous mode** — the client submits to a submit endpoint and receives a batch ID. Poll a separate download endpoint until the result is ready (HTTP 200) or a timeout occurs. Use this for large volumes or background workloads where the client can tolerate latency. Use separate API keys for sync and async traffic so a large async queue does not starve time-sensitive sync submissions.

The same Pulsar-based backend processes both modes; the difference is only in how the frontend manages the HTTP lifecycle.

---

## 4.4 Per-Customer Pulsar Topics

Each customer gets dedicated Pulsar topics rather than sharing a global queue. The naming convention distinguishes the API type:

| Topic suffix | Service |
|---|---|
| `SEARCH2` | Batch Search API |
| `ROUTING1` | Batch Routing API |
| `MATRIX1` | Matrix Routing v1 |

Topic-level isolation means a customer with a large backlog cannot block or delay other customers. It also simplifies diagnosis: queue depth, backlog, and unacknowledged message counts are visible per-customer and per-service in the Batch&Matrix [Grafana](https://grafana.com/docs/grafana/latest/) dashboards.

front12 creates a Pulsar producer for the appropriate topic on first use and logs the topic name alongside the customer token. Use this log entry to look up queue names during incident investigation.

---

## 4.5 Multi-Region Deployment via Azure Traffic Manager

Batch&Matrix is deployed across multiple Azure regions. [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/) routes incoming requests to the nearest healthy region using DNS-level traffic management.

Each region runs its own independent stack: front12, backend12, Apache Pulsar cluster, and Azure Blob Storage account. Regions share no runtime state. A submission accepted in one region is processed and stored there; the download endpoint in the same region serves the result.

This design provides:

- **Lower latency** — clients are routed to the geographically closest region.
- **Blast-radius containment** — a regional outage affects only submissions routed to that region; other regions keep serving traffic.
- **Independent failover** — disable a region in Traffic Manager without touching the applications. The runbook for disabling a region is documented separately.

---

## 4.6 Rate Limiting Strategy: Multi-Quota Mapping

Apigee does not apply a single flat QPS limit per API key. It uses a **ratelimiter Quota Name** concept: endpoints sharing a Quota Name draw from a shared bucket; endpoints with different Quota Names have independent buckets.

For example, forward search and search-along-route have different Quota Names and therefore independent QPS allowances. To maximise throughput under a customer's contract, backend12 implements a **multi-quota mapping** — it tracks which Apigee Quota Name applies to each request type and sends requests against each quota bucket independently and concurrently.

Configure this mapping in `backend/src/main/resources/application.yml` under `rate-limiter.multi-quota-mapping`. When a Batch Search submission contains multiple request types (e.g., forward geocode and reverse geocode), backend12 processes each type at its own quota rate instead of serialising all requests through a single rate limiter. This means total effective throughput can exceed what a single-quota approach would allow, making better use of the customer's contracted entitlements.

Monitor quota consumption per multi-quota key in the **Quota usage (Batch 1.2)** Grafana dashboard, which shows the current QPS in use and the customer's configured limit for each quota bucket.
