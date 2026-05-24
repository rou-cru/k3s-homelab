<!-- DOCSIBLE START -->

# 📃 Role overview

## validate_hardware



Description: Pre-flight checks to ensure minimum system requirements are met.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Performs pre-flight checks:
- Network connectivity to get.k3s.io
- Root partition disk space (> 20GB)
- System memory (> 4GB)
- Architecture (x86_64 only)


**Options**:




</details>










### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Set system hostname](tasks/main.yml#L2) | ansible.builtin.hostname | True | @docsible Sets persistent system hostname to match inventory |
| [Check disk space](tasks/main.yml#L8) | ansible.builtin.shell | False | @docsible Retrieves available space on root filesystem (KB) |
| [Assert disk space](tasks/main.yml#L16) | ansible.builtin.assert | False | @docsible Enforces minimum disk space requirement (Default: 20GB) |
| [Assert memory](tasks/main.yml#L28) | ansible.builtin.assert | False | @docsible Enforces minimum RAM requirement (Default: 2GB) |
| [Assert architecture](tasks/main.yml#L37) | ansible.builtin.assert | False | @docsible Enforces x86_64 CPU architecture |


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

  Start-->|Task| Set_system_hostname0[set system hostname<br>When: **not ansible check mode**]:::task
  Set_system_hostname0-->|Task| Check_disk_space1[check disk space]:::task
  Check_disk_space1-->|Task| Assert_disk_space2[assert disk space]:::task
  Assert_disk_space2-->|Task| Assert_memory3[assert memory]:::task
  Assert_memory3-->|Task| Assert_architecture4[assert architecture]:::task
  Assert_architecture4-->End
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
