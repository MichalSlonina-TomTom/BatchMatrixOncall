# Fire Drill: Status Codes HAProxy; Redis

## Scenario

Fire drill focused on two areas:
1. Redis (index 1) container restarts and pod health degradation
2. HAProxy status code analysis via Loki log queries

Recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQCcTT1Dg73XQZfq98nkZapGARAKL-tQhmYl66I2Auc2osw

## Participants

Limited content at time of documentation.

## Steps Performed

### Alerts Triggered (Redis)

- **PagerDuty Q0PHK8DWYZWUUY** — Redis (index 1) number of container restarts alert: Some redis (index 1) container has been restarted
  https://tomtom.pagerduty.com/incidents/Q0PHK8DWYZWUUY

- **PagerDuty Q3AWQ02NU07N33** — Redis (index 1) number of container restarts alert: Some redis (index 1) container has been restarted
  https://tomtom.pagerduty.com/incidents/Q3AWQ02NU07N33

- **PagerDuty Q06CSIY5JNW5HX** — Redis both (index 0, 1) pod health (HEALTHY=0) alert: Both redises (index 0, 1) pods are unhealthy
  https://tomtom.pagerduty.com/incidents/Q06CSIY5JNW5HX

### Analysis Resources (Redis)

- Redis Helm values (liveness/readiness probes, resource limits):
  https://github.com/tomtom-internal/batch-service2-infra/blob/0b69ae3f9bdc0cebaceaf3bc3950ff01b8fe99a1/helm/charts/internal/redis/values.yaml#L39-L76

- Redis scripts ConfigMap (init/health scripts):
  https://github.com/tomtom-internal/batch-service2-infra/blob/caeb9bb47c83a064683a8b54d3bfe0f71b703e03/helm/charts/internal/redis/templates/scripts-configmap.yaml#L9-L56

- Bitnami Redis upstream chart values (reference):
  https://github.com/bitnami/charts/blob/main/bitnami/redis/values.yaml#L744-L788

### Status Codes (HAProxy)

Loki query used to analyze HAProxy response status codes by path and customer token in production:

```logql
sum(label_replace(sum(count_over_time({service_name="batch-matrix-waypoint", deployment_environment="prod", k8s_deployment_name="ingress-haproxy-ingress-controller", k8s_container_name="access-logs"} | json | logfmt | drop __error__, __error_details__ | haproxy_backend_name !="" | haproxy_backend_name!="monitoring_prometheus-server_9090" | haproxy_request_path!~"/actuator/health.*"[$__auto])) by (haproxy_request_path, customerToken, haproxy_response_status_code), "service", "/$1/$2/$3", "haproxy_request_path", "/([^/]+)/([^/]+)/([^/.]+).*")) by (service, customerToken, haproxy_response_status_code)
```

Grafana dashboard:
https://grafana.tomtomgroup.com/goto/YBU_u6QHR?orgId=1

## Issues Encountered

Limited content at time of documentation.

## Lessons Learned

Limited content at time of documentation.

## Action Items

Limited content at time of documentation.
