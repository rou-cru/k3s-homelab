# AGENTS.md — k3s-homelab

## SDD pending to apply

Engram: sdd/consolidation-phase2/tasks

## ⚠️ Security

- `secrets.yaml` contains **real credentials** (Tailscale auth keys, Docker Hub tokens, passwords). It is gitignored but lives on disk. Never commit, log, or echo its contents.
- `.ansible_vault_pass` is the vault password file — also gitignored, never expose.
- `inventory.ini` has real IPs (LAN `192.168.1.71`, VPS `74.208.250.178`). Do not commit changes to these.

## Quick Commands

All tools are managed via **devbox**. Enter the shell first:
```
devbox shell
```

Then use **go-task** (`task`) for everything:

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

`task validate` and `task format` auto-render Jinja2 templates via task dependencies — do not run `task render-all` manually beforehand.

## Architecture

Ansible playbooks that provision a **single-node K3s homelab** on bare metal, plus an optional **VPS edge agent**. Includes system tuning, Tailscale mesh, Cilium CNI, NVIDIA GPU support, and cryptocurrency mining workloads.

### Execution flow (`site.yaml` — 4 plays, run in order)
1. **Setup K3s Master Node** — bootstrap, system tuning, K3s install, Cilium, cert-manager, gateway, secrets, GPU
2. **Deploy Mining Workloads** — CPU/GPU miners as K8s workloads
3. **Import VPS playbook** — conditionally runs `site-vps.yaml` if `vps` group exists
4. **Deploy ArgoCD GitOps** — ArgoCD controller for ongoing cluster state management

### Key directory boundaries
| Directory | Purpose |
|-----------|---------|
| `roles/bootstrap_master/` | Orchestrator — calls other roles in sequence for master node |
| `roles/bootstrap_vps/` | Orchestrator — calls other roles for VPS agent join |
| `roles/validate_secrets/` | Shared pre-flight checks |
| `roles/k3s_server/` | K3s server binary install and init |
| `roles/k3s_agent/` | K3s agent binary install and join |
| `roles/k3s_common/` | Shared K3s config (containerd, registry auth) |
| `roles/cilium/` | Cilium CNI deployment via Helm |
| `roles/cert_manager/` | cert-manager + self-signed CA + ACME/Let's Encrypt |
| `roles/gateway/` | Kubernetes Gateway API resources |
| `roles/external_secrets/` | External Secrets Operator + OCI Vault integration |
| `roles/argocd/` | ArgoCD GitOps controller |
| `roles/nvidia_gpu/` | NVIDIA driver + device plugin |
| `roles/gvisor/` | gVisor runtime for sandboxed containers |
| `roles/tailscale/` | Tailscale mesh networking |
| `roles/miners/` | Mining workload deployments |
| `k8s/bootstrap/` | Raw Kubernetes manifests applied during bootstrap |
| `k8s/gitops/` | ArgoCD-managed application definitions |
| `group_vars/` | Ansible variables — `all.yml` is the master defaults file |

## Conventions

- **Become is play-level**, not global. `group_vars/all.yml` explicitly does NOT set `ansible_become`.
- **`secrets_file` variable** defaults to `secrets.yaml` but can be overridden (e.g., for syntax checks using mock secrets).
- **`k3s_recreate: false`** by default — set to `true` only for full cluster rebuilds.
- **Traefik and ServiceLB are disabled** — Cilium handles both ingress and load balancing.
- **Cilium native routing CIDR** is `10.0.0.0/8` — must match across all nodes and Helm values.
- **Tailscale SNAT is disabled** to preserve source IPs for Cilium native routing visibility.
- **Fact caching** uses jsonfile to `/tmp/ansible_facts` with 1-hour timeout.
- **Ansible paths are repo-local** — `devbox.json` sets `ANSIBLE_COLLECTIONS_PATH` and `ANSIBLE_ROLES_PATH` to `$workspaceFolder/.ansible/collections` and `$workspaceFolder/roles`. Collections install locally, not globally.

## Validation

- `task validate` runs `yamllint`, `checkov` (Ansible framework), `ansible-playbook --syntax-check`, `j2lint`, and `shellcheck` on rendered bash scripts.
- `task ci-quick` skips yamllint/checkov/j2lint and runs only Ansible syntax + bash checks.
- `ansible-playbook --syntax-check` uses a mock `secrets.yaml` copied from `secrets.example.yaml`. Tasks guarded by `when: not ansible_check_mode` are skipped during syntax checks.

## Jinja2 template rendering

Two bash scripts are rendered from Jinja2 templates before validation/formatting:
- `roles/common/templates/apply-rog-tweaks.sh.j2` → `.task/rendered/apply-rog-tweaks.sh`
- `roles/common/templates/optimize-network.sh.j2` → `.task/rendered/optimize-network.sh`

The `render-all` task handles both. Validation and formatting tasks depend on rendering automatically.

## CI Pipeline

GitHub Actions runs only a **SonarQube scan** on push to `main` and PRs. All other validation runs locally via `task validate`.

## Python / Devbox

- Python 3.12 via devbox, managed with **uv** (not pip).
- Virtual env is at `.venv/` — activated automatically in devbox shell.
- Key deps: docsible, kubernetes.
- Ansible collections install to `.ansible/collections/` (gitignored).
