# Cilium Optimization Changes (2025-12-31)

## Summary
Optimized Cilium CNI configuration for K3s + Tailscale setup, reducing values file from 4011 lines to 202 lines while enabling advanced features.

## Changes Made

### 1. Values File Rewrite
**File**: `roles/cilium/templates/cilium-values.yaml.j2`
- **Before**: 4011 lines (full upstream template with mostly commented options)
- **After**: 202 lines (focused, production-ready configuration)
- **Approach**: Keep only modified/critical values, rely on Helm chart defaults for the rest

### 2. Features Enabled

#### kube-proxy Replacement (CRITICAL)
```yaml
kubeProxyReplacement: "strict"
socketLB:
  enabled: true
```
- Cilium completely replaces kube-proxy for service load balancing
- `strict` mode required for K3s compatibility
- Socket LB accelerates local service access

#### Gateway API
```yaml
gatewayAPI:
  enabled: true
```
- Modern ingress/routing API
- Eliminates need for external Ingress Controllers
- Auto-creates GatewayClass resource
- Manages TLS secrets via cilium-secrets namespace

#### Hubble Observability
```yaml
hubble:
  enabled: true
  metrics:
    enabled: [dns, drop, tcp, flow, icmp, http]
  relay:
    enabled: true
  ui:
    enabled: true
```
- Complete network visibility
- Prometheus-compatible metrics
- Web UI for flow visualization
- Essential for debugging and security monitoring

#### eBPF Optimizations
```yaml
bpf:
  preallocateMaps: true
  distributedLRU:
    enabled: true
  lbMapMax: 131072
```
- `preallocateMaps`: Reduces allocation latency (trades memory for speed)
- `distributedLRU`: Improves multi-core performance significantly
- `lbMapMax`: Doubled from default 65536 for better scalability

#### Bandwidth Manager
```yaml
bandwidthManager:
  enabled: true
  bbr: true
```
- Enables QoS for TCP/UDP workloads
- BBR congestion control for pods (better than CUBIC)

### 3. Tailscale Integration

#### No Conflicts
- **Pod CIDR**: 10.0.0.0/8 (Cilium manages)
- **Node IPs**: 100.x.x.x (Tailscale overlay, not managed by Cilium)
- **API Server**: `k8sServiceHost: "{{ tailscale_ip }}"` correctly configured

#### Routing Mode
- **Selected**: `tunnel` (VXLAN overlay)
- **Rationale**: Compatible with Tailscale overlay, works in any network topology
- **Alternative**: `native` would be faster but requires L2 adjacency

### 4. Features NOT Enabled (By Design)

#### Encryption
```yaml
# encryption.enabled: false
```
- **Reason**: Tailscale already provides WireGuard encryption for node-to-node traffic
- **Impact**: Avoid double encryption overhead

#### L2 Announcements
```yaml
# l2announcements.enabled: false
```
- **Reason**: Tailscale handles overlay routing
- **Impact**: Unnecessary for Tailscale overlay setup

#### BGP Control Plane
```yaml
# bgpControlPlane.enabled: false
```
- **Reason**: Not needed for homelab with Tailscale
- **Future**: Can be enabled for advanced routing scenarios

## Deployment Impact

### Breaking Changes
⚠️ **kube-proxy removal requires careful rollout:**
1. Existing connections may be disrupted during upgrade
2. Recommended: Drain nodes or perform maintenance window
3. Verify with: `kubectl get pods -n kube-system | grep kube-proxy` (should be empty after upgrade)

### New Components
- **hubble-relay**: New deployment (1 replica)
- **hubble-ui**: New deployment (1 replica)
- **Gateway API CRDs**: Auto-installed

### Resource Requirements
- **Increased memory**: ~200-300Mi per node (due to preallocateMaps)
- **New services**: hubble-ui, hubble-relay, gateway-api endpoints

## Verification Steps

### 1. Verify kube-proxy Replacement
```bash
kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement
# Expected: KubeProxyReplacement: Strict [...]
```

### 2. Check Hubble
```bash
kubectl get pods -n kube-system -l k8s-app=hubble-ui
kubectl get pods -n kube-system -l k8s-app=hubble-relay
```

### 3. Access Hubble UI
```bash
kubectl port-forward -n kube-system svc/hubble-ui 12000:80
# Browse to http://localhost:12000
```

### 4. Verify Gateway API
```bash
kubectl get gatewayclass
# Expected: cilium gateway class present
```

### 5. Test Service Connectivity
```bash
kubectl run test-pod --image=nicolaka/netshoot --rm -it -- bash
# Inside pod: curl <service-name>.<namespace>.svc.cluster.local
```

## Performance Expectations

### Expected Improvements
- **Service latency**: 10-30% reduction (kube-proxy replacement + socketLB)
- **Throughput**: 15-25% improvement (eBPF optimizations)
- **Connection setup**: Faster with BBR congestion control

### Monitoring
- Hubble metrics available at `:9965/metrics`
- Grafana dashboards: https://github.com/cilium/cilium/tree/main/examples/kubernetes/addons/prometheus

## Troubleshooting

### If Pods Cannot Reach Services
1. Check Cilium agent status: `kubectl -n kube-system exec ds/cilium -- cilium status`
2. Verify kube-proxy is gone: `kubectl get pods -n kube-system | grep kube-proxy`
3. Check BPF maps: `kubectl -n kube-system exec ds/cilium -- cilium bpf lb list`

### If Hubble UI Not Accessible
1. Check relay: `kubectl logs -n kube-system deploy/hubble-relay`
2. Check UI: `kubectl logs -n kube-system deploy/hubble-ui`
3. Verify certificates: `kubectl get secrets -n kube-system | grep hubble`

### If Gateway API Not Working
1. Verify GatewayClass: `kubectl describe gatewayclass cilium`
2. Check controller logs: `kubectl logs -n kube-system deploy/cilium-operator`

## Next Steps (Optional)

### 1. Enable Prometheus Monitoring
Add to values:
```yaml
prometheus:
  enabled: true
  serviceMonitor:
    enabled: true
```

### 2. Configure L7 Policies
Use CiliumNetworkPolicy for HTTP/gRPC-level policies

### 3. Advanced Gateway API
Deploy Gateway + HTTPRoute resources for ingress

### 4. Host Firewall
Enable if host-level policies needed:
```yaml
hostFirewall:
  enabled: true
```

## References
- Cilium Docs: https://docs.cilium.io/
- Gateway API: https://gateway-api.sigs.k8s.io/
- Hubble: https://docs.cilium.io/en/stable/observability/hubble/
- kube-proxy Replacement: https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/
