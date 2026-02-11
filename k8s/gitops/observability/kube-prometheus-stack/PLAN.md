# Plan de Integración: kube-prometheus-stack en k3s-homelab

**Fuente**: `rou-cru/idp-blueprint` (k3d demo)
**Destino**: `rou-cru/k3s-homelab` (k3s bare-metal, producción)
**Fecha**: 2026-02-11

---

## 1. ESTRUCTURA DE ARCHIVOS A CREAR

```
k8s/gitops/observability/kube-prometheus-stack/
├── kustomization.yaml          # Kustomize wrapper para Helm chart
├── values.yaml                 # Values adaptados para producción bare-metal
└── PLAN.md                     # Este documento (eliminar antes de merge)
```

El ApplicationSet `observability-stack` ya detectará este directorio automáticamente
y desplegará al namespace `monitoring` con sync automático.

---

## 2. ANÁLISIS LÍNEA POR LÍNEA: QUÉ CONSERVAR, QUÉ CAMBIAR

### 2.1 CRDs (`crds.enabled: false`)

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `crds.enabled: false` | **CONSERVAR** | CRDs se instalan en Fase 2 (bootstrap) vía Ansible role separado. ArgoCD no debe gestionar CRDs del Prometheus Operator porque causan race conditions en sync. |

**Acción**: Mantener idéntico. Los CRDs ya se instalan en `PHASE 2: CLUSTER` del playbook.

---

### 2.2 Default Rules

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `etcd: false` | **CAMBIAR → true** | K3s usa embedded etcd (sqlite por defecto en single-node, pero etcd si multi-node). Si se usa etcd embebido, las reglas aplican. Verificar con `k3s server --cluster-init`. Si es sqlite, mantener false. |
| `kubeProxy: false` | **CONSERVAR** | Cilium reemplaza kube-proxy (`kubeProxyReplacement: true` en cilium values). |
| `kubeScheduler: false` | **CAMBIAR → true** | En K3s bare-metal el scheduler existe y es accesible. A diferencia de k3d, tenemos acceso directo al proceso. Se scrapea vía `additionalScrapeConfigs`. |
| Resto | **CONSERVAR** | Reglas estándar de Kubernetes aplican igual. |

---

### 2.3 Alertmanager

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `enabled: true` | **CONSERVAR** | Necesario para alertas y futuro Pyrra. |
| `priorityClassName: platform-observability` | **CAMBIAR → `priority-observability`** | El homelab usa nombres diferentes de PriorityClasses. `priority-observability` (value: 100000) ya está definido en `k8s/bootstrap/priorityclasses/observability.yaml`. |
| `resources` (25m/64Mi → 100m/128Mi) | **AUMENTAR** | Producción bare-metal tiene más recursos. Aumentar a: requests 50m/128Mi, limits 200m/256Mi. |
| `receiver: argo-events-webhook` | **CAMBIAR → `null` (temporalmente)** | Argo Events no está desplegado aún (Fase 5). Usar receiver `null` o un webhook placeholder. Cuando se despliegue Argo Events, actualizar la ruta. |
| `group_wait/interval` | **CAMBIAR** | Para producción: `group_wait: 30s`, `group_interval: 5m`, `repeat_interval: 4h`. Los valores del blueprint (10s/10s) son agresivos para demo. |

**Config Alertmanager propuesta**:
```yaml
config:
  route:
    group_by: ['alertname', 'namespace', 'job']
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 4h
    receiver: 'null'
    routes:
      - match:
          severity: critical
        receiver: 'null'  # TODO: Configurar webhook cuando Argo Events esté listo
  receivers:
    - name: 'null'
```

---

