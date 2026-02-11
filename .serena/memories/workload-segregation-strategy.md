# Workload Segregation Strategy: Prioridades y Preemption

## Filosofía

El cluster aloja workloads con requisitos de recursos conflictivos:
- **Miners**: Usan 100% de recursos disponibles, baja prioridad, evictables
- **Plataforma**: Infraestructura crítica, alta prioridad, nunca evictables
- **Productivos**: Workloads de negocio, prioridad media, preferidos sobre miners

La estrategia usa PriorityClasses para garantizar que recursos estén disponibles para workloads importantes.

## Priority Classes

### Niveles Definidos

| Clase | Valor | Uso | Preemption |
|-------|-------|-----|------------|
| platform-infrastructure | 1000000 | ArgoCD, Prometheus, cert-manager | Nunca preempted |
| platform-observability | 10000 | Grafana, Loki, Alertmanager | Nunca preempted |
| platform-cicd | 7500 | Argo Workflows | Preempts lower |
| platform-dashboards | 5000 | Policy Reporter, Hubble UI | Preempts lower |
| production-workloads | 3000 | Workloads de negocio | Preempts lower |
| mining-workloads | -1000 | Mineros (CPU/GPU) | Siempre preemptable |

### Principio de Preemption

Cuando un pod de mayor prioridad no puede schedulearse:
1. Scheduler busca pods de menor prioridad que pueden ser evictados
2. Evicta pods de menor prioridad (graceful termination)
3. Schedulea pod de mayor prioridad en nodos liberados

## Categorías de Workloads

### Miners (Evictables)

**Características**:
- Priority: -1000 (más baja posible)
- PreemptionPolicy: PreemptLowerPriority
- Requests y Limits: Los miners son estables en su uso de recursos(buscan el maximo disponible) y
  por tanto se les da la cantidad deseada y no mas

**Comportamiento**:
- Cuando cluster tiene presión: mineros son evictados primero
- Cuando hay recursos libres: mineros consumen todo lo disponible
- Compensan costo eléctrico del servidor y amortizan el costo de hardware cuando no hay cargas rentables

**Tipos**:
- CPU Miner (TNN): Usa solo E-cores, se ha confirmado experimentalmente que 8 E-cores asignados de manera
  explicita es el sweet spot entre rentabilidad y control termico del servidor
- GPU Miner (Rigel): Usa RTX 4070 en nodo master
- Bandwidth Miner (Honeygain): Uso residual de red

### Plataforma (Críticos)

**Características**:
- Priority: 5000 - 1000000
- Nunca evictados por mineros
- Resource quotas garantizadas

**Componentes Estaticos**:
- Cert Manager
- External Secrets Operator
- ArgoCD

**Componentes GitOps**:
- Observability: Prometheus, Loki, Fluent-bit, Pyrra y Grafana
- Security y Gobernance: Kyverno, Falco, Trivy
- IT Services: Argo Workflows, Argo Events
- Akash: todo su stack

### Productivos

**Características**:
- Priority: 3000
- Evictan a mineros pero no a plataforma
- Recursos garantizados cuando necesarios

## Affinity y Anti-Affinity

### Nodos (Futuro)

Plan multi-nodo:
- Master: Solo platform workloads (taint NoSchedule)
- Workers: Productivos
- VPS: Solo gateway/egress y otras cargas de networking

## Escenarios Operativos

### Escenario: Despliegue de Nueva Aplicación

1. Nueva app productiva (priority 3000)
2. Mineros ocupan 8 cores (priority -1000) y app productiva requiere mas cores de lo que hay libre
3. Scheduler evicta minero CPU
4. Nueva app se schedulea
5. Mineros re-schedulean cuando se libere recurso. Se planea un mecanismo de re-schedule con reduccion
   de recurso para asignar solo recursos restantes de manera inteligente.

### Escenario: Presión de Memoria

1. Node alcanza 90% memoria
2. kubelet inicia eviction
3. Primero: pods BestEffort (mineros)
4. Luego: Burstable con uso > requests
5. Nunca: Guaranteed o platform-critical

### Escenario: Mantenimiento de Nodo

1. Drain del nodo
2. Mineros evictados inmediatamente (baja prioridad)
3. Platform workloads migran a otros nodos
4. Productivos migran si hay capacidad
5. Mineros quedan Pending hasta que hay recursos

## Métricas de Eficiencia

### KPIs de Segregación

- **Miner Eviction Time**: < 30 segundos para liberar recursos
- **Platform Availability**: 100% (nunca evictados)
- **Resource Utilization**: > 60% en idle (mineros consumen resto)
- **Preemption Events**: Métrica de cuántas veces ocurre por día

### Costo de Oportunidad

Mineros compensan costo eléctrico:
- Revenue variable:
  - XEL
  - Honeygain(JMPT)
