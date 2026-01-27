<!-- DOCSIBLE START -->

# 📃 Role overview

## developer_tools



Description: Installs development tools and useful CLIs for K3s environments.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Installs a suite of developer tools including terminal utilities (bat, tmux),
Kubernetes CLIs (kubectl, helm, k9s), Python tools (uv, pipx), and AI CLIs.


**Options**:


  - **devtools_installDocker**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Installs Docker CLI (not recommended for K3s nodes which use containerd).
  
  
  

  - **devtools_installVagrant**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Installs Vagrant for VM provisioning and testing.
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install dev tools (apt)](tasks/main.yml#L2) | ansible.builtin.apt | False | @docsible Install base development tools via APT |
| [Install NVM](tasks/main.yml#L20) | ansible.builtin.shell | True | @docsible Install Node Version Manager |
| [Install latest Node.js LTS via NVM](tasks/main.yml#L29) | ansible.builtin.shell | True | @docsible Install Node.js LTS via NVM |
| [Enable Corepack and activate pnpm](tasks/main.yml#L40) | ansible.builtin.shell | True | @docsible Enable Corepack and activate pnpm |
| [Install Devbox](tasks/main.yml#L51) | ansible.builtin.shell | True | @docsible Install Devbox package manager |
| [Install nvitop](tasks/main.yml#L58) | ansible.builtin.command | True | @docsible Install nvitop GPU monitor via uv |
| [Install Kimi](tasks/main.yml#L68) | ansible.builtin.command | True | @docsible Install Kimi CLI via uv |
| [Install AI tools](tasks/main.yml#L76) | ansible.builtin.shell | True | @docsible Install AI CLI tools via npm |
| [Install Docker](tasks/main.yml#L91) | block | True | @docsible Install Docker CLI if enabled |
| [Add Docker key](tasks/main.yml#L97) | ansible.builtin.shell | False | @docsible Add Docker GPG key |
| [Add Docker repo](tasks/main.yml#L105) | ansible.builtin.apt_repository | False | @docsible Add Docker APT repository |
| [Install Docker CLI](tasks/main.yml#L122) | ansible.builtin.apt | False | @docsible Install Docker CLI packages |
| [Show Docker warning](tasks/main.yml#L131) | ansible.builtin.debug | False | @docsible Warn about containerd conflict |
| [Install Vagrant and libvirt](tasks/main.yml#L143) | block | True | @docsible Install Vagrant and libvirt for testing |
| [Set HashiCorp repo release](tasks/main.yml#L149) | ansible.builtin.set_fact | False | @docsible Determine HashiCorp repo release |
| [Set HashiCorp repo architecture](tasks/main.yml#L154) | ansible.builtin.set_fact | False | @docsible Determine architecture for HashiCorp repo |
| [Validate HashiCorp repo architecture](tasks/main.yml#L165) | ansible.builtin.assert | False | @docsible Validate supported architecture |
| [Ensure APT keyrings dir (HashiCorp)](tasks/main.yml#L171) | ansible.builtin.file | True | @docsible Create APT keyrings directory |
| [Install HashiCorp keyring](tasks/main.yml#L178) | ansible.builtin.shell | True | @docsible Install HashiCorp GPG key |
| [Add HashiCorp APT repo](tasks/main.yml#L188) | ansible.builtin.apt_repository | True | @docsible Add HashiCorp APT repository |
| [Install libvirt and dependencies](tasks/main.yml#L204) | ansible.builtin.apt | False | @docsible Install libvirt and build dependencies |
| [Ensure libvirtd service is enabled and started](tasks/main.yml#L224) | ansible.builtin.systemd | False | @docsible Enable libvirtd service |
| [Add ansible_user to libvirt group](tasks/main.yml#L230) | ansible.builtin.user | False | @docsible Add ansible user to libvirt group |
| [Add root to libvirt group](tasks/main.yml#L236) | ansible.builtin.user | False | @docsible Add root to libvirt group |
| [Check installed Vagrant plugins](tasks/main.yml#L242) | ansible.builtin.command | False | @docsible List installed Vagrant plugins |
| [Install vagrant-libvirt plugin](tasks/main.yml#L247) | ansible.builtin.command | True | @docsible Install vagrant-libvirt plugin |
| [Show Vagrant installation success](tasks/main.yml#L256) | ansible.builtin.debug | False | @docsible Confirm Vagrant installation |


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

  Start-->|Task| Install_dev_tools__apt_0[install dev tools  apt ]:::task
  Install_dev_tools__apt_0-->|Task| Install_NVM1[install nvm<br>When: **not ansible check mode**]:::task
  Install_NVM1-->|Task| Install_latest_Node_js_LTS_via_NVM2[install latest node js lts via nvm<br>When: **not ansible check mode**]:::task
  Install_latest_Node_js_LTS_via_NVM2-->|Task| Enable_Corepack_and_activate_pnpm3[enable corepack and activate pnpm<br>When: **not ansible check mode**]:::task
  Enable_Corepack_and_activate_pnpm3-->|Task| Install_Devbox4[install devbox<br>When: **not ansible check mode**]:::task
  Install_Devbox4-->|Task| Install_nvitop5[install nvitop<br>When: **nvidia setupmode   default  auto       false  and<br>not ansible check mode**]:::task
  Install_nvitop5-->|Task| Install_Kimi6[install kimi<br>When: **not ansible check mode**]:::task
  Install_Kimi6-->|Task| Install_AI_tools7[install ai tools<br>When: **not ansible check mode**]:::task
  Install_AI_tools7-->|Block Start| Install_Docker8_block_start_0[[install docker<br>When: **devtools installdocker   default false    bool and<br>not ansible check mode**]]:::block
  Install_Docker8_block_start_0-->|Task| Add_Docker_key0[add docker key]:::task
  Add_Docker_key0-->|Task| Add_Docker_repo1[add docker repo]:::task
  Add_Docker_repo1-->|Task| Install_Docker_CLI2[install docker cli]:::task
  Install_Docker_CLI2-->|Task| Show_Docker_warning3[show docker warning]:::task
  Show_Docker_warning3-.->|End of Block| Install_Docker8_block_start_0
  Show_Docker_warning3-->|Rescue Start| Install_Docker8_rescue_start_0[install docker<br>When: **devtools installdocker   default false    bool and<br>not ansible check mode**]:::rescue
  Install_Docker8_rescue_start_0-->|Task| Report_Docker_installation_failure0[report docker installation failure]:::task
  Report_Docker_installation_failure0-->|Task| Fail_Docker_installation1[fail docker installation]:::task
  Fail_Docker_installation1-.->|End of Rescue Block| Install_Docker8_block_start_0
  Fail_Docker_installation1-->|Block Start| Install_Vagrant_and_libvirt9_block_start_0[[install vagrant and libvirt<br>When: **devtools installvagrant   default true    bool and<br>not ansible check mode**]]:::block
  Install_Vagrant_and_libvirt9_block_start_0-->|Task| Set_HashiCorp_repo_release0[set hashicorp repo release]:::task
  Set_HashiCorp_repo_release0-->|Task| Set_HashiCorp_repo_architecture1[set hashicorp repo architecture]:::task
  Set_HashiCorp_repo_architecture1-->|Task| Validate_HashiCorp_repo_architecture2[validate hashicorp repo architecture]:::task
  Validate_HashiCorp_repo_architecture2-->|Task| Ensure_APT_keyrings_dir__HashiCorp_3[ensure apt keyrings dir  hashicorp <br>When: **not ansible check mode**]:::task
  Ensure_APT_keyrings_dir__HashiCorp_3-->|Task| Install_HashiCorp_keyring4[install hashicorp keyring<br>When: **not ansible check mode**]:::task
  Install_HashiCorp_keyring4-->|Task| Add_HashiCorp_APT_repo5[add hashicorp apt repo<br>When: **not ansible check mode**]:::task
  Add_HashiCorp_APT_repo5-->|Task| Install_libvirt_and_dependencies6[install libvirt and dependencies]:::task
  Install_libvirt_and_dependencies6-->|Task| Ensure_libvirtd_service_is_enabled_and_started7[ensure libvirtd service is enabled and started]:::task
  Ensure_libvirtd_service_is_enabled_and_started7-->|Task| Add_ansible_user_to_libvirt_group8[add ansible user to libvirt group]:::task
  Add_ansible_user_to_libvirt_group8-->|Task| Add_root_to_libvirt_group9[add root to libvirt group]:::task
  Add_root_to_libvirt_group9-->|Task| Check_installed_Vagrant_plugins10[check installed vagrant plugins]:::task
  Check_installed_Vagrant_plugins10-->|Task| Install_vagrant_libvirt_plugin11[install vagrant libvirt plugin<br>When: **not ansible check mode and vagrant plugin list rc <br>  0 and  vagrant libvirt  not in vagrant plugin<br>list stdout**]:::task
  Install_vagrant_libvirt_plugin11-->|Task| Show_Vagrant_installation_success12[show vagrant installation success]:::task
  Show_Vagrant_installation_success12-.->|End of Block| Install_Vagrant_and_libvirt9_block_start_0
  Show_Vagrant_installation_success12-->|Rescue Start| Install_Vagrant_and_libvirt9_rescue_start_0[install vagrant and libvirt<br>When: **devtools installvagrant   default true    bool and<br>not ansible check mode**]:::rescue
  Install_Vagrant_and_libvirt9_rescue_start_0-->|Task| Report_Vagrant_installation_failure0[report vagrant installation failure]:::task
  Report_Vagrant_installation_failure0-->|Task| Fail_Vagrant_installation1[fail vagrant installation]:::task
  Fail_Vagrant_installation1-.->|End of Rescue Block| Install_Vagrant_and_libvirt9_block_start_0
  Fail_Vagrant_installation1-->End
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