### 2.4 Exporters (kubeEtcd, kubeControllerManager, kubeScheduler, kubeProxy)

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `kubeEtcd.enabled: false` | **EVALUAR** | K3s single-node usa SQLite por defecto (no etcd). Si `--cluster-init` está activo, K3s usa embedded etcd y se debe habilitar. Verificar configuración actual del servidor. |
| `kubeControllerManager.enabled: false` | **CONSERVAR** | En K3s, controller-manager corre integrado en el binario. Se scrapea vía `additionalScrapeConfigs` (ya presente en blueprint). |
| `kubeScheduler.enabled: false` | **CONSERVAR** | Mismo caso. Se scrapea vía `additionalScrapeConfigs`. |
| `kubeProxy.enabled: false` | **CONSERVAR** | Cilium con `kubeProxyReplacement: true`. No existe kube-proxy. |

**IMPORTANTE sobre additionalScrapeConfigs**: Los scrape configs del blueprint para kube-scheduler (10259), kube-controller-manager (10257) y kube-proxy (10249) necesitan validación en K3s:
- K3s expone scheduler en `127.0.0.1:10259` (HTTPS) - **verificar bind address**
- K3s expone controller-manager en `127.0.0.1:10257` (HTTPS) - **verificar bind address**
- kube-proxy scrape config: **ELIMINAR** (no existe con Cilium)

**Acción**: Eliminar el scrape config de `kube-proxy`. Mantener scheduler y controller-manager pero validar que K3s expone esos puertos en la IP del nodo (puede requerir flags `--kube-scheduler-arg=bind-address=0.0.0.0` en K3s config).

---

### 2.5 Prometheus

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `priorityClassName: platform-observability` | **CAMBIAR → `priority-observability`** | Nombre de PriorityClass del homelab. |
| `*SelectorNilUsesHelmValues: false` | **CONSERVAR** | Crítico para descubrir ServiceMonitors de todos los namespaces (ArgoCD, Cilium, etc.). |
| `scrapeInterval: 60s` | **CAMBIAR → 30s** | Producción bare-metal tiene recursos suficientes. 30s da mejor resolución para SLOs sin carga excesiva en single-node. |
| `scrapeTimeout: 40s` | **CAMBIAR → 25s** | Debe ser menor que scrapeInterval. |
| `retention: 24h` | **CAMBIAR → 15d** | En producción bare-metal con SSD local, 15 días de retención es razonable. El blueprint usa 24h porque k3d es efímero. |
| `storage: 1Gi` | **CAMBIAR → 20Gi** | Con 15d de retención y ~50 targets a 30s interval, 20Gi es conservador pero suficiente. Monitorear uso y ajustar. |
| `resources` (200m/512Mi → 500m/1536Mi) | **AUMENTAR** | Producción con más targets y retención: requests 500m/1Gi, limits 1000m/2Gi. |
| `additionalScrapeConfigs` | **MODIFICAR** | Eliminar kube-proxy job. Mantener scheduler y controller-manager. Agregar jobs para componentes específicos del homelab (ver sección 3). |

---

### 2.6 Grafana

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `priorityClassName: platform-dashboards` | **CAMBIAR → `priority-observability`** | No existe `platform-dashboards` en el homelab. Usar `priority-observability`. |
| `persistence: 1Gi` | **CAMBIAR → 5Gi** | Más dashboards, retención de anotaciones, producción. |
| `admin.existingSecret: grafana-admin-credentials` | **CONSERVAR** | ESO ya está desplegado y puede crear este secret. Crear ExternalSecret correspondiente. |
| `datasources` (Loki) | **CONSERVAR** | Loki será desplegado en su propio directorio. URL interna correcta. |
| `plugins` | **CONSERVAR + AGREGAR** | Mantener plugins existentes. Agregar `grafana-clock-panel` para dashboards de status. |
| `dashboards` | **MODIFICAR** | Ver sección 2.6.1 |
| `sidecar.dashboards` | **CONSERVAR** | Descubrimiento automático de ConfigMaps con dashboards. |
| `grafana.ini` | **CONSERVAR + AGREGAR** | Agregar configuración de anonymous access deshabilitado explícitamente para producción. |

#### 2.6.1 Dashboards - Análisis Individual

