<!-- DOCSIBLE START -->

# 📃 Role overview

## k3s_server



Description: Installs and configures K3s Kubernetes server for homelab usage.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Deploys a single-node K3s server with Tailscale integration.
Manages component disabling (Traefik/ServiceLB), kubeconfig generation,
and local context merging.


**Options**:


  - **k3s_server_version**
    - **Required**: False
    - **Type**: str
    - **Default**: v1.34.3+k3s1
  
    - **Description**: K3s version to install (e.g., v1.34.3+k3s1).
  
  
  

  - **k3s_server_disable_traefik**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Disables the default Traefik ingress controller.
  
  
  

  - **k3s_server_disable_servicelb**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Disables the default ServiceLB load balancer.
  
  
  

  - **k3s_server_kubeconfig_mode**
    - **Required**: False
    - **Type**: str
    - **Default**: 0644
  
    - **Description**: File permission mode for the generated kubeconfig on the server.
  
  
  

  - **k3s_server_node_token_timeout**
    - **Required**: False
    - **Type**: int
    - **Default**: 180
  
    - **Description**: Timeout (seconds) to wait for K3s generated config/token presence.
  
  
  

  - **k3s_server_readyz_retries**
    - **Required**: False
    - **Type**: int
    - **Default**: 30
  
    - **Description**: Number of retries for the API server readiness check.
  
  
  

  - **k3s_server_readyz_delay**
    - **Required**: False
    - **Type**: int
    - **Default**: 2
  
    - **Description**: Delay (seconds) between readiness check retries.
  
  
  

  - **k3s_server_recreate**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: If true, uninstalls and wipes previous K3s installation before deploying.
  
  
  

  - **k3s_server_copy_kubeconfig_local**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: If true, copies the generated kubeconfig to the Ansible controller.
  
  
  

  - **k3s_server_local_kubeconfig_path**
    - **Required**: False
    - **Type**: str
    - **Default**: ~/.kube/config
  
    - **Description**: Local path where the kubeconfig should be saved.
  
  
  



