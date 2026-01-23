# Project Audit: GitOps Transition & Expansion Plan
**Date:** 2025-01-20  
**Context:** Transition from Ansible-managed to GitOps (ArgoCD) + VPS integration  
**Reference:** idp-blueprint K8s structure

---

## Current State Assessment

### Ansible Execution Path (site.yaml)
```
k3s_server group:
  preflight → common → glances → network_opt → devtools → nvidia_gpu(host)
  → tailscale → gvisor → k3s_server → nvidia_gpu(cluster)
  → helm_setup → crds_bootstrap → cilium → cert_manager → external_secrets
  → [post_tasks: namespaces, miners, honeygain, argocd]
```
**Endpoint:** ArgoCD deployed but NO Applications/ApplicationSets defined.

### Molecule Coverage: 3/14 roles (21%)
| Role | Tested | Priority |
|------|--------|----------|
| preflight | ✅ | - |
| common | ✅ | - |
| glances | ✅ | - |
| k3s_server | ❌ | Alta |
| tailscale | ❌ | Alta (VPS) |
| gvisor | ❌ | Media |
| cilium | ❌ | Alta |
| cert_manager | ❌ | Media |
| external_secrets | ❌ | Media |
| argocd | ❌ | Media |
| nvidia_gpu | ❌ | Baja |
| developer_tools | ❌ | Baja |
| crds_bootstrap | ❌ | Baja |
| akash | ❌ | Alta (vacío) |

**Risk:** Sin idempotencia garantizada, re-runs pueden fallar o producir estados inconsistentes.

---

## GitOps Structure: Current vs Target

### Current k8s/ Directory
```
k8s/
├── namespaces/
│   └── miners.yaml
└── miners/
    ├── honeygain/
    ├── gpu-miner/
    ├── cpu-miner/
    ├── mining-secrets/
    └── mining-pools/
```
**Problem:** Solo miners, aplicados vía `kubectl apply` en post_tasks.

### Target Structure (adapted from idp-blueprint)
```
k8s/
├── bootstrap/              # IT/ equivalent - Ansible applies once
│   ├── namespaces/
│   ├── priorityclasses/
│   ├── serviceaccounts/
│   └── gateway/            # Gateway, HTTPRoute, TLSRoute
├── observability/
│   ├── governance/         # namespace, limitrange, resourcequota
│   ├── infrastructure/     # secretstore, eso-sa
│   ├── kube-prometheus-stack/
│   ├── loki/
│   └── applicationset-observability.yaml
├── security/
│   ├── governance/
│   ├── kyverno/
│   ├── network-policies/   # CiliumNetworkPolicy definitions
│   └── applicationset-security.yaml
├── workloads/
│   ├── governance/
│   ├── miners/
│   ├── akash/              # Akash provider components
│   └── applicationset-workloads.yaml
└── platform/
    └── argocd/             # AppProjects definitions
```

---

## Critical Gaps Identified

### 1. k3s_agent Role: NOT EXISTS
**Impact:** Cannot join VPS to cluster.
**Required:**
- Install k3s agent binary
- Configure `--server` pointing to master Tailscale IP
- Configure `--node-ip` to VPS Tailscale IP
- Handle token retrieval from master
- Set `--flannel-backend=none` for Cilium compatibility

### 2. Tailscale Exit-Node: NOT SUPPORTED
**Current:** Basic installation only.
**Required for VPS:**
- `--advertise-exit-node` flag
- Variable: `tailscale_exit_node_enabled`
- Post-config: Manual approval in Tailscale admin (documented)

### 3. PriorityClasses: ZERO DEFINED
**Impact:** Miners compete equally with system components.
**Required (from scheduler_priority_plan):**
```yaml
# k8s/bootstrap/priorityclasses/
- system-node-critical    # Built-in
- system-cluster-critical # Built-in
- priority-ops-critical: 1000000
- priority-akash-prod: 500000
- priority-observability: 100000
- priority-background: 1000
```

