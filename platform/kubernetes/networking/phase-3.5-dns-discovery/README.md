# Phase 03.5 — DNS and Service Discovery

## Objectives

- Verify Kubernetes Service discovery using short names and fully qualified
  domain names (FQDNs).
- Verify discovery of the Kubernetes API Service.
- Inspect the DNS Service, CoreDNS endpoints, and application EndpointSlices.
- Demonstrate DNS and application connectivity under an explicit egress policy.
- Keep the lab client non-root and restrict its network access.
- Preserve existing CoreDNS configuration, ingress controllers, and workloads.

## Architecture

Namespace: `kubeforge`

Resources:
- `network-dns-client` Deployment: one restricted BusyBox DNS test client.
- `network-dns-client-egress` NetworkPolicy: allows DNS queries to CoreDNS
  pods on TCP/UDP 53 and application traffic to `network-echo` on TCP 8080.
- `network-echo-ingress-allow-dns-client` NetworkPolicy: permits the lab
  client to reach the echo pods on TCP 8080.

The client uses the cluster's normal Pod DNS configuration. CoreDNS remains
managed in `kube-system`; its Corefile is not modified.

## Prerequisites

- The `kubeforge` namespace, `network-echo` Service, and echo Deployment exist.
- CoreDNS and the cluster DNS Service are healthy.
- The cluster's NetworkPolicy controller is operational.
- The cluster can retrieve `busybox:1.37.0`, unless the image is already cached.

## Deploy

From the repository root:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" apply \
      --dry-run=server -f \
      platform/kubernetes/networking/phase-3.5-dns-discovery/dns-and-discovery.yaml

    kubectl --kubeconfig="$HOME/.kube/kubeforge" apply \
      -f platform/kubernetes/networking/phase-3.5-dns-discovery/dns-and-discovery.yaml

Wait for the test client:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge rollout status deployment/network-dns-client \
      --timeout=120s

## Verification

Inspect CoreDNS and its Service endpoints:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kube-system get deployment coredns pods -o wide

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kube-system get service kube-dns

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kube-system get endpointslice \
      -l kubernetes.io/service-name=kube-dns

Test Service name resolution from the lab client:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge exec deployment/network-dns-client -- \
      nslookup network-echo

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge exec deployment/network-dns-client -- \
      nslookup network-echo.kubeforge.svc.cluster.local

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge exec deployment/network-dns-client -- \
      nslookup kubernetes.default.svc.cluster.local

The first two queries should resolve the same `network-echo` Service ClusterIP.
The third should resolve the Kubernetes API Service ClusterIP.

Verify the expected negative DNS case:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge exec deployment/network-dns-client -- \
      nslookup definitely-missing-kubeforge-service.kubeforge.svc.cluster.local

This lookup should report that the name cannot be resolved. Confirm the
negative result from the DNS output; do not interpret a failed command alone
as proof of NXDOMAIN if the output instead indicates a timeout.

Verify application connectivity:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge exec deployment/network-dns-client -- \
      wget -q -T 5 -O - http://network-echo/

The request should return the NGINX welcome page.

Inspect application endpoint readiness:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge get endpointslice \
      -l kubernetes.io/service-name=network-echo -o wide

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge get endpointslice \
      -l kubernetes.io/service-name=network-echo \
      -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{" ready="}{.conditions.ready}{"\n"}{end}'

Inspect the lab's policies:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge describe networkpolicy network-dns-client-egress

    kubectl --kubeconfig="$HOME/.kube/kubeforge" \
      -n kubeforge describe networkpolicy network-echo-ingress-allow-dns-client

## Acceptance criteria

- All three resources pass server-side dry-run validation.
- The lab Deployment becomes Available.
- Short-name and FQDN lookups resolve to the expected Services.
- The nonexistent Service produces a DNS negative result, not a timeout.
- The lab client reaches `network-echo`.
- EndpointSlices show ready echo endpoints.
- Existing NodeGrid and ingress controllers remain healthy.
- No CoreDNS configuration or unrelated workload is changed.

## Security notes

The egress policy is intentionally restrictive. It permits the specified DNS
and echo destinations only; it does not grant general Internet egress.
The cluster's existing ingress NetworkPolicies remain additive.

This lab tests Service discovery and DNS access under policy enforcement.
It does not change CoreDNS replica placement or establish cross-node DNS
high availability.

## Cleanup

Remove only this phase's resources:

    kubectl --kubeconfig="$HOME/.kube/kubeforge" delete \
      -f platform/kubernetes/networking/phase-3.5-dns-discovery/dns-and-discovery.yaml

The cleanup removes the test Deployment and the two policies introduced here.
It does not delete the namespace, the echo Service, CoreDNS, or ingress
controllers.

## Git delivery

Review and stage only this phase directory. Do not stage `platform/storage/`.

    git diff --check
    git add platform/kubernetes/networking/phase-3.5-dns-discovery/
    git diff --cached --check
    git diff --cached --name-status
    git diff --cached --stat

After all acceptance tests pass:

    git commit -m "feat(networking): add DNS and service discovery lab"
    git log -1 --oneline
    git status --short
