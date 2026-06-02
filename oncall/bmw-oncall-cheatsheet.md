# BMW On-call Cheatsheet

> Source: Confluence page [BMW on-call cheatsheet \[BETA ALPHA\]](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1436319806) — last updated 2026-04-10, version 16.

---

## Access

**Request PIM (Azure RBAC):**
<https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/azurerbac>

**Jumphost:**
```
batch-service2-infra/jumphost$ ./jumphost-login.sh prod
```

---

## Blackbox Monitoring

- **StatusCake:** <https://app.statuscake.com/YourStatus2.php>
  - You should have routing, batch, matrix, waypoints alerts
- **AlertSite:** <https://www.alertsite.com/sso/saml/a948bf4894450b2ec26fd11af059e0a8f7735247>
  - You should have `Prod_generic_MatrixRoutingV2-ApiTomtom-1step` and `Prod_generic_MatrixRoutingV2-ApiAzure-1step` alerts

---

## Client Identification

- [Developer Account Overview](https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview)
- [Search for Developer App by API key / developer ID / app ID / email / SSO ID / EA ID / SAP customer ID](https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id?orgId=1)

---

## [Grafana](https://grafana.com/)

**Main dashboard:** <https://grafana.prod.batch.tt4.nl/>

### Health Indicators

| Dashboard | Link |
|-----------|------|
| **[Components2 → Health indicators]** | [Health indicators](https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators?from=now-30m&to=now&var-cluster_name=All&var-customerToken=All&var-subCustomerId=All&var-groupBy=customerToken&orgId=1) |
| **[Front2 → Front health indicators]** | [Front health indicators](https://grafana.prod.batch.tt4.nl/d/batch2-front-health-indicators-1/front-health-indicators?from=now-30m&to=now&var-cluster_name=All&var-customerToken=All&var-subCustomerId=All&var-groupBy=customerToken&orgId=1) |
| **[Backend2 → Backend health indicators]** | [Backend health indicators](https://grafana.prod.batch.tt4.nl/d/batch2-backend-health-indicators-1/backend-health-indicators?from=now-30m&to=now&var-cluster_name=All&var-customerToken=All&var-subCustomerId=All&var-groupBy=customerToken&orgId=1) |

### Status Codes

| Dashboard | Link |
|-----------|------|
| **[Front2 → Status codes]** | [Status codes](https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes?from=now-30m&to=now&var-cluster_name=All&orgId=1) |
| **[Front2 → Status codes per client]** | [Status codes per client](https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client?from=now-30m&to=now&var-cluster_name=All&orgId=1) |
| **[Kubernetes → Ingress haproxy]** | [Kubernetes Ingress HAProxy](https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-percentile=0.95&var-apiKey=&var-customerToken=All&orgId=1) |

### Quota Usage

| Dashboard | Link |
|-----------|------|
| **[Front2 → Client usage]** | [Client usage](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-percentile=0.95&orgId=1) |
| **[Backend2 → Quota usage Batch 1/2]** | [Quota usage Batch 1-2](https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?from=now-30m&to=now&var-cluster_name=All&orgId=1) |
| **[Backend2 → Quota usage Matrix v2]** | [Quota usage Matrix v2](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-30m&to=now&var-cluster_name=All&orgId=1) |

### Executor

| Dashboard | Link |
|-----------|------|
| **[Backend2 → Executor Batch1-2]** | [Executor Batch1-2](https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch12-1/executor-batch1-2?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-apiKey=All&var-customerToken=All&var-subCustomerId=All&var-internal=All&var-percentile=0.95&orgId=1) |
| **[Backend2 → Executor Batch1-3]** | [Executor Batch1-3](https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch13-1/executor-batch1-3?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-apiKey=All&var-customerToken=All&var-subCustomerId=All&var-internal=All&var-percentile=0.95&orgId=1) |

---

## [Loki](https://grafana.com/oss/loki/)

### Ingress Logs

- **EU:** [Grafana Loki EU — ingress](https://grafana.tomtomgroup.com/a/grafana-lokiexplore-app/explore/service/batch-matrix-waypoint/logs?from=now-15m&to=now&var-ds=de3q4p49ry2gwf&var-filters=service_name%7C%3D%7Cbatch-matrix-waypoint&var-filters=deployment_environment%7C%3D%7Cprod&var-filters=k8s_deployment_name%7C%3D%7Cingress-haproxy-ingress-controller&var-filters=k8s_container_name%7C%3D%7Caccess-logs&patterns=%5B%5D&var-lineFormat=&var-fields=&var-levels=&var-metadata=&var-jsonFields=&var-patterns=&var-lineFilterV2=&var-lineFilters=&timezone=browser&var-all-fields=&userDisplayedFields=false&displayedFields=%5B%5D&urlColumns=%5B%5D&visualizationType=%22logs%22&prettifyLogMessage=false&sortOrder=%22Ascending%22&wrapLogMessage=false)
- **US:** [Grafana Loki US — ingress](https://grafana.tomtomgroup.com/a/grafana-lokiexplore-app/explore/service/batch-matrix-waypoint/logs?from=now-15m&to=now&var-ds=ae0cnl9k3qrcwa&var-filters=service_name%7C%3D%7Cbatch-matrix-waypoint&var-filters=deployment_environment%7C%3D%7Cprod&var-filters=k8s_deployment_name%7C%3D%7Cingress-haproxy-ingress-controller&var-filters=k8s_container_name%7C%3D%7Caccess-logs&patterns=%5B%5D&var-lineFormat=&var-fields=&var-levels=&var-metadata=&var-jsonFields=&var-patterns=&var-lineFilterV2=&var-lineFilters=&timezone=browser&var-all-fields=&userDisplayedFields=false&displayedFields=%5B%5D&urlColumns=%5B%5D&visualizationType=%22logs%22&prettifyLogMessage=false&sortOrder=%22Ascending%22&wrapLogMessage=false)

### Query: Status Codes per Customer

- **EU:** [Grafana Loki EU — status codes per customer](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%229oi%22%3A%7B%22datasource%22%3A%22de3q4p49ry2gwf%22%2C%22queries%22%3A%5B%7B%22refId%22%3A%22logs%22%2C%22expr%22%3A%22sum%28label_replace%28sum%28count_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22%2C+deployment_environment%3D%5C%22prod%5C%22%2C+k8s_deployment_name%3D%5C%22ingress-haproxy-ingress-controller%5C%22%2C+k8s_container_name%3D%5C%22access-logs%5C%22%7D+%7C+json+%7C+logfmt+%7C+drop+__error__%2C+__error_details__+%7C+haproxy_backend_name+%21%3D%5C%22%5C%22+%7C+haproxy_backend_name%21%3D%5C%22monitoring_prometheus-server_9090%5C%22+%7C+haproxy_request_path%21%7E%5C%22%2Factuator%2Fhealth.*%5C%22%5B%24__auto%5D%29%29+by+%28haproxy_request_path%2C+customerToken%2C+haproxy_response_status_code%29%2C+%5C%22service%5C%22%2C+%5C%22%2F%241%2F%242%2F%243%5C%22%2C+%5C%22haproxy_request_path%5C%22%2C+%5C%22%2F%28%5B%5E%2F%5D%2B%29%2F%28%5B%5E%2F%5D%2B%29%2F%28%5B%5E%2F.%5D%2B%29.*%5C%22%29%29+by+%28service%2C+customerToken%2C+haproxy_response_status_code%29%22%2C%22datasource%22%3A%7B%22type%22%3A%22loki%22%2C%22uid%22%3A%22de3q4p49ry2gwf%22%7D%2C%22editorMode%22%3A%22code%22%2C%22queryType%22%3A%22instant%22%2C%22direction%22%3A%22backward%22%7D%5D%2C%22range%22%3A%7B%22from%22%3A%22now-15m%22%2C%22to%22%3A%22now%22%7D%2C%22panelsState%22%3A%7B%22logs%22%3A%7B%22visualisationType%22%3A%22logs%22%7D%7D%2C%22compact%22%3Afalse%7D%7D&orgId=1)
- **US:** Change database to `grafanacloud-tomtomnvotlpus-hostedlogs`

### Query: Matrix v2 E2E Processing Time

- **EU:** [Grafana Loki EU — matrix v2 e2e processing time](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22%3A%7B%22datasource%22%3A%22de3q4p49ry2gwf%22%2C%22queries%22%3A%5B%7B%22refId%22%3A%22logs%22%2C%22expr%22%3A%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22%7D+%7C%3D+%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22+%7C+json+%7C+drop+__error__%2C+__error_details__+%7C+unwrap+processingTimeDetails_e2eProcessingTime%5B%24__auto%5D%29+by%28customerToken%29%22%2C%22datasource%22%3A%7B%22type%22%3A%22loki%22%2C%22uid%22%3A%22de3q4p49ry2gwf%22%7D%2C%22editorMode%22%3A%22code%22%2C%22queryType%22%3A%22range%22%2C%22direction%22%3A%22backward%22%7D%5D%2C%22range%22%3A%7B%22from%22%3A%22now-15m%22%2C%22to%22%3A%22now%22%7D%2C%22panelsState%22%3A%7B%22logs%22%3A%7B%22visualisationType%22%3A%22logs%22%7D%7D%2C%22compact%22%3Afalse%7D%7D&orgId=1)
- **US:** Change database to `grafanacloud-tomtomnvotlpus-hostedlogs`

---

## Quotas / Processing Speed / Timeout / Latency Spike

Reference pages:
- <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1308262582>
- <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849>
- <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086>

### Actions

#### Rollout Pods

- [Rollout restart batch cluster prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/)
- [Rollout restart Pulsar cluster prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/)

#### Disable Region

- <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233927941>

#### Update Internal API Keys

- <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832>

#### Rollback

1. Check recent releases: <https://github.com/tomtom-internal/batch-service2-infra/blob/master/RELEASES.md>
2. Go to Jenkins: **Batch → Prod → Batch_Release → Simple_Batch_release**
   - <https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch_Release/view/Simple_Batch_release/>
3. Enter the INFRA_BRANCH value into the `RELEASE_CANDIDATE_BRANCH` field.
4. Check `PANIC_MODE` — you probably want to speed up deployment a bit.
5. Wait for the job result (~30 min).

---

## Customers — Matrix Routing v2

### BOLT Matrix v2 sync

- **Contact:** [sso-19845@bolt.eu](mailto:sso-19845@bolt.eu) — Geo Matrix Live
- **Developer app ID:** `d496da47-e3f3-47e1-8243-7e889de2e8c5`
- **API key:** `M4lx...5YRW`
- [APIM grafana — app overview](https://grafana.api-system.tomtom.com/d/ON7yjypZz2/f09f948e-developer-app-overview?orgId=1&var-developerappname=Geo%20Matrix%20Live%20-%20%28sso-19845@bolt.eu%29&var-Interval=$__auto&from=now-7d%2Fd&to=now&timezone=utc&var-logging=1)
- [APIM grafana — call volumes](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&from=now-24h&to=now&var-developerappname=Geo%20Matrix%20Live%20-%20(sso-19845@bolt.eu)&var-environment=prod&var-apiproduct=Matrix%20Routing%20v2%20API&var-apiproxy=MatrixRoutingV2&var-ratelimiterQuotaName=d496...ngV2&var-method=routing%20matrix%202&var-consistent_structured=false&var-rate_limiter_quota_name=d496...ngV2&var-child_apiproductname=&timezone=utc&var-logging=1&var-dev_app_id=d496da47-e3f3-47e1-8243-7e889de2e8c5&var-apiproductname=MatrixRoutingV2&var-child_product=)
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=d496da47-e3f3-47e1-8243-7e889de2e8c5&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=d496da47-e3f3-47e1-8243-7e889de2e8c5&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=d496da47-e3f3-47e1-8243-7e889de2e8c5&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22d496da47-e3f3-47e1-8243-7e889de2e8c5%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D,%22panelsState%22:%7B%22logs%22:%7B%22visualisationType%22:%22logs%22%7D%7D,%22compact%22:false%7D%7D&orgId=1)

---

### MSFT Matrix v2 — All API Keys

- [Batch grafana — quota usage (all MSFT tokens)](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=fc5e270f-5596-4f60-a0c4-3c3c6860ee7b&var-customerToken=508c84c6-b306-495a-95ff-ca930c88d62d&var-customerToken=53778a9f-04ef-40e7-82f6-092df1bbf950&var-customerToken=ad79376a-3ab6-472f-9c03-1172ef258a83&var-customerToken=040a34bd-cd41-42f9-8ac3-23dda62420cb&var-customerToken=5ca02eb7-9fb1-40af-b5f4-ea30c232ba73&var-customerToken=ad32099e-ab9c-4670-b804-2916bc2760c7&var-customerToken=1009d32d-a957-4e00-8d41-92bf9e4cac71&var-customerToken=f0ce84cb-93e5-40b3-ae85-5be0a76f7f7e&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — data mix usage — graph (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22nzj%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22cost_per_route%22,%22expr%22:%22sum%20by%20%28%29%20%28%5Cn%20%20sum_over_time%28%5Cn%20%20%20%20%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,%5Cn%20%20%20%20%20k8s_deployment_name%3D%5C%22backend13-deployment%5C%22,%5Cn%20%20%20%20%20deployment_environment%3D%5C%22prod%5C%22,%5Cn%20%20%20%20%20k8s_container_name%3D%5C%22backend%5C%22%7D%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%5Cn%20%20%20%20%20%20%7C~%20%5C%22fc5e270f-5596-4f60-a0c4-3c3c6860ee7b%7C508c84c6-b306-495a-95ff-ca930c88d62d%7C53778a9f-04ef-40e7-82f6-092df1bbf950%7Cad79376a-3ab6-472f-9c03-1172ef258a83%7C040a34bd-cd41-42f9-8ac3-23dda62420cb%7C5ca02eb7-9fb1-40af-b5f4-ea30c232ba73%7Cad32099e-ab9c-4670-b804-2916bc2760c7%7C1009d32d-a957-4e00-8d41-92bf9e4cac71%7Cf0ce84cb-93e5-40b3-ae85-5be0a76f7f7e%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22sumOfProcessingTimes%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22totalNumberOfRoutes%5C%22%5Cn%20%20%20%20%20%20%7C%20json%5Cn%20%20%20%20%20%20%7C%20unwrap%20cmrCallsSummary_sumOfProcessingTimes%5Cn%20%20%5B$__interval%5D%29%5Cn%29%5Cn%2F%5Cnsum%20by%20%28%29%20%28%5Cn%20%20sum_over_time%28%5Cn%20%20%20%20%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,%5Cn%20%20%20%20%20k8s_deployment_name%3D%5C%22backend13-deployment%5C%22,%5Cn%20%20%20%20%20deployment_environment%3D%5C%22prod%5C%22,%5Cn%20%20%20%20%20k8s_container_name%3D%5C%22backend%5C%22%7D%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%5Cn%20%20%20%20%20%20%7C~%20%5C%22fc5e270f-5596-4f60-a0c4-3c3c6860ee7b%7C508c84c6-b306-495a-95ff-ca930c88d62d%7C53778a9f-04ef-40e7-82f6-092df1bbf950%7Cad79376a-3ab6-472f-9c03-1172ef258a83%7C040a34bd-cd41-42f9-8ac3-23dda62420cb%7C5ca02eb7-9fb1-40af-b5f4-ea30c232ba73%7Cad32099e-ab9c-4670-b804-2916bc2760c7%7C1009d32d-a957-4e00-8d41-92bf9e4cac71%7Cf0ce84cb-93e5-40b3-ae85-5be0a76f7f7e%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22sumOfProcessingTimes%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22totalNumberOfRoutes%5C%22%5Cn%20%20%20%20%20%20%7C%20json%5Cn%20%20%20%20%20%20%7C%20unwrap%20cmrCallsSummary_totalNumberOfRoutes%5Cn%20%20%5B$__interval%5D%29%5Cn%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22forward%22,%22step%22:%221h%22,%22hide%22:false,%22legendFormat%22:%22cost_per_route%22%7D%5D,%22range%22:%7B%22from%22:%22now-24h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)
- [Grafana Loki — data mix usage — table (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22nzj%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22cost_per_route%22,%22expr%22:%22sum%20by%20%28%29%20%28%5Cn%20%20sum_over_time%28%5Cn%20%20%20%20%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,%5Cn%20%20%20%20%20k8s_deployment_name%3D%5C%22backend13-deployment%5C%22,%5Cn%20%20%20%20%20deployment_environment%3D%5C%22prod%5C%22,%5Cn%20%20%20%20%20k8s_container_name%3D%5C%22backend%5C%22%7D%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%5Cn%20%20%20%20%20%20%7C~%20%5C%22fc5e270f-5596-4f60-a0c4-3c3c6860ee7b%7C508c84c6-b306-495a-95ff-ca930c88d62d%7C53778a9f-04ef-40e7-82f6-092df1bbf950%7Cad79376a-3ab6-472f-9c03-1172ef258a83%7C040a34bd-cd41-42f9-8ac3-23dda62420cb%7C5ca02eb7-9fb1-40af-b5f4-ea30c232ba73%7Cad32099e-ab9c-4670-b804-2916bc2760c7%7C1009d32d-a957-4e00-8d41-92bf9e4cac71%7Cf0ce84cb-93e5-40b3-ae85-5be0a76f7f7e%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22sumOfProcessingTimes%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22totalNumberOfRoutes%5C%22%5Cn%20%20%20%20%20%20%7C%20json%5Cn%20%20%20%20%20%20%7C%20unwrap%20cmrCallsSummary_sumOfProcessingTimes%5Cn%20%20%5B$__range%5D%29%5Cn%29%5Cn%2F%5Cnsum%20by%20%28%29%20%28%5Cn%20%20sum_over_time%28%5Cn%20%20%20%20%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,%5Cn%20%20%20%20%20k8s_deployment_name%3D%5C%22backend13-deployment%5C%22,%5Cn%20%20%20%20%20deployment_environment%3D%5C%22prod%5C%22,%5Cn%20%20%20%20%20k8s_container_name%3D%5C%22backend%5C%22%7D%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%5Cn%20%20%20%20%20%20%7C~%20%5C%22fc5e270f-5596-4f60-a0c4-3c3c6860ee7b%7C508c84c6-b306-495a-95ff-ca930c88d62d%7C53778a9f-04ef-40e7-82f6-092df1bbf950%7Cad79376a-3ab6-472f-9c03-1172ef258a83%7C040a34bd-cd41-42f9-8ac3-23dda62420cb%7C5ca02eb7-9fb1-40af-b5f4-ea30c232ba73%7Cad32099e-ab9c-4670-b804-2916bc2760c7%7C1009d32d-a957-4e00-8d41-92bf9e4cac71%7Cf0ce84cb-93e5-40b3-ae85-5be0a76f7f7e%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22sumOfProcessingTimes%5C%22%5Cn%20%20%20%20%20%20%7C%3D%20%5C%22totalNumberOfRoutes%5C%22%5Cn%20%20%20%20%20%20%7C%20json%5Cn%20%20%20%20%20%20%7C%20unwrap%20cmrCallsSummary_totalNumberOfRoutes%5Cn%20%20%5B$__range%5D%29%5Cn%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22instant%22%7D%5D,%22range%22:%7B%22from%22:%22now-24h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT BING Matrix v2 sync

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — Bing-Enterprise-Proxy-Routing-Sync
- **Developer app ID:** `508c84c6-b306-495a-95ff-ca930c88d62d`
- **API key:** `rL2T...Jm9b`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=508c84c6-b306-495a-95ff-ca930c88d62d&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=508c84c6-b306-495a-95ff-ca930c88d62d&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=508c84c6-b306-495a-95ff-ca930c88d62d&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22508c84c6-b306-495a-95ff-ca930c88d62d%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT BING Matrix v2 async

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — Bing-Enterprise-Proxy-Routing-Async
- **Developer app ID:** `f0ce84cb-93e5-40b3-ae85-5be0a76f7f7e`
- **API key:** `HC8H...rqAQ`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=f0ce84cb-93e5-40b3-ae85-5be0a76f7f7e&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=f0ce84cb-93e5-40b3-ae85-5be0a76f7f7e&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=f0ce84cb-93e5-40b3-ae85-5be0a76f7f7e&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%220ce84cb-93e5-40b3-ae85-5be0a76f7f7e%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT Azure Maps (NAM) sync

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_NAM_Sync_transition
- **Developer app ID:** `53778a9f-04ef-40e7-82f6-092df1bbf950`
- **API key:** `ATQ3...G1g9`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=53778a9f-04ef-40e7-82f6-092df1bbf950&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=53778a9f-04ef-40e7-82f6-092df1bbf950&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=53778a9f-04ef-40e7-82f6-092df1bbf950&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%2253778a9f-04ef-40e7-82f6-092df1bbf950%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT Azure Maps (NAM) Matrix v2 async

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_NAM_Async_transition
- **Developer app ID:** `040a34bd-cd41-42f9-8ac3-23dda62420cb`
- **API key:** `wsmB...GNTE`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=040a34bd-cd41-42f9-8ac3-23dda62420cb&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=040a34bd-cd41-42f9-8ac3-23dda62420cb&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=040a34bd-cd41-42f9-8ac3-23dda62420cb&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22040a34bd-cd41-42f9-8ac3-23dda62420cb%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT Azure Maps (RTB) Matrix v2 sync

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_RTB_Sync_transition
- **Developer app ID:** `ad32099e-ab9c-4670-b804-2916bc2760c7`
- **API key:** `dGvq...tOHr`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=ad32099e-ab9c-4670-b804-2916bc2760c7&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=ad32099e-ab9c-4670-b804-2916bc2760c7&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=ad32099e-ab9c-4670-b804-2916bc2760c7&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22ad32099e-ab9c-4670-b804-2916bc2760c7%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT Azure Maps (RTB) Matrix v2 async

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_RTB_Async_transition
- **Developer app ID:** `5ca02eb7-9fb1-40af-b5f4-ea30c232ba73`
- **API key:** `yfDz8...HV5P`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=5ca02eb7-9fb1-40af-b5f4-ea30c232ba73&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=5ca02eb7-9fb1-40af-b5f4-ea30c232ba73&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=5ca02eb7-9fb1-40af-b5f4-ea30c232ba73&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%225ca02eb7-9fb1-40af-b5f4-ea30c232ba73%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT Azure Maps (RTB KOR) Matrix v2 sync

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_KOR_RTB_Sync_transition
- **Developer app ID:** `ad79376a-3ab6-472f-9c03-1172ef258a83`
- **API key:** `EKZg...J1io`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=ad79376a-3ab6-472f-9c03-1172ef258a83&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=ad79376a-3ab6-472f-9c03-1172ef258a83&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=ad79376a-3ab6-472f-9c03-1172ef258a83&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22ad79376a-3ab6-472f-9c03-1172ef258a83%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### MSFT Azure Maps (RTB KOR) Matrix v2 async

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_KOR_RTB_Async_transition
- **Developer app ID:** `fc5e270f-5596-4f60-a0c4-3c3c6860ee7b`
- **API key:** `LDKE...58W`
- [Batch grafana — submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=fc5e270f-5596-4f60-a0c4-3c3c6860ee7b&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Batch grafana — items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=fc5e270f-5596-4f60-a0c4-3c3c6860ee7b&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Batch grafana — quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=fc5e270f-5596-4f60-a0c4-3c3c6860ee7b&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Grafana Loki — e2e processing time (EU)](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22fc5e270f-5596-4f60-a0c4-3c3c6860ee7b%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

---

## Customers — Batch & Matrix 1.2

### MSFT Azure Maps Batch Search Async

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_SEB_Async
- **Developer app ID:** `901a5973-a71f-4ea1-bd02-9745efe2a7fc`
- **API key:** `PpKE...LLjq`
- [APIM app overview](https://grafana.api-system.tomtom.com/d/ON7yjypZz2/developer-app-overview-wip?orgId=1&var-developerappname=AzM_Prod_SEB_Async%20-%20%28andrea.stucchi@tomtom.com%29)
- [Submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=$__all&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=12&var-apiKey=PpKE...LLjq&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-7)
- [Items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=901a5973-a71f-4ea1-bd02-9745efe2a7fc&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=12&var-apiKey=PpKE...LLjq&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-12)
- [Quota usage](https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?orgId=1&from=now-30m&to=now&timezone=UTC&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-cluster_name=$__all&var-percentile=0.95&var-adhoc=&var-apiKey=PpKE...LLjq&var-customerToken=901a5973-a71f-4ea1-bd02-9745efe2a7fc)
- [Batch Search call volume APIM — batch](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&from=now-3h&to=now&var-developerappname=AzM_Prod_SEB_Async%20-%20%28andrea.stucchi@tomtom.com%29&var-environment=prod&var-apiproduct=Online%20Search%20Batch%20Azure&var-apiproxy=OnlineSearchBatch&var-ratelimiterQuotaName=901a...zure&var-method=search%202%20batch&var-consistent_structured=false&var-rate_limiter_quota_name=901a...zure&var-child_apiproductname=&timezone=utc&var-logging=1&var-dev_app_id=901a5973-a71f-4ea1-bd02-9745efe2a7fc&var-apiproductname=OnlineSearchBatchAzure&var-child_product=)
- [Batch Search call volume APIM — search](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&from=now-3h&to=now&var-developerappname=AzM_Prod_SEB_Async%20-%20%28andrea.stucchi@tomtom.com%29&var-environment=prod&var-apiproduct=Online%20Search%20Azure&var-apiproxy=OnlineSearchBatch&var-ratelimiterQuotaName=901a...zure&var-method=search%202%20geocode%20json&var-consistent_structured=false&var-rate_limiter_quota_name=901a...e-gc&var-child_apiproductname=&timezone=utc&var-logging=1&var-dev_app_id=901a5973-a71f-4ea1-bd02-9745efe2a7fc&var-apiproductname=Online%20Search%20Azure&var-child_product=)
- e2e processing time: (none)

### MSFT Azure Maps Batch Search Sync

- **Contact:** [andrea.stucchi@tomtom.com](mailto:andrea.stucchi@tomtom.com) — AzM_Prod_SEB_Sync
- **Developer app ID:** `9d6a6538-1ee2-4e54-b57e-ebd778ba3cc7`
- **API key:** `FtX4...LSdQ`
- [APIM app overview](https://grafana.api-system.tomtom.com/d/ON7yjypZz2/f09f948e-developer-app-overview?orgId=1&var-developerappname=AzM_Prod_SEB_Sync%20-%20%28andrea.stucchi@tomtom.com%29&var-Interval=$__auto&from=now-7d%2Fd&to=now&timezone=utc&var-logging=1)
- [Submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=$__all&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=12&var-apiKey=FtX4...LSdQ&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-7)
- [Items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=$__all&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=12&var-apiKey=FtX4...LSdQ&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-12)
- [Quota usage](https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?orgId=1&from=now-30m&to=now&timezone=UTC&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-cluster_name=$__all&var-percentile=0.95&var-adhoc=&var-apiKey=FtX4...LSdQ&var-customerToken=$__all)
- [Batch Search call volume APIM — batch](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&from=now-6h&to=now&var-developerappname=AzM_Prod_SEB_Sync%20-%20%28andrea.stucchi@tomtom.com%29&var-environment=prod&var-apiproduct=Online%20Search%20Batch%20Azure&var-apiproxy=OnlineSearch&var-ratelimiterQuotaName=9d6a...e-gc&var-method=search%202%20batch%20json&var-consistent_structured=false&var-rate_limiter_quota_name=9d6a...zure&var-child_apiproductname=&timezone=utc&var-logging=1&var-dev_app_id=9d6a6538-1ee2-4e54-b57e-ebd778ba3cc7&var-apiproductname=OnlineSearchBatchAzure&var-child_product=)
- [Batch Search call volume APIM — search](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&from=now-6h&to=now&var-developerappname=AzM_Prod_SEB_Sync%20-%20%28andrea.stucchi@tomtom.com%29&var-environment=prod&var-apiproduct=Online%20Search%20Azure&var-apiproxy=OnlineSearch&var-ratelimiterQuotaName=9d6a...e-gc&var-method=search%202%20geocode%20json&var-consistent_structured=false&var-rate_limiter_quota_name=9d6a...e-gc&var-child_apiproductname=&timezone=utc&var-logging=1&var-dev_app_id=9d6a6538-1ee2-4e54-b57e-ebd778ba3cc7&var-apiproductname=Online%20Search%20Azure&var-child_product=)
- [e2e processing time — Grafana Loki US](https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22pqf%22:%7B%22datasource%22:%22ae0cnl9k3qrcwa%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,%20k8s_deployment_name%3D%5C%22ingress-haproxy-ingress-controller%5C%22%7D%20%7C%3D%20%5C%229d6a6538-1ee2-4e54-b57e-ebd778ba3cc7%5C%22%20%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20haproxy_time_request_time_ms%20%5B$__auto%5D%29%20by%20%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22ae0cnl9k3qrcwa%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22forward%22%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)

### SAP

- **Contact:** [sapearthobservation@sap.com](mailto:sapearthobservation@sap.com) — OEM Key
- **Developer app ID:** `07cb58b1-c188-45d3-98f8-b55724459ac2`
- **API key:** `b0Tb...Hx5K`
- [APIM app overview](https://grafana.api-system.tomtom.com/d/ON7yjypZz2/f09f948e-developer-app-overview?from=now-24h&to=now&var-developerappname=OEM%20Key%20-%20%28sapearthobservation@sap.com%29&timezone=utc&var-Interval=$__auto&orgId=1&var-logging=1)
- [Submissions](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=07cb58b1-c188-45d3-98f8-b55724459ac2&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7)
- [Items submitted](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=07cb58b1-c188-45d3-98f8-b55724459ac2&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19)
- [Quota usage](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=07cb58b1-c188-45d3-98f8-b55724459ac2&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC)
- [Matrix v2 call volume APIM](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&var-developerappname=OEM%20Key%20-%20%28sapearthobservation@sap.com%29&var-dev_app_id=07cb58b1-c188-45d3-98f8-b55724459ac2&var-environment=prod&var-consistent_structured=False&var-apiproduct=Matrix%20Routing%20v2%20API&var-apiproductname=MatrixRoutingV2&var-child_product=&var-child_apiproductname=&var-method=routing%20matrix%202&var-rate_limiter_quota_name=07cb...ngV2&var-logging=%7B%22user_id%22:%2081,%20%22user_email%22:%20%22adrian.pedziwiatr@tomtom.com%22,%20%22dashboard%22:%20%22%F0%9F%93%88%20Call%20volume%20vs%20quota%20breaches%22,%20%22grafana_environment%22:%20%22PROD%22%7D&from=now-7d&to=now&timezone=utc)
- [Matrix v2 volume and latency APIM](https://grafana.api-system.tomtom.com/d/2Djkte8Zk/b003154?orgId=1&from=now-7d&to=now&var-appname=OEM%20Key%20-%20%28sapearthobservation@sap.com%29&var-apiproduct=Matrix%20Routing%20v2%20API&var-method=routing%20matrix%202&timezone=utc&var-region=$__all&var-logging=1)

### SNOONU

- **Contact:** (??)
- **Developer app ID:** (TBD)
- **API key:** (TBD)
- APIM app overview: (TBD)
- Submissions: (TBD)
- Items submitted: (TBD)
- Quota usage: (TBD)
- Matrix v2 call volume: (TBD)
- Matrix v2 volume and latency: (TBD)

---

## HTTP 5xx

### BMW Response Error Codes (UPPER_CASE)

```json
{
  "detailedError": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "..."
  }
}

{
  "detailedError": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "..."
  }
}
```

### APIM Gloo Error Codes (PascalCase)

Reference: <https://tomtom.atlassian.net/wiki/spaces/APIM/pages/506692276>

```json
{
  "detailedError": {
    "code": "InternalServerError",
    "message": "..."
  }
}

{
  "detailedError": {
    "code": "ServiceUnavailable",
    "message": "..."
  }
}
```

---

## Gloo Errors Dashboards

- [Gateway / Gloo — Errors](https://grafana.tomtomgroup.com/d/eeffytafzka9sd/gateway-gloo-errors?orgId=1&from=now-3h&to=now&timezone=browser&var-env=prod&var-logs_search=&refresh=1m&var-region=$__all)
- [Gateway / Gloo / Proxies — Errors](https://grafana.tomtomgroup.com/d/fdx2e4glv1qmws/gateway-gloo-proxies-errors?orgId=1&from=now-3h&to=now&timezone=browser&var-env=prod&var-logs_search=&refresh=1m&var-proxy=MatrixRoutingV2&var-product=$__all&var-Filters=)

---

## Friendly On-calls

- **APIM — Primary OnCall:** <https://tomtom.pagerduty.com/schedules/PNTSI2O>
- **APIM — Secondary OnCall:** <https://tomtom.pagerduty.com/schedules/PVT3E21>

---

## MSFT & "Timeouts" — Reply Template

> **Do not copy-paste blindly — check first!**

> Around XX:XX UTC, approximately XX million batch items were submitted.
> Batches are processed correctly, in submission order, processing speed (quota utilization) is as expected.
> Currently, the "issue" is not ongoing. Batches are processed on an ongoing basis.
> The system is processing them as designed and is operating correctly all the time.
>
> I consider the repeated reports about timeout/latency incorrect.
> There are no issues on the batch & matrix side.
> Please see the following for more info/context on timeout/latency spikes observed by MSFT on Batch Search/Batch Routing products:
>
> - <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1308262582>
> - <https://tomtomslack.slack.com/archives/CAZJP939P/p1769154102035129>
> - <https://tomtomslack.slack.com/archives/CAZJP939P/p1770358663702469>

---

## Tool References

External documentation for key technologies used in this runbook:

| Tool | Documentation |
|------|---------------|
| [Grafana](https://grafana.com/) | Metrics and log visualization platform |
| [Loki](https://grafana.com/oss/loki/) | Log aggregation system, queried via Grafana Explore |
| [Apache Pulsar](https://pulsar.apache.org/) | Distributed messaging and streaming platform |
| [PagerDuty](https://www.pagerduty.com/) | Incident management and on-call scheduling |
| [Kubernetes](https://kubernetes.io/) | Container orchestration platform |
| [HAProxy](https://www.haproxy.org/) | High-availability load balancer and proxy |
| [Jenkins](https://www.jenkins.io/) | CI/CD automation server used for rollouts and rollbacks |
| [Gloo Gateway](https://www.solo.io/products/gloo-gateway/) | API gateway (APIM layer, error codes in PascalCase) |
| [Thanos](https://thanos.io/) | Highly available Prometheus setup with long-term storage |
