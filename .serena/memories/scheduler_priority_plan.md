# Scheduler Intelligence & Priority Strategy (Anti-Fragile Design)

## 1. Philosophy
In a resource-constrained environment (Fixed Hardware + 1 VPS) without auto-scaling, the Kubernetes Scheduler must be empowered to make ruthless decisions to preserve system integrity and SLA compliance.
*   **Goal:** Guarantee survival of critical components and revenue-generating workloads (SLA) at the expense of disposable tasks (Mining) or deferrable systems (Observability).
*   **Mechanism:** Strict `PriorityClass` hierarchy with aggressive Preemption.

## 2. Priority Hierarchy (The Pyramid of Survival)

### Level 1: System Integrity (Untouchable)
*   **Name:** `system-node-critical` / `system-cluster-critical` (Built-in)
*   **Value:** 2000000000+
*   **Scope:** Cilium (CNI), SPIRE Agent, Kube-Proxy, CoreDNS, Tailscale.
*   **Impact:** If these die, the cluster partitions or crashes. **Never preempted.**

### Level 2: IT Operations & Data Safety (High)
*   **Name:** `priority-ops-critical`
*   **Value:** 1,000,000
*   **Scope:** Longhorn (Storage), Vault, Cert-Manager, Kyverno, Gateway Controllers.
*   **Rationale:** Storage integrity and security enforcement must persist to support the business layer.

### Level 3: Business Revenue / SLA (Medium-High)
*   **Name:** `priority-akash-prod`
*   **Value:** 500,000
*   **Scope:** Akash Tenant Workloads.
*   **Rationale:** Direct revenue generation. SLAs must be met. Prioritized *above* observability to ensure service continuity during resource contention.

### Level 4: Observability (Medium)
*   **Name:** `priority-observability`
*   **Value:** 100,000
*   **Scope:** Prometheus, Grafana, Loki.
*   **Rationale:** "Fly blind" is better than "Crash land". In extreme pressure, metrics collection is sacrificed to keep client workloads running.

#### ⚠️ Tradeoff Aceptado (2025-01 Review)
Escenario: Akash tenant consume recursos → evicta Prometheus/Loki → pierdes visibilidad cuando más la necesitas.
**Decisión consciente:** Clientes Akash generando income = presupuesto para mejorar cluster > observabilidad temporal.
Mitigación: Healthchecks.io como Dead Man's Switch externo (ya planificado en Sección 10).

### Level 5: Background / Scavenger (Disposable)
*   **Name:** `priority-background`
*   **Value:** 1,000
*   **Scope:** Own Mining (CPU/GPU), Batch Jobs, Experiments.
*   **Rationale:** Pure scavengers. Immediate eviction (Preemption) if *any* higher tier needs resources (CPU, RAM, or the single GPU).

## 3. Implementation Strategy

### A. PriorityClass Objects
Define the custom classes with `preemptionPolicy: PreemptLowerPriority` enabled.

### B. Automated Assignment (Kyverno)
Do not rely on manual configuration. Use Kyverno `ClusterPolicy` to enforce priorities based on Namespace/Labels.
*   **Rule:** If Namespace is `monitoring` -> Assign `priority-observability`.
*   **Rule:** If Namespace is `akash-services` -> Assign `priority-akash-prod`.
*   **Rule:** If Label `app=miner` -> Assign `priority-background`.

### C. GPU Arbitrage logic
*   **Scenario:** Mining uses GPU. Akash Client requests GPU.
*   **Scheduler Action:** Detects conflict. Akash Priority (500k) > Mining Priority (1k).
*   **Result:** Miner pod receives `SIGTERM` instantly. GPU is released. Akash pod is scheduled.
