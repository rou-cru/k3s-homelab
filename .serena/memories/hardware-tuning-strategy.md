# Hardware Tuning Strategy: Optimización Bare-Metal

## Contexto

El cluster corre en hardware bare-metal específico (ASUS RoG), no en cloud. Esto permite y requiere optimizaciones que no aplican a entornos virtualizados.

## Principios de Optimización

### 1. Separación de Recursos

Dividir recursos físicos entre:
- **Sistema**: Cores de performance, uso responsivo
- **Workloads**: Cores eficientes, throughput batch

### 2. Eliminar Overhead de Virtualización

Sin hypervisor:
- Acceso directo a MSRs (Model Specific Registers)
- Control de frecuencia y power limits
- Optimización de NUMA (si aplica)

### 3. Tuning para Workload Mixto

Balance entre:
- Latencia baja (workloads interactivos)
- Throughput alto (mineros)
- Estabilidad térmica (hardware longevity)

## Áreas de Optimización

### CPU

**Frequency Scaling**:
- Governor: schedutil (balance performance/power)
- Max perf pct: Limitado para reducir heat/power
- No turbo: Opcional para thermal throttling prevention

**CPU Pinning**:
- Workloads críticos: Cores específicos (isolation)
- Mineros: Cores eficientes (eficiencia energética)
- IRQs: Cores dedicados para network interrupts

**RAPL (Running Average Power Limit)**:
- Intel-specific power management
- Package power limit: Controla consumo total
- Thermal design power compliance

### Memoria

**Hugepages**:
- Tamaño: 2MB (default) o 1GB
- Allocación estática en boot
- Uso: DPDK, algunos databases, VMs
- Trade-off: Memoria no swappable

**Swappiness**:
- Estado actual: no hay ajuste explícito de `vm.swappiness` en roles.
- Remediación pendiente: definir y aplicar tuning explícito en `roles/common/tasks/system_tuning.yml`.

### Red

**Kernel TCP Stack**:
- BBR congestion control (alto throughput, baja latencia)
- Buffer sizes aumentados para high-bandwidth
- Connection tracking tuning para muchas conexiones

**NIC Offloads**:
- Checksum offload: Reduce CPU para checksums
- TSO/GSO: Segmentación en hardware
- IRQ coalescing: Reduce interrupciones

**Cilium Optimizations**:
- Kube-proxy replacement: eBPF instead of iptables
- Bandwidth manager: BBR for pod traffic
- Host routing: Direct routing when possible

### Almacenamiento

- Estado actual: no hay tuning explícito de scheduler (`mq-deadline`/`none`) ni `noatime` gestionado por roles.
- Remediación pendiente: definir política por tipo de disco y aplicarla vía rol común para evitar drift manual.

### GPU

**NVIDIA Specific**:
- Persistence mode: Mantiene driver cargado (reduce latency)
- Coolbits: Overclocking/fan control
- Power limits: en RTX 4070 Mobile (GPU del master) no es posible ajustar `-pl`; el límite es por diseño de hardware.
- MPS: deseado para mejorar multiplexación, pero requiere más investigación y experimentación con el hardware disponible.

**Container Integration**:
- Container toolkit: GPU access en containers
- Device plugin: Scheduling GPU-aware
- Feature discovery: Node labels para GPU capabilities

## Thermal Management

### Monitoreo

- Temperaturas: CPU, GPU, NVMe, VRM
- Fan speeds: Ajuste automático vs manual
- Power draw: Total y por componente

### Límites de Seguridad

- Throttling térmico: CPU reduce frecuencia si caliente
- Emergency shutdown: Si temperatura crítica
- Fan curves: Balance ruido/enfriamiento

### ASUS RoG Specific

- Thermal policies: Modos de operación (silent/performance/turbo)
- Battery charge threshold: Protección de batería
- Radio block: Desactivar WiFi/Bluetooth no usados

## Power Management

### Estrategia

- On AC power: Performance mode, no suspend
- Battery (raro): Conservative, pero servidor siempre AC

### Tunables

- CPU idle states: C-states (power saving vs latency)
- PCIe ASPM: Power saving para buses
- USB autosuspend: Para puertos no usados

## Trade-offs Considerados

### Performance vs Power

- Miners: Maximizar hashrate por watt
- Plataforma: Responsiveness sobre efficiency
- Global: No exceder capacidad de PSU

### Latency vs Throughput

- Interfaz tailscale0: Low latency para control
- Minería: High throughput para procesamiento
- API K3s: Balance para operaciones mixtas

### Stability vs Optimization

- Conservative: Defaults seguros
- Aggressive: Máximo performance, riesgo de inestabilidad
- Actual: Moderate, validado con pruebas

## Validación de Tuning

### Benchmarks

- CPU: Stress-ng, sysbench
- Red: iperf3, sockperf
- Disk: fio
- GPU: Minería real (hashrate)
- Integral: Workloads productivos reales

### Monitoreo Continuo

- Prometheus: Métricas de hardware
- Alertas: Temperaturas altas, throttling frecuente
- Ajustes iterativos basados en datos

## Consideraciones Multi-Nodo (Futuro)

### Consistencia

- Mismos parámetros en todos los nodos
- Excepciones: Hardware diferente (VPS vs bare-metal)

### Hardware Heterogéneo

- VPS: Optimizaciones mínimas (cloud provider managed)
- Workers: Similar al master
- Master: Máxima optimización (workloads críticos)

### Networking

- Jumbo frames: MTU 9000 entre nodos (si soportado)
- Interrupts: Distribución entre cores
