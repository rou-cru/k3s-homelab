# gVisor Implementation Plan for k3s-homelab

**Fecha**: 2026-01-14
**Contexto**: Preparar cluster para workloads de clientes Akash con sandbox obligatorio
**Hardware**: ASUS RoG Strix G614JI (Intel i9-13980HX, NVIDIA RTX 4070 Laptop, 32GB DDR5)
**Driver NVIDIA**: nvidia-driver-535 (fallback actual)

---

## 🎯 OBJETIVOS

1. **Sandbox Multi-Tenant**: Aislar workloads de clientes Akash con gVisor (runsc)
2. **GPU Selectivo**: Habilitar GPU en workloads sandboxed cuando lo soliciten
3. **Performance Optimizado**: Minimizar overhead en bare-metal
4. **Seguridad por Default**: Workloads de cliente SIEMPRE con gVisor, infra opcional

---

## 📚 RESUMEN DE INVESTIGACIÓN

### ¿Qué es gVisor?

gVisor es un **sandbox de contenedores** que proporciona aislamiento entre aplicaciones y el kernel del host interceptando syscalls. A diferencia de VMs o containers tradicionales:

- **No virtualiza hardware**: Usa un kernel de userspace (Sentry)
- **Intercepta syscalls**: Vía ptrace o KVM (Systrap recomendado)
- **Compatible con OCI**: Funciona con containerd/Docker sin modificar imágenes

