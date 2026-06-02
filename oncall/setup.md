# Oncall Engineer Setup Guide

## Overview

As an oncall engineer for Batch & Matrix Routing, you are the first line of response for production incidents affecting TomTom's Batch Search API, Batch Routing API, Matrix Routing v1 (Batch & Matrix 1.2), and Matrix Routing v2. These services process up to 10,000 queries per submission on behalf of clients, executing against underlying APIs (Routing API, Search API, etc.) using client API keys.

You need access to ten systems before your first solo shift: GitHub (source code and infra scripts), Azure PIM (on-demand privileged roles), a jumphost bastion VM, two Grafana instances (Batch service and APIM), Grafana Cloud Logs (Loki), Scalyr for legacy log search, Jenkins for operational automation, Apache Pulsar (via jumphost), and PagerDuty for alerts.

For most access requests, ask your team lead. Systems where TomTom SSO is sufficient are noted per section below.

---

## Setup Checklist

Complete every item before going oncall solo.

### GitHub Access
- [ ] 1. Request access to the `tomtom-internal` GitHub organisation (ask your team lead)
- [ ] 2. Verify access to all five repos (see Section 1):
  `gh repo view tomtom-internal/batch-service2`
  `gh repo view tomtom-internal/batch-service2-1.2`
  `gh repo view tomtom-internal/batch-service2-infra`
  `gh repo view tomtom-internal/batch-service2-testing-tools`
  `gh repo view tomtom-internal/batch-service2-pulsar`
- [ ] 3. Clone `batch-service2-infra` locally (required for the jumphost login script)

