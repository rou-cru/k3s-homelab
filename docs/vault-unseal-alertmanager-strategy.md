# Vault Auto-Unseal & Alertmanager Strategy

**Fecha**: 2026-01-14
**Contexto**: Decisiones críticas pre-implementación - Vault unsealing y estrategia de alertas
**Urgencia**: Alta - Debe decidirse antes de Fase 3 (Secrets & TLS)

---

## 🔐 PARTE 1: VAULT AUTO-UNSEAL DECISION

### 1.1 Contexto del Problema

**Vault sealed state** = Vault NO puede acceder a ningún dato porque no conoce la clave de descifrado del storage backend.

**Cuando ocurre**:
- Reinicio del pod Vault
- Restart del nodo donde corre Vault
- Crash de Vault process
- Upgrade/rollout de Vault

**Impacto en k3s-homelab**:
- External Secrets Operator **FALLA** → NO puede sync secrets de Vault
- ArgoCD NO puede leer admin password → **NO puede sync apps**
- Grafana NO puede leer admin password → **NO puede iniciar**
- Todos los workloads que dependen de secrets via ESO **FALLAN**

**Blast radius**: **CRÍTICO** - Todo el cluster queda inoperativo excepto workloads sin secrets.

**Fuente**: [Seal/Unseal Concepts - HashiCorp](https://developer.hashicorp.com/vault/docs/concepts/seal)

---

### 1.2 Opción A: Manual Unseal (Shamir Shares)

#### Cómo Funciona

**Shamir Secret Sharing**:
1. Al init, Vault genera **unseal keys** (ej: 5 keys)
2. Define **threshold** (ej: 3 de 5 keys requeridas)
3. Para unseal, operador provee 3+ keys via CLI o API
4. Vault descifra root key y cambia a estado unsealed

**Ejemplo**:
```bash
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>
# Vault ahora unsealed
```

**Fuente**: [Comparing Unseal Options - Kloia](https://www.kloia.com/blog/comparison-of-unseal-options-in-hashicorp-vault)

#### Ventajas

✅ **Costo**: **$0** - Sin dependencias cloud
✅ **Control total**: Keys en tu control, no en KMS externo
✅ **Seguridad Shamir**: Ninguna persona tiene control completo (quorum requerido)
✅ **Simplicidad**: No requiere configuración GCP, IAM policies, Service Accounts

#### Desventajas

❌ **Operador humano requerido**: Si Vault pod reinicia a las 3am, queda sealed hasta que alguien lo unseal manualmente
❌ **No escalable**: Kubernetes puede rescheduling pods automáticamente → sealed inmediato
❌ **Blast radius temporal**: Cluster parcialmente inoperativo hasta unseal manual
❌ **Key management**: Necesitas almacenar unseal keys de forma segura (no en cluster)
❌ **Automatización**: Imposible automatizar recovery sin comprometer seguridad

**Probabilidad de fallo**: **MEDIA-ALTA** en Kubernetes por naturaleza efímera de pods.

**Fuente**: [Vault Auto-Unseal Trade-offs - Medium](https://medium.com/@czembower/recommended-patterns-for-vault-unseal-and-recovery-key-management-d6366a2f4607)

---

### 1.3 Opción B: Auto-Unseal con GCP Cloud KMS

#### Cómo Funciona

**Envelope Encryption**:
1. Vault root key cifrada por **KMS key** (en GCP Cloud KMS)
2. Al startup, Vault hace decrypt request a GCP KMS
3. GCP KMS descifra root key usando su HSM
4. Vault recibe root key descifrada → unsealed automáticamente

**Configuración**:
```hcl
seal "gcpckms" {
  project     = "my-gcp-project"
  region      = "us-central1"
  key_ring    = "vault-keyring"
  crypto_key  = "vault-key"
}
```

**Fuente**: [Auto-unseal using GCP Cloud KMS - HashiCorp](https://developer.hashicorp.com/vault/tutorials/auto-unseal/autounseal-gcp-kms)

#### Costos Reales

**Corrección importante**: El usuario mencionó **~$0.6 USD por uso**, pero el costo real es:

**GCP Cloud KMS Pricing** (vigente desde 17 marzo 2025):

| Operación | Costo |
|-----------|-------|
| **Encrypt/Decrypt** | **$0.03 per 10,000 operations** |
| **Key storage** (software) | **$0.06/month** per active key version |
| **Key storage** (HSM) | $3.00/month per active key version |
| **Admin operations** | FREE (rotations, disable, enable) |

**Free Tier**: 10,000 operations/month + 100 Autokey versions/month

**Fuente**: [Cloud KMS Pricing - Google Cloud](https://cloud.google.com/kms/pricing)

#### Frecuencia de Operaciones

**Por reinicio de Vault**:
- 1x decrypt operation (unseal)

**Operaciones continuas**:
- Health check cada **10 minutos** (ping a KMS)
- Si KMS falla: retry cada 1 minuto (logs warnings)

**Cálculo mensual** (escenario normal):
- 1 unseal/día (por rollout/upgrade) = 30 ops/mes
- Health checks: 4,320 ops/mes (6 por hora × 24h × 30 días)
- **Total: ~4,350 ops/mes**

**Costo estimado**: **$0.013/mes** (4,350 ops ÷ 10,000 × $0.03) + $0.06 key storage = **$0.073/mes** ≈ **$0.88/año**

**¡Mucho menor que $0.6 por uso!** El costo es casi despreciable.

**Fuentes**:
- [Auto-unseal GCP Cloud KMS - Medium](https://medium.com/google-cloud/auto-unseal-vault-using-gcp-cloud-kms-97c5450be264)
- [GCP KMS Pricing](https://cloud.google.com/kms/pricing)

#### Ventajas

✅ **Automation**: Vault auto-unseal en cada restart sin intervención humana
✅ **Disponibilidad**: Cluster recovery automático después de node failures
✅ **Kubernetes-native**: Ideal para pods efímeros y rescheduling
✅ **Key rotation**: GCP KMS rota keys automáticamente (viejas versiones descifran data legacy)
✅ **Costo negligible**: <$1/año
✅ **Workload Identity Federation**: No requiere secrets en filesystem (IAM via service account)

#### Desventajas

❌ **Dependencia crítica**: Si GCP KMS no disponible → **Vault NO puede reiniciarse**
❌ **Recovery keys inútiles**: Recovery keys NO pueden unseal si KMS falla (solo authz, no decrypt)
❌ **Vendor lock-in**: Migrar a otro KMS requiere re-seal completo
❌ **IAM complexity**: Requiere Service Account + IAM policy correctos
❌ **Blast radius externo**: Si GCP outage regional → Vault stuck sealed (raro pero posible)

**Probabilidad de fallo**: **BAJA** - GCP KMS tiene SLA 99.95% (región única) o 99.99% (multi-región).

**Mitigación crítica**: **NO eliminar/deshabilitar KMS key** o Vault es irrecuperable incluso con backups.

**Fuentes**:
- [Vault Sealed State Disaster Recovery](https://github.com/hashicorp/vault/issues/15490)
- [Auto-unseal Best Practices - HashiCorp](https://support.hashicorp.com/hc/en-us/articles/5277291261075-Auto-unseal-using-GCP-Cloud-KMS)

---

### 1.4 Análisis Comparativo

| Criterio | Manual Unseal | Auto-Unseal (GCP KMS) |
|----------|---------------|------------------------|
| **Costo** | $0 | ~$0.88/año |
| **Disponibilidad** | Media (requiere humano) | Alta (automático) |
| **Blast Radius (Vault down)** | Cluster parcial inoperativo | Mismo |
| **Blast Radius (KMS down)** | N/A | Vault NO puede reiniciar |
| **Blast Radius (Vault sealed)** | **CRÍTICO** hasta unseal manual | **CRÍTICO** si KMS falla |
| **Probability of Failure** | Media-Alta (pods K8s efímeros) | Baja (KMS SLA 99.95%) |
| **Recovery Time** | Minutos-Horas (humano) | Segundos (automático) |
| **Operational Overhead** | Alto (24/7 on-call) | Bajo (set & forget) |
| **Security Model** | Shamir (quorum) | Envelope encryption (KMS HSM) |
| **Kubernetes-friendly** | ❌ No | ✅ Sí |

---

### 1.5 Escenarios de Fallo

#### Escenario 1: Pod Restart (Normal Operation)

**Manual**:
1. Vault pod reinicia (por upgrade, node drain, etc.)
2. Vault inicia en sealed state
3. ESO NO puede sync secrets → Apps fallan
4. **Operador debe unseal manualmente** (puede tardar horas si es de madrugada)
5. Cluster recupera funcionalidad

**Auto-Unseal**:
1. Vault pod reinicia
2. Vault hace decrypt request a GCP KMS
3. **Unseal automático en <10 segundos**
4. Cluster recupera sin intervención

**Ganador**: Auto-Unseal

#### Escenario 2: GCP Regional Outage (Raro)

**Manual**:
- No afectado (keys locales)

**Auto-Unseal**:
1. GCP KMS us-central1 down
2. Vault running NO afectado (solo necesita KMS en restart)
3. Si Vault reinicia durante outage → **stuck sealed hasta KMS recovery**
4. Duración: Histórico GCP outages ~1-4 horas

**Mitigación**: Multi-región KMS (pero aumenta complejidad + costo)

**Ganador**: Manual (pero escenario muy improbable: 0.05% anual)

#### Escenario 3: KMS Key Eliminada Accidentalmente

**Manual**:
- No afectado

**Auto-Unseal**:
- **Vault IRRECUPERABLE** incluso con backups
- Requiere restore de Vault desde backup + re-init con nuevas keys
- Data loss potencial

**Mitigación**:
- IAM policy deny delete en KMS key
- Scheduled key versioning (no borrar versiones viejas)
- Backups regulares de Vault

**Ganador**: Manual (pero prevención vía IAM es suficiente)

#### Escenario 4: Malware/Ransomware en Cluster

**Manual**:
- Si atacante obtiene unseal keys → puede acceder a Vault
- Keys almacenadas fuera del cluster (más seguras)

**Auto-Unseal**:
- Si atacante compromete Service Account → puede unseal Vault
- Pero Service Account solo tiene permiso decrypt (no read secrets)
- Ataque requiere comprometer TANTO cluster COMO descifrar storage backend

**Ganador**: Empate (ambos requieren defensa en profundidad)

---

### 1.6 Recomendación

**RECOMENDACIÓN FUERTE: Auto-Unseal con GCP KMS**

**Justificación**:

1. **Costo negligible**: $0.88/año es irrelevante comparado con disponibilidad
2. **Disponibilidad crítica**: Cluster bare-metal con workloads Akash → downtime = pérdida de earnings
3. **Kubernetes reality**: Pods se van a reinicar (upgrades, node maintenance, etc.)
4. **Operational sanity**: No tener que unseal manualmente a las 3am
5. **Preparación para multi-node**: Si añades nodos, Vault HA requiere auto-unseal práctico

**Mitigaciones obligatorias**:

✅ **IAM Policy** deny delete en KMS key:
```json
{
  "bindings": [
    {
      "role": "roles/cloudkms.cryptoKeyEncrypterDecrypter",
      "members": [
        "serviceAccount:vault@PROJECT.iam.gserviceaccount.com"
      ]
    }
  ],
  "version": 3
}
```

✅ **Scheduled backups** de Vault (raft snapshots cada 24h)

✅ **Monitoring** de KMS health (SLO)

✅ **Recovery plan documentado** para KMS failure

✅ **GCP credits**: ~$0.90/año está MUY por debajo de $300 free tier (si nuevo account)

**Caso para Manual Unseal**:

Solo si:
- ❌ NO quieres depender de GCP en absoluto (100% on-prem)
- ❌ Tienes on-call 24/7 garantizado
- ❌ Cluster puede estar down horas sin problema

**Para homelab productivo con Akash → Auto-Unseal es la única opción razonable.**

**Fuentes**:
- [Auto-unseal Best Practices - Gruntwork](https://blog.gruntwork.io/a-guide-to-automating-hashicorp-vault-1-auto-unsealing-b219970f02c6)
- [Vault on Kubernetes Security - Google Cloud](https://cloud.google.com/blog/products/identity-security/exploring-container-security-running-and-connecting-to-hashicorp-vault-on-kubernetes)

---

## 🚨 PARTE 2: ALERTMANAGER STRATEGY

### 2.1 Deadman Switch (Healthchecks.io)

#### ¿Qué es Deadman Switch?

**Concepto**: Alert que **siempre está firing**. Si deja de firing = monitoring system está muerto.

**Problema que resuelve**: "¿Quién monitorea al monitor?" Si Prometheus/Alertmanager caen, NO recibes alertas de que están caídos.

**Fuente**: [Dead Man's Switch in Prometheus - Blog](https://blog.ediri.io/how-to-set-up-a-dead-mans-switch-in-prometheus)

#### Watchdog Alert (Built-in)

**kube-prometheus-stack ya incluye Watchdog**:

```yaml
# PrometheusRule (ya existe en stack)
- alert: Watchdog
  annotations:
    description: |
      This is an alert meant to ensure that the entire alerting pipeline is functional.
      This alert is always firing, therefore it should always be firing in Alertmanager
      and always fire against a receiver.
    runbook_url: https://runbooks.prometheus-operator.dev/runbooks/general/watchdog
    summary: An alert that should always be firing to certify that Alertmanager is working properly.
  expr: vector(1)
  labels:
    severity: none
```

**Expresión**: `vector(1)` → **siempre retorna 1** → alert siempre firing

**Fuente**: [Prometheus Watchdog Alert](https://jpweber.io/blog/taking-advantage-of-deadmans-switch-in-prometheus/)

#### Integración con Healthchecks.io

**Tu UUID**: `300a89e0-fcc1-4532-a7c2-30a177064be0`

**Endpoint**: `https://hc-ping.com/300a89e0-fcc1-4532-a7c2-30a177064be0`

**Alertmanager Config**:

```yaml
# alertmanager.yaml
route:
  receiver: 'deadman'
  group_wait: 0s
  group_interval: 1m
  repeat_interval: 50s     # Healthchecks espera ping cada 60s (10s de margen)
  routes:
  - match:
      alertname: Watchdog
    receiver: 'deadman'
    repeat_interval: 50s
  - match:
      severity: critical
    receiver: 'critical-alerts'
    continue: true          # También enviar a otros receivers
  # ... más routes

receivers:
- name: 'deadman'
  webhook_configs:
  - url: 'https://hc-ping.com/300a89e0-fcc1-4532-a7c2-30a177064be0'
    send_resolved: false   # No enviar resolved (healthchecks no lo necesita)

- name: 'critical-alerts'
  # ... (definir después)
```

**Comportamiento**:
- Watchdog alert firing → Alertmanager envía webhook cada 50s
- Healthchecks.io recibe ping → "System alive"
- Si NO recibe ping por 60s+ → **Emergency alert** (email, SMS, Slack)

**Fuentes**:
- [Securing Monitoring Stack with Dead Man Switch](https://seifrajhi.github.io/blog/securing-monitoring-stack-dead-man-switch/)
- [Healthchecks.io Docs](https://healthchecks.io/docs/)

#### ¿Qué configura Healthchecks.io?

En healthchecks.io dashboard:

1. **Period**: 1 minute (espera ping cada 60s)
2. **Grace**: 10 seconds (tolera 10s de delay)
3. **Alert methods**: Email, Slack, PagerDuty, etc.
4. **Failure alert**: Si no recibe ping por 70s (period + grace)

**Cuando falla**:
- Prometheus down
- Alertmanager down
- Network entre Alertmanager y healthchecks.io down
- Kubernetes cluster down
- **= Emergencia crítica, requiere intervención humana inmediata**

---

### 2.2 Estrategia de Routing por Severity

#### Severity Levels

**Estándar de industria**:

| Severity | Descripción | Acción |
|----------|-------------|--------|
| **critical** | Sistema caído, data loss inminente, SLO burned rápido | **Paging** (PagerDuty/SMS) + Auto-remediation |
| **warning** | Degradación, SLO burning lento, pre-emptive | **Slack** + Auto-remediation (si posible) |
| **info** | Informativo, no requiere acción inmediata | **Slack channel read-only** |

**Fuente**: [Prometheus Alertmanager Best Practices - Sysdig](https://www.sysdig.com/blog/prometheus-alertmanager)

#### Labels en PrometheusRules

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example-alerts
spec:
  groups:
  - name: critical.rules
    rules:
    - alert: VaultSealed
      expr: vault_core_unsealed == 0
      labels:
        severity: critical
        component: vault
        auto_remediate: "false"    # Requiere intervención humana
      annotations:
        summary: "Vault is sealed"
        description: "Vault in {{ $labels.namespace }} is sealed. Cluster secrets unavailable."
        runbook_url: "https://wiki.internal/runbooks/vault-sealed"

  - name: warning.rules
    rules:
    - alert: HighCPUUsage
      expr: node_cpu_usage > 80
      for: 5m
      labels:
        severity: warning
        component: node
        auto_remediate: "true"     # KEDA puede escalar
      annotations:
        summary: "High CPU usage on {{ $labels.instance }}"
```

#### Routing Tree

```yaml
route:
  receiver: 'default'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 4h
  routes:

  # Deadman switch (siempre primero)
  - match:
      alertname: Watchdog
    receiver: 'deadman'
    group_wait: 0s
    repeat_interval: 50s

  # Critical alerts CON auto-remediation
  - match:
      severity: critical
      auto_remediate: "true"
    receiver: 'argo-events-webhook'
    group_wait: 0s            # Enviar inmediatamente
    repeat_interval: 5m
    continue: true            # También enviar a Slack

  # Critical alerts SIN auto-remediation (requiere humano)
  - match:
      severity: critical
      auto_remediate: "false"
    receiver: 'pagerduty'     # O Slack con @channel
    group_wait: 0s
    repeat_interval: 15m      # Re-page cada 15min si no acknowledged

  # Warning alerts con auto-remediation
  - match:
      severity: warning
      auto_remediate: "true"
    receiver: 'argo-events-webhook'
    repeat_interval: 10m

  # Warning alerts informativos
  - match:
      severity: warning
    receiver: 'slack-warnings'
    repeat_interval: 1h

  # Info alerts
  - match:
      severity: info
    receiver: 'slack-info'
    repeat_interval: 4h
```

**Fuente**: [Alertmanager Configuration - Prometheus](https://prometheus.io/docs/alerting/latest/configuration/)

---

### 2.3 Inhibit Rules (Noise Reduction)

**Propósito**: Suprimir alertas redundantes cuando una alerta más crítica ya está firing.

**Ejemplo**: Si `NodeDown` está firing, NO enviar `HighCPU`, `HighMemory`, `DiskFull` del mismo nodo.

```yaml
inhibit_rules:
# Node down inhibe TODAS las alertas de ese nodo
- source_match:
    alertname: NodeDown
    severity: critical
  target_match_re:
    severity: warning|info
  equal: ['instance']

# Critical inhibe warning del mismo componente
- source_match:
    severity: critical
  target_match:
    severity: warning
  equal: ['alertname', 'namespace', 'pod']

# ArgoCD app unhealthy inhibe "deployment not ready"
- source_match:
    alertname: ArgoCDAppUnhealthy
  target_match:
    alertname: KubeDeploymentReplicasMismatch
  equal: ['namespace', 'deployment']

# Vault sealed inhibe "External Secret sync failed"
- source_match:
    alertname: VaultSealed
  target_match:
    alertname: ExternalSecretSyncFailed
  equal: ['namespace']

# SLO fast burn inhibe slow burn del mismo SLO
- source_match:
    alertname: ErrorBudgetBurnFast
  target_match:
    alertname: ErrorBudgetBurnSlow
  equal: ['slo']
```

**Resultado**: Solo recibes 1 alerta (la root cause), no 20 alertas de síntomas downstream.

**Fuentes**:
- [Alertmanager Noise Reduction - Netdata](https://www.netdata.cloud/academy/prometheus-alert-manager/)
- [Inhibition Rules Explained - DoHost](https://dohost.us/index.php/2025/09/28/understanding-alertmanagers-core-concepts-grouping-routing-and-inhibition/)

---

### 2.4 Receivers por Tipo de Alerta

#### Receiver: argo-events-webhook (Auto-Remediation)

**Propósito**: Disparar workflows de Argo Events para auto-remediar.

```yaml
- name: 'argo-events-webhook'
  webhook_configs:
  - url: 'http://argo-events-webhook.argo-events.svc.cluster.local:12000/alertmanager'
    send_resolved: true
```

**Argo Events Sensor** consume esto y dispara workflows (ya planeado en Fase 5).

**Ejemplos de auto-remediation**:
- `ArgoCDAppUnhealthy` → Force sync
- `ExternalSecretSyncFailed` → Restart ESO pod
- `HighMemoryUsage` + `pod=miner` → Scale down miner (KEDA)
- `GPUTemperatureHigh` → Scale to 0 miner (KEDA thermal protection)

#### Receiver: slack-critical (Human Attention)

**Propósito**: Alertas que NO se pueden auto-remediar.

```yaml
- name: 'slack-critical'
  slack_configs:
  - api_url: '<SLACK_WEBHOOK_URL>'    # Via secret
    channel: '#alerts-critical'
    title: '🔥 CRITICAL: {{ .GroupLabels.alertname }}'
    text: |
      {{ range .Alerts }}
      *Alert:* {{ .Labels.alertname }}
      *Severity:* {{ .Labels.severity }}
      *Summary:* {{ .Annotations.summary }}
      *Description:* {{ .Annotations.description }}
      *Runbook:* {{ .Annotations.runbook_url }}
      {{ end }}
    send_resolved: true
```

**Ejemplos**:
- `VaultSealed` (requiere unseal manual si KMS falla)
- `DiskFull` (requiere cleanup manual)
- `CertificateExpiringSoon` (cert-manager falló, requiere debug)
- `BackupFailed` (Velero issue)

#### Receiver: slack-warnings (Informativo)

```yaml
- name: 'slack-warnings'
  slack_configs:
  - api_url: '<SLACK_WEBHOOK_URL>'
    channel: '#alerts-warnings'
    title: '⚠️ Warning: {{ .GroupLabels.alertname }}'
    # ... similar template
```

#### Receiver: pagerduty (Opcional, si SLA firmado)

```yaml
- name: 'pagerduty'
  pagerduty_configs:
  - service_key: '<PAGERDUTY_SERVICE_KEY>'
    description: '{{ .GroupLabels.alertname }}: {{ .Annotations.summary }}'
```

**Uso**: Solo para alertas critical que requieren wake-up a las 3am.

---

### 2.5 Decisión: Qué Alertas Auto-Remediar vs Paging

#### Auto-Remediation (Argo Events → Workflows)

✅ **Bueno para**:
- Problemas conocidos con solución determinística
- Bajo riesgo de empeorar la situación
- Alta frecuencia (costo humano alto si manual)

**Ejemplos**:
- ArgoCD app unhealthy → Force sync
- Pod CrashLoopBackOff (known issue) → Rollback
- External Secret sync failed → Restart operator
- High CPU (miner) → Scale down
- SLO burn slow → Restart affected service

**Label**: `auto_remediate: "true"`

#### Human Intervention (Slack/PagerDuty)

✅ **Bueno para**:
- Problemas sin solución determinística
- Alto riesgo (data loss potencial)
- Requiere investigación/debugging
- Eventos raros (no vale automatizar)

**Ejemplos**:
- Vault sealed (KMS failure)
- Disk full (requiere analizar qué borrar)
- Certificate expired (cert-manager bug, requiere debug)
- Backup failed (múltiples causas posibles)
- Node hardware failure (reemplazo físico)
- Security breach alert (requiere forensics)

**Label**: `auto_remediate: "false"`

#### Híbrido (Auto-remediate THEN Paging si falla)

**Pattern**:
1. Alert fires → Auto-remediation workflow ejecuta
2. Si workflow falla O alert persiste 15min → Escalate a human

**Implementación**:
```yaml
# Alert con escalation
- alert: ArgoCDAppUnhealthy
  expr: argocd_app_info{health_status!="Healthy"} == 1
  for: 5m      # Esperar 5min antes de disparar
  labels:
    severity: warning
    auto_remediate: "true"
  annotations:
    summary: "ArgoCD app {{ $labels.name }} unhealthy"
    # Workflow intenta force-sync

# Alert de escalation si persiste
- alert: ArgoCDAppUnhealthyPersistent
  expr: argocd_app_info{health_status!="Healthy"} == 1
  for: 15m     # Solo si persiste 15min POST auto-remediation
  labels:
    severity: critical
    auto_remediate: "false"
  annotations:
    summary: "ArgoCD app {{ $labels.name }} unhealthy >15min (auto-remediation failed)"
```

**Routing**:
- `ArgoCDAppUnhealthy` → argo-events-webhook
- `ArgoCDAppUnhealthyPersistent` → slack-critical

---

### 2.6 SLO Burn Rate Alerts Strategy

**Contexto**: Tienes 9 SLOs definidos (de IDP Blueprint + customs para miners).

**Burn Rate Alerts** (generadas por Pyrra):
- **Fast burn** (1h window): Consume 5% error budget en 1h → Page
- **Slow burn** (6h window): Consume 2% error budget en 6h → Warn

**Routing**:

```yaml
# Fast burn = critical (puede agotar budget en <1 día)
- match:
    alertname: ErrorBudgetBurn
    severity: critical
    burn_rate: fast
  receiver: 'slack-critical'
  continue: true
  routes:
  - match:
      auto_remediate: "true"
    receiver: 'argo-events-webhook'

# Slow burn = warning (info + posible auto-remediation)
- match:
    alertname: ErrorBudgetBurn
    severity: warning
    burn_rate: slow
  receiver: 'slack-warnings'
  routes:
  - match:
      auto_remediate: "true"
    receiver: 'argo-events-webhook'
```

**Inhibit rule**:
```yaml
# Fast burn inhibe slow burn del mismo SLO
- source_match:
    burn_rate: fast
  target_match:
    burn_rate: slow
  equal: ['slo']
```

**Auto-remediation examples por SLO**:

| SLO | Fast Burn Cause | Auto-Remediation |
|-----|-----------------|------------------|
| `argocd-application-health` | App unhealthy | Force sync |
| `secrets-sync` | ESO failing | Restart ESO operator |
| `miner-uptime` | Miner crashed | Restart deployment |
| `gateway-latency` | Gateway overload | Scale up gateway pods (HPA) |
| `vault-api-availability` | Vault slow | Restart Vault pod (si no sealed) |

---

### 2.7 Implementación en Fases

#### Fase 6 Original: Loki + SLOs

**Ya incluye**:
- Pyrra deployment
- 9 SLO definitions
- PrometheusRules generadas por Pyrra

**Añadir**:

1. **Alertmanager config completo**:
   - `alertmanager-config-secret.yaml` (en `k8s/observability/kube-prometheus-stack/`)
   - Incluir: routes, receivers, inhibit_rules
   - Healthchecks.io webhook

2. **Slack integration**:
   - Crear secret `alertmanager-slack-webhook`
   - ExternalSecret desde GCP Secret Manager (usa 1 de los 6 slots)

3. **PrometheusRules custom**:
   - `k8s/observability/prometheus-rules/platform-alerts.yaml`
   - Alertas para: VaultSealed, NodeDown, DiskFull, CertExpiring

4. **Validación**:
   - Test Watchdog: Verificar ping en healthchecks.io
   - Test routing: Disparar alert manual y verificar receiver correcto
   - Test inhibit: Disparar NodeDown y verificar que supprime otras

#### Fase 5 Enhancement: Auto-Remediation

**Ya incluye** (en backlog original):
- Argo Events deployment
- Sensors para SLO remediation

**Añadir**:

5. **EventSource para Alertmanager**:
   - `alertmanager-eventsource.yaml` (webhook en :12000)

6. **Sensor para routing**:
   - `alert-remediation-sensor.yaml`
   - Condiciones: `data.labels.auto_remediate == "true"`
   - Triggers: workflows específicos por alertname

7. **Workflow Templates**:
   - `remediate-argocd-unhealthy.yaml` (ya planeado)
   - `remediate-externalsecret-failure.yaml` (ya planeado)
   - `remediate-miner-crash.yaml` (new)
   - `remediate-high-cpu.yaml` (new - scale down miner)

---

## 📋 RESUMEN DE DECISIONES

### ✅ DECISIÓN 1: Vault Auto-Unseal

**APROBADO**: Auto-Unseal con GCP Cloud KMS

**Justificación**:
- Costo: **$0.88/año** (negligible)
- Disponibilidad: **Crítica** para cluster productivo
- Kubernetes: Pods efímeros requieren auto-unseal
- Blast radius: Mitigable con IAM policy + backups

**Implementación** (Fase 3):
- [ ] Crear GCP KMS keyring + crypto key (región us-central1)
- [ ] Crear Service Account `vault-kms@PROJECT.iam.gserviceaccount.com`
- [ ] IAM binding: `roles/cloudkms.cryptoKeyEncrypterDecrypter`
- [ ] IAM policy deny delete en key
- [ ] Ansible role: Update Vault Helm values con seal stanza
- [ ] Init Vault con auto-unseal
- [ ] Validar unseal automático después de pod restart
- [ ] Documentar recovery procedure si KMS falla

**Costo tracking**: Monitorear ops/mes en GCP console (debería stay en free tier).

---

### ✅ DECISIÓN 2: Alertmanager Strategy

**APROBADO**: Multi-tier routing con deadman switch

**Componentes**:

1. **Deadman Switch**: Healthchecks.io UUID `300a89e0-fcc1-4532-a7c2-30a177064be0`
   - Watchdog alert → webhook cada 50s
   - Falla = Emergency (email/SMS)

2. **Severity Routing**:
   - `critical` + `auto_remediate=true` → Argo Events + Slack
   - `critical` + `auto_remediate=false` → Slack (o PagerDuty si SLA)
   - `warning` + `auto_remediate=true` → Argo Events
   - `warning` → Slack warnings channel
   - `info` → Slack info channel

3. **Inhibit Rules**:
   - NodeDown inhibe todo del mismo nodo
   - Critical inhibe warning del mismo componente
   - Fast burn inhibe slow burn del mismo SLO

4. **Auto-Remediation**:
   - ArgoCD unhealthy → Force sync
   - ExternalSecret failure → Restart operator
   - Miner crash → Restart deployment
   - High temp GPU → KEDA scale to 0

5. **Escalation**:
   - Alert persiste >15min post auto-remediation → Critical + human

**Implementación** (Fases 5 + 6):
- [ ] Configurar Alertmanager con routes completas
- [ ] Integrar Slack webhook (via GCP Secret Manager)
- [ ] Validar Watchdog → healthchecks.io
- [ ] Crear PrometheusRules custom (VaultSealed, etc.)
- [ ] Argo Events EventSource para Alertmanager
- [ ] Sensors para auto-remediation workflows
- [ ] Testing exhaustivo de routing

---

## 📚 REFERENCIAS

### Vault Auto-Unseal
- [Auto-unseal using GCP Cloud KMS - HashiCorp](https://developer.hashicorp.com/vault/tutorials/auto-unseal/autounseal-gcp-kms)
- [GCP Cloud KMS Pricing](https://cloud.google.com/kms/pricing)
- [Vault Sealed State Concepts](https://developer.hashicorp.com/vault/docs/concepts/seal)
- [Comparing Unseal Options - Kloia](https://www.kloia.com/blog/comparison-of-unseal-options-in-hashicorp-vault)
- [Auto-unseal Best Practices - Gruntwork](https://blog.gruntwork.io/a-guide-to-automating-hashicorp-vault-1-auto-unsealing-b219970f02c6)
- [Vault Security on Kubernetes - Google Cloud](https://cloud.google.com/blog/products/identity-security/exploring-container-security-running-and-connecting-to-hashicorp-vault-on-kubernetes)
- [Recovery Keys Limitation - GitHub Issue](https://github.com/hashicorp/vault/issues/15490)

### Alertmanager Strategy
- [Dead Man's Switch in Prometheus](https://blog.ediri.io/how-to-set-up-a-dead-mans-switch-in-prometheus)
- [Securing Monitoring Stack](https://seifrajhi.github.io/blog/securing-monitoring-stack-dead-man-switch/)
- [Prometheus Alertmanager Best Practices - Sysdig](https://www.sysdig.com/blog/prometheus-alertmanager)
- [Alertmanager Configuration - Prometheus](https://prometheus.io/docs/alerting/latest/configuration/)
- [Alertmanager Noise Reduction - Netdata](https://www.netdata.cloud/academy/prometheus-alert-manager/)
- [Inhibition Rules Explained - DoHost](https://dohost.us/index.php/2025/09/28/understanding-alertmanagers-core-concepts-grouping-routing-and-inhibition/)
- [Watchdog Alert Pattern - jpweber](https://jpweber.io/blog/taking-advantage-of-deadmans-switch-in-prometheus/)

---

**Última Actualización**: 2026-01-14
**Estado**: Decisiones tomadas, pendiente de implementación en Fases 3, 5, 6
