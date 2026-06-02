# Fire Drill: Jumphost PIM

**Date:** 2025-04-01

## Scenario

Practice accessing the jumphost using [PIM (Privileged Identity Management)](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) elevation. PIM access is required during oncall incidents that need direct access to production infrastructure. A VPN connection or office network is required to reach the jumphost, [Jenkins](https://www.jenkins.io/doc/), and [Grafana](https://grafana.com/docs/grafana/latest/).

## Participants

- Adrian Pedziwiatr (organizer/recorder)

## Steps Performed

- Follow the [jumphost login documentation/cheat sheet](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902100).
- Complete the full PIM elevation and jumphost login flow.

## Issues Encountered

None documented. See the session recordings for details:

- [Recording 1](https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQAoJ4aDMMbMQJapRbAmOFjqAdNkSfeeEMuaGyuUtJqGdZQ)
- [Recording 2](https://tomtominternational-my.sharepoint.com/:v:/g/personal/adrian_pedziwiatr_tomtom_com/IQCirMDQyuXfT5OwswJkzXMUAeFvrr8kmdkvOXsSL2XY-RA)

## Lessons Learned

- A VPN connection or office network is **required** to access the jumphost, Jenkins, and Grafana. There is no workaround without VPN.

## Action Items

- None. The Confluence page has minimal content — the session recordings linked above are the primary record.
