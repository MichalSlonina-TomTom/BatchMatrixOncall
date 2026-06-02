# Fire Drill: Quota Management - Matrix v2

**Date:** 2025-02-21

## Scenario

Quota management for Matrix Routing v2 (batch 1.3 / large matrix). Matrix v2 uses `calculateMultipleRoutes` (private implementation); processing speed is controlled by `maxParallelPerSeconds`. This differs from classic Batch & Matrix 1.2, which controls speed via QPS to routing/search APIs.

## Participants

_Not recorded on the Confluence page._

## Steps Performed

This drill focused on reference material rather than step-by-step actions. Use the dashboards and docs below as your starting point:

**[Grafana](https://grafana.com/docs/) dashboards used:**

- Status codes per client: https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client
- Client usage: https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage
- Quota usage Matrix v2: https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2
- Quota usage Batch 1.2 (classic): https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2

**Reference docs consulted:**

- Glossary: https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/glossary.md
- Architecture diagrams (Matrix v2 interactions): https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/integrations-matrixv2/matrixv2-interactions.drawio.png
- Internal docs: https://github.com/tomtom-internal/batch-service2-infra/tree/master/docs
- Troubleshooting: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233910010

**Matrix v2 API docs referenced:**

- Sync: https://developer.tomtom.com/routing-api/documentation/tomtom-maps/matrix-routing-v2/synchronous-matrix
- Async submission: https://developer.tomtom.com/matrix-routing-v2-api/documentation/asynchronous-matrix-submission
- Async status: https://developer.tomtom.com/matrix-routing-v2-api/documentation/asynchronous-matrix-status
- Async download: https://developer.tomtom.com/matrix-routing-v2-api/documentation/asynchronous-matrix-download
- Multi-customer / reseller mode: https://developer.tomtom.com/matrix-routing-v2-api/documentation/multi-customer

**Recommended reading (quota pages):**

- Batch 1.2 quotas (detailed): https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849
- Matrix v2 quotas: https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086

## Issues Encountered

_Not recorded on the Confluence page._

## Lessons Learned

_Not recorded on the Confluence page._

Keep these terms distinct — they refer to different systems with different quota mechanisms:

- **batch 1.2 / classic batch / classic Batch & Matrix** = Batch Search, Batch Routing, Matrix Routing v1 — uses client API key, processing speed controlled by QPS to routing/search APIs.
- **batch 1.3 / large matrix / Matrix Routing v2** = uses `calculateMultipleRoutes` (private implementation), processing speed controlled by `maxParallelPerSeconds`.

## Action Items

_Not recorded on the Confluence page._

---

_Source: Confluence page 529564667 — "2025-02-21 Fire drill - quota management - matrix v2" (last updated 2025-02-25). The page contains reference links and a glossary only. No step-by-step drill log, participant list, issues, lessons, or action items were recorded._
