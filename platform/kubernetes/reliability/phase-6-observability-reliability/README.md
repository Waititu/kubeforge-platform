# Phase 06 — Observability and Reliability

## Objectives

- Observe Kubernetes nodes, workloads, metrics, events and logs.
- Implement startup, readiness and liveness probes.
- Apply CPU and memory requests and limits.
- Demonstrate readiness failure and recovery.
- Demonstrate liveness-triggered container restart.
- Verify Deployment controller recovery after Pod deletion.
- Preserve unrelated cluster workloads and storage.

## Files

- `namespace.yaml`: isolated lab namespace with Restricted Pod Security
  Admission labels.
- `reliability-demo.yaml`: one-replica Deployment with explicit resource
  controls, hardened security settings, probes and a temporary emptyDir.

## Health-check behavior

The BusyBox test process creates two marker files on startup.

- `/work/ready` controls startup and readiness checks.
- `/work/live` controls liveness checks.

Removing the readiness marker should make the Pod unready without restarting
the container. Restoring it should make the Pod ready again.

Removing the liveness marker should cause failed liveness probes and a
container restart. The container entrypoint recreates both markers.

These marker-file checks simulate health failures; they do not establish
application-level health for a real service.

## Verification

1. Validate the manifests with server-side dry-run.
2. Wait for the Deployment to become available.
3. Inspect node and Pod metrics when the Metrics API is available.
4. Verify the readiness failure and restoration.
5. Verify the liveness-triggered restart count increases.
6. Delete the lab Pod and verify its Deployment replacement becomes ready.
7. Inspect events, logs, resource settings and Pod conditions.
8. Verify existing nodes, KubeForge workloads, NodeGrid and ingress remain
   healthy.

## Resource and cost controls

The lab uses one Pod, 25m CPU and 16Mi memory requests, and 100m CPU and
32Mi memory limits. It runs in the existing local Kubernetes cluster and
does not create cloud resources.

## Security

The workload runs as a non-root user, disables privilege escalation, drops
all Linux capabilities, uses RuntimeDefault seccomp, has a read-only root
filesystem, and does not mount a ServiceAccount token.

## Rollback

After saving any evidence you want to retain, the entire lab can be removed
with:

`kubectl --kubeconfig="$HOME/.kube/kubeforge" delete namespace kubeforge-reliability-lab`

This deletes only the dedicated Phase 06 namespace and its resources.

## Limitations

The emptyDir is ephemeral and is not persistent storage. Marker-file probes
are educational simulations, not production application checks. Metrics
collection depends on a functioning Metrics API. A production observability
platform would additionally need durable metric storage, dashboards, alerting,
log retention, tracing where appropriate, and tested incident procedures.
