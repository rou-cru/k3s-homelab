# Miners: XMRig (Unmineable) deployment notes

## Context
Deployment lives in `k8s/miners/unmineable/` and uses the prebuilt image `thechristech/unmineable:latest`. We override the image entrypoint via ConfigMap to control runtime behavior without rebuilding the image.

## Key files
- `k8s/miners/unmineable/deployment.yaml`: Deployment, mounts `/usr/src/mining/entrypoint.sh` from ConfigMap, sets env vars, requests/limits.
- `k8s/miners/unmineable/configmap-script.yaml`: Provides the custom entrypoint script.
- `k8s/miners/unmineable/configmap.yaml`: User-facing env config (pool/coin/worker/threads/affinity).
- `k8s/miners/unmineable/secret.yaml`: Wallet address.

## Why entrypoint override
The upstream image includes `entrypoint.sh` and `config/xmrig.json`. We override only the entrypoint to:
- remove CPU_LIMIT_* logic,
- keep control of pool/coin/wallet via env,
- add explicit thread control (`MINING_THREADS`) and RandomX init threads to match,
- add optional CPU affinity for P‑cores.
We do NOT mount/override `xmrig.json` because it is read-only if mounted from a ConfigMap and upstream uses `sed -i` to replace placeholders.

## Current entrypoint behavior (ConfigMap)
- Accepts `POOL` (and optional fallback to `MINING_POOL`), `COIN`, `REFERRAL_CODE`, `WALLET_ADDRESS`, `WORKER_NAME`.
- If `MINING_THREADS` set, adds `--threads=$MINING_THREADS --randomx-init=$MINING_THREADS`.
- If `CPU_AFFINITY_MASK` set, adds `--cpu-affinity=$CPU_AFFINITY_MASK`.
- Runs XMRig in foreground via `exec`, with either `-c xmrig.json` or CLI params (default path uses CLI params).

## Hasrate improvement findings
Main gain came from:
1) Limiting threads to P‑cores only (avoid E‑cores),
2) Setting explicit thread count via `MINING_THREADS`,
3) Adding CPU affinity via `CPU_AFFINITY_MASK`.

On the i9‑13980HX node, P‑cores are CPUs `0-15`. Using only one thread per P‑core yields:
- `MINING_THREADS=8`
- `CPU_AFFINITY_MASK=0x5555` (CPUs 0,2,4,6,8,10,12,14)

Result: ~5.1–5.2 kH/s with 8 threads (RandomX), notably higher than 12 threads across mixed cores (~2.9–3.0 kH/s).

## Current config values
- `k8s/miners/unmineable/configmap.yaml`
  - `MINING_THREADS: "8"`
  - `CPU_AFFINITY_MASK: "0x5555"`

## Notes on CPU Manager
Attempted to enable `cpuManagerPolicy=static` via k3s; kubelet crashed because reserved CPU resources were not configured. This change was reverted. The affinity mask still works without `static`, but does not guarantee exclusive cores.

## Huge pages & MSR
Managed by Ansible role `common`:
- `vm.nr_hugepages` is set via sysctl (RandomX requirement).
- `msr` kernel module is loaded for RandomX optimizations.

## Runtime validation
Logs should show:
- `Threads manually set to: 8`
- `CPU affinity mask set to: 0x5555`
- `randomx init dataset ... (8 threads)`
- `cpu ... profile * (8 threads)`
- `READY threads 8/8`
- `DONATE 0%`

## Deployment apply (manual)
```
kubectl apply --validate=false \
  -f k8s/miners/unmineable/configmap.yaml \
  -f k8s/miners/unmineable/configmap-script.yaml \
  -f k8s/miners/unmineable/secret.yaml \
  -f k8s/miners/unmineable/deployment.yaml
```
