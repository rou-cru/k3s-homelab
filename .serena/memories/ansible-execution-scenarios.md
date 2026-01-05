# Flujo logico de ejecucion (escenarios completos)

Ejecucion base (site.yaml):
0) Pre-tasks
- Actualiza cache APT (cache_valid_time 3600).
- Assert tailscale_authkey definido y no placeholder.

1) preflight
- HEAD a get.k3s.io; falla si no hay conectividad.
- Assert disco / >20GB, RAM >=4GB, arch x86_64.

2) common
- Deshabilita swap (runtime + fstab).
- Instala paquetes base + kernel HWE si aplica; fallback a linux-generic si HWE falla.
- Power management: logind ignora tapa; sleep/suspend targets masked (handler Restart logind).
- Hardware tuning: irqbalance, rfkill (bloqueo wifi/BT), PAM limits audio, fstrim.timer.
- System tuning: governor schedutil (handler Restart cpufrequtils), BBR, límites fds/inotify, watchdog, hugepages+msr si mining.
- Network/RoG: r8168-dkms + blacklist r8169 + pcie_aspm=off (si common_rog_server), script optimize-network + systemd service.
- Reboot consolidado si kernel o drivers de red cambiaron.

3) developer_tools (solo si devtools_enabled=true)
- Instala CLI y herramientas (apt/snap/npm/curl).
- Provee helm/kubectl/yq y tooling para Cilium/NVIDIA (requisito implicito si no hay herramientas previas).

4) nvidia_gpu host (solo si nvidia_gpu_setup != false)
- Detecta GPU (lspci 10de).
- nvidia_gpu_setup=auto: setea nvidia_gpu_active segun deteccion.
- nvidia_gpu_setup=true: falla si no hay GPU.
- nvidia_gpu_setup=false: fuerza nvidia_gpu_active=false.
- Si GPU activa: instala drivers (auto o fallback), blacklistea nouveau, instala toolkit y templatea config de containerd.
- Reboot si drivers o blacklist cambiaron.

5) nvidia_gpu headless (solo si nvidia_gpu_active=true y nvidia_gpu_headless_enabled=true)
- Instala X11, xorg.conf, servicios nvidia-persistence y nvidia-xorg; espera /tmp/.X0-lock si X11 habilitado.

6) tailscale
- Instala/arranca tailscaled; ejecuta tailscale up solo si no esta corriendo.
- Espera IP 100.x y setea tailscale_ip.

7) k3s_server
- Falla si tailscale_ip invalido.
- Escribe config K3s; notifica handler Restart k3s y hace flush handlers.
- Instala k3s si no existe; espera node-token y apiserver (no en check_mode).
- Crea kubeconfig del usuario; copia kubeconfig a localhost si k3s_server_copy_kubeconfig_local=true y no check_mode.

8) cilium (become=false)
- Requiere helm/kubectl en PATH del usuario y kubeconfig disponible.
- Instala/actualiza Cilium y espera rollout ds/cilium.

9) nvidia_gpu cluster (become=false, solo si nvidia_gpu_active=true)
- Instala nvidia-device-plugin via Helm y espera rollout.

Post-tasks (become=false en apply):
- Copia k8s/ al host y templatea secret honeygain.
- Calcula should_deploy_gpu_manifests:
  - true si nvidia_gpu_active=true, o si nvidia_gpu_active no existe y nvidia_gpu_setup=true.
  - En auto sin GPU: nvidia_gpu_active=false => false.
- Si should_deploy_gpu_manifests=false, elimina /tmp/k8s-manifests/miners/unmineable-gpu.
- Aplica namespaces primero (reintentos), luego todo el arbol de manifests (reintentos), y limpia /tmp/k8s-manifests.

Notas de check_mode:
- Varias acciones críticas (esperas, slurp/copy de kubeconfig) se omiten cuando ansible_check_mode.
- Handlers en common se ignoran en check_mode.
