# Playbook Master Guide

End-to-end execution map for this repository using generated Docsible documentation.

## Primary Flow

1. Control plane bootstrap: `docs/generated/site.md`
2. VPS agent bootstrap: `docs/generated/site-vps.md`
3. Role-level implementation details: `roles/*/README.md`

## Where To Insert New Tasks

| Goal | Insert In | Why |
| ---- | --------- | --- |
| Host prerequisites on master | `site.yaml` Play `Setup K3s Master Node`, PHASE 1 | Runs before cluster initialization |
| Cluster bootstrap sequencing | `site.yaml` Play `Setup K3s Master Node`, PHASE 2 | Defines control-plane bring-up order |
| Infra platform services | `site.yaml` Play `Setup K3s Master Node`, PHASE 3 | Cert-manager, secrets, gateway stack |
| GitOps controller changes | `site.yaml` Play `Deploy ArgoCD GitOps` | ArgoCD deployment and sync behavior |
| VPS edge/agent behavior | `site-vps.yaml` Play `Setup K3s VPS Agent Node` | Agent join and route advertisement |

## Role Docs

- `roles/argocd/README.md`
- `roles/cert_manager/README.md`
- `roles/cilium/README.md`
- `roles/common/README.md`
- `roles/crds_bootstrap/README.md`
- `roles/developer_tools/README.md`
- `roles/external_secrets/README.md`
- `roles/gateway/README.md`
- `roles/gvisor/README.md`
- `roles/k3s_agent/README.md`
- `roles/k3s_common/README.md`
- `roles/k3s_server/README.md`
- `roles/miners/README.md`
- `roles/nvidia_gpu/README.md`
- `roles/preflight/README.md`
- `roles/tailscale/README.md`
