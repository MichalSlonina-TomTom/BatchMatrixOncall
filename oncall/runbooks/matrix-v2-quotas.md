# Matrix Routing v2 — Quotas and Slow Processing Runbook

Source: [Confluence page 287900086](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086)

---

## Overview

Matrix Routing v2 has a different architecture from Batch&Matrix 1.2 (Batch Search, Batch Routing, Matrix Routing v1). The information here applies **only to Matrix Routing v2**. Do not use the Batch 1.2 runbook for Matrix v2 issues.

### Key differences from Batch&Matrix 1.2

| Aspect | Batch&Matrix 1.2 | Matrix Routing v2 |
|---|---|---|
| Components | front12, backend12 | **front13, backend13** |
| Underlying API | Routing API / Search API via client key | `calculateMultipleRoutes` private endpoint, via Matrix's **central internal key** |
| Client quota type | QPS to underlying service (client's own key) | `maxParallelRequests` entitlement (CPU cores in Routing API) |
| [Pulsar](https://pulsar.apache.org/docs/) queue | SEARCH2, ROUTING1, MATRIX1 | **LARGE_MATRIX1** |
| Job ID field in logs | batchId | also **batchId** (for consistency; API returns it as `jobId`) |

Matrix Routing v2 uses two routing engine implementations internally:

- **Asterix** (faster): used when `departAt`/`arriveAt` is set, `routeType` is fastest/shortest, no `avoid`/`avoidAreas`/`avoidVignette`, `travelMode` is not bicycle/pedestrian, and traffic is historical.
- **New Haven** (slower): the same engine as the regular Routing API `calculateRoute` endpoint; used when Asterix cannot be used. This significantly increases routing CPU usage and processing time.

### Two quota types that matter for Matrix v2

1. **QPS to the Matrix Routing v2 service** (`MatrixRoutingV2_quotaPerSecond`): limits how many requests a client can make to front13 per second — submission, status checks, and result downloads combined.
   - Default: 10 QPS
   - Standard enterprise value: 50 QPS

2. **`maxParallelRequests` entitlement** (`MatrixRoutingV2_Entitlements`): limits how many Routing API CPU cores a client can use at the same time in `calculateMultipleRoutes`.
   - Default: 10
   - Standard enterprise value: 50

Additionally, Matrix v2 has its own **central API key** (not the client's key) to call `calculateMultipleRoutes`. This key has a global QPS quota shared across all clients. If this key is exhausted, it is a service-wide incident.

---

## Customer Identification

A client in Matrix Routing v2 is identified by a **tuple of three values**:

- **Customer token** — the APIM developer app ID. This is the primary identifier in logs and metrics.
- **Sub-customer ID** — used when the client runs in [Multi-Customer mode](https://developer.tomtom.com/routing-api/documentation/tomtom-maps/matrix-routing-v2/multi-customer), giving each of their end-customers independent limits.
- **Downstream service** — clients of sub-services like [Waypoint Optimization](https://developer.tomtom.com/waypoint-optimization/documentation/waypoint-optimization-service) have separate quotas.

### Find customer token from batch ID, tracking ID, or developer app ID

Search in **[Grafana](https://grafana.com/docs/grafana/latest/) Cloud Logs** on `front13-deployment` for the `New submission request` log line:

```
[Labels filter] k8s_deployment_name=front13-deployment
[Search in log lines] New submission request
[Search in log lines] <batch-id OR tracking-id OR customer-token>
```

- Grafana Cloud Logs EU: https://grafana.tomtomgroup.com/goto/lIheXgbNg?orgId=1
- Grafana Cloud Logs US: https://grafana.tomtomgroup.com/goto/Y8-6uRbNg?orgId=1

The customer token is the APIM developer app ID.

### Find customer token from API key, email, or application name

Matrix v2 does not receive or store API keys. Use APIM Grafana to look up the customer token:

- **By developer name/email**: https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview
- **By API key (first/last 4 chars), email, app ID, SSO ID**: https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id?orgId=1

Find the "developer app id" — that is the customer token. Check the "Application usage information" section to confirm the app has Matrix Routing v2 API assigned and is active.

### Find Pulsar queue name from customer token

```
[Labels filter] k8s_deployment_name=front13-deployment
[Search in log lines] Created producer for topic
[Search in log lines] <customer-token>
```

- Grafana Cloud Logs EU: https://grafana.tomtomgroup.com/goto/kxyi9RbNg?orgId=1
- Grafana Cloud Logs US: https://grafana.tomtomgroup.com/goto/rIqi9gbNg?orgId=1

Log format: `Created producer for topic <topic_name>, assigned customer identifier is <customer-token>`

The **LARGE_MATRIX1** queue is dedicated to Matrix Routing v2.

---

## Checking Quotas

### QPS to Matrix Routing v2 (front13)

**Batch&Matrix Grafana — status codes per client:**
https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client?orgId=1

Filters: `Batch version=13`, `customerToken=<value>`

**APIM Grafana — quota breaches (rejected requests):**
https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1

Filters:
- Developer app email = `<appropriate value>`
- Environment = `prod` or `microsoft`
- New product structure = `False`
- API product = `Routing API`, Child product = `Matrix Routing v1`, Method = `routing matrix 2`

Rejected requests here mean the client's QPS quota is too low. This quota is set in [Apigee](https://cloud.google.com/apigee/docs) and **cannot be increased by the team** — it is tied to the customer's contract.

### maxParallelRequests usage (Routing API CPU cores)

**Grafana — Quota usage (Matrix v2):**
https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?orgId=1

Filter: `customerToken=<value>`

In the **"Per customer quota usage"** section:
- `requests used, per customer` — current Routing API CPU usage
- `Customer maxParallelRequests limit` — the configured ceiling

This entitlement is set in Apigee and **cannot be increased by the team**.

### Sync matrix parallel processing limit

On the same dashboard, the **"Sync matrices - parallel batch processing"** panel shows:
- `Sync Matrices in progress`
- `Sync Matrix - maxBatchesInProgressPerClient (based on maxParallelRequests)`

This limit is derived from `maxParallelRequests` (set in [backend application.yml](https://github.com/tomtom-internal/batch-service2/blob/batch-release-candidate-1.3.1928/backend/src/main/resources/application.yml#L52-L75)):

| maxParallelRequests | maxBatchesInProgressPerClient |
|---|---|
| 10 | 5 |
| 50 | 8 |

This limit **cannot be changed per client**. To change it globally, modify the `backend13-config` configmap and roll out the backend13 pods.

### Async matrix parallel processing (Pulsar backlog)

On the same dashboard, the **"Async matrices - parallel batch processing"** section shows:
- `Local backlog` — messages pending in the queue
- `Number of unacked messages` — messages currently being processed

To increase the async parallel limit for a specific client, run the commands in [pulsar-add-tenant-payload.sh lines 145-167](https://github.com/tomtom-internal/batch-service2-infra/blob/661cd9592eb73cd2e5005ebe405b45a98f3e1a73/terraform-apache-pulsar/pulsar-add-tenant-payload.sh#L145-L167) on the pulsar-toolset pod.

### Matrix v2 central API key QPS (global — affects all clients)

Matrix v2 uses an internal TomTom-managed key to call `calculateMultipleRoutes`. If this key is fully utilized, processing degrades for **all** clients.

Monitor at:
- **Batch&Matrix Grafana** "Global quota usage" section: https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?orgId=1
- **APIM Grafana — central key (2500 QPS)**: [Call volume vs quota breaches - largeMatrixAsyncProd](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1&from=now-24h&to=now&var-developerappname=largeMatrixAsyncProd%20-%20%28navfuturama@groups.tomtom.com%29&var-environment=prod&var-apiproduct=calculateMultipleRoutes&var-apiproxy=calculateMultipleRoutes&var-ratelimiterQuotaName=IuZH...mtky)
- **APIM Grafana — backup key (3400 QPS)**: [Call volume vs quota breaches - Matrix v2 with increased QPS](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1&from=now-24h&to=now&var-developerappname=Matrix%20v2%20with%20increased%20QPS%20-%20%28navfuturama@groups.tomtom.com%29&var-environment=&var-apiproduct=calculateMultipleRoutes&var-apiproxy=calculateMultipleRoutes&var-ratelimiterQuotaName=IuZH...mtky)

For emergency central key quota increase procedure, see: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832

### Matrix v2 Transaction API key QPS

Matrix v2 calls the Transaction API to report usage costs to APIM. Failed calls are retried, so occasional small breaches are less critical than central key breaches. Sustained saturation is still a problem.

Monitor at:
- **APIM Grafana — Transaction API key**: [batchTransactionApiProd](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1&from=now-24h&to=now&var-developerappname=batchTransactionApiProd%20-%20%28navfuturama@groups.tomtom.com%29&var-environment=prod&var-apiproduct=TransactionAPI)
- **Batch&Matrix Grafana — Transaction API**: https://grafana.prod.batch.tt4.nl/d/transactionapi-metrics-1/transaction-api?orgId=1

To increase this quota, create a ticket to SCA using the standard procedure.

---

## Common Issues and Resolutions

### Client reports slow processing

1. Identify the customer token (see Customer Identification section).
2. Check the **maxParallelRequests** usage panel — is the client hitting the CPU core ceiling? This is the most common reason.
3. Check the **sync/async parallel batch processing** panels — is the client hitting the parallel submission ceiling?
4. Check **QPS to Matrix v2** — is the client being throttled at the submission/status/download level?
5. Check the **central API key QPS** — is the global key saturated, affecting all clients?
6. Check whether the client is using the slower **New Haven** engine (requests with complex avoidances, bicycle/pedestrian mode, or no historical traffic). New Haven submissions take significantly longer than Asterix submissions — this is expected behavior, not a quota issue.

### Client reports HTTP 429 errors

- Check APIM Grafana "Call volume vs quota breaches" for the client (see QPS to Matrix v2 section above).
- If the client's QPS is being breached, raise the quota in Apigee by filing an SCA ticket — the team cannot do this directly.
- If the central key is saturated, follow the emergency procedure at: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832

### Client using same API key for sync and async submissions

Recommend separate API keys for synchronous ("live traffic") and asynchronous ("batch queue") submissions. With a single key, both use cases share the same `maxParallelRequests` budget and QPS, and compete with each other. With separate keys, each use case gets its own independent limits and they do not interfere.

### Pulsar queue appears stuck (async processing stalled)

Check the **"Async matrices - parallel batch processing"** panel for a growing backlog with no messages being unacked. This means backends are not consuming from the queue.

1. Check [Health indicators dashboard](https://grafana.prod.tt-lns-batch.com/d/batch2-health-indicators-1/health-indicators?orgId=1) for front13/backend13 health check failures.
2. Check [Blob storage dashboard](https://grafana.prod.tt-lns-batch.com/d/batch2-storage-1/blob-storage?orgId=1) for [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/) latency.
3. Perform rollout restart of Matrix v2 components via [Jenkins](https://www.jenkins.io/doc/): [rollout_restart_batch_cluster_prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/)
4. If restart does not help, perform rollout restart of the Pulsar cluster: [rollout_restart_pulsar_cluster_prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/)

### Other reasons for slow processing (component-level issues)

Slow processing affecting many customers at the same time (not a single client) is likely a component failure, not a quota issue. Refer to the "Other reasons for slow processing" section of the Batch&Matrix 1.2 runbook at: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849 — that guidance also applies to Matrix Routing v2.

Relevant alerts to watch:
- Dashboard: *Pulsar state alerts* — `backlog size > 2 without rate limiter events`
- Dashboard: *Status codes alerts* — `front13 - sync submissions - How many customers received at least one http 408/429? (percentage every minute)` (threshold: 30% of customers)

---

## Escalation

- **Quota increases (QPS or maxParallelRequests)**: Cannot be done by the team — these are Apigee settings tied to customer contracts. File an SCA ticket describing the customer, current quota values, and the requested new values.
- **Central API key quota exhaustion**: Follow the emergency runbook at https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832
- **Transaction API key quota exhaustion**: Create a ticket to SCA for standard quota increase.
- **Async parallel limit increase for a specific client**: Can be done by the team — run the pulsar-toolset script ([lines 145-167](https://github.com/tomtom-internal/batch-service2-infra/blob/661cd9592eb73cd2e5005ebe405b45a98f3e1a73/terraform-apache-pulsar/pulsar-add-tenant-payload.sh#L145-L167)).
- **Sync parallel limit increase for a specific client**: Not technically possible per-client. Requires a global change to `backend13-config` configmap and pod rollout.
- **Multi-region issues ([Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/))**: See infra runbooks for disabling a region: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233927941
- **Broader incident or unknown root cause**: Escalate to the Batch&Matrix dev team on-call.
