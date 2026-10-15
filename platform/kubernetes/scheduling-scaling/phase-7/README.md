# Phase 07 — Scheduling, Scaling and Workload Resilience

## Objectives
- Constrain application Pods to eligible worker nodes.
- Observe pod anti-affinity and topology-spread behavior.
- Demonstrate CPU-based HorizontalPodAutoscaler behavior.
- Protect a three-replica service with a PodDisruptionBudget.
- Verify bounded resource requests and limits.

## Resources
- namespace.yaml: isolated namespace with Restricted Pod Security Admission.
- scheduling-demo.yaml: three-replica HTTP Deployment and ClusterIP Service.
- autoscaling-demo.yaml: deliberately CPU-bound Deployment and bounded HPA.
- disruption-budget.yaml: require at least two available scheduling-demo replicas.

## Important limitations
- The CPU workload is intentionally busy-looping. Keep the HPA maximum at three.
- HPA utilization is measured relative to CPU requests, not CPU limits.
- A PDB constrains voluntary eviction requests; it cannot prevent node failure,
  and direct Pod deletion does not test PDB enforcement.
- Topology spread uses ScheduleAnyway, so distribution is preferred, not guaranteed.
- Node affinity uses the current lab's worker hostnames and must be reviewed
  if nodes are renamed.
- Do not drain or power off nodes as part of this phase. Existing workloads and
  node-local storage depend on the shared cluster.
- This lab does not modify existing deployments, node taints, or cluster-wide
  configuration.

## Validation
See the repository Phase 07 runbook in the project conversation for apply,
verification, autoscaling observation, eviction testing, cleanup boundaries,
and Git instructions.
