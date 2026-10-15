# Phase 04 — Storage and Stateful Workloads

## Objective

Demonstrate local dynamic volume provisioning, persistent data across pod
recreation, and file-level backup and restore using a separate persistent
volume in the KubeForge Kubernetes lab.

## Components

- `local-path-storage.yaml`: local-path provisioner and StorageClass.
- `statefulset.yaml`: headless Service, StatefulSet, and 1 GiB claim template.
- `restore-test.yaml`: isolated PVC and pod used for restoration testing.

## Apply

Use the kubeconfig for the KubeForge lab.

1. Server-side dry-run and apply `local-path-storage.yaml`.
2. Wait for the local-path provisioner Deployment.
3. Server-side dry-run and apply `statefulset.yaml`.
4. Wait for `statefulset/storage-demo`.
5. Confirm `data-storage-demo-0` is Bound.
6. Write a unique proof file, delete only `storage-demo-0`, and verify the
   recreated pod reads the exact same proof.
7. Back up the proof file outside the repository.
8. Apply `restore-test.yaml`, restore the file to its separate claim, and
   compare the restored content with the backup.

## Safety

- The StorageClass uses reclaimPolicy Delete. Deleting a claim can delete
  its provisioned volume and data.
- Do not delete either claim until the restore test has passed.
- Do not commit backups, private data, cluster credentials, or local
  certificates.
- Local-path storage is node-local. It does not provide replication,
  node-failure tolerance, or automatic cross-node data migration.
- The file-copy exercise is not an application-consistent database backup.
- Review resource quotas and PVC/PV state before cleanup.

## Acceptance criteria

- Provisioner Deployment becomes available.
- StorageClass `local-path` exists.
- `storage-demo-0` becomes Ready and its PVC becomes Bound.
- A unique proof file survives pod deletion and recreation.
- A backup restores successfully to a separate claim.
- NetworkGrid/NodeGrid ingress controllers and unrelated workloads remain
  unaffected.
- YAML server-side dry-runs pass.
- Only intended Phase 04 files are staged and committed.
