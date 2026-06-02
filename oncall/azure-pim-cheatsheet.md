# Azure PIM Cheat Sheet — Batch Matrix Oncall

CLI-only workflow to activate the four PIM roles required for jumphost and AKS access.
No browser needed once your eligible assignments are configured.

---

## Prerequisites

```bash
# az cli installed and logged in
az login

# verify you are in the right tenant
az account show --query "{tenant:tenantId, user:user.name}" -o table
```

**Prod subscription ID:** `2c48294f-c12f-4cd5-8c1a-b57f43e6fa43`

```bash
# set it as default so you don't have to repeat it
az account set --subscription 2c48294f-c12f-4cd5-8c1a-b57f43e6fa43
```

---

## Required roles

| Role | Why you need it |
|---|---|
| `Reader` | View all resources in the subscription |
| `Virtual Machine Administrator Login` | SSH into the jumphost VM |
| `Azure Kubernetes Service Contributor Role` | Connect to AKS clusters |
| `Contributor` | Make changes to resources (e.g., Traffic Manager, disk) |

> For routine log inspection and Grafana checks you only need **Reader** + **VM Administrator Login**.
> Add **AKS Contributor** when you need `kubectl`. Add **Contributor** when you need to modify resources.

---

## Step 1 — Get your principal ID

```bash
MY_PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Principal ID: $MY_PRINCIPAL_ID"
```

---

## Step 2 — List your eligible role assignments

```bash
az rest \
  --method GET \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01&\$filter=asTarget()" \
  --query "value[].{Role:properties.expandedProperties.roleDefinition.displayName, Scope:properties.expandedProperties.scope.displayName}" \
  -o table
```

You should see all four roles listed. If a role is missing, ask your team lead (Team Stratus) to grant you the eligible assignment.

---

## Step 3 — Look up role definition IDs

```bash
SUB=/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43

READER_ID=$(az role definition list --name "Reader" \
  --scope $SUB --query "[0].id" -o tsv)

VM_LOGIN_ID=$(az role definition list --name "Virtual Machine Administrator Login" \
  --scope $SUB --query "[0].id" -o tsv)

AKS_CONTRIB_ID=$(az role definition list --name "Azure Kubernetes Service Contributor Role" \
  --scope $SUB --query "[0].id" -o tsv)

CONTRIBUTOR_ID=$(az role definition list --name "Contributor" \
  --scope $SUB --query "[0].id" -o tsv)

echo "Reader:      $READER_ID"
echo "VM Login:    $VM_LOGIN_ID"
echo "AKS Contrib: $AKS_CONTRIB_ID"
echo "Contributor: $CONTRIBUTOR_ID"
```

---

## Step 4 — Activate roles

Each activation is a separate `az rest PUT` call. Use a fresh UUID for each request.

```bash
# generate a unique request ID for each activation
uuidgen   # macOS / Linux — run once per role
```

### Activate Reader

```bash
az rest \
  --method PUT \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$(uuidgen)?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"$MY_PRINCIPAL_ID\",
      \"roleDefinitionId\": \"$READER_ID\",
      \"requestType\": \"SelfActivate\",
      \"justification\": \"Oncall investigation\",
      \"scheduleInfo\": {
        \"expiration\": {
          \"type\": \"AfterDuration\",
          \"duration\": \"PT4H\"
        }
      }
    }
  }"
```

### Activate Virtual Machine Administrator Login

```bash
az rest \
  --method PUT \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$(uuidgen)?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"$MY_PRINCIPAL_ID\",
      \"roleDefinitionId\": \"$VM_LOGIN_ID\",
      \"requestType\": \"SelfActivate\",
      \"justification\": \"Oncall investigation\",
      \"scheduleInfo\": {
        \"expiration\": {
          \"type\": \"AfterDuration\",
          \"duration\": \"PT4H\"
        }
      }
    }
  }"
```

### Activate Azure Kubernetes Service Contributor Role

```bash
az rest \
  --method PUT \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$(uuidgen)?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"$MY_PRINCIPAL_ID\",
      \"roleDefinitionId\": \"$AKS_CONTRIB_ID\",
      \"requestType\": \"SelfActivate\",
      \"justification\": \"Oncall investigation\",
      \"scheduleInfo\": {
        \"expiration\": {
          \"type\": \"AfterDuration\",
          \"duration\": \"PT4H\"
        }
      }
    }
  }"
```

### Activate Contributor