### 4. CiliumNetworkPolicy: ZERO DEFINED
**Impact:** Zero Trust not enforced, tenants can access API server.
**Required:**
- Baseline deny-all for tenant namespaces
- Allow DNS (kube-system/coredns)
- Allow Prometheus scraping
- Block internal IPs (10.0.0.0/8, 192.168.0.0/16)
- Block API server (10.43.0.1, Tailscale IP)

### 5. Kyverno Role: NOT EXISTS
**Impact:** No policy enforcement, no automatic runtimeClassName injection.
**Required:**
- Helm deployment of Kyverno
- ClusterPolicy: Inject `runtimeClassName: gvisor` for Akash namespaces
- ClusterPolicy: Enforce PriorityClass based on namespace labels
- ClusterPolicy: Require resource limits

### 6. Gateway API Resources: NOT DEFINED
**Current:** Cilium has `gatewayAPI.enabled: true` but no Gateway/Routes.
**Required:**
- Gateway resource binding to VPS public IP
- TLSRoute for Akash passthrough
- HTTPRoutes for internal services (ArgoCD, Grafana, etc.)
- TLS wildcard certificate via cert-manager

### 7. Akash Role: EMPTY
**Current:** Directory structure only, no content.
**Required:**
- Akash node installation
- Provider configuration
- Bid engine setup
- Nginx Ingress for Akash (separate from Cilium Gateway)

### 8. Longhorn Role: NOT EXISTS
**Impact:** No distributed storage, no replication to VPS.
**Required:**
- Helm deployment
- StorageClass configuration
- Node scheduling (best-effort locality)
- Backup target configuration (OCI)

### 9. Healthchecks.io Integration: NOT EXISTS
**Impact:** No external dead man's switch.
**Required:**
- Alertmanager configuration for heartbeat
- Endpoint: `https://hc-ping.com/300a89e0-fcc1-4532-a7c2-30a177064be0`
- 5-minute interval

---

## VPS-Specific Considerations

### Variables Override (group_vars/vps.yml needed)
```yaml
# Disable hardware-specific features
common_mining_enabled: false
common_audio_optimization_enabled: false
common_radio_block_enabled: false
nvidia_gpu_setup_mode: 'false'
common_power_efficiency_tuning_enabled: false

# Enable exit-node
tailscale_exit_node_enabled: true

# Resource constraints (2 vCore, 4GB RAM)
# Note: Most workloads should NOT run on VPS
```

### VPS Playbook (site-vps.yaml needed)
```yaml
- name: Setup K3s VPS Agent Node
  hosts: vps
  roles:
    - preflight
    - common        # With VPS overrides
    - tailscale     # With exit-node
    - k3s_agent     # NEW ROLE
```

---

## Ansible → GitOps Handoff Point

### Ansible Responsibilities (Final State)
1. OS configuration (common, preflight)
2. K3s installation (server + agent)
3. CNI installation (Cilium)
4. Core infrastructure (cert-manager, external-secrets)
5. ArgoCD installation
6. **Bootstrap manifests:**
   - Namespaces
   - PriorityClasses
   - ServiceAccounts for ESO
   - Gateway/GatewayClass
   - Initial Application/ApplicationSets

### GitOps Responsibilities (ArgoCD)
1. Observability stack
2. Security stack (Kyverno, policies)
3. Workloads (miners, Akash)
4. Network policies
5. SLO definitions
6. All ongoing changes

---

## Implementation Order (Suggested)

### Phase 1: Foundation (Ansible)
1. Create `k3s_agent` role
2. Create `group_vars/vps.yml`
3. Create `site-vps.yaml` playbook
4. Extend Tailscale role with exit-node support
5. Test VPS joining cluster

### Phase 2: Bootstrap Structure (Ansible + k8s/)
1. Create `k8s/bootstrap/` directory structure
2. Define PriorityClasses
3. Define Gateway/Routes skeleton
4. Create AppProjects in ArgoCD

