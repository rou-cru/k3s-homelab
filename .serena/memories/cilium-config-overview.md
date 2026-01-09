# Cilium (hechos actuales)

- Se instala via Helm (repo cilium, version 1.18.5) en kube-system.
- Values templated habilitan: kube-proxy replacement, socket LB, Gateway API, Hubble (relay+UI+metrics), BPF optimizations, bandwidthManager con BBR.
- IPAM en modo cluster-pool con PodCIDR 10.0.0.0/8 y mask /24; routing mode tunnel.
- k8sServiceHost usa tailscale_ip y puerto 6443.
