<!-- DOCSIBLE START -->

# 📃 Role overview

## k3s_common



Description: Common configurations for K3s nodes (server and agent)






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Shared tasks for K3s nodes including directory setup,
containerd configuration, and registry authentication.


**Options**:


  - **k3s_recreate**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Uninstall and wipe existing K3s before setup.
  
  
  

  - **k3s_commonRestartHandler**
    - **Required**: False
    - **Type**: str
    - **Default**: Restart k3s
  
    - **Description**: Handler name to notify on config changes.
  
  
  

  - **k3s_commonRegistryAuths**
    - **Required**: False
    - **Type**: list
    - **Default**: []
  
    - **Description**: List of registry authentication configs.
  
  
  

  - **k3s_commonContainerdAdditionalRuntimes**
    - **Required**: False
    - **Type**: list
    - **Default**: []
  
    - **Description**: Additional containerd runtimes (nvidia, runsc).
  
  
  

  - **k3s_cniConfDir**
    - **Required**: False
    - **Type**: str
    - **Default**: /etc/cni/net.d
  
    - **Description**: CNI configuration directory.
  
  
  

  - **k3s_cniBinDir**
    - **Required**: False
    - **Type**: str
    - **Default**: /opt/cni/bin
  
    - **Description**: CNI binaries directory.
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Check K3s uninstall script](tasks/main.yml#L2) | ansible.builtin.stat | False | @docsible Check for existing server uninstall script |
| [Check K3s agent uninstall script](tasks/main.yml#L8) | ansible.builtin.stat | False | @docsible Check for existing agent uninstall script |
| [Uninstall K3s (Server)](tasks/main.yml#L14) | ansible.builtin.command | True | @docsible Uninstall K3s server if recreate requested |
| [Uninstall K3s (Agent)](tasks/main.yml#L23) | ansible.builtin.command | True | @docsible Uninstall K3s agent if recreate requested |
| [Cleanup K3s directories](tasks/main.yml#L32) | ansible.builtin.file | True | @docsible Remove K3s data directories |
| [Ensure K3s config directory exists](tasks/main.yml#L46) | ansible.builtin.file | False | @docsible Create K3s configuration directory |
| [Configure K3s registry auth](tasks/main.yml#L53) | ansible.builtin.template | True | @docsible Configure container registry authentication |
| [Ensure CNI config directory exists](tasks/main.yml#L65) | ansible.builtin.file | True | @docsible Create CNI configuration directory |
| [Ensure CNI bin directory exists](tasks/main.yml#L73) | ansible.builtin.file | True | @docsible Create CNI binaries directory |
| [Ensure K3s agent etc directory exists (for containerd)](tasks/main.yml#L81) | ansible.builtin.file | True | @docsible Create containerd configuration directory |
| [Deploy containerd configuration template](tasks/main.yml#L90) | ansible.builtin.template | True | @docsible Deploy containerd configuration template |
| [Remove containerd configuration template](tasks/main.yml#L99) | ansible.builtin.file | True | @docsible Remove containerd template when no extra runtimes are configured |


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

  Start-->|Task| Check_K3s_uninstall_script0[check k3s uninstall script]:::task
  Check_K3s_uninstall_script0-->|Task| Check_K3s_agent_uninstall_script1[check k3s agent uninstall script]:::task
  Check_K3s_agent_uninstall_script1-->|Task| Uninstall_K3s__Server_2[uninstall k3s  server <br>When: **k3s recreate   bool and k3s server uninstall<br>script stat exists and not ansible check mode**]:::task
  Uninstall_K3s__Server_2-->|Task| Uninstall_K3s__Agent_3[uninstall k3s  agent <br>When: **k3s recreate   bool and k3s agent uninstall script<br>stat exists and not ansible check mode**]:::task
  Uninstall_K3s__Agent_3-->|Task| Cleanup_K3s_directories4[cleanup k3s directories<br>When: **k3s recreate   bool**]:::task
  Cleanup_K3s_directories4-->|Task| Ensure_K3s_config_directory_exists5[ensure k3s config directory exists]:::task
  Ensure_K3s_config_directory_exists5-->|Task| Configure_K3s_registry_auth6[configure k3s registry auth<br>When: **k3s commonregistryauths is defined and k3s<br>commonregistryauths   length   0**]:::task
  Configure_K3s_registry_auth6-->|Task| Ensure_CNI_config_directory_exists7[ensure cni config directory exists<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Ensure_CNI_config_directory_exists7-->|Task| Ensure_CNI_bin_directory_exists8[ensure cni bin directory exists<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Ensure_CNI_bin_directory_exists8-->|Task| Ensure_K3s_agent_etc_directory_exists__for_containerd_9[ensure k3s agent etc directory exists  for<br>containerd <br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Ensure_K3s_agent_etc_directory_exists__for_containerd_9-->|Task| Deploy_containerd_configuration_template10[deploy containerd configuration template<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Deploy_containerd_configuration_template10-->|Task| Remove_containerd_configuration_template11[remove containerd configuration template<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length    0**]:::task
  Remove_containerd_configuration_template11-->End
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