```bash
az rest \
  --method PUT \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$(uuidgen)?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"$MY_PRINCIPAL_ID\",
      \"roleDefinitionId\": \"$CONTRIBUTOR_ID\",
      \"requestType\": \"SelfActivate\",
      \"justification\": \"Oncall investigation\",
      \"scheduleInfo\": {
        \"expiration\": {
          \"type\": \"AfterDuration\",
          \"duration\": \"PT4H\"
        }
      }
    }
  }"
```

> **If a role requires approval:** the response status will be `Pending`. Ping **Team Stratus** on Slack and share the approval link:
> `https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/azurerbac`
> Outside business hours, use the `#noc-pim-request` Slack channel instead.

---

## Step 5 — Verify active roles

```bash
az rest \
  --method GET \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleInstances?api-version=2020-10-01&\$filter=asTarget()" \
  --query "value[].{Role:properties.expandedProperties.roleDefinition.displayName, Expires:properties.endDateTime}" \
  -o table
```

All four roles should appear with an expiry ~4 hours from now.

---

## Step 6 — Log into the jumphost

### Via script (preferred)

```bash
# from batch-service2-infra repo root
cd jumphost
./jumphost-login.sh prod
```

### Via az CLI directly

```bash
# fix for Ubuntu 22.04+ OpenSSH incompatibility (run once)
sudo tee /etc/ssh/ssh_config.d/azure-ssh.conf <<'EOF'
Host *
    PubkeyAcceptedKeyTypes +ssh-rsa-cert-v01@openssh.com
EOF

# ssh in
az ssh vm --ip jumphost.prod.batch.tt4.nl -- -tA
```

### Backup jumphost (if main is unreachable)

```bash
az ssh vm --ip jumphost2.prod.batch.tt4.nl -- -tA
```

---

## Step 7 — First-time setup on jumphost

Run once after first login (or after a jumphost redeploy):

```bash
/opt/tomtom/jumphost-configure-user-environment.sh
```

Then log in to your business account from the jumphost:

```bash
az login --use-device-code
```

---

## Step 8 — Connect to an AKS cluster

```bash
# list available clusters (run on jumphost)
az aks list --subscription 2c48294f-c12f-4cd5-8c1a-b57f43e6fa43 \
  --query "[].{Name:name, Region:location, RG:resourceGroup}" -o table

# get credentials for a specific cluster (user role — prompts for TomTom login)
az-aks-get-credentials-prod-user aks21 westeurope
# sets kubectl context to aks21-prod-westeurope

# verify
kubectl get nodes
kubectl get pods -A | grep -E "front12|backend12|front13|backend13"
```

Known prod clusters (from fire drill records):

| Cluster | Region |
|---|---|
| `aks132` | `eastus` |
| `aks136` | `westeurope` |
| `aks153` | `westus2` |

---

## Deactivate roles when done

```bash
# list active schedule instance IDs
az rest \
  --method GET \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleRequests?api-version=2020-10-01&\$filter=asTarget()" \
  --query "value[?properties.status=='Provisioned'].{Name:name, Role:properties.expandedProperties.roleDefinition.displayName}" \
  -o table

# deactivate by request name
az rest \
  --method PUT \
  --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleRequests/$(uuidgen)?api-version=2020-10-01" \
  --body "{
    \"properties\": {
      \"principalId\": \"$MY_PRINCIPAL_ID\",
      \"roleDefinitionId\": \"$VM_LOGIN_ID\",
      \"requestType\": \"SelfDeactivate\"
    }
  }"
```

Repeat with `$READER_ID`, `$AKS_CONTRIB_ID`, and `$CONTRIBUTOR_ID` as needed.

---

## Quick reference

| What | Command |
|---|---|
| Show current account | `az account show` |
| List eligible roles | `az rest --method GET --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleEligibilityScheduleInstances?api-version=2020-10-01&\$filter=asTarget()" --query "value[].properties.expandedProperties.roleDefinition.displayName" -o tsv` |
| List active roles | `az rest --method GET --url "https://management.azure.com/subscriptions/2c48294f-c12f-4cd5-8c1a-b57f43e6fa43/providers/Microsoft.Authorization/roleAssignmentScheduleInstances?api-version=2020-10-01&\$filter=asTarget()" --query "value[].{Role:properties.expandedProperties.roleDefinition.displayName,Expires:properties.endDateTime}" -o table` |
| SSH to jumphost | `az ssh vm --ip jumphost.prod.batch.tt4.nl -- -tA` |
| SSH to backup jumphost | `az ssh vm --ip jumphost2.prod.batch.tt4.nl -- -tA` |
| Clear stale SSH host key | `ssh-keygen -R jumphost.prod.batch.tt4.nl` |
| PIM approval page | `https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/azurerbac` |
| NOC Slack channel | `#noc-pim-request` |
