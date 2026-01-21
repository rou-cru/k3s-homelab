# Base Setup for `k3s-vps` (Ubuntu Server 24.04, VPS)

## 1. Target & Connectivity
*   **Host:** `k3s-vps` (IP: `74.208.250.178`)
*   **User:** `rc` (Same as master, key-based auth assumed).
*   **Group:** `vps` (New group to isolate from `k3s_server` logic).

## 2. Required Roles
*   **`preflight`**: Connectivity, disk space, and memory checks.
*   **`common`**: Base packages, K3s OS requirements (`cgroup`, `sysctl` params), and tuning.
*   **`tailscale`**: VPN connectivity and Exit Node.

## 3. Essential Variable Configuration
These variables are critical to adapt the `common` role for a generic VPS and prevent hardware-specific failures or bloat (Mining/Nvidia).

| Variable | Value | Reason |
| :--- | :--- | :--- |
| `common_mining_enabled` | `false` | **CRITICAL:** Prevents installation of Hugepages (2.5GB reserved), MSR module, and Nvidia drivers. |
| `common_audio_optimization_enabled` | `false` | Removes `alsa-utils`, real-time priority limits, and audio tuning irrelevante for a VPS. |
| `common_radio_block_enabled` | `false` | Prevents errors trying to block WiFi/Bluetooth hardware that doesn't exist. |
| `nvidia_gpu_setup_mode` | `'false'` | Explicitly disables any GPU driver checks or installation logic. |
| `common_power_efficiency_tuning_enabled` | `false` | Skips Intel-specific energy tuning (governor/EPP) which may not be available or effective in a virtualized CPU. |

## 4. Tailscale Exit Node Strategy
*   **Requirement:** Enable `--advertise-exit-node`.
*   **Limitation:** The current `roles/tailscale` does not support this flag via variables.
*   **Action Plan:**
    1.  Deploy standard Tailscale role.
    2.  **Post-Provisioning (Manual):** Run `sudo tailscale set --advertise-exit-node` on the node.
    3.  **Admin Console:** Approve the exit node in the Tailscale admin panel.

## 5. OS Optimizations for K3s (Included in `common`)
*   **Sysctl:**
    *   `vm.max_map_count=1048576` (Elasticsearch/Log requirement).
    *   `net.ipv4.conf.all.rp_filter=0` (Cilium/Tailscale routing).
    *   `net.core.default_qdisc=fq_codel` + `tcp_congestion_control=bbr` (Network performance).
*   **System Limits:** Increased File Descriptors (`nofile`) and Inotify watches (`fs.inotify.max_user_watches`) for many containers.
*   **Swap:** Disabled (Required for Kubelet).

## 6. K3s Cluster Join Strategy (Future Phase)
To attach the VPS to the cluster as a worker node after Cilium is ready, a new `k3s_agent` role is required (current `k3s_server` is master-only).

*   **Role Requirements:** Create `roles/k3s_agent` to install `k3s-agent`.
*   **Double Layer Security:**
    *   **Layer 1 (Transport):** All traffic is encapsulated and encrypted via **Tailscale (WireGuard)**. The cluster will communicate exclusively via `100.x.x.x` IPs.
    *   **Layer 2 (Authentication):** Use the **K3s Secure Token (K10 format)**. This includes the Master's CA hash for automatic **CA Pinning**, ensuring the agent only joins the legitimate master.
