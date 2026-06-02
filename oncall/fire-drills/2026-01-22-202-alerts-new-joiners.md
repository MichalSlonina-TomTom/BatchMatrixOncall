# Fire Drill: 202 Alerts, New Joiners

Source: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1409089954
Date: 2026-01-22

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQAkMAqJg1dcT7cTU-MM8TKQAeWBpM2vFRyLJdmJjv_SBhw

## Scenario

Alert: `[FIRING:1] front12 - downloads - Many customers got 202 Batch & Matrix alerts`

Alert description:

```
At least 30% of batch1.2 customers get 202 codes on download endpoints.
The state lasts for at least 5 minutes.
Http code 202 does not indicate an error, but when many customers receive them, you should check that the system works properly.
On the alert dashboard, next to the alert, you will find a graph showing which customers get this status code.
```

Background: [HTTP 202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202) on the Asynchronous Batch Download endpoint means the batch response is not yet ready before the timeout. The client receives HTTP 202, the batch request is accepted for processing, and the client downloads batch results from the URL specified by the Location header. This is not necessarily an error, but when many customers receive it, it requires verification.

Reference: https://developer.tomtom.com/batch-search-api/documentation/product-information/introduction

```
When a client calls the Asynchronous Batch Download endpoint the possible scenarios are:

    Batch response is calculated before timeout (by default this is 120 seconds it can be changed by using the waitTimeSeconds parameter).
        The client receives HTTP 200.
        Batch response is ready and it gets streamed to the client.
    Batch response is not ready before timeout.
        The client receives HTTP 202.
        Batch request is accepted for processing.
        The client downloads batch results from the URL specified by the Location header (see point 3).
```

## Participants

Limited content at time of documentation.

## Steps Performed

### Incident 1 — [PagerDuty](https://www.pagerduty.com/) Q1YAUSRZYCZW6X

PagerDuty: https://tomtom.pagerduty.com/incidents/Q1YAUSRZYCZW6X

