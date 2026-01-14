# Advanced Observability, KEDA & VPA Implementation Plan

**Fecha**: 2026-01-14
**Contexto**: Métricas de hardware críticas, monitoring de mineros, scale-to-zero inteligente, calibración de recursos
**Hardware**: ASUS RoG Strix G614JI (Intel i9-13980HX 24 cores, NVIDIA RTX 4070 Laptop 8GB, 32GB DDR5, 1TB NVMe)

---

## 🎯 OBJETIVOS

1. **Hardware Metrics**: Temperatura, consumo eléctrico, fan speed, CPU freq → Prometheus sin explosión de cardinalidad
2. **Miner Metrics**: Endpoints específicos de mineros (hashrate, shares, rejected) → Prometheus
3. **KEDA**: Scale-to-zero para liberar recursos, levantamiento inteligente basado en eventos
4. **VPA**: Calibración temporal de resource requests/limits (NO escalamiento dinámico)

---

## 📊 PARTE 1: MÉTRICAS DE HARDWARE

### 1.1 Node Exporter (Hardware Monitoring)

#### Collectors Habilitados

**node_exporter** incluye el **hwmon collector** por default en Linux, exponiendo métricas de sensores físicos via `/sys/class/hwmon`.

**Métricas disponibles**:

| Categoría | Métrica | Descripción |
|-----------|---------|-------------|
| **Temperatura** | `node_hwmon_temp_celsius` | Temperatura en °C por sensor |
| **CPU Frequency** | `node_cpu_scaling_frequency_hertz` | Frecuencia actual escalada |
| | `node_cpu_frequency_min_hertz` | Frecuencia mínima |
| | `node_cpu_frequency_max_hertz` | Frecuencia máxima |
| **Fan Speed** | `node_hwmon_fan_rpm` | Velocidad en RPM |
| | `node_hwmon_pwm_enable` | PWM habilitado (0/1) |
| **Power** | `node_hwmon_power_watt` | Potencia instantánea en W |
| | `node_hwmon_energy_joule_total` | Energía acumulada (counter) |
| **Voltage** | `node_hwmon_voltage_volts` | Voltaje por rail |
| **Current** | `node_hwmon_current_ampere` | Corriente en A |

