# Phase 05 — Security and Governance

## Objectives

- Demonstrate least-privilege namespace-scoped RBAC.
- Enforce the Restricted Pod Security Standard in an isolated lab namespace.
- Apply a ValidatingAdmissionPolicy to reject insufficiently hardened Pods.
- Verify both allowed and denied operations.
- Practice safe handling of Kubernetes Secrets without committing credentials.

## Files

- `security-baseline.yaml`: isolated namespace, ServiceAccount, Role,
  RoleBinding, ValidatingAdmissionPolicy and its binding.
- `hardened-pod.yaml`: a minimal compliant workload.

## RBAC model

The `app-reader` ServiceAccount can get, list and watch Pods and Services
inside `kubeforge-security-lab`. It has no permission to read Secrets,
create Deployments, or access Pods in other namespaces.

The ServiceAccount does not automatically mount an API token into its Pod.
Administrative impersonation tests use the operator's credentials.

## Admission controls

The lab namespace enforces Pod Security Admission at `restricted`.
The additional ValidatingAdmissionPolicy requires non-root execution,
RuntimeDefault seccomp, disabled privilege escalation, a read-only root
filesystem, and dropping all Linux capabilities for application containers.

The binding selects only namespaces labeled
`kubeforge.security/enforce: "true"`. Do not add this label to unrelated
namespaces without reviewing workload compatibility.

## Verification

1. Server-side dry-run both manifests.
2. Apply the baseline and compliant Pod.
3. Wait for the compliant Pod to become Ready.
4. Verify allowed and denied RBAC actions with `kubectl auth can-i`.
5. Confirm a noncompliant Pod is rejected by server-side dry-run.
6. Confirm the Secret is inaccessible to `app-reader`.
7. Verify nodes, existing workloads, and NodeGrid ingress.

## Secret safety

Never commit real credentials. Base64 is not encryption. The disposable
Secret exercise uses a fake value and does not prove encryption at rest.
Do not use this local lab as a production secret-management design.

## Storage and rollback safety

This phase does not change Phase 04 storage resources or delete any PVCs.
The lab namespace and its dummy Secret are intentionally left in place for
inspection. Remove them only when ready to discard the exercise.

## Limitations

This is a local educational control plane, not a complete production security
program. Production readiness also requires identity integration, audit-log
retention, secret encryption and rotation, image provenance/scanning,
vulnerability management, and a tested incident-response process.
