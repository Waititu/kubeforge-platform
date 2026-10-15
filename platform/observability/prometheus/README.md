# KubeForge local observability

This directory deploys a small, resource-limited Prometheus instance for
the local Kubernetes lab.

## Components

- Prometheus with six-hour retention and a 128 MB TSDB retention limit
- Prometheus self-scrape
- Argo Rollouts metrics
- ingress-nginx controller metrics

## Prerequisites

- A working local Kubernetes cluster
- kubectl configured for the intended cluster
- An ingress-nginx controller Deployment in namespace ingress-nginx
- The Argo Rollouts metrics Service in namespace argo-rollouts

## Validate and deploy Prometheus

Render and inspect the manifests:

    kubectl kustomize platform/observability/prometheus

Validate against the API server without changing resources:

    kubectl apply --dry-run=server -k platform/observability/prometheus

Apply:

    kubectl apply -k platform/observability/prometheus

## Enable ingress-nginx metrics

The controller patch is intentionally separate because the ingress-nginx
Deployment is not managed by this directory's Kustomize resources.

Back up the current Deployment before applying the patch:

    mkdir -p /tmp/kubeforge-phase12
    kubectl get deployment ingress-nginx-controller -n ingress-nginx -o yaml \
      > /tmp/kubeforge-phase12/ingress-nginx-controller.before-metrics-patch.yaml

Review the patch:

    cat platform/observability/prometheus/ingress-nginx-controller-metrics-patch.yaml

Apply it:

    kubectl patch deployment ingress-nginx-controller \
      -n ingress-nginx \
      --type=strategic \
      --patch-file platform/observability/prometheus/ingress-nginx-controller-metrics-patch.yaml

Wait for recovery:

    kubectl rollout status deployment/ingress-nginx-controller \
      -n ingress-nginx --timeout=180s

The patch replaces the controller's argument and port lists with the
versioned lists in the patch file. Review these lists against the live
Deployment before applying after any controller upgrade.

## Verify

    kubectl get pods -n kubeforge-observability
    kubectl get service prometheus -n kubeforge-observability
    kubectl get service ingress-nginx-metrics -n ingress-nginx
    kubectl get endpointslice -n ingress-nginx \
      -l kubernetes.io/service-name=ingress-nginx-metrics

Port-forward Prometheus in one terminal:

    kubectl port-forward -n kubeforge-observability service/prometheus 19090:9090

In another terminal, check target health:

    curl -fsS 'http://127.0.0.1:19090/api/v1/targets?state=active'

All three scrape jobs should report health "up":
- prometheus
- argo-rollouts
- ingress-nginx

Example PromQL query for ingress traffic:

    sum by (host, ingress, status) (nginx_ingress_controller_requests)

Metrics may not include a particular request series until traffic has
actually reached the relevant ingress.

## Cost and safety

- Intended for the local lab; no cloud resources are created.
- Prometheus uses bounded CPU/memory and local ephemeral storage.
- The ingress controller patch can interrupt traffic during recreation.
- Preserve the existing NodeGrid and Traefik ingress configurations.
- Do not commit cluster credentials, Secrets, or generated runtime data.
