# Análisis Comparativo: k3s-homelab vs IDP Blueprint

**Fecha**: 2026-01-14
**Branch**: claude/analyze-k8s-it-dirs-HMFYd
**Propósito**: Mapear gaps y definir backlog para transformación a IDP productivo

---

## 📊 ESTADO ACTUAL DEL CLUSTER

### ✅ Fortalezas Implementadas

1. **Hardware Optimizado**
   - OS tuning completo: BBR, hugepages (2.5GB), MSR module
   - CPU governor: schedutil
   - Power management: lid/sleep/suspend disabled
   - Kernel: HWE con optimizaciones de red

2. **GPU Completamente Funcional**
   - NVIDIA drivers auto-detectados (nvidia-driver-535)
   - Container toolkit integrado con containerd
   - X11 headless para fan control
   - Persistence mode + Coolbits 28
   - Device plugin + NFD + GFD desplegados

3. **Red Híbrida Robusta**
   - **Tailscale**: Overlay VPN, API accesible remotamente
   - **Cilium**: CNI con kube-proxy replacement
   - **Separación limpia**: Cilium devices excluye tailscale0
   - **Hubble**: UI + metrics para observabilidad de red
   - **Gateway API**: Habilitado (sin Gateways CR aún)

4. **Cluster Operativo**
   - K3s v1.34.3+k3s1 single-node
   - API bind a Tailscale IP
   - Kubeconfig remoto funcional
   - Acceso desde cafetería validado ✅

5. **Mineros Productivos**
   - **XEL (CPU)**: ~0.2 XEL/día, compensa electricidad
   - **AVAX (GPU)**: Rigel Autolykos2
   - ResourceQuota en namespace miners
   - NetworkPolicy: deny ingress, allow egress DNS + internet

6. **Automatización Base**
   - Ansible 100% idempotente
   - 8 roles bien estructurados
   - Preflight checks (disk, RAM, connectivity)
   - Secrets vía Ansible Vault (opcional)

7. **Seguridad Básica**
   - Audit logs: `/var/log/k3s/audit.log` (30 días)
   - Secrets encryption en etcd
   - NetworkPolicies en miners namespace
   - SSH over Tailscale only

---

## ❌ GAPS CRÍTICOS VS IDP BLUEPRINT

| Componente | Estado | Prioridad | Impacto en Producción |
|------------|--------|-----------|------------------------|
| **ArgoCD** | ❌ Ausente | 🔴 Crítica | Sin GitOps = deployment manual, sin drift detection, sin rollback |
| **Prometheus Stack** | ❌ Ausente | 🔴 Crítica | Sin métricas = ceguera operacional, no SLOs, no alertas |
| **PriorityClasses** | ❌ Ausente | 🔴 Crítica | Mineros no evictables, competirán con workloads productivos |
| **External Secrets Operator** | ❌ Ausente | 🟡 Alta | Necesario para GCP Secret Manager integration |
| **Cert-Manager** | ❌ Ausente | 🟡 Alta | Requerido para TLS automatizado en roura.xyz |
| **Ingress/Gateway** | ⚠️ Parcial | 🟡 Alta | Gateway API habilitado pero sin Gateway CR ni HTTPRoutes |
| **Argo Workflows** | ❌ Ausente | 🟡 Alta | Sin CI/CD automatizado para pipelines |
| **Loki + Fluent-Bit** | ❌ Ausente | 🟢 Media | Log aggregation para troubleshooting |
| **Kyverno** | ❌ Ausente | 🟢 Media | Policy enforcement, governance, compliance |
| **Argo Events** | ❌ Ausente | 🟢 Media | Event-driven automation, self-healing |
| **Backstage** | ❌ Ausente | 🟢 Baja | Portal dev, última prioridad |

---

## 🔄 DIFERENCIAS ARQUITECTURALES

### Demo (k3d) → Producción (bare-metal)

