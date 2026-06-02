# Batch&Matrix 1.2 — Quotas and Slow Processing Runbook

**Scope:** Batch Search API, Batch Routing API, Matrix Routing v1 (batch-service2-1.2).
Does NOT apply to Matrix Routing v2.

**Source of truth:** Confluence page 233915849 — "Batch&Matrix 1.2 - quotas, processing speed, recommendations for clients"

---

## When to use this runbook

Open this runbook when you observe any of the following:

- Customers reporting batches not completing, or taking much longer than expected.
- HTTP 403 or 429 errors surfaced in alerts or customer reports.
- [Grafana](https://grafana.com/docs/grafana/latest/) alerts firing:
  - "backlog size > 2 without rate limiter events" (consumers not polling messages)
  - "front12 - sync submissions - How many customers received at least one http 408/429? (percentage every minute)" — fires at >= 30%
- General degraded throughput affecting multiple customers.

Work through Steps 1-5 in order. For NOC-only triage, jump to the NOC-Specific Section at the bottom.

---

## Step 1: Identify the Customer

Gather the API key, customer token (= APIM developer app ID), and optionally the [Pulsar](https://pulsar.apache.org/docs/) queue name before checking any quota panels. Start from whatever you have — batch ID, tracking ID, API key, customer token, or developer email.

### 1a. Find API key and customer token from a batch ID, tracking ID, or known API key

**Grafana Cloud Logs (preferred):**

Go to one of these pre-filtered links and add your known value as a third log-line search term:

- EU cluster: https://grafana.tomtomgroup.com/goto/CEEQuRbNg?orgId=1
- US cluster: https://grafana.tomtomgroup.com/goto/fmCQuRxHg?orgId=1

Apply filters manually if not using the shortlinks:

```
[Labels filter]      k8s_deployment_name=front12-deployment
[Search in log line] New submission request
[Search in log line] <batch-id | tracking-id | api-key | customer-token>
```

The log line for a new submission contains batch ID, tracking ID, API key (shown as `first4Chars...last4Chars`), and customer token together.

**Scalyr (alternative):**

```
app.kubernetes.io\/name="front12-deployment" "New submission request" "<what you have>"
```

Examples:
```
app.kubernetes.io\/name="front12-deployment" "New submission request" "some-batch-id"
app.kubernetes.io\/name="front12-deployment" "New submission request" "api…key"
app.kubernetes.io\/name="front12-deployment" "New submission request" "customer-token"
```

### 1b. Find customer token from a developer email or application name

Use the APIM Grafana dashboards:

- **Search by name/email (fuzzy):** https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview
- **Search by email, app ID, API key (exact):** https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id?orgId=1

A developer may have multiple apps. Click into each app, then check the "Application usage information" section to confirm which app has a Batch API product assigned and recent Batch&Matrix usage. The "developer app id" shown there is the customer token used everywhere else.

### 1c. Find Pulsar queue name from customer token

**Grafana Cloud Logs:**

- EU: https://grafana.tomtomgroup.com/goto/k8jXXgxHR?orgId=1
- US: https://grafana.tomtomgroup.com/goto/K_WrugbNg?orgId=1

Manual filter:
```
[Labels filter]      k8s_deployment_name=front12-deployment
[Search in log line] Created producer for topic
[Search in log line] <customer-token>
```

Log format: `Created producer for topic <topic_name> customerToken=<customer-token>`

Queue naming convention:
- `SEARCH2` — Batch Search
- `ROUTING1` — Batch Routing
- `MATRIX1` — Matrix Routing v1

**Scalyr:**
```
app.kubernetes.io\/instance="front12" "Created producer for topic" "<customer-token>"
```

---

## Step 2: Check QPS to Batch&Matrix Service

This tells you how many requests the customer can make to the Batch&Matrix service itself — submission and download endpoints combined.

**Batch&Matrix Grafana (status codes seen by our service):**

https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client?orgId=1

Filters:
- `Batch version` = `12`
- `customerToken` = `<customer token from Step 1>`

**APIM Grafana (authoritative quota enforcement view):**

https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1

Filters:
- `Developer app - email` = `<developer email>`
- `Environment` = `prod` or `microsoft`
- `New product structure` = `True`
- API product / Child product / Method by API type:

| API | API product | Child product | Method |
|-----|-------------|---------------|--------|
| Batch Search | Batch Search API | Batch Search API Batch | search 2 batch |
| Batch Routing | Routing API | Routing API Calculate Route | routing 1 batch |
| Matrix Routing v1 | Routing API | Routing API Calculate Route | routing 1 matrix |

**What to look for:** If _Rejected API requests_ appears on the APIM dashboard, the customer's QPS to Batch&Matrix is too small. Check the QPS consumption graph to see how frequently the quota is hit.

Note: This QPS limit is set in [Apigee](https://cloud.google.com/apigee/docs) based on the customer's contract. The oncall team cannot increase it directly — escalate to the account team or APIM owners.

---

## Step 3: Check QPS to Underlying Services

Batch&Matrix uses the customer's own API key to call underlying services (Routing API, Search API, Reverse Geocoding API, etc.) on the customer's behalf. The customer's QPS to those services directly controls how fast batches are processed.

**Grafana dashboard — Quota Usage (Batch 1.2):**

https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?orgId=1

Filters:
- `apiKey` = `<API key from Step 1>`
- `customerToken` = `<customer token from Step 1>`

In the "quota usage" section look at:
- `QPS (quota used)` — actual throughput consumed
- `Customer maxQps limit` — the ceiling

**Understanding multi-quota (the dashboard legend):**

The legend shows `<service_name>/<multi_quota_key>`. Key points:
- `routing1` covers both Batch Routing and Matrix Routing v1 — they share the same underlying Routing API quota.
- `search1` can have multiple quota keys because different search endpoints (forward search, search along route, geocode, structured geocode, etc.) each have their own Apigee "ratelimiter Quota Name". Throttling even one key slows the entire Batch Search recalculation, even if the other keys are not fully utilized.
- The multi-quota mapping is configured in `backend/src/main/resources/application.yml` at key `rate-limiter.multi-quota-mapping` (see batch-service2-1.2 repo, lines 120-184).

**Is quota exhaustion actually a problem?**

Not always. Consider the customer's usage pattern:

- **Large queue workload** ("compute 10,000 items, then the next 10,000"): The QPS will be fully utilized by design. Higher QPS gives faster results, but the customer may already be satisfied with current throughput. Ask: is the customer unhappy with the processing time?
- **Live traffic** ("submit and need results now"): Full QPS utilization is a genuine problem — raise quota.

Quick sanity check: open the Client Usage dashboard to see submission volume:

https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage

Filters: `Batch version=12`, `apiKey=<api key>`

Formula: `items_submitted / QPS = expected_processing_seconds`. E.g. 10,000 items at QPS 5 = ~2000 s of processing.

Also check APIM Grafana for the underlying service quota:

https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1

Use the same filters as Step 2, but set API product/Child product/Method to the relevant underlying service (e.g. Routing API / Routing API Calculate Route / routing 1 for routing).

---

## Step 4: Check Concurrent Request Limits

Two distinct limits apply here. Both are visible on the same Quota Usage dashboard:

https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?orgId=1

Filters: `apiKey=<api key>`, `customerToken=<customer token>`

### 4a. Concurrent requests to underlying service

Batch&Matrix caps the number of in-flight HTTP requests to underlying services per customer. The cap is derived from the customer's QPS using global multipliers defined in `application.yml` (batch-service2-1.2 repo, lines 99-119). There is no per-customer override for this limit.

In the "Concurrent requests" panel: if the customer is also hitting QPS throttling (Step 3), that is the primary lever — focus there first. If QPS is fine but concurrent requests are capped, the customer is sending batch items with high per-item latency (heavy route calculations, etc.). Inform the customer of the internal concurrency cap and suggest they re-estimate their required underlying-service QPS.

### 4b. Maximum number of parallel batches (40-batch limit)

The system allows a maximum of **40 parallel batch processing slots per service** (Batch Search / Batch Routing / Matrix Routing v1 each counted separately). This is set in Pulsar configuration (batch-service2-infra repo, `terraform-apache-pulsar/pulsar-add-tenant-payload.sh`, lines 27-30).

In the "Number of parallel batch processing usage" panel look at:
- `Local backlog` — messages pending in the queue, not yet picked up
- `Number of unacked messages` — messages currently being processed by backends

If `unacked messages` is at 40 and `local backlog` is growing, the customer has hit this limit.

**How to increase the limit for a specific customer:**

Log into `pulsar-toolset` and execute the commands from the script:
https://github.com/tomtom-internal/batch-service2-infra/blob/661cd9592eb73cd2e5005ebe405b45a98f3e1a73/terraform-apache-pulsar/pulsar-add-tenant-payload.sh#L145-L167

This is a live configuration change; no deployment required. Coordinate with the dev team before changing for a large customer.

---

## Step 5: Other Reasons for Slow Processing

If quota analysis (Steps 2-4) does not explain the slowness, especially when multiple customers are affected simultaneously, look for infrastructure-level issues.

### 5a. Health indicators

Dashboard: https://grafana.prod.tt-lns-batch.com/d/batch2-health-indicators-1/health-indicators?orgId=1

Checks whether front12 or backend12 application health checks are reporting problems.

### 5b. Blob storage

Dashboard: https://grafana.prod.tt-lns-batch.com/d/batch2-storage-1/blob-storage?orgId=1

Elevated storage operation latency can slow result delivery and cause timeouts.

### 5c. Stuck queue detection

The alert "backlog size > 2 without rate limiter events" fires when a Pulsar topic has a growing backlog but backends are not consuming messages. Note: this alert does NOT account for the 40-parallel-batch limit — check Step 4b first before concluding the queue is stuck.

To confirm backends are actively processing, run a Scalyr search:

```
app.kubernetes.io\/name="backend-deployment" "<api-key>"
```

Make sure log lines appear from all backend12 pods. Absence on some pods indicates a partial outage.

Also check QPS activity on the Quota Usage dashboard — if QPS used is zero for an active customer, backends are not processing.

### 5d. Rollout restart via Jenkins

When a queue appears genuinely stuck and infrastructure checks show nothing obvious:

- **Restart Batch components:** https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/
- **Restart Pulsar cluster components:** https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/

Both are Jenkins jobs that perform rolling restarts without downtime. Run the Batch restart first; only escalate to Pulsar restart if the Batch restart does not resolve the issue, or if Pulsar itself shows unhealthy indicators on the health dashboard.

### 5e. Release job as a fix

If Grafana monitoring confirms an issue (errors, unhealthy indicators, stuck processing) and a rollout restart does not resolve it, try running the release job to redeploy the latest known-good version:

**Jenkins:** Batch → Prod → Batch_Release → Simple_Batch_release
https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch_Release/view/Simple_Batch_release/

1. Check recent releases for a known-good branch: https://github.com/tomtom-internal/batch-service2-infra/blob/master/RELEASES.md
2. Enter the target branch into the `RELEASE_CANDIDATE_BRANCH` field.
3. Enable `PANIC_MODE` to speed up deployment if the incident is ongoing.
4. Wait for the job to complete (~30 min).

Use this after a rollout restart fails, or when you suspect the current deployment itself is broken rather than a transient runtime issue.

---

## NOC-Specific Section

Use this section for first-line triage. If these steps do not explain the issue, escalate to on-call developer and provide what you found.

### NOC Step 1: Identify the customer

You need the customer's developer email, API key, or batch/tracking ID. Use whichever you have:

- **From email:** https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview — search by name or email to get developer app ID.
- **From batch/tracking ID or API key:** https://grafana.tomtomgroup.com/goto/CEEQuRbNg?orgId=1 (EU) or https://grafana.tomtomgroup.com/goto/fmCQuRxHg?orgId=1 (US) — filter `k8s_deployment_name=front12-deployment`, search for `New submission request` and your known value. The log line shows API key and customer token together.

### NOC Step 2: Check QPS to the Batch&Matrix service

Go to: https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1

Set:
- `Developer app - email` = customer email
- `Environment` = `prod` (or `microsoft`)
- `New product structure` = `True`
- API product / Child product / Method per the table in Step 2 above

If _Rejected API requests_ appears, the customer is hitting their Batch&Matrix QPS limit. Note the quota value and escalate to the account team — this cannot be changed by NOC.

### NOC Step 3: Check QPS to underlying services

Go to: https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches?orgId=1

Same dashboard, same filters, but change the API product/method to the underlying service the customer queries (e.g. Routing API for batch routing submissions).

- If _Allowed API requests_ is close to _Quota limit_ or _Rejected API requests_ is visible: the underlying service QPS may be limiting processing speed. This is not necessarily a bug — see the explanation in Step 3 above.
- If breaches appear on the **underlying service** (not on Batch&Matrix itself), this is often expected. Two common causes: clock skew between Batch&Matrix and Apigee, or the customer using the same API key for both direct API calls and batch submissions.

Collect your findings (screenshots, quota values, customer email/token) and escalate to the on-call developer if the cause is unclear or if a quota increase is needed.
