# Flujo logico de roles en site.yaml

Orden de ejecucion:
1) preflight: valida conectividad, disco, RAM y arquitectura.
2) common: prepara SO, tuning y servicios de optimizacion; maneja reboot consolidado si aplica.
3) developer_tools: instala tooling (condicional por devtools_enabled).
4) nvidia_gpu host: drivers y runtime antes de K3s (condicional por nvidia_gpu_setup).
5) tailscale: instala y configura VPN; obtiene tailscale_ip.
6) k3s_server: instala K3s usando tailscale_ip, limpia CNIs residuales, copia kubeconfig local.
7) cilium: instala Cilium via Helm usando values templated.
8) nvidia_gpu cluster: instala device plugin via Helm (condicional por nvidia_gpu_setup).

Post-tasks:
- Copia manifiestos k8s a /tmp en el host.
- Templa secret de honeygain.
- Aplica namespaces primero y luego todo el arbol de manifests; elimina manifests GPU si no hay GPU.
