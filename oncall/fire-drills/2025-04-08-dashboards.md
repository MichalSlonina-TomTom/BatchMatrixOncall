# Fire Drill: Clicking Through Dashboards - Apigee, 202s

**Date:** 2025-04-08

## Scenario

This session covered two topics:

- **Apigee issues** - how to investigate problems originating from the [Apigee](https://cloud.google.com/apigee/docs) API gateway layer
- **Lots of 202 alerts (quota utilization)** - how to handle high volumes of HTTP 202 responses (requests accepted but queued due to quota limits)

A recording of the session is available at:
https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQBbBilNn2XZQZdkfFd7uJR6AX5G0f4mdwTaANeyKq21THM

## Participants

_Not recorded on the Confluence page._

## Steps Performed

### Impact Assessment Skills

#### Client Identification

To identify the affected client, use:

- Scalyr (EU): https://app.eu.scalyr.com/
- Scalyr (US): https://app.scalyr.com/
- APIM Developer Account Overview dashboard: https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview
- APIM Search for Developer App (by API key, developer ID, app ID, email, SSO ID, EA ID, or SAP customer ID): https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id?orgId=1

See also: Batch & Matrix 1.2 quotas page, section 4.1 Client Identification:
https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849/Batch+Matrix+1.2+-+quotas+processing+speed+recommendations+for+clients#4.1.-%5BinlineExtension%5DClient-identification

#### Quota Usage Dashboards

**[Backend2 → Quota usage] [Front2 → Client usage]**

- Quota Usage - Batch 1.2: https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2
- Quota Usage - Matrix V2: https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2
- Client Usage (all keys): https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage

#### Status Codes Dashboards

**[Front2 → Status codes] [Kubernetes → Ingress haproxy]**

- Status Codes: https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes
- Status Codes per Client: https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client
- Kubernetes Ingress HAProxy: https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy

#### Executor Dashboards

**[Backend2 → Executor]**

- Executor - Batch 1.2: https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch12-1/executor-batch1-2
- Executor - Batch 1.3: https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch13-1/executor-batch1-3

#### Health Indicators Dashboards

**[Components2 → Health indicators] = [Front2 → Front health indicators] + [Backend2 → Backend health indicators]**

- Health Indicators (combined): https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators
- Front Health Indicators: https://grafana.prod.batch.tt4.nl/d/batch2-front-health-indicators-1/front-health-indicators
- Backend Health Indicators: https://grafana.prod.batch.tt4.nl/d/batch2-backend-health-indicators-1/backend-health-indicators

## Issues Encountered

_Not recorded on the Confluence page._

## Lessons Learned

As an on-caller, master **impact assessment** — it has two core skills:

1. **Client identification** - find which client/API key is driving the traffic that triggered the alert, using Scalyr logs and APIM dashboards.
2. **Dashboard navigation** - know which [Grafana](https://grafana.com/docs/grafana/latest/) dashboards to check for quota usage, status codes, executor metrics, and health indicators across Batch 1.2 and Matrix V2.

The dashboards are grouped by component view (Frontend, Backend, Kubernetes) and by concern (quota, status codes, executor health, health indicators).

## Action Items

_Not recorded on the Confluence page._
