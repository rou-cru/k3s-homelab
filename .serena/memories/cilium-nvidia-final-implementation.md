# Cilium + NVIDIA GPU - Implementación Final (2025-12-31)

## Cambios Implementados

### 1. Cilium CNI Optimizado ✅
**Archivo**: `roles/cilium/templates/cilium-values.yaml.j2`

**Features Habilitadas:**
- `kubeProxyReplacement: true` - Cilium reemplaza kube-proxy completamente
- `socketLB.enabled: true` - Accelerated local service access
- `gatewayAPI.enabled: true` - Gateway API nativo
- `hubble.enabled: true` con relay + UI + métricas completas
- `bpf.preallocateMaps: true` - Reduce latencia
- `bpf.distributedLRU: true` - Mejor performance multi-core
- `bandwidthManager.enabled: true` + BBR congestion control
- `operator.replicas: 1` - Single-node cluster

**Values file:** 202 líneas (reducido de 4011 líneas originales)

---

### 2. NVIDIA GPU Refactorizado ✅

#### Estructura Nueva:
```
roles/nvidia_gpu/
├── tasks/
│   ├── host.yml      ← Drivers, toolkit, containerd (PRE-K3s)
│   └── cluster.yml   ← Helm chart NFD+GFD+device-plugin (POST-Cilium)
├── templates/
│   └── config.toml.tmpl
├── files/
│   └── nvidia-device-plugin-values.yaml
└── defaults/
    └── main.yml
```

#### Archivo: `nvidia-device-plugin-values.yaml` - Cambios:

**GFD Habilitado:**
```yaml
gfd:
  enabled: true  # GPU Feature Discovery crea labels nvidia.com/*
```

**RuntimeClassName:**
```yaml
runtimeClassName: nvidia  # Device plugin usa nvidia runtime
```

**Recursos Explícitos:**
```yaml
resources:
  limits:
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

**NodeSelector GFD:**
```yaml
nodeSelector:
  nvidia.com/gpu.present: "true"  # Label creado por GFD
```

**Affinity con Fallback:**
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      # Option 1: GFD label (preferred)
      - matchExpressions:
        - key: nvidia.com/gpu.present
          operator: In
          values: ["true"]
      # Option 2: NFD PCI label (fallback)
      - matchExpressions:
        - key: feature.node.kubernetes.io/pci-10de.present
          operator: In
          values: ["true"]
```

**Tolerations:**
```yaml
tolerations:
  - key: CriticalAddonsOnly
    operator: Exists
  - key: nvidia.com/gpu
    operator: Exists
    effect: NoSchedule
  - key: node.cilium.io/agent-not-ready  # ← NUEVO
    operator: Exists
```

---

### 3. Orden de Ejecución ✅
**Archivo**: `site.yaml`

```yaml
roles:
  - preflight
  - common
  - developer_tools (optional)
  - nvidia_gpu (tasks_from: host.yml)    # ← ANTES de K3s
  - tailscale
  - k3s_server                            # ← Detecta nvidia runtime
  - cilium                                # ← CNI
  - nvidia_gpu (tasks_from: cluster.yml) # ← DESPUÉS de Cilium
```

**Beneficios:**
- K3s detecta nvidia-container-runtime en startup (NO restart necesario)
- NFD/GFD pueden usar Cilium CNI desde el inicio
- Device plugin puede schedulear workloads GPU inmediatamente

---

### 4. Archivos Eliminados ✅
- `roles/nvidia_gpu/handlers/main.yml` - Ya no se necesita restart de K3s
- `roles/nvidia_gpu/tasks/main.yml` - Dividido en host.yml + cluster.yml

---

## Componentes NVIDIA Desplegados

### Host Level (nvidia_gpu/tasks/host.yml):
1. **Drivers NVIDIA** - Auto-detectados o fallback
2. **nvidia-container-toolkit** - Runtime para containers
3. **Containerd config** - `/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl`
   - Runtime `nvidia` configurado con `BinaryName: /usr/bin/nvidia-container-runtime`

