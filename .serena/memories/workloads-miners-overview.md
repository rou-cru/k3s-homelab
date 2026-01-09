# Workloads miners (hechos actuales)

- Namespace: miners.
- CPU mining (unmineable): usa imagen thechristech/unmineable, hugepages y /dev/cpu; config via ConfigMap y Secret.
- GPU mining (unmineable-gpu): usa imagen nvidia/cuda runtime; runtimeClassName nvidia; descarga T-Rex en entrypoint; config via ConfigMap y Secret.
- Honeygain: deployment con configmap para email/device y secret para password.
