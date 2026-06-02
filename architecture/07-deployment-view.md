# Section 7: Deployment View

## Infrastructure Level 1 — Multi-Region Azure Overview

![Deployment](../diagrams/deployment-azure.png)

Batch&Matrix runs across multiple Azure regions in a single Azure subscription
(`NAV Routing/Search Batch - Production`,
subscription `2c48294f-c12f-4cd5-8c1a-b57f43e6fa43`).
All regions share one resource group for Traffic Manager profiles
(`batch-traffic-manager-prd`) but have independent, isolated stacks for
compute, messaging, and storage. This isolation prevents a failure in one
region from spreading to others and lets data-residency constraints
(EU, US, Korea) be enforced at the DNS level.

**Active production regions**

| Region ID | Azure name     | Geography |
|-----------|----------------|-----------|
| a1        | westeurope     | EU        |
| b1        | northeurope    | EU        |
| a2        | westus2        | US        |
| b2        | eastus         | US        |
| a3        | koreacentral   | Korea     |

---

## Infrastructure Level 2 — Component Detail

### 1. [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/) (DNS geo-routing)

Azure Traffic Manager is the global entry point. It routes client requests via geographic DNS to the nearest healthy region. Each geography has its own Traffic Manager profiles for submission endpoints:

- `global-prod-submission12-api-tt-batch` / `global-prod-submission13-api-tt-batch` — catches all traffic not matched by a regional geography
- `eu-prod-submission12-api-tt-batch` / `eu-prod-submission13-api-tt-batch` — serves EU clients (`eu.api.tomtom.com`)
- `us-prod-submission12-api-tt-batch` / `us-prod-submission13-api-tt-batch` — serves US clients
- `kr-prod-submission12-api-tt-batch` / `kr-prod-submission13-api-tt-batch` — serves Korea clients

