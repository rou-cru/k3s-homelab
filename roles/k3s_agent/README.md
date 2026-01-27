<!-- DOCSIBLE START -->

# 📃 Role overview

## k3s_agent



Description: Install and configure K3s agent node to join existing cluster






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**:
- Installs K3s in agent mode and joins an existing cluster
- Configures Tailscale-based secure communication
- Supports custom node labels and taints


**Options**:


  - **k3s_agentVersion**
    - **Required**: false
    - **Type**: str
    - **Default**: v1.35.0+k3s1
  
    - **Description**: K3s version to install (should match server version)
  
  
  

  - **k3s_agentServerUrl**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: K3s server URL (use Tailscale IP)
  
  
  

  - **k3s_agentToken**
    - **Required**: False
    - **Type**: str
    - **Default**: none
  
    - **Description**: K3s server token for node authentication (set dynamically from server)
  
  
  

  - **k3s_agentNodeLabels**
    - **Required**: false
    - **Type**: list
    - **Default**: []
  
    - **Description**: Labels to apply to this node
  
  
  

  - **k3s_agentNodeTaints**
    - **Required**: false
    - **Type**: list
    - **Default**: []
  
    - **Description**: Taints to apply to this node
  
  
  

  - **k3s_agentRecreate**
    - **Required**: false
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Uninstall and wipe previous K3s agent before deploying
  
  
  

  - **IP_tailscale**
    - **Required**: False
    - **Type**: str
    - **Default**: none
  
    - **Description**: Tailscale IP address (100.x.x.x) for node communication (set by tailscale role)
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate Tailscale IP](tasks/main.yml#L2) | ansible.builtin.assert | False | @docsible Validate Tailscale IP format (100.x.x.x) |
| [Verify K3s agent requirements](tasks/main.yml#L11) | ansible.builtin.assert | False | @docsible Verify required variables are defined |
| [Check for runsc binary](tasks/main.yml#L21) | ansible.builtin.stat | False | @docsible Check for gVisor runtime |
| [Check for nvidia-container-runtime](tasks/main.yml#L27) | ansible.builtin.stat | False | @docsible Check for NVIDIA runtime |
| [Build containerd runtime list](tasks/main.yml#L33) | ansible.builtin.set_fact | False | @docsible Build list of additional containerd runtimes |
| [Run K3s Common](tasks/main.yml#L43) | ansible.builtin.import_role | False | @docsible Import common K3s setup tasks |
| [Deploy agent config](tasks/main.yml#L51) | ansible.builtin.template | True | @docsible Deploy agent configuration file |
| [Install K3s agent](tasks/main.yml#L60) | ansible.builtin.shell | True | @docsible Install K3s agent binary |
| [Create override dir](tasks/main.yml#L76) | ansible.builtin.file | False | @docsible Create systemd override directory |
| [Create override](tasks/main.yml#L83) | ansible.builtin.copy | False | @docsible Deploy systemd service override |
| [Reload systemd](tasks/main.yml#L94) | ansible.builtin.systemd | False | @docsible Reload systemd daemon |
| [Start K3s agent](tasks/main.yml#L99) | ansible.builtin.systemd | True | @docsible Enable and start K3s agent service |
| [Flush handlers](tasks/main.yml#L107) | ansible.builtin.meta | False | @docsible Apply pending handler restarts |
| [Wait for node to be ready](tasks/main.yml#L111) | kubernetes.core.k8s_info | True | @docsible Wait for node Ready condition |
| [Apply node labels](tasks/main.yml#L129) | kubernetes.core.k8s | True | @docsible Apply custom node labels |
| [Apply node taints](tasks/main.yml#L143) | kubernetes.core.k8s_taint | True | @docsible Apply custom node taints |
| [Show agent join status](tasks/main.yml#L159) | ansible.builtin.debug | False | @docsible Display join confirmation |


## Task Flow Graphs



### Graph for main.yml

```mermaid
flowchart TD
Start
classDef block stroke:#3498db,stroke-width:2px;
classDef task stroke:#4b76bb,stroke-width:2px;
classDef includeTasks stroke:#16a085,stroke-width:2px;
classDef importTasks stroke:#34495e,stroke-width:2px;
classDef includeRole stroke:#2980b9,stroke-width:2px;
classDef importRole stroke:#699ba7,stroke-width:2px;
classDef includeVars stroke:#8e44ad,stroke-width:2px;
classDef rescue stroke:#665352,stroke-width:2px;

  Start-->|Task| Validate_Tailscale_IP0[validate tailscale ip]:::task
  Validate_Tailscale_IP0-->|Task| Verify_K3s_agent_requirements1[verify k3s agent requirements]:::task
  Verify_K3s_agent_requirements1-->|Task| Check_for_runsc_binary2[check for runsc binary]:::task
  Check_for_runsc_binary2-->|Task| Check_for_nvidia_container_runtime3[check for nvidia container runtime]:::task
  Check_for_nvidia_container_runtime3-->|Task| Build_containerd_runtime_list4[build containerd runtime list]:::task
  Build_containerd_runtime_list4-->|Import role| Run_K3s_Common_k3s_common_5([run k3s common<br>import_role: k3s common]):::importRole
  Run_K3s_Common_k3s_common_5-->|Task| Deploy_agent_config6[deploy agent config<br>When: **not ansible check mode**]:::task
  Deploy_agent_config6-->|Task| Install_K3s_agent7[install k3s agent<br>When: **not ansible check mode**]:::task
  Install_K3s_agent7-->|Task| Create_override_dir8[create override dir]:::task
  Create_override_dir8-->|Task| Create_override9[create override]:::task
  Create_override9-->|Task| Reload_systemd10[reload systemd]:::task
  Reload_systemd10-->|Task| Start_K3s_agent11[start k3s agent<br>When: **not ansible check mode**]:::task
  Start_K3s_agent11-->|Task| Flush_handlers12[flush handlers]:::task
  Flush_handlers12-->|Task| Wait_for_node_to_be_ready13[wait for node to be ready<br>When: **not ansible check mode**]:::task
  Wait_for_node_to_be_ready13-->|Task| Apply_node_labels14[apply node labels<br>When: **k3s agentnodelabels   length   0 and not ansible<br>check mode**]:::task
  Apply_node_labels14-->|Task| Apply_node_taints15[apply node taints<br>When: **k3s agentnodetaints   length   0 and not ansible<br>check mode**]:::task
  Apply_node_taints15-->|Task| Show_agent_join_status16[show agent join status]:::task
  Show_agent_join_status16-->End
```





## Author Information
rc

### License

MIT

### Minimum Ansible Version

2.14

### Platforms

- **Ubuntu**: ['jammy', 'noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
