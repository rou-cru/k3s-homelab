# Planned Refactoring Phase 1: Common Role Simplification

**Status:** Planned / Pending Implementation
**Goal:** Remove over-engineering and use native systemd/linux features instead of custom scripts.

## Objectives

1.  **Remove Custom Systemd Services**
    *   **Target:** `rog-server-tweaks.service`, `network-optimization.service`
    *   **Reasoning:** These services invoke simple bash scripts that write to `/sys` or run `ethtool`. This is better handled by `systemd-tmpfiles` and `NetworkManager` dispatcher scripts.
    *   **Action:** Delete `.service` files and associated `.sh.j2` templates.

2.  **Implement Native Alternatives**
    *   **Hardware Tweaks (RoG):**
        *   Create `/etc/tmpfiles.d/rog-tweaks.conf`.
        *   Content: Write battery threshold and thermal policy values to sysfs.
        *   Mechanism: Systemd automatically applies these at boot.
    *   **Network Optimization:**
        *   Create `/etc/NetworkManager/dispatcher.d/pre-up.d/99-optimize-eth`.
        *   Content: `ethtool` commands for ring buffers and offloading.
        *   Mechanism: NetworkManager applies this exactly when the interface comes up.

3.  **Cleanup `common` Role**
    *   Remove tasks that deploy the deleted templates and services.
    *   Ensure new configuration files are deployed with `ansible.builtin.copy` or `template`.

## Expected Benefits
*   Reduction of managed files (4 files removed, 2 added).
*   Elimination of script logic maintenance.
*   Adherence to Linux standards (tmpfiles.d, NM dispatcher).
