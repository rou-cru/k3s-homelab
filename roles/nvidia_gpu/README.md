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
    - **Default**: none
  
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
| [nvidia_gpu_setup](defaults/main.yml#L5)   | str | `auto` |    false  |  GPU Setup Mode |
| [nvidia_gpu_driver_package](defaults/main.yml#L10)   | str | `auto` |    false  |  Driver Package |
| [nvidia_gpu_driver_fallback](defaults/main.yml#L15)   | str | `nvidia-driver-535` |    false  |  Fallback Driver |
| [nvidia_gpu_toolkit_repo_url](defaults/main.yml#L20)   | str | `https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list` |    false  |  Toolkit Repo URL |
| [nvidia_gpu_toolkit_gpg_url](defaults/main.yml#L25)   | str | `https://nvidia.github.io/libnvidia-container/gpgkey` |    false  |  Toolkit GPG Key |
| [nvidia_gpu_device_plugin_version](defaults/main.yml#L30)   | str | `0.14.3` |    false  |  Device Plugin Version |
| [nvidia_gpu_device_plugin_repo](defaults/main.yml#L35)   | str | `https://nvidia.github.io/k8s-device-plugin` |    false  |  Device Plugin Repo |
| [nvidia_gpu_reboot_timeout](defaults/main.yml#L40)   | int | `600` |    false  |  Reboot Timeout |
| [nvidia_gpu_headless_x11_enabled](defaults/main.yml#L45)   | bool | `True` |    false  |  Headless X11 |
| [nvidia_gpu_pci_bus_id](defaults/main.yml#L50)   | str | `1:0:0` |    false  |  PCI Bus ID |
| [nvidia_gpu_coolbits](defaults/main.yml#L55)   | str | `28` |    false  |  Coolbits |
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
| [NVIDIA GPU cluster setup](tasks/cluster.yml#L1) | block | False | cluster,nvidia |
| [Create temp values](tasks/cluster.yml#L4) | ansible.builtin.tempfile | False |  |
| [Copy values](tasks/cluster.yml#L9) | ansible.builtin.copy | False |  |
| [Install device plugin](tasks/cluster.yml#L14) | kubernetes.core.helm | False |  |
| [Wait for daemonset](tasks/cluster.yml#L23) | ansible.builtin.command | False |  |
| [Check GPU resources](tasks/cluster.yml#L30) | ansible.builtin.shell | False |  |
| [Debug GPU resources](tasks/cluster.yml#L38) | ansible.builtin.debug | False |  |

#### File: tasks/headless_optimization.yml

| Name | Module | Has Conditions | Tags |
| ---- | ------ | -------------- | -----|
| [NVIDIA GPU headless optimization setup](tasks/headless_optimization.yml#L1) | block | True | nvidia,gpu,nvidia-headless |
| [Install X11 deps](tasks/headless_optimization.yml#L5) | ansible.builtin.apt | False |  |
| [Configure xorg](tasks/headless_optimization.yml#L13) | ansible.builtin.template | False |  |
| [Deploy persistence svc](tasks/headless_optimization.yml#L21) | ansible.builtin.copy | False |  |
| [Deploy Xorg svc](tasks/headless_optimization.yml#L29) | ansible.builtin.copy | False |  |
| [Reload systemd (nvidia)](tasks/headless_optimization.yml#L37) | ansible.builtin.systemd | True |  |
| [Start persistence svc](tasks/headless_optimization.yml#L41) | ansible.builtin.systemd | False |  |
| [Start Xorg svc](tasks/headless_optimization.yml#L46) | ansible.builtin.systemd | True |  |
| [Wait for X server](tasks/headless_optimization.yml#L52) | ansible.builtin.wait_for | True |  |

#### File: tasks/host.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [NVIDIA GPU host setup](tasks/host.yml#L1) | block | False | host,nvidia |  |
| [Install pciutils](tasks/host.yml#L4) | ansible.builtin.apt | False |  |  |
| [Normalize setup mode](tasks/host.yml#L11) | ansible.builtin.set_fact | True |  | Ensure pciutils for GPU detection |
| [Get PCI vendors](tasks/host.yml#L15) | ansible.builtin.shell | False |  |  |
| [Debug PCI Vendors](tasks/host.yml#L19) | ansible.builtin.debug | False |  |  |
| [Detect GPU](tasks/host.yml#L31) | ansible.builtin.set_fact | False |  |  |
| [Set GPU active (auto)](tasks/host.yml#L45) | ansible.builtin.set_fact | True |  |  |
| [Set GPU active (forced)](tasks/host.yml#L50) | ansible.builtin.set_fact | True |  |  |
| [Fail if GPU missing](tasks/host.yml#L55) | ansible.builtin.fail | True |  |  |
| [Set GPU active (disabled)](tasks/host.yml#L61) | ansible.builtin.set_fact | True |  |  |
| [Install driver deps](tasks/host.yml#L66) | ansible.builtin.apt | True |  |  |
| [Detect driver](tasks/host.yml#L75) | ansible.builtin.shell | True |  |  |
| [Set driver version](tasks/host.yml#L85) | ansible.builtin.set_fact | True |  |  |
| [Set driver fallback](tasks/host.yml#L92) | ansible.builtin.set_fact | True |  |  |
| [Set manual driver](tasks/host.yml#L105) | ansible.builtin.set_fact | True |  |  |
| [Blacklist nouveau](tasks/host.yml#L111) | ansible.builtin.copy | True |  |  |
| [Update initramfs](tasks/host.yml#L120) | ansible.builtin.command | True |  |  |
| [Set utils package](tasks/host.yml#L125) | ansible.builtin.set_fact | True |  | Derive the nvidia-utils package from the detected driver (e.g., nvidia-driver-535 -> nvidia-utils-535) |
| [Check broken packages](tasks/host.yml#L129) | ansible.builtin.shell | True |  |  |
| [Fix broken packages](tasks/host.yml#L134) | ansible.builtin.shell | True |  |  |
| [Install NVIDIA driver](tasks/host.yml#L151) | ansible.builtin.apt | True |  |  |
| [Reboot system (nvidia)](tasks/host.yml#L160) | ansible.builtin.reboot | True |  |  |
| [Ensure APT keyrings dir](tasks/host.yml#L171) | ansible.builtin.file | True |  |  |
| [Download toolkit keyring](tasks/host.yml#L177) | ansible.builtin.get_url | True |  |  |
| [Download toolkit repo list](tasks/host.yml#L183) | ansible.builtin.get_url | True |  |  |
| [Read toolkit repo list](tasks/host.yml#L190) | ansible.builtin.slurp | True |  |  |
| [Write toolkit repo with signed-by](tasks/host.yml#L195) | ansible.builtin.copy | True |  |  |
| [Install toolkit](tasks/host.yml#L210) | ansible.builtin.apt | True |  |  |
| [Create containerd dir](tasks/host.yml#L217) | ansible.builtin.file | True |  |  |
| [Configure containerd](tasks/host.yml#L223) | ansible.builtin.template | True |  |  |


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
  NVIDIA_GPU_cluster_setup0_block_start_0-->|Task| Create_temp_values0[create temp values]:::task
  Create_temp_values0-->|Task| Copy_values1[copy values]:::task
  Copy_values1-->|Task| Install_device_plugin2[install device plugin]:::task
  Install_device_plugin2-->|Task| Wait_for_daemonset3[wait for daemonset]:::task
  Wait_for_daemonset3-->|Task| Check_GPU_resources4[check gpu resources]:::task
  Check_GPU_resources4-->|Task| Debug_GPU_resources5[debug gpu resources]:::task
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
  NVIDIA_GPU_headless_optimization_setup0_block_start_0-->|Task| Install_X11_deps0[install x11 deps]:::task
  Install_X11_deps0-->|Task| Configure_xorg1[configure xorg]:::task
  Configure_xorg1-->|Task| Deploy_persistence_svc2[deploy persistence svc]:::task
  Deploy_persistence_svc2-->|Task| Deploy_Xorg_svc3[deploy xorg svc]:::task
  Deploy_Xorg_svc3-->|Task| Reload_systemd__nvidia_4[reload systemd  nvidia <br>When: **nvidia gpu persistence service changed or nvidia<br>gpu xorg service changed**]:::task
  Reload_systemd__nvidia_4-->|Task| Start_persistence_svc5[start persistence svc]:::task
  Start_persistence_svc5-->|Task| Start_Xorg_svc6[start xorg svc<br>When: **nvidia gpu headless x11 enabled   default true   <br>bool**]:::task
  Start_Xorg_svc6-->|Task| Wait_for_X_server7[wait for x server<br>When: **nvidia gpu headless x11 enabled   default true   <br>bool**]:::task
  Wait_for_X_server7-.->|End of Block| NVIDIA_GPU_headless_optimization_setup0_block_start_0
  Wait_for_X_server7-->|Rescue Start| NVIDIA_GPU_headless_optimization_setup0_rescue_start_0[nvidia gpu headless optimization setup<br>When: **nvidia gpu active   default false    bool**]:::rescue
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
  NVIDIA_GPU_host_setup0_block_start_0-->|Task| Install_pciutils0[install pciutils]:::task
  Install_pciutils0-->|Task| Normalize_setup_mode1[normalize setup mode<br>When: **nvidia gpu setup mode is not defined**]:::task
  Normalize_setup_mode1-->|Task| Get_PCI_vendors2[get pci vendors]:::task
  Get_PCI_vendors2-->|Task| Debug_PCI_Vendors3[debug pci vendors]:::task
  Debug_PCI_Vendors3-->|Task| Detect_GPU4[detect gpu]:::task
  Detect_GPU4-->|Task| Set_GPU_active__auto_5[set gpu active  auto <br>When: **nvidia gpu setup mode     auto**]:::task
  Set_GPU_active__auto_5-->|Task| Set_GPU_active__forced_6[set gpu active  forced <br>When: **nvidia gpu setup mode     true**]:::task
  Set_GPU_active__forced_6-->|Task| Fail_if_GPU_missing7[fail if gpu missing<br>When: **nvidia gpu setup mode     true  and not  nvidia<br>gpu present   default false**]:::task
  Fail_if_GPU_missing7-->|Task| Set_GPU_active__disabled_8[set gpu active  disabled <br>When: **nvidia gpu setup mode     false**]:::task
  Set_GPU_active__disabled_8-->|Task| Install_driver_deps9[install driver deps<br>When: **nvidia gpu active   default false    bool**]:::task
  Install_driver_deps9-->|Task| Detect_driver10[detect driver<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver package     auto**]:::task
  Detect_driver10-->|Task| Set_driver_version11[set driver version<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver package     auto  and nvidia gpu<br>detected driver stdout   length   0**]:::task
  Set_driver_version11-->|Task| Set_driver_fallback12[set driver fallback<br>When: **nvidia gpu driver package     auto  and      <br>nvidia gpu detected driver skipped is defined  <br>and nvidia gpu detected driver skipped   or <br>nvidia gpu detected driver stdout   length    0 <br>and nvidia gpu active   default false    bool**]:::task
  Set_driver_fallback12-->|Task| Set_manual_driver13[set manual driver<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver package     auto**]:::task
  Set_manual_driver13-->|Task| Blacklist_nouveau14[blacklist nouveau<br>When: **nvidia gpu active   default false    bool**]:::task
  Blacklist_nouveau14-->|Task| Update_initramfs15[update initramfs<br>When: **nvidia gpu blacklist nouveau changed**]:::task
  Update_initramfs15-->|Task| Set_utils_package16[set utils package<br>When: **nvidia gpu active   default false    bool**]:::task
  Set_utils_package16-->|Task| Check_broken_packages17[check broken packages<br>When: **nvidia gpu active   default false    bool**]:::task
  Check_broken_packages17-->|Task| Fix_broken_packages18[fix broken packages<br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu broken check stdout   int   0**]:::task
  Fix_broken_packages18-->|Task| Install_NVIDIA_driver19[install nvidia driver<br>When: **nvidia gpu active   default false    bool**]:::task
  Install_NVIDIA_driver19-->|Task| Reboot_system__nvidia_20[reboot system  nvidia <br>When: **nvidia gpu active   default false    bool and<br>nvidia gpu driver install changed or nvidia gpu<br>blacklist nouveau changed**]:::task
  Reboot_system__nvidia_20-->|Task| Ensure_APT_keyrings_dir21[ensure apt keyrings dir<br>When: **nvidia gpu active   default false    bool**]:::task
  Ensure_APT_keyrings_dir21-->|Task| Download_toolkit_keyring22[download toolkit keyring<br>When: **nvidia gpu active   default false    bool**]:::task
  Download_toolkit_keyring22-->|Task| Download_toolkit_repo_list23[download toolkit repo list<br>When: **nvidia gpu active   default false    bool**]:::task
  Download_toolkit_repo_list23-->|Task| Read_toolkit_repo_list24[read toolkit repo list<br>When: **nvidia gpu active   default false    bool**]:::task
  Read_toolkit_repo_list24-->|Task| Write_toolkit_repo_with_signed_by25[write toolkit repo with signed by<br>When: **nvidia gpu active   default false    bool**]:::task
  Write_toolkit_repo_with_signed_by25-->|Task| Install_toolkit26[install toolkit<br>When: **nvidia gpu active   default false    bool**]:::task
  Install_toolkit26-->|Task| Create_containerd_dir27[create containerd dir<br>When: **nvidia gpu active   default false    bool**]:::task
  Create_containerd_dir27-->|Task| Configure_containerd28[configure containerd<br>When: **nvidia gpu active   default false    bool**]:::task
  Configure_containerd28-.->|End of Block| NVIDIA_GPU_host_setup0_block_start_0
  Configure_containerd28-->|Rescue Start| NVIDIA_GPU_host_setup0_rescue_start_0[nvidia gpu host setup]:::rescue
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
