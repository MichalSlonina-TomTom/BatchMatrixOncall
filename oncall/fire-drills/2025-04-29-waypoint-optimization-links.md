# Fire Drill: Waypoint Optimization Important Links

## Scenario

Fire drill conducted on 2025-04-29 to validate familiarity with Waypoint Optimization's key observability and monitoring resources. The goal was to ensure on-call engineers can quickly locate logs, dashboards, metrics, and uptime monitors during an incident.

## Participants

- Adrian Pedziwiatr (recorded session host)

## Steps Performed

### Recording

- Session recording: https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQC8OuOsrUe-QoQQuwZXciQlAZmTtW7JevIjPMoHEbHJ-_0

### Links Reviewed

**Uptime Monitoring**

- [StatusCake](https://www.statuscake.com) tests: https://app.statuscake.com/YourStatus2.php — search by keyword `Waypoint`

**[Scalyr](https://www.dataset.com) Logs and Dashboards**

- Live logs (excluding ingress, filtering by waypoints component):
  https://app.eu.scalyr.com/events?filter=app.kubernetes.io%5C%2Finstance+%21%3D+%27ingress%27+component%3D%27waypoints%27&teamToken=hUUcDsKzE9CckPrAEhpHgQ--
- Waypoints - Metrics dashboard (1-year view, Main tab):
  https://app.eu.scalyr.com/dashboards/Waypoints%20-%20Metrics?teamToken=hUUcDsKzE9CckPrAEhpHgQ--&activeTab=Main&startTime=1+year
- Waypoints - Metrics timeline dashboard (Response Codes tab):
  https://app.eu.scalyr.com/dashboards/Waypoints%20-%20Metrics%20timeline?teamToken=hUUcDsKzE9CckPrAEhpHgQ--&activeTab=Response+Codes

**[Grafana](https://grafana.com)**

- Waypoint Optimization API dashboard (prod, West Europe, last 15 min):
  https://grafana.prod.batch.tt4.nl/d/WJ5fONM7z/waypoint-optimization-api?orgId=1&from=now-15m&to=now&var-cluster_name=aks136-prod-westeurope

## Issues Encountered

Limited content at time of documentation.

## Lessons Learned

Limited content at time of documentation.

## Action Items

Limited content at time of documentation.