### Azure Access & PIM
- [ ] 4. Confirm your TomTom Azure account is active and can sign in to the [Azure Portal](https://portal.azure.com)
- [ ] 5. Ask your team lead to verify you have **Eligible** assignments for all four PIM roles (see Section 2)
- [ ] 6. Practice requesting a role at [PIM — My Roles](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ActivationMenuBlade/azurerbac)
- [ ] 7. Verify you can reach the [PIM Approve requests page](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/azurerbac)
- [ ] 8. Join the `#noc-pim-request` Slack channel (out-of-hours NOC approvals)

### Jumphost SSH Access
- [ ] 9. Install `az cli` with ssh extension >= 0.1.6
- [ ] 10. Add OpenSSH compatibility fix if on Ubuntu 22.04+ (see Section 3)
- [ ] 11. Activate PIM roles, then test login: `az ssh vm --ip jumphost.prod.batch.tt4.nl -- -tA`
- [ ] 12. Run first-time user setup: `/opt/tomtom/jumphost-configure-user-environment.sh`
- [ ] 13. Log in from jumphost: `az login --use-device-code`
- [ ] 14. Verify AKS access: `az-aks-get-credentials-prod-user aks21 westeurope`
- [ ] 15. Bookmark the break-glass Vault URL and read the procedure (Section 3)
- [ ] 16. Read `oncall/runbooks/jumphost-pim.md` and [Confluence 233902281](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902281)

### Grafana — Batch Service Dashboards
- [ ] 17. Request access and bookmark [Status codes per client](https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client)
- [ ] 18. Bookmark [Quota usage — Batch 1.2](https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2)
- [ ] 19. Bookmark [Quota usage — Matrix v2](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2)
- [ ] 20. Bookmark [Health indicators](https://grafana.prod.tt-lns-batch.com/d/batch2-health-indicators-1/health-indicators)
- [ ] 21. Bookmark [Client usage](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage)
- [ ] 22. Bookmark [Blob storage](https://grafana.prod.tt-lns-batch.com/d/batch2-storage-1/blob-storage)

### Grafana — APIM Dashboards
- [ ] 23. Request access to `https://grafana.api-system.tomtom.com` and bookmark [Call volume vs quota breaches](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches)
- [ ] 24. Bookmark [Developer account overview](https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview)
- [ ] 25. Bookmark [Search for developer app by API key / email / ID](https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id)

### Grafana Cloud Logs (Loki)
- [ ] 26. Open [EU log explorer (front12 preset)](https://grafana.tomtomgroup.com/goto/CEEQuRbNg?orgId=1) and confirm log lines appear
- [ ] 27. Open [US log explorer (front12 preset)](https://grafana.tomtomgroup.com/goto/fmCQuRxHg?orgId=1) and confirm log lines appear

### Scalyr (DataSet)
- [ ] 28. Request Scalyr access from your team lead; verify you can query `app.kubernetes.io\/name="front12-deployment" "New submission request"`

### Jenkins CI
- [ ] 29. Request access to `https://ci.dev.batch.tt4.nl` and bookmark [rollout_restart_batch_cluster_prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/)
- [ ] 30. Bookmark [rollout_restart_pulsar_cluster_prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/), [deploy_jumphost_prod](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Jumphost/job/deploy_jumphost_prod/), and [Simple_Batch_release](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch_Release/view/Simple_Batch_release/) (use after Grafana confirms issue and rollout restart fails)

### Apache Pulsar
- [ ] 31. Verify jumphost + AKS access (prerequisite), then locate `pulsar-toolset` pod and confirm you can exec into it

### PagerDuty / Alerting
- [ ] 32. Ask your team lead to add you to the oncall rotation in PagerDuty
- [ ] 33. Install the PagerDuty mobile app and enable push notifications
- [ ] 34. Test that you can acknowledge and resolve a test alert

---

## Detailed Setup Instructions

### 1. GitHub — tomtom-internal Organisation

**What it is:** All source code, infrastructure-as-code, and tooling. You need read access to review code during incidents and to run the jumphost login script from `batch-service2-infra`.

**How to request access:** Ask your team lead to add you to the relevant GitHub teams.

**Repos:**

| Repo | Purpose |
| --- | --- |
| `batch-service2` | Matrix Routing v2 (front13, backend13) |
| `batch-service2-1.2` | Batch Search, Batch Routing, Matrix Routing v1 (front12, backend12) |
| `batch-service2-infra` | Terraform, Helm, jumphost scripts, Pulsar config |
| `batch-service2-testing-tools` | Load and integration testing |
| `batch-service2-pulsar` | Pulsar configuration and tooling |

**Verify access:** `gh repo view tomtom-internal/<repo>` should return metadata, not a 404.

---

### 2. Azure Access & PIM (Privileged Identity Management)

**What it is:** Production AKS clusters and jumphost VMs are gated by [Azure PIM](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure). You activate roles on demand (default 4 hours) rather than holding standing access.

**Required PIM roles:**

| Role | What it grants |
| --- | --- |
| NAV Routing/Search Batch — prod — Reader | View all resources |
| NAV Routing/Search Batch — prod — Virtual Machine Administrator Login | SSH login to jumphost |
| NAV Routing/Search Batch — prod — Azure Kubernetes Service Contributor Role | Manage AKS resources |
| NAV Routing/Search Batch — prod — Contributor | Full resource management |

**How to activate (business hours):** Go to [PIM — My Roles](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ActivationMenuBlade/azurerbac). Click **Activate** next to the role, enter a reason and duration, then submit. Roles requiring approval send an email to all eligible team members. Track your request at [PIM — My requests](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/RequestMenuBlade/azurerbac).

**How to approve a peer's request:** Go to [PIM — Approve requests](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/azurerbac).

**Out-of-hours (NOC approval):** Submit your PIM request as normal, then post in `#noc-pim-request` Slack using the pinned workflow form. NOC approves on your behalf. Full details: [Confluence 233902278](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902278).

Detailed docs: [Confluence 233902249](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902249) | [Confluence 233902272](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902272) | `oncall/runbooks/jumphost-pim.md`

---

### 3. Jumphost SSH Access

**What it is:** Bastion VM. The only path into the production AKS clusters and Pulsar toolset.

| Host | Region | Purpose |
| --- | --- | --- |
| `jumphost.prod.batch.tt4.nl` | West Europe | Primary |
| `jumphost2.prod.batch.tt4.nl` | East US | Backup |

**OpenSSH fix** (Ubuntu 22.04+ or any modern OpenSSH client): create `/etc/ssh/ssh_config.d/azure-ssh.conf` with the following content:

```
Host *
    PubkeyAcceptedKeyTypes +ssh-rsa-cert-v01@openssh.com
```

**Login — using the infra script (recommended):** From `batch-service2-infra/jumphost/`:

```bash
./jumphost-login.sh prod                    # primary
./jumphost-login.sh prod --backup-jumphost  # backup
```

**Login — az cli only:**

```bash
az ssh vm --ip jumphost.prod.batch.tt4.nl -- -tA
```

**First-time setup once logged in:**

```bash
/opt/tomtom/jumphost-configure-user-environment.sh
az login --use-device-code
az-aks-get-credentials-prod-user aks21 westeurope
```

**Troubleshooting — login hangs with no output:**

```bash
ssh-keygen -R jumphost.prod.batch.tt4.nl
ssh-keygen -R jumphost2.prod.batch.tt4.nl
```

**Break-glass procedure** (PIM unavailable):

1. Copy your SSH key: `cp ~/.ssh/your-work.key ~/.ssh/jumphost.key`
2. Go to `https://vault.tomtomgroup.com/ui/vault/secrets/break-glass/sign/default?namespace=cit-compute-public` — sign in with OIDC (allow pop-ups)
3. Click **More options**; paste your **public** key into "Public Key"; enter subscription ID `2c48294f-c12f-4cd5-8c1a-b57f43e6fa43` into "Valid principals"; click **Sign**
4. Save the "Signed key" as `~/.ssh/jumphost.key.pub`, then:

```bash
ssh -o PreferredAuthentications=publickey -tA -l azureuser jumphost.prod.batch.tt4.nl -i ~/.ssh/jumphost.key
```

5. On the jumphost, activate the managed identity for Contributor access:

```bash
az login --identity -u /subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/resourceGroups/managed-identities-prod/providers/Microsoft.ManagedIdentity/userAssignedIdentities/jumphost
```

Detailed docs: [Confluence 233902100](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902100) | [Confluence 233902281](https://tomtom.atlassian.net/wiki/spaces/DIRECTIONS/pages/233902281) | `oncall/runbooks/jumphost-pim.md`

---

### 4. Grafana — Batch Service Dashboards

**What it is:** Primary observability for Batch & Matrix. Shows request status codes, quota utilisation, healthcheck results, client submission volume, and blob storage latency. Dashboards run on [Grafana](https://grafana.com/docs/grafana/latest/).

**How to request access:** Ask your team lead. TomTom SSO works for `grafana.prod.batch.tt4.nl`. A second instance at `grafana.prod.tt-lns-batch.com` hosts health and storage dashboards.

**Verify:** Open `https://grafana.prod.batch.tt4.nl` and confirm dashboards load.

| Dashboard | URL | Use for |
| --- | --- | --- |
| Status codes per client | [link](https://grafana.prod.batch.tt4.nl/d/batch2-status-codes-per-client1/status-codes-per-client) | HTTP response codes; filter by `Batch version` (12 or 13) and `customerToken` |
| Quota usage — Batch 1.2 | [link](https://grafana.prod.batch.tt4.nl/d/quota-usage-batch12-1/quota-usage-batch-1-2) | QPS to underlying services, concurrent requests, parallel batch limit |
| Quota usage — Matrix v2 | [link](https://grafana.prod.batch.tt4.nl/d/batch2-quota-usage-matrix2-1/quota-usage-matrix-v2) | maxParallelRequests usage, sync/async parallel matrices, central key QPS |
| Health indicators | [link](https://grafana.prod.tt-lns-batch.com/d/batch2-health-indicators-1/health-indicators) | Healthcheck status for front12/backend12 — first stop in an incident |
| Client usage | [link](https://grafana.prod.batch.tt4.nl/d/batch2-client-usage-allkeys-1/client-usage) | Items submitted over time; filter by `Batch version` and `apiKey` |
| Blob storage | [link](https://grafana.prod.tt-lns-batch.com/d/batch2-storage-1/blob-storage) | Azure Blob Storage read/write latency |

---

### 5. Grafana — APIM Dashboards

**What it is:** Gateway-level observability via [Apigee](https://cloud.google.com/apigee/docs)/APIM. Batch & Matrix does not track quota rejections — 403/429 errors are authoritative here. Also the primary tool for client API key and developer account lookup.

**How to request access:** Ask your team lead. **Verify:** Open `https://grafana.api-system.tomtom.com`.

| Dashboard | URL | Use for |
| --- | --- | --- |
| Call volume vs quota breaches | [link](https://grafana.api-system.tomtom.com/d/DbsVGRfWk/call-volume-vs-quota-breaches) | Check QPS/QPM limit hits; filter by developer app email, environment, API product and method |
| Developer account overview | [link](https://grafana.api-system.tomtom.com/d/ON7yjypZz1/developer-account-overview) | Find a client's developer app IDs by name or email |
| Search for developer app | [link](https://grafana.api-system.tomtom.com/d/ON7yjypZz/search-for-developer-app-by-api-key-developer-id-app-id-email-sso-id-ea-id-or-sap-customer-id) | Look up client by API key (first/last 4 chars), email, SSO ID, or SAP customer ID |

**Common quota-breach filter values:** Batch Search — `API product=Batch Search API`, `Method=search 2 batch`. Batch Routing — `Method=routing 1 batch`. Matrix v1 — `Method=routing 1 matrix`. Matrix v2 — `Child product=Matrix Routing v1`, `Method=routing matrix 2`, `New product structure=False`.

---

### 6. Grafana Cloud Logs (Loki)

**What it is:** Centralised log aggregation for all services using [Grafana Loki](https://grafana.com/docs/loki/latest/). Primary tool for real-time log search during incidents.

**How to request access:** Log in with TomTom SSO at `https://grafana.tomtomgroup.com`. If access is denied, ask your team lead to grant it.

**Verify:** Open the EU link below and confirm log lines appear.

- EU (front12 preset): [https://grafana.tomtomgroup.com/goto/CEEQuRbNg?orgId=1](https://grafana.tomtomgroup.com/goto/CEEQuRbNg?orgId=1)
- US (front12 preset): [https://grafana.tomtomgroup.com/goto/fmCQuRxHg?orgId=1](https://grafana.tomtomgroup.com/goto/fmCQuRxHg?orgId=1)

**Common search patterns:** Set label filter `k8s_deployment_name=front12-deployment` (or `front13-deployment` for Matrix v2), then add log line filters as needed:

| Goal | Log line filters |
| --- | --- |
| Find submission by batch ID / tracking ID / API key | `New submission request` + `<identifier>` |
| Find queue name for a customer token | `Created producer for topic` + `<customer-token>` |

---

### 7. Scalyr (DataSet) — Legacy Log Search

**What it is:** Legacy log platform still referenced in some runbooks. Logs are indexed by the `app.kubernetes.io/name` label.

**How to request access:** Submit via IT portal or ask your team lead. **Verify:** Run a test query in the Scalyr console.

Common query: `app.kubernetes.io\/name="front12-deployment" "New submission request" "<identifier>"`

For queue name lookup: `app.kubernetes.io\/instance="front12" "Created producer for topic" "<customer-token>"`

---

### 8. Jenkins CI

**What it is:** [Jenkins](https://www.jenkins.io/doc/) CI/CD and operational automation. Use it during incidents to trigger rollout restarts without direct `kubectl` access.

**How to request access:** Ask your team lead (TomTom SSO). **Verify:** Open `https://ci.dev.batch.tt4.nl`.

| Job | URL | When to use |
| --- | --- | --- |
| `rollout_restart_batch_cluster_prod` | [link](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch/job/rollout_restart_batch_cluster_prod/) | Restart front12/backend12 when processing has stalled |
| `rollout_restart_pulsar_cluster_prod` | [link](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Pulsar/job/rollout_restart_pulsar_cluster_prod/) | Restart Pulsar when backlog grows and consumers stop polling |
| `Simple_Batch_release` | [link](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Batch_Release/view/Simple_Batch_release/) | **Redeploy a known-good release.** Use when Grafana confirms an issue and a rollout restart does not fix it. Set `RELEASE_CANDIDATE_BRANCH` from [RELEASES.md](https://github.com/tomtom-internal/batch-service2-infra/blob/master/RELEASES.md); enable `PANIC_MODE` during active incidents (~30 min). |
| `deploy_jumphost_prod` | [link](https://ci.dev.batch.tt4.nl/view/Batch/view/Prod/view/Jumphost/job/deploy_jumphost_prod/) | Redeploy jumphost VM; new VM inherits existing DNS |

---

### 9. Apache Pulsar

**What it is:** [Apache Pulsar](https://pulsar.apache.org/docs/) distributed message queue that decouples HTTP frontends (front12/front13) from processing backends. Each customer has dedicated Pulsar topics. Access is via the `pulsar-toolset` pod, reachable only through the jumphost.

**How to request access:** Jumphost and AKS access are the prerequisites. Exec into the `pulsar-toolset` pod once you have AKS credentials.

**Verify:** From the AKS cluster context on the jumphost, exec into `pulsar-toolset` and run a basic admin command.

**Queue naming:** `SEARCH2` = Batch Search; `ROUTING1` = Batch Routing + Matrix v1; `LARGE_MATRIX1` = Matrix Routing v2.

**What you can do:** Check topic backlog, inspect unacknowledged message counts, and run emergency procedures to increase the parallel batch processing limit per client (script: `batch-service2-infra/terraform-apache-pulsar/pulsar-add-tenant-payload.sh`).

---

### 10. PagerDuty / Alerting

**What it is:** [PagerDuty](https://support.pagerduty.com/) oncall rotation management and alert delivery. Production alerts from Grafana and [Kubernetes](https://kubernetes.io/docs/) route here first.

**How to request access:** Ask your team lead to add you to the Batch & Matrix service and oncall schedule.

**Verify:** Log in and confirm you appear in the schedule.

**Escalation path:** Dev oncall (you) → NOC (for out-of-hours PIM or escalation) → Team lead (decisions outside oncall authority).

**Before your first shift:** Install the PagerDuty mobile app, enable push notifications, and test alert acknowledgement.

---

## Quick Reference Card

| System | URL / Command | Access Type | Who to ask |
| --- | --- | --- | --- |
| GitHub | `gh repo view tomtom-internal/batch-service2` | GitHub team | Team lead |
| PIM — activate | https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ActivationMenuBlade/azurerbac | Eligible role | Team lead |
| PIM — approve | https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/azurerbac | Eligible role | Team lead |
| PIM — out-of-hours | `#noc-pim-request` Slack | NOC approval | NOC |
| Jumphost (primary) | `az ssh vm --ip jumphost.prod.batch.tt4.nl -- -tA` | PIM + az cli | Team lead |
| Jumphost (backup) | `az ssh vm --ip jumphost2.prod.batch.tt4.nl -- -tA` | PIM + az cli | Team lead |
| Break-glass Vault | https://vault.tomtomgroup.com/ui/vault/secrets/break-glass/sign/default?namespace=cit-compute-public | OIDC (self-service) | — |
| Grafana Batch | https://grafana.prod.batch.tt4.nl | TomTom SSO | Team lead |
| Grafana APIM | https://grafana.api-system.tomtom.com | TomTom SSO | Team lead |
| Grafana Cloud Logs EU | https://grafana.tomtomgroup.com/goto/CEEQuRbNg?orgId=1 | TomTom SSO | Team lead |
| Grafana Cloud Logs US | https://grafana.tomtomgroup.com/goto/fmCQuRxHg?orgId=1 | TomTom SSO | Team lead |
| Scalyr (DataSet) | Scalyr console | IT-managed | Team lead / IT |
| Jenkins CI | https://ci.dev.batch.tt4.nl | TomTom SSO | Team lead |
| PagerDuty | PagerDuty portal | Schedule invite | Team lead |

---

## Next Steps

1. **Read the architecture docs** — work through all files in `architecture/` starting with `01-introduction-and-goals.md`. Understanding the data flow from client submission through front12/front13 → Pulsar → backend12/backend13 → Azure Blob Storage is essential for incident diagnosis.

2. **Read all runbooks in `oncall/runbooks/`** — read every runbook before your first shift, especially `jumphost-pim.md` and any runbooks covering queue-stuck scenarios and rollout restart procedures.

3. **Shadow an experienced oncall engineer** — join as secondary oncall for at least one full rotation before going solo.

4. **Attend a fire drill** — the team runs periodic drills simulating real incidents. Participation is required before solo oncall. Confirm the next date with your team lead.

5. **Verify all bookmarks load** — open every Grafana URL in this guide and confirm data is visible before your first shift.

6. **Review the BMW on-call cheatsheet** — see `oncall/bmw-oncall-cheatsheet.md` for a condensed reference covering BMW-specific client workflows and quick actions.
