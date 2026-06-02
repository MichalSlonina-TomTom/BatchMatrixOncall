# Fire Drill: New Oncall - This Is Happening Now

## Scenario

Fire drill session for new on-call engineers, conducted on 2025-05-06. Participants were walked through the key tools, dashboards, and runbooks used during a real on-call incident response.

## Participants

Not explicitly listed on the Confluence page.

## Steps Performed

### 1. Access Prerequisites

- **Jumphost / PIM**: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902100
- **VPN** is required (!!)

### 2. Log Access

**Scalyr:**
- EU: https://app.eu.scalyr.com/events?teamToken=hUUcDsKzE9CckPrAEhpHgQ--
- US: https://app.scalyr.com/events?teamToken=Rk1PkhX3KH4BeKkUAolxrQ--

**[Loki](https://grafana.com/oss/loki/) (via [Grafana](https://grafana.com)):**
- US: https://grafana.tomtomgroup.com/goto/qOuM-YbHg?orgId=1
- EU: https://grafana.tomtomgroup.com/goto/_A2naLbNg?orgId=1

### 3. Client Identification (APIM Utils)

- Developer account overview: https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview
- Search by API key / developer ID / app ID / email / SSO ID / EA ID / SAP customer ID: https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id?orgId=1

### 4. Batch/Matrix Grafana Dashboards

Base URL: https://grafana.prod.batch.tt4.nl/

**Quota Usage** (`[Backend2 → Quota usage]` / `[Front2 → Client usage]`):
- Batch 1/2: https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?from=now-30m&to=now&var-cluster_name=All&orgId=1
- Matrix v2: https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-30m&to=now&var-cluster_name=All&orgId=1
- Client usage: https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-percentile=0.95&orgId=1

**Status Codes** (`[Front2 → Status codes]` / `[Kubernetes → Ingress haproxy]`):
- Status codes: https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes?from=now-30m&to=now&var-cluster_name=All&orgId=1
- Status codes per client: https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client?from=now-30m&to=now&var-cluster_name=All&orgId=1
- Kubernetes Ingress HAProxy: https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-percentile=0.95&var-apiKey=&var-customerToken=All&orgId=1

**Executor** (`[Backend2 → Executor]`):
- Executor Batch 1/2: https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch12-1/executor-batch1-2?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-apiKey=All&var-customerToken=All&var-subCustomerId=All&var-internal=All&var-percentile=0.95&orgId=1
- Executor Batch 1/3: https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch13-1/executor-batch1-3?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-apiKey=All&var-customerToken=All&var-subCustomerId=All&var-internal=All&var-percentile=0.95&orgId=1

**Health Indicators** (`[Components2 → Health indicators]` = `[Front2 → Front health indicators]` + `[Backend2 → Backend health indicators]`):
- Health indicators: https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators?from=now-30m&to=now&var-cluster_name=All&var-customerToken=All&var-subCustomerId=All&var-groupBy=customerToken&orgId=1
- Front health indicators: https://grafana.prod.batch.tt4.nl/d/batch2-front-health-indicators-1/front-health-indicators?from=now-30m&to=now&var-cluster_name=All&var-customerToken=All&var-subCustomerId=All&var-groupBy=customerToken&orgId=1
- Backend health indicators: https://grafana.prod.batch.tt4.nl/d/batch2-backend-health-indicators-1/backend-health-indicators?from=now-30m&to=now&var-cluster_name=All&var-customerToken=All&var-subCustomerId=All&var-groupBy=customerToken&orgId=1

### 5. CI / Release & Rollout Jobs

Base URL: https://ci.dev.batch.tt4.nl/

- Release job: https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch_Release/view/Simple_Batch_release/
  - List of past releases: https://github.com/tomtom-internal/batch-service2-infra/blob/master/RELEASES.md
- Rollout batch pods: https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/
- Rollout Pulsar pods: https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/

## Issues Encountered

Not documented on the Confluence page.

## Lessons Learned

Not documented on the Confluence page.

## Action Items

Not documented on the Confluence page.

## Recordings

- https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQDQVmRtutDqRpVHeya-nUVXAc9rqKQ4K-hx_4KojQeJlU4
