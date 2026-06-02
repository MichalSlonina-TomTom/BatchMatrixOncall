# Fire Drill: AlertSite, StatusCake Issues; Grafana async/sync

**Date:** 2025-08-19
**Confluence page:** https://tomtom.atlassian.net/wiki/spaces/~pageId=759434147

**Recording:** https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQABH3zO2m7UQY_l-3jAGxnSAf_kXIUSZJzyqJ5URSdQluY

---

## Scenario

Three categories of alerts were exercised during this fire drill:

1. **[AlertSite](https://smartbear.com/product/alertsite/) alerts** - problems reported from one AlertSite region; tracking IDs not found in matrix logs; "read timed out" with response time 0s (likely a network issue on AlertSite's side).
2. **[StatusCake](https://www.statuscake.com/) alerts** - health down reported for multiple services; NOC was aware; multiple StatusCake emails triggered; multiple [PagerDuty](https://www.pagerduty.com/) incidents related to "korea went down".
3. **[Grafana](https://grafana.com/) alerts** - async/sync not working; pods fresh after jumphost login with high (new) node number; cluster capacity alert for topic count over 800.

---

## Participants

- Adrian Pedziwiatr
- Michał Słonina
- Simon
- Adam
- Milan
- Giannis

**Blackbox monitoring access status:**
- StatusCake - all participants should have access.
- AlertSite (ticket: https://tomtom.atlassian.net/browse/SPSRE-3427):
  - Adrian, Michał, Simon - should have access to matrix v2 alerts.
  - Adam, Milan, Giannis - should have accounts; access to matrix v2 alerts to be verified.

---

## Steps Performed

### AlertSite Alerts

PagerDuty incidents:
- https://tomtom.pagerduty.com/incidents/Q187J4R8JLWMP4
- https://tomtom.pagerduty.com/incidents/Q30CFT42W6FI5G
- https://tomtom.pagerduty.com/incidents/Q0EUUP0YCIKQG2
- https://tomtom.pagerduty.com/incidents/Q2WT7UZ3EPVKLU

Steps:
1. Identified that problems were reported from one AlertSite region only.
2. Checked matrix logs - tracking IDs not found.
3. Observed "read timed out" errors with response time 0s, indicating a probable network issue on AlertSite's side.
4. Temporarily disabled the affected AlertSite location as a mitigation.

### StatusCake Alerts

PagerDuty incident:
- https://tomtom.pagerduty.com/incidents/Q14PA52AMKVUT3

PagerDuty search for related incidents:
- https://tomtom.pagerduty.com/search/?searchString=korea%20went%20down&searchType%5B%5D=incident&sortBy=recency&startDate=2025-08-18

Steps:
1. Identified health down alerts for multiple services.
2. Confirmed NOC was already aware.
3. Reviewed multiple StatusCake emails.
4. Reviewed multiple PagerDuty incidents related to "korea went down".

### Grafana Alerts (async/sync)

PagerDuty incidents:
- https://tomtom.pagerduty.com/incidents/Q03R8MBGKVJZ74
- https://tomtom.pagerduty.com/incidents/Q2SA6086F0OL6M
- https://tomtom.pagerduty.com/incidents/Q05MV07XVIIO5C

Steps:
1. Reviewed the alert graph:
   - https://grafana.prod.batch.tt4.nl/d/common-alerts-1/common-alerts?tab=query&viewPanel=14&orgId=1&from=1755455738653&to=1755459030044&editPanel=14
2. Logged in to jumphost - observed pods are fresh, node has a high (new) number.
3. Double-checked theory in logs:
   - https://grafana.tomtomgroup.com/goto/IzCKbWXNR?orgId=1
4. Investigated a real improvement and applied a hot fix:
   - https://github.com/tomtom-internal/batch-service2-infra/pull/603

### Grafana Alerts 2 (Cluster Capacity)

PagerDuty incident:
- https://tomtom.pagerduty.com/incidents/Q0AOVKUMXC4G5U

Steps:
1. Identified the "Cluster capacity - urgent action required" alert, triggered when the number of [Pulsar](https://pulsar.apache.org/) topics exceeds 800.
2. Action when this alert fires: **"Do a pulsar release followed by a batch release NOW!"**

---

## Issues Encountered

- AlertSite reported failures from a single region only; tracking IDs were absent from matrix logs, making it hard to correlate. Root cause assessed as a network issue on AlertSite's side ("read timed out" + 0s response time).
- StatusCake triggered health-down alerts for multiple services simultaneously; required cross-checking with NOC to confirm awareness and avoid duplicate work.
- Grafana async/sync alerts were caused by fresh pods on a node with a high (new) number - indicating a node replacement or scaling event that disrupted in-flight operations.
- Cluster capacity alert fires when the number of Pulsar topics exceeds 800; requires immediate coordinated release action.

---

## Lessons Learned

- When AlertSite fires from a single region only with 0s response time and "read timed out", prioritize investigating AlertSite infrastructure or network issues before investigating the service itself.
- Disabling a misbehaving AlertSite monitoring location is a valid temporary mitigation.
- For StatusCake mass-health-down events, always check with NOC first to confirm awareness and get context before escalating.
- After jumphost login, fresh pods on a newly numbered node are a signal of a node replacement event that may explain transient Grafana async/sync alerts.
- Cluster capacity alert (>800 topics): the response is a coordinated pulsar + batch release immediately.
- AlertSite access for Adam, Milan, and Giannis needs to be verified (SPSRE-3427).

---

## Action Items

| # | Action | Owner | Status |
|---|--------|-------|--------|
| 1 | Verify AlertSite access for Adam, Milan, Giannis (SPSRE-3427) | Adam / Milan / Giannis | Open |
| 2 | Review and merge batch-service2-infra PR #603 (hot improvement for Grafana async/sync) | Team | Open |
| 3 | Document procedure for disabling an AlertSite monitoring location during false-positive events | Team | Open |
| 4 | Ensure all team members know the cluster capacity alert response: pulsar release + batch release immediately when topics > 800 | Team | Open |
