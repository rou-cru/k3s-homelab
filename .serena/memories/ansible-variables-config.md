# Ansible Variables & Configuration

## Variable Sources
1.  **Inventory (`inventory.ini`):**
    *   `gpu_setup`: Boolean toggle for NVIDIA role (overrides role default).
    *   `ansible_user`, `ansible_become`.

2.  **Secrets (`secrets.yaml`):**
    *    Referenced in `site.yaml` but not committed (correct practice).
    *   Expected keys: `tailscale_authkey`.

3.  **Role Defaults (`defaults/main.yml`):**

    *   **`common` Role:**
        *   `network_optimization_enabled`: true
        *   `rog_server`: true (Toggles ASUS specific tasks)
        *   `radio_block_enabled`: true
        *   `audio_optimization_enabled`: true
        *   *Limits:*
            *   `file_descriptors_soft/hard`: 100000
            *   `fs_file_max`: 2097152
            *   `inotify_max_instances`: 8192
            *   `inotify_max_watches`: 524288
            *   `watchdog_timeout_sec`: 120
        *   *Hardware:*
            *   `battery_charge_threshold`: 80
            *   `thermal_policy`: 1 (Turbo)
            *   `ring_buffer_target`: 4096

    *   **`k3s_server` Role:**
        *   `k3s_version`: "v1.34.3+k3s1"
        *   `k3s_disable_traefik`: true
        *   `k3s_disable_servicelb`: true
        *   `k3s_kubeconfig_mode`: "644"
        *   `k3s_node_token_timeout`: 180
        *   `k3s_readyz_retries`: 30
        *   `k3s_readyz_delay`: 2

    *   **`tailscale` Role:**
        *   `tailscale_hostname_prefix`: "k3s"
        *   `tailscale_tags`: "tag:k3s"
        *   `tailscale_accept_dns`: "true"
        *   `tailscale_ssh`: "true"

    *   **`nvidia_gpu` Role:**
        *   `gpu_setup`: true (default, can be overridden in inventory)
        *   `nvidia_driver_package`: "auto"
        *   `nvidia_driver_fallback`: "nvidia-driver-535"
        *   `nvidia_toolkit_repo_url`: "https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list"
        *   `nvidia_toolkit_gpg_url`: "https://nvidia.github.io/libnvidia-container/gpgkey"
        *   `nvidia_device_plugin_version`: "0.14.3"
        *   `nvidia_device_plugin_repo`: "https://nvidia.github.io/k8s-device-plugin"
        *   `nvidia_reboot_timeout`: 600
        *   `nvidia_initramfs_timeout`: 300

    *   **`cilium` Role:**
        *   `cilium_version`: "1.18.5"
        *   `cilium_chart_repo`: "https://helm.cilium.io/"
        *   `cilium_chart_name`: "cilium"
        *   `cilium_namespace`: "kube-system"
        *   `cilium_rollout_timeout`: 300

## Logic & Flow Control
*   **Conditionals:**
    *   `rog_server | bool`: Controls execution of ASUS specific hardware tasks.
    *   `gpu_setup | bool`: Controls execution of `nvidia_gpu` role block.
    *   `network_optimization_enabled | bool`: Controls execution of network tuning tasks.
*   **Facts:**
    *   `tailscale_ip`: Dynamically set by `tailscale` role, consumed by `k3s_server` role.
    *   `k3s_token`: Captured from master, intended for potential worker joining (though currently single node).
