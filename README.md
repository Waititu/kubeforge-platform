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
