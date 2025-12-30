# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible-based infrastructure-as-code repository for deploying and managing a K3s Kubernetes cluster on homelab hardware. The setup is optimized for ASUS RoG Strix server hardware with NVIDIA GPUs and uses Tailscale for secure networking.

## Key Commands

### Running the Playbook

```bash
# Deploy the full stack (requires secrets.yaml to be configured)
ansible-playbook site.yaml

# Dry run to see what would change
ansible-playbook site.yaml --check

# Limit execution to specific hosts
ansible-playbook site.yaml --limit master1

# Run with increased verbosity
ansible-playbook site.yaml -v   # or -vv, -vvv for more detail
```

### Testing and Validation

```bash
# Check connectivity to all hosts
ansible all -m ping

# Gather facts from hosts
ansible all -m setup

# Check K3s cluster status (run on the server)
ssh ubuntu@10.10.10.10 "k3s kubectl get nodes -o wide"
ssh ubuntu@10.10.10.10 "k3s kubectl get pods -A"

# Verify Cilium status
ssh ubuntu@10.10.10.10 "k3s kubectl -n kube-system rollout status ds/cilium"

# Check NVIDIA GPU availability (if gpu_setup=true)
ssh ubuntu@10.10.10.10 "k3s kubectl describe nodes | grep -A 5 'Capacity:'"
```

### Configuration

```bash
# Create secrets file from template (required before first run)
cp secrets.example.yaml secrets.yaml
# Then edit secrets.yaml and add your real Tailscale auth key

# Modify inventory
vim inventory.ini

# Modify role defaults
vim roles/<role_name>/defaults/main.yml
```

## Architecture

### Execution Flow

The `site.yaml` playbook orchestrates deployment in this specific order:

1. **common** - System preparation (swap disable, kernel updates, hardware tuning)
2. **tailscale** - VPN networking layer (K3s uses Tailscale IPs for node communication)
3. **k3s_server** - K3s installation with Flannel disabled (Cilium replaces it)
4. **nvidia_gpu** - GPU driver and container runtime configuration (conditional)
5. **cilium** - CNI network plugin deployment via HelmChart

### Critical Dependencies

- **Tailscale must complete before K3s**: K3s binds to the Tailscale IP (`tailscale_ip` fact) for `--node-ip` and `--advertise-address`
- **K3s must complete before Cilium**: Cilium is deployed via K3s's auto-apply manifest mechanism (`/var/lib/rancher/k3s/server/manifests/`)
- **GPU setup is conditional**: Controlled by `gpu_setup` variable in inventory (per-host) or defaults

### Networking Architecture

- **Physical Network**: Standard LAN (10.10.10.x in example)
- **Tailscale Overlay**: K3s cluster communication happens over Tailscale VPN IPs
- **CNI**: Cilium (Flannel explicitly disabled with `--flannel-backend=none`)
- **Service Mesh**: Traefik and ServiceLB disabled by default (Cilium handles LoadBalancer)

### Role Responsibilities

**common**
- Disables swap permanently
- Installs HWE kernel for newer drivers
- Applies hardware-specific tuning for ASUS RoG Strix servers:
  - Realtek r8168 driver installation (RoG hardware fix)
  - ASPM (Active State Power Management) disable for stability
  - EEE (Energy-Efficient Ethernet) disable for network performance
  - CPU governor and audio optimizations
- Configures power management (lid switch ignore, no sleep)
- System kernel tuning (BBR congestion control, file limits, watchdog)

**tailscale**
- Installs Tailscale via official script
- Authenticates with ephemeral auth key (from `secrets.yaml`)
- Sets hostname to `k3s-<inventory_hostname>` pattern
- Captures Tailscale IPv4 and stores in `tailscale_ip` fact

**k3s_server**
- Installs specific K3s version (v1.34.3+k3s1 as of defaults)
- Configures K3s to use Tailscale IP for cluster communication
- Disables Flannel (CNI), Traefik (ingress), ServiceLB (load balancer)
- Waits for API server readiness before proceeding

**nvidia_gpu**
- Detects NVIDIA hardware (fails gracefully if `gpu_setup=true` but no GPU)
- Auto-detects recommended driver using `ubuntu-drivers` tool
- Blacklists nouveau driver
- Installs NVIDIA Container Toolkit
- Configures K3s containerd to use NVIDIA runtime
- Deploys NVIDIA Device Plugin via HelmChart

**cilium**
- Deploys Cilium via K3s HelmChart CRD (auto-applied from manifests directory)
- Configuration in `roles/cilium/files/cilium-values.yaml`
- Waits for DaemonSet rollout completion

## Secrets Management

**IMPORTANT**: Never commit `secrets.yaml` to git (it's in `.gitignore`)

- Copy `secrets.example.yaml` to `secrets.yaml`
- Add your Tailscale auth key (obtain from https://login.tailscale.com/admin/settings/keys)
- The playbook validates that the key is not the placeholder value

## Common Modifications

### Changing K3s Version

Edit `roles/k3s_server/defaults/main.yml`:
```yaml
k3s_version: "v1.34.3+k3s1"
```

### Disabling GPU Setup

In `inventory.ini`, set `gpu_setup=false` for specific hosts, or edit `roles/nvidia_gpu/defaults/main.yml` to change the default.

### Customizing Cilium

Edit `roles/cilium/files/cilium-values.yaml` for Cilium Helm chart values, or change the version in `roles/cilium/defaults/main.yml`.

### Hardware-Specific Tuning

The `common` role includes several hardware optimization modules controlled by flags in `roles/common/defaults/main.yml`:
- `network_optimization_enabled` - EEE disable, ring buffer tuning
- `rog_server` - ASUS RoG Strix specific fixes (Realtek driver, ASPM)
- `radio_block_enabled` - Block WiFi/Bluetooth radios
- `audio_optimization_enabled` - Audio realtime/performance tuning

Set these to `false` if running on non-RoG hardware or if optimizations cause issues.

## File Locations on Target Host

- K3s binary: `/usr/local/bin/k3s`
- K3s data: `/var/lib/rancher/k3s/`
- Auto-apply manifests: `/var/lib/rancher/k3s/server/manifests/`
- Containerd config: `/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl`
- Kubeconfig: `/etc/rancher/k3s/k3s.yaml` (mode 644 for non-root access)
- K3s node token: `/var/lib/rancher/k3s/server/node-token`

## Troubleshooting

### Playbook Fails on Tailscale Auth

Ensure `secrets.yaml` exists and contains a valid auth key. The playbook will fail early if the key is still the placeholder value.

### K3s API Server Not Ready

Check K3s service status:
```bash
ssh ubuntu@<host> "systemctl status k3s"
ssh ubuntu@<host> "journalctl -u k3s -n 100"
```

### Cilium Pods Not Starting

Verify K3s auto-applied the HelmChart:
```bash
ssh ubuntu@<host> "k3s kubectl get helmchart -n kube-system"
ssh ubuntu@<host> "k3s kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium"
```

### GPU Not Detected in Kubernetes

Verify driver and toolkit:
```bash
ssh ubuntu@<host> "nvidia-smi"
ssh ubuntu@<host> "k3s crictl info | grep -A 10 nvidia"
ssh ubuntu@<host> "k3s kubectl get pods -n kube-system | grep nvidia-device-plugin"
```

### Reboot Required

Several tasks may trigger automatic reboots:
- HWE kernel installation
- NVIDIA driver installation
- Nouveau blacklist changes

The playbook handles these gracefully with `reboot` module and waits for reconnection.
