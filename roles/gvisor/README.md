<!-- DOCSIBLE START -->

# 📃 Role overview

## gvisor



Description: Install gVisor runsc and register a RuntimeClass for K3s server workloads.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

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
| [Install runsc binary](tasks/host.yml#L2) | ansible.builtin.get_url | True | @docsible Installs runsc gVisor runtime version {{ gvisor_version }} |

#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Download runsc](tasks/main.yml#L3) | ansible.builtin.get_url | False |  | @docsible Downloads runsc binary from the latest release |
| [Remove runsc (cleanup)](tasks/main.yml#L13) | ansible.builtin.file | False | cleanup,never | @docsible Removes runsc binary during cleanup |

#### File: tasks/runtimeclass.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Apply gVisor RuntimeClass](tasks/runtimeclass.yml#L2) | kubernetes.core.k8s | True | @docsible Registers gVisor RuntimeClass (requires runsc on nodes) |


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

  Start-->|Task| Install_runsc_binary0[install runsc binary<br>When: **gvisor install   default true    bool**]:::task
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
  Download_runsc0-->|Task| Remove_runsc__cleanup_1[remove runsc  cleanup ]:::task
  Remove_runsc__cleanup_1-->End
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

  Start-->|Task| Apply_gVisor_RuntimeClass0[apply gvisor runtimeclass<br>When: **gvisor install   default true    bool**]:::task
  Apply_gVisor_RuntimeClass0-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.20.0

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
