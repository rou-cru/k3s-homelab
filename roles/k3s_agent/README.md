<!-- DOCSIBLE START -->

# 📃 Role overview

## k3s_agent



Description: Install and configure K3s agent node to join existing cluster






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: 
- Installs K3s in agent mode and joins an existing cluster
- Configures Tailscale-based secure communication
- Supports custom node labels and taints


**Options**:


  - **k3s_agent_version**
    - **Required**: false
    - **Type**: str
    - **Default**: v1.34.3+k3s1
  
    - **Description**: K3s version to install (should match server version)
  
  
  

  - **k3s_agent_server_url**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: K3s server URL (use Tailscale IP)
  
  
  

  - **k3s_agent_token**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: K3s server token for node authentication
  
  
  

  - **k3s_agent_node_labels**
    - **Required**: false
    - **Type**: list
    - **Default**: []
  
    - **Description**: Labels to apply to this node
  
  
  

  - **k3s_agent_node_taints**
    - **Required**: false
    - **Type**: list
    - **Default**: []
  
    - **Description**: Taints to apply to this node
  
  
  

  - **k3s_agent_recreate**
    - **Required**: false
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Uninstall and wipe previous K3s agent before deploying
  
  
  

  - **tailscale_ip**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Tailscale IP address (100.x.x.x) for node communication
  
  
  



