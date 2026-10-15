# Phase 03.2 — Kubernetes NetworkPolicy Enforcement

## Objective

Enforce a namespace-scoped ingress allow-list without replacing the
existing Flannel CNI installation.

## Components

- `controller-v1.1.1.yaml`: Kubernetes SIG Network Policy controller manifest from upstream release v1.1.1; its container image is pinned to v1.1.0.
- `network-echo-ingress.yaml`: permits TCP/8080 ingress to network-echo
  only from pods labelled `app.kubernetes.io/name=network-client`.
- `verification-probes.yaml`: temporary cross-node allowed and denied
  test pods. Apply for verification and delete afterward.

## Expected behavior

| Source | Destination | Expected |
|---|---|---|
| Existing network-client | network-echo Service | Allowed |
| network-client-cross-node on worker 1 | network-echo Service | Allowed |
| network-denied-probe on control plane | network-echo Service | Denied |

The policy selects the echo pods and targets their container port 8080,
not the Service's frontend port 80. It does not define egress restrictions.

## Rollback

1. Delete the NetworkPolicy.
2. Delete temporary verification pods if present.
3. Delete the controller manifest resources.
4. Confirm Flannel remains healthy and the baseline Service request works.

Removing the controller alone would leave NetworkPolicy resources present
but unenforced, so remove the policy first.
