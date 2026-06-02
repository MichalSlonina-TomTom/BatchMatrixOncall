# Matrix Routing v2 API Key — Emergency Procedures

Matrix Routing v2 uses one central API key (`calculateMultipleRoutes` API key) shared across all sync and async requests. This runbook covers two emergency scenarios: the key hits its quota limit, or the key stops working and must be replaced.

Source: [Confluence — Matrix v2 API key emergency procedures](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832)

---

## Scenarios

| Scenario | Trigger | Action |
|---|---|---|
| Quota exhaustion | Alert "1.3 Underlying Service QPS Throttles" fires (>5 quota exceeded / 203 / 429 errors within 1 min) | Switch to higher-quota backup key or add keys in round-robin |
| Key no longer working | Requests fail with auth errors; key may have been revoked | Replace with any other available key |

**Alert location:** [Common Alerts dashboard](https://grafana.prod.batch.tt4.nl/d/common-alerts-1/common-alerts?orgId=1) — alert "1.3 Underlying Service QPS Throttles", connected to [PagerDuty](https://support.pagerduty.com/main/docs/introduction).

---

## Prerequisites

- Access to the jumphost. See [Accessing jumphost & break-glass](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902281).
- [Azure PIM](https://learn.microsoft.com/en-us/azure/role-based-access-control/pim-azure-resource) roles activated via [Azure Portal RBAC](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ActivationMenuBlade/azurerbac):
  - `Virtual Machine Administrator Login`
  - `Azure Kubernetes Service Cluster User Role` ([AKS docs](https://learn.microsoft.com/en-us/azure/aks/overview))
- A team colleague (or NOC via `#noc-pim-request` Slack) to approve PIM activation.
- All API keys belong to account `batch_matrix_waypoint_team@groups.tomtom.com` on the [TomTom Developer Portal](https://developer.tomtom.com/). In an emergency, reset the account password.

### Available API Keys (prod)

| Developer App name | Quota (QPS) | Status |
|---|---|---|
| `largeMatrixAsyncProd` | 10 000 | **Current PROD key** |
| `largeMatrixAsyncProdBackup` | 3 500 | Backup |
| `largeMatrixSyncProd` | 1 700 | Backup |
| `largeMatrixSyncProdBackup` | 1 700 | Backup |
| `Matrix v2 with increased QPS` | 10 000 | Use for quota increase |

Note: the "sync"/"async" in key names is historical — there is no functional distinction. The `api-key.value` field in `backend13-config` accepts a comma-separated list to distribute load across multiple keys in round-robin.

Find the actual key values in [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/overview):
- Resource group: `key-vaults-prod`
- Key vault: `tomtom-batch2-prod`
- Secret: `batch13-api-key`

To browse the vault manually, configure access first — see the [no-Jenkins docs](https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/production/batch/release-procedure-no-jenkins-and-jumphost.md#get-access-to-the-production-environment).

---

## Procedure: Increasing Quota

### Step 1 — Verify the problem

Check current QPS usage:
- [Batch&Matrix Grafana — Quota Usage Matrix v2](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?orgId=1) — "Global quota usage" section.
- [APIM — Call volume vs quota breaches](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches) (filter by `largeMatrixAsyncProd`).

### Step 2 — Contact stakeholders

1. **Inform Routing on-call** before generating more load — contact via `#noc-general` Slack and agree on the new quota level.
2. **Inform NOC** about the ongoing customer impact via `#noc-general`.

### Step 3 — Reconfigure the configmap (per region)

Apply the key change **in every prod region** separately.

1. Request PIM roles (see Prerequisites) and get approval.
2. Log in to the jumphost.
3. Set the [Kubernetes](https://kubernetes.io/docs/home/) context for the target region:
   ```bash
   az aks get-credentials --subscription "NAV Routing/Search Batch - prod" \
     -n aks10-prod-westeurope -g aks10-prod-westeurope --overwrite-existing
   ```
   Replace `aks10-prod-westeurope` with the correct region cluster name.

4. Edit the configmap using [`kubectl`](https://kubernetes.io/docs/reference/kubectl/):
   ```bash
   kubectl edit cm backend13-config
   ```

5. To use the high-quota backup key, update the `api-key.value` field:
   ```yaml
   api-key:
     value: <key for "Matrix v2 with increased QPS">
   ```

   To use multiple keys in round-robin (additive quota):
   ```yaml
   api-key:
     value: apiKey1,apiKey2
   ```

6. Save and exit. The change takes effect within minutes. Verify in app logs:
   ```
   c.t.lns.batch.backend.ApiKeyProperties   : Successfully reloaded (1) apikey values.
   ```

7. **Repeat steps 3–6 for every remaining prod region.**

### Alternative: Ask APIM team to raise quota

Contact NOC via `#noc-general` to escalate to the APIM team for an emergency quota increase on the existing key. This avoids a key swap but takes longer.

---

## Procedure: Replacing the Key

Follow the same configmap edit procedure as above (Steps 1, 3–7 in "Increasing Quota"), substituting any working key from the table in the Prerequisites section.

```yaml
api-key:
  value: <replacement key value>
```

Repeat for every prod region.

---

## Verification

After each region change:

1. Watch app logs for the reload confirmation:
   ```
   Successfully reloaded (1) apikey values.
   ```
2. Check the [Quota Usage Matrix v2 dashboard](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?orgId=1) — quota breach rate should drop.
3. Check the [APIM Call volume vs quota breaches dashboard](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches) — 429 errors should stop.
4. Confirm the "1.3 Underlying Service QPS Throttles" alert resolves in PagerDuty / Grafana.

---

## Rollback

If the new key causes problems, edit the configmap again to revert:

```bash
kubectl edit cm backend13-config
```

Restore the original value:
```yaml
api-key:
  value: <original key>
```

Repeat for each prod region. Verify as above.

---

## Post-Action (next business day)

If the key in the configmap now differs from what is stored in Key Vault, update the vault before the next release. Otherwise the next deployment will revert the change.

1. Request `Contributor` role via Azure PIM.
2. In resource group `key-vaults-prod`, navigate to `tomtom-batch2-prod` > Secrets.
3. Create a new version of secret `batch13-api-key` with the value currently in use (including comma-separated multi-key strings where applicable).
