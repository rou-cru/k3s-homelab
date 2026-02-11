# AGENTS.md - AI Coding Agent Guide

> This file contains essential context for AI coding agents working on this project.
> The project language is English for code/infrastructure, with some Spanish in comments/examples.

## Project Overview

**k3s-homelab** is an Infrastructure-as-Code (IaC) project that automates the deployment of a single-node K3s Kubernetes cluster using Ansible. The cluster is designed for homelab use with optional cryptocurrency mining workloads, GPU support, and a hybrid cloud setup with a VPS gateway.

### Key Characteristics

- **Primary Purpose**: Deploy and manage a K3s Kubernetes cluster with Tailscale mesh networking
- **Target Environment**: Single-node bare metal (ASUS ROG server) + optional VPS agent
- **Networking**: Tailscale for mesh VPN, Cilium as CNI with kube-proxy replacement
- **GitOps**: ArgoCD manages cluster state after initial bootstrap
- **Optional Workloads**: NVIDIA GPU support, cryptocurrency miners (XEL, TNN, Rigel), Honeygain

## Technology Stack

| Layer | Technology |
|-------|------------|
| **OS** | Ubuntu 24.04 LTS |
| **Container Orchestration** | K3s v1.35.0+k3s1 |
| **CNI** | Cilium 1.18.5 (kube-proxy replacement) |
| **Mesh VPN** | Tailscale |
| **GitOps** | ArgoCD |
| **Secrets** | Ansible Vault + External Secrets Operator |
| **Certs** | cert-manager with Let's Encrypt |
| **Ingress** | Gateway API (Cilium) |
| **IaC** | Ansible + Kubernetes manifests |
| **Dev Environment** | Devbox (Nix) + Python 3.12 + uv |
| **Testing** | Molecule + Vagrant + Testinfra |
| **CI/CD** | GitHub Actions + SonarQube |

## Project Structure

```
.
├── site.yaml                 # Main playbook - K3s master node setup
├── site-vps.yaml            # VPS agent node setup playbook
├── inventory.ini            # Ansible inventory (k3s_server, vps groups)
├── ansible.cfg              # Ansible configuration
├──
├── group_vars/              # Variable definitions by host group
│   ├── all.yml             # Global defaults
│   ├── k3s_server.yml      # Master node overrides (ASUS ROG specific)
│   ├── vps.yml             # VPS-specific settings
│   └── red.yml             # Additional node group
│
├── roles/                   # 16 Ansible roles
│   ├── preflight/          # System requirement validation
│   ├── common/             # OS base setup, kernel tuning
│   ├── k3s_server/         # K3s control plane
│   ├── k3s_agent/          # K3s worker node
│   ├── k3s_common/         # Shared K3s components
│   ├── tailscale/          # Mesh VPN setup
│   ├── cilium/             # CNI deployment
│   ├── nvidia_gpu/         # NVIDIA drivers & device plugin
│   ├── cert_manager/       # TLS certificate management
│   ├── external_secrets/   # External secrets operator
│   ├── argocd/             # GitOps controller
│   ├── gateway/            # Gateway API resources
│   ├── gvisor/             # gVisor sandboxed runtime
│   ├── glances/            # Host monitoring
│   ├── developer_tools/    # Dev utilities (kubectl, helm)
│   └── crds_bootstrap/     # Essential Kubernetes CRDs
│
├── k8s/                     # Kubernetes manifests
│   ├── bootstrap/          # Initial cluster resources
│   │   ├── namespaces/     # Namespace definitions
│   │   ├── miners/         # Mining workloads (Kustomize)
│   │   ├── argocd/         # ArgoCD bootstrap
│   │   ├── cilium/         # Cilium values/templates
│   │   ├── cert-manager/   # cert-manager bootstrap
│   │   ├── external-secrets/ # ESO bootstrap
│   │   └── gateway/        # Gateway resources
│   └── gitops/             # Resources managed by ArgoCD
│       ├── security/       # Falco, Trivy, Kyverno, network policies
│       ├── observability/  # Prometheus, Loki, Fluent-bit
│       ├── infrastructure/ # Rook, workflows, events
│       └── akash/          # Akash provider (if enabled)
│
├── molecule/                # Integration tests
│   ├── preflight/          # Preflight role tests (Vagrant)
│   ├── common/             # Common role tests
│   └── glances/            # Glances role tests
│
├── images/                  # Custom Docker images
│   ├── cpu-miner/          # XMRig CPU miner
│   ├── cpu-miner-tnn/      # TNN CPU miner
│   ├── gpu-miner/          # lolMiner GPU miner
│   └── gpu-miner-rigel/    # Rigel GPU miner
│
├── Taskfile.yml            # Task automation (build, test, validate)
├── docker-bake.hcl         # Docker buildx bake configuration
├── pyproject.toml          # Python dependencies (uv)
├── devbox.json             # Devbox shell configuration
├── requirements.yml        # Ansible collections
├── secrets.yaml            # Encrypted secrets (Ansible Vault)
└── .ansible_vault_pass     # Vault password file (600 permissions)
```

