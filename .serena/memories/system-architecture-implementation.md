# System Architecture & Implementation

## Network Architecture
- **Physical Network:** Standard LAN (10.10.10.x in example)
- **Tailscale Overlay:** K3s cluster communication happens over Tailscale VPN IPs
- **CNI:** Cilium replaces default Flannel with `--flannel-backend=none`
- **Service Mesh:** Traefik and ServiceLB disabled by default

## Execution Dependencies
The `site.yaml` playbook has the following execution order:

1. **Tailscale → K3s:** K3s uses Tailscale IP for `--node-ip` and `--advertise-address`
   - Tailscale role sets `tailscale_ip` fact consumed by k3s_server role

2. **K3s → Cilium:** Cilium is deployed via K3s's auto-apply manifest mechanism
   - Cilium manifests go to `/var/lib/rancher/k3s/server/manifests/`

3. **Common → Others:** System preparation happens before specialized roles
   - Swap disabled, kernel updates, hardware tuning applied first

## Hardware-Specific Implementations
- **ASUS RoG Strix Support:** Multiple optimizations for this hardware platform
  - Realtek r8168 driver installation
  - ASPM (Active State Power Management) disable
  - EEE (Energy-Efficient Ethernet) disable
- **NVIDIA GPU Support:** Conditional deployment with auto-detection
- **Power Management:** Custom settings for server operation

## Security Implementation
- **Secrets Management:** Externalized to `secrets.yaml` (git-ignored)
- **Service Configuration:** Traefik and ServiceLB disabled by default
- **System Configuration:** Various kernel and system optimizations

## Deployment Implementation
- **Role Execution:** All roles designed to be re-runnable (idempotent)
- **Reboot Management:** Consolidated reboots to minimize total reboot count
- **Validation:** Preflight checks performed before critical operations
- **Conditional Execution:** Based on hardware detection and configuration flags