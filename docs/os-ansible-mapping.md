# OS vs Ansible Mapping (Host)

Scope: host OS vs Ansible state. Ignore `k8s/` workloads. Ignore devbox.

## Mapping table (OS vs Ansible)

| Area | Status | Notes / Action |
| --- | --- | --- |
| Swap | Ansible correct | OS has `/dev/zram0` active; keep Ansible behavior (no swap/zram replication). |
| RFKill | Ansible correct | OS blocks Bluetooth only; Wi‑Fi enabled. |
| GRUB ASPM | Needs idempotence | OS has `pcie_aspm=off` repeated; Ansible must dedupe. |
| Glances | Drift | Ansible expects `/opt/glances`; OS has none and service points to `/home/rc/.local/bin/glances` (fails). |
| nvitop | Change | Use `uv` (user‑level). OS uses apt (`/usr/bin/nvitop`); Ansible uses pipx as root. |
| uv | Change | OS is user‑local (`/home/rc/.local/bin/uv`); Ansible installs as root (`/root/.cargo/bin/uv`). Policy: use `uv` whenever possible; pip/pipx only if `uv` cannot. |
| kimi | Change | Use `uv` (user‑level). OS user‑local (`/home/rc/.local/bin/kimi`); Ansible root. |
| node/pnpm | Change | OS uses `nvm` (not system PATH); Ansible uses snap + npm -g. |
| kubectl | Change | Use official curl method (no snap, no apt): `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`. OS uses apt (`/usr/bin/kubectl`); Ansible uses snap. |
| helm | Change | Use official script; avoid duplicate installs. OS has `/usr/local/bin/helm`; Ansible also installs snap (duplication). Assume helm repo state is correct per instruction. |
| yq/btop | Policy | Prefer non‑snap if equally simple; snap allowed if best option. OS uses snap today. If snap remains, keep `/etc/profile.d/apps-bin-path.sh`. |
| Tailscale | Assume correct | No changes for now. |
| Audio | Assume correct | No changes. |
| Power tuning | Correct (turbo/max_perf_pct) | OS: `no_turbo=0`, `max_perf_pct=100`. |
| PL1/PL2 (RAPL) | Drift note | OS: 200/175W. Ansible (if enabled) would apply 100/140W. Analyze later. |
| msr module | Correct | Loaded and persisted (`/etc/modules-load.d/msr.conf`). |
| pam_limits | Correct | nofile/memlock/rtprio applied. |
| sysctl default_qdisc | Change | Set `net.core.default_qdisc=fq_codel`. |
| sysctl rp_filter | Change | Set `net.ipv4.conf.*.rp_filter=0` (all/default and Cilium/LXC) for Tailscale + Cilium. |
| sysctl vm.max_map_count | Change | Set `vm.max_map_count=1048576` (needed under heavy logs, e.g., fluent-bit). |
| modules-load nvidia.conf | Change | Add `/etc/modules-load.d/nvidia.conf` (manual today, not from driver). |
| modprobe supergfxd.conf | Ignore for now | Only if supergfx is managed. |

Note: return to the K3s containerd `config.toml` vs missing `config.toml.tmpl` after the mapping.

## Packages to add (OS present, not managed by Ansible)

Confirmed adds:
- `gh`
- `imagemagick`
- `s-tui`
- `fbi`
- `nvtop`
- `tree`
- `tmux`
- `ripgrep`
- `make`
- `cmake`
- `ninja-build`
- `git`
- `timeshift`
- `xvfb`
- `sqlite3`

## Local builds / unmanaged binaries

`asusctl/asusd` and `supergfxctl/supergfxd` are built locally (no dpkg owner). This is drift:
- Do not compile in Ansible.
- Use an artifact strategy (e.g., CI build + release in a fork).
- Decide whether to apply `strip` for asusctl builds.
- Manage `99-supergfxctl.rules` if supergfx is managed.

Standard build notes (from upstream repos):
- asusctl: `make && sudo make install` (Rust/Cargo; needs build deps like libclang-dev, libudev-dev, libfontconfig-dev, build-essential, cmake, libxkbcommon-dev).
- supergfxctl: `make && sudo make install` (Rust/Cargo; build deps: curl, git, build-essential). Service: `systemctl enable supergfxd --now`.

## Cluster (k3s) notes

Decisions and pending changes:
- Single-node now, but keep future nodes in mind.
- CNI: Cilium only; Flannel and kube-proxy remain disabled.
- Networking: Tailscale for node visibility; avoid extra networking complexity.
- GPU workloads expected (miners today, monitoring/SLO soon).
- Cilium should own CNI (eBPF/Hubble); avoid kube-proxy/Flannel.
- Datastore: keep SQLite for now (no etcd, no snapshots/backups yet).

Planned security/logging changes (to be enforced via `/etc/rancher/k3s/config.yaml`):

```yaml
secrets-encryption: true
audit-policy-file: /etc/rancher/k3s/audit-policy.yaml
audit-log-path: /var/log/k3s/audit.log
audit-log-maxage: 30
audit-log-maxbackup: 10
audit-log-maxsize: 100
```

Minimal audit policy (simple and low-noise):

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: Metadata
    resources:
      - group: ""
        resources: ["secrets", "configmaps"]
  - level: RequestResponse
    resources:
      - group: ""
        resources: ["pods", "services", "nodes", "namespaces"]
  - level: Metadata
    omitStages:
      - RequestReceived
```

Operational notes:
- Enabling `secrets-encryption` requires key rotation; document a runbook.
- Ensure `/var/log/k3s` exists (root) for audit log output.