| Aspecto | Demo IDP Blueprint | k3s-homelab Target |
|---------|-------------------|---------------------|
| **Entorno** | k3d (Docker containers) | Bare-metal ASUS RoG |
| **Propósito** | Experimentación/aprendizaje | Producción con exposición real |
| **Secrets** | Vault standalone (Raft, demo) | GCP Secret Manager (6 secrets max free) + ESO |
| **Exposición** | nip.io local (*.192-168-x-x.nip.io) | Cloudflare DNS (*.roura.xyz) + método TBD |
| **TLS** | Self-signed CA | Let's Encrypt (cert-manager) |
| **SonarQube** | ✅ Desplegado en cluster | ❌ Omitido (solo en pipelines externos) |
| **Trivy** | ✅ Trivy Operator continuo | ❌ Solo en pipelines CI/CD |
| **Carga Adicional** | Ninguna | ✅ Mineros XEL/AVAX (prioridad baja, evictables) |
| **Red** | Docker bridge + port mapping | Tailscale mesh + Cilium tunnel |
| **Nodos** | 1 server + 2 agents (contenedores) | 1 bare-metal hoy, multi-node geo-distribuido futuro |
| **Storage** | Ephemeral (demo) | Persistente, backups requeridos |
| **Hardening** | Mínimo (local only) | Producción (PSS, RBAC estricto, network policies) |
| **SLOs** | Demo (paper SLOs) | Reales (compensar electricidad, posible SLA firmado) |
| **Escalamiento** | No aplica | Dinámico (optimizar uso de recursos) |

---

## 🎯 CAMBIOS IDENTIFICADOS EN EL PROYECTO

### Ya Implementado (Divergencias Positivas)

✅ **Ansible reemplaza Taskfile**: Más poderoso para bare-metal OS management
✅ **Tailscale integrado**: VPN overlay como capa de red estable
✅ **GPU support completo**: NVIDIA drivers + device plugin + headless X11
✅ **OS hardening exhaustivo**: Kernel tuning, drivers optimizados, power management
✅ **Mineros como workload**: ResourceQuota, NetworkPolicy, node labels
✅ **Secrets encryption**: etcd encryption at rest
✅ **API audit logging**: Configurado con retention policies

### Pendiente de Implementar

Ver backlog por fases más abajo.

---

## 📋 BACKLOG PROPUESTO

### 🔴 FASE 1: Fundación GitOps (Bloqueante)

**Objetivo**: Habilitar continuous deployment declarativo

- [ ] **1.1** Desplegar ArgoCD via Ansible role
  - Helm chart v8.6.0+ con values adaptados del blueprint
  - Bind a Tailscale IP o ClusterIP
  - Admin password vía secret (preparar para ESO después)

- [ ] **1.2** Crear 6 AppProjects
  - `cicd` - CI/CD pipelines
  - `events` - Event-driven automation
  - `observability` - Monitoring/logging
  - `policies` - Governance/compliance
  - `security` - Vulnerability scanning
  - `production` - Workloads productivos (incluye miners)

- [ ] **1.3** Migrar manifests existentes a estructura GitOps
  ```
  k8s/
  ├── bootstrap/          # Namespaces, PriorityClasses (manual)
  ├── production/
  │   ├── applicationset-production.yaml
  │   ├── governance/     # ResourceQuota, LimitRange
  │   ├── infrastructure/ # SecretStores, RBAC
  │   └── miners/         # Mineros migrados
  └── observability/
      └── (vacío por ahora)
  ```

- [ ] **1.4** Crear ApplicationSet para production stack
  - Git directory generator: `k8s/production/*`
  - Sync policy: automated con prune
  - Sync waves configurados

- [ ] **1.5** Validar ArgoCD healthy y syncing miners
  - Health checks custom para miners (tolerarCrashLoopBackOff si pool down)
  - Logs de sync en ArgoCD UI

**Entregable**: Cluster 100% GitOps-managed, cambios solo via Git

---

### 🔴 FASE 2: Observabilidad Básica (Crítica)

**Objetivo**: Visibilidad de métricas y recursos

- [ ] **2.1** Desplegar Prometheus Operator CRDs
  - Via Helm chart (CRDs separados)

- [ ] **2.2** Desplegar kube-prometheus-stack
  - Prometheus: 6h retention (bare-metal, puede ajustarse)
  - Grafana: Admin password vía secret
  - Alertmanager: Configuración básica
  - Node Exporter: Collectors mínimos (CPU, mem, disk, network)
  - Kube-State-Metrics: Whitelist resources

