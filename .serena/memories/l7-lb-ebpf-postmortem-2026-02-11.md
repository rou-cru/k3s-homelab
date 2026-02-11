# Post-mortem: L7-LB cross-node failure (eBPF datapath)

Date: 2026-02-11
Scope: namespaces `cilium-test-1` and `cilium-test-2` in 2-node cluster (`k3s-master`, `k3s-vps`).

## Executive summary

A reproducible failure affects `l7-lb` Service/L7 path for traffic originating from pods on `k3s-vps` (`client3`).
Direct PodIP connectivity works, while Service VIP / DNS (`l7-lb`) fails and returns `503` in failing runs. This strongly localizes the issue to Cilium eBPF L7/LB datapath handling, not generic pod-to-pod connectivity.

## Confirmed experimental findings (from pod-based tests)

### Cluster/node baseline
- `k3s-master` and `k3s-vps` are `Ready`.
- `l7-lb` pods are `Running` and `Ready` in both test namespaces.
- `l7-lb` backend endpoints are on `k3s-master` (`10.0.0.174` and `10.0.0.237`).

### Traffic matrix (confirmed)
From `client` / `client2` on master:
- `http://l7-lb:8080` -> OK
- `http://<l7-lb ClusterIP>:8080` -> OK
- `http://<l7-lb PodIP>:8080` -> OK

From `client3` on vps:
- `http://l7-lb:8080` -> FAIL
- `http://<l7-lb ClusterIP>:8080` -> FAIL
- `http://<l7-lb PodIP>:8080` -> OK
- `http://echo-other-node:8080` and `http://echo-same-node:8080` -> OK

NodePort checks:
- NodePort on master can be OK from master-side clients.
- NodePort path involving vps side is failing in the same pattern as Service/L7-LB scenarios.

### HTTP error confirmation
From `client3` in both namespaces:
- `wget -S http://l7-lb:8080/` returned `HTTP/1.1 503 Service Unavailable`.

### Cilium/Envoy behavior observed
On `k3s-vps` Envoy logs during failing requests:
- attempts to connect to upstream backends `10.0.0.174:8080` and `10.0.0.237:8080`
- `stream reset: connection termination`
- `connect timeout`

This matches Service/L7 datapath failure while direct PodIP connectivity remains functional.

## User-confirmed constraints (accepted as facts)

- Root cause is in eBPF handling for failing scenarios.
- In failing scenarios there is no packet egress on interfaces (silent disappearance).
- Enabling tunnel modes (`geneve`/`vxlan`) does not fix this.
- iptables/tailscale-route adjustments do not fix this.
- Other network scenarios continue working normally.

## Correlation with failure report provided by user

Report: `no-unexpected-packet-drops` failed in both `cilium-test-1` and `cilium-test-2`.
Key drop counters:
- `EGRESS / FIB lookup failed` (present on master and vps in report)
- `EGRESS / Unknown L4 protocol` (lower counts)
- `INGRESS / First logical datagram fragment not found` (very high counts)

Correlation assessment:
- `FIB lookup failed` aligns directly with observed cross-node L7 Service failures.
- High fragment-related drops may indicate additional background fragmentation issue; not required to explain the specific TCP L7-LB failure pattern.

## Non-findings / exclusions

- No `NetworkPolicy`, `CiliumNetworkPolicy`, or `CiliumClusterwideNetworkPolicy` explicitly causing the failure in tested namespaces.
- Not a generic DNS issue (direct ClusterIP lookup + PodIP controls performed).
- Not a generic pod-to-pod connectivity issue (PodIP path works).

## Current conclusion

The failure is specific to Cilium eBPF L7/Service datapath for cross-node traffic in this topology. Experimental evidence and drop metrics are consistent with eBPF forwarding/routing decision failures (notably FIB lookup failure), causing silent packet loss and eventual HTTP 503 at L7.

## BPF maps inspection (validated 2026-02-11)

### LB maps consistency (master vs vps)

Inspected on `cilium-42pqh` (k3s-master) and `cilium-vbg22` (k3s-vps):
- `cilium_lb4_services_v2`
- `cilium_lb4_backends_v3`
- `cilium_lb4_reverse_nat`
- `cilium_lb4_reverse_sk`

