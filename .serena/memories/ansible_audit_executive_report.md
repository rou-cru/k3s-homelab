# Reporte Ejecutivo: Análisis de Flujo Ansible K3s Homelab

## Resumen Ejecutivo

Análisis completo de la infraestructura Ansible para cluster K3s híbrido (on-premise + VPS). Se evaluaron 18 roles, 2 playbooks principales, y documentación docsible generada.

---

## 1. ORDEN DE EJECUCIÓN GLOBAL

### Flujo Correcto (Single Entry Point)
`site.yaml` importa condicionalmente `site-vps.yaml` al final (línea 301-304), garantizando ejecución secuencial:

```
MASTER (site.yaml) → [completo] → VPS (site-vps.yaml)
```

### Problemas Identificados

| ID | Problema | Severidad |
|----|----------|-----------|
| ORD-2 | Sin `wait_for` explícito en archivo de token antes de join del VPS | MEDIA |
| ORD-3 | Riesgo de race condition si se ejecutan playbooks separados | MEDIA |
| ORD-4 | No hay validación de que el master completó k3s_server antes de VPS | MEDIA |

---

## 2. IDEMPOTENCIA

### Problemas Críticos (6 instancias)

| Archivo | Issue |
|---------|-------|
| `nvidia_gpu/tasks/host.yml:135` | `changed_when: true` incondicional |
| `common/tasks/main.yml:4` | `swapoff -a` siempre reporta changed |
| `k3s_agent/tasks/main.yml:108-130` | Labels y taints siempre reportan changed |
| `k3s_server/tasks/main.yml:178` | kubectl delete con check frágil |
| `cilium/tasks/main.yml:11` | helm repo add con error handling débil |
| `site.yaml:124-137` | kubectl label sin changed_when |

### Problemas Medios (5 instancias)
- Shell/command sin `creates`, `removes`, o `changed_when` apropiado
- Operaciones de archivo sin verificación de estado
- Loops sobre listas vacías por defecto (defensivos pero innecesarios)

---

## 3. OVERENGINEERING

### Problemas Críticos

| ID | Área | Descripción |
|----|------|-------------|
| OVR-3 | Variable explosion | 12 feature flags para features deshabilitados por defecto |

### Patrones Detectados
- **Templates complejos**: cilium-values.yaml.j2 con 115 líneas y lógica operacional mezclada
- **Variables no utilizadas**: ~15 defaults definidos pero nunca referenciados

---

## 4. MALAS PRÁCTICAS

### Seguridad (CRÍTICO)
| ID | Problema |
|----|----------|
| SEC-1 | `secrets.yaml` en plaintext (no vault-encrypted) |
| SEC-2 | Passwords expuestos: SSH, become, Honeygain |
| SEC-3 | `.ansible_vault_pass` existe pero no se usa |

### Código

| ID | Problema | Instancias |
|----|----------|------------|
| BP-3 | `ignore_errors: true` sin justificación | 3 |
| BP-4 | Valores hardcodeados que deberían ser variables | 3 |
| BP-5 | Handlers notificados pero no definidos en rol | 2 |
| BP-6 | `check_mode: no` inconsistente (debería ser `false`) | 2 |
| BP-7 | Task names poco descriptivos | 6 |
| BP-8 | Tags inconsistentes (lista vs string) | Múltiples |

### Arquitectura
- Sin `host_vars/k3s-master.yml` - master depende enteramente de group_vars
- Naming inconsistente de variables: `common_*`, `k3s_*`, `nvidia_gpu_*`, `devtools_*`
- Lógica condicional dispersa en playbooks en lugar de centralizada

---

## 5. CALIDAD DOCUMENTACIÓN DOCSIBLE

### Evaluación: 7.5/10

| Criterio | Evaluación |
|----------|------------|
| **Cobertura** | 100% (17/17 roles con README.md) |
| **Idioma** | Inglés consistente |
| **Concisión** | Variable (common: 778 líneas vs crds_bootstrap: 111 líneas) |
| **Valor genuino** | Alto - descripciones contextuales, no fluff genérico |
| **Actualización** | ~37h desfase entre código y docs |

### Gaps Identificados
| ID | Problema |
|----|----------|
| DOC-1 | 8/17 roles sin `argument_specs.yml` (47%) |
| DOC-2 | No hay tracking de versión en documentación |
| DOC-3 | Docs generados no commiteados a git |

### Roles sin argument_specs
akash, argocd, cert_manager, crds_bootstrap, external_secrets, gvisor, k3s_common, longhorn

---

## MATRIZ DE PRIORIZACIÓN

| Prioridad | Categoría | Items |
|-----------|-----------|-------|
| **P0 - Crítico** | Seguridad | SEC-1, SEC-2 (secrets plaintext) |
| **P1 - Alto** | Idempotencia | 6 instancias `changed_when: true` |
| **P1 - Alto** | Orden | ORD-1 (IP hardcodeada) |
| **P2 - Medio** | Overengineering | OVR-1, OVR-2 (common, developer_tools) |
| **P2 - Medio** | Malas prácticas | BP-1 a BP-5 |
| **P3 - Bajo** | Documentación | DOC-1 (argument_specs faltantes) |

---

## MÉTRICAS CLAVE

```
Roles totales:           18
Roles con idempotencia perfecta: ~40%
Variables en defaults:   400+
Boolean flags:           30+
Tasks con shell/command: 45+
Handlers definidos:      10
ignore_errors usados:    5
```

---

## CONCLUSIÓN

La implementación es **funcional pero con deuda técnica significativa**. Los problemas más urgentes son:

1. **Secrets en plaintext** - Riesgo de seguridad inmediato
2. **Idempotencia rota** - Dificulta CI/CD y re-ejecuciones
3. **IP hardcodeada del master** - Punto único de fallo para el VPS

La documentación docsible está por encima del promedio pero incompleta en argument_specs. El overengineering en `common` y `developer_tools` aumenta la complejidad de mantenimiento sin beneficio proporcional.