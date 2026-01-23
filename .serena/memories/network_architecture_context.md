# Network Architecture Analysis: Cilium over Tailscale

**Status**: Confirmed & Understood.

## 🧠 Core Architecture
The cluster implements a specific, non-standard network stack optimized for secure homelab usage:

1.  **Transport Layer**: **Tailscale Mesh**.
    - The node uses Tailscale (`tailscale0`) as the primary interface for cluster traffic.
    - All inter-node (future) and ingress traffic is intended to flow via this secure overlay.

2.  **CNI Layer**: **Cilium** (Tunnel Mode).
    - **Interface**: Binds explicitly to `tailscale+` devices.
    - **Encapsulation**: VXLAN.
    - **MTU Tuning**: Critical setting `mtu: 1230` handles the double encapsulation overhead (Tailscale 1280 - VXLAN 50).
    - **Features**: `kubeProxyReplacement: true` (Full eBPF), `bandwidthManager: true` (BBR).

3.  **Ingress/Gateway Layer**: **Cilium Gateway API**.
    - **Enabled**: `gatewayAPI.enabled: true`.
    - **Traefik**: Explicitly disabled (`k3s_server_disable_traefik: true`).
    - **Strategy**: The project intends to use Cilium's native Gateway API capabilities for ingress, not legacy Ingress Controllers like Nginx or Traefik, unless strictly forced by compatibility (like potentially Akash).

4.  **Workload Exceptions**:
    - **Miners**: Bypass this stack using `hostNetwork: true` for raw performance/hardware access.
    - **Akash Tenants**: Will reside inside the Cilium overlay, secured by NetworkPolicies (and gVisor).

## ⚠️ Akash Integration Challenge
Akash Provider software expects a standard `Ingress` controller (typically Nginx) to automatically provision ingress for tenants.
**The Challenge**: Reconciling Akash's expectation of `Ingress` resources + Public IP with our **Cilium Gateway API + Tailscale** architecture.
- We must determine if Cilium can process the standard `Ingress` resources created by Akash, or if we need a translation layer.
- The "Public IP" requirement of Akash conflicts with the Tailscale-only design, necessitating a specific Gateway (VPS/Tunnel) solution that maps a public endpoint into the Tailscale network.