| Dashboard | Blueprint | Decisión | Razón |
|-----------|-----------|----------|-------|
| k8s-deployment (17685) | ✅ | **CONSERVAR** | Útil para monitorear deployments |
| k8s-statefulset (7581) | ✅ | **CONSERVAR** | Para Prometheus, Loki statefulsets |
| k8s-daemonset (14982) | ✅ | **CONSERVAR** | Para node-exporter, fluent-bit |
| k8s-resource (21839) | ✅ | **CONSERVAR** | Vista general de recursos |
| k8s-namespace (15758) | ✅ | **CONSERVAR** | Breakdown por namespace |
| k8s-overview (22082) | ✅ | **CONSERVAR** | Overview del cluster |
| cert-manager (20842) | ✅ | **CONSERVAR** | cert-manager ya desplegado |
| argocd (14584) | ✅ | **CONSERVAR** | ArgoCD ya desplegado con metrics |
| cilium-operator (17660) | ✅ | **CONSERVAR** | Cilium es el CNI |
| kyverno (15804) | ✅ | **POSPONER** | Kyverno no desplegado aún (Fase 5) |
| trivy-operator (17813) | ✅ | **POSPONER** | Trivy no desplegado aún |
| trivy-vulnerability (16742) | ✅ | **POSPONER** | Trivy no desplegado aún |
| loki-logs (15141) | ✅ | **CONSERVAR** | Loki será desplegado pronto |
| loki-logs-pod (16976) | ✅ | **CONSERVAR** | Complemento de logs por pod |
| **AGREGAR**: Node Exporter Full (1860) | ❌ | **AGREGAR** | Crítico para bare-metal: CPU, RAM, disco, temps, etc. |
| **AGREGAR**: NVIDIA GPU (12239) | ❌ | **AGREGAR** | GPU monitoring cuando DCGM exporter se agregue |

---

### 2.7 Prometheus Operator

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `priorityClassName: platform-observability` | **CAMBIAR → `priority-observability`** | PriorityClass del homelab. |
| `admissionWebhooks.certManager.enabled: true` | **CONSERVAR** | cert-manager ya desplegado con `ca-issuer` ClusterIssuer. |
| `admissionWebhooks.certManager.issuerRef.name: ca-issuer` | **CONSERVAR** | `ca-issuer` ya existe en el homelab. |
| `admissionWebhooks.failurePolicy: Ignore` | **CAMBIAR → Fail** | En producción, queremos que webhooks de validación de PrometheusRules fallen si el cert no es válido. Previene reglas malformadas. |
| `admissionWebhooks.patch.enabled: false` | **CONSERVAR** | Correcto con cert-manager. |
| `resources` (25m/32Mi → 50m/64Mi) | **AUMENTAR LIGERAMENTE** | Producción: requests 50m/64Mi, limits 100m/128Mi. |

---

### 2.8 Kube State Metrics

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `priorityClassName: platform-observability` | **CAMBIAR → `priority-observability`** | PriorityClass del homelab. |
| `extraArgs` (resource whitelist) | **CONSERVAR + AGREGAR** | Agregar `replicasets` y `ingresses` (si se usan). El whitelist approach es correcto para reducir cardinalidad. |
| `metricRelabelings` (drop uid, container_id, image_id) | **CONSERVAR** | Reduce cardinalidad significativamente. Buena práctica. |
| `resources` (25m/64Mi → 50m/128Mi) | **CONSERVAR** | Adecuado para producción. |

---

### 2.9 Node Exporter

| Blueprint | Decisión | Razón |
|-----------|----------|-------|
| `priorityClassName: platform-observability` | **CAMBIAR → `priority-observability`** | PriorityClass del homelab. |
| Collectors (minimal set) | **CAMBIAR → AMPLIAR** | El blueprint deshabilita defaults y activa solo un subset. Para bare-metal producción necesitamos más collectors. |
| `resources` (15m/24Mi → 30m/48Mi) | **AUMENTAR** | Con más collectors: requests 25m/48Mi, limits 50m/96Mi. |

**Collectors para bare-metal producción** (el blueprint omite varios críticos):

