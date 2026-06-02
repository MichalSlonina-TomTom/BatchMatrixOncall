# Section 6: Runtime View

This section describes the runtime behavior of Batch&Matrix 1.2. Three scenarios are covered:
the dominant asynchronous submission flow, the lightweight synchronous flow, and the
rate-limited processing loop that controls how quickly results are produced.

---

## 6.1 Asynchronous Batch Submission

The asynchronous flow is the primary path for large or long-running submissions (up to 10,000
items per request). The client submits once, receives an immediate acknowledgement, polls for
completion, and downloads results from Azure Blob Storage.

![Async Submission](../diagrams/runtime-async-submission.png)

### Notable interactions

**Quota enforcement at the front door (steps 1-2).** Every inbound request passes through
[Apigee](https://cloud.google.com/apigee/docs) / [APIM](https://learn.microsoft.com/en-us/azure/api-management/) before reaching front12. APIM enforces the per-customer QPS quota on the
Batch&Matrix submission endpoint (`OnlineRoutingBatch_quotaPerSecond` for Batch Routing /
Matrix v1, `OnlineBatchSearchGeneral_quotaPerSecond` for Batch Search). Requests exceeding
this quota are rejected with HTTP 429 before front12 is invoked.

**Decoupling via Pulsar (steps 3-4).** front12 validates the request, resolves the customer
token (APIM developer app ID), and publishes a single message to the customer's dedicated
[Apache Pulsar](https://pulsar.apache.org/docs/) topic. A dedicated topic per customer isolates queue backlogs: a slow customer
does not delay others. front12 returns HTTP 202 Accepted with a `Location` header pointing
to the status polling endpoint.

**Polling (steps 5-7).** The client polls `GET /batch/{batchId}/status`. Each poll passes
through APIM quota enforcement (counted against the same submission-endpoint quota). While the
batch is still processing, front12 returns HTTP 202. Use exponential back-off to avoid
exhausting the QPS quota through excessive polling.

**Processing handoff (steps 8-15).** backend12 consumes the Pulsar message and begins
processing items against the underlying services (Routing API, Search API, etc.) using the
**client's own API key**. This means the processing speed is bounded by the quota the client
holds for those underlying services, not by any Batch&Matrix-internal limit.

**Result storage and redirect (steps 16-18).** Once all items are processed, backend12 writes
the aggregated JSON result to [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/) and acknowledges the Pulsar message. On the
next status poll, front12 detects the result and returns HTTP 303 See Other with a signed Blob
Storage URL. The client downloads the file directly from Azure — front12 is not in the
download data path.

---

## 6.2 Synchronous Batch Submission

The synchronous flow is for smaller submissions where the client wants an immediate response
without managing a polling loop.

```
Client → APIM → front12 → Underlying Services (inline, no Pulsar)
                         → HTTP 200 (aggregated result in response body)
```

front12 processes all batch items inline within the HTTP connection. Without a Pulsar handoff,
latency is lower and the implementation is simpler, but the request times out if processing
takes too long. Use the synchronous endpoint only for small batches or latency-sensitive
"live traffic" scenarios.

Quota mechanics are identical to the asynchronous path: APIM enforces QPS on the submission
endpoint, and front12 forwards each item to underlying services using the client API key,
subject to that key's underlying-service quota.

If the synchronous endpoint is overloaded (HTTP 408 or 429 responses), switch to the
asynchronous endpoint or reduce submission frequency.

---

## 6.3 Rate-Limited Processing Loop

The processing loop inside backend12 translates a customer's underlying-service QPS quota
into actual throughput. Understand this mechanism before diagnosing slow processing incidents.

![Processing](../diagrams/runtime-processing.png)

### Multi-quota mapping

Underlying services expose multiple quota buckets that share a namespace with APIM's
`ratelimiter Quota Name`. For example, "forward search" and "search along route" belong to
different quota names even though both are Batch Search items. backend12 models this structure
through the **multi-quota mapping** (`rate-limiter.multi-quota-mapping` in `application.yml`).
Each item is assigned a quota key (e.g. `routing1`, `search1`, `geocode1`,
`reverse-geocode1`) and throttled against the corresponding bucket independently.

This design maximises throughput: a batch mixing routing and geocoding items can saturate
both quotas simultaneously. However, if *any* quota bucket is fully saturated, items in that
bucket stall. Because all buckets must complete before the batch finishes, one exhausted quota
can bottleneck the entire submission.

### Concurrent-request limit

Beyond QPS, backend12 caps the number of **concurrent in-flight requests** to underlying
services per customer. The cap equals the customer's QPS for that service multiplied by a
globally configured multiplier (defined in the `rate-limiter.concurrent-requests` section of
`application.yml`). This prevents slow individual requests from monopolising threads. When
items take unusually long to compute (heavy routing calculations, large geocoding payloads),
the concurrent-request limit binds before the QPS limit does. In that case, the
[Grafana](https://grafana.com/docs/) "Concurrent requests" panel on the Quota Usage dashboard
shows utilisation near the ceiling even when QPS is not fully consumed.

### Parallel batch limit

A second ceiling controls how many batch submissions can be **actively processed** for a given
service at the same time. This limit is **40 per service** (Batch Search, Batch Routing, Matrix
Routing v1) and is enforced at the Pulsar level via the maximum number of unacknowledged
messages per consumer. If a customer submits more than 40 concurrent batches, the excess queues
in the Pulsar backlog (visible as "Local backlog" on the Quota Usage dashboard) until an active
slot opens.

### Interaction between limits

The three limits — APIM QPS, concurrent requests, and parallel batch count — are independent
and can each become the binding constraint depending on the customer's workload:

| Binding constraint | Symptom | Grafana signal |
|---|---|---|
| Underlying-service QPS quota | Items processed, but slowly | "QPS quota used" panel near ceiling |
| Concurrent-request limit | Heavy items stall throughput | "Concurrent requests" panel near ceiling, QPS not saturated |
| Parallel batch limit (40) | New submissions queue | "Local backlog" growing, "Unacked messages" at 40 |

When backend12 receives a 429 or 403 from APIM, it backs off and retries the item. A 403 can
occur even when the customer's QPS is theoretically sufficient, because of clock skew between
backend12 and APIM (the "second" boundary is not perfectly synchronised). This is expected
and is not a configuration error. Sustained 403 errors over several minutes, however, indicate
that the QPS quota is genuinely too low for the submitted workload.

---

## References

- Quota details and troubleshooting guide: Confluence page 233915849 (Batch&Matrix 1.2 – quotas, processing speed, recommendations)
- `application.yml` rate-limiter configuration: `batch-service2-1.2/backend/src/main/resources/application.yml` (lines 99–184)
- Grafana – Quota Usage (Batch 1.2): https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2
- Grafana – APIM Call Volume vs Quota Breaches: https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches
- Grafana Cloud Logs (EU): https://grafana.tomtomgroup.com
