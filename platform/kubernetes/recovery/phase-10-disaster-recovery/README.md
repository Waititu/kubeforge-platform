# Phase 10 — Disaster Recovery and Failure Engineering

## Scope and safety

All scenarios are isolated to `kubeforge-dr-lab`. Do not run these commands
against production workloads or the existing `kubeforge` storage claims.
No cloud resources are created. The exercises use the local `local-path`
StorageClass and consume local cluster disk.

## Deploy

From the repository root:

```bash
kubectl apply -k platform/kubernetes/recovery/phase-10-disaster-recovery
kubectl -n kubeforge-dr-lab rollout status deployment/dr-web --timeout=180s
kubectl -n kubeforge-dr-lab get pods,pvc
```

The two claims are bound when a pod first uses them. If they remain Pending,
inspect the local-path provisioner and PVC events before continuing.

## Scenario A — Controller self-healing

```bash
bash scripts/phase-10-recovery.sh self-heal
```

Pass criteria: the Deployment returns to two ready replicas. The reported
elapsed time is a lab measurement, not an availability SLA.

## Scenario B — Failed release and rollback

```bash
bash scripts/phase-10-recovery.sh rollback
```

The script temporarily changes only `kubeforge-dr-lab/dr-web` to an
intentionally nonexistent image tag. It waits for rollout failure and rolls
back to the recorded known-good image. Do not interrupt the script after
failure injection; if interrupted, recover with:

```bash
kubectl -n kubeforge-dr-lab rollout undo deployment/dr-web
kubectl -n kubeforge-dr-lab rollout status deployment/dr-web --timeout=180s
```

## Scenario C — Backup and restore integrity

```bash
bash scripts/phase-10-recovery.sh data-recovery
```

The Job writes a test record to one PVC, copies it to the second PVC, removes
the primary copy, restores it, and compares the restored content. This
validates a file-level exercise only. It is not an application-consistent
database backup or an independent off-cluster disaster recovery copy.

## Evidence and objectives

Record each run's date, scenario, result, elapsed seconds, and any relevant
events in the portfolio notes. Recovery Time Objective (RTO) is the target
time to restore service. Recovery Point Objective (RPO) is the acceptable
amount of data loss measured in time. These labs establish observed recovery
times and integrity for narrow scenarios; do not claim production RTO/RPO
until repeated measurements and application-level tests support them.

## Inspect

```bash
bash scripts/phase-10-recovery.sh status
kubectl -n kubeforge-dr-lab get events --sort-by=.lastTimestamp
```

## Cleanup

First inspect the namespace and confirm it contains only Phase 10 resources:

```bash
kubectl get all,pvc -n kubeforge-dr-lab
kubectl get namespace kubeforge-dr-lab --show-labels
```

After saving evidence, delete only the dedicated lab namespace:

```bash
kubectl delete namespace kubeforge-dr-lab
```

PVC reclaim behavior is controlled by the local StorageClass/PV. Confirm
that lab-owned persistent volumes and node-local files are no longer needed
before cleanup. Never delete PVs or storage directories belonging to other
namespaces.
