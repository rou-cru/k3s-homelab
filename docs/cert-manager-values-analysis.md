# Análisis de valores de cert-manager Helm Chart

## 📊 Configuración Actual vs Capacidades Disponibles

### Configuración actual en el proyecto
```yaml
# roles/cert_manager/tasks/main.yml:24
values:
  installCRDs: true
```

**Observación**: La configuración actual es minimalista y solo define la instalación de CRDs.

---

## 🎯 Oportunidades de Mejora Identificadas

### 1. **Alta Disponibilidad (HA)** - CRÍTICO para producción

#### Estado actual:
- ✗ **Controller**: 1 replica (default)
- ✗ **Webhook**: 1 replica (default)
- ✗ **CA Injector**: 1 replica (default)
- ✗ **PodDisruptionBudget**: Deshabilitado

#### Recomendación:
```yaml
values:
  # Controller HA
  replicaCount: 2  # Mínimo 2-3 para producción
  podDisruptionBudget:
    enabled: true
    minAvailable: 1

  # Webhook HA
  webhook:
    replicaCount: 2
    podDisruptionBudget:
      enabled: true
      minAvailable: 1

  # CA Injector HA
  cainjector:
    replicaCount: 2
    podDisruptionBudget:
      enabled: true
      minAvailable: 1
```

**Impacto**: Evita downtime durante actualizaciones de nodos o disrupciones voluntarias.

---

### 2. **Monitoreo con Prometheus** - ALTA PRIORIDAD

#### Estado actual:
- ✗ No hay configuración de ServiceMonitor/PodMonitor
- ℹ️  El proyecto tiene `argocd_servicemonitor_enabled: true` para ArgoCD

#### Configuración disponible:
```yaml
values:
  prometheus:
    enabled: true  # Ya está habilitado por default
    servicemonitor:
      enabled: true  # 🔥 ACTIVAR ESTO
      prometheusInstance: default
      interval: 60s
      scrapeTimeout: 30s
      labels:
        prometheus: kube-prometheus  # O el label de tu Prometheus Operator
```

**Beneficios**:
- Métricas de certificados expirando
- Problemas con ACME challenges
- Errores de renovación
- Performance de validations

---

### 3. **Recursos (Requests/Limits)** - RECOMENDADO

#### Estado actual:
- ✗ Sin recursos definidos (usa defaults de Kubernetes)

#### Recomendación basada en best practices:
```yaml
values:
  # Controller
  resources:
    requests:
      cpu: 50m      # Suficiente para carga moderada
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi

  # Webhook
  webhook:
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
      limits:
        cpu: 100m
        memory: 64Mi

  # CA Injector
  cainjector:
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
      limits:
        cpu: 100m
        memory: 128Mi
```

**Beneficios**:
- QoS garantizado (Guaranteed class si requests == limits)
- Previene evictions por falta de recursos
- Mejor scheduling

---

### 4. **Gestión de CRDs Moderna** - MEJORA

#### Estado actual:
```yaml
values:
  installCRDs: true  # Método deprecated
```

#### Método recomendado:
```yaml
values:
  installCRDs: false  # Deshabilitar el deprecated
  crds:
    enabled: true   # Método moderno
    keep: true      # Protege los CRDs de uninstall accidental
```

**Nota**: El método `installCRDs` está deprecated. La nueva forma es usar `crds.enabled`.

---

### 5. **Seguridad y Compliance** - OPCIONAL pero RECOMENDADO

#### Configuraciones de seguridad avanzadas:

```yaml
values:
  # Network Policies (aislamiento de red)
  networkPolicy:
    enabled: true
    ingress:
      - ports:
        - port: http-metrics
          protocol: TCP
        - port: http-healthz
          protocol: TCP
    egress:
      - ports:
        - port: 80
          protocol: TCP
        - port: 443
          protocol: TCP
        - port: 53
          protocol: TCP
        - port: 53
          protocol: UDP
        - port: 6443  # Kubernetes API
          protocol: TCP

  webhook:
    networkPolicy:
      enabled: true

  cainjector:
    networkPolicy:
      enabled: true

  # Security contexts ya están hardened por default:
  # - runAsNonRoot: true
  # - readOnlyRootFilesystem: true
  # - capabilities: drop ALL
  # - seccompProfile: RuntimeDefault
```

**Beneficio**: Cumplimiento con políticas de seguridad enterprise (zero-trust).

---

### 6. **Estrategia de Actualización** - MEJORA OPERACIONAL

#### Configuración recomendada:
```yaml
values:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1

  webhook:
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 0
        maxUnavailable: 1

  cainjector:
    strategy:
      type: RollingUpdate
      rollingUpdate:
        maxSurge: 0
        maxUnavailable: 1
```

**Beneficio**: Actualizaciones sin overhead de recursos (no crea pods extra).

---

### 7. **Logging y Verbosidad** - DEBUGGING

#### Estado actual:
- ⚠️  Default: `logLevel: 2` (moderate)

#### Para troubleshooting:
```yaml
values:
  global:
    logLevel: 4  # Aumentar temporalmente para debug
```

**Niveles**: 0 (panic) → 6 (trace). Default 2 es suficiente para producción.

---

### 8. **DNS01 Challenge para ACME** - SI USAS LETSENCRYPT

#### Si usas DNS challenges para certificados wildcard:
```yaml
values:
  # Nameservers custom para DNS01 self-check
  dns01RecursiveNameservers: "1.1.1.1:53,8.8.8.8:53"
  dns01RecursiveNameserversOnly: false  # Usa ISP DNS + custom
```

**Caso de uso**: Certificados wildcard con Let's Encrypt vía DNS challenge.

---

