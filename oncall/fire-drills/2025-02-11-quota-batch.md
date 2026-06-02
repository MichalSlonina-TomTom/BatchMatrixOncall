# Fire Drill: Quota Management - Classic Batch

**Date:** 2025-02-11

Source: [Confluence page 507809445](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/507809445)

## Scenario

Customer complaint: batch processing took too long. The drill covers quota management for Classic Batch (Batch 1.2), which includes Batch Search, Batch Routing, and Matrix Routing v1. All three use the client API key, and their processing speed is controlled by QPS to the underlying routing/search APIs.

Simulated example batch jobs used during the drill:

- `https://api.tomtom.com/search/2/batch/b1-c247c351-ba49-45c7-b479-34f9ef739689-0013?key=*eKUN`
- `https://api.tomtom.com/search/2/batch/a1-e43cbcc2-084b-4512-b82f-0d5e58568ced-0013?key=RK9G*`

Key concepts exercised:

- **QPS to Batch&Matrix itself** — limits the rate of calls to submission and download endpoints.
- **QPS to underlying APIs** (calculateRoute, reverseGeocode, geocode, search, etc.) — limits processing speed.
- **tracking-id** — set by the client.
- **batchId** — internal ID set by the service, encoded in the download URL path (e.g. `a1-e43cbcc2-084b-4512-b82f-0d5e58568ced-0013`).
- Batches are processed in submission order.
- All timestamps are UTC.

## Participants

*Not recorded in source Confluence page.*

## Steps Performed

1. Review the glossary and terminology:
   - Classic batch / batch 1.2 = Batch Search + Batch Routing + Matrix Routing v1 (client key, QPS-controlled).
   - batch 1.3 / large matrix / Matrix Routing v2 = uses `calculateMultipleRoutes`, controlled by `maxParallelPerSeconds`.
   - Reference: <https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/glossary.md>

2. Review the architecture diagrams:
   - Batch 1.2 max-QPS sequence diagram: <https://github.com/tomtom-internal/batch-service2-infra/blob/master/docs/diagrams/integrations-batch12/batch1.2-max-qps-sequence-diagram.drawio.png>

3. Locate and review API docs and test data examples:
   - Batch Search sync/async: <https://developer.tomtom.com/batch-search-api/documentation/asynchronous-batch-submission>
   - Batch Routing sync/async: <https://developer.tomtom.com/routing-api/documentation/tomtom-maps/batch-routing/synchronous-batch>
   - Example payloads in [batch-service2-testing-tools](https://github.com/tomtom-internal/batch-service2-testing-tools/blob/master/test-data/)

4. Investigate metrics and logs:
   - [Grafana](https://grafana.com/docs/grafana/latest/): <https://grafana.prod.batch.tt4.nl>
     - Status codes per client: `/d/batch2-status-codes-per-client1/status-codes-per-client`
     - Client usage: `/d/batch2-client-usage-allkeys-1/client-usage`
     - Quota usage: `/d/quota-usage-batch12-1/quota-usage-batch-1-2`
   - Scalyr (logs):
     - <https://app.eu.scalyr.com>
     - <https://app.scalyr.com>

5. Analyze a real-life traffic example (modeled after Slack incident in [#CAZJP939P](https://tomtomslack.slack.com/archives/CAZJP939P/p1699093819396309)):
   - Traffic peak: 8:20–9:50 UTC, ~2.75k batch items/s submitted.
   - Low traffic period: 9:50–16:00 UTC, ~1.5 batch items/s.
   - Total submitted between 8:20–16:00 UTC: ~14.8M batch items.
   - Processing speed: ~460 items/s.
   - At 460 items/s, processing 14.8M items takes ~9 hours → estimated completion 17:20 UTC.

6. Compose a sample customer response:

   > Our traffic summary metrics show that:
   >
   > - The traffic peak was between 8:20 UTC and 9:50 UTC. During this period, ~2.75k batch items/s were submitted.
   > - Later (9:50 UTC - 16:00 UTC) there is little traffic: ~1.5 batch items/s.
   > - Between 8:20 UTC and 16:00 UTC, ~14.8M batch items were submitted in total.
   > - At 460 items/s, processing 14.8M items takes ~9 hours. Estimated completion: 17:20 UTC.
   >
   > Disclaimer: The numbers given were read from summary metrics and are indicative values only. You will be able to check the exact values after computation on the invoice.

7. Review the troubleshooting docs: <https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233910010/Troubleshooting>

## Issues Encountered

*Not recorded in source Confluence page.*

## Lessons Learned

- Use Grafana (metrics) and Scalyr (logs) as the primary tools for diagnosing slow batch processing.
- Always quote timestamps in UTC — to customers and internally.
- The batchId is embedded in the download URL; use it to track and investigate a specific job.
- Divide total submitted items by the observed processing rate (~460 items/s) to give customers a reliable ETA.
- Batches are processed in submission order — a large burst delays all subsequent jobs.
- QPS to the underlying APIs (not just to Batch itself) is the key lever that controls processing speed.

## Action Items

*Not recorded in source Confluence page.*
