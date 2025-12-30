# Ansible Variables & Configuration

## Variable Sources
1.  **Inventory (`inventory.ini`):**
    *   `gpu_setup`: Boolean toggle for NVIDIA role.
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
        *   *Hardware:*
            *   `battery_charge_threshold`: 80
            *   `thermal_policy`: 1 (Turbo)
            *   `ring_buffer_target`: 4096

    *   **`k3s_server` Role:**
        *   `k3s_version`: "v1.34.3+k3s1"
        *   `k3s_disable_traefik`: true
        *   `k3s_disable_servicelb`: true
        *   `k3s_kubeconfig_mode`: "644"

## Logic & Flow Control
*   **Conditionals:**
    *   `rog_server | bool`: Controls execution of ASUS specific hardware tasks.
    *   `gpu_setup | bool`: Controls execution of `nvidia_gpu` role block.
    *   `network_optimization_enabled | bool`: Controls execution of network tuning tasks.
*   **Facts:**
    *   `tailscale_ip`: Dynamically set by `tailscale` role, consumed by `k3s_server` role.
    *   `k3s_token`: Captured from master, intended for potential worker joining (though currently single node).
