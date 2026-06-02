# Section 8: Cross-Cutting Concepts

This section covers architectural concepts that apply across Batch Search API, Batch Routing API, and Matrix Routing v1 (collectively referred to as Batch&Matrix). These concepts govern how the system enforces fairness, isolates customers, and manages submissions from receipt to result delivery.

---

## 8.1 QPS/QPM Rate Limiting

Batch&Matrix enforces rate limiting at two independent levels. Both must be correctly provisioned for a customer to get the expected throughput.

**Level 1 — QPS to Batch&Matrix itself.** Every HTTP call a client makes to the Batch&Matrix frontend (front12) — whether submitting a new batch or polling for a result — consumes quota enforced by [Apigee](https://cloud.google.com/apigee/docs)/APIM at the edge. The relevant Apigee quota names are `OnlineRoutingBatch_quotaPerSecond` for Batch Routing and Matrix Routing v1, and `OnlineBatchSearchGeneral_quotaPerSecond` for Batch Search. Rejections at this level return HTTP 429 to the client before the request reaches front12 and are visible in APIM [Grafana](https://grafana.com/docs/) as rejected API requests. Batch&Matrix has no visibility into how many requests were rejected at this layer.

**Level 2 — QPS to underlying services.** When backend12 processes batch items, it calls the underlying APIs (Routing API, Search API, Reverse Geocoding API, etc.) using the client's own API key. The client must therefore have sufficient QPS quota on those underlying APIs. This quota determines actual processing throughput. A client who submits 10,000 routing queries with a Routing API QPS of 10 will wait approximately 1,000 seconds for completion. The relationship is linear: `processing_time ≈ item_count / underlying_QPS`.

These two levels are independent. A client can have ample QPS to Batch&Matrix while being bottlenecked on underlying service QPS, or vice versa. To diagnose slowness, check both levels separately: Batch&Matrix Grafana for the processing side, APIM Grafana for the submission side.

---

## 8.2 Multi-Quota Mapping

Apigee models quotas using a **ratelimiter Quota Name**: endpoints that share a quota name draw from the same counter; endpoints with different quota names have independent counters. For example, `geocode` and `structuredGeocode` share the `OnlineGeocodingGeneral` quota name, whereas `searchAlongRoute` has its own `OnlineSearchAlongRoute` quota name.

Batch&Matrix mirrors this structure internally through the **multi-quota mapping** configured in `backend/src/main/resources/application.yml` under the `rate-limiter.multi-quota-mapping` key ([L120–L184](https://github.com/tomtom-internal/batch-service2-1.2/blob/master/backend/src/main/resources/application.yml#L120-L184)). Each entry maps a batch service-name (the internal identifier for a query type within a submission) to the corresponding Apigee quota key. The backend uses this mapping to track rate consumption per quota bucket — not per endpoint — matching exactly how Apigee counts usage on the client's key.

Example mappings for the `api.tomtom.com` environment (search2 service):

| Batch service-name | Apigee quota key |
|--------------------|-----------------|
| `search`, `poiSearch`, `categorySearch`, `geometrySearch`, `nearbySearch` | `OnlineSearchGeneral` |
| `searchAlongRoute` | `OnlineSearchAlongRoute` |
| `geocode`, `structuredGeocode` | `OnlineGeocodingGeneral` |
| `reverseGeocode` | `OnlineReverseGeocodingGeneral` |
| `additionalData` | `OnlineSearchAdditionalData` |
| `chargingAvailability` | `OnlineChargingAvailabilityGeneral` |

The Microsoft Azure environment (`api.azure.tomtom.com`) uses a simplified mapping because Search APIs there are configured as a single product with a common quota, with `additionalData` as the only exception.

In practice, a Batch Search submission that mixes several search types is subject to multiple independent quota buckets at once. Throttling on any single bucket slows the entire submission, even if all other buckets have headroom remaining. The Grafana "Quota usage" dashboard breaks down usage by multi-quota key, so you can identify which specific quota is the bottleneck.

---

## 8.3 Client Key Model

Batch&Matrix does not use a shared service account or pool of TomTom-internal keys to call underlying APIs. Instead, **backend12 forwards the client's own API key** when making requests to Routing API, Search API, or any other underlying service.

This design has two important consequences:

1. **Quota is personal.** A client's throughput is directly tied to the QPS quotas on their own key. Two customers using Batch&Matrix at the same time do not share an underlying-service quota pool and cannot affect each other's processing speed.

2. **Key separation matters.** If a client uses the same API key for both direct (non-batch) calls to an underlying service and for Batch&Matrix submissions, those two traffic streams compete for the same quota. Batch&Matrix has no visibility into concurrent direct usage of the key and will not self-throttle to compensate. Provision separate API keys per traffic type: one for live single requests, one for synchronous batch, one for asynchronous batch — and, if both Batch Routing and Batch Search are used, separate keys per service type.

---

## 8.4 Concurrent Request Limiting

In addition to QPS-based rate limiting, backend12 caps the number of **simultaneous in-flight HTTP requests** it makes to an underlying service on behalf of a single customer. This limit is derived from the customer's underlying-service QPS and a configured multiplier (defined globally in `application.yml` at L99–L119). The cap prevents a customer with slow-responding batch items from accumulating many hanging connections against the underlying service.

Separately, the system limits each customer to a maximum of **40 parallel batch jobs per service type** (Batch Search, Batch Routing, or Matrix Routing v1) in active processing at any time. This limit is enforced at the [Apache Pulsar](https://pulsar.apache.org/docs/) level via consumer configuration in the infra scripts. Submissions beyond the 40-job limit are queued in the customer's Pulsar topic and processed as active jobs complete.

If a customer is near this limit and processing appears slow, check the "Number of parallel batch processing usage" panel in the Quota usage Grafana dashboard: the "local backlog" value shows pending messages, and "number of unacknowledged messages" shows how many are actively being processed. To raise the 40-job limit for a specific customer, run the relevant commands on pulsar-toolset.

---

## 8.5 Synchronous vs. Asynchronous Mode

Batch&Matrix supports two submission modes, selectable per request:

**Synchronous mode** — The client submits a batch and holds the HTTP connection open. The frontend waits for backend12 to finish processing and returns the result directly in the HTTP response. Use this mode for small, time-sensitive submissions where the client needs an immediate answer and can tolerate a long-lived connection. The connection has a timeout; if processing does not complete in time, the client receives HTTP 408.

**Asynchronous mode** — The client submits a batch and immediately receives HTTP 202 (Accepted). The submission is enqueued in Apache Pulsar for background processing. The client polls a status endpoint; when the result is ready, the poll returns HTTP 303 (See Other) with a redirect to the result location in [Azure Blob Storage](https://learn.microsoft.com/azure/storage/blobs/). Use this mode for large submissions, queued workloads, or situations where the client cannot maintain a long-lived connection.

The choice of mode does not affect the underlying processing pipeline. Both modes route submissions through the same Pulsar topics and backend12 workers. The only difference is how the client is notified that work is done.

---

## 8.6 Pulsar Topic Naming

Each customer gets a dedicated Apache Pulsar topic per service type. Topics are not shared across customers or across service types. The topic name encodes both the customer identity (customer token, which equals the APIM developer app ID) and the service type:

- `SEARCH2` — Batch Search API submissions
- `ROUTING1` — Batch Routing API submissions
- `MATRIX1` — Matrix Routing v1 submissions

This per-customer, per-service-type isolation ensures that a backlog for one customer in one service cannot delay processing for a different customer or a different service type for the same customer. To identify which queue belongs to which customer, search for `"Created producer for topic"` in front12 logs filtered by customer token to find the full topic name.

---

## 8.7 Error Code Semantics

The HTTP status codes used by Batch&Matrix and the underlying services have specific, operationally significant meanings:

| Code | Context | Meaning |
|------|---------|---------|
| **202** | Batch&Matrix response | Async submission accepted; job is queued. Normal, expected response for async mode. |
| **303** | Batch&Matrix response | Result is ready; Location header points to the result in Blob Storage. |
| **408** | Batch&Matrix response | Sync submission timed out before processing completed. The job may still be running in the background. |
| **429** | Batch&Matrix response or underlying service | Rate limit exceeded. The request was rejected because the client's QPS quota was breached. |
| **403** | Underlying service response | Quota exceeded as seen by Apigee. May be transient due to time-synchronization differences between backend12 and Apigee — see note below. |

**On 403 from underlying services:** backend12 enforces the QPS limit it calculates internally, but Apigee measures the "current second" independently. Because system clocks are not perfectly aligned, Apigee may see a burst that crosses a quota boundary a few milliseconds before or after backend12's internal window resets. This produces occasional 403 responses from underlying services even when backend12 believes it is within quota. This is a known, accepted limitation of the design. A small number of 403s is not a problem indicator; a sustained stream of 403s warrants checking whether the customer's underlying-service QPS is correctly provisioned.
