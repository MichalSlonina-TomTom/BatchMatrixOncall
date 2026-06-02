# Fire Drill: Quota Management - Matrix Routing v2

## Scenario

Quota management for Matrix Routing v2. The drill covers two types of quotas under the 1.3 quotas model:

- **QPS to Matrix Routing v2 itself** - number of possible calls to submission, download, and status endpoints
- **Entitlement "maxParallelRequests"** - maximum number of CPU cores a client can consume in the Routing API

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQDA24bFDzTsRZXN6Zbyh8yNAR5-DfT3EgYMUwS4IGlpNLw

CMR (Calculate Multiple Routes) documentation: https://developer.tomtom.com/routing-api/documentation/tomtom-maps/private/calculate-multiple-routes

Reference page: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086

## Participants

Limited content at time of documentation.

## Steps Performed

### Quota Usage Dashboards

**Front2 - Client usage:**
- https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-percentile=0.95&orgId=1

**Backend2 - Quota usage:**
- https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?from=now-30m&to=now&var-cluster_name=All&orgId=1
- https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-30m&to=now&var-cluster_name=All&orgId=1

### Test Client: BOLT (sync) Matrix v2

Client: `sso-19845@bolt.eu` — Geo Matrix Live

- Developer App ID: `d496da47-e3f3-47e1-8243-7e889de2e8c5`
- API Key: `M4lx...5YRW`

**APIM App overview:**
https://grafana.api-system.tomtom.com/d/ON7yjypZz2/f09f948e-developer-app-overview?orgId=1&var-developerappname=Geo%20Matrix%20Live%20-%20%28sso-19845@bolt.eu%29&var-Interval=$__auto&from=now-7d%2Fd&to=now&timezone=utc&var-logging=1

**Submissions:**
https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-6h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=d496da47-e3f3-47e1-8243-7e889de2e8c5&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&editPanel=7

**Items submitted:**
https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-24h&to=now&timezone=UTC&var-cluster_name=$__all&var-customerToken=d496da47-e3f3-47e1-8243-7e889de2e8c5&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=13&var-apiKey=$__all&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-19

**Quota usage:**
https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-3h&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=$__all&var-percentile=0.95&var-apiKey=&var-customerToken=d496da47-e3f3-47e1-8243-7e889de2e8c5&orgId=1&var-subCustomerId=$__all&var-groupBy=customerToken&timezone=UTC

**Matrix v2 call volume (APIM):**
https://grafana.api-system.tomtom.com/d/DbsVGRfWk/f09f9388-call-volume-vs-quota-breaches?orgId=1&from=now-24h&to=now&var-developerappname=Geo%20Matrix%20Live%20-%20(sso-19845@bolt.eu)&var-environment=prod&var-apiproduct=Matrix%20Routing%20v2%20API&var-apiproxy=MatrixRoutingV2&var-ratelimiterQuotaName=d496...ngV2&var-method=routing%20matrix%202&var-consistent_structured=false&var-rate_limiter_quota_name=d496...ngV2&var-child_apiproductname=&timezone=utc&var-logging=1&var-dev_app_id=d496da47-e3f3-47e1-8243-7e889de2e8c5&var-apiproductname=MatrixRoutingV2&var-child_product=

**E2E processing time (Grafana Loki EU):**
https://grafana.tomtomgroup.com/explore?schemaVersion=1&panes=%7B%22s8g%22:%7B%22datasource%22:%22de3q4p49ry2gwf%22,%22queries%22:%5B%7B%22refId%22:%22logs%22,%22expr%22:%22avg_over_time%28%7Bservice_name%3D%5C%22batch-matrix-waypoint%5C%22,k8s_deployment_name%3D%5C%22backend13-deployment%5C%22%7D%20%7C%3D%20%5C%22c.t.l.b.backend.flow.ProcessingDetails%5C%22%20%7C%3D%20%5C%22d496da47-e3f3-47e1-8243-7e889de2e8c5%5C%22%20%7C%20json%20%7C%20drop%20__error__,%20__error_details__%20%7C%20unwrap%20processingTimeDetails_e2eProcessingTime%5B$__auto%5D%29%20by%28customerToken%29%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22de3q4p49ry2gwf%22%7D,%22editorMode%22:%22code%22,%22queryType%22:%22range%22,%22direction%22:%22backward%22%7D%5D,%22range%22:%7B%22from%22:%22now-3h%22,%22to%22:%22now%22%7D,%22panelsState%22:%7B%22logs%22:%7B%22visualisationType%22:%22logs%22%7D%7D,%22compact%22:false%7D%7D&orgId=1

## Issues Encountered

Limited content at time of documentation.

## Lessons Learned

Limited content at time of documentation.

## Action Items

Limited content at time of documentation.
