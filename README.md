# KubeForge — Production Platform Engineering Lab

KubeForge is a local-first Kubernetes platform engineering project
for learning production operations through a commerce and inventory
application.

## Objectives

- Kubernetes workloads, scheduling, and resource management
- Services, DNS, ingress, and network policies
- Configuration, secrets, and workload identity
- Persistent storage and stateful services
- Rollouts, availability, and autoscaling
- Monitoring, alerting, and troubleshooting
- Helm-based packaging and GitOps delivery
- Cluster security, upgrades, backup, and recovery
- Advanced networking and multi-cluster operations

## Environment

- macOS on Apple silicon
- Vagrant and VirtualBox
- Three-node Ubuntu Kubernetes cluster
- Kubernetes v1.37.0
- containerd and Flannel

## Safety

KubeForge must remain isolated from existing NodeGrid and
multicloud-platform workloads. Never perform destructive cluster-wide
operations as part of routine project development.

## Local validation and CI

KubeForge's validation workflow checks YAML syntax, renders every
tracked Kustomize root, lints and renders Helm charts, validates
rendered Kubernetes resources against schemas, and applies a
production-focused security policy to the release-demo production
overlay.

The checks are validation-only. They do not run `kubectl apply`,
connect to the cluster, or create cloud resources. Custom resources
whose schemas are not available to Kubeconform are skipped by the
schema check; YAML syntax and Kustomize rendering still apply.

### Prerequisites

- Git
- Python 3 and pip
- `kubectl`
- Helm
- Kubeconform

On macOS with Homebrew:

```bash
brew install kubeconform
python3 -m venv /tmp/kubeforge-ci-venv
/tmp/kubeforge-ci-venv/bin/python -m pip install PyYAML==6.0.2
