<!-- DOCSIBLE START -->

# 📃 Role overview

## nvidia_gpu



Description: Configures NVIDIA GPUs for K3s, including drivers, container toolkit, and device plugin.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Manages NVIDIA drivers, container toolkit, and device plugin installation.
Supports host setup, cluster setup, and headless X11 configurations.


**Options**:


  - **nvidia_gpu_setup**
    - **Required**: False
    - **Type**: str
    - **Default**: auto
  
    - **Description**: Control mode for GPU setup ('auto', 'true', 'false').
  
      - **Choices**:
    
          - auto
    
          - true
    
          - false
    
  
  
  

  - **nvidia_gpu_driver_package**
    - **Required**: False
    - **Type**: str
    - **Default**: auto
  
    - **Description**: Specific driver package to install or "auto" for detection.
  
  
  

  - **nvidia_gpu_driver_fallback**
    - **Required**: False
    - **Type**: str
    - **Default**: nvidia-driver-535
  
    - **Description**: Fallback driver if auto-detection fails.
  
  
  

  - **nvidia_gpu_toolkit_repo_url**
    - **Required**: False
    - **Type**: str
    - **Default**: https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list
  
    - **Description**: Repository URL for NVIDIA Container Toolkit.
  
  
  

  - **nvidia_gpu_toolkit_gpg_url**
    - **Required**: False
    - **Type**: str
    - **Default**: https://nvidia.github.io/libnvidia-container/gpgkey
  
    - **Description**: GPG key URL for the toolkit repository.
  
  
  

  - **nvidia_gpu_device_plugin_version**
    - **Required**: False
    - **Type**: str
    - **Default**: 0.14.3
  
    - **Description**: Version of the NVIDIA device plugin Helm chart.
  
  
  

  - **nvidia_gpu_device_plugin_repo**
    - **Required**: False
    - **Type**: str
    - **Default**: https://nvidia.github.io/k8s-device-plugin
  
    - **Description**: Helm repository for the device plugin.
  
  
  

  - **nvidia_gpu_reboot_timeout**
    - **Required**: False
    - **Type**: int
    - **Default**: 600
  
    - **Description**: Timeout (seconds) for rebooting after driver installation.
  
  
  

  - **nvidia_gpu_headless_x11_enabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Enables X11 services for headless GPU management (fan control, etc.).
  
  
  

  - **nvidia_gpu_pci_bus_id**
    - **Required**: False
    - **Type**: str
    - **Default**: 1:0:0
  
    - **Description**: PCI Bus ID of the GPU for xorg.conf generation.
  
  
  

  - **nvidia_gpu_coolbits**
    - **Required**: False
    - **Type**: str
    - **Default**: 28
  
    - **Description**: Coolbits value for unlocking GPU control (fans, clocks).
  
  
  



