# Hybrid Network Architecture: Tailscale + Cilium + Gateway API

## Overview

El proyecto utiliza una arquitectura de red híbrida que combina tres tecnologías principales para lograr conectividad segura, rendimiento y exposición de servicios.

## Componentes Principales

### Tailscale (VPN Overlay)

- Propósito: Malla VPN que conecta todos los nodos (master en casa, VPS en cloud, nodos cloud, bare-metal en redes distintas, etc)
- Funciones:
  - Interfaz de red estable (tailscale0)
  - API del cluster accesible remotamente de forma segura y solo por equipos autorizados
  - Anuncio de rutas: Pod CIDRs y Service CIDR para conectividad desde Cilium
  - Cifrado wireguard entre nodos
  - K3s API se binda a la IP Tailscale del master

### Cilium (CNI)

- Propósito: Container Network Interface con funcionalidades avanzadas
- Funciones:
  - Kube-proxy replacement para rendimiento optimizado
  - Hubble para observabilidad de red
  - eBPF para políticas de red y balanceo
- Relación con otros componentes:
  - Coordina con Tailscale para evitar colisiones en el manejo de red, tailscale es "la red" y cilium la abstrae para el cluster
  - Proporciona GatewayClass para Gateway API

### Gateway API(envoy)

- Propósito: Exposición de servicios al exterior
- Funciones:
  - GatewayClass proporcionada por Cilium
  - HTTPRoutes para enrutar tráfico
  - TLS: Cloudflare Origin CA via External Secrets desde OCI Vault
  - Cloudflare Proxy activo para TLS termination público
- Relación con otros componentes:
  - Depende de Cilium para implementación del datapath
  - Cloudflare maneja TLS cliente→edge, Origin CA maneja edge→origin

## Topología de Red

```
[Internet] ←→ [VPS - Tailscale Exit Node] ←→ [Tailscale Mesh] ←→ [Master Node]
                       ↓                                           ↓
                [Anuncia Service CIDR]                    [K3s Control Plane]
                       ↓                                           ↓
                [Gateway API Ingress]                      [Cilium CNI]
```

## Flujos de Tráfico

### Acceso Remoto Administrativo

1. Admin se conecta a Tailscale
2. Accede a API K3s via Tailscale IP (100.x.x.x:6443)
3. kubectl funciona como si estuviera en LAN local

### Acceso a Servicios Públicos

1. Usuario externo accede a servicio.roura.xyz
2. DNS resuelve a VPS (IP pública)
3. VPS recibe tráfico via Gateway API(envoy)
4. Cilium enruta a pod destino
5. Respuesta retorna por mismo path

### Comunicación Pod-to-Pod

1. Pods en diferentes nodos comunican via Cilium sobre tailnet.
2. Nodos están conectados en la tailnet, tráfico cifrado end-to-end desde Tailscale
3. Cilium maneja políticas de red entre pods y capas no gestionadas por Tailscale

## Decisiones de Arquitectura

### Por qué Tailscale + Cilium

- Tailscale: Proporciona conectividad estable entre nodos geográficamente distribuidos sin restricciones de ISP y provee seguridad
- Cilium: Proporciona CNI avanzado con observabilidad y políticas de red, flexible y en el estado del arte de los CNI, compatible con proveedores cloud
- Combinación:
  - Red cerrada para el mundo, transparente para los nodos
  - CNI de alto rendimiento + Tracing de bajo nivel
  - Reduccion de componentes y configuraciones que mantener
  - Red final "plana"
  - eBPF cuando no hay interferencia con tailnet
  - Gateway API nativo

### Eliminación de Túneles Redundantes

La arquitectura original tenía 3 capas de túneles apilados:
1. **WireGuard (Tailscale)** — conectividad entre nodos
2. **Geneve (Cilium)** — encapsulación CNI pod-to-pod
3. **Websocket (K3s)** — apiserver↔kubelet para kubectl exec/logs

El túnel websocket de K3s (egress mode `agent`) es redundante cuando Tailscale ya provee conectividad cifrada entre nodos. Se deshabilitó con `egress-selector-mode: "disabled"` en la config de K3s, eliminando una capa innecesaria que solo traia problemas y complicaba el setup de cilium.

Con esto, `kubectl exec`/`kubectl logs` van directo al kubelet:10250 a través de Tailscale, sin pasar por el websocket de K3s.

### DNS: CoreDNS Custom (Cloudflare + Tailscale MagicDNS)

Se despliega un ConfigMap `coredns-custom` en `kube-system` con:
- **Forward por defecto**: `1.1.1.1` (primario) + `8.8.8.8` (fallback) con `policy sequential`
- **Server block para Tailscale**: `genet-wyvern.ts.net:53` (la tailnet que conecta los nodos) → forward a `100.100.100.100` (MagicDNS)

