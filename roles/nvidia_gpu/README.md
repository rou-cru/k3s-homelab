<!-- DOCSIBLE START -->

# 📃 Role overview

## nvidia_gpu



Description: Configures NVIDIA GPUs for K3s, including drivers, container toolkit, and device plugin.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Manages NVIDIA drivers, container toolkit, and device plugin installation.
Supports host setup, cluster setup, and headless X11 configurations.


**Options**:


  - **nvidia_setup**
    - **Required**: False
    - **Type**: str
    - **Default**: auto
  
    - **Description**: Control mode for GPU setup ('auto', 'true', 'false').
  
      - **Choices**:
    
          - auto
    
          - true
    
          - false
    
  
  
  

  - **nvidia_driverPackage**
    - **Required**: False
    - **Type**: str
    - **Default**: auto
  
    - **Description**: Specific driver package to install or "auto" for detection.
  
  
  

  - **nvidia_driverFallback**
    - **Required**: False
    - **Type**: str
    - **Default**: nvidia-driver-535
  
    - **Description**: Fallback driver if auto-detection fails.
  
  
  

  - **nvidia_toolkitRepoUrl**
    - **Required**: False
    - **Type**: str
    - **Default**: https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list
  
    - **Description**: Repository URL for NVIDIA Container Toolkit.
  
  
  

  - **nvidia_toolkitGpgUrl**
    - **Required**: False
    - **Type**: str
    - **Default**: https://nvidia.github.io/libnvidia-container/gpgkey
  
    - **Description**: GPG key URL for the toolkit repository.
  
  
  

  - **nvidia_devicePluginVersion**
    - **Required**: False
    - **Type**: str
    - **Default**: none
  
    - **Description**: Version of the NVIDIA device plugin Helm chart.
  
  
  

  - **nvidia_devicePluginRepo**
    - **Required**: False
    - **Type**: str
    - **Default**: https://nvidia.github.io/k8s-device-plugin
  
    - **Description**: Helm repository for the device plugin.
  
  
  

  - **nvidia_rebootTimeout**
    - **Required**: False
    - **Type**: int
    - **Default**: 600
  
    - **Description**: Timeout (seconds) for rebooting after driver installation.
  
  
  

  - **nvidia_headlessX11Enabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Enables X11 services for headless GPU management (fan control, etc.).
  
  
  

  - **nvidia_pciBusId**
    - **Required**: False
    - **Type**: str
    - **Default**: 1:0:0
  
    - **Description**: PCI Bus ID of the GPU for xorg.conf generation.
  
  
  

  - **nvidia_coolbits**
    - **Required**: False
    - **Type**: str
    - **Default**: 28
  
    - **Description**: Coolbits value for unlocking GPU control (fans, clocks).
  
  
  



</details>








### Tasks


