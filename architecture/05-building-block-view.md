# Section 5: Building Block View

## Whitebox: Overall System

Batch & Matrix is an asynchronous batch processing platform scaled horizontally across services. Clients submit up to 10,000 queries in a single request. The platform fans those queries out to underlying TomTom APIs (Routing API, Search API, Geocoding API, and others) using the client's API key, aggregates all responses, and stores the combined result for retrieval.

The system runs across multiple Azure regions. DNS-based load balancing distributes traffic between regions. The API gateway enforces quota before any request reaches application code.

Two distinct codebases share the same infrastructure:

- **Batch & Matrix 1.2** (`batch-service2-1.2`): serves Batch Search API, Batch Routing API, and Matrix Routing v1 API.
- **Matrix Routing v2** (`batch-service2`): serves Matrix Routing v2 API with a separately evolved architecture.

![Building Blocks](../diagrams/building-blocks.png)

---

## Level 1 Building Blocks

### 1. front12-deployment (HTTP Frontend — Batch & Matrix 1.2)

**Responsibility**

`front12-deployment` is the HTTP entry point for all Batch & Matrix 1.2 API requests. It accepts client submissions for the Batch Search API, Batch Routing API, and Matrix Routing v1 API. For async requests, it enqueues the job onto [Apache Pulsar](https://pulsar.apache.org/docs/) and immediately returns HTTP `202 Accepted` with a job identifier. For synchronous requests, it waits for the backend to finish and returns the result inline. For result retrieval, when a client polls with a job identifier, `front12` reads the completed result from Azure Blob Storage and streams it back.

**Interfaces**

- Inbound: REST/HTTPS from [Apigee](https://cloud.google.com/apigee/docs)/[APIM](https://learn.microsoft.com/azure/api-management/) (quota-checked and authenticated). Paths include `/routing/1/batch`, `/search/2/batch`, and Matrix v1 endpoints.
- Outbound to Pulsar: job enqueue on per-customer topics.
- Outbound to Blob: result read for polling clients.
- Auth delegation: Apigee/APIM validates the client's API key and enforces quota; `front12` does not perform these checks itself.

**Source repository:** `tomtom-internal/batch-service2-1.2` — `front` module (runs on port 18080 in dev).

---

### 2. backend12-deployment (Batch Processor — Batch & Matrix 1.2)

**Responsibility**

`backend12-deployment` is the asynchronous worker that processes jobs. It consumes jobs from Apache Pulsar, fans out up to 10,000 individual queries per job to the appropriate underlying service (Routing API, Search API, etc.) using the client's API key, applies per-customer rate limiting to protect downstream services, and writes the aggregated result to [Azure Blob Storage](https://learn.microsoft.com/azure/storage/blobs/) once all sub-queries complete. This layer enforces a maximum of 40 parallel batches per customer per service type.

**Interfaces**

- Inbound: Apache Pulsar topic subscription (per-customer topics, per service type).
- Outbound: HTTP calls to underlying TomTom APIs using the client's API key.
- Outbound: Azure Blob Storage write of aggregated result.

**Quality characteristics:** Internal rate limiting respects downstream QPS limits. The deployment scales horizontally — multiple backend replicas share Pulsar topic partitions.

**Source repository:** `tomtom-internal/batch-service2-1.2` — `backend` module (runs on port 28080 in dev).

---

### 3. Apache Pulsar Cluster

**Responsibility**

Apache Pulsar is the durable message broker that decouples job submission (`front12`) from job execution (`backend12`). Jobs are placed on per-customer, per-service-type topics, which provides natural isolation: a high-volume customer cannot delay processing for another customer. If the backend is saturated, new submissions queue in Pulsar instead of being dropped.

**Interfaces**

- Producers: `front12-deployment` (Batch & Matrix 1.2) and `front-deployment` (Matrix Routing v2).
- Consumers: `backend12-deployment` (Batch & Matrix 1.2) and `backend-deployment` (Matrix Routing v2).

**Constraints**

- Maximum 40 parallel batches per customer per service type enforced at consumer level.
- Pulsar configuration and topic naming conventions live in the `tomtom-internal/batch-service2-pulsar` repository.

**Infrastructure repository:** `tomtom-internal/batch-service2-infra`.

---

### 4. Azure Blob Storage (Result Store)

**Responsibility**

Azure Blob Storage is the persistent store for completed batch results. When `backend12-deployment` finishes a job, it writes the full aggregated response as a blob keyed by the job identifier. When a client polls `front12-deployment`, the frontend reads and returns that blob. Results remain available until the configured retention period expires.

**Interfaces**

- Writers: `backend12-deployment`, `backend-deployment` (Matrix v2).
- Readers: `front12-deployment`, `front-deployment` (Matrix v2).

**Quality characteristics:** Blob Storage provides the durability guarantee for results. It decouples the processing worker lifecycle from result retrieval, so clients can fetch results long after processing completes.

---

### 5. Apigee / APIM (External Quota Enforcement)

**Responsibility**

All external client traffic passes through Apigee (legacy) or Azure API Management (APIM) before reaching any Batch & Matrix component. This layer validates API keys, enforces per-customer quota, and rate-limits at the ingress level. Quota policies for Batch & Matrix 1.2 are on the [Batch 1.2 quotas Confluence page](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849); Matrix Routing v2 quotas are on the [MatrixV2 quotas page](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086).

**Interfaces**

- Inbound: external HTTPS from clients.
- Outbound: quota-checked requests forwarded to Azure Traffic Manager.

**Observability:** APIM metrics are available on the [Grafana APIM dashboard](https://grafana.api-system.tomtom.com).

---

### 6. Azure Traffic Manager (DNS Load Balancing)

**Responsibility**

[Azure Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/) provides DNS-based geographic and failover load balancing across Azure regions. It routes requests from Apigee/APIM to `front12-deployment` (or `front-deployment` for Matrix v2) in the nearest healthy region. During a regional failure, reconfigure Traffic Manager to stop sending traffic to the affected region. See the [Disabling Traffic Manager region Confluence page](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233927941) for the procedure.

**Interfaces**

- Inbound: DNS queries from Apigee/APIM.
- Outbound: routes to `front12-deployment` instances across Azure regions.

**Infrastructure repository:** `tomtom-internal/batch-service2-infra`.

---

## Matrix Routing v2 Components (batch-service2)

Matrix Routing v2 is a separate product with its own codebase (`tomtom-internal/batch-service2`) deployed on the same shared infrastructure. It shares Apache Pulsar and Azure Blob Storage with Batch & Matrix 1.2, but runs its own `front-deployment` and `backend-deployment` [Kubernetes](https://kubernetes.io/docs/) deployments.

| Component | Role |
|---|---|
| `front-deployment` | HTTP entry point for Matrix Routing v2 API (`/routing/matrix/2`). Follows the same pattern as `front12`: enqueues on Pulsar, returns 202 for async, reads results from Blob for polling. |
| `backend-deployment` | Async worker for Matrix Routing v2. Consumes Pulsar, calls the underlying Routing API with the client key, writes results to Blob. |

Matrix Routing v2 evolved independently from Batch & Matrix 1.2, letting it iterate on matrix-specific computation and quota logic without affecting Batch Search and Batch Routing.

---

## Building Block Interfaces Summary

| From | To | Protocol | Purpose |
|---|---|---|---|
| External Client | Apigee/APIM | HTTPS | API submission and result polling |
| Apigee/APIM | Azure Traffic Manager | HTTPS | Quota-checked forwarding |
| Azure Traffic Manager | front12-deployment | HTTPS | Regional routing |
| front12-deployment | Apache Pulsar | Pulsar protocol | Job enqueue |
| front12-deployment | Azure Blob Storage | Azure SDK / HTTPS | Result read (poll) |
| backend12-deployment | Apache Pulsar | Pulsar protocol | Job dequeue |
| backend12-deployment | Underlying Services | HTTPS + client API key | Per-query execution |
| backend12-deployment | Azure Blob Storage | Azure SDK / HTTPS | Result write |
| Azure Traffic Manager | front-deployment (v2) | HTTPS | Matrix v2 regional routing |
| front-deployment (v2) | Apache Pulsar | Pulsar protocol | Job enqueue (Matrix v2) |
| backend-deployment (v2) | Apache Pulsar | Pulsar protocol | Job dequeue (Matrix v2) |
| backend-deployment (v2) | Underlying Services | HTTPS + client API key | Per-query execution (Matrix v2) |
| backend-deployment (v2) | Azure Blob Storage | Azure SDK / HTTPS | Result write (Matrix v2) |