</details>




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [k3s_server_version](defaults/main.yml#L5)   | str | `v1.34.3+k3s1` |    false  |  K3s Version |
| [k3s_server_disable_traefik](defaults/main.yml#L10)   | bool | `True` |    false  |  Disable Traefik |
| [k3s_server_disable_servicelb](defaults/main.yml#L15)   | bool | `True` |    false  |  Disable ServiceLB |
| [k3s_server_kubeconfig_mode](defaults/main.yml#L20)   | str | `0600` |    false  |  Kubeconfig Mode |
| [k3s_server_node_token_timeout](defaults/main.yml#L25)   | int | `180` |    false  |  Token Timeout |
| [k3s_server_readyz_retries](defaults/main.yml#L30)   | int | `30` |    false  |  Readiness Retries |
| [k3s_server_readyz_delay](defaults/main.yml#L35)   | int | `2` |    false  |  Readiness Delay |
| [k3s_server_recreate](defaults/main.yml#L40)   | bool | `True` |    false  |  Recreate Cluster |
| [k3s_server_copy_kubeconfig_local](defaults/main.yml#L45)   | bool | `True` |    false  |  Copy Kubeconfig Local |
| [k3s_server_local_kubeconfig_path](defaults/main.yml#L50)   | str | `{{ lookup('env', 'HOME') }}/.kube/config` |    false  |  Local Kubeconfig Path |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>k3s_server_version</b></td><td>K3s version to install (e.g., v1.34.3+k3s1).</td></tr>
<tr><td><b>k3s_server_disable_traefik</b></td><td>Disables the default Traefik ingress controller.</td></tr>
<tr><td><b>k3s_server_disable_servicelb</b></td><td>Disables the default ServiceLB load balancer.</td></tr>
<tr><td><b>k3s_server_kubeconfig_mode</b></td><td>File permission mode for the generated kubeconfig on the server.</td></tr>
<tr><td><b>k3s_server_node_token_timeout</b></td><td>Timeout (seconds) to wait for K3s generated config/token presence.</td></tr>
<tr><td><b>k3s_server_readyz_retries</b></td><td>Number of retries for the API server readiness check.</td></tr>
<tr><td><b>k3s_server_readyz_delay</b></td><td>Delay (seconds) between readiness check retries.</td></tr>
<tr><td><b>k3s_server_recreate</b></td><td>If true, uninstalls and wipes previous K3s installation before deploying.</td></tr>
<tr><td><b>k3s_server_copy_kubeconfig_local</b></td><td>If true, copies the generated kubeconfig to the Ansible controller.</td></tr>
<tr><td><b>k3s_server_local_kubeconfig_path</b></td><td>Local path where the kubeconfig should be saved.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate IP](tasks/main.yml#L2) | ansible.builtin.assert | False | Validate Tailscale IP address format for secure cluster communication |
| [Check uninstall script](tasks/main.yml#L10) | ansible.builtin.stat | False | Check if K3s uninstall script exists for cleanup operations |
| [Recreate cluster](tasks/main.yml#L15) | ansible.builtin.command | True | Uninstall existing K3s cluster if recreation is requested |
| [Cleanup directories](tasks/main.yml#L23) | ansible.builtin.file | True | Remove K3s data directories for clean installation |
| [Create config dir](tasks/main.yml#L37) | ansible.builtin.file | False | Create K3s configuration directory |
| [Ensure K3s log directory exists](tasks/main.yml#L43) | ansible.builtin.file | False | Create secure log directory for K3s components |
| [Ensure K3s audit log file exists with restrictive permissions](tasks/main.yml#L51) | ansible.builtin.file | False | Create audit log file with strict permissions for security |
| [Deploy K3s audit policy](tasks/main.yml#L60) | ansible.builtin.template | False | Deploy Kubernetes audit policy for API security monitoring |
| [Deploy config](tasks/main.yml#L67) | ansible.builtin.template | False | Deploy K3s server configuration with security hardening |
| [Install K3s](tasks/main.yml#L74) | ansible.builtin.shell | False | Download and install K3s with specified version |
| [Create override dir](tasks/main.yml#L84) | ansible.builtin.file | False | Create systemd override directory for K3s service customization |
| [Create override](tasks/main.yml#L90) | ansible.builtin.copy | False | Override K3s service configuration for clean startup |
| [Remove env file](tasks/main.yml#L100) | ansible.builtin.file | False | Remove legacy environment file to prevent conflicts |
| [Reload systemd (k3s)](tasks/main.yml#L106) | ansible.builtin.systemd | False | Reload systemd configuration after service changes |
| [Start K3s](tasks/main.yml#L110) | ansible.builtin.systemd | False | Enable and start K3s service |
| [Flush handlers](tasks/main.yml#L116) | ansible.builtin.meta | False | Apply pending service restarts before continuing |
| [Wait for kubeconfig](tasks/main.yml#L119) | ansible.builtin.wait_for | True | Wait for K3s to generate admin kubeconfig file |
| [Read kubeconfig](tasks/main.yml#L125) | ansible.builtin.slurp | False | Read K3s admin kubeconfig for Tailscale integration |
| [Build canonical config](tasks/main.yml#L130) | ansible.builtin.set_fact | False | Replace localhost with Tailscale IP for remote cluster access |
| [Write server config](tasks/main.yml#L136) | ansible.builtin.copy | False | Store Tailscale-enabled kubeconfig for server access |
| [Create user kube dir](tasks/main.yml#L144) | ansible.builtin.file | False | Create secure kubeconfig directory for ansible user |
| [Write user config](tasks/main.yml#L152) | ansible.builtin.copy | False | Deploy Tailscale-enabled kubeconfig for ansible user |
| [Wait for apiserver](tasks/main.yml#L160) | ansible.builtin.command | True | Verify Kubernetes API server is ready before proceeding |
| [Remove Traefik](tasks/main.yml#L172) | ansible.builtin.command | True | Remove default Traefik ingress controller if disabled |
| [Copy local config](tasks/main.yml#L185) | block | True | Copy kubeconfig to local machine for remote cluster management |
| [Create local dir](tasks/main.yml#L194) | ansible.builtin.file | False | Create local directory for kubeconfig storage |
| [Fetch config](tasks/main.yml#L200) | ansible.builtin.slurp | False | Retrieve Tailscale-enabled kubeconfig from server |
| [Parse config](tasks/main.yml#L207) | ansible.builtin.set_fact | False | Customize kubeconfig with unique context names for multi-cluster support |
| [Write local config](tasks/main.yml#L217) | ansible.builtin.copy | False | Save customized kubeconfig to local file |
| [Show config info](tasks/main.yml#L223) | ansible.builtin.debug | False | Display success message with kubeconfig location |


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

  Start-->|Task| Validate_IP0[validate ip]:::task
  Validate_IP0-->|Task| Check_uninstall_script1[check uninstall script]:::task
  Check_uninstall_script1-->|Task| Recreate_cluster2[recreate cluster<br>When: **k3s server recreate   bool and k3s uninstall<br>script stat exists**]:::task
  Recreate_cluster2-->|Task| Cleanup_directories3[cleanup directories<br>When: **k3s server recreate   bool and k3s uninstall<br>script stat exists**]:::task
  Cleanup_directories3-->|Task| Create_config_dir4[create config dir]:::task
  Create_config_dir4-->|Task| Ensure_K3s_log_directory_exists5[ensure k3s log directory exists]:::task
  Ensure_K3s_log_directory_exists5-->|Task| Ensure_K3s_audit_log_file_exists_with_restrictive_permissions6[ensure k3s audit log file exists with restrictive<br>permissions]:::task
  Ensure_K3s_audit_log_file_exists_with_restrictive_permissions6-->|Task| Deploy_K3s_audit_policy7[deploy k3s audit policy]:::task
  Deploy_K3s_audit_policy7-->|Task| Deploy_config8[deploy config]:::task
  Deploy_config8-->|Task| Install_K3s9[install k3s]:::task
  Install_K3s9-->|Task| Create_override_dir10[create override dir]:::task
  Create_override_dir10-->|Task| Create_override11[create override]:::task
  Create_override11-->|Task| Remove_env_file12[remove env file]:::task
  Remove_env_file12-->|Task| Reload_systemd__k3s_13[reload systemd  k3s ]:::task
  Reload_systemd__k3s_13-->|Task| Start_K3s14[start k3s]:::task
  Start_K3s14-->|Task| Flush_handlers15[flush handlers]:::task
  Flush_handlers15-->|Task| Wait_for_kubeconfig16[wait for kubeconfig<br>When: **not ansible check mode**]:::task
  Wait_for_kubeconfig16-->|Task| Read_kubeconfig17[read kubeconfig]:::task
  Read_kubeconfig17-->|Task| Build_canonical_config18[build canonical config]:::task
  Build_canonical_config18-->|Task| Write_server_config19[write server config]:::task
  Write_server_config19-->|Task| Create_user_kube_dir20[create user kube dir]:::task
  Create_user_kube_dir20-->|Task| Write_user_config21[write user config]:::task
  Write_user_config21-->|Task| Wait_for_apiserver22[wait for apiserver<br>When: **not ansible check mode**]:::task
  Wait_for_apiserver22-->|Task| Remove_Traefik23[remove traefik<br>When: **not ansible check mode and k3s server disable<br>traefik   bool**]:::task
  Remove_Traefik23-->|Block Start| Copy_local_config24_block_start_0[[copy local config<br>When: **k3s server copy kubeconfig local   default true   <br>bool and not ansible check mode**]]:::block
  Copy_local_config24_block_start_0-->|Task| Create_local_dir0[create local dir]:::task
  Create_local_dir0-->|Task| Fetch_config1[fetch config]:::task
  Fetch_config1-->|Task| Parse_config2[parse config]:::task
  Parse_config2-->|Task| Write_local_config3[write local config]:::task
  Write_local_config3-->|Task| Show_config_info4[show config info]:::task
  Show_config_info4-.->|End of Block| Copy_local_config24_block_start_0
  Show_config_info4-->|Rescue Start| Copy_local_config24_rescue_start_0[copy local config<br>When: **k3s server copy kubeconfig local   default true   <br>bool and not ansible check mode**]:::rescue
  Copy_local_config24_rescue_start_0-->|Task| Report_kubeconfig_copy_failure0[report kubeconfig copy failure]:::task
  Report_kubeconfig_copy_failure0-->|Task| Fail_kubeconfig_copy1[fail kubeconfig copy]:::task
  Fail_kubeconfig_copy1-.->|End of Rescue Block| Copy_local_config24_block_start_0
  Fail_kubeconfig_copy1-->End
```





## Author Information
Roura

#### License

MIT

#### Minimum Ansible Version

2.20.0

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
