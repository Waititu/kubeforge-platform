# Phase 08 — Deployment Strategies and Release Safety

## Objectives

- Deploy a healthy three-replica application.
- Perform a rolling update with maxSurge=1 and maxUnavailable=0.
- Observe a deliberately failed image update in this isolated namespace.
- Prove the healthy replicas remain available during the failed update.
- Roll back to the last healthy revision and verify the HTTP response.
- Preserve existing labs, NodeGrid, and storage resources.

## Resources

- `namespace.yaml`: isolated namespace with Restricted Pod Security Admission.
- `release-demo.yaml`: Deployment, Service, probes, resource bounds, and rollout policy.
- `disruption-budget.yaml`: protects at least two available replicas.

## Rollout policy

`maxSurge: 1` permits one extra Pod during an update.
`maxUnavailable: 0` prevents the Deployment controller from intentionally
reducing the available replica count during a rolling update.

These settings do not guarantee application availability during node failures,
cluster-wide outages, or failures outside the Deployment controller's control.

## Apply and verify

Validate manifests before applying them. Apply the namespace first, then the
namespaced resources. Follow the Phase 08 runbook used during the lab exercise
for successful updates, failure injection, rollback, and final checks.

## Safety

- The deliberately invalid image tag must only be applied to this lab Deployment.
- Never use `kubectl delete pod` as a substitute for testing a PDB eviction.
- Do not drain nodes, alter cluster-wide configuration, or change NodeGrid.
- Do not commit unrelated working-tree changes.
- The `emptyDir` content is ephemeral and is not application data storage.