[Grafana](https://grafana.com/) dashboard (status codes alerts):
https://grafana.prod.batch.tt4.nl/d/alert-statuscodes-1/status-codes-alerts?from=2026-01-19T12:11:30.000Z&orgId=1&to=2026-01-19T13:12:02.531Z&timezone=UTC&var-location=$__all&var-basename=$__all&var-cluster_name=$__all&var-batch_version=$__all&var-customerToken=$__all&var-subCustomerId=$__all&var-internal=$__all

Finding: one client, multiple API keys.

### Incident 2 — PagerDuty Q1HOBFUU5E47JL

PagerDuty: https://tomtom.pagerduty.com/incidents/Q1HOBFUU5E47JL

Grafana dashboard (status codes alerts):
https://grafana.prod.batch.tt4.nl/d/alert-statuscodes-1/status-codes-alerts?from=2026-01-20T13:45:30.000Z&orgId=1&to=2026-01-20T14:46:02.528Z&timezone=UTC&var-location=$__all&var-basename=$__all&var-cluster_name=$__all&var-batch_version=$__all&var-customerToken=$__all&var-subCustomerId=$__all&var-internal=$__all

Finding: one client, one API key, northeurope region.

## Issues Encountered

- A single client can trigger the alert even when there is no major incident, e.g. because it does most of its traffic in a small region.
- In the "one client, multiple API keys" case, we are not currently aware that multiple keys belong to the same developer, making it harder to correctly assess the alert.
- Comparison to routing: similar in nature to `UserErrorRateTooHigh` in routing — not necessarily a major incident, but requires verification.

## Lessons Learned

- HTTP 202 alerts indicate something that is not necessarily a major incident, but require verification to be sure.
- The northeurope single-client case has been observed once. More investigation could be done, but was not prioritized.
- The "one client, multiple API keys" case has been seen more than once and is more actionable.

## Action Items

- [ ] northeurope case: possible improvement, but only observed once — no immediate action taken.
- [ ] one client, multiple API keys case: requested developer-identity information to correlate API keys to the same developer.
  - PR for APIM gateway config: https://github.com/tomtom-internal/apim-gw-config/pull/924
  - Once that information is available, the alert logic can be improved to account for multiple keys belonging to the same developer.

---

## New Joiners Onboarding Notes

Goal: get a general sense of the services covered by the on-call rotation — not to read everything in detail or memorize it right away.

### Initial Tasks

- Run some test requests against the services covered by the on-call rotation.
- Read up on service quota management and understand why requests are processed more slowly or more quickly in different scenarios.
- Review the architecture and flow diagrams to get a better understanding of how these services work.

### Services in the On-Call Rotation

**batch1.2** — repo: https://github.com/tomtom-internal/batch-service2-1.2
- Batch Search API: https://developer.tomtom.com/batch-search-api/documentation/product-information/introduction
- Batch Routing API: https://developer.tomtom.com/routing-api/documentation/tomtom-maps/batch-routing/batch-routing-service

**batch1.3** — repo: https://github.com/tomtom-internal/batch-service2
- Matrix v2: https://developer.tomtom.com/matrix-routing-v2-api/documentation/product-information/introduction

**waypoints** — repo: https://github.com/tomtom-internal/routing-waypoint-optimization
- Waypoint Optimization: https://developer.tomtom.com/waypoint-optimization/documentation/waypoint-optimization-service

### Key Terminology

- batch 1.2 / classic batch / classic Batch&Matrix = Batch Search, Batch Routing, Matrix Routing v1
  - Uses client key; processing speed controlled by QPS to routing APIs and search APIs.
- batch 1.3 / large matrix = Matrix Routing v2
  - Uses `calculateMultipleRoutes` (private implementation details); processing speed controlled by `maxParallelPerSeconds`.

### Sample Requests

https://github.com/tomtom-internal/batch-service2-testing-tools/tree/master/test-data

### Quota Management Documentation

- https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/1308262582
- https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849
- https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086

### Architecture Diagrams

- https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/architecture-overall/batch1.2-architecture.drawio.png
- https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/architecture-overall/matrixv2-async-architecture.drawio.png
- https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/architecture-overall/matrixv2-sync-architecture.drawio.png

### Flow / Interaction Diagrams

- https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/integrations-batch12/batch1.2-max-qps-sequence-diagram.drawio.png
- https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/integrations-matrixv2/matrixv2-interactions.drawio.png

### Glossary

https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/glossary.md

### Full Documentation

- https://github.com/tomtom-internal/batch-service2-infra/tree/master/docs
- https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233910010
- https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/507809433

### Useful Links

- Grafana (dev): https://grafana.dev.batch.tt4.nl/
- Logs ([Loki](https://grafana.com/oss/loki/)): https://grafana.tomtomgroup.com/a/grafana-lokiexplore-app/explore/service/batch-matrix-waypoint/logs?patterns=%5B%5D&from=now-15m&to=now&var-lineFormat=&var-ds=de3q4p49ry2gwf&var-filters=service_name%7C%3D%7Cbatch-matrix-waypoint&var-fields=&var-levels=&var-metadata=&var-jsonFields=&var-patterns=&var-lineFilterV2=&var-lineFilters=&timezone=browser&var-all-fields=&displayedFields=%5B%5D&urlColumns=%5B%5D&visualizationType=%22logs%22&prettifyLogMessage=false&sortOrder=%22Ascending%22&wrapLogMessage=false
- [Azure](https://azure.microsoft.com/) dev subscription: https://portal.azure.com/#@TomTomInternational.onmicrosoft.com/resource/subscriptions/9b2c1b4c-3f07-4721-951e-1b6b28654863/overview
  - Test deployment: ms1-dev-westeurope
  - Message broker: [Apache Pulsar](https://pulsar.apache.org/) 57-dev-westeurope
  - Monitoring: monitoring 100-dev-westeurope
