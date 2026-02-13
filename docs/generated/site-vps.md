<!-- DOCSIBLE START -->

# 📃 Role overview

## site-vps



Description: Playbook documentation wrapper for site-vps.yaml
















### Tasks





## Playbook

```yml
---
# site-vps.yaml - Setup K3s VPS Agent Node
# This playbook configures a VPS as an edge/gateway node for the k3s cluster

- name: Setup K3s VPS Agent Node
  hosts: vps
  become: true
  vars_files:
    - "{{ secrets_file | default('secrets.yaml') }}"
  pre_tasks:
    # @docsible Refreshes APT cache with 1-hour validity
    - name: Update APT cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
      tags: always

    # # @docsible Asserts tailscale_authkey is defined and valid before proceeding
    # - name: Validate Tailscale AuthKey presence
    #   ansible.builtin.assert:
    #     that:
    #       - tailscale_authkey is defined
    #       - tailscale_authkey | length > 0
    #       - "tailscale_authkey != 'tskey-auth-REPLACE-WITH-REAL-KEY'"
    #     fail_msg: "ERROR: Configure your real 'tailscale_authkey' in 'secrets.yaml'."
    #     success_msg: "Tailscale AuthKey validated successfully."
    #   tags: always
    #   no_log: true

    # @docsible Ensures 'k3s_server' group exists in inventory for master discovery
    - name: Validate k3s_server group exists
      ansible.builtin.assert:
        that:
          - groups['k3s_server'] is defined
          - groups['k3s_server'] | length > 0
        fail_msg: "ERROR: No hosts in 'k3s_server' group. Check your inventory."
      tags: always

  tasks:
    # ==========================================================================
    # PHASE 1: HOST (OS preparation)
    # ==========================================================================
    # @docsible Validates VPS system requirements (RAM, Disk, Connectivity)
    # - name: Run preflight role
    #   ansible.builtin.import_role:
    #     name: preflight
    #   tags: ["host"]

    # @docsible Configures base OS settings, packages, and kernel parameters
    - name: Run common role
      ansible.builtin.import_role:
        name: common
      tags: ["host"]

    # # @docsible Tunes networking stack (BBR) for gateway performance
    # - name: Run common network optimizations
    #   ansible.builtin.import_role:
    #     name: common
    #     tasks_from: network_optimization.yml
    #   when: system_networkOptimize | default(false)
    #   tags: ["host"]

    # ==========================================================================
    # PHASE 2: CLUSTER (VPS joins as agent node)
    # ==========================================================================
    # @docsible Configures Tailscale interface and routing
    - name: Run tailscale role
      ansible.builtin.import_role:
        name: tailscale
      tags: ["cluster", "tailscale"]

    # @docsible Flushes host-level handlers before K3s agent bootstrap
    - name: Flush host handlers before cluster join
      ansible.builtin.meta: flush_handlers

    # @docsible Resolves K3s Master Tailscale IP (100.x) for secure join
    - name: Get master Tailscale IP
      ansible.builtin.command: tailscale ip -4
      register: k3s_master_tailscale_ip
      delegate_to: "{{ groups['k3s_server'][0] }}"
      changed_when: false
      when: not ansible_check_mode

    # @docsible Fails early when master Tailscale IP cannot be resolved
    - name: Validate Master IP
      ansible.builtin.fail:
        msg: "Could not determine K3s Master Tailscale IP. Tailscale might be down or not authenticated."
      when:
        - not ansible_check_mode
        - k3s_master_tailscale_ip.stdout | length == 0

    # @docsible Constructs internal K3s API URL using Tailscale IP
    - name: Set K3s agent server URL
      vars:
        k3s_masterTailscaleIp: >-
          {{
            (k3s_master_tailscale_ip.stdout_lines | default([]) | first)
            | default(k3s_master_tailscale_ip.stdout | trim)
          }}
      ansible.builtin.set_fact:
        k3s_agentServerUrl: "https://{{ k3s_masterTailscaleIp }}:6443"
      when: not ansible_check_mode

    # @docsible Mocks API URL for Ansible check mode safety
    - name: Set K3s agent server URL (check mode)
      ansible.builtin.set_fact:
        k3s_agentServerUrl: "https://100.64.0.1:6443"
      when: ansible_check_mode

    # @docsible Fetches K3s node-token directly from Master node
    - name: Retrieve K3s server token from master
      ansible.builtin.slurp:
        src: /var/lib/rancher/k3s/server/node-token
      register: k3s_token_raw
      delegate_to: "{{ groups['k3s_server'][0] }}"
      become: true
      no_log: true
      tags: ["cluster"]
      when: not ansible_check_mode

    # @docsible Registers node-token fact for agent role consumption
    - name: Set K3s token fact
      ansible.builtin.set_fact:
        k3s_agentToken: >-
          {{
            'mock-token-for-check-mode' if ansible_check_mode
            else (k3s_token_raw.content | b64decode | trim)
          }}
      no_log: true
      tags: ["cluster"]
      when: ansible_check_mode or k3s_token_raw is not skipped

    # @docsible Installs K3s agent and joins the cluster
    - name: Run k3s_agent role
      ansible.builtin.import_role:
        name: k3s_agent
      tags: ["cluster"]

    # @docsible Announces local Pod CIDR to Tailscale mesh (Hybrid connectivity)
    - name: Advertise Cilium pod CIDR via Tailscale
      ansible.builtin.import_role:
        name: tailscale
        tasks_from: advertise_pod_cidr
      tags: ["cluster", "tailscale"]
      become: false
      when: not ansible_check_mode

    # @docsible Advertises Service CIDR (10.43.0.0/16) to function as Cluster Gateway
    # - name: Advertise Service CIDR via Tailscale on VPS
    #   vars:
    #     _service_cidr: "{{ tailscale_serviceCidr | default('10.43.0.0/16') }}"
    #   ansible.builtin.command: >
    #     tailscale set
    #     --advertise-routes="{{ _cilium_pod_cidr | default('') }},{{ _service_cidr }}"
    #   become: true
    #   when:
    #     - not ansible_check_mode
    #     - _cilium_pod_cidr | default('') | length > 0
    #   tags: ["cluster", "tailscale"]

  post_tasks:
    # @docsible Outputs post-install summary and manual action items
    - name: Display VPS setup summary
      ansible.builtin.debug:
        msg: |
          ====================================
          VPS Node Setup Complete
          ====================================
          Hostname: {{ ansible_facts['hostname'] }}
          Tailscale IP: {{ IP_tailscale | default('Not configured') }}
          Public IP: {{ ansible_host }}
          K3s Server: {{ k3s_agentServerUrl | default('Not configured') }}
          Exit Node: {{ tailscale_exitNodeEnabled | default(false) }}
      tags: always

```
## Playbook graph
```mermaid
flowchart TD
  hosts[vps]-->|Import role| Run_common_role_common_0([run common role<br>import_role: common]):::importRole
  Run_common_role_common_0-->|Import role| Run_tailscale_role_tailscale_1([run tailscale role<br>import_role: tailscale]):::importRole
  Run_tailscale_role_tailscale_1-->|Task| Flush_host_handlers_before_cluster_join2[flush host handlers before cluster join]:::task
  Flush_host_handlers_before_cluster_join2-->|Task| Get_master_Tailscale_IP3[get master tailscale ip<br>When: **not ansible check mode**]:::task
  Get_master_Tailscale_IP3-->|Task| Validate_Master_IP4[validate master ip<br>When: **not ansible check mode and k3s master tailscale ip<br>stdout   length    0**]:::task
  Validate_Master_IP4-->|Task| Set_K3s_agent_server_URL5[set k3s agent server url<br>When: **not ansible check mode**]:::task
  Set_K3s_agent_server_URL5-->|Task| Set_K3s_agent_server_URL__check_mode_6[set k3s agent server url  check mode <br>When: **ansible check mode**]:::task
  Set_K3s_agent_server_URL__check_mode_6-->|Task| Retrieve_K3s_server_token_from_master7[retrieve k3s server token from master<br>When: **not ansible check mode**]:::task
  Retrieve_K3s_server_token_from_master7-->|Task| Set_K3s_token_fact8[set k3s token fact<br>When: **ansible check mode or k3s token raw is not skipped**]:::task
  Set_K3s_token_fact8-->|Import role| Run_k3s_agent_role_k3s_agent_9([run k3s agent role<br>import_role: k3s agent]):::importRole
  Run_k3s_agent_role_k3s_agent_9-->|Import role| Advertise_Cilium_pod_CIDR_via_Tailscale_tailscale_10([advertise cilium pod cidr via tailscale<br>When: **not ansible check mode**<br>import_role: tailscale]):::importRole
```

## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.14

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
