# Fire Drill: No Healthy Upstream

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQCZ6TIU7a0NTZZ4EIwo50kCAcHce4oQRrTNQEHG65-fhrE

## Scenario

The "no healthy upstream" issue occurs when the APIM Gateway cannot route requests to any healthy backend instance. The service returns HTTP 503 with body `no healthy upstream`. This is a transient APIM-level error that can affect Batch & Matrix services globally or per region.

Sample [PagerDuty](https://www.pagerduty.com/) incidents:
- https://tomtom.pagerduty.com/incidents/Q2N776DQO37EZE
- https://tomtom.pagerduty.com/incidents/Q0LB22RPU6RSP0

Sample [StatusCake](https://www.statuscake.com/) alert:
- https://app.statuscake.com/UptimeStatus.php?tid=6206720

## Participants

(Not recorded in source page.)

## Steps Performed

### How to recognize the problem

- Response status code: **503**
- Response body: **no healthy upstream**

### Impact analysis

#### Check on BMW side

- BMW [Grafana](https://grafana.com/) -> Front2 -> Status codes:
  https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes?from=now-30m&to=now&var-cluster_name=All&orgId=1
- BMW Grafana -> Components2 -> Health indicators:
  https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-http_codes=.%2A&var-percentile=0.95&orgId=1

#### Check on APIM side

[Loki](https://grafana.com/oss/loki/) queries to EU database:

**Number of affected requests:**

```
sum(count_over_time({owner="api-gateway@groups.tomtom.com", k8s_namespace_name="gloo-mesh-gateways"}
| environment="prod" | source="gateway" | resp_detail="no_healthy_upstream" [$__auto]))by(upstream_cluster)
```

Grafana link: https://grafana.tomtomgroup.com/goto/4iaYyDUNR?orgId=1

**Returned status codes:**

```
sum(count_over_time({owner="api-gateway@groups.tomtom.com", k8s_namespace_name="gloo-mesh-gateways"}
| environment="prod" | source="gateway" | upstream_cluster=~".*batch.*" [$__auto]))by(cloud_region,product_id,resp_code)
```

Grafana link: https://grafana.tomtomgroup.com/goto/0aEsyD8NR?orgId=1

### Sample response to NOC

> PagerDuty incident: https://tomtom.pagerduty.com/incidents/Q2N776DQO37EZE
>
> StatusCake test failed with the following details:
> - response body: no healthy upstream
> - response code: 503
>
> **Impact (example 1):**
> Batch&Matrix v1 services (Batch Search, Batch Routing, Matrix Routing v1) via Korean domain
> (kr-api.tomtom.com, kr-api.azure.tomtom.com).
> These services do not have active (=producing load) kr users; during the alert only traffic from
> blackbox monitoring was observed.
>
> **Impact (example 2):**
> - Impacted service: Matrix Routing v2
> - Problem visible for 1 minute; estimated global error rate at that timeframe (based on APIM logs): 0.3%
>
> **Analysis:**
> The service was working properly at the time of the alert. No issues visible based on internal health metrics.
> The error was returned at the APIM Gateway level.
> "No healthy upstream" is a previously seen issue. A bug ticket is open for investigation:
> https://tomtom.atlassian.net/browse/APIM-3230

## Issues Encountered

- The error originates at the APIM Gateway level, not within the Batch/Matrix services themselves.
- Can affect specific regional domains (e.g. Korean domain) without any active user traffic — only blackbox monitoring triggers the alert.
- Transient in nature: in one observed case the problem lasted approximately 1 minute with ~0.3% global error rate.

## Lessons Learned

- Internal health metrics may show no issues even when the APIM Gateway is returning 503 for a service — always cross-check at the APIM/Loki level.
- Regional domains with no active users will still generate PagerDuty alerts via blackbox monitoring; assess impact accordingly before escalating.
- The APIM team has an open bug ticket (APIM-3230) for root cause investigation; reference it in NOC responses to avoid duplicate work.

## Action Items

- APIM bug ticket to track and resolve root cause: https://tomtom.atlassian.net/browse/APIM-3230
- When this alert fires, use the Loki queries above to quantify the real user impact before escalating.
- Consider adding runbook link to PagerDuty alert description for faster on-call response.