**Fuentes**:
- [Temperature and hardware monitoring metrics from node exporter - Robust Perception](https://www.robustperception.io/temperature-and-hardware-monitoring-metrics-from-the-node-exporter/)
- [Hardware Monitoring Collector - DeepWiki](https://deepwiki.com/prometheus/node_exporter/3.11-textfile-collector)
- [CPU frequency scaling metrics - Robust Perception](https://www.robustperception.io/cpu-frequency-scaling-metrics-from-the-node-exporter/)

#### Configuración en Helm Values

```yaml
# kube-prometheus-stack/values.yaml
prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
nodeExporter:
  enabled: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 200m
      memory: 128Mi
  # Collectors habilitados por default incluyen hwmon
  # No requiere configuración adicional
```

**Labels relevantes** en métricas hwmon:
- `chip`: Identificador del chip sensor (ej: `coretemp-isa-0000`, `nvme-pci-0400`)
- `sensor`: Nombre del sensor (ej: `temp1`, `fan1`)
- `instance`: Node hostname

#### Ejemplo de Queries PromQL

**Temperatura CPU (cores)**:
```promql
node_hwmon_temp_celsius{chip="coretemp-isa-0000",sensor=~"temp[0-9]+"}
```

**Temperatura NVME**:
```promql
node_hwmon_temp_celsius{chip=~"nvme.*"}
```

**CPU Frequency promedio**:
```promql
avg(node_cpu_scaling_frequency_hertz{instance="master1"})
```

**Fan Speed**:
```promql
node_hwmon_fan_rpm{sensor=~"fan[0-9]+"}
```

---

### 1.2 Power Consumption Monitoring (RAPL + Scaphandre)

#### Intel RAPL (Running Average Power Limit)

**RAPL** expone consumo energético via MSRs (Model Specific Registers) en Intel CPUs desde Sandy Bridge (2011+).

**Acceso**:
- **Kernel powercap interface**: `/sys/class/powercap/intel-rapl/` (no requiere root, Linux 3.13+)
- **perf_event**: Requiere root (Linux 3.14+)
- **Raw MSR**: `/dev/msr` (requiere root)

**Dominios de power**:
- `package-0`: CPU package completo (cores + iGPU + uncore)
- `core`: Solo cores (sin iGPU)
- `uncore`: Memory controller, L3 cache
- `dram`: Memoria RAM (si soportado)

**Fuentes**:
- [Measuring Energy Consumption with RAPL - Medium](https://medium.com/@sagarwal3110/measuring-energy-consumption-using-rapl-in-x86-64-cpus-42beb6205f7a)
- [Energy measurements in Linux - chih's blog](https://blog.chih.me/read-cpu-power-with-RAPL.html)
- [Intel Community - Energy profiling tool](https://community.intel.com/t5/Software-Tuning-Performance/Is-there-an-energy-profiling-tool-to-monitor-CPU-power/m-p/1167468)

#### Scaphandre (RAPL Prometheus Exporter)

**Scaphandre** es un exporter de Prometheus que lee RAPL y expone métricas de consumo energético.

**Instalación**:

```yaml
# scaphandre-deployment.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: scaphandre
  namespace: observability
spec:
  selector:
    matchLabels:
      app: scaphandre
  template:
    metadata:
      labels:
        app: scaphandre
    spec:
      hostNetwork: true
      containers:
      - name: scaphandre
        image: hubblo/scaphandre:latest
        args: ["prometheus"]
        ports:
        - containerPort: 8080
          name: metrics
        securityContext:
          privileged: true  # Requiere acceso a /sys/class/powercap
        volumeMounts:
        - name: powercap
          mountPath: /sys/class/powercap
          readOnly: true
        - name: proc
          mountPath: /proc
          readOnly: true
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
      volumes:
      - name: powercap
        hostPath:
          path: /sys/class/powercap
      - name: proc
        hostPath:
          path: /proc
```

**ServiceMonitor**:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: scaphandre
  namespace: observability
  labels:
    prometheus: kube-prometheus
spec:
  selector:
    matchLabels:
      app: scaphandre
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

**Métricas expuestas**:
- `scaph_host_power_microwatts`: Consumo total del host (contador)
- `scaph_process_power_consumption_microwatts`: Consumo por proceso
- `scaph_socket_power_microwatts`: Consumo por socket CPU

**Conversión a Watts**:
```promql
rate(scaph_host_power_microwatts[5m]) / 1000000
```

**Fuente**: [How to monitor Power Usage of Linux with Prometheus/Grafana - Medium](https://medium.com/@dreams-smoke/how-to-monitor-power-usage-of-your-linux-computing-system-with-prometheus-grafana-f21b9933762)

#### Turbostat (Alternativa)

**turbostat** es una herramienta CLI que lee MSRs y expone power metrics.

**Instalación**:
```bash
sudo apt-get install linux-cpupower
```

**Uso**:
```bash
turbostat --interval 1
```

**Output incluye**:
- `PkgWatt`: Consumo package en Watts (via RAPL)
- `CorWatt`: Consumo cores
- `GFXWatt`: Consumo iGPU (si presente)
- `RAMWatt`: Consumo DRAM (si soportado)

**Textfile Collector** (para exportar a Prometheus):

```bash
# Script en /usr/local/bin/turbostat-exporter.sh
#!/bin/bash
OUTPUT=/var/lib/node_exporter/textfile_collector/turbostat.prom
turbostat --quiet --show PkgWatt --interval 1 --num_iterations 1 | \
  awk 'NR==2 {print "node_power_package_watts " $1}' > $OUTPUT.$$
mv $OUTPUT.$$ $OUTPUT
```

**Cron**:
```cron
* * * * * /usr/local/bin/turbostat-exporter.sh
```

**Fuentes**:
- [turbostat man page - Debian](https://manpages.debian.org/testing/linux-cpupower/turbostat.8.en.html)
- [Quick Sensor Metrics with Textfile Collector - Robust Perception](https://www.robustperception.io/quick-sensor-metrics-with-the-textfile-collector/)

---

### 1.3 GPU Metrics (DCGM Exporter)

#### NVIDIA DCGM Exporter

**DCGM** (Data Center GPU Manager) es el stack oficial de NVIDIA para monitoring de GPUs en producción.

**Despliegue via GPU Operator** (ya instalado en tu cluster):

El **NVIDIA GPU Operator** incluye DCGM exporter por default. Validar que esté corriendo:

```bash
kubectl get pods -n gpu-operator -l app=nvidia-dcgm-exporter
```

Si NO está corriendo, habilitar en values:

```yaml
# nvidia-device-plugin/values.yaml (ya desplegado)
dcgmExporter:
  enabled: true
  repository: nvcr.io/nvidia/k8s/dcgm-exporter
  version: 3.3.0-3.4.0-ubuntu22.04
  env:
  - name: DCGM_EXPORTER_LISTEN
    value: ":9400"
  - name: DCGM_EXPORTER_KUBERNETES
    value: "true"
  resources:
    requests:
      cpu: 50m
      memory: 128Mi
    limits:
      cpu: 200m
      memory: 256Mi
  serviceMonitor:
    enabled: true
    interval: 15s
    additionalLabels:
      prometheus: kube-prometheus
```

**Métricas clave**:

| Métrica | Descripción | Unidad |
|---------|-------------|--------|
| `DCGM_FI_DEV_GPU_TEMP` | Temperatura GPU | °C |
| `DCGM_FI_DEV_MEMORY_TEMP` | Temperatura VRAM | °C |
| `DCGM_FI_DEV_POWER_USAGE` | Consumo instantáneo | W |
| `DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION` | Energía acumulada | mJ |
| `DCGM_FI_DEV_GPU_UTIL` | Utilización GPU | % |
| `DCGM_FI_DEV_MEM_COPY_UTIL` | Utilización memory bandwidth | % |
| `DCGM_FI_DEV_SM_CLOCK` | Frecuencia SM (Streaming Multiprocessor) | MHz |
| `DCGM_FI_DEV_MEM_CLOCK` | Frecuencia VRAM | MHz |
| `DCGM_FI_DEV_PCIE_TX_THROUGHPUT` | PCIe TX bandwidth | KB/s |
| `DCGM_FI_DEV_PCIE_RX_THROUGHPUT` | PCIe RX bandwidth | KB/s |
| `DCGM_FI_DEV_FB_USED` | VRAM usada | MiB |
| `DCGM_FI_DEV_FB_FREE` | VRAM libre | MiB |
| `DCGM_FI_PROF_GR_ENGINE_ACTIVE` | Graphics engine active | % |
| `DCGM_FI_PROF_SM_ACTIVE` | SM active cycles | % |
| `DCGM_FI_PROF_SM_OCCUPANCY` | SM occupancy | % |
| `DCGM_FI_PROF_PCIE_TX_BYTES` | PCIe TX total | bytes |
| `DCGM_FI_PROF_PCIE_RX_BYTES` | PCIe RX total | bytes |

**Labels**:
- `gpu`: GPU index (0, 1, ...)
- `UUID`: UUID único de la GPU
- `device`: Nombre del device (ej: `nvidia0`)
- `modelName`: Modelo GPU (ej: `NVIDIA GeForce RTX 4070 Laptop GPU`)
- `Hostname`: Node hostname

**Ejemplo Queries**:

**Temperatura GPU**:
```promql
DCGM_FI_DEV_GPU_TEMP{gpu="0"}
```

**Consumo Power (rate)**:
```promql
rate(DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION{gpu="0"}[5m]) / 1000
```

**Utilization GPU**:
```promql
DCGM_FI_DEV_GPU_UTIL{gpu="0"}
```

**VRAM Usage %**:
```promql
(DCGM_FI_DEV_FB_USED / (DCGM_FI_DEV_FB_USED + DCGM_FI_DEV_FB_FREE)) * 100
```

**Fuentes**:
- [DCGM Exporter - NVIDIA GitHub](https://github.com/NVIDIA/dcgm-exporter)
- [Tracking GPU Usage in K8s with DCGM - Medium](https://medium.com/@penkow/tracking-gpu-usage-in-k8s-with-prometheus-and-dcgm-a-complete-guide-7c8590809d7c)
- [DCGM-Exporter Documentation - NVIDIA](https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html)
- [NVIDIA GPU Monitoring with DCGM - OpenObserve](https://openobserve.ai/blog/how-to-monitor-nvidia-gpu/)

---

### 1.4 Disk Metrics (smartmontools)

**smartmontools** expone métricas SMART de SSDs/HDDs (temperatura, wear level, errores).

**node_exporter NO incluye collector SMART** por default. Opciones:

#### Opción A: Textfile Collector

**Script**:
```bash
#!/bin/bash
# /usr/local/bin/smartmon-exporter.sh
OUTPUT=/var/lib/node_exporter/textfile_collector/smartmon.prom
smartctl -A /dev/nvme0n1 | awk '/Temperature:/ {print "node_nvme_temperature_celsius{device=\"nvme0n1\"} " $2}' > $OUTPUT.$$
smartctl -A /dev/nvme0n1 | awk '/Available Spare:/ {print "node_nvme_spare_percent{device=\"nvme0n1\"} " $3}' >> $OUTPUT.$$
smartctl -A /dev/nvme0n1 | awk '/Percentage Used:/ {print "node_nvme_wear_percent{device=\"nvme0n1\"} " $3}' >> $OUTPUT.$$
mv $OUTPUT.$$ $OUTPUT
```

**Cron**: Cada 5 minutos

#### Opción B: Prometheus SMART Exporter

Usar [smartmon_exporter](https://github.com/prometheus-community/node-exporter-textfile-collector-scripts) (community script).

**Instalación**:
```bash
curl -o /usr/local/bin/smartmon.sh https://raw.githubusercontent.com/prometheus-community/node-exporter-textfile-collector-scripts/master/smartmon.sh
chmod +x /usr/local/bin/smartmon.sh
```

**Cron**:
```cron
*/5 * * * * /usr/local/bin/smartmon.sh > /var/lib/node_exporter/textfile_collector/smartmon.prom
```

**Métricas expuestas**:
- `smartmon_temperature_celsius_value`
- `smartmon_available_spare_threshold_value`
- `smartmon_percentage_used_value`
- `smartmon_media_errors_value`

**Fuente**: [Prometheus Community node_exporter scripts](https://github.com/prometheus-community/node-exporter-textfile-collector-scripts)

---

## 📊 PARTE 2: MÉTRICAS DE MINEROS

### 2.1 Rigel GPU Miner (API :4067)

#### API Nativa

Rigel expone **HTTP API** en el puerto configurado con `--api-bind`.

**Tu configuración actual** (en entrypoint.sh):
```bash
rigel --api-bind 0.0.0.0:4067
```

Con `hostNetwork: true`, el API es accesible en `http://<node-ip>:4067/`.

**Endpoints**:
- `GET /` - Stats JSON completo

**Ejemplo Response**:
```json
{
  "version": "1.13.3",
  "uptime": 3600,
  "algorithm": "autolykos2",
  "pool": {
    "url": "autolykos.unmineable.com:3333",
    "user": "AVAX:0x...#refcode",
    "status": "connected"
  },
  "devices": [
    {
      "id": 0,
      "name": "NVIDIA GeForce RTX 4070 Laptop GPU",
      "hashrate": 120500000,
      "temperature": 68,
      "power": 95,
      "fan": 65,
      "core_clock": 2400,
      "memory_clock": 8001,
      "accepted_shares": 142,
      "rejected_shares": 2,
      "invalid_shares": 0
    }
  ],
  "hashrate": {
    "total": 120500000,
    "unit": "h/s"
  },
  "shares": {
    "accepted": 142,
    "rejected": 2,
    "invalid": 0
  }
}
```

**Fuentes**:
- [Rigel Miner GitHub](https://github.com/rigelminer/rigel)
- [Rigel Instruction](https://www.miner.download/instructions/rigel)

#### Service para exponer API

Crear Service para que Prometheus pueda scrapear:

```yaml
# rigel-miner-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: rigel-miner
  namespace: miners
  labels:
    app: unmineable-gpu-rigel
spec:
  type: ClusterIP
  clusterIP: None  # Headless service
  ports:
  - name: metrics
    port: 4067
    targetPort: 4067
    protocol: TCP
  selector:
    app: unmineable-gpu-rigel
```

#### Custom Exporter (JSON → Prometheus)

Rigel NO expone formato Prometheus nativo. Necesitas **custom exporter** que parsee JSON y exponga metrics.

**Opción A: json_exporter**

Usar [json_exporter](https://github.com/prometheus-community/json_exporter) con config custom.

**Deployment**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rigel-exporter
  namespace: miners
spec:
  replicas: 1
  selector:
    matchLabels:
      app: rigel-exporter
  template:
    metadata:
      labels:
        app: rigel-exporter
    spec:
      containers:
      - name: json-exporter
        image: prometheuscommunity/json-exporter:latest
        args:
        - --config.file=/config/rigel-exporter.yml
        ports:
        - containerPort: 7979
          name: metrics
        volumeMounts:
        - name: config
          mountPath: /config
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 100m
            memory: 128Mi
      volumes:
      - name: config
        configMap:
          name: rigel-exporter-config
```

**ConfigMap**:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: rigel-exporter-config
  namespace: miners
data:
  rigel-exporter.yml: |
    modules:
      default:
        metrics:
        - name: rigel_uptime_seconds
          path: '{.uptime}'
          help: Miner uptime in seconds
          type: gauge
        - name: rigel_hashrate_total
          path: '{.hashrate.total}'
          help: Total hashrate
          type: gauge
        - name: rigel_shares_accepted_total
          path: '{.shares.accepted}'
          help: Accepted shares
          type: counter
        - name: rigel_shares_rejected_total
          path: '{.shares.rejected}'
          help: Rejected shares
          type: counter
        - name: rigel_shares_invalid_total
          path: '{.shares.invalid}'
          help: Invalid shares
          type: counter
        - name: rigel_device_hashrate
          path: '{.devices[*]}'
          help: Device hashrate
          type: gauge
          labels:
            device_id: '{.id}'
            device_name: '{.name}'
          values:
            hashrate: '{.hashrate}'
        - name: rigel_device_temperature_celsius
          path: '{.devices[*]}'
          help: Device temperature
          type: gauge
          labels:
            device_id: '{.id}'
            device_name: '{.name}'
          values:
            temperature: '{.temperature}'
        - name: rigel_device_power_watts
          path: '{.devices[*]}'
          help: Device power consumption
          type: gauge
          labels:
            device_id: '{.id}'
            device_name: '{.name}'
          values:
            power: '{.power}'
        - name: rigel_device_fan_percent
          path: '{.devices[*]}'
          help: Device fan speed
          type: gauge
          labels:
            device_id: '{.id}'
            device_name: '{.name}'
          values:
            fan: '{.fan}'
        - name: rigel_device_core_clock_mhz
          path: '{.devices[*]}'
          help: Device core clock
          type: gauge
          labels:
            device_id: '{.id}'
            device_name: '{.name}'
          values:
            core_clock: '{.core_clock}'
        - name: rigel_device_mem_clock_mhz
          path: '{.devices[*]}'
          help: Device memory clock
          type: gauge
          labels:
            device_id: '{.id}'
            device_name: '{.name}'
          values:
            memory_clock: '{.memory_clock}'
```

**ServiceMonitor**:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: rigel-exporter
  namespace: miners
  labels:
    prometheus: kube-prometheus
spec:
  selector:
    matchLabels:
      app: rigel-exporter
  endpoints:
  - port: metrics
    interval: 15s
    path: /probe
    params:
      target: ["http://rigel-miner.miners.svc.cluster.local:4067/"]
      module: ["default"]
```

**Opción B: Custom Python Exporter**

Si json_exporter es complejo, escribir exporter simple en Python:

```python
#!/usr/bin/env python3
# rigel-exporter.py
import time
import requests
from prometheus_client import start_http_server, Gauge, Counter

# Métricas
UPTIME = Gauge('rigel_uptime_seconds', 'Miner uptime')
HASHRATE_TOTAL = Gauge('rigel_hashrate_total', 'Total hashrate')
SHARES_ACCEPTED = Counter('rigel_shares_accepted_total', 'Accepted shares')
SHARES_REJECTED = Counter('rigel_shares_rejected_total', 'Rejected shares')
DEVICE_HASHRATE = Gauge('rigel_device_hashrate', 'Device hashrate', ['device_id', 'device_name'])
DEVICE_TEMP = Gauge('rigel_device_temperature_celsius', 'Device temperature', ['device_id', 'device_name'])
DEVICE_POWER = Gauge('rigel_device_power_watts', 'Device power', ['device_id', 'device_name'])
DEVICE_FAN = Gauge('rigel_device_fan_percent', 'Device fan speed', ['device_id', 'device_name'])

RIGEL_URL = "http://rigel-miner.miners.svc.cluster.local:4067/"

def collect():
    try:
        r = requests.get(RIGEL_URL, timeout=5)
        data = r.json()

        UPTIME.set(data['uptime'])
        HASHRATE_TOTAL.set(data['hashrate']['total'])
        SHARES_ACCEPTED.inc(data['shares']['accepted'] - SHARES_ACCEPTED._value._value)
        SHARES_REJECTED.inc(data['shares']['rejected'] - SHARES_REJECTED._value._value)

        for dev in data['devices']:
            labels = [str(dev['id']), dev['name']]
            DEVICE_HASHRATE.labels(*labels).set(dev['hashrate'])
            DEVICE_TEMP.labels(*labels).set(dev['temperature'])
            DEVICE_POWER.labels(*labels).set(dev['power'])
            DEVICE_FAN.labels(*labels).set(dev['fan'])
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    start_http_server(8080)
    while True:
        collect()
        time.sleep(15)
```

**Dockerfile**:
```dockerfile
FROM python:3.11-alpine
RUN pip install prometheus_client requests
COPY rigel-exporter.py /app/
CMD ["python3", "/app/rigel-exporter.py"]
```

**Deployment**: Similar al json_exporter, expone en :8080.

---

### 2.2 TNN CPU Miner (Sin API nativa)

**TNN miner NO expone API HTTP** según el entrypoint analizado.

**Opciones**:

#### Opción A: Parsear Logs (Textfile Collector)

Si TNN imprime hashrate en stdout, parsear logs y generar métricas textfile.

**DaemonSet sidecar** que lee logs del container:

```yaml
# Añadir sidecar en deployment
- name: log-parser
  image: busybox
  command:
  - sh
  - -c
  - |
    while true; do
      # Parsear last line con hashrate
      kubectl logs -n miners unmineable-tnn-deployment-xxx --tail=10 | \
        grep -oP 'hashrate: \K[0-9.]+' | tail -1 | \
        awk '{print "tnn_hashrate " $1}' > /var/lib/node_exporter/textfile_collector/tnn.prom
      sleep 15
    done
  volumeMounts:
  - name: textfile
    mountPath: /var/lib/node_exporter/textfile_collector
```

**Problema**: Acceso a logs desde dentro del pod es complejo. Mejor usar DaemonSet externo con hostPath.

#### Opción B: Fork TNN y Añadir API

Modificar código de TNN miner para exponer HTTP API (requiere desarrollo).

#### Opción C: Omitir métricas detalladas

Si TNN es secundario, omitir métricas específicas y usar solo:
- `kube_pod_status_phase` (up/down)
- `container_cpu_usage_seconds_total`
- `container_memory_working_set_bytes`

**Recomendación**: **Opción C** (omitir) + monitorear solo status via kube-state-metrics.

---

### 2.3 ServiceMonitors Consolidados

**Resumen de ServiceMonitors**:

1. **node-exporter** - ya incluido en kube-prometheus-stack
2. **dcgm-exporter** - ya incluido en GPU operator
3. **scaphandre** - power consumption (crear)
4. **rigel-exporter** - miner metrics (crear custom exporter)

**Namespace labels** para selector:

Todos los ServiceMonitors deben tener:
```yaml
labels:
  prometheus: kube-prometheus
```

Para que el Prometheus del stack los descubra (asumiendo `serviceMonitorSelectorNilUsesHelmValues: false`).

---

## 🚫 PARTE 3: CONTROL DE CARDINALIDAD

### 3.1 Problema de Cardinalidad

**High-cardinality** ocurre cuando una métrica tiene muchos valores únicos de labels, generando millones de time series.

**Ejemplo malo**:
```promql
http_requests_total{path="/api/users/12345", method="GET"}
http_requests_total{path="/api/users/67890", method="GET"}
# Si hay 1M usuarios, 1M time series solo para esta métrica
```

**Límite práctico Prometheus**: **~10M time series** (depende de RAM disponible).

**Fuentes**:
- [How to Manage High Cardinality Metrics - Last9](https://last9.io/blog/how-to-manage-high-cardinality-metrics-in-prometheus/)
- [High Cardinality Metrics Management - Grafana Labs](https://grafana.com/blog/2022/10/20/how-to-manage-high-cardinality-metrics-in-prometheus-and-kubernetes/)

### 3.2 Estrategias de Mitigación

#### 1. Metric Relabeling (Drop labels)

Eliminar labels innecesarios ANTES de almacenar.

**Ejemplo** (en Prometheus config):

```yaml
# kube-prometheus-stack/values.yaml
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
    - job_name: 'node-exporter'
      static_configs:
      - targets: ['localhost:9100']
      metric_relabel_configs:
      # Drop chip label si no es relevante
      - source_labels: [__name__, chip]
        regex: 'node_hwmon_temp_celsius;.*nvme.*'
        action: drop
      # Agregar sensor a "temp_all"
      - source_labels: [__name__, sensor]
        regex: 'node_hwmon_temp_celsius;(temp[0-9]+)'
        target_label: sensor_type
        replacement: 'cpu_core'
        action: replace
```

#### 2. Recording Rules (Pre-aggregate)

Pre-computar queries frecuentes y almacenar como nuevas time series con menos labels.

**Ejemplo**:

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: hardware-metrics-aggregate
  namespace: observability
  labels:
    prometheus: kube-prometheus
spec:
  groups:
  - name: hardware.rules
    interval: 30s
    rules:
    # Temperatura CPU máxima (sin label "sensor")
    - record: node:cpu_temperature_max:celsius
      expr: max(node_hwmon_temp_celsius{chip="coretemp-isa-0000"}) by (instance)

    # Temperatura CPU promedio
    - record: node:cpu_temperature_avg:celsius
      expr: avg(node_hwmon_temp_celsius{chip="coretemp-isa-0000"}) by (instance)

    # Fan speed promedio
    - record: node:fan_speed_avg:rpm
      expr: avg(node_hwmon_fan_rpm) by (instance)

    # CPU frequency promedio
    - record: node:cpu_frequency_avg:hertz
      expr: avg(node_cpu_scaling_frequency_hertz) by (instance)

    # GPU utilization total
    - record: node:gpu_utilization:percent
      expr: DCGM_FI_DEV_GPU_UTIL{gpu="0"}

    # Power consumption rate (Watts)
    - record: node:power_consumption:watts
      expr: rate(scaph_host_power_microwatts[5m]) / 1000000
```

**Beneficio**: Queries en Grafana usan `node:cpu_temperature_max:celsius` en lugar de `max(node_hwmon_temp_celsius{...})`, reduciendo cardinalidad Y latencia.

**Naming convention**: `level:metric:operations`

**Fuentes**:
- [Recording Rules - Prometheus](https://prometheus.io/docs/practices/rules/)
- [Prometheus Recording Rules Guide - Last9](https://last9.io/blog/prometheus-recording-rules/)

#### 3. Limit Label Values

Limitar valores únicos de labels dinámicos.

**Ejemplo**: Para miner hashrate por worker, limitar a top 10 workers:

```yaml
metric_relabel_configs:
- source_labels: [worker_name]
  regex: '^(worker[1-9]|worker10)$'
  action: keep
```

#### 4. Streaming Aggregation

Agregar en tiempo real ANTES de almacenar (requiere VictoriaMetrics o Thanos).

**Prometheus vanilla NO soporta streaming aggregation nativo**.

**Fuente**: [Streaming Aggregation vs Recording Rules - Last9](https://last9.io/blog/streaming-aggregation-vs-recording-rules/)

#### 5. Drop High-Cardinality Metrics

Eliminar métricas completas si no son críticas.

**Ejemplo**:

```yaml
metric_relabel_configs:
- source_labels: [__name__]
  regex: 'node_network_transmit_packets_total|node_network_receive_packets_total'
  action: drop
```

#### 6. Sample Limit

Limitar número de samples por scrape (emergency brake).

```yaml
prometheus:
  prometheusSpec:
    enforcedSampleLimit: 100000  # Max 100k samples per target
```

**Fuente**: [Limitations of Prometheus Labels - SigNoz](https://signoz.io/guides/what-are-the-limitations-of-prometheus-labels/)

### 3.3 Aplicación a este Proyecto

**Métricas con potencial high-cardinality**:

1. **node_hwmon_*** - Múltiples sensores (temp1-temp10, fan1-fan3, etc.)
   - **Mitigación**: Recording rules para max/avg por tipo

2. **DCGM_FI_*** - 50+ métricas por GPU
   - **Mitigación**: Deshabilitar métricas no usadas via DCGM config

3. **rigel_device_*** - Labels dinámicos (device_name con UUID)
   - **Mitigación**: Relabeling para remover UUID, usar solo device_id

**DCGM Config para reducir métricas**:

```yaml
# dcgm-exporter ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: dcgm-exporter-metrics
  namespace: gpu-operator
data:
  metrics.csv: |
    # Only essential metrics
    DCGM_FI_DEV_GPU_TEMP, gauge, GPU temperature (in C).
    DCGM_FI_DEV_POWER_USAGE, gauge, Power draw (in W).
    DCGM_FI_DEV_GPU_UTIL, gauge, GPU utilization (in %).
    DCGM_FI_DEV_MEM_COPY_UTIL, gauge, Memory utilization (in %).
    DCGM_FI_DEV_FB_USED, gauge, Framebuffer memory used (in MiB).
    DCGM_FI_DEV_SM_CLOCK, gauge, SM clock frequency (in MHz).
    DCGM_FI_DEV_MEM_CLOCK, gauge, Memory clock frequency (in MHz).
```

Montar ConfigMap en dcgm-exporter con arg `-f /etc/dcgm-exporter/metrics.csv`.

**Recording Rules esenciales**:

```yaml
- record: cluster:cpu_temp_max:celsius
  expr: max(node_hwmon_temp_celsius{chip="coretemp-isa-0000"})

- record: cluster:gpu_temp:celsius
  expr: DCGM_FI_DEV_GPU_TEMP{gpu="0"}

- record: cluster:power_total:watts
  expr: rate(scaph_host_power_microwatts[5m]) / 1000000 + DCGM_FI_DEV_POWER_USAGE{gpu="0"}

- record: cluster:miner_hashrate_total
  expr: sum(rigel_device_hashrate)
```

**Estimación de cardinalidad**:

| Fuente | Métricas | Labels | Valores/label | Time Series |
|--------|----------|--------|---------------|-------------|
| node-exporter (filtered) | 50 | 3 | 5 | 750 |
| dcgm-exporter (filtered) | 8 | 2 | 2 | 32 |
| scaphandre | 3 | 1 | 1 | 3 |
| rigel-exporter | 10 | 2 | 2 | 40 |
| kube-state-metrics | 100 | 5 | 10 | 50000 |
| **Total** | | | | **~51k** |

**Muy por debajo del límite** (10M). ✅ Seguro.

---

## 🎢 PARTE 4: KEDA (Kubernetes Event-Driven Autoscaling)

### 4.1 ¿Qué es KEDA?

**KEDA** escala workloads de Kubernetes basándose en eventos externos (Prometheus, cron, queues, etc.), incluyendo **scale-to-zero**.

**Diferencias con HPA**:
- HPA: Solo CPU/memoria, NO escala a 0
- KEDA: Cualquier métrica, SÍ escala a 0

**Fuentes**:
- [KEDA Official](https://keda.sh/)
- [Scale to zero with KEDA - Google Cloud](https://cloud.google.com/kubernetes-engine/docs/tutorials/scale-to-zero-using-keda)
- [KEDA Autoscaling - Devtron](https://devtron.ai/blog/introduction-to-kubernetes-event-driven-autoscaling-keda/)

### 4.2 Instalación

**Via Helm**:

```yaml
# Añadir a ansible/post_tasks o crear role keda
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace \
  --set prometheus.metricServer.enabled=true \
  --set prometheus.metricServer.port=9022 \
  --set prometheus.operator.enabled=true
```

**Validar**:
```bash
kubectl get pods -n keda
# Expected: keda-operator, keda-metrics-apiserver
```

### 4.3 ScaledObject Anatomy

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: example-scaledobject
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: target-deployment
  pollingInterval: 30      # Check triggers cada 30s
  cooldownPeriod: 300      # Esperar 5min antes de scale-to-zero
  minReplicaCount: 0       # Puede escalar a 0
  maxReplicaCount: 10
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus:9090
      query: sum(rate(http_requests_total[2m]))
      threshold: '100'
  - type: cron
    metadata:
      timezone: America/Mexico_City
      start: 0 8 * * *      # Scale up a las 8am
      end: 0 22 * * *        # Scale down a las 10pm
      desiredReplicas: "3"
```

**Fuente**: [ScaledObject Spec - KEDA](https://keda.sh/docs/2.16/reference/scaledobject-spec/)

### 4.4 Casos de Uso en k3s-homelab

#### Caso 1: Miners Scale-to-Zero (Off-Peak Hours)

**Objetivo**: Pausar miners de 2am-8am para permitir workloads Akash usar 100% recursos.

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: miner-scheduler
  namespace: miners
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: unmineable-gpu-rigel-deployment
  pollingInterval: 60
  cooldownPeriod: 60       # Scale down rápido
  minReplicaCount: 0
  maxReplicaCount: 1
  triggers:
  - type: cron
    metadata:
      timezone: America/Mexico_City
      start: 0 8 * * *      # 8am: Scale up
      end: 0 2 * * *        # 2am: Scale down
      desiredReplicas: "1"
```

**Comportamiento**:
- 8am: KEDA crea replica (miner starts)
- 2am: KEDA escala a 0 (miner stops, libera GPU)

**Trigger alternativo**: Basado en carga del cluster:

```yaml
triggers:
- type: prometheus
  metadata:
    serverAddress: http://prometheus-kube-prometheus-prometheus.observability:9090
    query: |
      sum(kube_pod_info{namespace="akash-tenants"})
    threshold: '1'      # Si hay ≥1 pod Akash, scale down miner
    activationThreshold: '0'  # Scale up solo si 0 pods Akash
```

**Fuente**: [Prometheus Scaler - KEDA](https://keda.sh/docs/2.17/scalers/prometheus/)

#### Caso 2: Akash Workloads Scale-Up Inteligente

**Objetivo**: Escalar pods Akash cuando hay requests pendientes (via custom metric).

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: akash-tenant-autoscaler
  namespace: akash-tenants
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: akash-workload
  minReplicaCount: 0
  maxReplicaCount: 10
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-kube-prometheus-prometheus.observability:9090
      query: akash_pending_deployments
      threshold: '1'
```

(Requiere que Akash provider exponga métrica `akash_pending_deployments`)

#### Caso 3: Scale on GPU Temperature

**Objetivo**: Scale down miner si GPU > 80°C (protección térmica).

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: thermal-protection
  namespace: miners
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: unmineable-gpu-rigel-deployment
  minReplicaCount: 0
  maxReplicaCount: 1
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus-kube-prometheus-prometheus.observability:9090
      query: DCGM_FI_DEV_GPU_TEMP{gpu="0"}
      threshold: '80'
      activationThreshold: '75'  # Scale up solo si <75°C
  cooldownPeriod: 600  # Esperar 10min antes de reintentar
```

**Comportamiento**:
- GPU temp >80°C: Scale to 0 (stop miner)
- GPU temp <75°C (después de cooldown): Scale up

**Fuente**: [KEDA Autoscaling with Prometheus - Devtron](https://devtron.ai/blog/keda-autoscaling-prometheus/)

### 4.5 Limitaciones KEDA

1. **CPU/Memory triggers NO escalan a 0**:
   - Si usas `type: cpu` o `type: memory`, minReplicaCount debe ser ≥1
   - Workaround: Usar Prometheus trigger con query de CPU

2. **Metrics Server requerido**:
   - K3s lo incluye por default ✅

3. **Polling interval overhead**:
   - Cada ScaledObject hace query cada 30s (default)
   - Con 10 ScaledObjects = 10 queries/30s
   - Bajo impacto en Prometheus

**Fuentes**:
- [CPU Scaler - KEDA](https://keda.sh/docs/2.10/scalers/cpu/)
- [Memory Scaler - KEDA](https://keda.sh/docs/2.17/scalers/memory/)

---

## 📏 PARTE 5: VPA (Vertical Pod Autoscaler)

### 5.1 ¿Qué es VPA?

**VPA** ajusta automáticamente `resources.requests` y `resources.limits` de pods basándose en uso histórico.

**Modos**:
1. **Off**: Solo recomendaciones (NO aplica cambios)
2. **Initial**: Asigna resources solo en creación (NO modifica después)
3. **Auto/Recreate**: Evicta y recrea pods con nuevos resources
4. **InPlaceOrRecreate**: Update in-place si posible (experimental)

**Fuentes**:
- [Vertical Pod Autoscaling - Kubernetes](https://kubernetes.io/docs/concepts/workloads/autoscaling/vertical-pod-autoscale/)
- [VPA GitHub](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [How to Implement VPA - OneUptime](https://oneuptime.com/blog/post/2026-01-06-kubernetes-vpa-vertical-pod-autoscaling/view)

### 5.2 Instalación

```bash
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler
./hack/vpa-up.sh
```

**O via Helm** (community chart):

```bash
helm repo add fairwinds-stable https://charts.fairwinds.com/stable
helm install vpa fairwinds-stable/vpa --namespace vpa --create-namespace \
  --set recommender.enabled=true \
  --set updater.enabled=false \    # Deshabilitamos updater (solo modo Off)
  --set admissionController.enabled=false
```

**Validar**:
```bash
kubectl get pods -n vpa
# Expected: vpa-recommender
```

### 5.3 VPA para Calibración (Modo Off)

**Objetivo**: Recolectar recomendaciones durante 1-2 semanas, luego ajustar manifests manualmente.

**VerticalPodAutoscaler para Miners**:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: miner-cpu-vpa
  namespace: miners
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: unmineable-tnn-deployment
  updatePolicy:
    updateMode: "Off"  # Solo recomendaciones
  resourcePolicy:
    containerPolicies:
    - containerName: unmineable-cpu-tnn
      minAllowed:
        cpu: 1000m
        memory: 512Mi
      maxAllowed:
        cpu: 12000m
        memory: 4Gi
      controlledResources: ["cpu", "memory"]
```

**Para GPU Miner**:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: miner-gpu-vpa
  namespace: miners
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: unmineable-gpu-rigel-deployment
  updatePolicy:
    updateMode: "Off"
  resourcePolicy:
    containerPolicies:
    - containerName: unmineable-gpu-rigel
      minAllowed:
        cpu: 500m
        memory: 512Mi
      maxAllowed:
        cpu: 4000m
        memory: 2Gi
      controlledResources: ["cpu", "memory"]
      # Excluimos GPU resource (VPA no debe tocar limits de GPU)
```

### 5.4 Leer Recomendaciones

```bash
kubectl describe vpa miner-cpu-vpa -n miners
```

**Output**:
```yaml
Status:
  Recommendation:
    Container Recommendations:
      Container Name: unmineable-cpu-tnn
      Lower Bound:
        Cpu:     8000m
        Memory:  2Gi
      Target:
        Cpu:     10000m
        Memory:  2500Mi
      Uncapped Target:
        Cpu:     12000m
        Memory:  3Gi
      Upper Bound:
        Cpu:     12000m
        Memory:  4Gi
```

**Interpretación**:
- **Lower Bound**: Mínimo para no causar throttling
- **Target**: Recomendación óptima (usar este)
- **Uncapped Target**: Sin límites de `maxAllowed`
- **Upper Bound**: Máximo observado

**Aplicar manualmente**:

```yaml
# En deployment
resources:
  requests:
    cpu: 10000m     # De Target
    memory: 2500Mi
  limits:
    cpu: 12000m     # De Upper Bound
    memory: 4Gi
```

### 5.5 Best Practices VPA

1. **NO usar con HPA en mismos resources** (CPU/memory conflict)
   - OK: VPA ajusta CPU, HPA escala por custom metric
   - NO OK: VPA y HPA ambos ajustan CPU

2. **Modo Off para calibración inicial** (1-2 semanas de data)

3. **Aplicar cambios en mantenimiento** (VPA Auto evicta pods)

4. **No aplicar a StatefulSets críticos** (eviction causa downtime)

5. **minAllowed debe ser > 0** para evitar pods unschedulable

**Fuentes**:
- [VPA Best Practices - AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/vertical-pod-autoscaler.html)
- [VPA Stormforge Guide](https://stormforge.io/kubernetes-autoscaling/vertical-pod-autoscaler/)

### 5.6 Duración de Calibración

**Recomendación**: **2 semanas mínimo**.

**Por qué**:
- Capturar variabilidad de carga (días laborales vs fines de semana)
- Miners tienen uso estable, pero workloads Akash varían
- VPA usa histogramas de 8 días para recomendaciones

**Después de calibración**:
1. Aplicar Target recommendations a manifests
2. Commit cambios a Git
3. GitOps sync
4. Eliminar VPA resources (o mantener en Off para monitoring continuo)

---

## 📋 PARTE 6: PLAN DE IMPLEMENTACIÓN

### Fase 2-Enhanced: Observabilidad Avanzada (Post-Prometheus Stack)

**Pre-requisito**: Fase 2 original completada (kube-prometheus-stack desplegado)

#### 2-E.1 Hardware Metrics

- [ ] **Validar node-exporter hwmon**
  ```bash
  kubectl exec -n observability node-exporter-xxx -- curl localhost:9100/metrics | grep node_hwmon
  # Expected: Métricas de temp, fan, power
  ```

- [ ] **Instalar lm-sensors en host** (si no detecta sensores)
  ```bash
  sudo apt-get install lm-sensors
  sudo sensors-detect --auto
  sudo systemctl restart lm-sensors
  ```

- [ ] **Desplegar Scaphandre (power monitoring)**
  - Crear DaemonSet
  - Crear Service
  - Crear ServiceMonitor
  - Validar métricas: `scaph_host_power_microwatts`

- [ ] **Validar DCGM Exporter**
  ```bash
  kubectl get pods -n gpu-operator -l app=nvidia-dcgm-exporter
  kubectl logs -n gpu-operator nvidia-dcgm-exporter-xxx
  # Verificar que expone :9400/metrics
  ```

- [ ] **Configurar DCGM metrics whitelist** (reducir cardinalidad)
  - Crear ConfigMap con metrics.csv filtered
  - Restart dcgm-exporter pods

- [ ] **Crear Recording Rules para hardware**
  - PrometheusRule `hardware-metrics-aggregate`
  - Reglas: cpu_temp_max, gpu_temp, power_total, fan_speed_avg
  - Validar en Prometheus UI

#### 2-E.2 Miner Metrics

- [ ] **Rigel Miner Exporter**
  - **Opción A**: Desplegar json_exporter con ConfigMap
  - **Opción B**: Build custom Python exporter (Dockerfile)
  - Crear Service `rigel-miner` (ClusterIP None)
  - Crear ServiceMonitor
  - Validar query: `rigel_hashrate_total`

- [ ] **TNN Miner**: Decidir estrategia
  - Si omitir: Documentar decisión
  - Si parsear logs: Implementar sidecar
  - Si fork: Planificar desarrollo (fuera de scope actual)

#### 2-E.3 Cardinalidad Control

- [ ] **Audit current cardinality**
  ```promql
  sum(count by (__name__)({__name__=~".+"}))
  # Contar time series actuales
  ```

- [ ] **Aplicar metric relabeling** si >100k series
  - Editar kube-prometheus-stack values
  - Drop labels innecesarios (chip UUIDs, etc.)

- [ ] **Crear Recording Rules** (obligatorio)
  - PrometheusRule en `k8s/observability/prometheus-rules/`
  - GitOps sync

- [ ] **Monitorear cardinalidad** con dashboard
  - Grafana panel: `scrape_samples_scraped` by job
  - Alert si >500k series

#### 2-E.4 Dashboards

- [ ] **Crear Dashboard "Hardware Overview"**
  - CPU temp (max, avg, per-core)
  - GPU temp, power, utilization
  - Fan speeds
  - Power consumption total (CPU + GPU)
  - CPU frequency scaling

- [ ] **Crear Dashboard "Miners"**
  - Hashrate (Rigel GPU, TNN CPU)
  - Shares (accepted, rejected, invalid)
  - Earnings estimate (manual calculation)
  - Uptime

- [ ] **Crear Dashboard "Cardinalidad"**
  - Time series count by job
  - Scrape duration
  - Sample count

**Entregable Fase 2-E**: Métricas de hardware + miners en Prometheus, dashboards funcionales, cardinalidad controlada.

---

### Fase 6-Enhanced: KEDA & VPA (Post-Logging)

**Pre-requisito**: Fase 6 original completada (Loki, Fluent-Bit, SLOs)

#### 6-E.1 KEDA Installation

- [ ] **Instalar KEDA via Helm**
  ```bash
  helm install keda kedacore/keda --namespace keda --create-namespace
  ```

- [ ] **Validar KEDA pods**
  ```bash
  kubectl get pods -n keda
  # keda-operator, keda-metrics-apiserver
  ```

- [ ] **Validar External Metrics API**
  ```bash
  kubectl get apiservices | grep external.metrics
  # Should show v1beta1.external.metrics.k8s.io
  ```

#### 6-E.2 KEDA ScaledObjects

- [ ] **ScaledObject: Miner Scheduler (Cron)**
  - `k8s/production/miners/keda-miner-scheduler.yaml`
  - Cron trigger: 8am scale up, 2am scale down
  - Target: `unmineable-gpu-rigel-deployment`
  - Test: Cambiar cron a "+5 minutes" y validar scale

- [ ] **ScaledObject: Thermal Protection (Prometheus)**
  - `k8s/production/miners/keda-thermal-protection.yaml`
  - Trigger: `DCGM_FI_DEV_GPU_TEMP > 80`
  - Scale to 0 si excede, scale up si <75°C
  - Test: `stress-ng` para simular alta temp

- [ ] **ScaledObject: Akash Workload (Custom Metric)**
  - `k8s/akash-tenants/keda-akash-scaler.yaml`
  - Trigger: `akash_pending_deployments > 0` (cuando disponible)
  - Scale 0→10 basado en demanda

- [ ] **Monitorear KEDA metrics**
  ```bash
  kubectl get scaledobject -A
  kubectl describe scaledobject miner-scheduler -n miners
  # Verificar "Active: True/False"
  ```

#### 6-E.3 VPA Installation

- [ ] **Instalar VPA (solo Recommender)**
  ```bash
  helm install vpa fairwinds-stable/vpa --namespace vpa --create-namespace \
    --set recommender.enabled=true \
    --set updater.enabled=false \
    --set admissionController.enabled=false
  ```

- [ ] **Validar VPA pod**
  ```bash
  kubectl get pods -n vpa
  # vpa-recommender
  ```

#### 6-E.4 VPA Resources (Modo Off)

- [ ] **VPA: CPU Miner**
  - `k8s/production/miners/vpa-cpu-miner.yaml`
  - updateMode: Off
  - minAllowed: 1 CPU / 512Mi
  - maxAllowed: 12 CPU / 4Gi

- [ ] **VPA: GPU Miner**
  - `k8s/production/miners/vpa-gpu-miner.yaml`
  - updateMode: Off
  - minAllowed: 500m / 512Mi
  - maxAllowed: 4 CPU / 2Gi
  - Excluir `nvidia.com/gpu` de controlledResources

- [ ] **VPA: Platform Components** (opcional)
  - ArgoCD server, Prometheus, Grafana
  - Solo si resources están muy sobredimensionados

#### 6-E.5 Calibración (2 semanas)

- [ ] **Semana 1**: Recolectar data
  - No tocar deployments
  - Dejar miners corriendo 24/7

- [ ] **Semana 2**: Validar variabilidad
  - Introducir workloads Akash (si posible)
  - Observar cambios en recomendaciones

- [ ] **Fin Semana 2**: Leer recomendaciones
  ```bash
  kubectl describe vpa -n miners
  # Anotar Target recommendations
  ```

- [ ] **Aplicar calibraciones a manifests**
  - Editar `k8s/production/miners/*/deployment.yaml`
  - Ajustar requests/limits según VPA Target
  - Commit + GitOps sync

- [ ] **Eliminar VPA resources** (o mantener en Off)
  - Decisión: Mantener para monitoring continuo vs limpiar

**Entregable Fase 6-E**: KEDA scale-to-zero funcional, VPA calibraciones aplicadas, miners optimizados.

---

## 🎯 RESUMEN DE COMPONENTES

| Componente | Propósito | Puerto | Namespace | ServiceMonitor |
|------------|-----------|--------|-----------|----------------|
| **node-exporter** | Hardware metrics (temp, fan, CPU freq) | 9100 | observability | ✅ (incluido) |
| **dcgm-exporter** | GPU metrics (temp, power, utilization) | 9400 | gpu-operator | ✅ (incluido) |
| **scaphandre** | Power consumption (RAPL) | 8080 | observability | ⚠️ Crear |
| **rigel-exporter** | Miner hashrate, shares, device stats | 8080 | miners | ⚠️ Crear |
| **KEDA** | Scale-to-zero + event-driven autoscaling | - | keda | N/A |
| **VPA** | Resource recommendations (calibración) | - | vpa | N/A |

---

## 📚 REFERENCIAS COMPLETAS

### Hardware Monitoring
- [Temperature and hardware monitoring - Robust Perception](https://www.robustperception.io/temperature-and-hardware-monitoring-metrics-from-the-node-exporter/)
- [CPU frequency scaling metrics - Robust Perception](https://www.robustperception.io/cpu-frequency-scaling-metrics-from-the-node-exporter/)
- [Hardware Monitoring Collector - DeepWiki](https://deepwiki.com/prometheus/node_exporter/3.11-textfile-collector)
- [Sensor Exporter GitHub](https://github.com/ncabatoff/sensor-exporter)

### GPU Monitoring
- [DCGM Exporter - NVIDIA GitHub](https://github.com/NVIDIA/dcgm-exporter)
- [Tracking GPU Usage in K8s with DCGM - Medium](https://medium.com/@penkow/tracking-gpu-usage-in-k8s-with-prometheus-and-dcgm-a-complete-guide-7c8590809d7c)
- [DCGM-Exporter Documentation - NVIDIA](https://docs.nvidia.com/datacenter/dcgm/latest/gpu-telemetry/dcgm-exporter.html)
- [NVIDIA GPU Monitoring with DCGM - OpenObserve](https://openobserve.ai/blog/how-to-monitor-nvidia-gpu/)

### Power Monitoring
- [Measuring Energy with RAPL - Medium](https://medium.com/@sagarwal3110/measuring-energy-consumption-using-rapl-in-x86-64-cpus-42beb6205f7a)
- [Energy measurements in Linux - chih's blog](https://blog.chih.me/read-cpu-power-with-RAPL.html)
- [Power Usage Monitoring with Prometheus - Medium](https://medium.com/@dreams-smoke/how-to-monitor-power-usage-of-your-linux-computing-system-with-prometheus-grafana-f21b9933762)
- [Turbostat man page](https://manpages.debian.org/testing/linux-cpupower/turbostat.8.en.html)

### Miner Monitoring
- [Rigel Miner GitHub](https://github.com/rigelminer/rigel)
- [XMRig Monitoring GitHub](https://github.com/leonardochaia/xmrig-monitoring)
- [XMRig HTTP API](https://xmrig.com/docs/miner/api)
- [Prometheus Mining Exporter](https://github.com/platofff/prometheus-mining)

### Cardinality Management
- [High Cardinality Metrics - Last9](https://last9.io/blog/how-to-manage-high-cardinality-metrics-in-prometheus/)
- [High Cardinality - Grafana Labs](https://grafana.com/blog/2022/10/20/how-to-manage-high-cardinality-metrics-in-prometheus-and-kubernetes/)
- [Prometheus Recording Rules](https://prometheus.io/docs/practices/rules/)
- [Recording Rules Guide - Last9](https://last9.io/blog/prometheus-recording-rules/)
- [Streaming Aggregation vs Recording Rules](https://last9.io/blog/streaming-aggregation-vs-recording-rules/)
- [Prometheus Labels Limitations - SigNoz](https://signoz.io/guides/what-are-the-limitations-of-prometheus-labels/)

### ServiceMonitors
- [Using Service Monitors - Observability for K8s](https://observability.thomasriley.co.uk/prometheus/configuring-prometheus/using-service-monitors/)
- [ServiceMonitors and PodMonitors - Rancher](https://ranchermanager.docs.rancher.com/reference-guides/monitoring-v2-configuration/servicemonitors-and-podmonitors/)
- [Service Discovery Guide - Medium](https://medium.com/@helia.barroso/a-guide-to-service-discovery-with-prometheus-operator-how-to-use-pod-monitor-service-monitor-6a7e4e27b303)

### KEDA
- [KEDA Official](https://keda.sh/)
- [Scale to zero with KEDA - Google Cloud](https://cloud.google.com/kubernetes-engine/docs/tutorials/scale-to-zero-using-keda)
- [ScaledObject Specification](https://keda.sh/docs/2.16/reference/scaledobject-spec/)
- [Prometheus Scaler - KEDA](https://keda.sh/docs/2.17/scalers/prometheus/)
- [KEDA Autoscaling - Devtron](https://devtron.ai/blog/keda-autoscaling-prometheus/)
- [CPU Scaler - KEDA](https://keda.sh/docs/2.10/scalers/cpu/)
- [Memory Scaler - KEDA](https://keda.sh/docs/2.17/scalers/memory/)

### VPA
- [Vertical Pod Autoscaling - Kubernetes](https://kubernetes.io/docs/concepts/workloads/autoscaling/vertical-pod-autoscale/)
- [VPA GitHub](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler)
- [How to Implement VPA - OneUptime](https://oneuptime.com/blog/post/2026-01-06-kubernetes-vpa-vertical-pod-autoscaling/view)
- [VPA - AWS EKS](https://docs.aws.amazon.com/eks/latest/userguide/vertical-pod-autoscaler.html)
- [VPA - Stormforge](https://stormforge.io/kubernetes-autoscaling/vertical-pod-autoscaler/)

---

**Última Actualización**: 2026-01-14
**Estado**: Plan completo pendiente de validación e implementación