### Phase 3: GitOps Takeover
1. Create ApplicationSets for each stack
2. Migrate miners to GitOps
3. Deploy Kyverno via GitOps
4. Deploy Network Policies via GitOps
5. Deploy Observability stack via GitOps

### Phase 4: Akash Integration
1. Implement Akash role (or via GitOps)
2. Configure Nginx Ingress for Akash
3. Setup TLSRoute passthrough
4. Configure Egress Gateway for SNAT

### Phase 5: Hardening
1. Add Molecule tests for critical roles
2. Longhorn deployment
3. Healthchecks.io integration
4. Documentation update

---

## Testing Strategy: Molecule Priorities for Multi-Node

### Crítico (Bloqueante para VPS)
| Role | Razón | Tests Mínimos |
|------|-------|---------------|
| **k3s_server** | Core del cluster, si falla no hay nada | Idempotencia, kubeconfig generado, API accesible |
| **k3s_agent** | NUEVO, sin testing = alto riesgo | Join exitoso, node Ready, flannel-backend=none |
| **tailscale** | Conectividad inter-nodo | Servicio activo, IP asignada, exit-node (VPS) |
| **cilium** | CNI crítico, pods no schedulean sin él | Helm release existe, cilium status healthy |

### Alto (Antes de producción)
| Role | Razón | Tests Mínimos |
|------|-------|---------------|
| **gvisor** | Runtime para Akash, si falla = sin aislamiento | RuntimeClass existe, pod con gvisor funciona |
| **cert_manager** | TLS para todo, fallos = servicios inaccesibles | Helm release, ClusterIssuer ready |
| **external_secrets** | Secrets para todo, fallos = pods crashean | Operator running, ClusterSecretStore ready |

### Medio (Mejora calidad)
| Role | Razón | Tests Mínimos |
|------|-------|---------------|
| common | Base OS, ya tiene tests básicos | Expandir: sysctl, limits, paquetes |
| argocd | GitOps engine | Helm release, server accessible |
| crds_bootstrap | CRDs para otros componentes | CRDs instalados |

### Bajo (Nice-to-have)
| Role | Razón |
|------|-------|
| nvidia_gpu | Hardware específico, difícil de testear en CI |
| developer_tools | No crítico para operación |
| glances | Monitoring auxiliar |

### Molecule Test Patterns Recomendados
```yaml
# molecule/k3s_server/molecule.yml
verifier:
  name: testinfra
  options:
    v: true

# molecule/k3s_server/tests/test_k3s.py
def test_k3s_service(host):
    svc = host.service("k3s")
    assert svc.is_running
    assert svc.is_enabled

def test_kubeconfig_exists(host):
    f = host.file("/etc/rancher/k3s/k3s.yaml")
    assert f.exists

def test_api_server_responds(host):
    cmd = host.run("kubectl cluster-info")
    assert cmd.rc == 0

def test_idempotence(host):
    # Verificar que no hay cambios en segunda ejecución
    # (Molecule hace esto automáticamente con converge x2)
    pass
```

---

## OCI Vault Integration con Ansible

### Estado Actual
- `oracle.oci` collection tiene **módulos**, no lookup plugins
- Módulos ejecutan en target, no durante parsing del playbook
- SSH keys son problema especial: se necesitan ANTES de conectar

### Estrategia Propuesta: Pre-fetch Local

```yaml
# site.yaml - Play 0: Fetch secrets locally
- name: Fetch secrets from OCI Vault
  hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - name: Get Tailscale AuthKey from OCI
      oracle.oci.oci_secrets_secret_bundle_facts:
        secret_id: "{{ oci_secret_tailscale_authkey }}"
      register: tailscale_secret_raw
      delegate_to: localhost

    - name: Decode and set fact
      set_fact:
        tailscale_authkey: "{{ tailscale_secret_raw.secret_bundle.secret_bundle_content.content | b64decode }}"

# Luego usar en plays posteriores
- name: Setup nodes
  hosts: all
  vars:
    tailscale_authkey: "{{ hostvars['localhost']['tailscale_authkey'] }}"
```

