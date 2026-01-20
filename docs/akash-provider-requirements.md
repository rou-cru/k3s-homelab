# Akash Provider Requirements Checklist

> Fuentes: [Docs Oficiales](https://akash.network/docs/providers/getting-started/), [Hardware Reqs](https://akash.network/docs/providers/getting-started/hardware-requirements/), [Helm Charts](https://github.com/akash-network/helm-charts), [Community Discussions](https://github.com/orgs/akash-network/discussions)

---

## Requisitos Obligatorios

### Hardware

- [ ] **OS**: Ubuntu 24.04 LTS Server (único oficialmente soportado)
- [ ] **CPU**: x86_64 exclusivamente (ARM no soportado)
- [ ] **CPU mínimo**: 8 cores (reservar 2-4 para K8s overhead)
- [ ] **RAM mínimo**: 16 GB (recomendado 48 GB+)
- [ ] **Storage root**: 100 GB SSD mínimo (500 GB+ recomendado, NVMe preferido)
- [ ] **GPU**: Solo NVIDIA soportado
- [ ] **GPU constraint**: Un solo tipo de GPU por nodo

### Red

- [ ] **Bandwidth**: 100 Mbps simétrico mínimo (1 Gbps+ recomendado)
- [ ] **IP pública estática** o **DDNS** configurado
- [ ] **Dominio** propio para identificación del provider
- [ ] **Puertos abiertos (TCP)**: 80, 443, 8443, 8444
- [ ] **Puertos abiertos (TCP/UDP)**: 30000-32767 (NodePort range)
- [ ] **Latencia**: < 10 ms a hubs principales (preferido)

### Kubernetes

- [ ] **Versión**: 1.33.x (según docs actuales con Kubespray 2.29.1)
- [ ] **CNI**: Calico (único oficialmente soportado por Akash)
- [ ] **Ingress Controller**: NGINX Ingress (hardcoded en hostname-operator)
- [ ] **Storage Class**: Al menos una default configurada

### Operators (Todos requeridos)

- [ ] **akash-hostname-operator**: Mapea Ingress a deployments
- [ ] **akash-inventory-operator**: Discovery de recursos (ahora obligatorio en todos los providers)
- [ ] **operator-inventory-hardware-discovery**: Un pod por worker node

### Wallet

- [ ] **Wallet AKT** creada y configurada
- [ ] **Balance mínimo**: 50 AKT recomendado para empezar
- [ ] **Deposit por bid**: ~5 AKT por lease activo (devuelto al cerrar)

---

## Requisitos Opcionales (Recomendados)

### Hardware

- [ ] **Storage persistente**: Mínimo 4 SSDs o 2 NVMe (para ofrecer persistent storage beta2/beta3)
- [ ] **Multi-node**: Red < 1 ms latencia entre nodos, 10 Gbps+ para storage traffic
- [ ] **GPU high-end**: A100/H100 para workloads ML competitivos

### Features Opcionales

- [ ] **IP Operator** (`akash-ip-operator`): Solo si ofreces IP Leases dedicadas
- [ ] **Puerto 8444**: Requerido si habilitas Feature Discovery gRPC
- [ ] **Persistent Storage**: Capacidad beta2/beta3 (requiere SSDs dedicados uniformes)

### Tuning

- [ ] **Sysctl optimizations**: `net.core.somaxconn=4096`, `fs.file-max=100000`
- [ ] **Withdraw period**: Configurar período de withdraw (default 1h en Helm)

---

## Decisiones de Integración Pendientes

> Marcar con [x] cuando se tome la decisión, documentar resultado.

| Decisión | Opciones | Elegido |
|----------|----------|---------|
| CNI | Calico (oficial) vs Cilium (actual) | [ ] |
| Ingress | NGINX dedicado para Akash vs adaptar Cilium Gateway | [ ] |
| Acceso Público | DDNS vs VPS Gateway vs Tailscale Funnel vs IP estática | [ ] |
| IP Leases | Habilitar vs Ingress-only mode | [ ] |
| Persistent Storage | Ofrecer vs solo ephemeral | [ ] |
| Runtime sandbox | gVisor vs standard containerd | [ ] |

---

## Insights de la Comunidad

### Problemas Comunes Reportados

1. **Wallet drain por bids**: Sistema de create/close bid genera muchas tx fees. Sin GPU leases, providers pequeños pierden dinero (~5 AKT en 2 meses reportado).

2. **Attribute signature errors**: Deployments requieren atributos específicos o attestations firmadas. Si el provider no los tiene, declina el bid automáticamente.

3. **NVIDIA attributes**: Deben listarse correctamente (`nvidia-rtx-4070` formato normalizado) o los bids fallan silenciosamente.

4. **DNS Configuration issues**: Reportados problemas de semanas debuggeando config DNS en provider-console.

### Recomendaciones de la Comunidad

- **Discord #providers**: Canal principal de soporte técnico
- **Provider software**: Última versión v0.10.5 (Nov 2025)
- **Mínimo viable**: GTX 1660+ para GPU, pero RTX 3000/4000+ para ser competitivo
- **ROI realista**: Sin GPU de gama alta, difícil ser rentable como provider pequeño

### Incompatibilidades Conocidas con Nuestro Stack

| Componente Actual | Requerimiento Akash | Impacto |
|-------------------|---------------------|---------|
| Cilium CNI | Calico CNI | Requiere evaluación de compatibilidad |
| Gateway API | NGINX Ingress | hostname-operator hardcoded para NGINX |
| Tailscale overlay | IP pública o DDNS accesible | Requiere gateway/proxy o DDNS apuntando a entrada pública |

---

## Referencias

- [Hardware Requirements](https://akash.network/docs/providers/getting-started/hardware-requirements/)
- [Provider Architecture](https://akash.network/docs/providers/architecture)
- [Helm Charts](https://github.com/akash-network/helm-charts)
- [IP Operator Docs](https://akash.network/docs/providers/architecture/operators/ip/)
- [Provider Discussions](https://github.com/orgs/akash-network/discussions)
- [Community Support](https://github.com/akash-network/support/issues)
