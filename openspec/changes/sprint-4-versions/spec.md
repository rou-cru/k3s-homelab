# Spec: Sprint 4 - Fijado y Upgrade de Versiones

## Component: version-management

### Requirements

#### REQ-4.1: K3s Version Upgrade
**MUST** actualizar K3s de v1.35.0+k3s1 a v1.35.3+k3s1 en todos los archivos relevantes.

**Scenarios:**
- **SC-4.1.1**: Dado que `group_vars/all.yml` define `k3s_version`, cuando se actualiza el valor, entonces debe ser `"v1.35.3+k3s1"`
- **SC-4.1.2**: Dado que `roles/k3s_server/meta/argument_specs.yml` tiene default de `k3s_serverVersion`, cuando se sincroniza, entonces el default debe ser `"v1.35.3+k3s1"`
- **SC-4.1.3**: Dado que `roles/k3s_agent/meta/argument_specs.yml` tiene default de `k3s_agentVersion`, cuando se sincroniza, entonces el default debe ser `"v1.35.3+k3s1"`
- **SC-4.1.4**: Dado que `roles/k3s_server/README.md` menciona la versión, cuando se actualiza la documentación, entonces debe reflejar `"v1.35.3+k3s1"` en todas las ocurrencias
- **SC-4.1.5**: Dado que `roles/k3s_agent/README.md` menciona la versión, cuando se actualiza la documentación, entonces debe reflejar `"v1.35.3+k3s1"`

#### REQ-4.2: Cilium Version Upgrade
**MUST** actualizar Cilium de 1.19.0 a 1.19.3 y eliminar inconsistencias.

**Scenarios:**
- **SC-4.2.1**: Dado que `group_vars/all.yml` define `cilium_chartVersion`, cuando se actualiza, entonces debe ser `"1.19.3"`
- **SC-4.2.2**: Dado que `roles/cilium/meta/argument_specs.yml` tiene default `1.18.5`, cuando se corrige, entonces debe ser `"1.19.3"` para coincidir con group_vars
- **SC-4.2.3**: Dado que `Taskfile.yml` tiene versión hardcodeada, cuando se refactoriza, entonces debe usar la variable `{{ cilium_chartVersion }}`

#### REQ-4.3: Gateway API Version Upgrade
**MUST** actualizar Gateway API de v1.2.0 a v1.5.1 y agregar server-side apply.

**Scenarios:**
- **SC-4.3.1**: Dado que `group_vars/all.yml` define `gateway_apiVersion`, cuando se actualiza, entonces debe ser `"v1.5.1"`
- **SC-4.3.2**: Dado que `roles/crds_bootstrap/meta/argument_specs.yml` tiene default, cuando se actualiza, entonces debe ser `"v1.5.1"`
- **SC-4.3.3**: Dado que Gateway API v1.5+ requiere server-side apply para CRDs >262KB, cuando se aplica el CRD, entonces debe usar `state: apply` con `server_side_apply: true`

#### REQ-4.4: gVisor Version Upgrade
**MUST** actualizar gVisor de 20231204.0 a 20260413.0.

**Scenarios:**
- **SC-4.4.1**: Dado que `group_vars/all.yml` define `gvisor_version`, cuando se actualiza, entonces debe ser `"20260413.0"`
- **SC-4.4.2**: Dado que el salto es de 2.5 años, cuando se valida post-upgrade, entonces los workloads sandboxed deben funcionar correctamente

#### REQ-4.5: cert-manager Version Definition
**MUST** agregar versión fijada para cert-manager.

**Scenarios:**
- **SC-4.5.1**: Dado que `group_vars/all.yml` no tiene `certManager_chartVersion` definido, cuando se agrega, entonces debe ser `"v1.20.2"`

#### REQ-4.6: ArgoCD Version Definition
**MUST** agregar versión fijada para ArgoCD (evitando v3.3.7 con bug).

**Scenarios:**
- **SC-4.6.1**: Dado que `group_vars/all.yml` no tiene `argocd_chartVersion` definido, cuando se agrega, entonces debe ser `"9.4.17"` (que instala ArgoCD v3.3.6)
- **SC-4.6.2**: Dado que ArgoCD v3.3.7 tiene bug de reconciliación #27344, cuando se fija la versión, entonces debe ser explícitamente 9.4.17 (no latest)

#### REQ-4.7: External Secrets Operator Version
**MUST** agregar soporte para External Secrets Operator con versión fijada.

**Scenarios:**
- **SC-4.7.1**: Dado que `group_vars/all.yml` no tiene `externalSecrets_chartVersion`, cuando se agrega, entonces debe ser `"2.3.0"`

#### REQ-4.8: NVIDIA Device Plugin Upgrade
**MUST** actualizar NVIDIA Device Plugin de 0.14.3 a 0.19.0 y actualizar configuración.

**Scenarios:**
- **SC-4.8.1**: Dado que `group_vars/k3s_server.yml` define `nvidia_devicePluginVersion`, cuando se actualiza, entonces debe ser `"0.19.0"`
- **SC-4.8.2**: Dado que `k8s/bootstrap/nvidia/values.yaml` necesita configuración para v0.19.0, cuando se actualiza, entonces debe tener `enableNodeFeatureApi: true` y `gfd.sleepInterval: infinite`
- **SC-4.8.3**: Dado que `roles/nvidia_gpu/meta/argument_specs.yml` no tiene default, cuando se agrega, entonces `nvidia_devicePluginVersion` debe tener default `"0.19.0"`

#### REQ-4.9: Prometheus Stack Upgrade
**MUST** actualizar Prometheus CRDs primero, luego el stack.

**Scenarios:**
- **SC-4.9.1**: Dado que `group_vars/all.yml` define `prometheus_operatorCrdsVersion`, cuando se actualiza, entonces debe ser `"28.0.1"`
- **SC-4.9.2**: Dado que `k8s/gitops/observability/kube-prometheus-stack/kustomization.yaml` define la versión, cuando se actualiza, entonces debe ser `"83.6.0"`
- **SC-4.9.3**: Dado que las CRDs deben actualizarse antes que el stack, cuando se aplica el cambio, entonces el orden debe respetarse

## Component: crds-bootstrap

### Requirements

#### REQ-4.10: Server-Side Apply para Gateway API
**MUST** usar server-side apply para Gateway API CRDs v1.5+.

**Scenarios:**
- **SC-4.10.1**: Dado que las CRDs de Gateway API v1.5.1 superan 262KB, cuando se aplica con k8s, entonces debe usar `state: apply` en lugar de `state: present`
- **SC-4.10.2**: Dado que server-side apply es requerido, cuando se ejecuta el task, entonces debe incluir `server_side_apply: true`

## Verification Criteria

- [ ] Todas las versiones en group_vars/all.yml coinciden con las versiones target del Sprint 4
- [ ] No hay versiones hardcodeadas en Taskfile.yml
- [ ] Los argument_specs.yml tienen defaults sincronizados con group_vars
- [ ] `ansible-playbook --check` ejecuta sin errores de sintaxis
- [ ] `yamllint` pasa sin errores en los archivos modificados
- [ ] Los archivos README.md reflejan las versiones correctas
