# Refactor de variables Ansible: hallazgos y plan

Comparativa: `HEAD` vs `154d537ec2e95d5069ae6762f9ebadd51f484400`.

## Hallazgos clave (roturas y regresiones)

- **K3s server** perdió el flujo Tailscale de kubeconfig: se eliminó la creación de `k8s_kubeconfig` y `k3s-tailscale.yaml`, y ahora reemplaza `127.0.0.1` por `inventory_hostname`, rompiendo acceso remoto y tareas que dependen de `k8s_kubeconfig`. (`roles/k3s_server/tasks/main.yml`)
- Se eliminaron pasos funcionales (no solo renombrados): audit policy/log, `systemd daemon_reload` y enable/start explícito, por lo que el override puede no aplicarse. (`roles/k3s_server/tasks/main.yml`)
- **k3s_common** perdió `recreate/uninstall`, eliminó dirs CNI y cambió el path del template de containerd a `/etc/rancher/k3s/...` (K3s espera `/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl`). (`roles/k3s_common/tasks/main.yml`)
- Template de containerd “simplificado” eliminó parámetros críticos (snapshotter, unprivileged ports, etc.) y la sección CNI. (`roles/k3s_common/templates/containerd-config.toml.tmpl.j2`)
- Variables antiguas aún referenciadas → `undefined` en runtime:
  - K3s agent config: `roles/k3s_agent/templates/config.yaml.j2`
  - External Secrets: `roles/external_secrets/tasks/main.yml`
  - CRDs bootstrap: `roles/crds_bootstrap/tasks/main.yml`
  - Molecule Glances: `molecule/glances/tests/test_glances.py`

## Cambios requeridos (manteniendo el renombrado)

- **Reponer flujo Tailscale kubeconfig** de `154d` pero con nombres nuevos: generar `k3s_kubeconfig_canonical`, escribir `/etc/rancher/k3s/k3s-tailscale.yaml`, escribir `k8s_kubeconfig` y usar `tailscale_ip` para el kubeconfig local. (`roles/k3s_server/tasks/main.yml`)
- **Restaurar piezas funcionales** eliminadas sin relación al renombrado:
  - audit policy/log
  - `systemd daemon_reload`, enable/start donde correspondía
  - `k3s_common` recreate/uninstall, dirs CNI y path correcto del template de containerd
  - template de containerd volver al contenido anterior pero con nuevos nombres
- **Renombrar referencias rezagadas**:
  - `roles/k3s_agent/templates/config.yaml.j2` → `k3s_agentServerUrl`, `k3s_agentToken`, `k3s_agentNodeLabels`, `k3s_agentNodeTaints`, `k3s_agentKubeletArgs`
  - `roles/external_secrets/tasks/main.yml` → `externalSecrets_*`
  - `roles/crds_bootstrap/tasks/main.yml` → `prometheus_operatorCrdsNamespace`, `prometheus_operatorCrdsVersion`
  - `molecule/glances/tests/test_glances.py` → `glances_venvPath`

## Plan

1. Completar migración de nombres (sin aliases permanentes salvo compat temporal).
2. Restaurar flujo funcional de kubeconfig en K3s server con `tailscale_ip`.
3. Revertir `k3s_common` al flujo funcional anterior (con nuevos nombres).
4. Actualizar tests y roles auxiliares con variables nuevas.
