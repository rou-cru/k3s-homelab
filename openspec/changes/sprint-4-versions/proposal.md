# Proposal: Sprint 4 - Fijado y Upgrade de Versiones

## Intent
Actualizar todas las versiones de componentes del proyecto k3s-homelab a releases estables verificadas, corregir inconsistencias detectadas entre argument_specs y group_vars, y fijar versiones que actualmente están sin definir.

## Scope

### In Scope
- Upgrade K3s: v1.35.0+k3s1 → v1.35.3+k3s1
- Upgrade Cilium: 1.19.0 → 1.19.3
- Upgrade Gateway API: v1.2.0 → v1.5.1 + server-side apply
- Upgrade gVisor: 20231204.0 → 20260413.0
- Upgrade NVIDIA Device Plugin: 0.14.3 → 0.19.0 + actualizar values.yaml
- Upgrade Prometheus: CRDs 26.0.0 → 28.0.1, Stack 72.6.2 → 83.6.0
- Fijar cert-manager: v1.20.2 (sin definir → definido)
- Fijar ArgoCD: 9.4.17/v3.3.6 (sin definir → definido)
- Agregar External Secrets: 2.3.0 (nuevo)
- Sincronizar argument_specs con group_vars
- Corregir Taskfile.yml para usar variable de Cilium

### Out of Scope
- Upgrade de dependencias de desarrollo (nvm, etc.)
- Cambios funcionales en la lógica de los roles
- Testing automático (el proyecto no tiene tests unitarios)

## Capabilities

### New Capabilities
- `version-management`: Centralización y fijado de todas las versiones de componentes
- `cert-manager-version`: Soporte explícito para versión de cert-manager
- `argocd-version`: Soporte explícito para versión de ArgoCD
- `external-secrets`: Soporte para External Secrets Operator

### Modified Capabilities
- `k3s-bootstrap`: Actualización de versión de K3s
- `cilium-cni`: Actualización de versión de Cilium
- `gateway-api`: Actualización de versión + server-side apply
- `nvidia-gpu`: Actualización de versión + configuración de Node Feature API
- `prometheus-stack`: Actualización de versión del stack y CRDs

## Approach

1. Actualizar `group_vars/all.yml` con todas las versiones target
2. Sincronizar `group_vars/k3s_server.yml` con nueva versión de NVIDIA
3. Actualizar `argument_specs.yml` en roles afectados para reflejar defaults correctos
4. Modificar `roles/crds_bootstrap/tasks/main.yml` para usar server-side apply
5. Actualizar `k8s/bootstrap/nvidia/values.yaml` con nuevos parámetros
6. Actualizar `Taskfile.yml` para usar variable de Cilium en lugar de hardcode
7. Actualizar READMEs con nuevas versiones

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `group_vars/all.yml` | Modified | Actualizar 10+ variables de versión |
| `group_vars/k3s_server.yml` | Modified | NVIDIA plugin version |
| `roles/k3s_server/meta/argument_specs.yml` | Modified | Sincronizar default de k3s_version |
| `roles/k3s_agent/meta/argument_specs.yml` | Modified | Sincronizar default de k3s_agentVersion |
| `roles/cilium/meta/argument_specs.yml` | Modified | Corregir default 1.18.5 → 1.19.3 |
| `roles/crds_bootstrap/meta/argument_specs.yml` | Modified | Actualizar gateway_apiVersion |
| `roles/crds_bootstrap/tasks/main.yml` | Modified | Agregar server_side_apply: true |
| `roles/nvidia_gpu/meta/argument_specs.yml` | Modified | Agregar default de nvidia_devicePluginVersion |
| `k8s/bootstrap/nvidia/values.yaml` | Modified | Agregar enableNodeFeatureApi y gfd.sleepInterval |
| `k8s/gitops/observability/kube-prometheus-stack/kustomization.yaml` | Modified | Actualizar a 83.6.0 |
| `Taskfile.yml` | Modified | Usar variable cilium_chartVersion en lugar de hardcode |
| `roles/k3s_server/README.md` | Modified | Actualizar versión documentada |
| `roles/k3s_agent/README.md` | Modified | Actualizar versión documentada |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| gVisor 2.5 años de salto puede romper workloads | Medium | Validar post-upgrade, tener rollback plan |
| Gateway API v1.5+ requiere server-side apply | Low | Implementar server_side_apply: true |
| NVIDIA v0.19.0 cambia defaults de Node Feature API | Low | Explicitar enableNodeFeatureApi: true en values.yaml |
| ArgoCD v3.3.7 tiene bug de reconciliación | Low | Usar v3.3.6 (chart 9.4.17) explícitamente |

## Rollback Plan

1. Revertir commits de este sprint
2. Re-aplicar con `ansible-playbook site.yaml` usando versiones anteriores
3. Para componentes Kubernetes: `helm rollback` o reinstalar con versiones anteriores
4. K3s: Reinstalar con versión anterior (requiere recrear cluster)

## Dependencies
- Acceso al cluster para validación post-upgrade
- Helm CLI para verificar charts

## Success Criteria

- [ ] Todas las variables de versión en group_vars/all.yml tienen valores definidos
- [ ] No hay versiones hardcodeadas en Taskfile.yml
- [ ] argument_specs.yml sincronizados con group_vars
- [ ] Gateway API usa server_side_apply: true
- [ ] NVIDIA values.yaml tiene enableNodeFeatureApi configurado
- [ ] Validación con `ansible-playbook --check` pasa sin errores
