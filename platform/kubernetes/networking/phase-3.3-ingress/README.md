# Phase 03.3 — Ingress and HTTP Routing

## Goals

- Deploy a version-pinned Traefik Ingress controller.
- Preserve the existing ingress-nginx controller and NodeGrid route.
- Demonstrate host-based routing and longest-prefix path matching.
- Verify NetworkPolicy enforcement between Traefik and backend Pods.
- Expose HTTP and HTTPS entrypoints using dedicated NodePorts.

## Architecture

- Helm chart: traefik/traefik 41.4.0
- Traefik Proxy version: v3.7.12
- Controller namespace: traefik
- IngressClass: traefik (not the default class)
- HTTP NodePort: 30080
- HTTPS NodePort: 30443
- Existing ingress-nginx NodePorts: 32061 and 32318
- Existing NodeGrid IngressClass: nginx

## Routes

| Host | Path | Backend |
| --- | --- | --- |
| echo.kubeforge.test | / | network-echo |
| echo.kubeforge.test | /route-check | network-route-backend |
| path-only.kubeforge.test | /route-check | network-route-backend |

The longest matching path wins. The path-only host is used to test a
404 response for an unmatched path.

## NetworkPolicy

The existing network-echo-ingress-allow-client policy is retained.
Additional policies allow Traefik Pods in the traefik namespace to
reach the selected backend Pods on TCP 8080 only.

## Installation

See the phase implementation instructions in the project history.
Install with Helm chart version 41.4.0 and this directory's
traefik-values.yaml.

## Cleanup

Remove the two Ingress resources and the route backend/policies with
kubectl delete -f, uninstall the traefik Helm release, and then remove
the now-unused traefik namespace. Do not delete ingress-nginx or
change the existing NodeGrid Ingress.
