# Network Security & Policy Constitution

## 1. Zero Trust Philosophy
*   **Default Stance:** Deny All.
*   **Enforcement:** Cilium Network Policies (CNP) + Kyverno Admission Control.
*   **Scope:** Strict segmentation between Untrusted Workloads (Akash Tenants) and Trusted Infrastructure (Control Plane, IT, Storage).

## 2. Tenant Isolation Rules (Akash Workloads)
**Target:** Namespaces managed by Akash (e.g., `akash-services` or dynamic tenant namespaces).

### A. Egress Restrictions (Salida del Pod)
1.  **Strict Blocking:**
    *   **DENY** to `World` (Direct Internet Access) *EXCEPT* via the designated Egress Gateway (VPS Tunnel).
    *   **DENY** to `Cluster-Internal` (Other Namespaces, Private IPs 10.0.0.0/8, 192.168.0.0/16).
    *   **DENY** to `Kube-APIServer` (Cluster IP `10.43.0.1` & External Tailscale IP). *Crucial protection against internal attacks.*
2.  **Allowed Traffic:**
    *   **CoreDNS:** Allow UDP/TCP port 53 to `kube-system/coredns`. (Required for basic functioning).
    *   **Public Internet:** Allowed *only* if routed through the Managed Egress Gateway (ensuring IP reputation consistency).

### B. Ingress Restrictions (Entrada al Pod)
1.  **Allowed Sources:**
    *   **Akash Ingress Controller:** To receive legitimate user traffic.
    *   **Prometheus (Monitoring):** Strictly identified by Cilium Identity (`source.identity == prometheus`). *IP-based rules are forbidden here.*
2.  **Blocked:** Everything else. Tenant A cannot talk to Tenant B.

## 3. Trusted Infrastructure Rules
**Target:** `kube-system`, `argocd`, `monitoring`, `vault`.

*   **Inter-Communication:** `Allow All` within the Trusted Zone. Flexibility for operational agility.
*   **API Access:**
    *   Allowed from Trusted Zones.
    *   Allowed from `tailscale0` interface (Admin Laptops, VPN).
    *   **Blocked** from Public Internet interfaces.

## 4. Runtime Security (Kyverno Enforcing)
To guarantee isolation regardless of Akash Provider configuration.

*   **Policy:** `Mutate` admission webhook.
*   **Rule:** "Force gVisor Runtime".
*   **Logic:**
    *   **Match:** Pods in `akash-services` (or tenant namespaces).
    *   **Action:** Patch `.spec.runtimeClassName` to `gvisor` (runsc).
*   **Benefit:** Provides kernel-level isolation even if the Network Policy fails or is misconfigured. Prevents container escapes.

## 5. Implementation Roadmap
1.  **Cilium:** Apply `CiliumClusterwideNetworkPolicy` for baseline "Deny Internal API for Tenants".
2.  **Kyverno:** Deploy ClusterPolicy for `runtimeClassName` injection.
3.  **Testing:** Verify DNS resolution works, but `curl 10.43.0.1` times out from inside a tenant pod.

## 6. Validated Technical Decisions (2025-01 Review)

### mTLS Strategy: Defense in Depth sin SPIRE (Fase Inicial)
SPIRE añade complejidad operacional significativa para cluster de 2 nodos. Bugs activos en Cilium v1.17.5-v1.18.0.

**Capas de protección implementadas:**
| Capa | Mecanismo | Protege Contra |
|------|-----------|----------------|
| Transport | Tailscale WireGuard | Sniffing inter-nodo |
| Network Identity | CiliumNetworkPolicy `fromEndpoints` | Lateral movement |
| Runtime Isolation | gVisor (recomendado por Akash) | Container escape |
| Admission Control | Kyverno mutations | Misconfigurations |

**Decisión:** Implementar NetworkPolicies + gVisor primero. Evaluar SPIRE después de 3-6 meses de operación si se detecta necesidad de mTLS workload-to-workload.

### Egress Gateway: Viable sin L7
Documentación Cilium confirma incompatibilidad L7 proxy + Egress Gateway. Solución validada:
- Egress Gateway para SNAT con IP VPS (reputación Akash)
- Políticas L3/L4 suficientes para control de egress (bloquear IPs internas)
- L7 inspection aplica solo a ingress (manejado por Nginx Akash)
