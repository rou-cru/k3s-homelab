# Ansible Project Structure & Configuration

## File Layout
The project follows a standard Ansible directory structure:

*   **Configuration:** `ansible.cfg` (Root)
*   **Inventory:** `inventory.ini` (INI format)
*   **Playbook:** `site.yaml` (Main entry point)
*   **Variables:** `group_vars/all.yaml`
*   **Roles:** Located in `roles/` directory.
    *   `cilium`
    *   `common`
    *   `k3s_server`
    *   `nvidia_gpu`
    *   `preflight`
    *   `tailscale`

## Base Configuration (`ansible.cfg`)
*   **Inventory source:** `inventory.ini`
*   **Callbacks:** `stdout_callback = yaml` (Readable output)
*   **Pipelining:** Enabled (`True`) for performance.
*   **Fact Caching:** JSON file based (`/tmp/ansible_facts`), timeout 1h.
*   **Host Key Checking:** Disabled.

## Inventory (`inventory.ini`)
*   **Groups:** `k3s_server`
*   **Hosts:** Single node `master1` (10.10.10.10).
*   **Host Variables:** `gpu_setup=true` defined inline.
*   **Global Variables:** `ansible_user=ubuntu`, `ansible_become=true`.

## Main Playbook (`site.yaml`)
*   **Target:** `k3s_server` group.
*   **Privilege Escalation:** `become: true`.
*   **Secret Management:** Loads `secrets.yaml` via `vars_files`.
*   **Pre-tasks:**
    *   Updates APT cache.
    *   Validates `tailscale_authkey`.
*   **Role Order:**
    1.  `preflight` (Tags: preflight, validation)
    2.  `common` (Tags: common, system)
    3.  `tailscale` (Tags: tailscale, network, vpn)
    4.  `k3s_server` (Tags: k3s, kubernetes)
    5.  `nvidia_gpu` (Tags: nvidia, gpu)
    6.  `cilium` (Tags: cilium, cni, network)

## Linting (`.ansible-lint`)
*   **Profile:** Production.
*   **Exclusions:** `roles/cilium/files/cilium-values.yaml`.
*   **Skipped Rules:** `var-naming[no-role-prefix]`.
