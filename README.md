# k3s-homelab

[![Quality gate](https://sonarcloud.io/api/project_badges/quality_gate?project=rou-cru_k3s-homelab)](https://sonarcloud.io/summary/new_code?id=rou-cru_k3s-homelab)

Ansible playbook for single-node K3s homelab with system tuning, Tailscale, Cilium CNI, optional NVIDIA GPU support, and cryptocurrency miners.

## What it sets up

Roles executed by `site.yaml`:

- preflight: system requirements validation
- common: base OS setup, kernel tweaks, power/hardware tuning, Helm repos
- common (network_optimization.yml): Realtek NIC optimization  
- developer_tools: kubectl/helm/yq/node/etc for host convenience
- nvidia_gpu (host.yml): GPU drivers + container toolkit on host
- nvidia_gpu (headless_optimization.yml): optional X11 + persistence
- tailscale: VPN client with auth key
- k3s_server: single-node K3s install and kubeconfig
- cilium: CNI installed via Helm
- nvidia_gpu (cluster.yml): NVIDIA device plugin on cluster (optional)
- post_tasks: apply k8s manifests (namespaces + miners)

## Workloads deployed

- **honeygain** (bandwidth-miner): Bandwidth sharing
- **cpu-miner** (cpu-miner): CPU mining (XelisHash)
- **gpu-miner** (gpu-miner): GPU mining (XelisHash)

## Configuration

**IMPORTANT: You MUST configure your wallet address or you'll mine for the developer by default.**

### Wallet Configuration

Create your XEL wallet at https://wallet.xelis.io then configure:

```yaml
# Required: Set your XEL wallet address
mining_wallet: "YOUR_XEL_WALLET_ADDRESS"

# Optional: Different wallets for CPU/GPU mining
unmineable_wallet_cpu: "YOUR_CPU_WALLET"
unmineable_wallet_gpu: "YOUR_GPU_WALLET"
```

### Mining Settings

```yaml
# Optional mining configuration
unmineable_referral: "18ps-7t5s"  # Reduces your mining fee from 1% to 0.75%

# Honeygain Settings  
honeygain_email: "your@email.com"
honeygain_pass: "your_password"
honeygain_device: "bandwidth-miner"
```

## Quick start

1. Clone and configure:
```bash
git clone <repo>
cd k3s-homelab
cp secrets.example.yaml secrets.yaml
$EDITOR inventory.ini
$EDITOR secrets.yaml
```

2. Install dependencies:
```bash
ansible-galaxy collection install -r requirements.yml
```

3. Run playbook:
```bash
ansible-playbook site.yaml
```

## Requirements

- **OS**: Ubuntu 24.04 (Noble)
- **Arch**: x86_64
- **Disk**: ≥20 GB free on `/`
- **RAM**: ≥4 GB
- **Network**: Internet access
- **Ansible**: ≥2.20.0

Required secrets:
```yaml
tailscale_authkey: "tskey-auth-YOUR-KEY"
ansible_ssh_pass: "SSH-PASSWORD"
ansible_become_password: "SUDO-PASSWORD"
honeygain_pass: "HONEYGAIN-PASSWORD"
```

## Key defaults

K3s:
- `k3s_server_version`: `v1.34.3+k3s1`
- `k3s_server_disable_traefik`: `true`
- `k3s_server_recreate`: `true`

Cilium:
- `cilium_version`: `1.18.5`

Mining:
- `common_mining_enabled`: `true`
- `common_hugepages_count`: `1280` (2.5GB for RandomX)

Optional tags for partial runs:
```bash
ansible-playbook site.yaml --tags host      # OS setup only
ansible-playbook site.yaml --tags network   # Network optimization
ansible-playbook site.yaml --tags nvidia    # GPU setup
ansible-playbook site.yaml --tags apps      # Deploy miners only
```

## Notes

- Mining workloads deploy by default
- Only control plane node automated (worker nodes not implemented)
- RoG hardware optimizations enabled by default (disable with `common_rog_server: false`)
