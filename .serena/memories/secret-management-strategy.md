# Secret Management Strategy: External Integration Flow

## Visión General

Los secrets nunca se almacenan en Git. El flujo sigue el patrón:

```
External Secret Store (OCI Vault) → External Secrets Operator → Kubernetes Secrets → Workloads
```

## Componentes del Flujo

### 1. External Secret Store

**Oracle Cloud Infrastructure (OCI) Vault**:
- Backend actual para secrets
- Ubicación: Región específica
- Autenticación: API Key (configurada en archivo local)

### 2. External Secrets Operator (ESO)

**Funciones**:
- Se conecta a backends (OCI Vault)
- Sincroniza secrets externos a Kubernetes Secrets
- Soporta rotación automática
- Soporta push en caso de generacion interna al cluster

**Arquitectura**:
- Controller: Reconcilia ExternalSecrets
- Webhook: Valida CRs
- Cert-manager: TLS para webhook

### 3. ClusterSecretStore

Recurso de configuración que define:
- Qué backend usar (OCI Vault)
- Credenciales de acceso (referenciadas, no inline)
- Alcance: Todo el cluster, se usa para IT interno

### 4. Secret Store

Reservado para uso especifico por namespace en cargas que no son IT interno

### 5. Kubernetes Secret

**Creado automáticamente por Ansible**:
- Tipo: Opaque, TLS, docker-registry, etc.
- Usado como origen de los primeros datos sensibles requeridos, luego ESO toma el control
- Lifecycle: Creados por Ansible a partir de secrets.yaml el cual no se versiona en git

## Consideraciones de Seguridad

### Transit Encryption

- OCI Vault API: TLS 1.3
- Kubernetes API: TLS 1.3
- etcd: Encrypted at rest
