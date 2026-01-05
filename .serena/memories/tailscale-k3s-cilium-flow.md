# Tailscale → K3s → Cilium (detalles criticos sin codigo)

Objetivo del flujo
- Usar Tailscale como overlay de red y fuente de IP estable para K3s, y luego instalar Cilium como CNI/kube-proxy replacement apuntando al API server en tailscale_ip.

Dependencias y precondiciones
- Requiere tailscale_authkey valido (no placeholder) antes de ejecutar roles.
- Requiere conectividad a internet (preflight valida acceso a get.k3s.io).
- Para Cilium: helm y kubectl deben existir en PATH del usuario remoto (normalmente provistos por developer_tools).
- Kubeconfig debe existir en /home/{{ ansible_user }}/.kube/config; se crea en k3s_server.

Tailscale (hechos de implementacion)
- Instala tailscaled si el binario no existe y lo habilita/arranca.
- Evalua estado con tailscale status --json; si BackendState no es Running, ejecuta tailscale up.
- No intenta reconciliar configuracion si ya esta Running; posibles drift de opciones (tags/accept-dns/ssh) no se corrigen.
- Espera una IPv4 100.x.x.x y la expone como tailscale_ip; si no hay 100.x, la ejecucion de K3s falla.
- Si tailscale_tags esta vacio, no se pasa --advertise-tags.

K3s (hechos de implementacion)
- Valida tailscale_ip con regex ^100\.; aborta si es invalido.
- Escribe /etc/rancher/k3s/config.yaml usando tailscale_ip para node-ip, advertise-address y tls-san.
- Deshabilita flannel y network-policy en K3s, y deshabilita traefik/servicelb.
- Antes de instalar K3s, elimina archivos CNI residuales (calico/flannel/podman) si existen.
- Instala K3s via script solo si /usr/local/bin/k3s no existe.
- Si el config cambia, notifica handler Restart k3s y hace flush inmediato antes de continuar.
- Espera node-token y disponibilidad del API server via kubectl (no en check_mode).
- Crea kubeconfig para el usuario remoto; opcionalmente copia kubeconfig a localhost reemplazando 127.0.0.1 por tailscale_ip (no en check_mode).

Cilium (hechos de implementacion)
- Se ejecuta sin become (usuario remoto). Requiere kubeconfig funcional y permisos de kubectl/helm.
- Genera values temporales con k8sServiceHost=tailscale_ip y k8sServicePort=6443.
- Instala/actualiza Cilium via Helm (version 1.18.5) y espera rollout de ds/cilium.
- Configuracion clave: kubeProxyReplacement=true, socketLB habilitado, Gateway API habilitado, Hubble habilitado (relay+UI+metrics), k8sNetworkPolicy habilitado, IPAM cluster-pool 10.0.0.0/8 (/24), routing mode tunnel.

Puntos de fallo y debugging
- Si tailscale no obtiene IP 100.x, K3s no se instala (bloqueo temprano).
- Si helm/kubectl no estan disponibles para el usuario remoto, Cilium falla aunque K3s este OK.
- Si kubeconfig no se genera (fallo en k3s_server o permisos), Cilium falla.
- Tailscale Running con config antigua puede dejar hostname/tags/ssh/dns en estado inesperado sin reconfiguracion.
- Cilium requiere API server accesible en tailscale_ip:6443; fallos de conectividad Tailscale bloquean el rollout.

Relacion con post-tasks
- Los manifiestos k8s se aplican despues de Cilium; un fallo en Cilium normalmente implica fallo en aplicacion de workloads.
- Los manifests GPU se eliminan si no hay GPU activa antes de aplicar.