### Cluster Level (nvidia_gpu/tasks/cluster.yml):
1. **NFD** (Node Feature Discovery) - Subchart, 1 master replica
   - Crea label: `feature.node.kubernetes.io/pci-10de.present: "true"`
2. **GFD** (GPU Feature Discovery) - Habilitado
   - Crea labels: `nvidia.com/gpu.count`, `nvidia.com/gpu.product`, `nvidia.com/cuda.driver-version.full`, etc.
3. **NVIDIA Device Plugin** - DaemonSet
   - Expone `nvidia.com/gpu` resource
   - Usa `runtimeClassName: nvidia`

---

## Verificación Post-Deployment

### 1. Verificar Cilium
```bash
kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement
# Expected: KubeProxyReplacement: True
```

### 2. Verificar Hubble
```bash
kubectl get pods -n kube-system -l k8s-app=hubble-ui
kubectl get pods -n kube-system -l k8s-app=hubble-relay
kubectl port-forward -n kube-system svc/hubble-ui 12000:80
```

### 3. Verificar NVIDIA Runtime
```bash
kubectl get runtimeclass nvidia
# Expected: nvidia runtime class exists
```

### 4. Verificar GFD Labels
```bash
kubectl get nodes -o json | jq '.items[].metadata.labels | with_entries(select(.key | startswith("nvidia.com")))'
```

**Expected:**
```json
{
  "nvidia.com/cuda.driver-version.major": "535",
  "nvidia.com/gpu.count": "1",
  "nvidia.com/gpu.present": "true",
  "nvidia.com/gpu.product": "...",
  "nvidia.com/gpu.memory": "..."
}
```

### 5. Verificar Device Plugin
```bash
kubectl get ds -n kube-system nvidia-device-plugin
kubectl describe node <node> | grep nvidia.com/gpu
```

**Expected:**
```
Capacity:
  nvidia.com/gpu: 1
Allocatable:
  nvidia.com/gpu: 1
```

### 6. Test GPU Workload
```bash
kubectl run gpu-test --image=nvidia/cuda:12.0-base --rm -it \
  --overrides='{"spec":{"runtimeClassName":"nvidia","containers":[{"name":"gpu-test","image":"nvidia/cuda:12.0-base","command":["nvidia-smi"],"resources":{"limits":{"nvidia.com/gpu":"1"}}}]}}'
```

**Expected:** `nvidia-smi` output mostrando GPU info

---

## Uso de GPU en Pods

### Pod Spec Mínimo:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gpu-workload
spec:
  runtimeClassName: nvidia  # ← REQUERIDO
  containers:
  - name: app
    image: nvidia/cuda:12.0-base
    resources:
      limits:
        nvidia.com/gpu: 1  # ← Request GPU
```

### Lo que sucede internamente:
1. Scheduler busca nodo con `nvidia.com/gpu.present: true`
2. Device plugin verifica disponibilidad de GPU
3. Kubelet usa runtime `nvidia` para el container
4. Runtime monta:
   - `/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm`
   - Drivers CUDA en `/usr/local/cuda`
   - Bibliotecas en `/usr/lib/x86_64-linux-gnu`
5. **Aplicación ve GPU como bare metal** - transparente

---

## Tags Ansible

```bash
# Deploy completo
ansible-playbook -i inventory.ini site.yaml

# Solo Cilium
ansible-playbook -i inventory.ini site.yaml --tags cilium

# Solo NVIDIA host setup
ansible-playbook -i inventory.ini site.yaml --tags nvidia-host

# Solo NVIDIA cluster setup
ansible-playbook -i inventory.ini site.yaml --tags nvidia-cluster

# NVIDIA completo
ansible-playbook -i inventory.ini site.yaml --tags nvidia
```

---

## Referencias
- [NVIDIA k8s-device-plugin](https://github.com/NVIDIA/k8s-device-plugin)
- [GPU Feature Discovery](https://github.com/NVIDIA/k8s-device-plugin/blob/main/docs/gpu-feature-discovery/README.md)
- [K3s Advanced Options](https://docs.k3s.io/advanced)
- [Cilium Documentation](https://docs.cilium.io/)
- [Gateway API](https://gateway-api.sigs.k8s.io/)
