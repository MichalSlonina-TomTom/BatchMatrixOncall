# Azure Traffic Manager — Disabling/Enabling a Region Runbook

Source: [Confluence — Disabling a region in Traffic Manager](https://tomtom.atlassian.net/wiki/spaces/~233897990/pages/233927941)

---

## When to Use

Use this runbook when a specific Azure region serving Batch/Matrix traffic must be taken out of rotation. Common triggers:

- A region has elevated error rates or latency that is impacting end users.
- Planned maintenance on region-specific infrastructure (e.g., [Kubernetes](https://kubernetes.io/docs/home/) cluster upgrade, node pool drain).
- A deployment rollout requires traffic to be drained before proceeding.
- An incident requires isolating a region to limit the blast radius.

Do **not** disable a region as a first reflex. Confirm the problem is region-specific and that disabling will improve overall service health before proceeding.

---

## Prerequisites

**PIM access (Azure portal)**

Elevated [Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview) permissions are required to modify [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/traffic-manager-overview) profiles. Activate your role via [PIM (Privileged Identity Management)](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) before starting:

- Follow the [Request PIM](https://tomtom.atlassian.net/wiki/spaces/~233897990/pages/233902249) runbook to activate your role.
- Outside business hours: follow the [Out-of-hours PIM](https://tomtom.atlassian.net/wiki/spaces/~233897990/pages/233902278) runbook.
- If a second approver is needed: follow [Approving PIM](https://tomtom.atlassian.net/wiki/spaces/~233897990/pages/233902272).

**Repository access (for script-based approach)**

- Clone or have a local copy of the `batch-service2-infra` GitHub repo (tomtom-internal org).
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/) (`az`) authenticated to the TomTom tenant.

**Critical rule before you start**

Only modify **submission** Traffic Manager profiles. **Never disable download profiles** without an explicit, deliberate reason. Disabling download profiles prevents clients from retrieving completed batch results — causing outage beyond new submission traffic.

---

## Procedure: Disabling a Region

### Option A — Script (preferred)

1. Navigate to the cloned `batch-service2-infra` repository.
2. Change into the `scripts/maintenance` directory.
3. Run the script with no arguments to see usage help:
   ```bash
   ./disable-region.sh
   ```
4. Run with the appropriate arguments:
   ```bash
   ./disable-region.sh <ENVIRONMENT> <REGION> --includeBatch12 --includeBatch13 --includeWaypoints
   ```
   Example — disable `westeurope` in production:
   ```bash
   ./disable-region.sh prod westeurope --includeBatch12 --includeBatch13 --includeWaypoints
   ```
   Supported environments: `prod`. Supported regions: `westeurope`, `northeurope`, `westus2`, `eastus`, `koreacentral`.

   If the script fails or behaves unexpectedly, fall back to Option B and verify Traffic Manager profile state manually.

### Option B — Azure Portal (manual fallback)

**Step 1 — Identify which profiles to modify**

Each region maps to two geographies: `global` and its physical geography. Modify **all** submission profiles for both geographies.

| Region | Geographies | Submission profiles to modify |
|---|---|---|
| westeurope | global, eu | `global-prod-submission12`, `global-prod-submission13`, `eu-prod-submission12`, `eu-prod-submission13` |
| northeurope | global, eu | same as westeurope |
| westus2 | global, us | `global-prod-submission12`, `global-prod-submission13`, `us-prod-submission12`, `us-prod-submission13` |
| eastus | global, us | same as westus2 |
| koreacentral | global, kr | `global-prod-submission12`, `global-prod-submission13`, `kr-prod-submission12`, `kr-prod-submission13` |

All profiles live in the [batch-traffic-manager-prd](https://portal.azure.com/#@TomTomInternational.onmicrosoft.com/resource/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/resourceGroups/batch-traffic-manager-prd/overview) resource group.

**Step 2 — Disable the endpoint in each profile**

Repeat for every profile identified in Step 1:

1. Open the Traffic Manager profile in the Azure portal.
2. Go to **Endpoints** in the left menu.
3. Find the endpoint named after the region abbreviation (e.g., `we` for `westeurope`).
4. Click the endpoint, change its **Status** to **Disabled**, and save.

Complete all relevant submission profiles before moving to verification.

---

## Verification

After running the script or completing manual steps:

1. **Azure portal** — Confirm each modified endpoint shows **Disabled** status in the Traffic Manager profile overview.
2. **[Grafana](https://grafana.com/docs/grafana/latest/) (Batch)** — Check [https://grafana.prod.batch.tt4.nl](https://grafana.prod.batch.tt4.nl) for a drop in request volume from the disabled region. Allow 30–90 seconds for Azure Traffic Manager to propagate the DNS TTL change.
3. **Grafana (APIM)** — Check [https://grafana.api-system.tomtom.com](https://grafana.api-system.tomtom.com) to confirm no new traffic is reaching the disabled region's endpoints.
4. **Grafana Cloud Logs** — Search [https://grafana.tomtomgroup.com](https://grafana.tomtomgroup.com) for the disabled region's host/pod logs; incoming request volume should fall to zero for new submissions.
5. **Functional check** — Submit a test batch request and confirm it routes to one of the remaining active regions (check the response or logs for the handling region).

Traffic Manager uses DNS-based routing. Existing long-lived connections or clients that aggressively cache DNS may take up to the DNS TTL (typically 30–60 s) to failover.

---

## Re-enabling a Region

### Option A — Script (preferred)

1. Navigate to `batch-service2-infra/scripts/maintenance`.
2. Run with no arguments to see usage:
   ```bash
   ./test-and-enable-region.sh
   ```
3. Run with arguments:
   ```bash
   ./test-and-enable-region.sh <ENVIRONMENT> <REGION> --includeBatch12 --includeBatch13 --includeWaypoints
   ```
   Example — re-enable `westeurope` in production:
   ```bash
   ./test-and-enable-region.sh prod westeurope --includeBatch12 --includeBatch13 --includeWaypoints
   ```
   The script tests region health before re-enabling. If the test fails, the endpoint is not re-enabled — investigate the region health before retrying.

### Option B — Azure Portal (manual fallback)

Follow the same steps as disabling (Option B above), but set each endpoint **Status** to **Enabled** instead of **Disabled**. Process all submission profiles that were previously disabled.

After re-enabling, repeat the Verification steps above to confirm traffic is flowing to the region again.

---

## Impact Assessment

| Scenario | Impact |
|---|---|
| Disabling one EU region (e.g., westeurope) | Remaining EU region (northeurope) absorbs EU and global traffic. Monitor for capacity saturation. |
| Disabling both EU regions simultaneously | All global and EU traffic falls to US or Korea regions. High capacity risk — alert the team before doing this. |
| Disabling a download profile (AVOID) | Clients with in-flight or completed jobs cannot retrieve results. Causes customer-facing errors unrelated to submission health. |
| DNS TTL lag after disabling | Some clients continue hitting the disabled region for up to 60 s. Region should still return errors or timeouts if the underlying service is unhealthy. |

After disabling a region, monitor the remaining active regions for CPU, memory, and queue depth spikes. If a surviving region becomes overloaded from absorbed traffic, escalate to the on-call team lead immediately.
