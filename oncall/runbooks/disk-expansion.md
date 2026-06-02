# Disk Expansion Runbook

Source: [Confluence — How to update allocated resources - expand disk](https://tomtom.atlassian.net/wiki/spaces/~233897990/pages/233915836)

## When to Use

Trigger this runbook when:

- A [Grafana](https://grafana.com/docs/grafana/latest/) alert fires for disk pressure on an [Apache Pulsar](https://pulsar.apache.org/docs/) node (bookie or zookeeper).
- A [PVC (PersistentVolumeClaim)](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) is at or near capacity, causing Pulsar [bookies](https://bookkeeper.apache.org/) to stop accepting writes.
- The batch service degrades or returns errors attributable to storage exhaustion (e.g. Pulsar bookie ledger disk full).
- An on-call alert references a [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) volume claim running out of space.

Typical affected components: `pulsar-bookie` (ledger or journal disks), `pulsar-zookeeper` data disks.

## Prerequisites

- **[Azure PIM](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure) access** — elevated [AKS](https://learn.microsoft.com/en-us/azure/aks/) credentials for the target cluster are required. Request PIM via the standard process (Confluence page 233902249) and wait for approval before proceeding.
- **kubectl via jumphost** — connect to the Jumphost (Confluence page 233902100) and run kubectl from there. Direct cluster access from a local machine is not available in production.
- **AZ CLI** — authenticate `az` so it can call `az aks get-credentials`.
- **Resize one replica at a time.** Never resize all replicas simultaneously — stopping multiple bookies at once risks data loss.

## Procedure

The example below uses these parameters; substitute real values for your incident:

| Parameter | Example value |
|---|---|
| Resource group / cluster name | `pulsaradr4-dev-westeurope` |
| StatefulSet namespace | `default` |
| StatefulSet name | `pulsar-bookie` |
| Volume claim prefix | `pulsar-bookie-ledgers-pulsar-bookie` |
| Current disk size | `64Gi` |
| Target disk size | `104Gi` |

### 1. Set kubectl context

```bash
az aks get-credentials -g pulsaradr4-dev-westeurope -n pulsaradr4-dev-westeurope
```

### 2. Back up the StatefulSet definition

```bash
kubectl -n default get statefulsets.apps pulsar-bookie -o yaml > pulsar-bookie-statefulset.yaml
```

### 3. Edit the backup file — update disk size

Open `pulsar-bookie-statefulset.yaml`, find the `volumeClaimTemplates` section, locate the entry for the target volume claim, and set `storage` to the new target size (e.g. `104Gi`).

### 4. Verify all replicas are healthy before starting

```bash
kubectl -n default describe statefulsets.apps pulsar-bookie | grep -E "^Replicas"
```

The "desired" count must equal the "total" count. If they differ, investigate and resolve the discrepancy before proceeding.

### 5. Repeat the following block for each replica (0, 1, 2, ...)

Replace `0` with the current replica index in every command below.

#### 5a. Delete the StatefulSet definition (without cascading to pods)

```bash
kubectl -n default delete statefulsets.apps pulsar-bookie --cascade=false
```

Wait for the deletion confirmation message before continuing. The `--cascade=false` flag keeps the running pods alive while removing the StatefulSet controller.

#### 5b. Delete the target pod

```bash
kubectl -n default delete pod pulsar-bookie-0
```

#### 5c. Confirm the pod is gone

```bash
kubectl -n default get pod | sed '1p;/pulsar-bookie-0/!d'
```

Wait until no rows appear for `pulsar-bookie-0`. Re-run the command if needed.

#### 5d. Identify and edit the target PVC

List all PVCs to confirm the correct name:

```bash
kubectl -n default get pvc
```

Edit the PVC for the current replica:

```bash
kubectl -n default edit pvc pulsar-bookie-ledgers-pulsar-bookie-0
```

Under `spec.resources.requests.storage`, set the value to the target size (e.g. `104Gi`). Save and exit.

#### 5e. Wait for the PVC resize to be acknowledged

```bash
kubectl -n default describe pvc pulsar-bookie-ledgers-pulsar-bookie-0
```

Check the `Conditions` section. Wait until it shows:

> Waiting for user to (re-)start a pod to finish system resize of volume on node.

#### 5f. Recreate the StatefulSet

```bash
kubectl apply -f pulsar-bookie-statefulset.yaml
```

Wait for the apply confirmation before continuing.

#### 5g. Confirm the pod is back and healthy

```bash
kubectl -n default get pod | sed '1p;/pulsar-bookie-0/!d'
```

Wait until all containers show `Ready` (e.g. `2/2`) and status is `Running`.

Return to step 5a for the next replica index.

## Verification

After all replicas are resized:

```bash
kubectl -n default get pvc
```

Verify that every target PVC shows the new capacity in the `CAPACITY` column.

```bash
kubectl -n default get statefulsets.apps pulsar-bookie
```

Verify that `READY` matches the expected replica count and no pods are in a crash loop.

Check Pulsar bookie health:

```bash
kubectl -n default exec pulsar-bookie-0 -- bin/bookkeeper shell bookiesanity
```

## Monitoring

Watch the following in Grafana after completing the procedure:

- **Grafana (Batch):** <https://grafana.prod.batch.tt4.nl> — check Pulsar bookie disk usage panels to confirm the new capacity is reflected and utilisation has dropped below the alert threshold.
- **Grafana Cloud Logs:** <https://grafana.tomtomgroup.com> — filter on the Pulsar namespace to verify no bookie error logs persist after the resize.
- **Grafana (APIM):** <https://grafana.api-system.tomtom.com> — confirm batch request error rates have returned to baseline, indicating the service recovered from any disk-pressure-induced failures.

If disk utilisation climbs back quickly, increase the target size further or investigate what is consuming storage faster than expected.