*   **Connectivity:**
    *   **Interface Binding:** Bind K3s to Tailscale (`--node-ip <Tailscale-IP>` and `--flannel-iface tailscale0`).
    *   **Token Retrieval:** Ansible will `slurp` the full token from `/var/lib/rancher/k3s/server/node-token` on the master and provide it to the agent.
    *   **Master URL:** Use `https://100.114.180.12:6443` (Master's Tailscale IP).
*   **Cilium Compatibility:**
    *   **No-Flannel:** Installation flags must include `--flannel-backend=none` to prevent conflicts with Cilium.
    *   **Routing:** Verify `net.ipv4.conf.all.rp_filter=0` is active (handled by `common` role) for Cilium cross-node traffic.

## 7. Public Traffic & Security (Gateway API)
The VPS will serve as the public ingress point for user workloads, while administrative access remains private.

*   **API Server:** STRICTLY PRIVATE. Accessible only via Tailscale IP (`100.x`). No public exposure.
*   **Traffic Management:** Use **Kubernetes Gateway API** (via Cilium) instead of legacy Ingress.
*   **Public TLS Strategy:**
    *   **Cert-Manager:** Installed in cluster.
    *   **Issuer:** `ClusterIssuer` configured with **Cloudflare DNS-01** challenge. This allows obtaining valid wildcard certificates (`*.domain.com`) without exposing port 80/HTTP.
    *   **Integration:** Cert-Manager will automatically secure Gateway Listeners.
*   **Entrypoint:** The Gateway LoadBalancer service will bind to the VPS Public IP (`74.208.250.178`), routing valid traffic through the Tailscale tunnel to workloads running anywhere in the cluster (Home or VPS).

## 8. Zero Trust Architecture (Hardening for Production)
Given the mixed environment (Trusted Control Plane vs. Hostile User Workloads), strict identity verification is required.

### Fase 1: Defense in Depth sin SPIRE (MVP)
SPIRE añade complejidad operacional significativa. Bugs activos en Cilium v1.17.5-v1.18.0 (GitHub #40533).

**Estrategia validada:**
| Capa | Mecanismo | Estado |
|------|-----------|--------|
| Transport | Tailscale WireGuard | ✅ Ya existe |
| Network Identity | CiliumNetworkPolicy `fromEndpoints` | 🔨 Implementar |
| Runtime Isolation | gVisor | ✅ Role existe |
| Admission Control | Kyverno | 🔨 Crear role |

**Decisión:** NetworkPolicies + gVisor primero. Evaluar SPIRE después de 3-6 meses si se detecta necesidad de mTLS workload-to-workload.

### Fase 2: SPIRE (Futuro, si requerido)
*   **Technology:** Cilium Service Mesh + SPIRE.
*   **Constraint:** Pinear Cilium a versión compatible (evitar v1.17.5-v1.18.0).
*   **Components:**
    *   SPIRE Server (StatefulSet): 2 replicas con Pod Anti-Affinity.
    *   SPIRE Agent (DaemonSet): En cada nodo.
    *   Cilium Integration: `authentication.mutual.spire.enabled=true`.
*   **Performance:** DISABLE Cilium WireGuard/IPsec (Tailscale ya encripta).

## 9. Storage Strategy (Hybrid Resilience)
Leverage distributed resources to ensure data safety without dedicated NAS hardware.

*   **Mechanism:** **Longhorn** (Distributed Block Storage).
*   **Architecture:**
    *   **Master Node (Home):** Performance tier (NVMe/SSD). Primary source for local workloads.
    *   **VPS Node (Cloud):** Resilience tier (120GB Disk). Acts as a **Replication Target**.
*   **Configuration:**
    *   **Data Locality:** `best-effort`. Prefer local reads (speed), fall back to network reads via Tailscale if local disk fails.
    *   **Replica Count:** 2 (1 Home + 1 VPS) for critical volumes (Vault, Databases). 1 for non-critical (Caches).
*   **Disaster Recovery & Observability (Off-site):**
    *   **Target:** **OCI Object Storage** (Always Free Tier - 20GB).
    *   **Primary Usage (Loki Backend):** Direct storage for Loki chunks and indexes.
    *   **Secondary Usage:** Critical volume snapshots (Longhorn backups) if space permits.

### Advertencia: Longhorn sobre WAN (2025-01 Review)
GitHub issue #962 documenta: *"It's hard to run Longhorn across different regions. Network latency can result in slow response."*

**Riesgos identificados:**
- Write latency = RTT * 2 mínimo (~40-100ms con ISP residencial)
- Risk de split-brain si túnel Tailscale cae
- Replicas síncronas degradarán performance

**Decisión:** Proceder como EXPERIMENTO. Fallback plan:
- Si latencia inaceptable → Longhorn solo local (Home)
- VPS disco usado para: cache local, logs efímeros
- OCI Object Storage como único off-site backup

## 10. SRE Resilience & Emergency Readiness
Prepare for "Total Network/CNI Collapse" and Resource Exhaustion.

*   **OS Level Tooling (Injected via Ansible `common`):**
    *   **Network:** `tcpdump`, `iproute2`, `conntrack`, `bind9-host` (dig/host).
    *   **System:** `htop`, `iotop`, `glances` (standalone), `jq`, `yq`, `vim`.
    *   **Container Ops:** `crictl` (pre-configured to talk to containerd), `nerdctl` (docker-compatible CLI for containerd).
*   **Out-of-Band (OOB) Access:**
    *   **Primary:** Tailscale SSH (Enabled on both Master & VPS).
    *   **Secondary:** IONOS Cloud Console (Web-based emergency serial access).
*   **Resource Guarding (Kubelet Hardening):**
    *   **System-Reserved:** Force-reserve resources that the K8s scheduler cannot touch:
        *   `cpu=200m`
        *   `memory=512Mi`
    *   **Eviction Thresholds:** Hard-evict pods when `memory.available < 256Mi` or `nodefs.available < 10%`. Protects the Linux Kernel from OOM (Out of Memory) locks.
*   **External Watcher (Dead Man's Switch):**
    *   **Provider:** Healthchecks.io.
    *   **Endpoint:** `https://hc-ping.com/300a89e0-fcc1-4532-a7c2-30a177064be0`
    *   **Trigger:** Alertmanager heartbeat sent every 5 minutes. Failure triggers external alert (Telegram/Email).