</details>




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [nvidia_gpu_setup](defaults/main.yml#L6)   | str | `auto` |    false  |  GPU Setup Mode |
| [nvidia_gpu_driver_package](defaults/main.yml#L12)   | str | `auto` |    false  |  Driver Package |
| [nvidia_gpu_driver_fallback](defaults/main.yml#L18)   | str | `nvidia-driver-535` |    false  |  Fallback Driver |
| [nvidia_gpu_toolkit_repo_url](defaults/main.yml#L24)   | str | `https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list` |    false  |  Toolkit Repo URL |
| [nvidia_gpu_toolkit_gpg_url](defaults/main.yml#L30)   | str | `https://nvidia.github.io/libnvidia-container/gpgkey` |    false  |  Toolkit GPG Key |
| [nvidia_gpu_device_plugin_version](defaults/main.yml#L36)   | str | `0.14.3` |    false  |  Device Plugin Version |
| [nvidia_gpu_device_plugin_repo](defaults/main.yml#L42)   | str | `https://nvidia.github.io/k8s-device-plugin` |    false  |  Device Plugin Repo |
| [nvidia_gpu_reboot_timeout](defaults/main.yml#L48)   | int | `600` |    false  |  Reboot Timeout |
| [nvidia_gpu_headless_x11_enabled](defaults/main.yml#L54)   | bool | `True` |    false  |  Headless X11 |
| [nvidia_gpu_pci_bus_id](defaults/main.yml#L60)   | str | `1:0:0` |    false  |  PCI Bus ID |
| [nvidia_gpu_coolbits](defaults/main.yml#L66)   | str | `28` |    false  |  Coolbits |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>nvidia_gpu_setup</b></td><td>Control mode for GPU setup ('auto', 'true', 'false').</td></tr>
<tr><td><b>nvidia_gpu_driver_package</b></td><td>Specific driver package to install or "auto" for detection.</td></tr>
<tr><td><b>nvidia_gpu_driver_fallback</b></td><td>Fallback driver if auto-detection fails.</td></tr>
<tr><td><b>nvidia_gpu_toolkit_repo_url</b></td><td>Repository URL for NVIDIA Container Toolkit.</td></tr>
<tr><td><b>nvidia_gpu_toolkit_gpg_url</b></td><td>GPG key URL for the toolkit repository.</td></tr>
<tr><td><b>nvidia_gpu_device_plugin_version</b></td><td>Version of the NVIDIA device plugin Helm chart.</td></tr>
<tr><td><b>nvidia_gpu_device_plugin_repo</b></td><td>Helm repository for the device plugin.</td></tr>
<tr><td><b>nvidia_gpu_reboot_timeout</b></td><td>Timeout (seconds) for rebooting after driver installation.</td></tr>
<tr><td><b>nvidia_gpu_headless_x11_enabled</b></td><td>Enables X11 services for headless GPU management (fan control, etc.).</td></tr>
<tr><td><b>nvidia_gpu_pci_bus_id</b></td><td>PCI Bus ID of the GPU for xorg.conf generation.</td></tr>
<tr><td><b>nvidia_gpu_coolbits</b></td><td>Coolbits value for unlocking GPU control (fans, clocks).</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/cluster.yml

| Name | Module | Has Conditions | Tags |
| ---- | ------ | -------------- | -----|
| [NVIDIA GPU cluster setup](tasks/cluster.yml#L2) | block | False | cluster,nvidia |
| [Create temporary values file for device plugin](tasks/cluster.yml#L5) | ansible.builtin.tempfile | False |  |
| [Copy device plugin values to temp file](tasks/cluster.yml#L11) | ansible.builtin.copy | False |  |
| [Install NVIDIA device plugin via Helm](tasks/cluster.yml#L17) | kubernetes.core.helm | False |  |
| [Wait for device plugin daemonset](tasks/cluster.yml#L27) | ansible.builtin.command | False |  |
| [Check GPU resources available](tasks/cluster.yml#L35) | ansible.builtin.shell | False |  |
| [Debug GPU resources](tasks/cluster.yml#L44) | ansible.builtin.debug | False |  |

#### File: tasks/headless_optimization.yml

| Name | Module | Has Conditions | Tags |
| ---- | ------ | -------------- | -----|
| [NVIDIA GPU headless optimization setup](tasks/headless_optimization.yml#L2) | block | True | nvidia,gpu,nvidia-headless |
| [Install X11 packages for headless GPU management](tasks/headless_optimization.yml#L6) | ansible.builtin.apt | False |  |
| [Deploy xorg.conf with coolbits for GPU management](tasks/headless_optimization.yml#L15) | ansible.builtin.template | False |  |
| [Deploy NVIDIA persistence mode systemd service](tasks/headless_optimization.yml#L24) | ansible.builtin.copy | False |  |
| [Deploy NVIDIA X server systemd service](tasks/headless_optimization.yml#L33) | ansible.builtin.copy | False |  |
| [Reload systemd daemon](tasks/headless_optimization.yml#L42) | ansible.builtin.systemd | True |  |
| [Enable and start NVIDIA persistence mode service](tasks/headless_optimization.yml#L47) | ansible.builtin.systemd | False |  |
| [Enable and start NVIDIA X server service](tasks/headless_optimization.yml#L53) | ansible.builtin.systemd | True |  |
| [Wait for X server to be ready](tasks/headless_optimization.yml#L60) | ansible.builtin.wait_for | True |  |

#### File: tasks/host.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [NVIDIA GPU host setup](tasks/host.yml#L2) | block | False | host,nvidia |  |
| [Ensure pciutils installed for lspci](tasks/host.yml#L5) | ansible.builtin.apt | False |  |  |
| [Normalize NVIDIA GPU setup mode](tasks/host.yml#L12) | ansible.builtin.set_fact | True |  | Ensure pciutils for GPU detection |
| [Get PCI Vendor IDs](tasks/host.yml#L17) | ansible.builtin.shell | False |  |  |
| [Debug PCI Vendors](tasks/host.yml#L22) | ansible.builtin.debug | False |  |  |
| [Detect NVIDIA GPU presence](tasks/host.yml#L34) | ansible.builtin.set_fact | False |  |  |
| [Set GPU Active Fact (Auto)](tasks/host.yml#L48) | ansible.builtin.set_fact | True |  |  |
| [Set GPU Active Fact (Forced)](tasks/host.yml#L54) | ansible.builtin.set_fact | True |  |  |
| [Fail if forced but missing](tasks/host.yml#L60) | ansible.builtin.fail | True |  |  |
| [Set GPU Active Fact (Disabled)](tasks/host.yml#L67) | ansible.builtin.set_fact | True |  |  |
| [Install driver tools](tasks/host.yml#L73) | ansible.builtin.apt | False |  |  |
| [Detect NVIDIA driver](tasks/host.yml#L80) | ansible.builtin.shell | True |  |  |
| [Set detected driver](tasks/host.yml#L90) | ansible.builtin.set_fact | True |  |  |
| [Set driver fallback](tasks/host.yml#L97) | ansible.builtin.set_fact | True |  |  |
| [Set manual driver](tasks/host.yml#L107) | ansible.builtin.set_fact | True |  |  |
| [Blacklist nouveau driver](tasks/host.yml#L113) | ansible.builtin.copy | True |  |  |
| [Update initramfs if blacklist changed](tasks/host.yml#L122) | ansible.builtin.command | True |  |  |
| [Calculate nvidia-utils package name](tasks/host.yml#L127) | ansible.builtin.set_fact | True |  | Deriva el paquete nvidia-utils del driver detectado (ej: nvidia-driver-535 -> nvidia-utils-535) |
| [Check if NVIDIA packages are in broken state](tasks/host.yml#L131) | ansible.builtin.shell | True |  |  |
| [Force remove broken NVIDIA packages](tasks/host.yml#L136) | ansible.builtin.shell | True |  |  |
| [Install NVIDIA Driver](tasks/host.yml#L148) | ansible.builtin.apt | True |  |  |
| [Reboot if driver installed](tasks/host.yml#L157) | ansible.builtin.reboot | True |  |  |
| [Add Toolkit GPG Key](tasks/host.yml#L166) | ansible.builtin.apt_key | True |  |  |
| [Add Toolkit Repository](tasks/host.yml#L171) | ansible.builtin.get_url | True |  |  |
| [Install Toolkit](tasks/host.yml#L178) | ansible.builtin.apt | True |  |  |
| [Ensure containerd config dir exists](tasks/host.yml#L185) | ansible.builtin.file | True |  |  |
| [Deploy containerd config template](tasks/host.yml#L191) | ansible.builtin.template | True |  |  |


## Task Flow Graphs



### Graph for cluster.yml

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

  Start-->|Block Start| NVIDIA_GPU_cluster_setup0_block_start_0[[nvidia gpu cluster setup]]:::block
  NVIDIA_GPU_cluster_setup0_block_start_0-->|Task| Create_temporary_values_file_for_device_plugin0[create temporary values file for device plugin]:::task
  Create_temporary_values_file_for_device_plugin0-->|Task| Copy_device_plugin_values_to_temp_file1[copy device plugin values to temp file]:::task
  Copy_device_plugin_values_to_temp_file1-->|Task| Install_NVIDIA_device_plugin_via_Helm2[install nvidia device plugin via helm]:::task
  Install_NVIDIA_device_plugin_via_Helm2-->|Task| Wait_for_device_plugin_daemonset3[wait for device plugin daemonset]:::task
  Wait_for_device_plugin_daemonset3-->|Task| Check_GPU_resources_available4[check gpu resources available]:::task
  Check_GPU_resources_available4-->|Task| Debug_GPU_resources5[debug gpu resources]:::task
  Debug_GPU_resources5-.->|End of Block| NVIDIA_GPU_cluster_setup0_block_start_0
  Debug_GPU_resources5-->|Rescue Start| NVIDIA_GPU_cluster_setup0_rescue_start_0[nvidia gpu cluster setup]:::rescue
  NVIDIA_GPU_cluster_setup0_rescue_start_0-->|Task| Report_NVIDIA_GPU_cluster_setup_failure0[report nvidia gpu cluster setup failure]:::task
  Report_NVIDIA_GPU_cluster_setup_failure0-->|Task| Fail_NVIDIA_GPU_cluster_setup1[fail nvidia gpu cluster setup]:::task
  Fail_NVIDIA_GPU_cluster_setup1-.->|End of Rescue Block| NVIDIA_GPU_cluster_setup0_block_start_0
  Fail_NVIDIA_GPU_cluster_setup1-->End
```


### Graph for headless_optimization.yml

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

  Start-->|Block Start| NVIDIA_GPU_headless_optimization_setup0_block_start_0[[nvidia gpu headless optimization setup<br>When: **nvidia gpu active   default false    bool**]]:::block
  NVIDIA_GPU_headless_optimization_setup0_block_start_0-->|Task| Install_X11_packages_for_headless_GPU_management0[install x11 packages for headless gpu management]:::task
  Install_X11_packages_for_headless_GPU_management0-->|Task| Deploy_xorg_conf_with_coolbits_for_GPU_management1[deploy xorg conf with coolbits for gpu management]:::task
  Deploy_xorg_conf_with_coolbits_for_GPU_management1-->|Task| Deploy_NVIDIA_persistence_mode_systemd_service2[deploy nvidia persistence mode systemd service]:::task
  Deploy_NVIDIA_persistence_mode_systemd_service2-->|Task| Deploy_NVIDIA_X_server_systemd_service3[deploy nvidia x server systemd service]:::task
  Deploy_NVIDIA_X_server_systemd_service3-->|Task| Reload_systemd_daemon4[reload systemd daemon<br>When: **nvidia gpu persistence service changed or nvidia<br>gpu xorg service changed**]:::task
  Reload_systemd_daemon4-->|Task| Enable_and_start_NVIDIA_persistence_mode_service5[enable and start nvidia persistence mode service]:::task
  Enable_and_start_NVIDIA_persistence_mode_service5-->|Task| Enable_and_start_NVIDIA_X_server_service6[enable and start nvidia x server service<br>When: **nvidia gpu headless x11 enabled   default true   <br>bool**]:::task
  Enable_and_start_NVIDIA_X_server_service6-->|Task| Wait_for_X_server_to_be_ready7[wait for x server to be ready<br>When: **nvidia gpu headless x11 enabled   default true   <br>bool**]:::task
  Wait_for_X_server_to_be_ready7-.->|End of Block| NVIDIA_GPU_headless_optimization_setup0_block_start_0
  Wait_for_X_server_to_be_ready7-->|Rescue Start| NVIDIA_GPU_headless_optimization_setup0_rescue_start_0[nvidia gpu headless optimization setup<br>When: **nvidia gpu active   default false    bool**]:::rescue
  NVIDIA_GPU_headless_optimization_setup0_rescue_start_0-->|Task| Report_NVIDIA_GPU_headless_optimization_failure0[report nvidia gpu headless optimization failure]:::task
  Report_NVIDIA_GPU_headless_optimization_failure0-->|Task| Fail_NVIDIA_GPU_headless_optimization1[fail nvidia gpu headless optimization]:::task
  Fail_NVIDIA_GPU_headless_optimization1-.->|End of Rescue Block| NVIDIA_GPU_headless_optimization_setup0_block_start_0
  Fail_NVIDIA_GPU_headless_optimization1-->End
```


### Graph for host.yml

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

  Start-->|Block Start| NVIDIA_GPU_host_setup0_block_start_0[[nvidia gpu host setup]]:::block
  NVIDIA_GPU_host_setup0_block_start_0-->|Task| Ensure_pciutils_installed_for_lspci0[ensure pciutils installed for lspci]:::task
  Ensure_pciutils_installed_for_lspci0-->|Task| Normalize_NVIDIA_GPU_setup_mode1[normalize nvidia gpu setup mode<br>When: **nvidia gpu setup mode is not defined**]:::task
  Normalize_NVIDIA_GPU_setup_mode1-->|Task| Get_PCI_Vendor_IDs2[get pci vendor ids]:::task
  Get_PCI_Vendor_IDs2-->|Task| Debug_PCI_Vendors3[debug pci vendors]:::task
  Debug_PCI_Vendors3-->|Task| Detect_NVIDIA_GPU_presence4[detect nvidia gpu presence]:::task
  Detect_NVIDIA_GPU_presence4-->|Task| Set_GPU_Active_Fact__Auto_5[set gpu active fact  auto <br>When: **nvidia gpu setup mode     auto**]:::task
  Set_GPU_Active_Fact__Auto_5-->|Task| Set_GPU_Active_Fact__Forced_6[set gpu active fact  forced <br>When: **nvidia gpu setup mode     true**]:::task
  Set_GPU_Active_Fact__Forced_6-->|Task| Fail_if_forced_but_missing7[fail if forced but missing<br>When: **nvidia gpu setup mode     true  and not  nvidia<br>gpu present   default false**]:::task
  Fail_if_forced_but_missing7-->|Task| Set_GPU_Active_Fact__Disabled_8[set gpu active fact  disabled <br>When: **nvidia gpu setup mode     false**]:::task
  Set_GPU_Active_Fact__Disabled_8-->|Task| Install_driver_tools9[install driver tools]:::task
  Install_driver_tools9-->|Task| Detect_NVIDIA_driver10[detect nvidia driver<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver package     auto**]:::task
  Detect_NVIDIA_driver10-->|Task| Set_detected_driver11[set detected driver<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver package     auto  and nvidia gpu<br>detected driver stdout   length   0**]:::task
  Set_detected_driver11-->|Task| Set_driver_fallback12[set driver fallback<br>When: **nvidia gpu driver package     auto  and  nvidia<br>gpu detected driver skipped is defined and nvidia<br>gpu detected driver skipped  or  nvidia gpu<br>detected driver stdout   length    0  and nvidia<br>gpu active   default false    bool**]:::task
  Set_driver_fallback12-->|Task| Set_manual_driver13[set manual driver<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver package     auto**]:::task
  Set_manual_driver13-->|Task| Blacklist_nouveau_driver14[blacklist nouveau driver<br>When: **nvidia gpu active   default false    bool**]:::task
  Blacklist_nouveau_driver14-->|Task| Update_initramfs_if_blacklist_changed15[update initramfs if blacklist changed<br>When: **nvidia gpu blacklist nouveau changed**]:::task
  Update_initramfs_if_blacklist_changed15-->|Task| Calculate_nvidia_utils_package_name16[calculate nvidia utils package name<br>When: **nvidia gpu active   default false    bool**]:::task
  Calculate_nvidia_utils_package_name16-->|Task| Check_if_NVIDIA_packages_are_in_broken_state17[check if nvidia packages are in broken state<br>When: **nvidia gpu active   default false    bool**]:::task
  Check_if_NVIDIA_packages_are_in_broken_state17-->|Task| Force_remove_broken_NVIDIA_packages18[force remove broken nvidia packages<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu broken check stdout   int   0**]:::task
  Force_remove_broken_NVIDIA_packages18-->|Task| Install_NVIDIA_Driver19[install nvidia driver<br>When: **nvidia gpu active   default false    bool**]:::task
  Install_NVIDIA_Driver19-->|Task| Reboot_if_driver_installed20[reboot if driver installed<br>When: **nvidia gpu driver install changed or nvidia gpu<br>blacklist nouveau changed**]:::task
  Reboot_if_driver_installed20-->|Task| Add_Toolkit_GPG_Key21[add toolkit gpg key<br>When: **nvidia gpu active   default false    bool**]:::task
  Add_Toolkit_GPG_Key21-->|Task| Add_Toolkit_Repository22[add toolkit repository<br>When: **nvidia gpu active   default false    bool**]:::task
  Add_Toolkit_Repository22-->|Task| Install_Toolkit23[install toolkit<br>When: **nvidia gpu active   default false    bool**]:::task
  Install_Toolkit23-->|Task| Ensure_containerd_config_dir_exists24[ensure containerd config dir exists<br>When: **nvidia gpu active   default false    bool**]:::task
  Ensure_containerd_config_dir_exists24-->|Task| Deploy_containerd_config_template25[deploy containerd config template<br>When: **nvidia gpu active   default false    bool**]:::task
  Deploy_containerd_config_template25-.->|End of Block| NVIDIA_GPU_host_setup0_block_start_0
  Deploy_containerd_config_template25-->|Rescue Start| NVIDIA_GPU_host_setup0_rescue_start_0[nvidia gpu host setup]:::rescue
  NVIDIA_GPU_host_setup0_rescue_start_0-->|Task| Report_NVIDIA_GPU_host_setup_failure0[report nvidia gpu host setup failure]:::task
  Report_NVIDIA_GPU_host_setup_failure0-->|Task| Fail_NVIDIA_GPU_host_setup1[fail nvidia gpu host setup]:::task
  Fail_NVIDIA_GPU_host_setup1-.->|End of Rescue Block| NVIDIA_GPU_host_setup0_block_start_0
  Fail_NVIDIA_GPU_host_setup1-->End
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