Download and status requests bypass Traffic Manager submission profiles. Every batch ID embeds a **sticky region ID** at the front (e.g., `a1-31176475-…`). [APIM](https://learn.microsoft.com/en-us/azure/api-management/)/[Apigee](https://cloud.google.com/apigee) extracts this prefix and routes directly to the matching regional DNS zone, so results are always fetched from the region that processed the job.

**Important:** Never disable Traffic Manager download profiles when taking a region out of service — clients with already-submitted jobs still need to retrieve their results. Disable only the submission profiles. For step-by-step instructions, see the runbook:
[oncall/runbooks/traffic-manager.md](../oncall/runbooks/traffic-manager.md).

Use the scripted helper in the infra repository to disable or re-enable a region without touching the Azure portal:

```bash
# Disable westeurope in production
./scripts/maintenance/disable-region.sh prod westeurope \
  --includeBatch12 --includeBatch13 --includeWaypoints

# Re-enable after recovery
./scripts/maintenance/test-and-enable-region.sh prod westeurope \
  --includeBatch12 --includeBatch13 --includeWaypoints
```

### 2. [AKS](https://learn.microsoft.com/en-us/azure/aks/) Clusters — front12 and backend12

Each region runs one AKS (Azure Kubernetes Service) cluster with two long-running [Kubernetes](https://kubernetes.io/docs/) Deployments that handle all Batch&Matrix traffic:

**front12** (HTTP frontend, repo: `batch-service2-1.2`)
- Exposes three ingresses: submission, submission-healthcheck, and download.
- Accepts client requests, validates quota (via Apigee/APIM), and publishes jobs to the [Apache Pulsar](https://pulsar.apache.org/docs/) queue (async mode) or processes them directly (sync mode).
- Liveness probe: `GET /actuator/health/liveness`
- Readiness probe used by Traffic Manager submission endpoints: `GET /actuator/health/readiness`
- Download healthcheck used by Traffic Manager download endpoints: `GET /actuator/health/download`

**backend12** (batch processor, repo: `batch-service2-1.2`)
- Consumes jobs from Pulsar, fans them out to underlying services (Routing API, Search/Geocoding API) using the client's own API key.
- Stores aggregated results in Azure Blob Storage.
- Liveness probe: `GET /actuator/health/liveness`
- Readiness probe: `GET /actuator/health/readiness`

Matrix Routing v2 (repo: `batch-service2`) runs its own frontend and processor pair in the same regions. It uses a central (non-client) API key for calls to underlying services. For its separate architecture, see the MatrixV2 ingress documentation (`docs/ingresses-and-healthchecks-matrixv2.md`).

### 3. Apache Pulsar Cluster (per region)

Each region hosts a dedicated Apache Pulsar cluster
(`pulsar{number}-{env}-{region}`). Pulsar decouples job acceptance from
batch processing and delivers job messages durably and in order.
front12 publishes to the regional Pulsar cluster; backend12 consumes from it.
The cluster is managed via the `batch-service2-pulsar` repository.

One Pulsar cluster per region is intentional: it prevents cross-region queue consumption, keeps data within the required geography, and limits the blast radius of a Pulsar outage to a single region.

### 4. [Azure Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/) (per region)

Each region has a dedicated Azure Storage account (format: `batch-core{n}-{env}`,
e.g. `batch-core1-prd`) in the per-region core resource group. backend12 writes job metadata, per-item request blobs, response blobs, and final result payloads here. front12 reads from the same account when a client polls for status or downloads a completed batch.

Storage access uses a per-region user-assigned [managed identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/) in the `managed-identities-prd` resource group — no storage keys are used at runtime.

**Disaster-recovery note:** Blob Storage is not replicated across regions. If a region is permanently lost and in-flight jobs must be recovered, manually copy all blobs from the failed region to a replacement region before switching Traffic Manager over. Pulsar messages may also need to be reconstructed from blob metadata. See `docs/deploy-new-region.md` in the infra repo for the full procedure.

### 5. Deployment Pipeline — [Jenkins](https://www.jenkins.io/doc/) CI

Continuous delivery runs on Jenkins at
[https://ci.dev.batch.tt4.nl](https://ci.dev.batch.tt4.nl). The pipeline is configured in the **Batch2 Release** job and integrates with the GitHub `tomtom-internal` organisation repositories via webhooks. For setup details, see `docs/jenkins-github-integration.md` in the infra repo.

Typical release flow:

1. Merge to `master` (or a release branch) in one of the application repos (`batch-service2-1.2`, `batch-service2`, `batch-service2-infra`).
2. Jenkins builds and tests the artefact.
3. Trigger the **Batch2 Release** job (or run it manually) to deploy to each configured region in sequence.
4. Region-specific settings come from `region-configuration.yaml`, `region-storage-batch-configuration.yaml`, and `region-storage-matrixv2-configuration.yaml` in the infra repo.

Infrastructure changes ([Terraform](https://developer.hashicorp.com/terraform/docs) / ARM templates) in `batch-service2-infra` follow the same pipeline. To add a new region, update these YAML files and the Jenkins job definition — see `docs/deploy-new-region.md`.

---

## Mapping of Building Blocks to Infrastructure

| Software component           | Region scope              |
|-----------------------------|---------------------------|
| front12                      | per region (AKS)          |
| backend12                    | per region (AKS)          |
| MatrixV2 frontend/processor  | per region (AKS)          |
| Apache Pulsar cluster        | per region                |
| Azure Blob Storage account   | per region                |
| Azure Traffic Manager        | global + per-geography    |
| APIM / Apigee                | global (TomTom gateway)   |
| Jenkins CI                   | shared (dev subscription) |

---

## Quality and Performance Characteristics

- **High availability:** EU and US each have two regions, so Traffic Manager can fail over within the geography if one region goes unhealthy — without rerouting traffic across continents.
- **Data residency:** Geographic DNS routing keeps EU-bound requests on EU infrastructure in normal operation.
- **Scalability:** backend12 autoscales horizontally on AKS — pod count scales with Pulsar queue depth.
- **Result durability:** Blob Storage retains completed batch results independently of application pods, so clients can download results after a pod restart.
- **Observability:** [Grafana](https://grafana.com/docs/grafana/latest/) dashboards are at [https://grafana.prod.batch.tt4.nl](https://grafana.prod.batch.tt4.nl) (Batch metrics) and [https://grafana.api-system.tomtom.com](https://grafana.api-system.tomtom.com) (APIM). Logs are centralised in [Grafana Cloud Logs](https://grafana.tomtomgroup.com).
