# Ansible Roles Analysis

## 1. Role: `preflight`
*   **Purpose:** Validates system readiness before installation.
*   **Checks:**
    *   Network connectivity (HTTP HEAD to get.k3s.io).
    *   Disk space (Requires > 20GB).
    *   Memory (Requires > 4GB).
    *   Architecture (Requires x86_64).
*   **Implementation:** Uses Ansible's `uri` module for network checks and `assert` module for validations.

## 2. Role: `common`
*   **Purpose:** Base system configuration and tuning.
*   **Key Components:**
    *   **Packages:** Installs base utils (curl, iptables, etc.) and HWE kernel.
    *   **Swap:** Disables swap (command + fstab).
    *   **Hardware Tuning:**
        *   Installs `irqbalance`, `rfkill`.
        *   Installs `alsa-utils` (when `audio_optimization_enabled` is true).
        *   Soft-blocks wifi/bluetooth via `rfkill` shell commands (when `radio_block_enabled` is true).
        *   Configures PAM limits for audio (realtime, when `audio_optimization_enabled` is true).
    *   **Network Optimization:**
        *   Deploys custom systemd service (`network-optimization.service`) wrapping a script (`optimize-network.sh`).
        *   Script tweaks: EEE off, WOL off, Ring Buffers max.
        *   Realtek drivers: Installs `r8168-dkms`, blacklists `r8169`.
        *   GRUB: Disables ASPM (`pcie_aspm=off`).
    *   **Power Management:**
        *   Logind: Ignores lid switch events.
        *   Systemd: Masks sleep/suspend targets.
    *   **RoG Hardware (ASUS specific):**
        *   Installs `asusctl`.
        *   Deploys custom systemd service (`rog-server-tweaks.service`) wrapping a script (`apply-rog-tweaks.sh`).
        *   Script tweaks: Battery charge limit (80%), Thermal policy (Turbo).
    *   **System Tuning:**
        *   CPU Governor: `schedutil`.
        *   Sysctl: Enables BBR, increases file descriptors/inotify limits.
        *   Watchdog: Enables RuntimeWatchdog.
*   **Reboot Logic:** Consolidated reboot at end of role if kernel or network drivers changed.

## 3. Role: `tailscale`
*   **Purpose:** Installs and configures Tailscale VPN.
*   **Installation:** `curl | sh` script.
*   **Configuration:**
    *   `tailscale up` with AuthKey from secrets file, passed via CLI command.
    *   Sets fact `tailscale_ip` for use in K3s role.

## 4. Role: `k3s_server`
*   **Purpose:** Installs K3s Kubernetes distribution.
*   **Prerequisites:** Requires `tailscale_ip` fact.
*   **Installation:** `curl | sh` script.
*   **Configuration:**
    *   Exec args: Disable traefik/servicelb, use Tailscale IP.
    *   Token: Retrieves node-token after install.
    *   Wait: Blocks until `readyz` check passes.

## 5. Role: `nvidia_gpu`
*   **Purpose:** Configures NVIDIA drivers and Container Toolkit.
*   **Detection:** Uses `lspci` to detect NVIDIA GPU and `ubuntu-drivers` for driver detection (shell parsing, when `nvidia_driver_package` is set to "auto").
*   **Driver Install:** APT (managed driver or fallback).
*   **Container Runtime:**
    *   Installs `nvidia-container-toolkit`.
    *   Templating `config.toml.tmpl` for K3s containerd.
*   **Device Plugin:** Deploys via K3s HelmChart manifest.

## 6. Role: `cilium`
*   **Purpose:** Installs Cilium CNI.
*   **Method:** K3s HelmChart manifest + `cilium-values.yaml`.
*   **Verification:** Waits for `ds/cilium` rollout.
