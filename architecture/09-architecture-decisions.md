# Section 9: Architecture Decisions

This section documents the key architecture decisions for the Batch & Matrix platform (Batch Search API, Batch Routing API, Matrix Routing v1, and Matrix Routing v2). Each decision is an Architecture Decision Record (ADR) that captures the context, the decision, its status, and the consequences.

---

## ADR-001: Apache Pulsar for Message Queuing

**Status:** Accepted

### Context

Batch & Matrix accepts up to 10,000 queries per submission. Traffic spikes can occur at any time and from many customers simultaneously. Processing each submission synchronously in the HTTP frontend would tie up resources, couple acceptance to execution tightly, and provide no way to absorb bursts.

The system needed a durable, scalable intermediary that could:

- Decouple HTTP submission (front12) from batch processing (backend12).
- Isolate one customer's load from another so a single high-volume customer cannot starve others.
- Maintain ordered, per-customer processing queues with controllable concurrency.
- Survive transient backend failures without losing submitted work.

Several messaging systems were evaluated ([RabbitMQ](https://www.rabbitmq.com/docs), [Kafka](https://kafka.apache.org/documentation/), [Azure Service Bus](https://learn.microsoft.com/en-us/azure/service-bus-messaging/)). [Apache Pulsar](https://pulsar.apache.org/docs/) was selected for its native multi-topic architecture and built-in per-tenant topic isolation.

### Decision

Use **Apache Pulsar** as the message queue between the HTTP frontend and the batch processing backend. Each customer receives a dedicated Pulsar topic. Backend workers consume from per-customer topics, enforcing a maximum of **40 parallel batches per customer** at any one time.

### Consequences

**Positive:**

- Backlog management is straightforward: unconsumed messages accumulate in Pulsar and are processed in order as capacity becomes available.
- Per-customer topic isolation ensures that one customer's large submission does not block or delay other customers.
- Pulsar's persistence model means submissions are not lost if a backend worker crashes mid-processing.
- Operational visibility is available via the Pulsar State Alerts dashboard in [Grafana](https://grafana.com/docs/grafana/latest/) (`grafana.prod.batch.tt4.nl`).

**Negative / trade-offs:**

- The team must operate and maintain a Pulsar cluster (managed via the `batch-service2-pulsar` repository). This adds operational overhead: Pulsar upgrades, broker health monitoring, and storage management are on-call responsibilities.
- The 40-parallel-batches-per-customer cap is a hard constraint. Customers with very high submission rates queue behind themselves — this is by design, but communicate it clearly in SLA documentation.
- A Pulsar cluster failure degrades the entire async path. On-call runbooks must cover Pulsar recovery; the Grafana Pulsar alerts dashboard is the primary triage tool.

---

## ADR-002: Client API Key for Underlying Service Calls

**Status:** Accepted

### Context

Batch & Matrix acts as a proxy: it receives a batch submission and calls underlying services (Routing API, Search API, Geocoding API, etc.) once per query on the customer's behalf. These underlying services enforce per-key rate limits and quotas.

The question was whose API key to use for downstream calls: a shared internal service key, or the customer's own key.

A shared internal key would create one quota pool for all customers, making it impossible to attribute usage or enforce per-customer limits at the underlying service layer. It would also hide actual customer consumption from quota enforcement systems ([Apigee](https://docs.cloud.google.com/apigee/docs) / [APIM](https://learn.microsoft.com/en-us/azure/api-management/)).

### Decision

Batch & Matrix uses the **client's own API key** when calling underlying services. The key provided by the customer at batch submission time is forwarded to each downstream request made on their behalf.

### Consequences

**Positive:**

- Per-customer quota enforcement is handled naturally by the underlying services and by Apigee / APIM — no bespoke quota accounting is needed inside Batch & Matrix itself.
- Customers cannot exceed their contracted limits for underlying services, regardless of how large a batch they submit.
- Billing and usage attribution at the underlying service level accurately reflects the customer's consumption.

**Negative / trade-offs:**

- Processing speed is tied directly to the customer's contract tier. A customer with a low Routing API rate limit will have their batch processed slowly, because backend workers must throttle to avoid 429 responses.
- Clock skew between Batch & Matrix infrastructure and underlying service infrastructure can cause intermittent 403 errors from time-based token validation. These are transient and acceptable — the system retries on 403, and on-call does not need to treat isolated 403 spikes as incidents.
- If a customer's API key is revoked or expires mid-batch, the batch fails. Error handling and alerting cover this case.

---

## ADR-003: Synchronous and Asynchronous Processing Modes

**Status:** Accepted

### Context

Different customer workloads have different latency requirements. Some customers submit small batches and expect a result within the HTTP request lifetime (seconds). Others submit large batches (up to 10,000 queries) where waiting for an HTTP response is impractical — the connection would time out before processing completes.

A single processing model cannot serve both use cases efficiently. A synchronous-only design would force large-batch customers to implement polling themselves. An asynchronous-only design would add unnecessary complexity for small, fast batches.

### Decision

Batch & Matrix supports **both synchronous (sync) and asynchronous (async) processing modes**. Customers select the mode per submission.

- **Sync mode:** The HTTP connection is held open; the result is returned in the response body when processing completes. Suitable for small, fast batches.
- **Async mode:** The submission is accepted immediately with an HTTP 202, queued in Pulsar, processed by backend12, and the result written to **Azure Blob Storage**. The customer polls a status endpoint and downloads the result from Blob Storage when ready.

### Consequences

**Positive:**

- Customers with time-sensitive, small batch workloads get low-latency responses without polling overhead.
- Customers with large batches can submit and retrieve results at their own pace without holding connections open.
- The API surface is clean: mode is a per-request parameter, not a separate product endpoint.

**Negative / trade-offs:**

- Two code paths must be maintained in front12 and backend12. Apply changes to result formatting or error handling consistently to both paths.
- Async mode depends on **[Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/)** for result persistence. Blob Storage availability and latency directly affect the async customer experience. Monitor Blob Storage health alongside Pulsar and the HTTP frontend.
- Result retention in Blob Storage requires a lifecycle policy. Clean up stale results to control storage costs.

---

## ADR-004: Multi-Region Azure Deployment with Azure Traffic Manager

**Status:** Accepted

### Context

Batch & Matrix serves customers globally. A single-region deployment is an unacceptable single point of failure: a regional Azure outage would make the service completely unavailable. Customers in distant regions also experience higher latency when routed to a single fixed endpoint.

The system needed a multi-region strategy with automatic failover and, where possible, latency-based routing to the nearest healthy region.

### Decision

Batch & Matrix is deployed to **multiple Azure regions**. **[Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/)** provides DNS-based routing, directing customer requests to the appropriate regional endpoint. Traffic Manager health probes monitor regional front12 instances; unhealthy regions are automatically removed from DNS rotation.

Infrastructure is managed via **[Terraform](https://developer.hashicorp.com/terraform)** in the `batch-service2-infra` repository. The Traffic Manager resource group in production is `batch-traffic-manager-prd` in the shared Azure subscription.

### Consequences

**Positive:**

- A regional Azure failure results in automatic DNS failover; customers are rerouted to a healthy region within the Traffic Manager TTL window.
- Latency-based routing reduces round-trip times for geographically distributed customers.
- Terraform management of Traffic Manager and regional resources enables reproducible, auditable infrastructure changes and disaster recovery.

**Negative / trade-offs:**

- Know how to **manually disable a Traffic Manager region** when a region is degraded but not fully down — health probes may still pass while the region serves errors. See the runbook in the Batch & Matrix knowledge base (Confluence page 233927941).
- DNS TTL means failover is not instantaneous. Customers may see a window of errors during region transitions.
- Multi-region deployments increase infrastructure cost and complexity. Each region runs its own front12, backend12, Pulsar cluster, and associated dependencies.
- Pulsar and Blob Storage state is not automatically replicated across regions. In-flight batches in a failed region may need to be resubmitted by the customer after failover.
