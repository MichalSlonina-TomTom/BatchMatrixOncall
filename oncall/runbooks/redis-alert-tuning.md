# Redis Alert Threshold Tuning

Use this runbook when Redis alerts are firing frequently and investigation confirms they are not actionable — i.e., the underlying Redis service is healthy and processing is unaffected.

Raising a threshold reduces noise. Only do this after verifying the alerts are genuinely non-critical.

---

## Alert definitions

Redis alert rules live in the `batch-service2-infra` repository:

```
terraform-monitoring/grafana-rule-groups/Redis alerts.json
```

Current alerts and their thresholds:

| Alert | Threshold | Notes |
|---|---|---|
| `redis (index 0) pods health alert` | `gt 0.5` / `gt 0.6` | Pod not ready |
| `redis (index 1) pods health alert` | `gt 0.5` / `gt 0.6` | Pod not ready |
| `redis both (index 0,1) pod health (HEALTHY=0) alert` | `gt 0.4` / `gt 0.5` | Both pods unhealthy |
| `redis (index 0) number of container restarts alert` | `gt 7.5` | Container restart count |
| `redis (index 1) number of container restarts alert` | `gt 7.5` | Container restart count |
| `redis (index 0) cpu usage alert` | `gt 800` | CPU millicores |
| `redis (index 1) cpu usage alert` | `gt 800` | CPU millicores |
| `redis number of leader finder exceptions alert` | `gt 0.5` | Leader election errors |

The **container restarts** alerts (`gt 7.5`) are the most common source of noise — Redis restarts due to transient Kubernetes API connectivity issues (e.g. node pressure) without affecting service availability.

---

## Procedure: raising a threshold

### 1. Verify the alert is non-critical

Before touching thresholds, confirm:

- Redis pods recover on their own without manual intervention.
- Batch/Matrix processing metrics (quota usage, status codes, health indicators) show no degradation during the alert window.
- The Grafana [Redis alerts dashboard](https://grafana.prod.batch.tt4.nl/d/redis-alerts-1/redis-alerts) shows the pattern is recurring but benign.

If in doubt, **do not raise the threshold** — escalate to the team instead.

### 2. Edit the alert rule file

In the `batch-service2-infra` repo, open:

```
terraform-monitoring/grafana-rule-groups/Redis alerts.json
```

Find the rule by its `"title"` field and update the `"params"` value under `"evaluator"`:

```json
"evaluator": {
    "params": [
        7.5        ← change this value
    ],
    "type": "gt"
}
```

Example — raising the container restarts threshold from 7.5 to 15:

```json
"evaluator": {
    "params": [
        15
    ],
    "type": "gt"
}
```

Each rule may have two `evaluator` blocks (one per query ref). Update both to keep them consistent.

### 3. Deploy the change

From the `terraform-monitoring/` directory, run the update script against production:

```bash
./update-alert-resources.sh prod --filter "Redis alerts"
```

This pushes the updated rule group to Grafana at `grafana.prod.batch.tt4.nl`.

### 4. Verify

- Open the [Redis alerts dashboard](https://grafana.prod.batch.tt4.nl/d/redis-alerts-1/redis-alerts) and confirm the rule shows the new threshold.
- Monitor for 24–48 hours to confirm alert noise is reduced without masking real issues.

---

## Caution

- **Do not raise health-check thresholds** (`pods health alert`, `both pods health`) — these indicate real unavailability and should stay sensitive.
- **Prefer raising by a small increment** rather than silencing entirely. If the restart count was routinely hitting 9–10 and the threshold was 7.5, raising to 15 is reasonable. Raising to 100 masks real failures.
- **Record the change** in the PR description and in a comment on the relevant PagerDuty alert or Confluence incident, so future oncall engineers know why the threshold was raised.