Validated facts:
- `l7-lb` Service keys are present in both nodes for both test namespaces:
  - `10.43.30.26:8080` and `10.43.196.188:8080` (L7 LB service entries)
  - NodePort entries `31738` and `31969` are present.
- Backends are present in both nodes:
  - `10.0.0.174:8080` and `10.0.0.237:8080` exist in `cilium_lb4_backends_v3`.
- Reverse NAT entries for those services/ports are present in both nodes.
- Map sizes are consistent on both nodes:
  - `cilium_lb4_services_v2`: 76
  - `cilium_lb4_backends_v3`: 14
  - `cilium_lb4_reverse_nat`: 38

Observed asymmetry:
- `cilium_lb4_reverse_sk`:
  - master: 4 entries
  - vps: empty

### IPCache / endpoint resolution

On vps (`cilium-vbg22`), `cilium_ipcache_v2` contains:
- `10.0.0.174/32` and `10.0.0.237/32`
- both with `flags=hastunnel` and tunnel endpoint `100.96.136.51`

This confirms that backend pod IPs are known in datapath metadata and not missing from ipcache.

### Drop metrics confirmation (matches user report)

From `cilium-dbg metrics list`:
- k3s-vps:
  - `cilium_drop_count_total{direction="EGRESS",reason="FIB lookup failed"} = 24`
  - `cilium_drop_count_total{direction="EGRESS",reason="Unknown L4 protocol"} = 43`
  - `cilium_drop_count_total{direction="INGRESS",reason="First logical datagram fragment not found"} = 9236826`
- k3s-master:
  - `cilium_drop_count_total{direction="EGRESS",reason="FIB lookup failed"} = 56`
  - `cilium_drop_count_total{direction="INGRESS",reason="First logical datagram fragment not found"} = 1498521`

### Interpretation update

The failure is not explained by absent/missing LB map programming for `l7-lb`.
Service keys, backends, and revnat entries exist on both nodes.
The strongest remaining signal is runtime datapath handling failure (consistent with `FIB lookup failed`) during specific L7/Service cross-node paths, producing silent packet loss and HTTP 503.

## Preliminar A/B: L7 Service vs plain ClusterIP Service (validated 2026-02-11)

### Objective

Validate whether cross-node path failure is specific to `service.cilium.io/lb-l7: enabled` by comparing against a temporary plain Service targeting the same backend pods.

### Method

In both namespaces (`cilium-test-1`, `cilium-test-2`) a temporary Service was created:
- name: `l7-lb-plain`
- type: `ClusterIP`
- selector: `name=l7-lb`
- port: `8080 -> 8080`

Tested from:
- `deploy/client` (master)
- `deploy/client3` (vps)

Targets tested:
- `l7-lb:8080` (L7 LB Service)
- `l7-lb-plain:8080` (plain Service)
- ClusterIP of each Service
- backend PodIP

Temporary Services were deleted after tests.

### Results (confirmed)

From `client` (master), in both namespaces:
- `l7-lb` -> OK
- `l7-lb-plain` -> OK
- both ClusterIPs -> OK
- PodIP -> OK

From `client3` (vps), in both namespaces:
- `l7-lb` -> FAIL
- `l7-lb` ClusterIP -> FAIL
- `l7-lb-plain` -> OK
- `l7-lb-plain` ClusterIP -> OK
- PodIP -> OK

### Impact on diagnosis

This A/B confirms that cross-node traffic can traverse the current topology when using a normal ClusterIP Service to the same backend pods.
Failure remains specific to the L7 service datapath (`lb-l7` path), not to generic inter-node reachability or backend availability.

## Suggested next diagnostics (not yet executed in this memory)

- Correlate failing single flow with `cilium-dbg monitor --type drop,trace` on both nodes.
- Inspect LB BPF maps around failing requests (`lb4_services`, `lb4_backends`, revnat/affinity).
- Capture identity/policy context for `client3@vps -> l7-lb ClusterIP -> backend@master` to identify exact drop point/hook.
