# Fire Drill: Unhealthy Download, HAProxy Status Codes

**Date:** 2025-07-29
**Confluence source:** https://tomtom.atlassian.net/wiki/spaces/~pageId=731225141

## Scenario

Matrix "download" service was unhealthy. [HAProxy](https://www.haproxy.org/) was masking 5xx errors — no 5xx codes appeared in the [Grafana](https://grafana.com/) status code graph, but 5xx responses were present in logs. The drill investigated why 5xx errors were not visible in Grafana and how to detect real impact in such cases.

## Participants

- Adrian Pędziwiatr
- Michał Słonina
- Simon
- Adam
- Milan
- Giannis

## Steps Performed

1. Received [PagerDuty](https://www.pagerduty.com/) alert: https://tomtom.pagerduty.com/incidents/Q16Q7DPQ4U13YR
2. Checked [StatusCake](https://www.statuscake.com/) for alert details (routing, batch, matrix, waypoints alerts visible at https://app.statuscake.com/YourStatus2.php).
3. Checked [AlertSite](https://www.alertsite.com/) for `Prod_generic_MatrixRoutingV2-ApiTomtom-1step` and `Prod_generic_MatrixRoutingV2-ApiAzure-1step` alerts at https://www.alertsite.com/sso/saml/a948bf4894450b2ec26fd11af059e0a8f7735247.
4. Reviewed status code graph in Grafana — no 5xx recorded: https://grafana.prod.batch.tt4.nl/goto/NgVTwpwNg?orgId=1
5. Checked storage issues graph: https://grafana.prod.batch.tt4.nl/goto/EDXoQtQHR?orgId=1
6. Checked matrix "download" health status: https://grafana.prod.batch.tt4.nl/goto/3CEJwtQNg?orgId=1
7. Cross-checked with [Loki](https://grafana.com/oss/loki/) logs — 5xx responses were present in logs despite not showing in metrics: https://grafana.tomtomgroup.com/goto/2fzCQpQNR?orgId=1
8. Reviewed HAProxy failover diagram to understand why 5xx errors were hidden: https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/healthcheks-haproxy-failover.drawio.png

## Issues Encountered

- **HAProxy masking 5xx errors:** When the "download" service is unhealthy, HAProxy fails over to another upstream. The status code metrics graph reflects the final response served to the client (which may be 2xx from the failover upstream), hiding the underlying 5xx errors from the unhealthy node. This means Grafana status code graphs cannot be relied upon as the sole indicator of impact.
- **AlertSite access gaps:** Adam, Milan, and Giannis had AlertSite accounts but lacked access to Matrix V2 alerts at the time of the drill (tracked in SPSRE-3427: https://tomtom.atlassian.net/browse/SPSRE-3427).

## Lessons Learned

- Do not rely solely on the HAProxy-level status code graph to assess impact when an upstream is unhealthy. HAProxy failover can suppress 5xx metrics even when errors are occurring.
- Loki logs are the authoritative source for detecting real 5xx responses in HAProxy failover scenarios.
- Ready-to-use Loki queries are needed to quickly find impact in cases where HAProxy masks errors.

## Action Items

- [ ] Prepare ready-to-use Loki queries that find client impact in cases where HAProxy failover masks 5xx status codes.
- [ ] Ensure all oncall participants (Adam, Milan, Giannis) have access to Matrix V2 alerts in AlertSite (ref: SPSRE-3427).

## Recording

- https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQA08A0Q4E_7R5EePxxojigFAUShwDFZuOG-4VlLSMgMCZk