**Fuente**: [gVisor Architecture Guide](https://gvisor.dev/docs/architecture_guide/performance/)

---

## 🔌 SOPORTE DE GPU (nvproxy)

### Estado Actual

gVisor soporta GPU NVIDIA mediante **nvproxy**, un proxy driver que:

1. **Intercepta ioctls** de `/dev/nvidia*` y los reenvía al driver host
2. **No emula lógica**: Passthrough casi directo
3. **Shared memory**: GPU operations via shared memory (overhead mínimo)

**Overhead de GPU**: **Negligible** - la mayoría de comunicación GPU es vía shared memory donde gVisor no añade overhead

**Fuentes**:
- [GPU Support - gVisor](https://gvisor.dev/docs/user_guide/gpu/)
- [GPU-based Containers as a Service](https://topofmind.dev/blog/2025/10/21/gpu-based-containers-as-a-service/)

### Capabilities Soportadas

Por default:
- ✅ `compute` - CUDA workloads
- ✅ `utility` - nvidia-smi, monitoring

Opcionales (flag `--nvproxy-allowed-driver-capabilities`):
- `graphics` - OpenGL, Vulkan
- `video` - NVENC/NVDEC (encoding/decoding)

**Importante**: GKE Sandbox (Google) solo soporta CUDA workloads oficialmente.

**Fuente**: [GPU Support - gVisor](https://gvisor.dev/docs/user_guide/gpu/)

### GPUs Testeadas

- NVIDIA T4, L4, A100, H100
- RTX 4070 Laptop (tu GPU) **no está oficialmente testeada pero es arquitectura Ada Lovelace (similar a L4)**

**Workloads validados**:
- PyTorch
- Stable Diffusion
- LLMs (Large Language Models)
- CUDA general

**Fuente**: [Running Stable Diffusion on GPU with gVisor](https://gvisor.dev/blog/2023/06/20/gpu-pytorch-stable-diffusion/)

---

## ⚠️ LIMITACIONES CRÍTICAS

### 1. Driver Version Lock

**Problema**: NVIDIA ABI no es estable entre versiones de driver. gVisor debe conocer cada versión específica.

**Tu driver actual**: `nvidia-driver-535` (fallback)

**Validación requerida**:
```bash
runsc nvproxy list-supported-drivers
```

**Verificar** que tu versión exacta (535.x.y) esté soportada. Si no:
- Actualizar gVisor a última versión
- O cambiar driver a versión soportada

**Problema real reportado**: Version 535.161.07 soportada, 535.161.08 NO soportada → fatal error.

**Fuentes**:
- [Add support for nvidia driver version 535.161.08 · Issue #10605](https://github.com/google/gvisor/issues/10605)
- [GPU Support - gVisor](https://gvisor.dev/docs/user_guide/gpu/)

### 2. Mantenimiento Continuo

**Burden**: Cada nueva versión de driver requiere actualización de gVisor. Google no puede seguir el ritmo de NVIDIA (releases frecuentes).

**Implicación**: No puedes actualizar driver NVIDIA libremente sin verificar compatibilidad con gVisor.

**Estrategia recomendada**:
- Pin driver version estable y soportada
- Actualizar gVisor primero, luego driver
- Monitorear [gVisor releases](https://github.com/google/gvisor/releases)

**Fuente**: [GPU-based Containers as a Service](https://topofmind.dev/blog/2025/10/21/gpu-based-containers-as-a-service/)

### 3. Limitaciones Funcionales

- ❌ No Multi-GPU arbitrario (asume GPU index == minor device ID)
- ❌ No GPU checkpointing (CRIU)
- ❌ No MIG (Multi-Instance GPU) support explícito
- ⚠️ Capability segmentation limitada (compute+utility default, graphics/video opt-in)

**Fuentes**:
- [nvproxy assumes GPU index == minor device ID · Issue #9389](https://github.com/google/gvisor/issues/9389)
- [Support for GPU checkpointing · Issue #11095](https://github.com/google/gvisor/issues/11095)
- [nvproxy: Support GPU capability segmentation · Issue #10856](https://github.com/google/gvisor/issues/10856)

---

## 📊 OVERHEAD DE PERFORMANCE

### CPU Overhead

**Datos de producción** (Ant Group):
- **70%** de apps: **<1% overhead**
- **25%** de apps: **<3% overhead**
- **5%** de apps: >3% overhead (syscall-intensive)

**Syscall overhead**:
- Native: ~70ns
- gVisor: ~800ns (**11x overhead**)

**Contexto**: Apps compute-bound (como GPU workloads) hacen POCAS syscalls → overhead negligible.

**Plataforma recomendada**: **Systrap** (mejor performance que ptrace)

**Fuentes**:
- [Performance Guide - gVisor](https://gvisor.dev/docs/architecture_guide/performance/)
- [Running gVisor in Production at Scale in Ant](https://gvisor.dev/blog/2021/12/02/running-gvisor-in-production-at-scale-in-ant/)

### Memory Overhead

- **Fixed overhead**: ~150-200MB por sandbox (Sentry process)
- **No overhead en memory access**: Mappings directos, sin traducción
- **Factor de overhead**: 1.48x - 1.72x en memory-intensive workloads (pero GPU workloads usan GPU RAM, no system RAM)

**Fuente**: [Improving gVisor Memory Subsystem Performance](https://xhfu.me/files/ad5e3bbbdb2e7f4dbb5dc19c121e89a9/cse291_project_final_report.pdf)

### I/O Overhead

**Disk I/O**: Overhead significativo (125% en SQLite benchmark vs 17% Kata, 0% runc)

**Network I/O**: Moderado (depende de syscalls de networking)

**GPU I/O**: **Negligible** (shared memory bypass)

**Fuentes**:
- [How Containerization Affects Database Performance](https://kubeblocks.io/blog/does-containerization-affect-the-performance-of-databases)
- [Performance Evaluation of Container Runtimes](https://www.scitepress.org/Papers/2020/93404/93404.pdf)

### Benchmark Summary

| Workload Type | Overhead |
|---------------|----------|
| **GPU Compute** | <1% (mayoría vía shared memory) |
| **CPU Compute** | <1% (pocas syscalls) |
| **Syscall-heavy** | 5-30% (ej: file I/O intensivo) |
| **Memory access** | 0% (directo) |
| **Memory allocation** | 48-72% (syscalls de mmap/brk) |
| **Disk I/O** | 125% (interacción con filesystem) |

**Implicación para Akash**: Workloads GPU (AI/ML, rendering) tendrán overhead < 3% en la mayoría de casos.

---

## 🔧 INTEGRACIÓN CON K3S

### Arquitectura

K3s usa **containerd** embebido. Configuración en:
```
/var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

**⚠️ IMPORTANTE**: Este archivo es **sobrescrito** por K3s en cada reinicio. **NO editarlo directamente**.

**Solución**: Usar **template file**:
```
/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl
```

K3s renderiza el template y genera el config final.

**Fuentes**:
- [How to install and configure gVisor for K3s · GitHub](https://gist.github.com/Frichetten/c77ee24b12edd2ab852738fc8221a1f1)
- [Secure k3s with gVisor - devopstales](https://devopstales.github.io/kubernetes/k3s-gvisor/)

### Pasos de Configuración

#### 1. Instalar runsc Binary

**Opción A: Release oficial**
```bash
ARCH=$(uname -m)
URL=https://storage.googleapis.com/gvisor/releases/release/latest/${ARCH}
wget ${URL}/runsc ${URL}/runsc.sha512 \
  ${URL}/containerd-shim-runsc-v1 ${URL}/containerd-shim-runsc-v1.sha512
sha512sum -c runsc.sha512 -c containerd-shim-runsc-v1.sha512
rm -f *.sha512
chmod a+rx runsc containerd-shim-runsc-v1
sudo mv runsc containerd-shim-runsc-v1 /usr/local/bin
```

**Opción B: APT (si disponible)**
```bash
sudo apt-get install runsc
```

**Fuente**: [Containerd Quick Start - gVisor](https://gvisor.dev/docs/user_guide/containerd/quick_start/)

#### 2. Configurar Containerd Template

Crear `/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl`:

```toml
{{ template "base" . }}

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
  runtime_type = "io.containerd.runsc.v1"

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc-gpu]
  runtime_type = "io.containerd.runsc.v1"
  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc-gpu.options]
    TypeUrl = "io.containerd.runsc.v1.options"
    ConfigPath = "/etc/containerd/runsc-gpu.toml"
```

**Explicación**:
- `runsc`: Runtime base sin GPU
- `runsc-gpu`: Runtime con nvproxy habilitado

#### 3. Configurar runsc para GPU

Crear `/etc/containerd/runsc-gpu.toml`:

```toml
[runsc_config]
platform = "systrap"
nvproxy = true
nvproxy-allowed-driver-capabilities = "compute,utility"
```

**Flags clave**:
- `platform = "systrap"`: Mejor performance (vs ptrace)
- `nvproxy = true`: Habilita GPU passthrough
- `nvproxy-allowed-driver-capabilities`: Limitar capabilities (seguridad)

**Fuente**: [Containerd Advanced Configuration - gVisor](https://gvisor.dev/docs/user_guide/containerd/configuration/)

#### 4. Configurar NVIDIA Container Runtime (Integración)

Editar `/etc/nvidia-container-runtime/config.toml`:

```toml
[nvidia-container-cli]
#root = "/run/nvidia/driver"
#path = "/usr/bin/nvidia-container-cli"
#ldconfig = "@/sbin/ldconfig"
#load-kmods = true
#no-cgroups = false
#user = "root:video"
#ldcache = "/etc/ld.so.cache"

[nvidia-container-runtime]
#debug = "/var/log/nvidia-container-runtime.log"
#log-level = "info"
#mode = "auto"
#runtimes = ["docker-runc", "runc", "crun"]

# gVisor integration: Set runsc as the low-level runtime
runtimes = ["runsc"]

[nvidia-container-runtime.modes.cdi]
#annotation-prefixes = ["cdi.k8s.io/"]
#default-kind = "management.nvidia.com/gpu"
#spec-dirs = ["/etc/cdi", "/var/run/cdi"]

[nvidia-container-runtime.modes.csv]
#mount-spec-path = "/etc/nvidia-container-runtime/host-files-for-container.d"
```

**Crítico**: `runtimes = ["runsc"]` hace que nvidia-container-runtime delegue a runsc.

**Problema conocido**: Algunos reportan que nvidia-container-runtime no funciona con runsc en K8s. **Workaround**: No usar nvidia-container-runtime, configurar nvproxy directamente en runsc.

**Fuente**: [Running runsc with containerd and --nvproxy=true removes NVIDIA drivers · Issue #9368](https://github.com/google/gvisor/issues/9368)

#### 5. Reiniciar K3s

```bash
sudo systemctl restart k3s
# o
sudo systemctl restart k3s-agent  # si es worker node
```

#### 6. Crear RuntimeClasses en Kubernetes

**RuntimeClass sin GPU** (`gvisor.yaml`):
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
scheduling:
  nodeSelector:
    gvisor.enabled: "true"
```

**RuntimeClass con GPU** (`gvisor-gpu.yaml`):
```yaml
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor-gpu
handler: runsc-gpu
overhead:
  podFixed:
    memory: "200Mi"
    cpu: "100m"
scheduling:
  nodeSelector:
    gvisor.enabled: "true"
    nvidia.com/gpu.present: "true"
```

**Overhead**: Declarar overhead para que scheduler lo considere.

**Fuente**: [Kubernetes Quick Start - gVisor](https://gvisor.dev/docs/user_guide/quick_start/kubernetes/)

#### 7. Etiquetar Nodos

```bash
kubectl label node master1 gvisor.enabled=true
kubectl label node master1 nvidia.com/gpu.present=true
```

**Fuente**: [Securing Kubernetes Workloads with gVisor RuntimeClass](https://medium.com/@GiteshWadhwa/securing-kubernetes-workloads-implementing-gvisor-runtime-class-with-containerd-for-enhanced-04f61eb93d9d)

---

## 🎛️ USO SELECTIVO EN WORKLOADS

### Workloads de Cliente (Akash) - OBLIGATORIO gVisor

**Deployment example**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-workload
  namespace: akash-tenants
spec:
  template:
    spec:
      runtimeClassName: gvisor  # Sin GPU
      containers:
      - name: app
        image: client/app:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
```

**Con GPU**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client-gpu-workload
  namespace: akash-tenants
spec:
  template:
    spec:
      runtimeClassName: gvisor-gpu  # Con GPU
      containers:
      - name: gpu-app
        image: client/ml-app:latest
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
            nvidia.com/gpu: 1
          limits:
            nvidia.com/gpu: 1
```

### Workloads de Infra - OPCIONAL gVisor

**Expuestos públicamente** (ArgoCD, Grafana): Usar `gvisor` por seguridad adicional.

**Internos** (Prometheus, Loki): Usar `runc` (default) por performance.

**Miners**: **NUNCA gVisor** (necesitan privileged + hostNetwork + MSR access).

```yaml
# Ejemplo: ArgoCD con gVisor
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-server
  namespace: argocd
spec:
  template:
    spec:
      runtimeClassName: gvisor  # Sandboxed por exposición pública
      containers:
      - name: argocd-server
        # ...
```

---

## 🛡️ POLÍTICAS DE SEGURIDAD

### Namespace-Level Enforcement

Usar **Kyverno** para forzar `runtimeClassName` en namespaces de clientes:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-gvisor-akash
spec:
  validationFailureAction: Enforce
  background: true
  rules:
  - name: require-gvisor
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaceSelector:
            matchLabels:
              akash.network/tenant: "true"
    validate:
      message: "Akash tenant workloads must use gVisor runtime"
      pattern:
        spec:
          runtimeClassName: "gvisor | gvisor-gpu"
```

**Resultado**: Pods en namespaces con label `akash.network/tenant: "true"` DEBEN usar gVisor.

### Network Policies

Combinar con NetworkPolicies estrictas:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: akash-tenant-isolation
  namespace: akash-tenants
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}  # Solo pods del mismo namespace
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53  # DNS
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8
        - 172.16.0.0/12
        - 192.168.0.0/16
```

**Resultado**: Tenants aislados entre sí y del cluster interno.

---

## 🧪 TESTING Y VALIDACIÓN

### 1. Validar Instalación de runsc

```bash
runsc --version
# Expected: runsc version release-YYYYMMDD.X

runsc nvproxy list-supported-drivers
# Expected: Lista incluyendo tu driver (535.x.y)
```

### 2. Test Básico sin GPU

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gvisor-test
spec:
  runtimeClassName: gvisor
  containers:
  - name: test
    image: nginx:alpine
    command: ["sh", "-c", "echo 'Hello from gVisor' && sleep 3600"]
```

**Validar**:
```bash
kubectl logs gvisor-test
# Expected: "Hello from gVisor"

kubectl exec gvisor-test -- dmesg
# Expected: gVisor kernel messages (not host kernel)
```

### 3. Test GPU con gVisor

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: gvisor-gpu-test
spec:
  runtimeClassName: gvisor-gpu
  containers:
  - name: cuda-test
    image: nvidia/cuda:12.0.0-base-ubuntu22.04
    command:
    - nvidia-smi
    resources:
      limits:
        nvidia.com/gpu: 1
  restartPolicy: OnFailure
```

**Validar**:
```bash
kubectl logs gvisor-gpu-test
# Expected: nvidia-smi output mostrando RTX 4070
```

### 4. Benchmark Performance

**CPU Overhead Test**:
```bash
# Sin gVisor
kubectl run cpu-bench --image=alpine --restart=Never -- sh -c "time sh -c 'i=0; while [ \$i -lt 1000000 ]; do i=\$((i+1)); done'"

# Con gVisor
kubectl run cpu-bench-gvisor --image=alpine --restart=Never --overrides='{"spec":{"runtimeClassName":"gvisor"}}' -- sh -c "time sh -c 'i=0; while [ \$i -lt 1000000 ]; do i=\$((i+1)); done'"
```

**GPU Benchmark**:
```bash
# PyTorch training con/sin gVisor, medir epoch time
```

**Expected**: <5% diferencia en GPU workloads.

---

## 📋 PLAN DE IMPLEMENTACIÓN

### Fase 0: Pre-requisitos (AHORA)

- [x] **Hardware**: RTX 4070, driver nvidia-driver-535 instalado
- [x] **K3s**: Corriendo con containerd
- [ ] **Validar versión de driver exacta**:
  ```bash
  nvidia-smi | grep "Driver Version"
  # Verificar que esté en lista de runsc nvproxy list-supported-drivers
  ```

### Fase 1: Instalación Base (Ansible Role)

**Crear role**: `roles/gvisor/`

**Tasks**:
1. Detectar arquitectura (x86_64)
2. Descargar runsc + containerd-shim-runsc-v1 (latest release)
3. Validar checksums
4. Instalar binaries en `/usr/local/bin`
5. Configurar `/etc/containerd/runsc-gpu.toml`
6. Crear containerd template `/var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl`
7. Reiniciar K3s
8. Validar que runsc funciona (`runsc --version`)

**Integrar en `site.yaml`** después de `k3s_server` role, antes de `cilium`.

### Fase 2: RuntimeClasses en GitOps (k8s/bootstrap/)

**Manifests**:
- `k8s/bootstrap/runtimeclasses/gvisor.yaml`
- `k8s/bootstrap/runtimeclasses/gvisor-gpu.yaml`

**Aplicar**:
```bash
kubectl apply -f k8s/bootstrap/runtimeclasses/
```

**Validar**:
```bash
kubectl get runtimeclass
# Expected: gvisor, gvisor-gpu, nvidia (existing)
```

### Fase 3: Testing (Manual)

1. Desplegar test pods (sin GPU, con GPU)
2. Validar logs, dmesg, nvidia-smi
3. Benchmark performance
4. Validar overhead < 5%

### Fase 4: Policies (Kyverno)

**Después de Fase 5 del backlog principal** (Kyverno deployment):

1. Crear policy `require-gvisor-akash.yaml`
2. Aplicar a namespace `akash-tenants` (crear si no existe)
3. Validar enforcement (intentar desplegar sin runtimeClassName → reject)

### Fase 5: Integración Akash (Futuro)

**Cuando se configure Akash provider**:

1. Configurar Akash provider manifest para exponer `runtimeClassName` como atributo
2. Clientes pueden solicitar GPU + gVisor
3. Scheduler de Akash asigna a nodo con `gvisor.enabled=true`
4. Deployment automático con `runtimeClassName: gvisor-gpu`

---

## ⚙️ OPTIMIZACIONES BARE-METAL

### 1. Platform Selection

**Usar Systrap** (no ptrace) en config:
```toml
[runsc_config]
platform = "systrap"
```

**Justificación**: Systrap tiene ~50% menos overhead que ptrace.

**Fuente**: [Performance Guide - gVisor](https://gvisor.dev/docs/architecture_guide/performance/)

### 2. Filesystem Overlay

gVisor usa overlay filesystem por default (desde 2023). **No requiere configuración adicional**.

**Beneficio**: Reduce overhead de I/O en filesystem.

**Fuente**: [gVisor improves performance with root filesystem overlay](https://opensource.googleblog.com/2023/04/gvisor-improves-performance-with-root-filesystem-overlay.html)

### 3. Seccomp Optimization

gVisor usa seccomp internamente. **Ya optimizado** en releases recientes.

**Fuente**: [Optimizing seccomp usage in gVisor](https://gvisor.dev/blog/2024/02/01/seccomp/)

### 4. Memory Tuning

**No requiere hugepages** para gVisor (solo para miners sin gVisor).

**Asignar hugepages solo a miners**:
- Actual: 2560Mi (1280 pages) globales
- Target: Asignar dinámicamente según workload

### 5. CPU Pinning

**Separar cores**:
- Cores 0-15: Sistema + gVisor Sentry processes
- Cores 16-27: Miners (sin gVisor, affinity 0x0FFF0000)

**Implementar con cgroups** o `cpuset` en Kubernetes.

### 6. NUMA Awareness

**No crítico** en single-socket i9-13980HX (no NUMA), pero si se añaden nodos multi-socket:

```yaml
# En RuntimeClass
overhead:
  podFixed:
    memory: "200Mi"
    cpu: "100m"
scheduling:
  nodeSelector:
    gvisor.enabled: "true"
  tolerations:
  - key: "numa-zone"
    operator: "Equal"
    value: "0"
```

---

## 🚨 PROBLEMAS CONOCIDOS Y WORKAROUNDS

### 1. NVIDIA Container Runtime Conflict

**Problema**: `nvidia-container-runtime` puede no delegar correctamente a `runsc`.

**Síntoma**: Pods con GPU no inician, error "NVIDIA drivers not found".

**Workaround**: No usar `nvidia-container-runtime`, configurar nvproxy directamente en runsc config.

**Fuente**: [Issue #9368 - gVisor](https://github.com/google/gvisor/issues/9368)

### 2. Driver Version Mismatch

**Problema**: `runsc` no soporta tu versión exacta de driver.

**Síntoma**: Fatal error "unsupported Nvidia driver version X.Y.Z".

**Workaround**:
- Opción A: Actualizar gVisor (`runsc`) a última versión
- Opción B: Downgrade driver NVIDIA a versión soportada
- Opción C: Usar flag `--nvproxy-driver-version` para forzar ABI compatible

**Validar antes**: `runsc nvproxy list-supported-drivers`

### 3. Device File Permissions

**Problema**: `/dev/nvidia*` no accesibles en sandbox.

**Síntoma**: "Permission denied" al ejecutar `nvidia-smi`.

**Workaround**: Asegurar que containerd monta devices correctamente. Verificar containerd config include `device_ownership_from_security_context = true`.

### 4. Performance Degradation en I/O

**Problema**: Workloads con heavy disk I/O (logs, checkpoints) sufren >50% overhead.

**Workaround**:
- Usar volumes ephemeral (emptyDir) cuando sea posible
- Minimizar writes a PVCs
- Usar tmpfs para temporales

### 5. Incompatibilidad con Privileged Pods

**Problema**: gVisor NO soporta `securityContext.privileged: true`.

**Síntoma**: Pod stuck en Pending o CrashLoopBackOff.

**Workaround**: **Miners NUNCA usar gVisor** (requieren privileged para MSR access).

---

## 📐 ARQUITECTURA FINAL

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes API                        │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴──────────────┐
        │                            │
   ┌────▼─────┐              ┌───────▼────────┐
   │ RuntimeClass             │ RuntimeClass    │
   │ gvisor                   │ gvisor-gpu      │
   │ (handler: runsc)         │ (handler: runsc-gpu) │
   └────┬─────┘              └───────┬────────┘
        │                            │
        │                            │
   ┌────▼────────────────────────────▼────────┐
   │         Containerd (K3s embedded)        │
   │  /var/lib/rancher/k3s/agent/etc/...     │
   └────┬─────────────────────┬───────────────┘
        │                     │
   ┌────▼─────┐         ┌─────▼──────────────┐
   │  runsc   │         │  runsc (nvproxy)   │
   │  (CPU)   │         │  (GPU enabled)     │
   └────┬─────┘         └─────┬──────────────┘
        │                     │
        │                ┌────▼──────────────┐
        │                │ NVIDIA Driver     │
        │                │ (host kernel)     │
        │                │ /dev/nvidia*      │
        │                └───────────────────┘
        │
   ┌────▼────────────────────────────────────┐
   │     Host Kernel (Ubuntu 24.04 HWE)      │
   │     ASUS RoG Strix G614JI               │
   │     i9-13980HX + RTX 4070 Laptop        │
   └─────────────────────────────────────────┘
```

**Workload Routing**:

1. **Akash Tenants** (namespace `akash-tenants`):
   - Policy enforcement: MUST use `gvisor` or `gvisor-gpu`
   - Network Policy: Isolated, egress DNS + internet only
   - PriorityClass: `user-workloads` (3000)

2. **Miners** (namespace `production/miners`):
   - RuntimeClass: **NONE** (usa runc default)
   - Privileged: true, hostNetwork: true
   - PriorityClass: `mining-workloads` (-1000, evictable)

3. **Platform Infra** (namespaces `argocd`, `observability`, etc.):
   - Expuestos públicamente: `runtimeClassName: gvisor`
   - Internos: RuntimeClass omitido (runc default)
   - PriorityClass: `platform-*` (1000000 - 10000)

---

## 🎓 RECURSOS Y REFERENCIAS

### Documentación Oficial

- [gVisor User Guide](https://gvisor.dev/docs/user_guide/)
- [GPU Support - gVisor](https://gvisor.dev/docs/user_guide/gpu/)
- [Performance Guide - gVisor](https://gvisor.dev/docs/architecture_guide/performance/)
- [Containerd Quick Start - gVisor](https://gvisor.dev/docs/user_guide/containerd/quick_start/)
- [Kubernetes Quick Start - gVisor](https://gvisor.dev/docs/user_guide/quick_start/kubernetes/)

### Guías de Integración

- [How to install gVisor for K3s (GitHub Gist)](https://gist.github.com/Frichetten/c77ee24b12edd2ab852738fc8221a1f1)
- [Secure k3s with gVisor - devopstales](https://devopstales.github.io/kubernetes/k3s-gvisor/)
- [Securing Kubernetes Workloads with gVisor RuntimeClass (Medium)](https://medium.com/@GiteshWadhwa/securing-kubernetes-workloads-implementing-gvisor-runtime-class-with-containerd-for-enhanced-04f61eb93d9d)

### Blog Posts Técnicos

- [Running Stable Diffusion on GPU with gVisor](https://gvisor.dev/blog/2023/06/20/gpu-pytorch-stable-diffusion/)
- [Running gVisor in Production at Scale in Ant](https://gvisor.dev/blog/2021/12/02/running-gvisor-in-production-at-scale-in-ant/)
- [GPU-based Containers as a Service](https://topofmind.dev/blog/2025/10/21/gpu-based-containers-as-a-service/)

### Issues Relevantes

- [Running runsc with containerd and nvproxy=true · Issue #9368](https://github.com/google/gvisor/issues/9368)
- [Add support for nvidia driver version 535.161.08 · Issue #10605](https://github.com/google/gvisor/issues/10605)
- [nvproxy: Support GPU capability segmentation · Issue #10856](https://github.com/google/gvisor/issues/10856)

### Performance Research

- [Performance Evaluation of Container Runtimes (PDF)](https://www.scitepress.org/Papers/2020/93404/93404.pdf)
- [How Containerization Affects Database Performance](https://kubeblocks.io/blog/does-containerization-affect-the-performance-of-databases)
- [Improving gVisor Memory Subsystem Performance (PDF)](https://xhfu.me/files/ad5e3bbbdb2e7f4dbb5dc19c121e89a9/cse291_project_final_report.pdf)

### Akash Network

- [Akash Provider GPU Resource Enablement](https://akash.network/docs/providers/build-a-cloud-provider/akash-cli/gpu-resource-enablement/)
- [Provider Build With GPU - Akash Guidebook](https://docs.akash.network/other-resources/archived-resources/provider-build-with-gpu)

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Pre-Implementación
- [ ] Validar driver NVIDIA version exacta (`nvidia-smi`)
- [ ] Verificar que driver esté soportado por runsc (`runsc nvproxy list-supported-drivers`)
- [ ] Backup de `/var/lib/rancher/k3s/agent/etc/containerd/` (si existe config custom)

### Ansible Role Development
- [ ] Crear `roles/gvisor/defaults/main.yml` (versión de runsc, flags)
- [ ] Crear `roles/gvisor/tasks/main.yml` (instalación de binaries)
- [ ] Crear `roles/gvisor/templates/config.toml.tmpl.j2` (containerd config)
- [ ] Crear `roles/gvisor/templates/runsc-gpu.toml.j2` (nvproxy config)
- [ ] Añadir role a `site.yaml` (después de k3s_server, antes de cilium)
- [ ] Validar idempotencia del role

### Testing
- [ ] Test básico: Pod nginx con `runtimeClassName: gvisor`
- [ ] Test GPU: Pod cuda con `runtimeClassName: gvisor-gpu`
- [ ] Validar logs: `kubectl logs` muestran output correcto
- [ ] Validar dmesg: `kubectl exec -- dmesg` muestra gVisor kernel (no host)
- [ ] Benchmark: CPU overhead < 5%
- [ ] Benchmark: GPU performance > 95% de nativo

### GitOps Integration
- [ ] Crear manifests en `k8s/bootstrap/runtimeclasses/`
- [ ] Aplicar RuntimeClasses a cluster
- [ ] Validar: `kubectl get runtimeclass`

### Policy Enforcement
- [ ] Crear namespace `akash-tenants` con label `akash.network/tenant: "true"`
- [ ] Desplegar Kyverno policy `require-gvisor-akash.yaml`
- [ ] Test enforcement: Intentar desplegar pod sin runtimeClassName → debe fallar
- [ ] Test bypass: Desplegar en namespace sin label → debe permitir

### Documentation
- [ ] Actualizar `docs/analysis-homelab-vs-blueprint.md` con Fase 0: gVisor
- [ ] Crear runbook: "Troubleshooting gVisor GPU issues"
- [ ] Documentar proceso de actualización de driver NVIDIA (con validación gVisor)

### Production Readiness
- [ ] Monitoring: Añadir metric para contar pods por runtimeClass
- [ ] Alerting: Alert si ningún pod usa gVisor en namespace akash-tenants
- [ ] Logging: Asegurar que logs de runsc van a Loki (cuando se despliegue)

---

## 🔮 CONSIDERACIONES FUTURAS

### Multi-Node

Cuando se añadan nodos:

1. **Label nodes** con `gvisor.enabled=true` solo en nodos con runsc instalado
2. **GPU nodes** adicional label `nvidia.com/gpu.present=true`
3. **Actualizar RuntimeClass** `nodeSelector` para scheduling correcto
4. **Ansible role** debe ejecutarse en todos los nodos

### Driver Updates

**Proceso de actualización de driver NVIDIA**:

1. Check gVisor releases: ¿Última versión soporta driver nuevo?
2. Si NO:
   - Esperar release de gVisor
   - O contribuir ABI definitions a gVisor upstream
3. Si SÍ:
   - Actualizar runsc primero: `ansible-playbook site.yaml --tags gvisor`
   - Validar: `runsc nvproxy list-supported-drivers | grep <new-version>`
   - Actualizar driver NVIDIA: `ansible-playbook site.yaml --tags nvidia`
   - Test: Desplegar pod GPU test
4. En producción: Blue-Green deployment (si multi-node)

### Akash Integration

**Provider Manifest** (cuando se configure Akash):

```yaml
apiVersion: akash.network/v2beta2
kind: Provider
spec:
  # ...
  attributes:
  - key: runtime
    value: gvisor
  - key: runtime-gpu
    value: gvisor-gpu
  - key: gpu-vendor
    value: nvidia
  - key: gpu-model
    value: rtx-4070
  # ...
```

Clientes pueden filtrar providers con `runtime=gvisor-gpu`.

### Advanced Isolation

**Si se requiere aislamiento aún mayor**:

1. **Kata Containers**: VMs ligeras (mayor overhead pero aislamiento VM-level)
2. **Firecracker**: microVMs (usado por AWS Lambda)
3. **gVisor + Kata**: Nested (overkill, pero posible)

**Para este proyecto**: gVisor es suficiente y óptimo (balance seguridad/performance).

---

## 📊 IMPACTO EN BACKLOG PRINCIPAL

### Modificaciones al Backlog

**NUEVA FASE 0** (antes de Fase 1 GitOps):

**🔴 FASE 0: gVisor Sandbox (Bloqueante para Akash)**

**Objetivo**: Habilitar multi-tenancy seguro con GPU support

- [ ] **0.1** Validar driver NVIDIA exacto y compatibilidad con runsc
- [ ] **0.2** Crear Ansible role `gvisor`
  - Instalar runsc + containerd-shim-runsc-v1
  - Configurar containerd template con runtimes `runsc` y `runsc-gpu`
  - Configurar nvproxy en `/etc/containerd/runsc-gpu.toml`
- [ ] **0.3** Integrar role en `site.yaml` (después de k3s_server)
- [ ] **0.4** Crear RuntimeClass manifests (`gvisor`, `gvisor-gpu`)
- [ ] **0.5** Testing exhaustivo
  - Pod test sin GPU
  - Pod test con GPU (CUDA)
  - Benchmark performance (target: <5% overhead)
- [ ] **0.6** Actualizar PriorityClasses (añadir `akash-tenants: 2000`)
- [ ] **0.7** Documentar troubleshooting y driver update process

**Entregable**: Cluster listo para recibir workloads Akash con sandbox GPU

**Duración Estimada**: 3-5 días

---

### Ajustes a Fases Existentes

**Fase 5 (CI/CD & Governance) - Añadir**:

- [ ] **5.10** Kyverno policy: `require-gvisor-akash`
  - Enforce `runtimeClassName: gvisor | gvisor-gpu` en namespaces Akash
  - Validar enforcement con test negativo

**Fase 7 (Hardening) - Añadir**:

- [ ] **7.9** Validar que workloads privileged NO usen gVisor
  - Miners: runtimeClassName omitido (runc default)
  - GPU miners: NO compatible con gVisor (MSR + hostNetwork)

**Fase 8 (Features Avanzadas) - Añadir**:

- [ ] **8.8** Akash Provider Configuration
  - Instalar Akash provider software
  - Configurar provider manifest con runtime attributes
  - Integrar con Akash network
  - Testing: Deploy SDL desde Akash console → validate lands en gvisor-gpu

---

## 🎯 CONCLUSIÓN

**gVisor es CRÍTICO y FACTIBLE** para este proyecto:

✅ **Pros**:
- Overhead < 3% en GPU workloads (mayoría < 1%)
- Aislamiento robusto para multi-tenancy Akash
- GPU support funcional vía nvproxy
- Compatible con K3s + containerd
- Producción-ready (usado por Google, Ant Group)

⚠️ **Contras**:
- Driver version lock (mantenimiento continuo)
- No soporta privileged containers (miners quedan sin sandbox)
- Overhead significativo en I/O (mitigable con emptyDir)

🎯 **Recomendación**: **IMPLEMENTAR en Fase 0** antes de GitOps. Es prerequisito para Akash y no afecta workloads existentes (miners seguirán con runc).

**Next Action**: Validar driver version y comenzar desarrollo de Ansible role `gvisor`.

---

**Última Actualización**: 2026-01-14
**Estado**: Plan aprobado pendiente de implementación