```yaml
extraArgs:
  - --collector.disable-defaults
  # Conservar del blueprint:
  - --collector.cpu
  - --collector.cpufreq
  - --collector.meminfo
  - --collector.diskstats
  - --collector.filesystem
  - --collector.netdev
  - --collector.loadavg
  - --collector.pressure
  - --collector.vmstat
  - --collector.stat
  - --collector.uname
  # AGREGAR para bare-metal:
  - --collector.hwmon        # Temperaturas de CPU/GPU/disco (CRÍTICO para laptop)
  - --collector.thermal_zone # Zonas térmicas del hardware
  - --collector.edac         # Errores de memoria ECC
  - --collector.powersupplyclass # Estado de batería (ASUS ROG es laptop)
  - --collector.schedstat    # Scheduler stats del kernel
  - --collector.conntrack    # Connection tracking (importante con Cilium)
  - --collector.entropy      # Entropy pool (seguridad)
  - --collector.timex        # Precisión del reloj (NTP drift)
  - --collector.sockstat     # Socket statistics
```

---

## 3. SCRAPE CONFIGS ADICIONALES PARA EL HOMELAB

Agregar a `additionalScrapeConfigs`:

```yaml
# Kubelet cAdvisor (métricas de contenedores - K3s expone en 10250)
- job_name: 'kubelet-cadvisor'
  kubernetes_sd_configs:
    - role: node
  scheme: https
  tls_config:
    insecure_skip_verify: true
  bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
  metrics_path: /metrics/cadvisor
  relabel_configs:
    - source_labels: [__meta_kubernetes_node_address_InternalIP]
      replacement: $1:10250
      target_label: __address__
```

**NOTA**: Eliminar el job `kube-proxy` del blueprint (Cilium lo reemplaza).

---

## 4. KUSTOMIZATION.YAML - ESTRUCTURA

El ApplicationSet de observability espera un directorio Kustomize. Necesitamos un wrapper:

```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
  - name: kube-prometheus-stack
    repo: https://prometheus-community.github.io/helm-charts
    version: "72.6.2"  # Última versión estable (verificar)
    releaseName: kube-prometheus-stack
    namespace: monitoring
    valuesFile: values.yaml
    includeCRDs: false
```

**ALTERNATIVA**: Si el CMP `kustomize-with-helm` del ArgoCD soporta `helmCharts` en Kustomize, esta estructura funciona. Si no, considerar usar un Application directamente con source tipo Helm.

**VERIFICAR**: El ArgoCD del homelab tiene configurado el plugin `kustomize-with-helm` (confirmado en `k8s/bootstrap/argocd/values.yaml` líneas 50-56). Validar que soporta `helmCharts` en kustomization.yaml.

---

## 5. DEPENDENCIAS Y PRERREQUISITOS

### 5.1 Antes de desplegar (ya completado)

- [x] Namespace `monitoring` creado (Ansible)
- [x] PriorityClass `priority-observability` definida
- [x] cert-manager desplegado con `ca-issuer` ClusterIssuer
- [x] External Secrets Operator desplegado
- [x] ArgoCD con ApplicationSet `observability-stack` configurado
- [x] Cilium con ServiceMonitor habilitado
- [x] ArgoCD con métricas habilitadas

### 5.2 Pendiente de crear

- [ ] CRDs de Prometheus Operator (instalar vía Ansible ANTES del chart)
- [ ] ExternalSecret `grafana-admin-credentials` en namespace `monitoring`
- [ ] Validar que K3s expone scheduler/controller-manager en IP del nodo
- [ ] Opcional: DCGM Exporter para métricas GPU (puede ser fase posterior)

### 5.3 Prerrequisitos CRDs

Los CRDs deben instalarse **antes** de que ArgoCD intente sincronizar el chart.
Opciones:
1. **Ansible role** (recomendado): Instalar CRDs en PHASE 2 del playbook, junto a los CRDs de Gateway API que ya se instalan ahí.
2. **Helm chart separado**: `prometheus-operator-crds` chart en un directorio aparte.
3. **ArgoCD sync wave**: Usar `argocd.argoproj.io/sync-wave: "-1"` pero requiere reestructurar el ApplicationSet.

