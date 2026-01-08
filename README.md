# k3s-homelab (draft)

Out-of-the-box Ansible playbook to provision a single-node (extensible) K3s
homelab with system tuning, Tailscale connectivity, Cilium CNI, optional NVIDIA
GPU support, and a small set of K8s workloads (miners).

This README is a preliminary draft based on existing code. Fill in the TODOs as
we confirm project intent and target environment.

## What it sets up

Roles executed by `site.yaml` (in order):

- preflight: connectivity, disk, memory, architecture checks.
- common: base OS setup, kernel tweaks, power/hardware tuning, Helm repos.
- common (network_optimization.yml): Realtek tuning + NIC optimization service.
- developer_tools: kubectl/helm/yq/node/etc for convenience on the host.
- nvidia_gpu (host.yml): GPU drivers + container toolkit on the host.
- nvidia_gpu (headless_optimization.yml): optional X11 + persistence.
- tailscale: VPN client configured with auth key.
- k3s_server: single-node K3s install and kubeconfig.
- cilium: CNI installed via Helm.
- nvidia_gpu (cluster.yml): NVIDIA device plugin on the cluster (optional).
- post_tasks: apply k8s manifests (namespaces + miners).

## Workloads deployed (apps tag)

- **honeygain** (bandwidth-miner): Bandwidth sharing.
- **unmineable** (cpu-miner): CPU mining (RandomX).
- **unmineable-gpu** (gpu-miner): GPU mining (Autolykos2).

## Configuration & Transparency

The project is designed to work **immediately** out-of-the-box.

### Wallets (Donations vs. Earnings)
By default, the system mines to the developer's wallet (`0x57...`).
1.  **For Testing:** You can deploy immediately to verify stability without needing a wallet.
2.  **Donations:** If you leave it as-is, you are donating your hashrate to support this project. Thank you!
3.  **Your Earnings:** To start earning for yourself, **you must set `mining_wallet`** to your own address. **Note:** You are responsible for ensuring compatibility between the mined token, network, and your wallet.

### Referral Codes (Fee Reduction)
The default referral code (`18ps-7t5s`) is active by default.
*   **Why keep it?** It reduces **your** Unmineable mining fee (typically from 1% to 0.75%). It's a win-win: you save money, and I get a small kickback.
*   **Can I change it?** Absolutely. Set `unmineable_referral` to any code you prefer.

### Variables Reference
Add these to your Ansible variables:

```yaml
# Master wallet variable.
# Default: Developer's wallet (Donation/Test).
# CHANGE THIS to your address to receive payouts.
# (Ensure your wallet supports the chosen network and token)
mining_wallet: "0xYOUR_WALLET_ADDRESS"

# Overrides (Optional): Use if you need different wallets for CPU vs GPU.
unmineable_wallet_cpu: "..."
unmineable_wallet_gpu: "..."

# Mining Settings
unmineable_coin: "AVAX"        # Default: AVAX
unmineable_referral: "..."     # Default: 18ps-7t5s (Reduces your fee)

# Honeygain Settings
honeygain_email: "email@example.com"
honeygain_pass: "your_password"
honeygain_device: "bandwidth-miner"
```

## Custom Docker Images

Miner images are built and pushed using Docker Bake and Taskfile.

```bash
task release:miners
```

## Quick start (single node)

1) Clone and enter the repo:

```bash
git clone <repo>
cd k3s-homelab
```

2) Configure the inventory and secrets:

```bash
cp secrets.example.yaml secrets.yaml
$EDITOR inventory.ini
$EDITOR secrets.yaml
```

Opcional (si quieres usar Ansible Vault): `task secrets:setup`

Inventory example (already present):

```
[k3s_server]
master1 ansible_host=192.168.65.16

[all:vars]
ansible_user=rc
ansible_become=true
ansible_python_interpreter=/usr/bin/python3
```

Secrets required:

```
tailscale_authkey: "tskey-auth-REEMPLAZA-ESTO-POR-TU-CLAVE-REAL"
ansible_ssh_pass: "CONTRASEÑA-SSH"
ansible_become_password: "CONTRASEÑA-SUDO"
honeygain_pass: "CONTRASEÑA-HONEYGAIN"
```

3) Install Ansible collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

4) Run the playbook:

```bash
ansible-playbook site.yaml
```

Optional: use tags to run partial flows:

```bash
ansible-playbook site.yaml --tags host
ansible-playbook site.yaml --tags network
ansible-playbook site.yaml --tags nvidia
ansible-playbook site.yaml --tags apps
```

## Requirements and assumptions

From preflight and role metadata:

- OS: Ubuntu noble (24.04) is the supported platform today.
- Arch: x86_64.
- Disk: >= 20 GB free on `/`.
- RAM: >= 4 GB.
- Internet access from the target node (downloads K3s, packages, Helm charts).
- Tailscale auth key set in `secrets.yaml`.

Optional:

- NVIDIA GPU present (auto-detected), or force via `nvidia_gpu_setup: "true"`.
- Honeygain account (password required in `secrets.yaml`).

## Key configuration knobs

These are the most relevant defaults; override via inventory vars or extra vars.

K3s:

- `k3s_server_version`: `v1.34.3+k3s1`
- `k3s_server_disable_traefik`: `true`
- `k3s_server_disable_servicelb`: `true`
- `k3s_server_recreate`: `true`
- `k3s_server_copy_kubeconfig_local`: `true`
- `k3s_server_local_kubeconfig_path`: `~/.kube/config`

Cilium:

- `cilium_version`: `1.18.5`
- `cilium_namespace`: `kube-system`

Tailscale:

- `tailscale_hostname_prefix`: `k3s`
- `tailscale_tags`: `""`
- `tailscale_accept_dns`: `"true"`
- `tailscale_ssh`: `"true"`

NVIDIA:

- `nvidia_gpu_setup`: `auto` (auto|true|false)
- `nvidia_gpu_driver_package`: `auto`
- `nvidia_gpu_device_plugin_version`: `0.14.3`
- `nvidia_gpu_headless_x11_enabled`: `true`

Common system tuning:

- `common_network_optimization_enabled`: `true`
- `common_rog_server`: `true`
- `common_mining_enabled`: `true`

Developer tools:

- `devtools_install_docker`: `false`

## Dev environment (optional)

The repo ships with `devbox.json`. Entering `devbox shell` will install
Ansible, Python, and other tooling, and create a `.venv` via `uv`.

## How the playbook is structured

`site.yaml` is the single entrypoint. It loads `secrets.yaml` (or a custom
file via `-e secrets_file=...`), runs host and cluster roles, then applies
Kubernetes manifests from `k8s/`.

## Extensibilidad

El objetivo es extender el homelab con nuevos nodos unidos por Tailscale y
orquestados con K3s. Hoy solo se automatiza el master; los agentes quedan
pendientes de agregar.

## Open questions / TODOs

- Mining workloads are default; add a documented switch to disable them.
- Do we want a "no-GPU" default path documented more explicitly?
