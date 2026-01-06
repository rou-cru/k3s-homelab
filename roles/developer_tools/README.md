<!-- DOCSIBLE START -->

# 📃 Role overview

## developer_tools



Description: Installs development tools and useful CLIs for K3s environments.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Installs a suite of developer tools including terminal utilities (bat, tmux),
Kubernetes CLIs (kubectl, helm, k9s), Python tools (uv, pipx), and AI CLIs.


**Options**:


  - **devtools_install_docker**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Installs Docker CLI (not recommended for K3s nodes which use containerd).
  
  
  



</details>




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [devtools_install_docker](defaults/main.yml#L6)   | bool | `False` |    false  |  Install Docker |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>devtools_install_docker</b></td><td>Installs Docker CLI (not recommended for K3s nodes which use containerd).</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install base CLI tools and dependencies via APT](tasks/main.yml#L2) | ansible.builtin.apt | False |  |
| [Install btop via snap](tasks/main.yml#L22) | ansible.builtin.snap | False | Terminal monitoring tools (snap) |
| [Install kubectl via snap](tasks/main.yml#L27) | ansible.builtin.snap | False | Kubernetes tools (snap) |
| [Install Helm via snap](tasks/main.yml#L31) | ansible.builtin.snap | False |  |
| [Install yq via snap](tasks/main.yml#L35) | ansible.builtin.snap | False |  |
| [Install Node.js via snap](tasks/main.yml#L40) | ansible.builtin.snap | False | Development environments |
| [Install pnpm globally](tasks/main.yml#L44) | community.general.npm | False |  |
| [Install Devbox](tasks/main.yml#L49) | ansible.builtin.shell | False |  |
| [Install uv (Python package installer)](tasks/main.yml#L55) | ansible.builtin.shell | False | Python package manager (uv) |
| [Install nvitop for NVIDIA GPU monitoring](tasks/main.yml#L63) | ansible.builtin.command | True | Python CLI tools (pipx/uv) |
| [Install Kimi CLI via uv](tasks/main.yml#L68) | ansible.builtin.command | False |  |
| [Install AI CLI tools via npm](tasks/main.yml#L76) | community.general.npm | False | AI CLI tools (npm) |
| [Docker installation (optional)](tasks/main.yml#L88) | block | True | Docker (optional, disabled by default) |
| [Add Docker APT key](tasks/main.yml#L91) | ansible.builtin.shell | False |  |
| [Add Docker APT repository](tasks/main.yml#L98) | ansible.builtin.apt_repository | False |  |
| [Install Docker CLI only](tasks/main.yml#L107) | ansible.builtin.apt | False |  |
| [Show Docker warning](tasks/main.yml#L115) | ansible.builtin.debug | False |  |


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

  Start-->|Task| Install_base_CLI_tools_and_dependencies_via_APT0[install base cli tools and dependencies via apt]:::task
  Install_base_CLI_tools_and_dependencies_via_APT0-->|Task| Install_btop_via_snap1[install btop via snap]:::task
  Install_btop_via_snap1-->|Task| Install_kubectl_via_snap2[install kubectl via snap]:::task
  Install_kubectl_via_snap2-->|Task| Install_Helm_via_snap3[install helm via snap]:::task
  Install_Helm_via_snap3-->|Task| Install_yq_via_snap4[install yq via snap]:::task
  Install_yq_via_snap4-->|Task| Install_Node_js_via_snap5[install node js via snap]:::task
  Install_Node_js_via_snap5-->|Task| Install_pnpm_globally6[install pnpm globally]:::task
  Install_pnpm_globally6-->|Task| Install_Devbox7[install devbox]:::task
  Install_Devbox7-->|Task| Install_uv__Python_package_installer_8[install uv  python package installer ]:::task
  Install_uv__Python_package_installer_8-->|Task| Install_nvitop_for_NVIDIA_GPU_monitoring9[install nvitop for nvidia gpu monitoring<br>When: **nvidia gpu setup mode   default  auto       false**]:::task
  Install_nvitop_for_NVIDIA_GPU_monitoring9-->|Task| Install_Kimi_CLI_via_uv10[install kimi cli via uv]:::task
  Install_Kimi_CLI_via_uv10-->|Task| Install_AI_CLI_tools_via_npm11[install ai cli tools via npm]:::task
  Install_AI_CLI_tools_via_npm11-->|Block Start| Docker_installation__optional_12_block_start_0[[docker installation  optional <br>When: **devtools install docker   default false    bool**]]:::block
  Docker_installation__optional_12_block_start_0-->|Task| Add_Docker_APT_key0[add docker apt key]:::task
  Add_Docker_APT_key0-->|Task| Add_Docker_APT_repository1[add docker apt repository]:::task
  Add_Docker_APT_repository1-->|Task| Install_Docker_CLI_only2[install docker cli only]:::task
  Install_Docker_CLI_only2-->|Task| Show_Docker_warning3[show docker warning]:::task
  Show_Docker_warning3-.->|End of Block| Docker_installation__optional_12_block_start_0
  Show_Docker_warning3-->|Rescue Start| Docker_installation__optional_12_rescue_start_0[docker installation  optional <br>When: **devtools install docker   default false    bool**]:::rescue
  Docker_installation__optional_12_rescue_start_0-->|Task| Report_Docker_installation_failure0[report docker installation failure]:::task
  Report_Docker_installation_failure0-->|Task| Fail_Docker_installation1[fail docker installation]:::task
  Fail_Docker_installation1-.->|End of Rescue Block| Docker_installation__optional_12_block_start_0
  Fail_Docker_installation1-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.9

#### Platforms

- **Ubuntu**: ['focal', 'jammy', 'noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