## Build and Development Commands

All development tasks are managed via `task` (Taskfile.yml):

### Validation and Linting

```bash
# Run all validations (YAML, Ansible, Jinja2, Bash)
task validate

# Individual validations
task validate-yaml           # yamllint
task validate-ansible-checkov # Checkov security scanning
task validate-ansible-syntax  # ansible-playbook --syntax-check
task validate-jinja2         # j2lint
task validate-bash           # shellcheck on rendered scripts
```

### Formatting

```bash
# Format all files
task format

# Individual formatters
task format-yaml             # yamlfmt
task format-bash             # shfmt
```

### CI Commands

```bash
task ci-full                 # Full CI pipeline (validate + format check)
task ci-quick                # Quick validation (syntax only)
task ci-format-check         # Check formatting without modifying
```

### Testing

```bash
# Molecule integration tests (requires Vagrant + libvirtd)
task test:preflight          # Run preflight role tests
task test:converge:preflight # Converge only (faster iteration)
task test:verify:preflight   # Verify only
task test:destroy            # Destroy test VMs
task test:all                # All role tests

# Initialize new test scenario
task test:init -- ROLE_NAME
```

### Secrets Management

```bash
# Initialize vault password file
task secrets:init

# Interactive setup of all secrets
task secrets:setup

# Set individual secret
task secrets:set -- KEY_NAME "value"
```

### Docker Image Building

```bash
# Build all miner images
task build:miners

# Build specific images
task build:miners:cpu        # CPU miners (i9, generic, tnn)
task build:miners:cpu:tnn    # TNN miner only
task build:miners:gpu        # lolMiner GPU
task build:miners:gpu:rigel  # Rigel GPU

# Push to registry
task push:miners
task release:miners          # Build + push
```

### Documentation

```bash
# Generate role READMEs with architecture graphs
task docs:generate
```

## Code Style Guidelines

### YAML

- **Indentation**: 2 spaces, consistent sequence indentation
- **Line length**: Max 120 characters (warning level)
- **Document start**: Disabled (no `---` required)
- **Quotes**: Use for strings containing special characters
- **Truth values**: Use `true`/`false` or `yes`/`no` (both allowed)
- **Comments**: Minimum 1 space from content

See `.yamllint.yml` and `.yamlfmt` for full configuration.

### Ansible

- **Module syntax**: Use FQCN (e.g., `ansible.builtin.copy`)
- **Tags**: Use specific tags for logical grouping (`host`, `cluster`, `infra`, `miners`, `gitops`)
- **Variable naming**: snake_case, descriptive prefixes (e.g., `k3s_`, `system_`)
- **Handlers**: Named with action verbs, flushed at strategic points
- **Blocks**: Use for logical grouping with shared `when` conditions
- **Vault**: All secrets in `secrets.yaml`, referenced via `vars_files`

### Jinja2 Templates

- **Spacing**: `{{ variable }}` (spaces inside braces)
- **Filters**: Chain with `|`, use `default()` for safety
- **Conditionals**: Use `is defined` checks before accessing optional vars
- **Linting**: j2lint ignores `jinja-variable-lower-case` rule

### Bash Scripts (Templates)

- **Shell**: Bash with `set -euo pipefail`
- **Indentation**: 4 spaces (shfmt)
- **Linting**: shellcheck enabled
- **Templates**: Located in `roles/*/templates/*.j2`
- **Rendered output**: Validated in `.task/rendered/`

### File Permissions

- **Vault password file**: `600` (`.ansible_vault_pass`)
- **SSH keys**: `600` for private, `644` for public
- **Kubeconfig**: `600`
- **Secret files**: `600`

## Testing Strategy

### Unit/Integration Testing with Molecule

- **Driver**: Vagrant with libvirt (KVM)
- **Platform**: generic/ubuntu2404
- **Verifier**: Testinfra (Python pytest)
- **Test sequence**: dependency → create → converge → idempotence → verify → destroy

### Security Scanning

- **Checkov**: Ansible framework scanning
- **Trufflehog**: Secret detection (via devbox)
- **SonarQube**: Code quality analysis (CI/CD)

### Validation Levels

