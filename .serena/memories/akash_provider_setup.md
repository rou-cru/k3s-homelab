# Akash Provider Implementation Roadmap

**Architecture**: Single-Node K3s + Cilium + Tailscale + VPS Gateway (Future).
**Strategy**: Sequential execution via Ansible.

## 1. System Tuning & Prerequisites (Ansible)
**Goal**: Prepare the OS and Hardware for high-performance provider duties.
- [ ] **Kernel Optimization**: Apply `sysctl` params (networking & file descriptors) for high concurrency.
- [ ] **Dependencies**: Ensure `helm`, `python3-pip`, `pip module: kubernetes` are installed.
- [ ] **NVIDIA Check**: Verify GPU drivers are loaded and accessible by container runtime.

## 2. Runtime & Storage Configuration (Ansible)
**Goal**: Satisfy Akash's strict sandbox and storage requirements.
- [ ] **gVisor Installation**: Install `runsc`, configure `containerd` config.toml to add the `runsc` runtime.
- [ ] **Storage Class**: Patch `local-path` to be default and (optionally) advertise `beta3` capability.

## 3. Ingress Layer (Ansible/Helm)
**Goal**: Deploy the specific Ingress Controller required by Akash.
- [ ] **Ingress Nginx**: Deploy `ingress-nginx` controller.
    - *Config*: `hostNetwork: true` (to simplify binding to Tailscale later) or bound to specific IP.
    - *Class*: `akash-nginx`.

## 4. Akash Software Stack (Ansible/Helm)
**Goal**: Deploy the Provider logic.
- [ ] **Operators**: Deploy `akash-hostname-operator` and `akash-inventory-operator`.
- [ ] **Provider**: Deploy `akash-provider` chart.
    - *Attributes*: Force `nvidia-rtx-4070` signature.

## 5. Connectivity (VPS Gateway)
**Goal**: Open the "Front Door" (User requested this as LAST step).
- [ ] **VPS Setup**: Provision external VPS.
- [ ] **Tunnel**: Establish Wireguard connection.
- [ ] **Forwarding**: Configure `iptables` rules on VPS.