Esto garantiza que los pods puedan resolver nombres de la tailnet (MagicDNS) y usen Cloudflare DNS como resolver principal (coherente con que los dominios del proyecto están en Cloudflare).

El ConfigMap se aplica automáticamente en el role `k3s_server` después de que el apiserver está listo, antes del bootstrap de Cilium/CoreDNS.

### Rol del VPS

- Actúa como punto de entrada público (único con IP pública estática)
- Anuncia Service CIDR para enrutamiento nodo-nodo, al ser VPS actua como nodo resiliente para garantizar el enrutamiento a service
- Permite la exposicion sin comprometer el interior del cluster. Es el punto donde se separa la "subnet publica" del cluster, contra tailnet que es "subnet privada" del cluster.

## Consideraciones Operativas

- Tailscale debe estar healthy antes de iniciar K3s
- El orden de despliegue es crítico: Tailscale → K3s → CoreDNS custom → Cilium
- Los Pod CIDRs se anuncian dinámicamente post-Cilium para que cada nodo publique su bloque de IP para pods
- El Service CIDR se anuncia solo en el master pero es conocido por todos los nodos en la tailnet
- K3s config: `egress-selector-mode: disabled` (elimina websocket tunnel redundante con Tailscale)
- CoreDNS custom ConfigMap se aplica antes de que CoreDNS inicie para tener siempre la configuracion correcta

## Topología de Red

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INTERNET                                          │
│                    Cliente → argocd.roura.xyz                               │
│                    Cloudflare: argocd.roura.xyz → 74.208.250.178            │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  NODO VPS (k3s-vps)                                                         │
│  └── IP Pública: 74.208.250.178 ◄────── Cliente llega aquí                  │
│       ├── IP Tailscale: 100.x.x.x                                           │
│       │                                                                     │
│       └── Cilium Gateway ←────────── Intenta conectar a backend             │
│              └── Tailscale Interface (tailscale0) ─────┐                    │
│                                                        │                    │
└────────────────────────────────────────────────────────┼────────────────────┘
                                                         │
                                                         │ Túnel WireGuard
                                                         ▼
            ┌────────────────────────────────────────────┼────────────────────────────────┐
            │  NODO ON-PREMISE                           │                                │
            │             Tailscale Interface  ◄─────────┘                                │
            │                ├── IP Tailscale: 100.x.x.x                                  │
            │  Cilium ◄──────┘                                                            │
            │  │                                                                          │
            │  └──→ Workload (10.0.0.46) ←────────── El Gateway necesita llegar aquí      │
            │                                       y volver hasta el cliente en internet │                                │
            └─────────────────────────────────────────────────────────────────────────────┘
```

### Exposicion con Gateway para ArgoCD

```

  ┌─────────────────┐     ┌──────────────────┐      ┌─────────────────┐
  │  public-gateway │────▶│   HTTPS:443      │────▶│  HTTPRoute      │
  │  (Cilium)       │     │   (TLS terminate)│      │  argocd-server  │
  └─────────────────┘     └──────────────────┘      │  (chart)        │
                                                    │  port: 80       │
                                                    └────────┬────────┘
                                                             │
                                ┌─────────────────────────┐──┘
                                │                         │
                                ▼                         ▼
  ┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
  │  public-gateway │────▶│   HTTPS:443      │────▶│  GRPCRoute      │
  │  (Cilium)       │     │   (TLS terminate)│     │  manual         │
  └─────────────────┘     └──────────────────┘     │  port: 8080     │
                                                   └────────┬────────┘
                                                            │
                                ┌───────────────────────────┘
                                │
                                ▼
                      ┌─────────────────┐
                      │  argocd-server  │
                      │  Service        │
                      │  port 80: HTTP  │
                      │  port 8080: gRPC│
                      └────────┬────────┘
                               │
                      ┌────────┴────────┐
                      │  TargetPort 8080│
                      │  (mismo pod)    │
                      └─────────────────┘
```

Y en el caso del CA desde cloudflare

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   OCI Vault     │───▶│ External Secrets │────▶│  Secret:        │
│                 │     │                  │     │  wildcard-      │
│ cloudflare-ca   │     │  Sync cada 24h   │     │  roura-xyz-tls  │
│ -pub / -priv    │     │                  │     │  (cert-manager) │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                              ┌───────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  public-gateway │
                    │  (Cilium)       │
                    │  HTTPS:443      │
                    │  *.roura.xyz    │
                    └─────────────────┘
```
