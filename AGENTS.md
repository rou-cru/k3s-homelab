# k3s-homelab - AI Agent Development Guide

## Project Overview

This is an Ansible-based Infrastructure-as-Code (IaC) project for setting up a single-node K3s Kubernetes homelab with cryptocurrency mining capabilities. The project automates the deployment of a comprehensive homelab environment including system optimization, GPU support, VPN connectivity, and mining workloads.

**Key Technologies:**
- **Automation**: Ansible with 14 specialized roles
- **Container Orchestration**: K3s (lightweight Kubernetes distribution)
- **CNI**: Cilium for advanced networking
- **Development Environment**: UV (Python package manager), Devbox, Go-Task
- **Testing**: Molecule with Vagrant/libvirt for role validation
- **Documentation**: Docsible for automated README generation

## Architecture

### Core Components
1. **System Layer**: Ubuntu 24.04 with kernel optimizations and hardware tuning
2. **Container Runtime**: K3s with containerd and optional gvisor security runtime
3. **Networking**: Cilium CNI with advanced networking features
4. **Security**: Tailscale VPN, encrypted secrets management
5. **Monitoring**: Glances for system monitoring
6. **Workloads**: CPU/GPU cryptocurrency mining (XelisHash) and bandwidth sharing

### Directory Structure
```
roles/                    # 14 Ansible roles for modular deployment
├── preflight/           # System requirements validation
├── common/              # Base OS setup, kernel tweaks, hardware tuning
├── developer_tools/     # kubectl, helm, yq, node tools
├── nvidia_gpu/          # GPU drivers and container toolkit
├── tailscale/           # VPN client setup
├── k3s_server/          # K3s installation and configuration
├── cilium/              # CNI installation via Helm
├── cert_manager/        # Kubernetes certificate management
├── external_secrets/    # External secrets operator
├── argocd/              # GitOps continuous delivery
├── glances/             # System monitoring
└── gvisor/              # Security runtime

k8s/                     # Kubernetes manifests
├── namespaces/          # Kubernetes namespaces
└── miners/              # Mining workload deployments

images/                  # Docker container definitions
├── cpu-miner/           # CPU mining containers
├── cpu-miner-tnn/       # Alternative CPU miner
├── gpu-miner/           # GPU mining containers
└── gpu-miner-rigel/     # Alternative GPU miner

molecule/                # Testing scenarios for Ansible roles
docs/                    # Advanced documentation and analysis
```

## Build and Development Commands

### Environment Setup
```bash
# Install Python dependencies with UV
uv sync

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Setup development environment with devbox
devbox shell
```

### Testing
```bash
# Run molecule tests for specific roles
molecule test -s common
molecule test -s preflight
molecule test -s glances

# Run all tests (from project root)
molecule test --all
```

### Task Automation
```bash
# Show available tasks
task

# Generate documentation for all roles
task docs:generate

# Render templates for testing
task render-all
```

### Deployment
```bash
# Full deployment
ansible-playbook site.yaml

# Partial deployments with tags
ansible-playbook site.yaml --tags host      # OS setup only
ansible-playbook site.yaml --tags network   # Network optimization
ansible-playbook site.yaml --tags nvidia    # GPU setup
ansible-playbook site.yaml --tags apps      # Deploy miners only
```

## Configuration Requirements

### Secrets Configuration
Create `secrets.yaml` from the example file:
```yaml
tailscale_authkey: "tskey-auth-YOUR-KEY"      # Required for VPN
ansible_ssh_pass: "SSH-PASSWORD"              # SSH password
ansible_become_password: "SUDO-PASSWORD"      # Sudo password
honeygain_pass: "HONEYGAIN-PASSWORD"          # Honeygain account
mining_wallet: "YOUR_XEL_WALLET_ADDRESS"      # Xelis wallet (MANDATORY)
```

### Host Configuration
Edit `inventory.ini`:
```ini
[k3s_server]
192.168.65.16 ansible_user=your_user
```

### Mining Configuration
Configure wallet addresses in secrets or as Ansible variables:
```yaml
mining_wallet: "YOUR_XEL_WALLET_ADDRESS"      # Primary wallet
unmineable_wallet_cpu: "YOUR_CPU_WALLET"      # Optional CPU-specific
unmineable_wallet_gpu: "YOUR_GPU_WALLET"      # Optional GPU-specific
unmineable_referral: "18ps-7t5s"              # Reduces mining fee to 0.75%
honeygain_email: "your@email.com"             # Honeygain account
honeygain_device: "bandwidth-miner"           # Device identifier
```

