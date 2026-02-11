# L7 LB 503 Investigation — Hard Data

## Topology

```
k3s-vps (100.108.70.45)                                k3s-master (100.96.136.51)
════════════════════════════════════════                 ════════════════════════════════

┌─────────────────┐                                     ┌──────────────────────┐
│ client3          │                                     │ l7-lb-5bf5fdf64d-    │
│ Pod (VPS)        │                                     │ fdlg8                │
│ 10.0.1.x         │                                     │ Pod (master)         │
└────────┬────────┘                                     │ 10.0.0.194:8080      │
         │                                              └──────────────────────┘
         │ ① HTTP GET                                                ▲
         ▼                                                           │
┌──────────────────────────────────────┐                             │
│ Service: l7-lb                        │                             │
│ Type: NodePort                        │                             │
│ ClusterIP: 10.43.186.172:8080         │                             │
│ NodePort: 31990                       │                             │
│ Annotation: service.cilium.io/        │                             │
│             lb-l7: enabled            │                             │
│                                       │                             │
│ Endpoints (EndpointSlice):            │                             │
│   10.0.0.194:8080                     │                             │
│   nodeName: k3s-master                │                             │
└────────┬─────────────────────────────┘                             │
         │                                                           │
         │ ② annotation lb-l7 activa:                                │
         ▼                                                           │
┌──────────────────────────────────────┐                             │
│ CiliumEnvoyConfig:                    │                             │
│ cilium-envoy-lb-l7-lb                 │                             │
│ (ns: cilium-test-2)                   │                             │
│                                       │                             │
│ Listener: cilium-test-2/l7-lb         │                             │
│   → HttpConnectionManager             │                             │
│   → useRemoteAddress: true            │                             │
│                                       │                             │
│ RouteConfig: domains ["*"]            │                             │
│   prefix "/" → cluster                │                             │
│                                       │                             │
│ Cluster: cilium-test-2/l7-lb          │                             │
│   type: EDS                           │                             │
│   connectTimeout: 5s                  │                             │
└────────┬─────────────────────────────┘                             │
         │                                                           │
         │ ③ EDS resuelve endpoints:                                 │
         ▼                                                           │
┌──────────────────────────────────────┐                             │
│ CiliumEndpoint:                       │                             │
│ l7-lb-5bf5fdf64d-fdlg8               │                             │
│                                       │                             │
│ ip: 10.0.0.194                        │                             │
│ node: 100.96.136.51 (master)          │                             │
│ identity: 29234                       │                             │
│ state: ready                          │                             │
└────────┬─────────────────────────────┘                             │
         │                                                           │
         │ ④ Envoy (VPS) debe conectar                               │
         │    a 10.0.0.194:8080                                      │
         │    en nodo 100.96.136.51                                  │
         │                                                           │
         ▼                                                           │
┌──────────────────────┐                                             │
│ cilium-envoy (VPS)   │                                             │
│ hostNetwork          │                                             │
│ 100.108.70.45        │  ④ connect(10.0.0.194:8080)                │
│ listener :19338      │  cx_connect_fail: incrementa               │
│                      │  tcpdump -i any: 0 paquetes               │
│ resultado: 503  ◄────│  nunca llega ───────────────────────────────┘
└──────────────────────┘
         │
         │ ⑤ 503
         ▼
┌─────────────────┐
│ client3          │
│ recibe 503       │
└─────────────────┘
```

## Kubernetes Resources

### Service l7-lb (cilium-test-2)
- Type: NodePort
- ClusterIP: 10.43.186.172
- Port: 8080 → targetPort: 8080
- NodePort: 31990
- Selector: name=l7-lb
- Annotation: service.cilium.io/lb-l7: enabled

### CiliumEnvoyConfig cilium-envoy-lb-l7-lb (cilium-test-2)
- Owner: Service l7-lb (auto-created by annotation)
- Listener: cilium-test-2/l7-lb (no explicit bind address, assigned 127.0.0.1:19338)
  - HttpConnectionManager with useRemoteAddress: true
  - TLS inspector listener filter
  - internalAddressConfig: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.1/32
- RouteConfig: domains ["*"], prefix "/" → cluster cilium-test-2/l7-lb
- Cluster: type EDS, connectTimeout 5s
  - outlierDetection: consecutiveLocalOriginFailure: 2
  - useDownstreamProtocolConfig with http2ProtocolOptions

### Endpoints/EndpointSlice
- Single endpoint: 10.0.0.194:8080
- nodeName: k3s-master
- ready: true, serving: true

### CiliumEndpoint l7-lb-5bf5fdf64d-fdlg8
- ip: 10.0.0.194
- node: 100.96.136.51 (k3s-master Tailscale IP)
- identity: 29234
- state: ready

### cilium-envoy Service (kube-system)
- Type: ClusterIP (headless, clusterIP: None)
- Port: 9964 (envoy-metrics)
- Endpoints: 100.96.136.51:9964, 100.108.70.45:9964