#### File: tasks/cluster.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [NVIDIA GPU cluster setup](tasks/cluster.yml#L2) | block | True | cluster,nvidia | @docsible Configure NVIDIA GPU in Kubernetes cluster |
| [Ensure NVIDIA Helm repo](tasks/cluster.yml#L6) | kubernetes.core.helm_repository | False |  | @docsible Add NVIDIA device plugin Helm repository |
| [Create temp values](tasks/cluster.yml#L12) | ansible.builtin.tempfile | False |  | @docsible Create temporary values file |
| [Copy values](tasks/cluster.yml#L19) | ansible.builtin.copy | False |  | @docsible Copy device plugin values template |
| [Install device plugin](tasks/cluster.yml#L26) | kubernetes.core.helm | False |  | @docsible Install NVIDIA device plugin via Helm |
| [Wait for daemonset](tasks/cluster.yml#L38) | kubernetes.core.k8s_info | False |  | @docsible Wait for device plugin DaemonSet readiness |
| [Check GPU resources](tasks/cluster.yml#L53) | kubernetes.core.k8s_info | False |  | @docsible Query node GPU capacity |
| [Extract GPU capacities from nodes](tasks/cluster.yml#L61) | ansible.builtin.set_fact | False |  | @docsible Parse GPU resource allocation |
| [Debug GPU resources](tasks/cluster.yml#L70) | ansible.builtin.debug | False |  | @docsible Display detected GPU resources |

#### File: tasks/headless_optimization.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install X11 deps](tasks/headless_optimization.yml#L2) | ansible.builtin.apt | True | @docsible Install X11 server for headless GPU control |
| [Configure xorg](tasks/headless_optimization.yml#L13) | ansible.builtin.template | True | @docsible Generate xorg.conf with Coolbits for fan/clocks control |
| [Deploy persistence svc](tasks/headless_optimization.yml#L24) | ansible.builtin.copy | True | @docsible Deploy persistence daemon service |
| [Deploy Xorg svc](tasks/headless_optimization.yml#L35) | ansible.builtin.copy | True | @docsible Deploy X11 service for headless operation |
| [Reload systemd (nvidia)](tasks/headless_optimization.yml#L46) | ansible.builtin.systemd | True | @docsible Reload systemd after service changes |
| [Start persistence svc](tasks/headless_optimization.yml#L54) | ansible.builtin.systemd | True | @docsible Start persistence daemon |
| [Start Xorg svc](tasks/headless_optimization.yml#L62) | ansible.builtin.systemd | True | @docsible Start X11 service on display :1 |
| [Wait for X server](tasks/headless_optimization.yml#L72) | ansible.builtin.wait_for | True | @docsible Wait for X server socket readiness |

#### File: tasks/host.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Install pciutils](tasks/host.yml#L2) | ansible.builtin.apt | False |  | @docsible Install PCI utilities |
| [Normalize setup mode](tasks/host.yml#L10) | ansible.builtin.set_fact | False |  | @docsible Normalize setup mode |
| [Get PCI vendors](tasks/host.yml#L15) | ansible.builtin.shell | False |  | @docsible Get PCI vendor IDs |
| [Detect GPU](tasks/host.yml#L21) | ansible.builtin.set_fact | False |  | @docsible Detect NVIDIA GPU presence |
| [Set GPU active (auto)](tasks/host.yml#L35) | ansible.builtin.set_fact | True |  | @docsible Set GPU active in auto mode |
| [Set GPU active (forced)](tasks/host.yml#L42) | ansible.builtin.set_fact | True |  | @docsible Force GPU active |
| [Fail if GPU missing](tasks/host.yml#L49) | ansible.builtin.fail | True |  | @docsible Fail if GPU missing in forced mode |
| [Set GPU active (disabled)](tasks/host.yml#L57) | ansible.builtin.set_fact | True |  | @docsible Disable GPU setup |
| [Debug NVIDIA facts](tasks/host.yml#L64) | ansible.builtin.debug | False |  | @docsible Debug NVIDIA facts |
| [Install driver deps](tasks/host.yml#L69) | ansible.builtin.apt | True |  | @docsible Install driver dependencies |
| [Detect driver](tasks/host.yml#L80) | ansible.builtin.shell | True |  | @docsible Detect recommended NVIDIA driver |
| [Set driver version](tasks/host.yml#L93) | ansible.builtin.set_fact | True |  | @docsible Set detected driver version |
| [Set driver fallback](tasks/host.yml#L102) | ansible.builtin.set_fact | True |  | @docsible Set fallback driver version |
| [Set manual driver](tasks/host.yml#L112) | ansible.builtin.set_fact | True |  | @docsible Set manual driver version |
| [Blacklist nouveau](tasks/host.yml#L120) | ansible.builtin.copy | True |  | @docsible Blacklist nouveau driver |
| [Update initramfs](tasks/host.yml#L130) | ansible.builtin.command | True |  |  |
| [Set utils package](tasks/host.yml#L138) | ansible.builtin.set_fact | True |  | @docsible Set utils package name |
| [Check broken packages](tasks/host.yml#L144) | ansible.builtin.shell | True |  | @docsible Check for broken NVIDIA packages |
| [Fix broken packages](tasks/host.yml#L151) | ansible.builtin.shell | True |  | @docsible Fix broken NVIDIA packages |
| [Install NVIDIA driver](tasks/host.yml#L165) | ansible.builtin.apt | True |  | @docsible Install NVIDIA driver |
| [Reboot system (nvidia)](tasks/host.yml#L176) | ansible.builtin.reboot | True |  | @docsible Reboot system to load drivers |
| [Ensure APT keyrings dir](tasks/host.yml#L186) | ansible.builtin.file | True |  | @docsible Ensure APT keyrings directory |
| [Write toolkit repo](tasks/host.yml#L196) | ansible.builtin.copy | True |  | @docsible Write NVIDIA toolkit repository |
| [Install toolkit](tasks/host.yml#L209) | ansible.builtin.apt | True |  | @docsible Install NVIDIA container toolkit |
| [Register NVIDIA as an available runtime](tasks/host.yml#L218) | ansible.builtin.set_fact | True | host,nvidia | @docsible Register NVIDIA runtime for containerd |
| [Import headless optimization](tasks/host.yml#L226) | ansible.builtin.import_tasks | True |  | @docsible Import headless X11 optimization |


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

  Start-->|Block Start| NVIDIA_GPU_cluster_setup0_block_start_0[[nvidia gpu cluster setup<br>When: **not ansible check mode**]]:::block
  NVIDIA_GPU_cluster_setup0_block_start_0-->|Task| Ensure_NVIDIA_Helm_repo0[ensure nvidia helm repo]:::task
  Ensure_NVIDIA_Helm_repo0-->|Task| Create_temp_values1[create temp values]:::task
  Create_temp_values1-->|Task| Copy_values2[copy values]:::task
  Copy_values2-->|Task| Install_device_plugin3[install device plugin]:::task
  Install_device_plugin3-->|Task| Wait_for_daemonset4[wait for daemonset]:::task
  Wait_for_daemonset4-->|Task| Check_GPU_resources5[check gpu resources]:::task
  Check_GPU_resources5-->|Task| Extract_GPU_capacities_from_nodes6[extract gpu capacities from nodes]:::task
  Extract_GPU_capacities_from_nodes6-->|Task| Debug_GPU_resources7[debug gpu resources]:::task
  Debug_GPU_resources7-.->|End of Block| NVIDIA_GPU_cluster_setup0_block_start_0
  Debug_GPU_resources7-->|Rescue Start| NVIDIA_GPU_cluster_setup0_rescue_start_0[nvidia gpu cluster setup<br>When: **not ansible check mode**]:::rescue
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

  Start-->|Task| Install_X11_deps0[install x11 deps<br>When: **nvidia active   default false    bool**]:::task
  Install_X11_deps0-->|Task| Configure_xorg1[configure xorg<br>When: **nvidia active   default false    bool**]:::task
  Configure_xorg1-->|Task| Deploy_persistence_svc2[deploy persistence svc<br>When: **nvidia active   default false    bool**]:::task
  Deploy_persistence_svc2-->|Task| Deploy_Xorg_svc3[deploy xorg svc<br>When: **nvidia active   default false    bool**]:::task
  Deploy_Xorg_svc3-->|Task| Reload_systemd__nvidia_4[reload systemd  nvidia <br>When: **nvidia active   default false    bool and nvidia<br>persistenceservice changed or nvidia xorgservice<br>changed**]:::task
  Reload_systemd__nvidia_4-->|Task| Start_persistence_svc5[start persistence svc<br>When: **nvidia active   default false    bool**]:::task
  Start_persistence_svc5-->|Task| Start_Xorg_svc6[start xorg svc<br>When: **nvidia active   default false    bool and nvidia<br>headlessx11enabled   default true    bool**]:::task
  Start_Xorg_svc6-->|Task| Wait_for_X_server7[wait for x server<br>When: **nvidia active   default false    bool and nvidia<br>headlessx11enabled   default true    bool**]:::task
  Wait_for_X_server7-->End
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

  Start-->|Task| Install_pciutils0[install pciutils]:::task
  Install_pciutils0-->|Task| Normalize_setup_mode1[normalize setup mode]:::task
  Normalize_setup_mode1-->|Task| Get_PCI_vendors2[get pci vendors]:::task
  Get_PCI_vendors2-->|Task| Detect_GPU3[detect gpu]:::task
  Detect_GPU3-->|Task| Set_GPU_active__auto_4[set gpu active  auto <br>When: **nvidia setupmode     auto**]:::task
  Set_GPU_active__auto_4-->|Task| Set_GPU_active__forced_5[set gpu active  forced <br>When: **nvidia setupmode     true**]:::task
  Set_GPU_active__forced_5-->|Task| Fail_if_GPU_missing6[fail if gpu missing<br>When: **nvidia setupmode     true  and not  nvidia present<br>  default false**]:::task
  Fail_if_GPU_missing6-->|Task| Set_GPU_active__disabled_7[set gpu active  disabled <br>When: **nvidia setupmode     false**]:::task
  Set_GPU_active__disabled_7-->|Task| Debug_NVIDIA_facts8[debug nvidia facts]:::task
  Debug_NVIDIA_facts8-->|Task| Install_driver_deps9[install driver deps<br>When: **nvidia active   default false    bool**]:::task
  Install_driver_deps9-->|Task| Detect_driver10[detect driver<br>When: **nvidia active   default false    bool and nvidia<br>driverpackage     auto**]:::task
  Detect_driver10-->|Task| Set_driver_version11[set driver version<br>When: **nvidia active   default false    bool and nvidia<br>driverpackage     auto  and nvidia detecteddriver<br>stdout   length   0**]:::task
  Set_driver_version11-->|Task| Set_driver_fallback12[set driver fallback<br>When: **nvidia driverpackage     auto  and  nvidia<br>detecteddriver skipped is defined and nvidia<br>detecteddriver skipped  or  nvidia detecteddriver<br>stdout   length    0  and nvidia active   default<br>false    bool**]:::task
  Set_driver_fallback12-->|Task| Set_manual_driver13[set manual driver<br>When: **nvidia active   default false    bool and nvidia<br>driverpackage     auto**]:::task
  Set_manual_driver13-->|Task| Blacklist_nouveau14[blacklist nouveau<br>When: **nvidia active   default false    bool**]:::task
  Blacklist_nouveau14-->|Task| Update_initramfs15[update initramfs<br>When: **nvidia blacklistnouveau is changed and not ansible<br>check mode**]:::task
  Update_initramfs15-->|Task| Set_utils_package16[set utils package<br>When: **nvidia active   default false    bool**]:::task
  Set_utils_package16-->|Task| Check_broken_packages17[check broken packages<br>When: **nvidia active   default false    bool**]:::task
  Check_broken_packages17-->|Task| Fix_broken_packages18[fix broken packages<br>When: **nvidia active   default false    bool and nvidia<br>brokencheck stdout   int   0 and not ansible check<br>mode**]:::task
  Fix_broken_packages18-->|Task| Install_NVIDIA_driver19[install nvidia driver<br>When: **nvidia active   default false    bool**]:::task
  Install_NVIDIA_driver19-->|Task| Reboot_system__nvidia_20[reboot system  nvidia <br>When: **nvidia active   default false    bool and nvidia<br>driverinstall changed or nvidia blacklistnouveau<br>changed and not ansible check mode**]:::task
  Reboot_system__nvidia_20-->|Task| Ensure_APT_keyrings_dir21[ensure apt keyrings dir<br>When: **nvidia active   default false    bool**]:::task
  Ensure_APT_keyrings_dir21-->|Task| Write_toolkit_repo22[write toolkit repo<br>When: **nvidia active   default false    bool**]:::task
  Write_toolkit_repo22-->|Task| Install_toolkit23[install toolkit<br>When: **nvidia active   default false    bool**]:::task
  Install_toolkit23-->|Task| Register_NVIDIA_as_an_available_runtime24[register nvidia as an available runtime<br>When: **nvidia active   default false    bool**]:::task
  Register_NVIDIA_as_an_available_runtime24-->|Import task| Import_headless_optimization_headless_optimization_yml_25[/import headless optimization<br>When: **nvidia active   default false    bool and nvidia<br>headlessx11enabled   default true    bool**<br>import_task: headless optimization yml/]:::importTasks
  Import_headless_optimization_headless_optimization_yml_25-->End
```





## Author Information
Roura

### License

MIT

### Minimum Ansible Version

2.20.0

### Platforms

- **Ubuntu**: ['noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