## Code Style Guidelines

### Ansible Best Practices
- **Role Structure**: Each role follows standard Ansible directory layout
- **Variable Naming**: Use descriptive names with role prefixes (e.g., `k3s_server_version`)
- **Tag Usage**: Implement meaningful tags for partial deployments
- **Idempotency**: All tasks must be idempotent for safe reruns
- **Error Handling**: Use proper error handling and validation

### YAML Standards
- **Linting**: Use yamllint with project configuration (`.yamllint.yml`)
- **Formatting**: 2-space indentation, consistent quoting
- **Comments**: Document complex logic and non-obvious configurations

### Shell Script Standards
- **Linting**: Use shellcheck for all shell scripts (`.shellcheckrc`)
- **Safety**: Use `set -euo pipefail` for error handling
- **Documentation**: Comment complex operations

## Testing Strategy

### Molecule Testing
- **Platform**: Ubuntu 24.04 on libvirt/KVM
- **Verifier**: pytest-testinfra for infrastructure validation
- **Scenarios**: Individual test scenarios for critical roles
- **Sequence**: dependency → cleanup → destroy → syntax → create → prepare → converge → idempotence → verify → cleanup → destroy

### Test Coverage
- **common**: System setup, kernel parameters, package installation
- **preflight**: System requirements validation
- **glances**: Monitoring tool installation and configuration

### Manual Testing
- **Deployment**: Test full and partial deployments
- **GPU Support**: Validate NVIDIA driver installation (if applicable)
- **Networking**: Verify Cilium CNI functionality
- **Mining**: Confirm mining workloads start and connect properly

## Security Considerations

### Vault Management
- **Encryption**: Use Ansible Vault for all sensitive data
- **Password File**: Store vault password in `.ansible_vault_pass`
- **Rotation**: Regular rotation of API keys and passwords

### Network Security
- **VPN**: Tailscale provides secure network connectivity
- **Firewall**: UFW configuration with restrictive rules
- **SSH**: Key-based authentication recommended

### Container Security
- **Runtime**: Optional gvisor runtime for additional isolation
- **Images**: Custom mining images built from official bases
- **Secrets**: External Secrets Operator for secure secret management

### Mining Security
- **Wallet Protection**: Ensure wallet addresses are correctly configured
- **Default Prevention**: Validate wallet configuration to prevent mining to developer address
- **Monitoring**: Implement monitoring for mining operations

## Development Workflow

### Making Changes
1. **Development**: Make changes in appropriate role or component
2. **Testing**: Run molecule tests for affected roles
3. **Validation**: Test deployment on development environment
4. **Documentation**: Update relevant documentation
5. **Review**: Ensure idempotency and best practices

### Adding New Features
1. **Design**: Consider impact on existing infrastructure
2. **Role Creation**: Follow Ansible role standards
3. **Integration**: Add to main playbook with appropriate tags
4. **Testing**: Create molecule scenario for new role
5. **Documentation**: Update README and relevant docs

### Maintenance
1. **Updates**: Regular dependency updates (K3s, Cilium, etc.)
2. **Security**: Monitor for security advisories
3. **Performance**: Review and optimize resource usage
4. **Cleanup**: Remove deprecated configurations

## Key Defaults and Versions

### K3s Configuration
- **Version**: `v1.34.3+k3s1`
- **Traefik**: Disabled (for Cilium)
- **Recreate**: `true` (allows clean reinstall)

### Cilium Configuration
- **Version**: `1.18.5`
- **Features**: Advanced networking and security policies

### Mining Configuration
- **Enabled**: `true` by default
- **Hugepages**: 1280 (2.5GB for RandomX algorithm)
- **Algorithm**: XelisHash for both CPU and GPU mining

## Troubleshooting

### Common Issues
1. **NVIDIA Driver Installation**: Check GPU compatibility and kernel headers
2. **Mining Connection Issues**: Verify wallet configuration and network connectivity
3. **K3s Installation**: Ensure system meets requirements and ports are available
4. **Tailscale Connection**: Validate auth key and network configuration

### Debug Commands
```bash
# Check K3s status
kubectl get nodes -o wide

# Verify mining pods
kubectl get pods -n miners

# Check system resources
kubectl top nodes
kubectl top pods --all-namespaces

# View logs
kubectl logs -n miners -l app=cpu-miner
kubectl logs -n miners -l app=gpu-miner
```

### Support Resources
- **Documentation**: Check `docs/` directory for advanced topics
- **Logs**: Review Ansible output and Kubernetes logs
- **Community**: Project follows standard Ansible practices for community support