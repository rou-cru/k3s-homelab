<!-- DOCSIBLE START -->

# 📃 Role overview

## gvisor



Description: Install gVisor runsc and register a RuntimeClass for K3s server workloads.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Downloads and installs gVisor runsc runtime and deploys
a RuntimeClass for sandboxed workloads in K3s.


**Options**:


  - **gvisor_version**
    - **Required**: False
    - **Type**: str
    - **Default**: latest
  
    - **Description**: gVisor version to install.
  
  
  

  - **gvisor_install**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Enable gVisor installation.
  
  
  



</details>








### Tasks


#### File: tasks/host.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install runsc binary](tasks/host.yml#L2) | ansible.builtin.get_url | True | @docsible Download and install gVisor runsc binary |

#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Download runsc](tasks/main.yml#L3) | ansible.builtin.get_url | False |  | @docsible Download gVisor runtime binary |
| [Ensure K3s manifests directory exists](tasks/main.yml#L13) | ansible.builtin.file | False |  | @docsible Use K3s auto-deploy manifests directory for the RuntimeClass |
| [Deploy RuntimeClass manifest](tasks/main.yml#L20) | ansible.builtin.template | False |  | @docsible Deploy gVisor RuntimeClass manifest |
| [Remove runsc (cleanup)](tasks/main.yml#L27) | ansible.builtin.file | False | cleanup,never | @docsible Remove gVisor runtime binary (cleanup) |

#### File: tasks/runtimeclass.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Ensure K3s manifests directory exists](tasks/runtimeclass.yml#L2) | ansible.builtin.file | True | @docsible Create K3s auto-deploy manifests directory |
| [Deploy gVisor RuntimeClass manifest](tasks/runtimeclass.yml#L12) | ansible.builtin.copy | True | @docsible Deploy gVisor RuntimeClass manifest |


## Task Flow Graphs



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

  Start-->|Task| Install_runsc_binary0[install runsc binary<br>When: **k3s server  in group names and  gvisor install  <br>default true    bool**]:::task
  Install_runsc_binary0-->End
```


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

  Start-->|Task| Download_runsc0[download runsc]:::task
  Download_runsc0-->|Task| Ensure_K3s_manifests_directory_exists1[ensure k3s manifests directory exists]:::task
  Ensure_K3s_manifests_directory_exists1-->|Task| Deploy_RuntimeClass_manifest2[deploy runtimeclass manifest]:::task
  Deploy_RuntimeClass_manifest2-->|Task| Remove_runsc__cleanup_3[remove runsc  cleanup ]:::task
  Remove_runsc__cleanup_3-->End
```


### Graph for runtimeclass.yml

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

  Start-->|Task| Ensure_K3s_manifests_directory_exists0[ensure k3s manifests directory exists<br>When: **k3s server  in group names and  gvisor install  <br>default true    bool**]:::task
  Ensure_K3s_manifests_directory_exists0-->|Task| Deploy_gVisor_RuntimeClass_manifest1[deploy gvisor runtimeclass manifest<br>When: **k3s server  in group names and  gvisor install  <br>default true    bool**]:::task
  Deploy_gVisor_RuntimeClass_manifest1-->End
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

- k3s_common (or k3s_server), to ensure K3s is present before RuntimeClass deploy
<!-- DOCSIBLE END -->