**Recomendación**: Opción 1, agregar al role existente de CRDs.

---

## 6. AJUSTES AL APPPROJECT OBSERVABILITY

El AppProject actual (`k8s/bootstrap/argocd/projects/observability.yaml`) tiene:

```yaml
destinations:
  - namespace: monitoring
    name: in-cluster
clusterResourceWhitelist:
  - group: monitoring.coreos.com
    kind: '*'
  - group: ''
    kind: ServiceAccount
```

**Cambios necesarios**:
- Agregar `group: ''` + `kind: ClusterRole` y `ClusterRoleBinding` (el chart crea cluster-level RBAC)
- Agregar `group: rbac.authorization.k8s.io` + `kind: '*'` (ClusterRoles del chart)
- Agregar `group: admissionregistration.k8s.io` + `kind: '*'` (ValidatingWebhookConfiguration)
- Agregar `group: policy` + `kind: PodSecurityPolicy` (si PSP está habilitado, probablemente no en K3s moderno)

**AppProject actualizado propuesto**:
```yaml
clusterResourceWhitelist:
  - group: monitoring.coreos.com
    kind: '*'
  - group: ''
    kind: ServiceAccount
  - group: rbac.authorization.k8s.io
    kind: '*'
  - group: admissionregistration.k8s.io
    kind: '*'
  - group: ''
    kind: ConfigMap
```

---

## 7. RESUMEN DE CAMBIOS POR PRIORIDAD

### Críticos (bloquean despliegue)

1. Crear `kustomization.yaml` con referencia al Helm chart
2. Crear `values.yaml` adaptado (todo lo documentado arriba)
3. Instalar CRDs de Prometheus Operator (Ansible o chart separado)
4. Crear ExternalSecret para `grafana-admin-credentials`
5. Actualizar AppProject `observability` con cluster resources necesarios

### Importantes (afectan funcionalidad)

6. Validar bind address de scheduler/controller-manager en K3s
7. Eliminar scrape config de kube-proxy
8. Ajustar PriorityClass names en todo el values
9. Configurar retención y storage para producción (15d, 20Gi)
10. Ampliar collectors del node-exporter para bare-metal

### Deseables (mejoran calidad)

11. Agregar dashboard Node Exporter Full (gnetId: 1860)
12. Agregar dashboard NVIDIA GPU
13. Configurar Alertmanager con rutas de producción
14. Ajustar Grafana con configuración de seguridad (disable signups, etc.)
15. Agregar collectors de hardware (hwmon, thermal_zone, powersupply)

---

## 8. DIFERENCIAS CLAVE K3D vs K3S BARE-METAL

| Aspecto | k3d (blueprint) | k3s bare-metal (homelab) |
|---------|-----------------|--------------------------|
| **Retención** | 24h (efímero) | 15d (persistente) |
| **Storage** | 1Gi (demo) | 20Gi (producción) |
| **Node Exporter** | Collectors mínimos | Collectors extendidos (hwmon, thermal) |
| **Scrape Interval** | 60s (ahorro) | 30s (mejor resolución SLOs) |
| **Alertmanager** | Argo Events webhook | null → webhook (cuando exista) |
| **Grafana persistence** | 1Gi | 5Gi |
| **Resources** | Mínimos (demo) | Producción (2x-4x) |
| **kube-proxy** | Deshabilitado (k3d) | Deshabilitado (Cilium) - mismo |
| **etcd** | No existe (k3d) | Potencialmente embedded |
| **Priority Classes** | platform-* | priority-* |
| **Webhooks failurePolicy** | Ignore (demo) | Fail (producción) |
| **Dashboards** | Incluye Kyverno/Trivy | Sin Kyverno/Trivy (no desplegados) |
| **Hardware monitoring** | No necesario | Crítico (temps, batería, fans) |