- [ ] **2.3** ServiceMonitors para componentes core
  - ArgoCD (30s interval)
  - Cilium Hubble (60s interval)
  - NVIDIA GPU metrics (via dcgm-exporter, añadir)
  - Miners APIs (Rigel 4067, TNN si expone)

- [ ] **2.4** Dashboards básicos en Grafana
  - Cluster overview (CPU, RAM, disk, network)
  - GPU utilization (temp, power, hashrate)
  - Miners performance (hashrate, uptime, earnings estimate)
  - ArgoCD sync status

- [ ] **2.5** PriorityClasses (adaptadas del blueprint)
  ```yaml
  1. platform-infrastructure (1000000) - ArgoCD, Prometheus
  2. platform-observability (10000) - Grafana, Loki
  3. platform-cicd (7500) - Argo Workflows
  4. platform-dashboards (5000) - Grafana, Hubble UI
  5. production-workloads (3000) - Futuros workloads productivos
  6. mining-workloads (-1000) - Mineros (evictables)
  ```

- [ ] **2.6** Aplicar PriorityClasses a miners
  - CPU miner: `mining-workloads`
  - GPU miner: `mining-workloads`
  - Preemption policy: PreemptLowerPriority

**Entregable**: Grafana expuesto (Tailscale/local), dashboards funcionales, mineros evictables

---

### 🟡 FASE 3: Secrets & TLS (Pre-Exposición)

**Objetivo**: Gestión segura de secrets y TLS automatizado

- [ ] **3.1** Desplegar cert-manager
  - Helm chart v1.19.0+
  - Priority: `platform-infrastructure`

- [ ] **3.2** Configurar ClusterIssuers
  - `letsencrypt-staging` - Para testing
  - `letsencrypt-prod` - Para *.roura.xyz
  - DNS01 challenge via Cloudflare API token (secret)

- [ ] **3.3** Desplegar External Secrets Operator
  - Helm chart latest stable
  - GCP Secret Manager backend

- [ ] **3.4** Definir 6 secrets en GCP Secret Manager
  - **Propuesta inicial** (validar):
    1. `argocd-admin-password`
    2. `grafana-admin-password`
    3. `github-pat` (ArgoCD + Backstage futuro)
    4. `docker-registry-credentials` (pull privado)
    5. `cloudflare-api-token` (cert-manager DNS01)
    6. `mining-wallets` (XEL + AVAX addresses)

- [ ] **3.5** Crear SecretStores por namespace
  - `observability` → GCP Secret Manager
  - `argocd` → GCP Secret Manager
  - `production` → GCP Secret Manager

- [ ] **3.6** Migrar secrets existentes a ExternalSecrets
  - `argocd-admin` ExternalSecret
  - `grafana-admin` ExternalSecret
  - `mining-wallets` ExternalSecret
  - Validar sync exitoso antes de borrar secrets legacy

**Entregable**: Secrets centralizados en GCP, cert-manager listo para TLS

---

### 🟡 FASE 4: Exposición Pública (Networking)

**Objetivo**: Servicios accesibles en *.roura.xyz

- [ ] **4.1** Decidir método de exposición
  - **Opción A**: Cloudflare Tunnel (recomendado para homelab)
  - **Opción B**: Nginx Ingress + Cloudflare proxy mode
  - **Opción C**: Tailscale Operator (VPN-only, no público)

- [ ] **4.2** Si Cloudflare Tunnel:
  - Instalar cloudflared como DaemonSet
  - Tunnel token en GCP Secret Manager → ExternalSecret
  - Configurar tunnel routes en Cloudflare dashboard

- [ ] **4.3** Si Nginx Ingress:
  - Desplegar Nginx Ingress Controller
  - Configurar LoadBalancer NodePort (30080/30443)
  - Port forwarding en router si necesario

- [ ] **4.4** Crear Gateway CR (si se usa Gateway API)
  - GatewayClass: `cilium` o `nginx`
  - Listeners: HTTP (redirect) + HTTPS
  - TLS: cert-manager Certificate para *.roura.xyz

- [ ] **4.5** Definir servicios a exponer
  - **Candidatos**:
    - `argocd.roura.xyz` - ArgoCD UI (decisión: ¿sí/no?)
    - `grafana.roura.xyz` - Grafana dashboards (¿sí/no?)
    - `hubble.roura.xyz` - Hubble UI (¿sí/no?)
  - **Futuros**:
    - `backstage.roura.xyz` - Developer portal (fase 8)