## Envoy State on VPS (cilium-5bmhf)
- Listener exists: cilium-test-2/l7-lb at 127.0.0.1:19338
- Cluster cilium-test-2/l7-lb:
  - EDS endpoint: 10.0.0.194:8080
  - health_flags: healthy (after restart)
  - cx_connect_fail: increments on each test
  - cx_total = cx_connect_fail (0 successes)
  - rq_success: 0

## Proven Facts
1. `curl` from VPS host to 10.0.0.194:8080 WORKS (via tailscale0, table 52)
2. L7 LB test returns 503
3. `tcpdump -i any host 10.0.0.194` on VPS during L7 LB test: 0 packets captured
4. Envoy cx_connect_fail increments (Envoy attempts connect())
5. No SYN packet appears on ANY interface on VPS
6. Cilium overwrites main table route on restart (10.0.0.0/24 via cilium_host proto kernel)
7. `ip route replace` to tailscale0 did NOT fix the 503

## Key Contradiction
- Envoy reports cx_connect_fail (socket-level failure)
- tcpdump -i any captures 0 packets to 10.0.0.194
- This means the connect() fails BEFORE generating a packet on any network interface

## Cgroup BPF Programs on VPS (root cgroup /sys/fs/cgroup/)
```
ID       AttachType              Name
88464    cgroup_inet4_connect    cil_sock4_connect
88466    cgroup_inet6_connect    cil_sock6_connect
88468    cgroup_inet4_post_bind  cil_sock4_post_bind
88470    cgroup_inet6_post_bind  cil_sock6_post_bind
88472    cgroup_udp4_sendmsg     cil_sock4_sendmsg
88467    cgroup_udp6_sendmsg     cil_sock6_sendmsg
88463    cgroup_udp4_recvmsg     cil_sock4_recvmsg
88471    cgroup_udp6_recvmsg     cil_sock6_recvmsg
88465    cgroup_inet4_getpeername cil_sock4_getpeername
88462    cgroup_inet6_getpeername cil_sock6_getpeername
88469    cgroup_inet_sock_release cil_sock_release
```

- `cil_sock4_connect` (ID 88464) intercepts ALL IPv4 connect() calls on the node
- Attached to root cgroup = affects every process including Envoy
- Program details: 6432B xlated, 3552B jited, uses map_ids 18283,20603,20611,375,937,19,18288,18281,18284,384,940

## Cilium BPF LB Map Entries for l7-lb Service
```
Frontend (0)                          Backend (1)                                      Flags
10.43.186.172:8080/TCP (0)            0.0.0.0:0 (138) (0)                             [ClusterIP, l7-load-balancer] (L7LB Proxy Port: 19338)
10.43.186.172:8080/TCP (1)            10.0.0.194:8080/TCP (138) (1)                   (backend)
100.108.70.45:31990/TCP (0)           0.0.0.0:0 (137) (0)                             [NodePort, l7-load-balancer] (L7LB Proxy Port: 19338)
100.108.70.45:31990/TCP (1)           10.0.0.194:8080/TCP (137) (1)                   (backend)
74.208.250.178:31990/TCP (0)          0.0.0.0:0 (136) (0)                             [NodePort, l7-load-balancer] (L7LB Proxy Port: 19338)
74.208.250.178:31990/TCP (1)          10.0.0.194:8080/TCP (136) (1)                   (backend)
0.0.0.0:31990/TCP (0)                 0.0.0.0:0 (135) (0)                             [NodePort, non-routable, l7-load-balancer] (L7LB Proxy Port: 19338)
0.0.0.0:31990/TCP (1)                 10.0.0.194:8080/TCP (135) (1)                   (backend)
```

- 10.0.0.194 is NOT a frontend in the LB map (only a backend)
- All frontends redirect to L7LB Proxy Port 19338

## Cilium Monitor Drops During L7 LB Test
```
xx drop (Unsupported L3 protocol) flow ... to endpoint 0, ifindex 14, file bpf_lxc.c:2450,
         identity 15094->unknown
```
- identity 15094 = client3 (10.0.1.36, on VPS)
- ifindex 14 = tailscale0
- Multiple drops with same pattern during test
- These are client3's packets being dropped at tailscale0, NOT Envoy's upstream traffic
- Envoy upstream traffic produces NO drop events (never becomes a packet)

## CiliumEndpoints in cilium-test-2
```
NAME                               IP           IDENTITY   NODE
client-7b7877766f-mqb8x            10.0.0.202   31143      100.96.136.51
client2-d56fbd75d-ls9h7            10.0.0.32    48311      100.96.136.51
client3-74887fc475-zv42j           10.0.1.36    15094      100.108.70.45
echo-other-node-7846965945-xvbx4   10.0.1.75    53021      100.108.70.45
echo-same-node-6478bdf47-4p2jl     10.0.0.161   3714       100.96.136.51
l7-lb-5bf5fdf64d-fdlg8             10.0.0.194   29234      100.96.136.51
```

## Conclusion
`cil_sock4_connect` (cgroup BPF) intercepts Envoy's connect(10.0.0.194:8080) at socket level before any packet is generated. This explains why tcpdump sees 0 packets but Envoy reports cx_connect_fail. Next step: investigate cil_sock4_connect source code to understand under what conditions it rejects/fails a connect() to a remote pod IP.
