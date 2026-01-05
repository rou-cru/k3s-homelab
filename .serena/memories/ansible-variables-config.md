# Variables y defaults (hechos actuales)

Secrets esperados (secrets.example.yaml): tailscale_authkey, ansible_ssh_pass, ansible_become_password, honeygain_pass.

Defaults relevantes por rol:
- common: optimizaciones de red y RoG activas; tuning de sistema (limits/inotify/bbr/watchdog); hugepages y msr si mining; parametros bateria/thermal.
- developer_tools: habilitado por defecto; instala CLI tools, snaps, devbox, uv; Docker CLI opcional (default false).
- tailscale: hostname prefix "k3s", tags vacio, accept-dns "true", ssh "true".
- k3s_server: version v1.34.3+k3s1; traefik y servicelb deshabilitados; kubeconfig 644; copia kubeconfig local habilitada.
- cilium: version 1.18.5; repo helm oficial; namespace kube-system; waits configurados.
- nvidia_gpu: setup "auto" (detecta GPU); driver auto con fallback 535; toolkit repo oficial; device plugin 0.14.3; modo headless y X11 habilitados por default.

Nota: no hay overrides en inventory para GPU u otras vars (solo vars globales).
