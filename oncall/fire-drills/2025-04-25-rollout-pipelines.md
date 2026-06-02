# Fire Drill: Rollout Pipelines

**Date:** 2025-04-25

## Scenario

This drill covers how to perform a component rollout as an immediate on-call action. It walks through using the rollout/restart pipelines in [Jenkins](https://www.jenkins.io/doc/) for the Batch cluster and [Pulsar](https://pulsar.apache.org/docs/) cluster in production. A real incident (Matrix Routing v2 - `maxParallelRequests` not provided) is used as a case study.

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQB4CKc7ro3YQbVjPeG47hXpAZTHtFLuHrD3VQnAczNPPkI

## Participants

Not recorded on the Confluence page.

## Steps Performed

### Skill set for an on-caller: immediate actions

To perform a component rollout as an immediate action, use the dedicated pipelines below:

- **Batch cluster rollout/restart (prod):**
  https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/

- **Pulsar cluster rollout/restart (prod):**
  https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/

### Case study: Matrix Routing v2 - `maxParallelRequests` not provided

The drill walked through this real incident as a case study:

- **PagerDuty alert:** https://tomtom.pagerduty.com/incidents/Q2TCMVDPN9FN1K
- **Slack thread:** https://tomtomslack.slack.com/archives/C02FX0X7M1P/p1744964018009269

## Issues Encountered

Not recorded on the Confluence page.

## Lessons Learned

Not recorded on the Confluence page.

## Action Items

Not recorded on the Confluence page.
