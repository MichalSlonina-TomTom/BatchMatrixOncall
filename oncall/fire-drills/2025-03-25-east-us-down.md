# Fire Drill: East US Was Down

**Date:** 2025-03-25

## Scenario

This drill simulated a full East US region outage. [PagerDuty](https://www.pagerduty.com/) fired [Redis](https://redis.io/docs/) alerts first, then StatusCake detected a broader outage. The drill covered how to assess impact across Batch & Matrix products and how to disable a failing region in [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/traffic-manager-overview).

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQAuYhDZnyl6RJfBRAb6UE0bAbBOuzirtnGhyoKgBMOxZxw

## Participants

Not listed explicitly on the Confluence page.

## Steps Performed

### 1. Initial Alerts

Three PagerDuty incidents triggered in sequence:

- Redis alerts fired first:
  - https://tomtom.pagerduty.com/incidents/Q2RCYCO9EN85R3
  - https://tomtom.pagerduty.com/incidents/Q2933TTCGL6H23
- StatusCake outage alert fired later:
  - https://tomtom.pagerduty.com/incidents/Q2WRUFWAF5QJDK

### 2. Impact Assessment

To assess impact:

- Check the main [Grafana](https://grafana.com/docs/grafana/latest/) dashboards: quota usage, status codes, executor, health indicators.
- Check logs in Scalyr & [Loki](https://grafana.com/docs/loki/latest/) for errors from classic batch/matrix/[Pulsar](https://pulsar.apache.org/docs/).
- Check graceful degradation via healthchecks:
  - Classic Batch & Matrix may be down while Matrix V2 still works.
  - Matrix V2 async may be down while sync still works.

Dashboards checked (all filtered to `eastus` region):

- **Redis alerts:** https://grafana.prod.batch.tt4.nl/d/redis-alerts-1/redis-alerts (filtered to `eastus`)
- **Status codes:** https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes (filtered to `eastus`)
- **Ingress [HAProxy](https://www.haproxy.org/) status codes:** https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy (filtered to `eastus`)
- **HAProxy connection stats:** same HAProxy dashboard, connections panel
- **Executor (batch12):** https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch12-1/executor-batch1-2
- **Executor (batch13):** https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch13-1/executor-batch1-3
- **Health indicators:** https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators

**Conclusion from dashboards:** All East US dashboards showed problems. Every dashboard either displays the region name or supports filtering by region.

### 3. Disable East US in Traffic Manager

Follow the runbook to turn off East US in Azure Traffic Manager:
https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233927941

### 4. Drain Nodes (Night Action)

Batch has **sticky regions**: jobs accepted in East US can only be computed there, and results are only available from that region. Because of this, the cluster was kept alive and fixed in place rather than simply disabled.

Steps taken:
1. Request [PIM (Privileged Identity Management)](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) access.
2. Log into the Jumphost.
3. Log into the East US [AKS](https://learn.microsoft.com/en-us/azure/aks/what-is-aks) cluster.
4. Drain all nodes one by one using `kubectl drain`: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_drain/

After draining, the health indicators dashboard returned to normal.

**Decision:** The region was NOT re-enabled that night because:
- The Azure Status page showed ongoing Azure issues in East US.
- Re-enabling a region that had just failed completely was considered too risky.

The situation was fully stabilized and the on-call engineer went to sleep.

### 5. Detailed Impact Analysis (Next Morning)

Deeper analysis the next morning revealed:

- **Status code errors affected only classic Batch & Matrix (batch12), not Matrix V2 (batch13).**
  - Dashboard (other regions for comparison): https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes (filtered to `westeurope`, `northeurope`, `westus2`, `koreacentral`)

- **HAProxy data for batch12 (`aks132-prod-eastus`):** Zero pods were alive. Traffic Manager correctly detected the problem and stopped routing traffic there, which reduced the number of surfaced errors.
  - Dashboard: https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy (filtered to `aks132-prod-eastus`)

- **batch13 (Matrix V2):** Reported healthy while actually returning many errors (confirmed by StatusCake). The healthcheck was incorrect.

- **[Apigee](https://docs.cloud.google.com/apigee/docs) (APIM) database analysis:** Status codes were also verified in [Azure Data Explorer](https://learn.microsoft.com/en-us/azure/data-explorer/data-explorer-overview):
  - Cluster: https://dataexplorer.azure.com/clusters/apianalyticsdashboard.westeurope/databases/ttapianalytics-westeu-db
  - Query used to compute error rate per 10-second bin across all Batch & Matrix products:

```kusto
Volume_Agg_1second
| where client_received_end_timestamp between (datetime(2025-03-18T23:25:00.000Z)..datetime(2025-03-18T23:55:00.000Z))
| where method_name in ("search 2 batch", "routing 1 batch", "routing 1 matrix", "routing matrix 2", "routing waypointoptimization 1")
| summarize error_rate=(
        (sum(client_5xx)+sum(client_408)+sum(client_429))*1.0/
        (sum(client_2xx)+sum(client_3xx)+sum(client_4xx)+sum(client_5xx))
    )*100
    by bin(client_received_end_timestamp, 10s)
| render linechart with  (ycolumns = error_rate, ymin=0, ymax = 100)
```

More details on findings from the Apigee database analysis in the RCA:
https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/550142097

## Issues Encountered

- **Matrix V2 (batch13) healthcheck was incorrect:** It reported healthy while failing with many errors. Traffic Manager did not detect the problem and kept routing traffic to the broken region.
- **Batch12 handled the outage better** because HAProxy correctly detected zero live pods and Traffic Manager removed it from rotation early.
- **Sticky regions complicate mitigation:** Disabling a region in Traffic Manager stops new traffic from reaching it, but jobs already accepted in East US can only be completed there. This narrowed the options for a quick recovery.

## Lessons Learned

- Filter **every Grafana dashboard by region** (`eastus` or the affected region) to confirm scope. Each dashboard either shows the region name or has a region filter variable.
- Check multiple dashboards in parallel: Redis alerts, status codes, HAProxy ingress, executor, health indicators.
- **Health indicator dashboards can give false positives** (batch13 reported healthy when it was not). Cross-check with status codes and HAProxy data.
- For Batch, draining/fixing a cluster is often better than disabling a region, especially for in-flight jobs held by sticky regions.
- Leaving a region disabled overnight is safe when Azure itself reports issues — re-enabling during an active Azure incident is risky.
- The Apigee/Azure Data Explorer query is useful for post-incident error rate analysis across all Batch & Matrix product APIs.

## Action Items

- Investigate why **Matrix V2 (batch13) healthcheck reported healthy** during a full East US outage. Traffic Manager uses this signal for routing — a false-healthy status causes continued error traffic. (Referenced in RCA: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/550142097)
