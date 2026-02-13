<!-- DOCSIBLE START -->

# 📃 Role overview

## site



Description: Playbook documentation wrapper for site.yaml
















### Tasks





## Playbook

```yml
---
# site.yaml - Master Playbook for K3s Homelab
# Organized into distinct phases for Master, Miners, VPS, and GitOps.

# ==============================================================================
# PLAY 1: K3s Master Node Setup (Infrastructure)
# ==============================================================================
- name: Setup K3s Master Node
  hosts: k3s_server
  become: true
  vars_files:
    - "{{ secrets_file | default('secrets.yaml') }}"
  pre_tasks:
    # @docsible Cleans up legacy/malformed NVIDIA source lists to prevent apt update failures
    # - name: Remove potential malformed NVIDIA source list
    #   ansible.builtin.file:
    #     path: /etc/apt/sources.list.d/nvidia-container-toolkit.list
    #     state: absent
    #   tags: always
    # @docsible Refreshes APT cache with 1-hour validity to minimize upstream hits
    - name: Update APT cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600
      tags: always
    # @docsible Normalizes nvidia_setupMode fact for downstream logic (auto detection)
    - name: Normalize NVIDIA GPU setup mode
      ansible.builtin.set_fact:
        nvidia_setupMode: "{{ nvidia_setup | default('auto') | string | lower }}"
      tags: ["nvidia"]
    # @docsible Asserts tailscale_authkey is defined and valid before proceeding
    - name: Validate Tailscale AuthKey presence
      ansible.builtin.assert:
        that:
          - tailscale_authkey is defined
          - tailscale_authkey | length > 0
          - "tailscale_authkey != 'tskey-auth-REPLACE-WITH-REAL-KEY'"
        fail_msg: "ERROR: Configure your real 'tailscale_authkey' in 'secrets.yaml'."
        success_msg: "Tailscale AuthKey validated successfully."
      tags: always
      no_log: true

  tasks:
    # ==========================================================================
    # PHASE 1: HOST (OS preparation - no cluster dependencies)
    # ==========================================================================
    # @docsible Validates hardware constraints (RAM/Disk) and system readiness
    - name: Run preflight role
      ansible.builtin.import_role:
        name: preflight
      tags: ["host"]
    # @docsible Configures kernel (BBR, hugepages), limits, and base packages
    - name: Run common role
      ansible.builtin.import_role:
        name: common
      tags: ["host"]
    # @docsible Applies advanced sysctl networking tuning (BBR, buffer sizes)
    - name: Run common network optimizations
      ansible.builtin.import_role:
        name: common
        tasks_from: network_optimization.yml
      when: system_networkOptimize | default(true)
      tags: ["host"]
    # @docsible Installs kubectl, helm, and dev utilities (if enabled)
    - name: Run developer tools role
      ansible.builtin.import_role:
        name: developer_tools
      tags: ["host"]
      when: devtools_enabled | default(true) | bool
    # @docsible Installs gVisor runsc for sandboxed container runtime
    - name: Run gvisor role
      ansible.builtin.import_role:
        name: gvisor
        tasks_from: host.yml
      tags: ["host", "gvisor"]
      when: not ansible_check_mode
    # @docsible Installs NVIDIA drivers, container toolkit, and configures X11 for fan control
    - name: Run NVIDIA GPU host role
      ansible.builtin.import_role:
        name: nvidia_gpu
        tasks_from: host.yml
      tags: ["host", "nvidia"]
      when: nvidia_setupMode != 'false'
    # @docsible Ensures kernel modules/sysctl changes are active before K8s init
    - name: Flush host handlers before cluster init
      ansible.builtin.meta: flush_handlers

    # ==========================================================================
    # PHASE 1.5: MANIFESTS (Copy Kubernetes resources to master)
    # ==========================================================================
    # @docsible Removes {{ k8s_manifestsDir }} to ensure a clean slate for manifest synchronization
    - name: Clean remote manifests directory
      ansible.builtin.file:
        path: "{{ k8s_manifestsDir }}"
        state: absent
      tags: ["cluster", "miners"]

    # @docsible Synchronizes local k8s/ directory to master node for bootstrap operations
    - name: Copy Kustomize bases to remote
      ansible.builtin.copy:
        src: k8s/
        dest: "{{ k8s_manifestsDir }}/"
        owner: "{{ ansible_user }}"
        group: "{{ ansible_user }}"
        directory_mode: "0755"
        mode: "0644"
      tags: ["cluster", "miners", "infra", "gitops"]

    # ==========================================================================
    # PHASE 2: CLUSTER (Tailscale + K8s + CNI = functional cluster)
    # ==========================================================================
    # @docsible Configures Tailscale mesh networking (interface, routing) prior to cluster start
    - name: Run tailscale role
      ansible.builtin.import_role:
        name: tailscale
      tags: ["cluster", "tailscale"]
    # @docsible Bootstraps K3s control plane with disabled Traefik/ServiceLB
    - name: Run k3s server role
      ansible.builtin.import_role:
        name: k3s_server
      tags: ["cluster"]
    # @docsible Registers runsc RuntimeClass in the cluster
    - name: Run gvisor RuntimeClass
      ansible.builtin.import_role:
        name: gvisor
        tasks_from: runtimeclass.yml
      tags: ["cluster", "gvisor"]
      become: false
      when: not ansible_check_mode
    # @docsible Applies essential CRDs (ServiceMonitor, etc.) required for addons
    - name: Run crds_bootstrap role
      ansible.builtin.import_role:
        name: crds_bootstrap
      tags: ["cluster"]
      become: false
      when: not ansible_check_mode
    # @docsible Deploys Cilium CNI (Helm) with kube-proxy replacement
    - name: Run cilium role
      ansible.builtin.import_role:
        name: cilium
      tags: ["cluster"]
      become: false
      when: not ansible_check_mode

    # @docsible Configures Tailscale to advertise K8s Pod CIDRs (post-Cilium)
    - name: Advertise Cilium pod CIDR via Tailscale
      ansible.builtin.import_role:
        name: tailscale
        tasks_from: advertise_pod_cidr
      tags: ["cluster", "tailscale"]
      become: false
      when: not ansible_check_mode

    # @docsible Deploys NVIDIA Device Plugin and GPU Feature Discovery
    - name: Run NVIDIA GPU cluster role
      ansible.builtin.import_role:
        name: nvidia_gpu
        tasks_from: cluster.yml
      tags: ["cluster", "nvidia"]
      when:
        - nvidia_active | default(false) | bool
        - not ansible_check_mode
      become: false

    # ==========================================================================
    # PHASE 3: INFRA (PKI + Secrets + Gateway)
    # ==========================================================================
    # @docsible Installs cert-manager via Helm for TLS certificate management (Base)
    - name: Run cert-manager role
      ansible.builtin.import_role:
        name: cert_manager
      tags: ["infra"]
      become: false
      when: not ansible_check_mode

    # @docsible Deploys External Secrets Operator for secret integration (GCP/Vault)
    - name: Run external-secrets role
      ansible.builtin.import_role:
        name: external_secrets
      tags: ["infra"]
      become: false
      when: not ansible_check_mode

    # @docsible Configures Cert-Manager Issuers (Depends on ESO for Cloudflare token)
    - name: Configure ACME Issuers
      ansible.builtin.import_role:
        name: cert_manager
        tasks_from: configure_issuers.yml
      tags: ["infra"]
      become: false
      when: not ansible_check_mode

    # @docsible Configures Gateway API infrastructure after ACME issuer/bootstrap completion
    - name: Run gateway role
      ansible.builtin.import_role:
        name: gateway
      tags: ["infra", "networking"]
      become: false
      when: not ansible_check_mode

# ==============================================================================
# PLAY 2: Mining Workloads (Deploy before VPS)
# ==============================================================================
- name: Deploy Mining Workloads
  hosts: k3s_server
  become: false
  vars_files:
    - "{{ secrets_file | default('secrets.yaml') }}"
  tasks:
    # @docsible Deploys mining workloads through the dedicated miners role
    - name: Run miners role
      ansible.builtin.import_role:
        name: miners
      tags: ["miners"]

# ==============================================================================
# PLAY 3: VPS Agent Setup (Import)
# ==============================================================================
# @docsible Triggers VPS setup if vps group is present
- name: Import VPS playbook
  ansible.builtin.import_playbook: site-vps.yaml
  when: groups['vps'] | default([]) | length > 0

# ==============================================================================
# PLAY 4: GitOps & Platform (ArgoCD)
# ==============================================================================
- name: Deploy ArgoCD GitOps
  hosts: k3s_server
  become: false
  tasks:
    # @docsible Deploys ArgoCD (GitOps controller) to manage cluster state
    - name: Run argocd role
      ansible.builtin.import_role:
        name: argocd
      tags: ["gitops"]
      when: not ansible_check_mode

```
## Playbook graph
```mermaid
flowchart TD
  hosts[k3s_server]-->|Import role| Run_preflight_role_preflight_0([run preflight role<br>import_role: preflight]):::importRole
  Run_preflight_role_preflight_0-->|Import role| Run_common_role_common_1([run common role<br>import_role: common]):::importRole
  Run_common_role_common_1-->|Import role| Run_common_network_optimizations_common_2([run common network optimizations<br>When: **system networkoptimize   default true**<br>import_role: common]):::importRole
  Run_common_network_optimizations_common_2-->|Import role| Run_developer_tools_role_developer_tools_3([run developer tools role<br>When: **devtools enabled   default true    bool**<br>import_role: developer tools]):::importRole
  Run_developer_tools_role_developer_tools_3-->|Import role| Run_gvisor_role_gvisor_4([run gvisor role<br>When: **not ansible check mode**<br>import_role: gvisor]):::importRole
  Run_gvisor_role_gvisor_4-->|Import role| Run_NVIDIA_GPU_host_role_nvidia_gpu_5([run nvidia gpu host role<br>When: **nvidia setupmode     false**<br>import_role: nvidia gpu]):::importRole
  Run_NVIDIA_GPU_host_role_nvidia_gpu_5-->|Task| Flush_host_handlers_before_cluster_init6[flush host handlers before cluster init]:::task
  Flush_host_handlers_before_cluster_init6-->|Task| Clean_remote_manifests_directory7[clean remote manifests directory]:::task
  Clean_remote_manifests_directory7-->|Task| Copy_Kustomize_bases_to_remote8[copy kustomize bases to remote]:::task
  Copy_Kustomize_bases_to_remote8-->|Import role| Run_tailscale_role_tailscale_9([run tailscale role<br>import_role: tailscale]):::importRole
  Run_tailscale_role_tailscale_9-->|Import role| Run_k3s_server_role_k3s_server_10([run k3s server role<br>import_role: k3s server]):::importRole
  Run_k3s_server_role_k3s_server_10-->|Import role| Run_gvisor_RuntimeClass_gvisor_11([run gvisor runtimeclass<br>When: **not ansible check mode**<br>import_role: gvisor]):::importRole
  Run_gvisor_RuntimeClass_gvisor_11-->|Import role| Run_crds_bootstrap_role_crds_bootstrap_12([run crds bootstrap role<br>When: **not ansible check mode**<br>import_role: crds bootstrap]):::importRole
  Run_crds_bootstrap_role_crds_bootstrap_12-->|Import role| Run_cilium_role_cilium_13([run cilium role<br>When: **not ansible check mode**<br>import_role: cilium]):::importRole
  Run_cilium_role_cilium_13-->|Import role| Advertise_Cilium_pod_CIDR_via_Tailscale_tailscale_14([advertise cilium pod cidr via tailscale<br>When: **not ansible check mode**<br>import_role: tailscale]):::importRole
  Advertise_Cilium_pod_CIDR_via_Tailscale_tailscale_14-->|Import role| Run_NVIDIA_GPU_cluster_role_nvidia_gpu_15([run nvidia gpu cluster role<br>When: **nvidia active   default false    bool and not<br>ansible check mode**<br>import_role: nvidia gpu]):::importRole
  Run_NVIDIA_GPU_cluster_role_nvidia_gpu_15-->|Import role| Run_cert_manager_role_cert_manager_16([run cert manager role<br>When: **not ansible check mode**<br>import_role: cert manager]):::importRole
  Run_cert_manager_role_cert_manager_16-->|Import role| Run_external_secrets_role_external_secrets_17([run external secrets role<br>When: **not ansible check mode**<br>import_role: external secrets]):::importRole
  Run_external_secrets_role_external_secrets_17-->|Import role| Configure_ACME_Issuers_cert_manager_18([configure acme issuers<br>When: **not ansible check mode**<br>import_role: cert manager]):::importRole
  Configure_ACME_Issuers_cert_manager_18-->|Import role| Run_gateway_role_gateway_19([run gateway role<br>When: **not ansible check mode**<br>import_role: gateway]):::importRole
  hosts[k3s_server]-->|Import role| Run_miners_role_miners_0([run miners role<br>import_role: miners]):::importRole
  hosts[k3s_server]-->|Import role| Run_argocd_role_argocd_0([run argocd role<br>When: **not ansible check mode**<br>import_role: argocd]):::importRole
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
