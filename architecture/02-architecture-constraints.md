# Section 2: Architecture Constraints

## 2.1 Technical Constraints

| Constraint | Description | Impact on Architecture |
|---|---|---|
| **Azure cloud deployment** | All Batch&Matrix and Matrix Routing v2 infrastructure runs exclusively on Azure (subscriptions: NAV Routing/Search Batch Dev and Prod). | No cloud-agnostic abstractions required; Azure-specific services (Blob Storage, Traffic Manager) are used directly. |
| **[Apache Pulsar](https://pulsar.apache.org/docs/) as message queue** | Async job processing is built around Apache Pulsar. Per-customer topics (queues) are provisioned by the service at submission time. | Queue topology, consumer group semantics, and backpressure handling are all Pulsar-specific. Migrating to another broker would require significant backend changes. |
| **[Azure Blob Storage](https://learn.microsoft.com/azure/storage/blobs/) for result storage** | Completed batch results are stored in Azure Blob Storage and served from there on download requests. | The download URL lifetime, storage costs, and access patterns are constrained by Blob Storage capabilities and configuration. |
| **[Apigee](https://cloud.google.com/apigee/docs) / [APIM](https://learn.microsoft.com/azure/api-management/) for quota enforcement** | QPS limits and entitlements for both external clients and internal service-to-service calls (e.g., Matrix v2 central key, transaction API key) are enforced by Apigee/APIM. Batch&Matrix cannot raise or modify these quotas itself. | To increase a quota, file a change request with the API Management / SCA team. Implement retry and back-off logic to handle 429 responses gracefully. |
| **[Azure Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/) for multi-region routing** | Client traffic is distributed across regions via Azure Traffic Manager. To fail over a region, disable its endpoint in Traffic Manager. | Traffic Manager health-check intervals and DNS TTLs constrain recovery time objectives. Account for DNS propagation delays when executing failover procedures. |
| **Underlying service dependency** | Batch&Matrix executes each batch item by calling an underlying service (Routing API, Search API, etc.) over HTTP using a client API key. Matrix Routing v2 uses the private `calculateMultipleRoutes` endpoint via APIM. | Network latency to underlying services is a direct component of end-to-end batch processing time. Quota exhaustion on the client key blocks all processing for that customer. |

## 2.2 Organizational Constraints

| Constraint | Description | Impact on Architecture |
|---|---|---|
| **Client API key used for underlying service calls** | Batch&Matrix authenticates to underlying services using the customer's own API key (or an internal service key for Matrix v2). Quota consumption is billed and tracked against the customer's contract. | Throughput is bound to the customer's contracted quota — the service cannot exceed it. Customers who share a key across multiple integration patterns (sync vs async) can starve one another; use separate keys per usage pattern to avoid this. |
| **QPS limits are contract-controlled** | The QPS entitlement for external access to Batch&Matrix endpoints and the `maxParallelRequests` entitlement for Routing API CPU usage are defined in Apigee per customer contract. Neither value can be raised by the engineering team alone. | Factor the contractual limits into capacity planning and SLA commitments. To raise a quota, coordinate with the Sales/SCA team. During an incident, follow the emergency key procedure — quota cannot be increased ad hoc. |
| **Multi-customer mode is opt-in** | Matrix Routing v2 supports a Multi-Customer mode where a single API key holder can allocate independent sub-customer quotas. This is an optional integration pattern, not enforced by default. | The architecture must maintain per-sub-customer quota tracking and queue isolation even though most deployments operate in single-customer mode. |
| **Team boundary: Team Stratus (PT Route Planning)** | The owning team is PU Directions - PT Route Planning - Team Stratus. Infrastructure, deployment pipelines ([Jenkins](https://www.jenkins.io/doc/) at `ci.dev.batch.tt4.nl`), and on-call responsibilities all sit within this team. | Changes to shared infrastructure (Apigee contracts, APIM product definitions, Azure subscription policies) require cross-team coordination and cannot be decided unilaterally. |

## 2.3 Conventions

| Convention | Description |
|---|---|
| **REST / HTTP APIs** | All external-facing interfaces (submission, status, download) are RESTful HTTP APIs versioned and documented on the TomTom developer portal. Internal service-to-service calls also use HTTP. |
| **JSON payloads** | Request bodies and response bodies are JSON throughout. Batch submissions are JSON arrays of individual query objects; aggregated results are returned as a single JSON document. |
| **Sync and async HTTP patterns** | Both synchronous (long-poll, result returned in the HTTP response) and asynchronous (submit-then-poll) patterns are supported. Clients select the pattern at submission time. Use async for large workloads; use sync for smaller or latency-sensitive matrices. |
| **Per-product repositories** | Each major product variant has its own GitHub repository under the `tomtom-internal` org: `batch-service2` (Matrix Routing v2), `batch-service2-1.2` (Batch&Matrix 1.2), `batch-service2-infra` (shared infrastructure), `batch-service2-pulsar`, and `batch-service2-testing-tools`. |
| **[Kubernetes](https://kubernetes.io/docs/) pod naming convention** | Frontend and backend components follow a versioned naming scheme: `front12`/`backend12` for Batch&Matrix 1.2 and `front13`/`backend13` for Matrix Routing v2. These names appear in Kubernetes labels, log queries, and Grafana dashboard filters. |
| **Observability stack** | [Grafana](https://grafana.com/docs/) is the primary observability tool: `grafana.prod.batch.tt4.nl` for service-level dashboards, `grafana.api-system.tomtom.com` for APIM quota dashboards, and Grafana Cloud Logs (`grafana.tomtomgroup.com`) for log queries (EU and US clusters). |
