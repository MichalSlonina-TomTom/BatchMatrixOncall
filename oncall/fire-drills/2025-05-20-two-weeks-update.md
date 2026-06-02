# Fire Drill: Two-Week Update

## Scenario

Two-week on-call update session covering recent [PagerDuty](https://www.pagerduty.com/) incidents and related code changes across batch-service2 repositories.

## Participants

Recording available at:
https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQDhDdsPUIU9SajusUTaEcplAeS1ohs-pBOccOE5mvUvTMk

## Steps Performed

Review of recent PagerDuty incidents for the team (PagerDuty team: https://tomtom.pagerduty.com/teams/P9MED0E#services):

- **2025-05-06** — https://tomtom.pagerduty.com/incidents/Q2H9YZX34M6NUH
  APIM did some manual requests via [Gloo](https://www.solo.io/products/gloo-gateway/); production traffic was not affected.
  Slack thread: https://tomtomslack.slack.com/archives/C02FX0X7M1P/p1746536153576489

- **2025-05-07** — https://tomtom.pagerduty.com/incidents/Q2XUFZMNFVEJHK
  Manual requests to TM, but our own.

- **2025-05-08** — https://tomtom.pagerduty.com/incidents/Q1KLDR3JOBJSIY
  Broken authorization on APIM side, whole TomTom is down.
  Slack thread: https://tomtomslack.slack.com/archives/CAZJP939P/p1746710539633729

Review of related pull requests and releases:

**batch-service2** (https://github.com/tomtom-internal/batch-service2):
- https://github.com/tomtom-internal/batch-service2/pull/920
- https://github.com/tomtom-internal/batch-service2/pull/919
- https://github.com/tomtom-internal/batch-service2/pull/930

**batch-service2-1.2** (https://github.com/tomtom-internal/batch-service2-1.2):
- https://github.com/tomtom-internal/batch-service2-1.2/pull/506
- https://github.com/tomtom-internal/batch-service2-1.2/pull/510

**batch-service2-infra** (https://github.com/tomtom-internal/batch-service2-infra):
- https://github.com/tomtom-internal/batch-service2-infra/pull/561
- Releases: https://github.com/tomtom-internal/batch-service2-infra/blob/master/RELEASES.md

## Issues Encountered

- **2025-05-06**: APIM made manual requests via Gloo; production traffic was not affected.
- **2025-05-07**: Manual requests to TM originating from our own team.
- **2025-05-08**: Broken authorization on APIM side causing a full TomTom-wide outage.

## Lessons Learned

Limited content at time of documentation. Refer to the session recording and linked PagerDuty incidents for detailed discussion notes.

## Action Items

Limited content at time of documentation. Review the linked pull requests for follow-up work identified during the session:
- https://github.com/tomtom-internal/batch-service2/pull/920
- https://github.com/tomtom-internal/batch-service2/pull/919
- https://github.com/tomtom-internal/batch-service2/pull/930
- https://github.com/tomtom-internal/batch-service2-1.2/pull/506
- https://github.com/tomtom-internal/batch-service2-1.2/pull/510
- https://github.com/tomtom-internal/batch-service2-infra/pull/561
