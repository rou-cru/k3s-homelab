# Pending Sprints — k3s-homelab Cleanup

## Sprint 2: Correcciones triviales de implementación

**Objetivo:** Fixes de 1-3 líneas que mejoran calidad sin tocar arquitectura.

| # | Tarea | Archivos | Esfuerzo | Estado |
|---|-------|----------|----------|--------|
| 2.1 | Fix Jinja2 `disable:` — generar YAML válido | `roles/k3s_server/templates/config.yaml.j2` | Simple | ⏸️ Pendiente |
| 2.2 | ~~Fix `swapoff -a` — chequear estado antes de reportar changed~~ | ~~`roles/common/tasks/main.yml`~~ | ~~Simple~~ | ✅ Done |
| 2.3 | ~~Eliminar duplicación de Tailscale IP validation~~ | | | ❌ Descartada |
| 2.4 | ~~Unificar `min_ansible_version` a `"2.20.0"` en todos los roles~~ | ~~`roles/*/meta/main.yml` (9 archivos)~~ | ~~Simple~~ | ✅ Done |
| 2.5 | ~~Fix tag destructivo — quitar `"miners"` del tag de clean-remote-manifests~~ | ~~`roles/bootstrap_master/tasks/main.yml`~~ | ~~Trivial~~ | ✅ Done |
| 2.6 | Quotear variables en shell templates | `roles/common/templates/apply-rog-tweaks.sh.j2`, `roles/common/templates/optimize-network.sh.j2` | Trivial | ⏸️ Pendiente |

**Riesgo:** MÍNIMO. Cada fix es aislado y verificable.
**Pendientes:** 2.1, 2.6

---

## Sprint 3: Documentación y convenciones

**Objetivo:** Todo lo de docs y repo infrastructure. Archivos nuevos o rewrites, no tocan código running.

| # | Tarea | Archivos | Esfuerzo | Estado |
|---|-------|----------|----------|--------|
| 3.1 | ~~Reescribir `README.md` en inglés con quickstart, prereqs, arquitectura~~ | ~~`README.md`~~ | ~~Simple~~ | ✅ Done |
| 3.2 | ~~Crear `LICENSE` (MIT)~~ | | | ⏸️ Pospuesta |
| 3.3 | ~~Crear `CONTRIBUTING.md` mínimo~~ | ~~`CONTRIBUTING.md`~~ | ~~Simple~~ | ✅ Done |
| 3.4 | ~~Crear PR template + Issue template~~ | | | ❌ Descartada |
| 3.5 | ~~Crear `docs/README.md` con índice de navegación~~ | | | ❌ Descartada |
| 3.6 | ~~Agregar `meta/main.yml` a roles `bootstrap_master`, `bootstrap_vps`, `bootstrap_validations`~~ | ~~`roles/bootstrap_*/meta/main.yml`~~ | ~~Trivial~~ | ✅ Done |
| 3.7 | ~~Desactivar Mermaid graphs en `.docsible`~~ | ~~`.docsible`~~ | ~~Trivial~~ | ✅ Done |
| 3.8 | ~~Eliminar emojis del Taskfile~~ | ~~`Taskfile.yml`~~ | ~~Trivial~~ | ✅ Done |
| 3.9 | ~~Crear `CHANGELOG.md` vacío con formato Conventional Commits~~ | | | ❌ Descartada |

**Riesgo:** NULO. Solo archivos de documentación.
**Pendientes:** 3.2 (pospuesta)

---

## Sprint 4: Fijado y upgrade de versiones — ✅ COMPLETADO

**Objetivo:** Pinnear TODAS las versiones del proyecto a releases estables verificadas + actualizar a las últimas compatibles.

### Componentes y versiones a aplicar

| # | Componente | Versión actual | Versión target | Riesgo |
|---|-----------|---------------|----------------|--------|
| 1 | **K3s** | v1.35.0+k3s1 | v1.35.3+k3s1 | Bajo |
| 2 | **Cilium** | 1.19.0 | 1.19.3 | Bajo |
| 3 | **cert-manager** | "" (sin fijar) | v1.20.2 | Bajo |
| 4 | **ArgoCD** | "" (sin fijar) | 9.4.17 (v3.3.6) | Bajo |
| 5 | **Gateway API** | v1.2.0 | v1.5.1 | Bajo |
| 6 | **gVisor** | 20231204.0 | 20260413.0 | Medio |
| 7 | **External Secrets** | sin definir | 2.3.0 | Bajo |
| 8 | **NVIDIA Plugin** | 0.14.3 | 0.19.0 | Bajo |
| 9 | **Prometheus Stack** | 72.6.2 | 83.6.0 | Bajo |
| 10 | **Prometheus CRDs** | 26.0.0 | 28.0.1 | Bajo |

### Archivos detallados por componente

**K3s (6 archivos):**
- `group_vars/all.yml` → `k3s_version: "v1.35.3+k3s1"`
- `roles/k3s_server/meta/argument_specs.yml` → default + description
- `roles/k3s_server/README.md` → 3 ocurrencias
- `roles/k3s_agent/meta/argument_specs.yml` → default
- `roles/k3s_agent/README.md` → 1 ocurrencia

**Cilium (3 archivos):**
- `group_vars/all.yml` → `cilium_chartVersion: "1.19.3"`
- `Taskfile.yml` → `--version 1.19.3`
- `roles/cilium/meta/argument_specs.yml` → default: "1.19.3"

**cert-manager (1 archivo):**
- `group_vars/all.yml` → `certManager_chartVersion: "v1.20.2"`

