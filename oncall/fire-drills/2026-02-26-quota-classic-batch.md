# Fire Drill: Quota Management - Classic Batch

**Date:** 2026-02-26
**Source:** [Confluence page 1582629509](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1582629509)

## Scenario

Quota management drill for Classic Batch (Batch v1/v2). The drill covers understanding and monitoring QPS (Queries Per Second) limits and quota usage across the Batch & Matrix platform, including:

- **1.2 QPS scope:**
  - QPS to Batch & Matrix itself — number of possible calls to submission and download endpoints
  - QPS to calculateRoute / reverseGeocode / geocode / search / etc. — processing speed

## Participants

Limited content at time of documentation. See recording for participant details.

**Recording:** [SharePoint video](https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQCBaVCAXwZYSIaXwJDCJ3TRAWHRyvYgKcAep5Do_59RD7Q)

## Steps Performed

### Quota Usage Monitoring

**Front2 → Client usage**

- Dashboard: [Client Usage (all keys)](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=now-30m&to=now&var-datasource=thanos-query&var-location=All&var-basename=All&var-cluster_name=All&var-batch_version=All&var-percentile=0.95&orgId=1)

**Backend2 → Quota usage**

- Dashboard (Batch 1/2): [Quota Usage - Batch 1&2](https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2?from=now-30m&to=now&var-cluster_name=All&orgId=1)
- Dashboard (Matrix v2): [Quota Usage - Matrix v2](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2?from=now-30m&to=now&var-cluster_name=All&orgId=1)

### Example Investigation

Example [Grafana](https://grafana.com) URL used during the drill (scoped to a specific customer token and time window):

```
https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage?from=2026-02-26T09:26:00.371Z&to=2026-02-26T09:30:39.136Z&timezone=UTC&var-cluster_name=$__all&var-customerToken=901a5973-a71f-4ea1-bd02-9745efe2a7fc&var-subCustomerId=$__all&var-groupBy=customerToken&orgId=1&var-datasource=thanos-query&var-location=$__all&var-basename=$__all&var-batch_version=12&var-apiKey=PpKE...LLjq&var-internal=$__all&var-percentile=0.95&var-adhoc=&viewPanel=panel-12
```

### Reference Pages

- [Confluence: Page 1308262582](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1308262582)
- [Confluence: Page 233915849](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849)
- [Confluence: Page 287900086](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086)

## Issues Encountered

Limited content at time of documentation.

## Lessons Learned

Limited content at time of documentation. See recording for detailed discussion.

## Action Items

Limited content at time of documentation.
