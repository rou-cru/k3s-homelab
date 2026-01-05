# Seguridad (hechos observables)

- Instalaciones via curl | sh para tailscale y k3s (sin verificacion de firmas en tareas actuales).
- Secrets se cargan desde secrets.yaml; tareas de tailscale pasan authkey en CLI (expuesto si no se usa no_log).
