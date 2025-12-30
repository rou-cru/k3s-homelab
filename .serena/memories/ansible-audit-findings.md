# Ansible Audit Findings

## 1. Bad Practices & Anti-Patterns

*   **Shell/Command Module Abuse:**
    *   **Preflight Checks:** Uses `shell` with `awk`/`grep` to parse `df`, `free`, and `lspci`.
        *   *Correction:* Use `ansible_facts['mounts']`, `ansible_facts['memory_mb']`, and `ansible_facts['pci_devices']` (or `community.general.pci_device` facts).
    *   **RFKill:** Uses `shell: rfkill block ...`.
        *   *Correction:* Use `community.general.rfkill` module.
    *   **Tailscale Install:** Uses `curl | sh`.
        *   *Correction:* Use official Tailscale Ansible role or apt repository configuration + package install.
    *   **K3s Install:** Uses `curl | sh`.
        *   *Correction:* Use a dedicated role (e.g., `ansible-role-k3s`) or download binary explicitly with verification.

*   **Idempotency Issues:**
    *   `tailscale up` runs every time unless `creates` or `changed_when` is perfectly tuned. The current check `creates: /var/lib/tailscale/tailscaled.state` is decent but doesn't handle re-configuration.
    *   Installation via pipe-to-bash is inherently risky and hard to make truly idempotent without complex `creates` logic.

*   **Secrets Management:**
    *   `tailscale up --auth-key ...` exposes the key in the process list (ps aux) during execution.
        *   *Correction:* Use `tailscale up --auth-key=file:/path/to/key`.

## 2. Over-Engineering

*   **Systemd Services for Simple Tweaks:**
    *   `rog-server-tweaks.service`: Created to run a script that echoes values to `/sys/class/power_supply` and `/sys/devices/...`.
    *   `network-optimization.service`: Created to run `ethtool` commands.
    *   *Analysis:* Creating persistent systemd services and template scripts for one-shot boot configurations adds unnecessary complexity (maintenance of service files + script templates).
    *   *Correction:* Use `ansible.builtin.cron` (special time `@reboot`), `systemd-tmpfiles` (for /sys values), or `NetworkManager` dispatcher scripts / `systemd.link` files for network settings.

## 3. Opportunities for Simplification (KISS)

*   **Hardware Tuning:**
    *   Writing to `/sys/class/power_supply/.../charge_control_end_threshold` is standard Linux sysfs interaction. It does not require a wrapper script + systemd service. A simple `udev` rule or `tmpfiles.d` entry is the native way to make this persistent.
*   **Package Management:**
    *   Consolidated apt installs are generally good, but splitting them by role function (as done) is acceptable for readability.

## 4. Quality & Standards

*   **FQCN (Fully Qualified Collection Names):**
    *   Mostly used (`ansible.builtin.*`), which is good.
    *   `community.general.pam_limits` used correctly.
*   **Error Handling:**
    *   Preflight checks use explicit `fail` tasks, which is good for UX.
*   **Reboot Strategy:**
    *   The "Consolidated Reboot" pattern in `common` is effective and avoids multiple reboots during provisioning.
