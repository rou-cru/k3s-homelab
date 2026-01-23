# Public Exposure & Traffic Routing Plan (Split Horizon Architecture)

## 1. Context & Philosophy
*   **Environment:** Production Cluster (Hybrid On-Prem + VPS).
*   **VPS Role:** Acts as the **Public Gateway** (Anchor IP) for incoming user traffic and specific outgoing business traffic (Akash).
*   **Bandwidth:** 1Gb/s Unmetered (IONOS).
*   **Strategy:** "Split Horizon" routing. Maximize performance/latency by routing traffic locally when possible, and via VPS only when necessary for identity (IP Reputation) or accessibility (Public Ingress).

## 2. Route Definition

### Route A: Ingress (Internet -> VPS -> Cluster)
*   **Goal:** Single public entry point (`74.208.250.178`).
*   **Architecture:** **Cilium Gateway API** acts as the L4/L7 Front Door.
*   **Traffic Split:**
    1.  **Akash Ingress (High Priority):**
        *   **Mechanism:** **TLSRoute (Passthrough)**.
        *   **Flow:** Internet -> VPS (Port 80/443) -> Cilium Gateway -> Akash NGINX Ingress Controller.
        *   **Reasoning:** Akash requires its own Ingress logic to manage tenant domains dynamically. Cilium blindly forwards the encrypted SNI traffic to Akash's NGINX, ensuring 100% compatibility without "touching" the traffic.
    2.  **System/App Ingress:**
        *   **Mechanism:** **HTTPRoute (Termination)**.
        *   **Flow:** Internet -> VPS -> Cilium Gateway (TLS Termination via Cert-Manager) -> Internal Services (ArgoCD, Monitoring).
        *   **Certificates:** Cloudflare DNS-01 for `*.domain.com`.

### Route B: Inter-Node (Node <-> Node)
*   **Goal:** Secure, private communication between Control Plane (Home) and Edge/Gateway (VPS).
*   **Mechanism:** **Tailscale (WireGuard)**.
*   **Addressing:** All internal K8s traffic uses the `100.x.x.x` overlay network.
*   **Optimization:**
    *   **MSS Clamping:** Critical configuration in Cilium/Firewall to prevent packet fragmentation inside the UDP tunnel.
    *   **Encryption:** Handled by Tailscale. Cilium WireGuard is **DISABLED** to avoid double-encryption performance hits.

### Route C: Egress (Internet <- Node)
*   **Goal:** Traffic discrimination based on workload identity.
*   **Mechanism:** **Cilium Egress Gateway**.
*   **Policy 1: Business Identity (Akash)**
    *   **Source:** Namespace `akash-services` (or specific tenant labels).
    *   **Route:** Tunnel to `k3s-vps` -> SNAT (Masquerade as `74.208.250.178`) -> Internet.
    *   **Benefit:** Akash Providers/Tenants see a static, high-reputation Data Center IP. Critical for reliability scores.
*   **Policy 2: Operational (Default)**
    *   **Source:** `kube-system`, Image Pulls, OS Updates.
    *   **Route:** Direct via `eth0` (Local ISP Gateway).
    *   **Benefit:** Zero latency overhead for heavy downloads. Distributed bandwidth usage.

## 3. Akash "Smooth Path" Specifics
To ensure the VPS setup aids rather than hinders Akash:
*   **Dedicated Passthrough:** Using `TLSRoute` prevents the Gateway from interfering with Akash's complex certificate management.
*   **IP Stability:** Egress Gateway ensures that even if the workload runs physically at "Home", the world sees it coming from the "VPS".
*   **Resource Priority:** The VPS is primarily a network appliance. CPU/RAM on the VPS should be prioritized for traffic shaping (Cilium/eBPF) rather than running heavy compute workloads.

## 4. Validated Architecture (2025-01 Review)

### TLSRoute Passthrough: CONFIRMADO
Cilium Gateway API soporta `TLSRoute` con `mode: Passthrough` oficialmente. Requiere:
- Instalar CRD TLSRoute separadamente: `kubectl apply -f https://...gateway-api/.../tlsroute.yaml`
- SNI-based routing funciona para separar Akash vs servicios internos

### Coexistencia Gateway API + Nginx Akash: VIABLE
```
Internet → VPS:443 → Cilium Gateway (L4 TLSRoute passthrough)
                          │
                          ├─→ SNI: *.akash.network → Akash Nginx Ingress
                          │
                          └─→ SNI: *.tudominio.com → Cilium HTTPRoute (TLS termination)
```
No hay conflicto - son paths separados. Cilium actúa como router L4 puro para Akash.

### VPS como SPOF: RIESGO ACEPTADO
Recursos VPS: 2 vCore, 4GB RAM, 120GB disco, 1Gbps.
- Prioridad absoluta: función de networking
- Todo lo demás (Longhorn replica, workloads) es secundario
- Si VPS cae, negocio Akash se detiene - aceptado conscientemente para poder operar