1. **Syntax**: `ansible-playbook --syntax-check`
2. **Lint**: yamllint, j2lint, shellcheck
3. **Security**: Checkov scanning
4. **Integration**: Molecule tests
5. **Format**: yamlfmt, shfmt compliance

## Security Considerations

### Secrets Management

- **Primary**: Ansible Vault (`secrets.yaml`)
- **Secondary**: External Secrets Operator (integrates with cloud vaults)
- **Vault password**: Stored in `.ansible_vault_pass` (never commit without encryption)
- **Example secrets**: `secrets.example.yaml` shows required keys

### Required Secrets (secrets.yaml)

```yaml
tailscale_authkey          # Tailscale authentication key
ansible_become_password    # Sudo password for target hosts
honeygainPass             # Honeygain service password
honeygainEmail            # Honeygain account email
miningWallet              # XEL wallet address
dockerhub_username        # Docker Hub credentials
dockerhub_token           # Docker Hub access token
```

### Network Security

- **Tailscale**: Mesh VPN, no public K8s API exposure
- **Cilium**: Network policies, L7 filtering
- **Gateway API**: TLS termination at edge
- **cert-manager**: Automated certificate rotation

### Runtime Security

- **gVisor**: Sandboxed container runtime (optional)
- **Falco**: Runtime threat detection (GitOps-managed)
- **Kyverno**: Policy enforcement (GitOps-managed)
- **Trivy**: Vulnerability scanning (GitOps-managed)

## Deployment Process

### Prerequisites

1. Target host with Ubuntu 24.04
2. SSH access with key authentication
3. Tailscale auth key
4. Populated `secrets.yaml`

### Main Deployment

```bash
# Full deployment (master node)
ansible-playbook site.yaml -K

# With specific tags
ansible-playbook site.yaml -K --tags "host,cluster"

# VPS agent node (after master is ready)
ansible-playbook site-vps.yaml -K
```

### Tag-based Deployment Phases

| Tag | Purpose | Roles |
|-----|---------|-------|
| `host` | OS preparation | preflight, common, developer_tools, gvisor, nvidia_gpu |
| `cluster` | K8s bootstrap | tailscale, k3s_server, crds_bootstrap, cilium |
| `infra` | Platform services | cert_manager, external_secrets, gateway |
| `miners` | Mining workloads | namespace setup, Kustomize deployments |
| `gitops` | ArgoCD deployment | argocd |
| `tailscale` | VPN configuration | tailscale |
| `nvidia` | GPU support | nvidia_gpu |

## Common Development Workflows

### Adding a New Role

1. Create role structure: `mkdir -p roles/new_role/{tasks,defaults,meta,templates}`
2. Add `meta/main.yml` with dependencies
3. Add `README.md` using docsible template
4. Create Molecule scenario: `task test:init -- new_role`
5. Run tests: `task test:preflight` (adapt for your role)
6. Generate docs: `task docs:generate`

### Modifying Kubernetes Manifests

1. Edit files in `k8s/bootstrap/` or `k8s/gitops/`
2. Validate YAML: `task validate-yaml`
3. Run syntax check: `task validate-ansible-syntax`
4. Test deployment: `ansible-playbook site.yaml -K --tags cluster,infra`

### Updating Miner Images

1. Modify Dockerfile in `images/*/`
2. Update `docker-bake.hcl` if needed
3. Build: `task build:miners`
4. Push: `task push:miners`
5. Update Kustomize references in `k8s/bootstrap/miners/`

### Handling Secrets

1. Never commit unencrypted secrets
2. Use `task secrets:set -- KEY VALUE` to add
3. Verify encryption: `cat secrets.yaml` should show AES256 header
4. For rotation: Edit with `ansible-vault edit secrets.yaml`

## Important File Locations

| Purpose | Path |
|---------|------|
| Main playbook | `site.yaml` |
| VPS playbook | `site-vps.yaml` |
| Inventory | `inventory.ini` |
| Global variables | `group_vars/all.yml` |
| Master overrides | `group_vars/k3s_server.yml` |
| Encrypted secrets | `secrets.yaml` |
| Vault password | `.ansible_vault_pass` |
| K8s manifests | `k8s/` |
| Custom images | `images/` |
| Role documentation | `roles/*/README.md` |
| CI workflow | `.github/workflows/build.yml` |

## Troubleshooting Tips

- **Check mode**: Many K8s tasks use `when: not ansible_check_mode` - they won't show changes in check mode
- **Tailscale dependency**: Master must be online for VPS to join (needs Tailscale IP)
- **GPU setup**: Requires reboot, handled automatically with `nvidia_rebootTimeout`
- **Cilium**: Can take several minutes to fully deploy - wait for CNI before app deployments
- **Molecule tests**: Require libvirtd running and Vagrant installed on host
