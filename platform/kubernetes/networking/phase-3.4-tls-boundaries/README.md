# Phase 03.4 — TLS and Traffic Boundaries

## Objectives

- Terminate HTTPS at Traefik using a Kubernetes TLS Secret.
- Redirect HTTP requests to HTTPS using a Traefik Middleware.
- Keep HTTP and HTTPS routers separate and explicitly configured.
- Keep application Services internal using ClusterIP.
- Preserve the existing NGINX Ingress controller and NodeGrid routing.
- Verify certificate trust, Subject Alternative Names (SANs), redirect
  locations, unauthorized traffic denial, and ingress regression behavior.

## Architecture

- Traefik HTTP NodePort: 30080
- Traefik HTTPS NodePort: 30443
- Internal Services: network-echo and network-route-backend (ClusterIP)
- TLS Secret: kubeforge/kubeforge-lab-tls
- Redirect Middleware: kubeforge/https-redirect
- Test hostnames: echo.kubeforge.test and path-only.kubeforge.test

## Certificate handling

Generate a local CA and server certificate under
`$HOME/.local/share/kubeforge/phase-3.4-tls`. Do not store private keys
or generated certificate artifacts in this repository.

The CA private key remains local. Only the server certificate and key
are stored in the Kubernetes TLS Secret. Trust the CA explicitly in
local tests; do not disable certificate validation for the HTTPS tests.

This is a lab PKI, not a publicly trusted production certificate.

## Apply

After generating the certificate and creating the Secret:

```bash
kubectl apply --dry-run=server -f tls-and-redirect.yaml
kubectl apply -f tls-and-redirect.yaml
```

## Verification

Verify:
- Both HTTPS hosts return valid certificates when the lab CA is trusted.
- Certificate SANs include both test hostnames.
- HTTP requests redirect to HTTPS on port 30443.
- The route backend marker is returned through HTTPS.
- Unknown hosts and unmatched paths return 404.
- Backend Services remain ClusterIP.
- NodeGrid continues to respond through the existing NGINX Ingress.
- Authorized network-client traffic works and unauthorized backend traffic
  remains blocked by NetworkPolicy.

## Cleanup

To remove only Phase 03.4 ingress and middleware resources:

```bash
kubectl -n kubeforge delete ingress \
  network-echo-tls path-only-tls network-echo path-only
kubectl -n kubeforge delete middleware https-redirect
kubectl -n kubeforge delete secret kubeforge-lab-tls
```

The cleanup commands above remove the Phase 03.3 ingress resources too;
reapply `phase-3.3-ingress/ingress-routes.yaml` if you want to restore the
HTTP-only baseline. They do not delete Services, Deployments, or NetworkPolicies.