### SSH Keys: Limitación Fundamental
**Problema:** Ansible necesita SSH key para conectar al target. No puedes obtener la key del vault si no puedes conectar primero.

**Opciones:**
1. **SSH key fuera de vault** (actual) - Key local, solo secrets de aplicación en vault
2. **Ansible desde OCI Compute** - Usar instance_principal auth, sin SSH keys
3. **Bastion con vault-agent** - Bastion tiene vault-agent que rota keys localmente
4. **SSH Certificate Authority** - Vault firma certificados SSH efímeros (complejo)

**Decisión tomada (2025-01-20):**
```
SSH keys: Mantener local (~/.ssh/) - reevaluar cuando escale a >3 nodos
App secrets: Migrar a OCI Vault (tailscale, mining, honeygain)
```

### Secrets a Migrar a OCI Vault
| Secret | Actual | Target |
|--------|--------|--------|
| tailscale_authkey | secrets.yaml | OCI Vault |
| mining_wallet | secrets.yaml | OCI Vault |
| honeygain_email/pass | secrets.yaml | OCI Vault |
| argocd admin | ExternalSecret (ya) | ✅ Ya migrado |
| SSH keys | ~/.ssh/ | Mantener local |

### Implementación
1. Crear secrets en OCI Vault Console/CLI
2. Añadir OCIDs a `group_vars/all.yml` (no son sensitivos)
3. Crear play de pre-fetch en `site.yaml`
4. Eliminar `secrets.yaml` del proyecto
5. Actualizar `.gitignore` para remover exclusión de secrets.yaml

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| VPS join fails over Tailscale | Medium | High | Test MTU, verify flannel-backend=none |
| GitOps chicken-egg (CRDs) | High | Medium | Bootstrap CRDs via Ansible first |
| Longhorn WAN latency | High | Medium | Fallback to local-only storage |
| Akash workload breaks gVisor | Medium | High | Test common images, document exceptions |
| Priority preemption cascade | Low | High | Monitor with alerts, tune thresholds |

---

## Decisions Taken (2025-01-20)

| Question | Decision | Rationale |
|----------|----------|-----------|
| **ApplicationSet naming** | `{{path.basename}}` simple | Sin prefijo de stack: `loki`, `kyverno`, `prometheus`. Más limpio. |
| **Namespace strategy** | Por stack (blueprint) | `observability`, `security`, `workloads`. Un namespace por stack. |
| **Observability SLOs** | Diferir Pyrra | Solo Prometheus/Grafana/Loki inicial. Pyrra cuando haya baseline. |
| **Secrets miners** | Migrar a ESO | Eliminar Kustomize bridge. Todos los secrets via ExternalSecrets + OCI Vault. |
| **Longhorn VPS** | Validar primero | Desplegar local-only. Añadir VPS como replica después de medir latencia real. |

### Implications

**ApplicationSets sin prefijo:**
```yaml
# K8s/observability/applicationset-observability.yaml
template:
  metadata:
    name: '{{path.basename}}'  # → loki, prometheus, grafana
```

**Namespaces por stack:**
```
observability  → Prometheus, Grafana, Loki, Fluent-bit
security       → Kyverno, Policy-Reporter, Trivy (futuro)
workloads      → Miners, Akash tenants
argocd         → ArgoCD (ya existe)
cert-manager   → Cert-Manager (ya existe)
```

**ESO Migration para miners:**
- Crear SecretStore para namespace `workloads`
- Crear ExternalSecrets para: mining-wallets, honeygain-credentials
- Eliminar `k8s/miners/*/secret.env` y Kustomize secretGenerator
- Actualizar deployments para referenciar nuevos secret names

**Longhorn Strategy:**
1. Deploy Longhorn con StorageClass `longhorn` (default)
2. Configurar `dataLocality: best-effort`
3. `numberOfReplicas: 1` (solo Home)
4. Después de VPS join: test `dd` y `fio` para medir latencia
5. Si <50ms RTT: habilitar replica 2 para volúmenes críticos
