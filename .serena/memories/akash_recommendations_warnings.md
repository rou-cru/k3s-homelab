# Akash Network: Official Recommendations & Warnings

**Purpose**: Document specific component recommendations and warnings from Akash Network documentation to inform architectural decisions for `k3s-homelab`.

## 💾 Storage: Rook Ceph vs. Local Path
**Official Stance**: Akash strongly recommends **persistent storage** (Beta3) for production providers.
*   **Recommendation**: **Rook Ceph** is the standard, battle-tested solution for Akash Providers. It allows storage replication, high availability, and dynamic provisioning.
*   **Warning (Data Loss)**: Without a persistent storage class (Beta3), tenant data is **ephemeral** and vanishes on pod restart. This limits the provider to stateless workloads.
*   **Warning (Complexity)**: Rook Ceph is resource-intensive and complex. Providers have reported issues with correct storage reporting.
*   **Context for k3s-homelab**: Since we are single-node, full Ceph is overkill and adds unnecessary overhead. We use `local-path-provisioner`.
    *   *Action*: We must configure `local-path` to advertise itself as a valid storage class (potentially mapping it to `beta3` capability in provider config) but accept the single-node risk (no replication).

## 🕸️ CNI: Calico vs. Cilium
**Official Stance**: The automated Akash Provider builds (Ansible) default to **Calico**.
*   **Recommendation**: Calico is the "happy path" for standard Akash setups.
*   **Warning**: No explicit warning *against* Cilium exists, but it deviates from the standard reference architecture.
*   **Context for k3s-homelab**: We use **Cilium**.
    *   *Risk*: Potential incompatibilities with `akash-provider` network policies if they assume Calico CRDs or iptables behavior.
    *   *Mitigation*: Ensure standard Kubernetes NetworkPolicies are supported (Cilium supports them fully).

## 🚦 Ingress: Nginx
**Official Stance**: **Ingress Nginx** is the expected standard.
*   **Implicit Warning**: The `akash-hostname-operator` is tightly coupled with Nginx Ingress annotations and behavior. Using other controllers (Traefik, Cilium Gateway) requires "translation" or significant configuration overrides, increasing breakage risk.
*   **Context for k3s-homelab**: We confirmed this in previous steps. We will deploy **Ingress Nginx** specifically for Akash to align with this recommendation.

## 🧱 Runtime: gVisor
**Official Stance**: Sandbox is critical for multi-tenancy.
*   **Recommendation**: gVisor (`runsc`) is the standard for isolating untrusted tenant workloads.
*   **Context for k3s-homelab**: We are implementing this in Phase 0.

## 📝 Summary of Deviations
| Component | Akash Standard | k3s-homelab | Status |
| :--- | :--- | :--- | :--- |
| **CNI** | Calico | Cilium | ⚠️ Deviated (Acceptable) |
| **Storage** | Rook Ceph | Local Path | ⚠️ Deviated (Single-node optimized) |
| **Ingress** | Nginx | Nginx (Dedicated) | ✅ Aligned |
| **Runtime** | gVisor | gVisor | ✅ Aligned |
