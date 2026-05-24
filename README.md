# k3s-homelab

[![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=rou-cru_k3s-homelab)](https://sonarcloud.io/summary/new_code?id=rou-cru_k3s-homelab)

Ansible playbooks that provision a single-node K3s homelab on bare metal, with optional VPS edge agent. Includes system tuning, Tailscale mesh networking, Cilium CNI, NVIDIA GPU support, and cryptocurrency mining workloads.

## Quick Start

### Prerequisites

- [devbox](https://www.jetify.com/devbox/) — manages the development environment
- Python 3.12 (installed via devbox)
- Ansible and dependencies (installed via devbox + uv)

### Getting Started

```bash
# Enter the devbox shell
devbox shell

# Run the full CI pipeline (format check + validation)
task ci-full
```

All tooling runs through [go-task](https://taskfile.dev/). Enter the devbox shell first, then use `task` for all operations.

## Architecture

This project uses Ansible to provision and manage a Kubernetes homelab with the following components:

| Component | Purpose |
|-----------|---------|
| **K3s** | Lightweight Kubernetes distribution, single-node control plane |
| **Cilium CNI** | Container networking, ingress, and load balancing (replaces Traefik and ServiceLB) |
| **Tailscale** | Mesh networking for secure node-to-node communication |
| **NVIDIA GPU** | Optional GPU passthrough with device plugin for GPU workloads |
| **gVisor** | Container runtime for sandboxed workloads |
| **cert-manager** | Certificate management with self-signed CA and ACME/Let's Encrypt |
| **External Secrets** | OCI Vault integration for secret management |
| **ArgoCD** | GitOps controller for ongoing cluster state management |
| **Mining Workloads** | CPU and GPU cryptocurrency miners as Kubernetes deployments |

### Execution Flow

The main `site.yaml` playbook runs four plays in sequence:

1. **Setup K3s Master Node** — bootstrap, system tuning, K3s install, Cilium, cert-manager, gateway, secrets, GPU
2. **Deploy Mining Workloads** — CPU/GPU miners as K3s workloads
3. **Import VPS Playbook** — conditionally runs `site-vps.yaml` if a `vps` group exists in inventory
4. **Deploy ArgoCD GitOps** — ArgoCD controller for ongoing cluster state management

## Key Commands

| Goal | Command |
|------|---------|
| Run full CI (validate + format check) | `task ci-full` |
| Quick check (syntax only) | `task ci-quick` |
| Validate all files | `task validate` |
| Format all files | `task format` |
| Generate role docs | `task docs:generate` |
| Deploy Cilium via Helm | `task k8s:bootstrap:cilium` |
| Build miner images | `task build:miners` |
| Clean rendered/cache files | `task clean` |
| Interactive secrets setup | `task secrets:setup` |
| List all tasks | `task` |

## Directory Structure

```
k3s-homelab/
├── roles/                  # Ansible roles
│   ├── bootstrap_master/   # Master node orchestration
│   ├── bootstrap_vps/      # VPS agent orchestration
│   ├── validate_secrets/  # Shared pre-flight checks
│   ├── k3s_server/         # K3s server binary install
│   ├── k3s_agent/          # K3s agent binary install
│   ├── k3s_common/         # Shared K3s config
│   ├── cilium/             # Cilium CNI via Helm
│   ├── cert_manager/       # cert-manager + CA + ACME
│   ├── gateway/            # Kubernetes Gateway API
│   ├── external_secrets/   # External Secrets Operator
│   ├── argocd/             # ArgoCD GitOps controller
│   ├── nvidia_gpu/         # NVIDIA driver + device plugin
│   ├── gvisor/             # gVisor runtime
│   ├── tailscale/          # Tailscale mesh networking
│   ├── miners/             # Mining workload deployments
│   ├── preflight/          # Hardware/resource validation
│   └── common/             # System-level setup
├── k8s/
│   ├── bootstrap/          # Raw Kubernetes manifests for bootstrap
│   └── gitops/             # ArgoCD-managed application definitions
├── group_vars/             # Ansible variables (all.yml = master defaults)
├── .github/                # GitHub Actions (SonarQube scan on push to main)
├── .task/                  # Taskfile rendered outputs and cache
├── secrets.yaml            # Gitignored credentials and secrets
└── site.yaml               # Main playbook entry point
```

## Operational Documentation

- Master flow: `docs/generated/playbook-master.md`
- Main playbook: `docs/generated/site.md`
- VPS playbook: `docs/generated/site-vps.md`
- Role documentation: `roles/*/README.md`

## Security

- `secrets.yaml` contains real credentials (Tailscale auth keys, Docker Hub tokens, passwords). It is gitignored but lives on disk. Never commit its contents.
- `.ansible_vault_pass` is the vault password file — also gitignored.
- `inventory.ini` contains real IPs. Do not commit changes to these.
