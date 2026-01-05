# NVIDIA GPU (hechos actuales)

- Deteccion GPU via lspci (vendor 10de) con modo auto; permite forzar o deshabilitar.
- Host setup instala drivers, blacklistea nouveau, toolkit, y configura containerd runtime nvidia.
- Optimizacion headless: instala X11 y configura servicios nvidia-persistence y nvidia-xorg.
- Cluster setup instala nvidia-device-plugin via Helm con NFD+GFD habilitados y runtimeClassName nvidia.
- Despliegue GPU de workloads se condiciona por fact nvidia_gpu_active.
