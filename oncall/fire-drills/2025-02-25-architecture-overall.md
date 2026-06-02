# Fire Drill: Architecture Overall

**Date:** 2025-02-25

## Scenario

Architecture review fire drill covering the overall Batch & Matrix system. The session walked through the system architecture and key integrations: [Apigee](https://cloud.google.com/apigee/docs), [Azure Traffic Manager](https://learn.microsoft.com/en-us/azure/traffic-manager/), the [Apache Pulsar](https://pulsar.apache.org/docs/) message queue, [Redis](https://redis.io/docs/), and [HAProxy](https://docs.haproxy.org/). A recording is available for reference.

## Participants

_Not recorded in the Confluence page._

## Steps Performed

The following resources were reviewed during the drill. Open each link to explore the relevant documentation or dashboard.

**Overall architecture:**
- Architecture diagrams: https://github.com/tomtom-internal/batch-service2-infra/tree/master/docs/diagrams/architecture-overall
- Apigee & Traffic Manager integration: https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/integration-with-apigee-trafficmanagers.md
- Azure Traffic Manager resource group (prod): https://portal.azure.com/#@TomTomInternational.onmicrosoft.com/resource/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/resourceGroups/batch-traffic-manager-prd/overview

**Pulsar:**
- Pulsar state alerts dashboard: https://grafana.prod.batch.tt4.nl/d/alert-pulsarstate-1/pulsar-state-alerts?from=now-30m&to=now&var-cluster_name=All&orgId=1

**Redis:**
- Redis high availability docs: https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/redis-high-availability.md
- Redis alerts dashboard: https://grafana.prod.batch.tt4.nl/d/redis-alerts-1/redis-alerts?orgId=1

**HAProxy:**
- HAProxy failover docs: https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/haproxy-failover.md

**Recording:** https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQDcS-kBM4XwQ6w6FcgtduTLAdb78s07_xf-dRWKFcemNvc

## Issues Encountered

_Not recorded in the Confluence page._

## Lessons Learned

_Not recorded in the Confluence page._

## Action Items

_Not recorded in the Confluence page._
