# Miners: Unmineable Deployments

## CPU Mining (XMRig)

**Location:** `k8s/miners/unmineable/`

Uses `thechristech/unmineable:latest` image with custom entrypoint override.

### Key files
- `deployment.yaml`: CPU mining with hugepages, privileged mode
- `configmap-script.yaml`: Custom entrypoint script
- `configmap.yaml`: Pool/coin/worker/threads/affinity config
- `secret.yaml`: Wallet address

### Configuration
- **Pool:** `rx.unmineable.com:3333` (RandomX)
- **Coin:** BNB
- **Wallet:** `0x57d893d8323CfB88ea133F4c4f5e3A2872Bf4f50`
- **Worker:** `home-miner`
- **Referral:** `18ps-7t5s`
- **Threads:** 8 (P-cores only on i9-13980HX)
- **CPU Affinity:** `0x5555` (CPUs 0,2,4,6,8,10,12,14)
- **Hashrate:** ~5.1-5.2 kH/s

### Resources
```yaml
requests:
  cpu: "8000m"
  memory: "3Gi"
  hugepages-2Mi: "2560Mi"
limits:
  cpu: "8000m"
  memory: "3Gi"
  hugepages-2Mi: "2560Mi"
```

### Volumes
- `/dev/cpu` - MSR module access for RandomX
- hugepages (HugePages-2Mi) - RandomX requirement

---

## GPU Mining (T-Rex)

**Location:** `k8s/miners/unmineable-gpu/`

Uses `nvidia/cuda:12.2.0-runtime-ubuntu22.04` base image, downloads T-Rex dynamically.

### Key files
- `deployment.yaml`: GPU mining with nvidia runtime
- `configmap-script.yaml`: T-Rex download + launch script
- `configmap.yaml`: Pool/coin/worker config
- `secret.yaml`: Wallet address (same as CPU)

### Configuration
- **Pool:** `autolykos.unmineable.com:3333` (Autolykos2/ERGO)
- **Coin:** BNB
- **Wallet:** `0x57d893d8323CfB88ea133F4c4f5e3A2872Bf4f50`
- **Worker:** `k8s-gpu`
- **Referral:** `18ps-7t5s`
- **T-Rex Version:** 0.26.8
- **Hashrate:** ~75.26 MH/s
- **Temperature:** 51-62°C
- **Power:** 60-87W
- **Efficiency:** 1.19-1.23 MH/W

### Resources
```yaml
resources:
  limits:
    nvidia.com/gpu: "1"
```

### Pod Spec Requirements
```yaml
runtimeClassName: nvidia
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: nvidia.com/gpu.present
          operator: In
          values: ["true"]
      - matchExpressions:
        - key: feature.node.kubernetes.io/pci-10de.present
          operator: In
          values: ["true"]
```

### Environment Variables
```yaml
env:
  - name: NVIDIA_VISIBLE_DEVICES
    value: "all"
  - name: NVIDIA_DRIVER_CAPABILITIES
    value: "all"
```

### T-Rex Entrypoint Logic
1. Downloads T-Rex v0.26.8 from GitHub releases
2. Extracts to `/tmp/trex/`
3. Launches with Unmineable format: `COIN:WALLET.WORKER#REFERRAL`
4. API server on `0.0.0.0:4067`

### T-Rex Command
```bash
exec /tmp/trex/t-rex \
  -a autolykos2 \
  -o stratum+tcp://autolykos.unmineable.com:3333 \
  -u "BNB:0x57d893d8323CfB88ea133F4c4f5e3A2872Bf4f50.k8s-gpu#18ps-7t5s" \
  -p x \
  --api-bind-http 0.0.0.0:4067 \
  --no-watchdog
```

---

## Why T-Rex Instead of lolMiner

**lolMiner issue:** Crashed with "Unrecoverable memory error by GPU 0" on RTX 4070 Laptop GPU despite connecting successfully.

**T-Rex advantages:**
- More stable for Autolykos2 on RTX 4070
- Better memory management in containers
- Excellent performance (75+ MH/s)
- Low power consumption (~60-87W)
- Built-in API server
- DevFee: 2%

---

## Deployment Status

```bash
$ kubectl get pods -n miners
NAME                              READY   STATUS    RESTARTS   AGE
honeygain-7f5cfdf6dc-hrnzl        1/1     Running   0          81m
unmineable-6b5fc6879c-4gvwk       1/1     Running   0          83m  # CPU XMRig
unmineable-gpu-7b44495787-pklfc   1/1     Running   0          3m   # GPU T-Rex
```

**nicehash deployment scaled to 0** to free GPU for Unmineable.

---

## Apply Commands

### CPU (XMRig)
```bash
kubectl apply -f k8s/miners/unmineable/configmap.yaml \
              -f k8s/miners/unmineable/configmap-script.yaml \
              -f k8s/miners/unmineable/secret.yaml \
              -f k8s/miners/unmineable/deployment.yaml
```

### GPU (T-Rex)
```bash
kubectl apply -f k8s/miners/unmineable-gpu/configmap.yaml \
              -f k8s/miners/unmineable-gpu/secret.yaml \
              -f k8s/miners/unmineable-gpu/configmap-script.yaml \
              -f k8s/miners/unmineable-gpu/deployment.yaml
```

---

## Monitoring

### Logs
```bash
# CPU miner
kubectl logs -n miners deployment/unmineable --tail=100

# GPU miner
kubectl logs -n miners deployment/unmineable-gpu --tail=100
```

### API Access
```bash
# T-Rex API (GPU)
kubectl port-forward -n miners deployment/unmineable-gpu 4067:4067
# Navigate to http://localhost:4067/trex
```

---

## Total Hashrate

- **CPU (RandomX):** ~5.1 kH/s
- **GPU (Autolykos2):** ~75.26 MH/s

Both mining BNB on Unmineable simultaneously to the same wallet.
