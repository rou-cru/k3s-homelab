# K3s Cluster Setup with Tailscale and Cilium

## Project Overview

This is an Ansible automation project for deploying a K3s (lightweight Kubernetes) cluster with Tailscale networking and Cilium CNI (Container Network Interface). The project sets up a secure, distributed Kubernetes cluster using Tailscale as the underlying network fabric and Cilium for advanced networking capabilities.

## Technology Stack

- **Infrastructure Automation**: Ansible
- **Container Orchestration**: K3s (Kubernetes distribution)
- **Networking**: Tailscale (VPN mesh), Cilium (CNI plugin)
- **Operating System**: Ubuntu (target hosts)
- **Package Management**: apt

## Architecture

The project creates a 3-node Kubernetes cluster:
- 1 K3s server (master) node
- 2 K3s agent (worker) nodes
- All nodes communicate via Tailscale mesh VPN
- Cilium handles pod networking with advanced features

## Project Structure

```
/home/rc/homelab/
├── inventory.ini          # Ansible inventory with host definitions
├── site.yaml             # Main Ansible playbook with all tasks
├── group_vars/
│   └── all.yaml          # Global configuration variables
└── AGENTS.md             # This file
```

### Key Files Description

**inventory.ini**: Defines the cluster topology
- `k3s_server` group: Contains the master node (master1)
- `k3s_agents` group: Contains worker nodes (worker1, worker2)
- Connection details: SSH user (ubuntu), sudo access enabled

**site.yaml**: Main playbook with 5 plays:
1. Base OS hygiene (disable swap, install packages)
2. Tailscale installation and configuration
3. K3s server installation with specific networking flags
4. K3s agent installation and cluster joining
5. Cluster verification and Cilium validation

**group_vars/all.yaml**: Configuration variables including:
- Tailscale authentication and settings
- K3s version and feature flags
- Cilium version and network configuration

## Build and Deployment Process

### Prerequisites
- Ansible installed on control machine
- SSH access to target hosts (Ubuntu systems)
- Tailscale auth key (replace placeholder in group_vars/all.yaml)

### Deployment Commands

```bash
# Run the complete playbook
ansible-playbook -i inventory.ini site.yaml

# Run specific sections
ansible-playbook -i inventory.ini site.yaml --tags "tailscale"
ansible-playbook -i inventory.ini site.yaml --start-at-task "Install k3s server"
```

### Key Configuration Steps

1. **Tailscale Setup**: Installs Tailscale VPN and configures secure mesh networking
2. **K3s Server**: Installs control plane with:
   - Node IP binding to Tailscale interface
   - Flannel disabled (Cilium will handle networking)
   - Traefik and ServiceLB disabled (optional)
3. **K3s Agents**: Join cluster using Tailscale IP for secure communication
4. **Cilium Installation**: Deployed via K3s auto-applied manifests

## Network Configuration

- **Tailscale**: Provides secure, encrypted mesh networking between nodes
- **Cilium**: Advanced CNI with:
  - kube-proxy replacement disabled (using standard kube-proxy)
  - Device detection using host's default interface
  - Auto MTU detection
  - Single operator replica

## Security Considerations

- Tailscale provides encrypted networking between all nodes
- SSH access via Tailscale SSH (configurable)
- Ansible uses privilege escalation (sudo) for system changes
- K3s kubeconfig file permissions set to 644 for accessibility

## Testing and Verification

The playbook includes built-in verification:
- K3s API server health checks
- Node status verification
- Cilium daemonset rollout status validation

## Important Notes

- Replace `tailscale_authkey` placeholder in `group_vars/all.yaml` with actual Tailscale auth key
- Consider using Ansible Vault for sensitive data in production
- The playbook assumes Ubuntu target hosts
- Tailscale must be properly configured in your Tailscale admin console
- K3s version and Cilium version can be adjusted in group_vars/all.yaml

## Development Conventions

- Spanish comments in configuration files (maintain consistency)
- Variables use descriptive names with prefixes (k3s_, tailscale_, cilium_)
- Tasks include proper error handling and idempotency checks
- File permissions explicitly set for security
- Uses Ansible best practices with proper delegation and fact setting