</details>




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [k3s_agent_version](defaults/main.yml#L5)   | str | `v1.34.3+k3s1` |    false  |  K3s Agent Version |
| [k3s_agent_server_url](defaults/main.yml#L11)   | str |  |    true  |  Server URL |
| [k3s_agent_token](defaults/main.yml#L17)   | str |  |    true  |  Server Token |
| [k3s_agent_node_labels](defaults/main.yml#L23)   | list | `[]` |    false  |  Node Labels |
| [k3s_agent_node_taints](defaults/main.yml#L29)   | list | `[]` |    false  |  Node Taints |
| [k3s_agent_readyz_retries](defaults/main.yml#L35)   | int | `30` |    false  |  Readiness Retries |
| [k3s_agent_readyz_delay](defaults/main.yml#L41)   | int | `5` |    false  |  Readiness Delay |
| [k3s_agent_recreate](defaults/main.yml#L47)   | bool | `False` |    false  |  Recreate Agent |
| [k3s_cni_bin_dir](defaults/main.yml#L53)   | str | `/opt/cni/bin` |    false  |  CNI Bin Directory |
| [k3s_cni_conf_dir](defaults/main.yml#L59)   | str | `/etc/cni/net.d` |    false  |  CNI Config Directory |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>k3s_agent_version</b></td><td>K3s version to install (should match server version).</td></tr>
<tr><td><b>k3s_agent_server_url</b></td><td>K3s server URL to connect to (use Tailscale IP for security).</td></tr>
<tr><td><b>k3s_agent_token</b></td><td>K3s server token for node authentication (K10 format with CA hash).</td></tr>
<tr><td><b>k3s_agent_node_labels</b></td><td>Labels to apply to this node (list of "key=value" strings).</td></tr>
<tr><td><b>k3s_agent_node_taints</b></td><td>Taints to apply to this node (list of "key=value:effect", e.g., "gpu=true:NoSchedule").</td></tr>
<tr><td><b>k3s_agent_readyz_retries</b></td><td>Number of retries for the node readiness check.</td></tr>
<tr><td><b>k3s_agent_readyz_delay</b></td><td>Delay (seconds) between readiness check retries.</td></tr>
<tr><td><b>k3s_agent_recreate</b></td><td>If true, uninstalls and wipes previous K3s agent before deploying.</td></tr>
<tr><td><b>k3s_cni_bin_dir</b></td><td>Directory for CNI binaries.</td></tr>
<tr><td><b>k3s_cni_conf_dir</b></td><td>Directory for CNI configuration.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate Tailscale IP](tasks/main.yml#L2) | ansible.builtin.assert | False | Validate Tailscale IP address format for secure cluster communication |
| [Validate server parameters](tasks/main.yml#L11) | ansible.builtin.assert | False | Validate required server connection parameters |
| [Check uninstall script](tasks/main.yml#L19) | ansible.builtin.stat | False | Check if K3s agent uninstall script exists for cleanup operations |
| [Recreate agent](tasks/main.yml#L25) | ansible.builtin.command | True | Uninstall existing K3s agent if recreation is requested |
| [Cleanup directories](tasks/main.yml#L34) | ansible.builtin.file | True | Remove K3s data directories for clean installation |
| [Create config dir](tasks/main.yml#L49) | ansible.builtin.file | False | Create K3s configuration directory |
| [Ensure CNI config directory exists](tasks/main.yml#L56) | ansible.builtin.file | False | Ensure CNI config directory exists |
| [Ensure CNI bin directory exists](tasks/main.yml#L63) | ansible.builtin.file | False | Ensure CNI bin directory exists |
| [Ensure K3s agent etc directory exists](tasks/main.yml#L70) | ansible.builtin.file | False | Ensure K3s agent etc directory exists for containerd config |
| [Deploy containerd configuration template](tasks/main.yml#L78) | ansible.builtin.template | False | Deploy containerd configuration template (same as server) |
| [Deploy agent config](tasks/main.yml#L86) | ansible.builtin.template | False | Deploy K3s agent configuration |
| [Install K3s agent](tasks/main.yml#L94) | ansible.builtin.shell | False | Download and install K3s agent with specified version |
| [Create override dir](tasks/main.yml#L109) | ansible.builtin.file | False | Create systemd override directory for K3s agent service customization |
| [Create override](tasks/main.yml#L116) | ansible.builtin.copy | False | Override K3s agent service configuration for clean startup |
| [Reload systemd](tasks/main.yml#L127) | ansible.builtin.systemd | False | Reload systemd configuration after service changes |
| [Start K3s agent](tasks/main.yml#L132) | ansible.builtin.systemd | False | Enable and start K3s agent service |
| [Flush handlers](tasks/main.yml#L139) | ansible.builtin.meta | False | Apply pending service restarts before continuing |
| [Wait for node to be ready](tasks/main.yml#L143) | ansible.builtin.shell | True | Wait for node to appear and become ready on the cluster |
| [Apply node labels](tasks/main.yml#L161) | ansible.builtin.command | True | Apply node labels if specified |
| [Apply node taints](tasks/main.yml#L175) | ansible.builtin.command | True | Apply node taints if specified |
| [Show agent join status](tasks/main.yml#L189) | ansible.builtin.debug | False | Display success message |


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
  Validate_Tailscale_IP0-->|Task| Validate_server_parameters1[validate server parameters]:::task
  Validate_server_parameters1-->|Task| Check_uninstall_script2[check uninstall script]:::task
  Check_uninstall_script2-->|Task| Recreate_agent3[recreate agent<br>When: **k3s agent recreate   bool and k3s agent uninstall<br>script stat exists**]:::task
  Recreate_agent3-->|Task| Cleanup_directories4[cleanup directories<br>When: **k3s agent recreate   bool and k3s agent uninstall<br>script stat exists**]:::task
  Cleanup_directories4-->|Task| Create_config_dir5[create config dir]:::task
  Create_config_dir5-->|Task| Ensure_CNI_config_directory_exists6[ensure cni config directory exists]:::task
  Ensure_CNI_config_directory_exists6-->|Task| Ensure_CNI_bin_directory_exists7[ensure cni bin directory exists]:::task
  Ensure_CNI_bin_directory_exists7-->|Task| Ensure_K3s_agent_etc_directory_exists8[ensure k3s agent etc directory exists]:::task
  Ensure_K3s_agent_etc_directory_exists8-->|Task| Deploy_containerd_configuration_template9[deploy containerd configuration template]:::task
  Deploy_containerd_configuration_template9-->|Task| Deploy_agent_config10[deploy agent config]:::task
  Deploy_agent_config10-->|Task| Install_K3s_agent11[install k3s agent]:::task
  Install_K3s_agent11-->|Task| Create_override_dir12[create override dir]:::task
  Create_override_dir12-->|Task| Create_override13[create override]:::task
  Create_override13-->|Task| Reload_systemd14[reload systemd]:::task
  Reload_systemd14-->|Task| Start_K3s_agent15[start k3s agent]:::task
  Start_K3s_agent15-->|Task| Flush_handlers16[flush handlers]:::task
  Flush_handlers16-->|Task| Wait_for_node_to_be_ready17[wait for node to be ready<br>When: **not ansible check mode**]:::task
  Wait_for_node_to_be_ready17-->|Task| Apply_node_labels18[apply node labels<br>When: **k3s agent node labels   length   0 and not ansible<br>check mode**]:::task
  Apply_node_labels18-->|Task| Apply_node_taints19[apply node taints<br>When: **k3s agent node taints   length   0 and not ansible<br>check mode**]:::task
  Apply_node_taints19-->|Task| Show_agent_join_status20[show agent join status]:::task
  Show_agent_join_status20-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.14

#### Platforms

- **Ubuntu**: ['jammy', 'noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