**ArgoCD (1 archivo):**
- `group_vars/all.yml` → `argocd_chartVersion: "9.4.17"` (NOTA: v3.3.7 tiene bug de reconciliación #27344, se usa v3.3.6)

**Gateway API (2 archivos + fix):**
- `group_vars/all.yml` → `gateway_apiVersion: "v1.5.1"`
- `roles/crds_bootstrap/meta/argument_specs.yml` → default: "v1.5.1"
- `roles/crds_bootstrap/tasks/main.yml` → cambiar `state: present` a `state: apply` + `server_side_apply: true` (requerido para CRDs >v1.4.0)

**gVisor (1-2 archivos):**
- `group_vars/all.yml` → `gvisor_version: "20260413.0"`
- `roles/gvisor/tasks/host.yml` → agregar descarga de `containerd-shim-runsc-v1` (recomendado)

**External Secrets (1 archivo):**
- `group_vars/all.yml` → agregar `externalSecrets_chartVersion: "2.3.0"`

**NVIDIA Plugin (3-4 archivos):**
- `group_vars/all.yml` → agregar `nvidia_devicePluginVersion: "0.19.0"`
- `group_vars/k3s_server.yml` → actualizar `nvidia_devicePluginVersion: "0.19.0"`
- `k8s/bootstrap/nvidia/values.yaml` → `enableNodeFeatureApi: true` + `gfd.sleepInterval: infinite`
- `roles/nvidia_gpu/meta/argument_specs.yml` → agregar default

**Prometheus (2 archivos):**
- `group_vars/all.yml` → `prometheus_operatorCrdsVersion: "28.0.1"`
- `k8s/gitops/observability/kube-prometheus-stack/kustomization.yaml` → `version: "83.6.0"`

### Notas críticas
- **ArgoCD**: v3.3.7 tiene bug conocido de reconciliación (#27344). Se fija en v3.3.6 (chart 9.4.17).
- **Gateway API**: v1.5+ requiere server-side apply para CRDs experimentales (>262KB).
- **gVisor**: Salto de 2.5 años. Riesgo medio — validar workloads post-upgrade.
- **Prometheus**: CRDs deben actualizarse PRIMERO (28.0.1), luego el stack (83.6.0).
- **NVIDIA**: `enableNodeFeatureApi: false` en values.yaml entra en conflicto con default de v0.19.0.

**Riesgo:** BAJO-MEDIO. Cambios de configuración, verificables con `--check`.
**Estado:** ✅ Completado. Todas las versiones pinnadas en `group_vars/all.yml`.

---

## Sprint 5: Limpieza de roles y estructura

**Objetivo:** Refactorizar estructura de roles. Requiere más contexto del flujo.

| # | Tarea | Archivos | Esfuerzo |
|---|-------|----------|----------|
| 5.1 | Mover AI CLI tools de `developer_tools` a role separado o eliminar | `roles/developer_tools/tasks/main.yml` | Simple |
| 5.2 | Agregar `tasks/main.yml` a `nvidia_gpu` que documente el patrón de uso | `roles/nvidia_gpu/tasks/main.yml` | Trivial |
| 5.3 | Agregar `meta/dependencies` explícitas a roles con dependencias implícitas | `roles/*/meta/main.yml` | Simple |
| 5.4 | Agregar health probes a deployments de mineros | `k8s/bootstrap/miners/*/deployment.yaml` | Simple |
| 5.5 | Agregar Pod Security labels al namespace `miners` | `k8s/bootstrap/namespaces/miners.yaml` | Trivial |

**Riesgo:** BAJO. Cambios aislados por role.

---

## Sprint 6: Lo sustancial (requiere más análisis)

**Objetivo:** Los cambios que tocan arquitectura o requieren decisiones de diseño.

| # | Tarea | Archivos | Esfuerzo |
|---|-------|----------|----------|
| 6.1 | CI pipeline: agregar yamllint, ansible-syntax, shellcheck, checkov a GitHub Actions | `.github/workflows/build.yml` | Medio |
| 6.2 | NetworkPolicies para namespace `miners` | `k8s/bootstrap/network-policies/` | Medio |
| 6.3 | RBAC mínimo con ServiceAccounts dedicados | `k8s/bootstrap/rbac/` | Medio |
| 6.4 | Alertmanager: configurar al menos un receiver real | `k8s/gitops/observability/...` | Simple-Medio |
| 6.5 | Deploy Loki para logging | `k8s/gitops/observability/loki/` | Medio |
| 6.6 | Estrategia de backup (Velero o scripts) | Nuevo | Complejo |
| 6.7 | Fix K3s upgrade idempotency (version check antes de install) | `roles/k3s_server/tasks/main.yml`, `roles/k3s_agent/tasks/main.yml` | Medio |
| 6.8 | Unificar fuente de verdad de manifiestos (lookup vs k8s_manifestsDir) | Múltiple | Complejo |

**Riesgo:** MEDIO-ALTO. Tocar arquitectura requiere testing cuidadoso.

---

## Resumen

| Sprint | Foco | Tareas | Riesgo | Tiempo est. |
|--------|------|--------|--------|-------------|
| **0** | ~~Eliminar Molecule~~ | ~~5~~ | ~~Nulo~~ | ~~15 min~~ | ✅ Done |
| **1** | ~~Código muerto~~ | ~~10~~ | ~~Nulo~~ | ~~20 min~~ | ✅ Done |
| **2** | Fixes triviales | 6 (3✅, 1❌, 2⏸️) | Mínimo | 30 min |
| **3** | Documentación | 9 (5✅, 3❌, 1⏸️) | Nulo | 45 min |
| **4** | Versiones (10 componentes) | ~20 archivos | Bajo-Medio | 60 min | ✅ Done |
| **5** | Estructura de roles | 5 | Bajo | 30 min | |
| **6** | Arquitectura | 8 | Medio-Alto | Variable | |

**Total pendiente:** 24 tareas en 4 sprints (Sprints 0, 1, 4 completados).
