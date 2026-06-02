# Section 11: Risks and Technical Debts

This section lists technical risks and debts for the Batch & Matrix Routing system, ordered by combined priority (probability × impact). Each entry includes its mitigations and links to relevant runbooks and dashboards.

---

## Technical Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Azure Region Outage | Medium | High | [Azure Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/) automatically routes new traffic away from a degraded region. Disable the affected region manually using the [Disabling Traffic Manager region runbook](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233927941). Batch & Matrix 1.2 uses sticky regions: jobs accepted in a failing region can only be computed and downloaded there, so stabilise that region (drain nodes, restart pods) rather than discard it. Matrix Routing v2 sync mode degrades more gracefully than async during a partial outage. Dashboards: [Health Indicators](https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators), [Status Codes](https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-1/status-codes), [HAProxy Ingress](https://grafana.prod.batch.tt4.nl/d/kubernetes-ingresshaproxy-1/kubernetes-ingress-haproxy). |
| Apache Pulsar Backlog Buildup | Medium | Medium | Each customer queue runs in its own [Apache Pulsar](https://pulsar.apache.org/docs/) namespace, so one noisy customer cannot block others. Start by checking the [Pulsar State Alerts dashboard](https://grafana.prod.batch.tt4.nl/d/alert-pulsarstate-1/pulsar-state-alerts). If a backlog grows, trigger a rolling restart of `backend12` pods via a [Jenkins](https://www.jenkins.io/doc/) rollout job. Per-topic retention and backlog quotas cap prolonged growth. |
| Client API Key Quota Exhaustion | Medium | Medium | [Apigee](https://docs.cloud.google.com/apigee/docs)/APIM enforces quota limits before requests reach the service. When a client approaches or exceeds its quota, follow the [Matrix Routing v2 API key emergency runbook](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832) or the [Batch 1.2 quotas page](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849) to apply a temporary adjustment. Monitor real-time usage on the [APIM Grafana dashboard](https://grafana.api-system.tomtom.com). |
| Underlying Service Outage (Routing API / Search API) | Low | High | Batch & Matrix is a thin orchestration layer and cannot compensate for upstream outages. When the Routing API or Search API fails, the executor returns errors for affected queries and includes them in the batch result. Watch the [Executor dashboard](https://grafana.prod.batch.tt4.nl/d/batch2-executor-batch12-1/executor-batch1-2) for elevated error rates and escalate to the responsible service team. There is no automated failover; graceful degradation is limited to returning partial results where possible. |
| Apache Pulsar Disk Full | Low | High | Pulsar brokers keep messages on disk until acknowledged. A full disk halts all message production and consumption, making async submissions completely unavailable. Follow the [Expand disk runbook](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915836) to recover. Monitor disk usage via Grafana Cloud Logs and the Pulsar State Alerts dashboard. Retention policies and periodic capacity reviews prevent recurrence. |
| Certificate or Authentication Issues | Low | High | Expired TLS certificates or misconfigured authentication between components (`front12`, `backend12`, Pulsar, [Redis](https://redis.io/docs/), [Azure Blob Storage](https://learn.microsoft.com/azure/storage/blobs/)) produce widespread 401/403 errors or a total loss of connectivity. Detect these via the [Health Indicators dashboard](https://grafana.prod.batch.tt4.nl/d/batch2-health-indicators-1/health-indicators) and the [Common Alerts dashboard](https://grafana.prod.batch.tt4.nl/d/common-alerts-1/common-alerts). Rotating credentials or certificates in production requires [PIM](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/) elevation — follow the [Accessing jumphost & break-glass runbook](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902281) and the [Request PIM runbook](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902249). |

---

## Technical Debts

### Coexistence of Batch & Matrix 1.2 and Matrix Routing v2

The system runs two architecturally distinct product generations side-by-side:

- **Batch & Matrix 1.2** (repo: `batch-service2-1.2`, components: `front12`, `backend12`) handles Batch Search, Batch Routing, and Matrix Routing v1.
- **Matrix Routing v2** (repo: `batch-service2`) is a newer, independently architected product that shares only the [Apache Pulsar](https://pulsar.apache.org/docs/) message broker and [Azure Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/) infrastructure.

This coexistence adds operational overhead: you must understand two component topologies, two sets of [Grafana](https://grafana.com/docs/grafana/latest/) dashboards, two separate [Kubernetes](https://kubernetes.io/docs/) clusters (`aks132-prod-*` for Batch 1.2, `aks13-prod-*` for Matrix v2), and two distinct runbooks. The two products can also fail independently and in asymmetric ways — as seen in the East US fire drill, where Batch 1.2 correctly reported unhealthy pods to Traffic Manager while Matrix v2 continued to advertise health despite serving errors. Decommissioning Batch 1.2 after all customers migrate to newer products would eliminate this dual-track complexity.

### Time Synchronisation Between Batch & Matrix and Apigee

Clock drift between Batch & Matrix service nodes and the Apigee/APIM quota enforcement layer is a recurring source of false `403 Forbidden` errors. When clocks diverge beyond the tolerance window for request signing or token validation, legitimate requests are rejected as though the API key is invalid or the quota is exceeded. This makes clock skew easy to overlook during an incident — you may spend time investigating quota configuration or authentication before identifying it as the root cause. To mitigate this, enforce and monitor NTP synchronisation on all node pools, and add clock drift as an explicit step in the quota/auth troubleshooting runbook.

---

## References

- [Batch & Matrix Knowledge Base](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/315602085)
- [Disabling Traffic Manager Region](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233927941)
- [Batch 1.2 Quotas](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915849)
- [Matrix Routing v2 Quotas](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/287900086)
- [Matrix Routing v2 API Key Emergency](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915832)
- [Expand Disk](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233915836)
- [Jumphost & PIM](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902100)
- [Accessing Jumphost & Break-Glass](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902281)
- [Request PIM](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902249)
- [Grafana (Batch)](https://grafana.prod.batch.tt4.nl)
- [Grafana (APIM)](https://grafana.api-system.tomtom.com)
- [Grafana Cloud Logs](https://grafana.tomtomgroup.com)
