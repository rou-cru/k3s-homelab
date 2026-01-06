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

Manifests from `k8s/` are copied to the host and applied with
`kubernetes.core.k8s` using `/home/{{ ansible_user }}/.kube/config`.

- namespaces: `miners`
- honeygain: deployment + configmap + secret (templated from `secrets.yaml`)
- unmineable (CPU): deployment + configmap + secret
- unmineable-gpu: deployment + configmap + secret (only when GPU enabled)

## Valores requeridos (mineria)

Defaults actuales (ojo: son míos) y cómo cambiarlos:

- Wallet (Unmineable): `0x57d893d8323CfB88ea133F4c4f5e3A2872Bf4f50`
  - Cambiar en `k8s/miners/unmineable/secret.yaml` y
    `k8s/miners/unmineable-gpu/secret.yaml`.
- Referral (Unmineable): `4ikk-u6bw`
  - Cambiar en `k8s/miners/unmineable/configmap.yaml` y
    `k8s/miners/unmineable-gpu/configmap.yaml`.
  - Puedes dejarlo si quieres apoyarme; igual es editable.
- Moneda de payout (Unmineable): `BNB` (default)
  - Cambiar `COIN` (CPU) en `k8s/miners/unmineable/configmap.yaml`.
  - Cambiar `MINING_COIN` (GPU) en `k8s/miners/unmineable-gpu/configmap.yaml`.
  - CPU usa RandomX (Monero) y GPU usa Autolykos2 (Ergo); la variable define
    la moneda de payout.

Honeygain (recomendado vía Jumpstart para ganar JMPT y convertirlo fácil a BNB):

- Email por defecto: `roura.cruz.al@gmail.com`
  - Cambiar en `k8s/miners/honeygain/configmap.yaml`.
- Password: `honeygain_pass` en `secrets.yaml`.
  - Se aplica desde `k8s/miners/honeygain/secret.yaml.j2`.
- Referral Honeygain: `https://join.honeygain.com/ROURA7955A`

Recomendación: usar una wallet tipo Metamask para consolidar BNB de Unmineable +
JMPT (Jumpstart) + otra fuente.

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
