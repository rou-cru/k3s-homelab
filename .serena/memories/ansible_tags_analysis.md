# Diseño Estandarizado de Tags Ansible (Canon V2)

## 1. Filosofía del Sistema
El sistema de tags ha sido refactorizado para eliminar redundancias y ambigüedades, adoptando un modelo de **Matriz Capa-Característica**. Esto permite ejecuciones parciales precisas basadas en el ciclo de vida (Capas) o en la funcionalidad transversal (Características).

## 2. Definición de Tags Canónicos (Total: 6)

### Capas Verticales (Ciclo de Vida)
Definen la etapa de despliegue. Respetan un orden estricto de dependencias.
*   **`host`**: Infraestructura base. Todo lo que ocurre antes de Kubernetes.
    *   *Incluye:* Tuning de OS, Drivers NVIDIA, VPN (Tailscale), Herramientas CLI.
*   **`cluster`**: Plataforma Kubernetes.
    *   *Incluye:* K3s Server, CNI (Cilium), NVIDIA Device Plugin.
*   **`apps`**: Cargas de trabajo y aplicaciones finales.
    *   *Incluye:* Manifiestos, Miners, Secretos.

### Características Horizontales (Funcionalidad)
Definen componentes tecnológicos específicos que pueden cruzar capas.
*   **`os`**: Configuración pura del Sistema Operativo. (Subconjunto de `host` sin componentes externos complejos como VPN/GPU).
*   **`network`**: Pila completa de conectividad.
    *   *Incluye:* Sysctl Tuning (`host`), Tailscale (`host`), Cilium (`cluster`).
*   **`nvidia`**: Stack completo de GPU.
    *   *Incluye:* Drivers (`host`), Device Plugin (`cluster`).

## 3. Matriz de Ejecución

| Componente | Tags Asignados | Lógica |
| :--- | :--- | :--- |
| **Base OS (Preflight/Common)** | `['host', 'os']` | Configuración base. |
| **Network Tuning (Sysctl)** | `['host', 'os', 'network']` | Optimización extraída a `site.yaml`. |
| **Tailscale VPN** | `['host', 'network']` | Red nivel Host. |
| **NVIDIA Drivers** | `['host', 'nvidia']` | Drivers nivel Host. |
| **K3s Server** | `['cluster']` | Núcleo K8s. |
| **Cilium CNI** | `['cluster', 'network']` | Red nivel Cluster. |
| **NVIDIA Plugin** | `['cluster', 'nvidia']` | Integración GPU Cluster. |
| **Workloads** | `['apps']` | Aplicaciones. |

## 4. Cambios Arquitectónicos Clave
*   **Extracción de Network Optimization:** La tarea `network_optimization.yml` se eliminó de la inclusión automática de `common` y se invocó explícitamente en `site.yaml` para permitir que el tag `network` la ejecute sin arrastrar todo el rol `common`.
*   **Eliminación de Sinónimos:** Se eliminaron tags redundantes como `gpu`, `kubernetes`, `system`, `preflight`, etc.

## 5. Guía de Uso Operativo
*   **Setup Inicial Completo:** `ansible-playbook site.yaml`
*   **Solo Infraestructura:** `ansible-playbook site.yaml --tags host`
*   **Solo Red (VPN + CNI + Tuning):** `ansible-playbook site.yaml --tags network`
*   **Solo Stack GPU:** `ansible-playbook site.yaml --tags nvidia` (Nota: Requiere gestión de reinicios si se actualizan drivers).
*   **Solo Apps:** `ansible-playbook site.yaml --tags apps`
