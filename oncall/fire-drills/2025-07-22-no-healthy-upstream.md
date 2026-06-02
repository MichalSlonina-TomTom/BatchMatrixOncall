# Fire Drill: No Healthy Upstream

## Scenario

The fire drill took place on 2025-07-22 and covered a `no_healthy_upstream` error that caused a brief outage on the MatrixV2 Async endpoint, as well as a related [Redis](https://redis.io) container restart alert and a `waypoints INTERNAL_SERVER_ERROR` issue that surfaced in the same period.

## Participants

Not explicitly listed on the Confluence page. Recording available at:
https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQC5iHb_hnV6SqZGP0W9tQANAWFs_e3_CUFx2AT8osO4Gog

## Steps Performed

### Incident 1: Redis container restarts alert

[PagerDuty](https://www.pagerduty.com): https://tomtom.pagerduty.com/incidents/Q03A6AN9QK73IU
Open: Jul 18, 2025 at 7:38 PM – 8:08 PM (30 minutes)

Alert: "redis (index 0) number of container restarts alert"

- **Oncall actions:**
  - Confirmed the situation was stable at the time of the alert.
  - Deferred deeper investigation to business hours.

- **Business hours follow-up:**
  - Identified that restarts were isolated to one cluster; one Redis instance was restarting with errors in the connection to the [Kubernetes](https://kubernetes.io) API.
  - [Grafana](https://grafana.com): https://grafana.tomtomgroup.com/goto/-CVvXuUHg?orgId=1
  - Mitigation: drained the affected node.

### Incident 2: no_healthy_upstream on MatrixV2 Async

PagerDuty: https://tomtom.pagerduty.com/incidents/Q1OTE52G9IY8H4
Open: Jul 19, 2025 at 5:44 AM – 5:45 AM (2 minutes)

Alert: "Website | Your site 'https://us-api.azure.tomtom.com/routing/matrix/2/async - MatrixV2 Async' went down"
Root cause: `no_healthy_upstream`

- Slack thread: https://tomtomslack.slack.com/archives/CAZJP939P/p1752896733966579
- Step-by-step runbook: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/710936386

### Incident 3: waypoints INTERNAL_SERVER_ERROR

- Slack thread: https://tomtomslack.slack.com/archives/CB62K05FB/p1752846375611999
- Details: see slack thread.

## Issues Encountered

- Redis restart errors caused by connectivity issues to the Kubernetes API in one cluster.
- `no_healthy_upstream` error caused a 2-minute downtime on the US MatrixV2 Async endpoint.
- `INTERNAL_SERVER_ERROR` observed in the waypoints service.

## Lessons Learned

- Limited retrospective notes recorded on the Confluence page. See the recording and linked Slack threads for full discussion.
- Redis Kubernetes API connectivity issues can cause cascading restarts; node drain was an effective mitigation.
- The `no_healthy_upstream` outage was short-lived (2 minutes), indicating the system recovered quickly once the issue was addressed.

## Action Items

- APIM-3230: https://tomtom.atlassian.net/browse/APIM-3230
- batch-service2-infra PR #593: https://github.com/tomtom-internal/batch-service2-infra/pull/593
- routing-waypoint-optimization PR #403 (waypoints INTERNAL_SERVER_ERROR fix): https://github.com/tomtom-internal/routing-waypoint-optimization/pull/403
- BMW release on 2025-07-22: released (included dependabot + waypoint logs change).