### 9. **Feature Gates** - FEATURES EXPERIMENTALES

#### Features disponibles (v1.20+):
```yaml
values:
  config:
    apiVersion: controller.config.cert-manager.io/v1alpha1
    kind: ControllerConfiguration
    featureGates:
      # Stable/Beta (habilitadas por default)
      ExperimentalGatewayAPISupport: true    # Gateway API support
      LiteralCertificateSubject: true         # Control exacto de subject
      NameConstraints: true                   # Name constraints en certs
      OtherNames: true                        # OtherNames en subject
      SecretsFilteredCaching: true            # Mejor performance
      StableCertificateRequestName: true      # Nombres predecibles

      # Alpha (deshabilitadas, evaluar)
      ServerSideApply: false                  # Server-side apply (requiere K8s 1.22+)
      UseCertificateRequestBasicConstraints: false
```

---

### 10. **Optimización de Performance** - HOMELAB CON MUCHOS CERTS

#### Si tienes muchos certificados:
```yaml
values:
  config:
    apiVersion: controller.config.cert-manager.io/v1alpha1
    kind: ControllerConfiguration
    kubernetesAPIQPS: 50        # Default: 20
    kubernetesAPIBurst: 100     # Default: 50
    numberOfConcurrentWorkers: 10  # Default: 5
    maxConcurrentChallenges: 60    # Default: 60 (ya suficiente)
```

**Caso de uso**: Más de 50 certificados o renovaciones frecuentes.

---

### 11. **Startup API Check** - YA HABILITADO

#### Estado actual:
- ✓ Habilitado por default
- ✓ Timeout: 1m (suficiente)

#### Solo ajustar si tienes problemas de instalación:
```yaml
values:
  startupapicheck:
    enabled: true
    timeout: 2m  # Aumentar si el cluster es lento
    backoffLimit: 4
```

---

## 📋 Configuración Recomendada Final para tu Homelab

### Nivel 1: Configuración Mínima Mejorada (BASELINE)
```yaml
values:
  # Gestión moderna de CRDs
  installCRDs: false
  crds:
    enabled: true
    keep: true

  # Monitoreo básico
  prometheus:
    enabled: true
    servicemonitor:
      enabled: true
      labels:
        release: kube-prometheus-stack  # Ajusta según tu Prometheus
```

### Nivel 2: Producción Básica (RECOMENDADO)
```yaml
values:
  installCRDs: false
  crds:
    enabled: true
    keep: true

  # HA básica
  replicaCount: 2
  podDisruptionBudget:
    enabled: true
    minAvailable: 1

  # Recursos definidos
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      memory: 256Mi

  # Monitoreo
  prometheus:
    enabled: true
    servicemonitor:
      enabled: true
      interval: 60s
      labels:
        release: kube-prometheus-stack

  # Webhook HA
  webhook:
    replicaCount: 2
    podDisruptionBudget:
      enabled: true
      minAvailable: 1
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
      limits:
        memory: 64Mi

  # CA Injector HA
  cainjector:
    replicaCount: 2
    podDisruptionBudget:
      enabled: true
      minAvailable: 1
    resources:
      requests:
        cpu: 10m
        memory: 32Mi
      limits:
        memory: 128Mi
```

### Nivel 3: Producción Hardened (ENTERPRISE)
Agregar a Nivel 2:
```yaml
values:
  # ... todo lo del Nivel 2 ...

  # Network Policies
  networkPolicy:
    enabled: true

  webhook:
    networkPolicy:
      enabled: true

  cainjector:
    networkPolicy:
      enabled: true

  # Optimización
  config:
    apiVersion: controller.config.cert-manager.io/v1alpha1
    kind: ControllerConfiguration
    kubernetesAPIQPS: 50
    kubernetesAPIBurst: 100
    numberOfConcurrentWorkers: 10
    featureGates:
      SecretsFilteredCaching: true

  # Estrategia de actualización controlada
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
```

---

## 🎯 Recomendaciones Priorizadas

### ALTA PRIORIDAD (implementar ahora):
1. ✅ **Monitoreo con ServiceMonitor** - Visibilidad crítica
2. ✅ **Migrar a `crds.enabled`** - Método moderno
3. ✅ **Definir recursos** - Estabilidad y scheduling

### MEDIA PRIORIDAD (implementar en siguiente iteración):
4. ⚠️  **Alta disponibilidad (2 replicas)** - Solo si tienes 2+ nodos
5. ⚠️  **PodDisruptionBudget** - Útil con HA

### BAJA PRIORIDAD (evaluar según necesidad):
6. ℹ️  **Network Policies** - Si necesitas compliance estricto
7. ℹ️  **Performance tuning** - Solo si >50 certificados
8. ℹ️  **Feature gates** - Evaluar caso por caso

---

## 🔍 Validaciones Post-Implementación

### Verificar que todo funciona:
```bash
# 1. Verificar pods
kubectl get pods -n cert-manager

# 2. Verificar ServiceMonitor (si habilitaste)
kubectl get servicemonitor -n cert-manager

# 3. Verificar métricas
kubectl port-forward -n cert-manager svc/cert-manager 9402:9402
curl http://localhost:9402/metrics

# 4. Verificar ClusterIssuers creados
kubectl get clusterissuer

# 5. Test de certificado
kubectl get certificate -A
```

---

## 📚 Referencias

- [Cert-manager Helm Values (GitHub)](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/values.yaml)
- [Best Practices](https://cert-manager.io/docs/installation/best-practice/)
- [Prometheus Metrics](https://cert-manager.io/docs/devops-tips/prometheus-metrics/)
- [Feature Gates](https://cert-manager.io/docs/cli/controller/)
