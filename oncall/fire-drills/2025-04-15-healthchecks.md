# Fire Drill: Healthchecks

**Date:** 2025-04-15

## Scenario

Review the healthcheck architecture for Batch 1.2 and Matrix v2. The drill covers ingress configurations, healthcheck endpoints, what each endpoint checks, and how they relate to [Kubernetes](https://kubernetes.io/docs/home/) probes, [HAProxy](https://docs.haproxy.org/) front health checks, and [Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/traffic-manager-overview) monitoring. Reference documentation used during the drill:

- [ingresses-and-healthchecks-batch12.md](https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/ingresses-and-healthchecks-batch12.md)
- [ingresses-and-healthchecks-matrixv2.md](https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/ingresses-and-healthchecks-matrixv2.md)
- [Kubernetes Ingress / HAProxy Grafana dashboard](https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy?from=now-30m&to=now&var-cluster_name=All&orgId=1)
- [Common Alerts Grafana dashboard](https://grafana.prod.batch.tt4.nl/d/common-alerts-1/common-alerts?from=now-30m&to=now&var-datasource=thanos-query&var-cluster_name=All&var-instance=All&var-code=All&orgId=1)

A recording of the session is available at: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQDS5-Umr7OSQruxc5PzIq2wATiD4_lxvxNbn408sdoztGo

## Participants

Not recorded on the Confluence page.

## Steps Performed

### Batch 1.2 — Ingresses

Batch 1.2 defines three ingresses:

| Ingress | Handles | Notes |
|---|---|---|
| `front12-submission-ingress` | Submission requests (Host header determines request type) | Uses HAProxy failover servers |
| `front12-submission-healthcheck-ingress` | All `/actuator` requests — healthcheck queries from Kubernetes and Traffic Manager | No failover servers (must reflect this region only) |
| `front12-download-ingress` | Download requests | No failover servers (sticky region) |

### Batch 1.2 — Healthcheck types and endpoints

| Healthcheck type | Endpoint used |
|---|---|
| Frontend pods — liveness | `/actuator/health/liveness` |
| Frontend pods — readiness | (not set) |
| Backend pods — liveness | `/actuator/health/liveness` |
| Backend pods — readiness | `/actuator/health/readiness` |
| Traffic Manager — submission | `/actuator/health/readiness` (frontend) |
| Traffic Manager — download | `/actuator/health/download` (frontend) |
| HAProxy — `front12-submission-ingress` | `/actuator/health/readiness` (frontend) |
| HAProxy — `front12-submission-healthcheck-ingress` | `/actuator/health/readiness` (frontend) |
| HAProxy — `front12-download-ingress` | `/actuator/health/download` (frontend) |

### Batch 1.2 — Healthcheck endpoint definitions

**Frontend:**

| Endpoint | Components checked | Usage | Notes |
|---|---|---|---|
| `liveness` | `livenessState`, `diskSpace` | Kubernetes liveness probe | Failure → pod deleted immediately. Requires ≥10 GB free disk (set in `application.yaml`). |
| `readiness` | `readinessState`, `diskSpace`, `pulsar`, `storageClient` | HAProxy front health check | Failure → HAProxy stops sending submissions to this pod. Requires working [Pulsar](https://pulsar.apache.org/docs/next/concepts-overview/) and Storage. |
| `download` | `livenessState`, `storageClient` | HAProxy front health check (download) | Failure → HAProxy stops sending download requests. Requires working Storage. |

**Backend:**

| Endpoint | Components checked | Usage | Notes |
|---|---|---|---|
| `liveness` | `livenessState`, `diskSpace` | Kubernetes liveness probe | Failure → pod deleted immediately. Requires ≥10 GB free disk. |
| `readiness` | `readinessState`, `diskSpace`, `pulsar`, `storageClient` | Kubernetes readiness probe | Failure → pod marked not ready. Requires working Pulsar and Storage. |

[Redis](https://redis.io/docs/latest/) is intentionally excluded from Batch 1.2 health checks — fallbacks for unhealthy Redis are handled in application code (see `redis-high-availability.md`). Both async and sync submissions use the same internal processing flow in Batch 1.2; the difference is in the public API only.

---

### Matrix v2 — Ingresses

Matrix v2 uses a more granular ingress setup to reflect its split async/sync architecture:

| Ingress | Handles | Notes |
|---|---|---|
| `front13-submission-async-ingress` | Async submission requests | Uses HAProxy failover servers |
| `front13-submission-async-healthcheck-ingress` | `/actuator/health/async-processing` queries | No failover servers |
| `front13-submission-sync-ingress` | Sync submission requests | Uses HAProxy failover servers |
| `front13-submission-sync-healthcheck-ingress` | `/actuator/health/sync-processing` queries | No failover servers |
| `front13-submission-tm-healthcheck-ingress` | `/actuator/health/readiness` — Traffic Manager queries | No failover servers |
| `front13-download-ingress` | Download requests | No failover servers (sticky region) |

### Matrix v2 — Healthcheck types and endpoints

| Healthcheck type | Endpoint used |
|---|---|
| Frontend pods — liveness | `/actuator/health/liveness` |
| Frontend pods — readiness | (not set) |
| Backend pods — liveness | `/actuator/health/liveness` |
| Backend pods — readiness | `/actuator/health/sync-processing` |
| Traffic Manager — submission | `/actuator/health/readiness` |
| Traffic Manager — download | `/actuator/health/download` |
| HAProxy — async submission ingresses | `/actuator/health/async-processing` |
| HAProxy — sync submission ingresses | `/actuator/health/sync-processing` |
| HAProxy — TM healthcheck ingress | `/actuator/health/readiness` |
| HAProxy — download ingress | `/actuator/health/download` |

### Matrix v2 — Healthcheck endpoint definitions

**Frontend:**

| Endpoint | Components checked | Usage | Notes |
|---|---|---|---|
| `liveness` | `livenessState`, `diskSpace` | Kubernetes liveness probe | Failure → pod deleted. Requires ≥10 GB free disk. |
| `sync-processing` | `readinessState`, `backendAvailability` | HAProxy front health check (sync ingresses) | Failure → HAProxy stops sending sync submissions to this pod. Sync path does NOT need Pulsar or Storage. `backendAvailability` tracks whether backend pods are available for sync requests. |
| `async-processing` | `readinessState`, `pulsar`, `storageClient`, `frontPulsarClient`, `shutdownListener` | HAProxy front health check (async ingresses) | Failure → HAProxy stops sending async submissions. Requires working Pulsar and Storage. |
| `readiness` | `readinessState`, `diskSpace` | Traffic Manager submission healthcheck | Intentionally lightweight — HAProxy handles failover for processing degradation. Failure for all pods → region disabled at TM level. |
| `download` | `readinessState`, `storageClient` | HAProxy front health check (download ingress) | Failure → HAProxy stops sending download requests. Requires working Storage. |

**Backend:**

| Endpoint | Components checked | Usage | Notes |
|---|---|---|---|
| `liveness` | `livenessState`, `diskSpace` | Kubernetes liveness probe | Failure → pod deleted. Requires ≥10 GB free disk. |
| `async-processing` | `readinessState`, `pulsar`, `storageClient`, `backendPulsarClient`, `shutdownListener` | Metrics only (not used as a Kubernetes probe) | Informational — async path requires Pulsar and Storage. |
| `sync-processing` | `readinessState` | Kubernetes readiness probe | Failure → front pods stop sending sync submissions to this backend. Sync path does NOT use Pulsar or Storage. |

Key architectural notes for Matrix v2:
- Async and sync submissions are handled by the same pods but via different flows.
- A pod/region can be **partially degraded** — e.g., async broken but sync still working; ingresses and healthchecks are designed to reflect this granularity.
- Redis is excluded from healthchecks; fallbacks are in code (see `redis-high-availability.md`).

### Observability — Healthcheck status dashboards

Inspect individual healthcheck component status to quickly identify which dependency caused a pod to become unhealthy:

- [Front health indicators](https://grafana.prod.batch.tt4.nl/d/batch2-front-health-indicators-1/front-health-indicators?from=now-30m&to=now&var-cluster_name=All&orgId=1)
- [Backend health indicators](https://grafana.prod.batch.tt4.nl/d/batch2-backend-health-indicators-1/backend-health-indicators?from=now-30m&to=now&var-cluster_name=All&orgId=1)
- [All health indicators](https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators?from=now-30m&to=now&var-cluster_name=All&orgId=1)

The [Common alerts dashboard](https://grafana.prod.batch.tt4.nl/d/common-alerts-1/common-alerts?orgId=1) fires on sustained partial degradation, including:
- Working front12 pods (HAProxy-healthchecked) < 1 for 5 minutes
- Working backend12 pods < 1 for 5 minutes
- Working front13 pods (HAProxy-healthchecked) < 1 for 5 minutes
- Working backend13 pods < 1 for 5 minutes
- sync/async not working on some front13 pod for 5 minutes
- sync/async not working on some backend13 pod for 5 minutes
- Korean Pulsar/Storage front12/13 not working for 5 minutes

## Issues Encountered

None recorded on the Confluence page.

## Lessons Learned

The Confluence page for this drill contained minimal notes — the primary content was pointers to the reference docs and dashboards listed above. Key takeaways inferred from those docs:

- Matrix v2 has a significantly more granular healthcheck architecture than Batch 1.2, enabling partial-degradation scenarios (e.g., async broken while sync continues to serve traffic).
- The Traffic Manager healthcheck endpoint (`/actuator/health/readiness`) in Matrix v2 is intentionally lightweight — HAProxy handles per-pod failover, and Traffic Manager only intervenes when the entire region is down.
- Healthcheck ingresses do NOT use HAProxy failover servers — they must reflect the health of the local region only.
- Redis failures are handled in application code with fallbacks, not by removing pods from rotation via healthchecks.
- Disk space (threshold: 10 GB) is included in both liveness and readiness endpoints for front and backend pods across both products.

## Action Items

None recorded on the Confluence page.
