# Batch Matrix Fire Drills

Fire drills are practice sessions where the on-call team walks through failure scenarios in a low-stakes environment. The goals are to build muscle memory for runbook execution, expose gaps in tooling and documentation, and ensure every engineer on the rotation can navigate dashboards, logs, and escalation paths before an actual incident.

## Fire Drill Records

| Date | Topic | Record |
|------|-------|--------|
| 2025-02-11 | Quota Management - Classic Batch | [2025-02-11-quota-batch.md](2025-02-11-quota-batch.md) |
| 2025-02-21 | Quota Management - Matrix v2 | [2025-02-21-quota-matrix-v2.md](2025-02-21-quota-matrix-v2.md) |
| 2025-02-25 | Architecture Overall | [2025-02-25-architecture-overall.md](2025-02-25-architecture-overall.md) |
| 2025-03-11 | Fire Drill Retro | [2025-03-11-retro.md](2025-03-11-retro.md) |
| 2025-03-25 | East US Was Down | _(no record yet)_ |
| 2025-03-31 | Plan 2025-04 | [2025-03-31-plan.md](2025-03-31-plan.md) |
| 2025-04-01 | Jumphost [PIM](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) | [2025-04-01-jumphost-pim.md](2025-04-01-jumphost-pim.md) |
| 2025-04-04 | Logs | [2025-04-04-logs.md](2025-04-04-logs.md) |
| 2025-04-08 | Clicking Through Dashboards - [Apigee](https://cloud.google.com/apigee/docs), 202s | _(no record yet)_ |
| 2025-04-15 | Healthchecks | _(no record yet)_ |
| 2025-04-22 | Releases | _(no record yet)_ |
| 2025-04-25 | Rollout Pipelines | _(no record yet)_ |

## How to Run a Fire Drill

1. **Pick a scenario.** Choose a runbook from [../runbooks/](../runbooks/) or define a new failure mode. Past retros and the planning session ([2025-03-31-plan.md](2025-03-31-plan.md)) are good starting points.
2. **Set the scope.** Choose between a solo walk-through, a pair session, or a full team exercise. Block 45-90 minutes on the calendar.
3. **Execute without shortcuts.** Follow the runbook step by step as if the incident is real. Note every unclear step, broken link, or missing access.
4. **Capture findings.** Create a record in this directory named `YYYY-MM-DD-<short-slug>.md`. Record what was practiced, what broke, and what action items follow.
5. **File action items.** Open tickets or pull requests for any gaps found. Link them from the drill record.
6. **Rotate facilitators.** Lead each drill with a different engineer to spread familiarity across the rotation.

## Related Resources

- [../setup.md](../setup.md) - Environment setup and access prerequisites for on-call engineers
- [../runbooks/](../runbooks/) - Operational runbooks referenced during drills and real incidents
