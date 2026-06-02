# Fire Drill: Gloo Error Responses

## Scenario

Two [PagerDuty](https://www.pagerduty.com/) alerts fired within ~24 hours of each other (May 22 and May 23, 2025) related to [Gloo Gateway](https://docs.solo.io/gateway/latest/) error responses affecting production traffic. The fire drill is based on the real incidents and covers how to identify, investigate, and respond to Gloo error response spikes.

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQBL8ex7oLs8SJ_T3StYDUl1AZWSpNjBoanFh-sK9GXNiFo

PagerDuty team services: https://tomtom.pagerduty.com/teams/P9MED0E#services

## Participants

- Adrian Pedziwiatr (recording author)
- Michal Slonina (note: working on KAAP, no related codebase changes)

## Steps Performed

### Incident 1 - May 22 at 4:25 PM

1. PagerDuty alert fired: https://tomtom.pagerduty.com/incidents/Q106UQW9SY27LC
2. NOC pinged about the problem at `May 22 at 6:12 PM`: https://tomtom.pagerduty.com/incidents/Q01IJ4GG3F9L0P
3. Slack discussion: https://tomtomslack.slack.com/archives/CAZJP939P/p1747929762152669
4. Investigated [Gloo Gateway](https://docs.solo.io/gateway/latest/) dashboard in [Grafana](https://grafana.com/):
   - Gloo graph: https://grafana.tomtomgroup.com/d/eeffytafzka9sd/gateway-gloo?orgId=1&from=2025-05-22T13:30:00.000Z&to=2025-05-22T15:30:00.000Z&timezone=browser&var-env=prod&var-logs_search=&refresh=1m
   - Gloo/proxies graph (MatrixRoutingV2): https://grafana.tomtomgroup.com/d/fdx2e4glv1qmws/gateway-gloo-proxies?orgId=1&from=2025-05-22T13:30:00.000Z&to=2025-05-22T15:30:00.000Z&timezone=browser&var-env=prod&var-logs_search=&refresh=1m&var-proxy=MatrixRoutingV2&var-product=$__all
5. Referenced Gloo error responses documentation: https://tomtom.atlassian.net/wiki/spaces/APIM/pages/506692276

### Incident 2 - May 23 at 3:39 PM

1. PagerDuty alert fired: https://tomtom.pagerduty.com/incidents/Q02SW9RTXOD4P5
2. Slack thread: https://tomtomslack.slack.com/archives/CAZJP939P/p1748008065038679
3. Same [Gloo Gateway](https://docs.solo.io/gateway/latest/) issue identified; investigated using:
   - Gloo gateway panel-64 (live view): https://grafana.tomtomgroup.com/d/eeffytafzka9sd/gateway-gloo?orgId=1&from=now-1h&to=now&timezone=browser&var-env=prod&refresh=1m&var-logs_search=&viewPanel=panel-64

### Access Verification Actions

Check [StatusCake](https://www.statuscake.com/) and [AlertSite](https://www.alertsite.com/) accesses to ensure on-call readiness:

- **[StatusCake](https://www.statuscake.com/)**: https://app.statuscake.com/YourStatus2.php
  - You should have alerts for: routing, batch, matrix, waypoints
- **[AlertSite](https://www.alertsite.com/)**: https://www.alertsite.com/sso/saml/a948bf4894450b2ec26fd11af059e0a8f7735247
  - You should have alerts for:
    - `Prod_generic_MatrixRoutingV2-ApiTomtom-1step`
    - `Prod_generic_MatrixRoutingV2-ApiAzure-1step`

## Issues Encountered

- [Gloo Gateway](https://docs.solo.io/gateway/latest/) error response spikes occurred on two consecutive days (May 22 and May 23), suggesting a recurring or unresolved root cause.
- NOC escalation on May 22 came roughly 1 h 45 m after the initial alert, indicating delayed detection or slow routing.

## Lessons Learned

- [Gloo Gateway](https://docs.solo.io/gateway/latest/) error response spikes can affect the MatrixRoutingV2 proxy and should be checked via both the general Gloo dashboard and the per-proxy (Gloo Proxies) dashboard in [Grafana](https://grafana.com/).
- On-call engineers should verify access to [StatusCake](https://www.statuscake.com/) and [AlertSite](https://www.alertsite.com/) before their shift begins to ensure alert visibility.
- The Gloo error responses documentation (https://tomtom.atlassian.net/wiki/spaces/APIM/pages/506692276) should be reviewed as part of on-call preparation.

## Action Items

- [ ] Verify [StatusCake](https://www.statuscake.com/) access includes routing, batch, matrix, and waypoints alerts before each on-call rotation.
- [ ] Verify [AlertSite](https://www.alertsite.com/) access includes `Prod_generic_MatrixRoutingV2-ApiTomtom-1step` and `Prod_generic_MatrixRoutingV2-ApiAzure-1step`.
- [ ] Review [Gloo Gateway](https://docs.solo.io/gateway/latest/) error responses runbook: https://tomtom.atlassian.net/wiki/spaces/APIM/pages/506692276
- [ ] Investigate whether root cause of May 22 / May 23 incidents was fully resolved to prevent recurrence.