- [ ] **4.6** Crear HTTPRoutes o Ingress resources
  - TLS termination
  - Backend references a Services
  - Basic auth o OIDC (Dex) para proteger UIs

- [ ] **4.7** Validar exposición
  - Certificados válidos (Let's Encrypt)
  - HTTPS funcional
  - Latency < 200ms (SLO target)

**Entregable**: Al menos 1 servicio accesible públicamente en roura.xyz con TLS válido

---

### 🟢 FASE 5: CI/CD & Governance

**Objetivo**: Pipelines automatizados y policy enforcement

- [ ] **5.1** Desplegar Argo Events
  - EventBus (NATS)
  - Priority: `platform-events`

- [ ] **5.2** Desplegar Argo Workflows
  - Controller + Server
  - Workflow templates adaptados del blueprint
  - Docker credentials via ExternalSecret
  - Priority: controller=`platform-cicd`, pods=`cicd-execution`

- [ ] **5.3** Crear Workflow Templates
  - `docker-pipeline-mvp` - Clone, lint, build (Kaniko), test, push
  - `remediate-argocd-unhealthy` - Force-sync unhealthy apps
  - `remediate-externalsecret-failure` - Fix failed secret syncs
  - `scale-down-miners` - Pause miners on high load (custom)

- [ ] **5.4** Configurar EventSources
  - `alertmanager-eventsource` - Prometheus alerts
  - `argocd-notifications-eventsource` - ArgoCD sync events
  - `github-webhook-eventsource` - Push events (futuro)

- [ ] **5.5** Crear Sensors
  - `slo-remediation-sensor` - Auto-healing de SLO violations
  - `argocd-sync-sensor` - Notificaciones de sync

- [ ] **5.6** Desplegar Kyverno
  - Admission controller
  - Priority: `platform-policy`

- [ ] **5.7** Aplicar políticas del blueprint
  - `enforce-namespace-labels` (Enforce mode)
  - `require-component-labels` (Audit mode)
  - `audit-namespace-resource-governance` (Audit)

- [ ] **5.8** Políticas custom para producción
  - `enforce-priorityclass` - Todos los pods deben tener priorityClassName
  - `restrict-hostnetwork` - Solo miners y system pods
  - `require-resource-limits` - Evitar unbounded workloads

- [ ] **5.9** Desplegar Policy Reporter
  - UI dashboard para violations
  - Priority: `platform-dashboards`

**Entregable**: CI/CD funcional, policies enforced, auto-remediación básica

---

### 🟢 FASE 6: Logging & SLOs

**Objetivo**: Log aggregation y SLO-driven operations

- [ ] **6.1** Desplegar Loki
  - Single binary mode
  - Storage: PVC 10Gi (ajustable)
  - Retention: 7 días (bare-metal)

- [ ] **6.2** Desplegar Fluent-Bit
  - DaemonSet en todos los nodos
  - Output: Loki
  - Parser: Kubernetes metadata

- [ ] **6.3** Configurar Loki datasource en Grafana
  - Pre-configured via kube-prometheus-stack values

- [ ] **6.4** Desplegar Pyrra
  - SLO dashboard
  - Datasource: Prometheus

- [ ] **6.5** Definir SLOs productivos (no demo)
  - **SLO 1: Miner Uptime**
    - Target: 95% uptime (24h window)
    - Metric: `kube_deployment_status_replicas_available{deployment=~"unmineable-.*"}`
    - Objetivo: Garantizar compensación eléctrica

  - **SLO 2: GitOps Sync Health**
    - Target: 99% healthy (6h window)
    - Metric: `argocd_app_info{health_status="Healthy"}`
    - Objetivo: Detectar drift o fallas de sync

  - **SLO 3: API Availability**
    - Target: 99.9% availability (24h window)
    - Metric: `up{job="kubernetes-apiservers"}`
    - Objetivo: SLA interno

  - **SLO 4: GPU Utilization**
    - Target: >80% utilization cuando miners running (24h window)
    - Metric: `DCGM_FI_DEV_GPU_UTIL`
    - Objetivo: Maximizar ROI de hardware

  - **SLO 5: Gateway Latency**
    - Target: 95% requests < 200ms (p95, 6h window)
    - Metric: `envoy_cluster_upstream_rq_time_bucket` (si Cilium Gateway)
    - Objetivo: UX de servicios expuestos

  - **SLO 6: Secrets Sync**
    - Target: 97% ExternalSecrets Ready (6h window)
    - Metric: `externalsecret_status_condition{condition="Ready",status="True"}`
    - Objetivo: Prevenir fallas por secrets stale

- [ ] **6.6** Crear ServiceLevelObjective CRDs
  - 6 SLOs en `/k8s/observability/slo/`
  - Pyrra genera PrometheusRules automáticamente

- [ ] **6.7** Configurar Alertmanager routes
  - Ruta para SLO violations → Argo Events webhook
  - Ruta para critical alerts → (email/Slack/Discord TBD)

- [ ] **6.8** Integrar SLO alerts con Argo Events
  - `slo-remediation-sensor` trigger workflows
  - Ejemplo: Miner down → restart deployment

**Entregable**: Logs centralizados, SLOs monitoreados, alertas auto-remediadas

---

### 🟢 FASE 7: Optimizaciones & Hardening

**Objetivo**: Producción-ready security y performance

- [ ] **7.1** Pod Security Standards
  - Namespace labels:
    - `observability`: restricted
    - `cicd`: baseline (Kaniko necesita privileged)
    - `production/miners`: privileged (MSR, nvidia-smi)
    - `argocd`: restricted
  - Validar enforcement con Kyverno

- [ ] **7.2** RBAC Audit
  - Service accounts dedicados (no default)
  - Least-privilege roles
  - ClusterRoles solo donde necesario
  - Eliminar permisos `*` en verbs

- [ ] **7.3** Network Policies cluster-wide
  - Default deny ingress en todos los namespaces
  - Allowlist explícito:
    - Prometheus → ServiceMonitors (all namespaces)
    - Loki ← Fluent-Bit
    - ArgoCD → API server + Git
    - Grafana → Prometheus + Loki
  - Miners: mantener current policy (egress DNS + pools)

- [ ] **7.4** Resource Optimization
  - VPA (Vertical Pod Autoscaler) para ajustar requests/limits
  - Identificar over-provisioned workloads
  - CPU pinning para mineros (ya implementado, validar)

- [ ] **7.5** Miner Scheduling Strategy
  - Validar PriorityClass `mining-workloads` (-1000)
  - Preemption: `PreemptLowerPriority` enabled
  - Resource requests: 50% de capacidad actual (para permitir preemption)
  - Resource limits: sin cambios (pueden burst)
  - NodeSelector o tolerations (futuro multi-node)

- [ ] **7.6** Audit Policy ampliada
  - Secrets access logging (metadata)
  - Exec/attach events (RequestResponse)
  - RBAC decisions (RequestResponse)
  - Retention: 90 días (vs 30 actual)

- [ ] **7.7** GPU optimizations
  - MPS (Multi-Process Service) si múltiples workloads GPU futuro
  - Time-slicing si compartir GPU
  - DCGM exporter para métricas detalladas

- [ ] **7.8** Hugepages dinámicas
  - Ajustar allocación según workload actual
  - Script en Ansible para modificar `/etc/sysctl.conf` dinámicamente
  - Validar no over-subscribe (miners + sistema)

**Entregable**: Cluster hardened, optimizado, production-ready

---

### 🔵 FASE 8: Features Avanzadas (Opcional/Futuro)

**Objetivo**: Developer experience y alta disponibilidad

- [ ] **8.1** Backstage Portal
  - PostgreSQL via operator (CloudNativePG)
  - Dex OIDC provider
  - Job Renderer pattern del blueprint
  - Integración con ArgoCD API
  - Software catalog (futuros servicios)

- [ ] **8.2** Velero Backups
  - Schedule: diario 2AM
  - Backup: etcd, PVCs, manifests
  - Restore testing mensual
  - Storage: S3-compatible (Backblaze B2 o similar)

- [ ] **8.3** Multi-Node Preparation
  - Taints en master node: `node-role.kubernetes.io/control-plane:NoSchedule`
  - Affinity rules: platform en master, workloads en workers
  - Longhorn para storage distribuido (sustituir local-path)

- [ ] **8.4** Falco Runtime Security
  - Rules para detectar:
    - Unexpected process execution
    - Secret file access
    - Network anomalies
  - Alertas a Argo Events

- [ ] **8.5** Service Mesh avanzado
  - Cilium service mesh features:
    - Mutual TLS
    - L7 traffic management
    - Canary deployments

- [ ] **8.6** Cost Management
  - Kubecost (opensource)
  - Track mining profitability vs infra costs
  - Chargeback a namespaces

- [ ] **8.7** Chaos Engineering
  - Chaos Mesh para resilience testing
  - Experiments: pod kill, network latency, CPU stress
  - Validar auto-remediación

**Entregable**: IDP completo, HA-ready, developer-friendly

---

## 🤔 DECISIONES PENDIENTES DE VALIDACIÓN

### 1. GCP Secret Manager - ¿Qué 6 secrets priorizamos?

**Propuesta inicial**:
1. `argocd-admin-password` - Crítico, acceso a GitOps
2. `grafana-admin-password` - Observabilidad
3. `github-pat` - ArgoCD repo access + Backstage futuro
4. `docker-registry-credentials` - Private images (si aplica)
5. `cloudflare-api-token` - cert-manager DNS01 challenge
6. `mining-wallets` - XEL + AVAX addresses

**Alternativas**:
- Sustituir `docker-registry-credentials` por `dex-client-secret` (OIDC futuro)
- Añadir `webhook-secret` para Argo Events (¿necesario?)
- Rotar secrets cada 90 días (políticas de GCP)

**Pregunta**: ¿Aprobada la propuesta o hay cambios?

---

### 2. Exposición Pública - ¿Método preferido?

**Opción A: Cloudflare Tunnel** (Recomendado para homelab)
- ✅ Pros: No port forwarding, DDoS protection, free, fácil setup
- ❌ Contras: Dependencia de Cloudflare, latency +20-50ms

**Opción B: Nginx Ingress + Cloudflare Proxy**
- ✅ Pros: Control total, latency óptima si proxy mode off
- ❌ Contras: Requiere IP pública estable o DDNS, port forwarding

**Opción C: Tailscale Operator**
- ✅ Pros: Zero-trust, no exposición pública real, secure by default
- ❌ Contras: Solo accesible en Tailscale VPN (no público)

**Pregunta**: ¿Opción A, B, o C? ¿O híbrido (Tailscale para admin, Cloudflare para públicos)?

---

### 3. Servicios a Exponer - ¿Cuáles en roura.xyz?

**Candidatos inmediatos** (Fase 4):
- [ ] `argocd.roura.xyz` - ArgoCD UI (¿público o Tailscale-only?)
- [ ] `grafana.roura.xyz` - Dashboards (¿público con auth o Tailscale?)
- [ ] `hubble.roura.xyz` - Network observability (¿necesario público?)

**Candidatos futuros** (Fase 8):
- [ ] `backstage.roura.xyz` - Developer portal
- [ ] `api.roura.xyz` - API gateway (si apps futuras)

**Seguridad**:
- Public: Requiere auth fuerte (OAuth2 Proxy + Dex, o básico con Cloudflare Access)
- Tailscale-only: Sin auth adicional necesaria

**Pregunta**: ¿Qué se expone públicamente y qué solo vía Tailscale?

---

### 4. Mineros - ¿Estrategia de Eviction?

**Opción A: PriorityClass Negativa + Preemption** (Recomendado)
- Priority: `-1000` (mining-workloads)
- Preemption: `PreemptLowerPriority` enabled
- Resource requests: 50% de actual (6 CPU, 1.5Gi RAM para TNN)
- Resource limits: sin cambio
- **Comportamiento**: Scheduler evicta automáticamente si pod productivo no cabe

**Opción B: Best-Effort QoS**
- Requests: mínimos (100m CPU, 128Mi RAM)
- Limits: actuales (12 CPU, 3Gi RAM)
- No PriorityClass
- **Comportamiento**: OOMKilled si presión de memoria

**Opción C: DaemonSet + PDB**
- Convertir a DaemonSet
- PodDisruptionBudget: minAvailable=0 (forzar eviction)
- **Comportamiento**: Evictable pero re-schedule agresivo

**Pregunta**: ¿Opción A (recomendada), B, o C? ¿O estrategia custom?

---

### 5. Multi-Tenant Namespaces - ¿Estructura preferida?

**Opción A: Replicar Demo Exacto**
```
namespaces:
  - backstage
  - cicd
  - events
  - observability
  - policies
  - security
```

**Opción B: Adaptado a Realidad Actual**
```
namespaces:
  - argocd (ya existe implícitamente)
  - observability
  - cicd
  - events
  - policies
  - security
  - production (workloads productivos + miners)
  - staging (futuro)
```

**Opción C: Híbrido**
```
namespaces:
  - Platform tier: argocd, observability, cicd, events, policies, security
  - Workload tier: production, staging, miners (separado)
  - Developer tier: dev-*, ephemeral namespaces (futuro Backstage)
```

**Pregunta**: ¿Opción A, B, C, u otra estructura?

---

### 6. Storage - ¿Local-path o Longhorn?

**Opción A: Mantener local-path-provisioner**
- ✅ Pros: Simple, suficiente para single-node, ya funciona
- ❌ Contras: No replicación, no snapshots, no multi-node ready

**Opción B: Migrar a Longhorn**
- ✅ Pros: Replicación, snapshots, backups, multi-node ready
- ❌ Contras: Overhead (CPU/RAM), complejidad, overkill para single-node

**Opción C: Híbrido**
- Local-path: Para workloads ephemeral (logs, cache)
- Longhorn: Para workloads stateful (Prometheus, Loki, Grafana)

**Pregunta**: ¿Opción A (keep it simple) o B/C (preparar futuro)?

---

## ⚠️ CONSIDERACIONES TÉCNICAS CRÍTICAS

### Hardening Obligatorio (Cluster Expuesto)

1. **Pod Security Standards**
   - restricted: observability, argocd
   - baseline: cicd (Kaniko requiere privileged)
   - privileged: miners (MSR, nvidia-smi)

2. **RBAC Least-Privilege**
   - Service accounts dedicados (no `default`)
   - ClusterRoles solo donde necesario
   - Eliminar wildcards (`*`) en verbs

3. **Network Policies**
   - Default deny ingress en todos los namespaces
   - Allowlist explícito (Prometheus, Loki, ArgoCD)
   - Egress controlado (DNS + APIs necesarias)

4. **Secrets Management**
   - NUNCA secrets en Git (gitignored, pero enforce)
   - Siempre via External Secrets Operator
   - Rotación cada 90 días (GCP Secret Manager)

5. **TLS Everywhere**
   - Solo TLS 1.3
   - Ciphers modernos (no CBC, no SHA1)
   - HSTS headers en Gateway/Ingress

6. **Audit Logging**
   - Ampliar policy a 90 días retention
   - Secrets access: Metadata level
   - Exec/attach: RequestResponse level
   - RBAC decisions: RequestResponse

7. **Runtime Security** (Fase 8)
   - Falco para detectar anomalías
   - AppArmor/SELinux profiles (futuro)

---

### Optimizaciones Bare-Metal

1. **CPU Pinning**
   - Mineros: cores 16-27 (ya implementado con affinity `0x0FFF0000`)
   - Sistema: cores 0-15
   - IRQ steering: NIC interrupts a cores sistema

2. **Hugepages Dinámicas**
   - Actual: 2560Mi fijos (1280 pages)
   - Target: Ajustar según workload (miners vs productivo)
   - Script Ansible para modificar `/etc/sysctl.conf`

3. **NUMA Awareness** (si multi-socket futuro)
   - Topology Manager: single-numa-node policy
   - CPU Manager: static policy para guaranteed pods

4. **GPU Optimizations**
   - Persistence mode: ya enabled ✅
   - MPS (Multi-Process Service): si múltiples workloads GPU
   - Time-slicing: si compartir GPU entre pods
   - DCGM exporter: métricas detalladas (FASE 2)

5. **Network Tuning**
   - TCP BBR: ya enabled ✅
   - Ring buffers: 4096 (ya tuned ✅)
   - NIC offloads: optimizados para Realtek ✅
   - Cilium BBR bandwidth manager: enabled ✅

6. **I/O Scheduling**
   - Disk scheduler: `mq-deadline` para SSDs (validar)
   - I/O priority: miners = best-effort, platform = realtime

---

### Escalamiento Dinámico

1. **VPA (Vertical Pod Autoscaler)**
   - Target: Ajustar requests/limits según uso real
   - Exclude: Miners (requests fijos bajos, limits altos)
   - Mode: Auto (con PDB para evitar downtime)

2. **HPA (Horizontal Pod Autoscaler)**
   - No aplica a miners (Deployment con replicas=1)
   - Futuro: Apps stateless con HPA en CPU/memoria

3. **Cluster Autoscaler**
   - Solo si nodos efímeros (cloud VMs)
   - No aplica a bare-metal actual

4. **Karpenter** (Futuro)
   - Si hybrid cloud (bare-metal + cloud burst)
   - Provisionar VMs temporales en GCP/AWS para picos

---

## 📊 MÉTRICAS DE ÉXITO

### KPIs de Transformación

| Métrica | Estado Actual | Target Post-Implementación |
|---------|---------------|----------------------------|
| **GitOps Coverage** | 0% (push-based) | 100% (todo via ArgoCD) |
| **Mean Time to Deploy** | Manual (~30min) | <5 min (automated) |
| **Secrets in Git** | ⚠️ gitignored | 0 (todos en GCP SM) |
| **Observability** | Logs only | Metrics + Logs + Traces |
| **SLO Compliance** | No SLOs | 6 SLOs monitored |
| **Auto-Remediation** | None | 3+ workflows active |
| **Policy Enforcement** | Manual review | Automated (Kyverno) |
| **TLS Coverage** | None public | 100% public endpoints |
| **Backup Coverage** | 0% | etcd + PVCs daily |
| **Miner Eviction Time** | N/A (no eviction) | <30s (priority-based) |

---

## 🚀 ROADMAP ESTIMADO

**Duración Total**: ~8-12 semanas (part-time)

| Fase | Duración Estimada | Complejidad |
|------|-------------------|-------------|
| Fase 1: GitOps | 1-2 semanas | Media |
| Fase 2: Observabilidad | 1 semana | Baja |
| Fase 3: Secrets & TLS | 1-2 semanas | Alta (GCP integration) |
| Fase 4: Exposición | 1 semana | Media (decisiones de arquitectura) |
| Fase 5: CI/CD | 2 semanas | Alta (workflows complejos) |
| Fase 6: Logging & SLOs | 1 semana | Media |
| Fase 7: Hardening | 2 semanas | Alta (security audit) |
| Fase 8: Features Avanzadas | Ongoing | Variable |

**Hitos Críticos**:
- ✅ **Semana 2**: ArgoCD operational, miners GitOps-managed
- ✅ **Semana 4**: Grafana dashboards, PriorityClasses aplicadas
- ✅ **Semana 6**: External Secrets Operator, GCP SM integrado
- ✅ **Semana 8**: Al menos 1 servicio público en roura.xyz
- ✅ **Semana 12**: Production-ready con 6 SLOs monitored

---

## 📝 PRÓXIMOS PASOS

1. **Validar Backlog** con owner
   - Confirmar prioridades de fases
   - Resolver decisiones pendientes (6 decisiones críticas)
   - Ajustar roadmap según urgencias

2. **Setup Inicial**
   - Crear proyecto en GCP Secret Manager
   - Registrar dominio roura.xyz en Cloudflare (si no está)
   - Preparar repositorio Git structure para GitOps

3. **Comenzar Fase 1**
   - Crear Ansible role para ArgoCD
   - Migrar manifests a estructura app-of-apps
   - Deploy y validación

---

## 📚 REFERENCIAS

- **IDP Blueprint Analysis**: `/tmp/idp-blueprint-analysis.md`
- **Demo Repository**: https://github.com/rou-cru/idp-blueprint
- **Homelab Repository**: https://github.com/rou-cru/k3s-homelab
- **Branch Actual**: `claude/analyze-k8s-it-dirs-HMFYd`

---

**Última Actualización**: 2026-01-14
**Estado**: Backlog pendiente de validación
