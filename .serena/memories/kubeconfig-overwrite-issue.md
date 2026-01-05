# Problema de Sobrescritura de Kubeconfig

El rol `k3s_server` actualmente implementa una estrategia destructiva para el archivo de configuración de Kubernetes del usuario (`~/.kube/config`).

## Comportamiento Actual
La tarea "Write kubeconfig for target user" utiliza el módulo `copy` para escribir el archivo generado por el servidor K3s (con la IP de Tailscale).

```yaml
- name: Write kubeconfig for target user
  ansible.builtin.copy:
    content: "{{ k3s_kubeconfig_canonical }}"
    dest: "/home/{{ ansible_user }}/.kube/config"
    # ...
```

## Impacto
- Elimina cualquier contexto existente de otros clústeres.
- Sobrescribe preferencias de usuario (namespace por defecto, usuario actual).
- Impide el manejo de múltiples clústeres desde el mismo nodo de control si se ejecuta el playbook.

## Solución Futura Requerida
Implementar una estrategia de fusión (merge) o backup:
1.  **Backup**: Usar `backup: yes` en la tarea de copia para preservar la versión anterior.
2.  **Merge Inteligente**: Usar `kubectl config set-cluster`, `set-credentials` y `set-context` para agregar/actualizar solo el contexto del clúster actual sin tocar otros. O utilizar una herramienta/script de Python para fusionar los YAMLs.
