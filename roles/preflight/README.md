<!-- DOCSIBLE START -->

# 📃 Role overview

## preflight



Description: Verificaciones previas para asegurar requisitos mínimos del sistema

| Field                | Value           |
|--------------------- |-----------------|
| Readme update        | 2026/01/06 |














### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| Check network connectivity | ansible.builtin.uri | False |
| Fail if no network connectivity | ansible.builtin.fail | True |
| Get actual disk space on root partition | ansible.builtin.shell | False |
| Assert Disk Space (Root Partition > 20GB) | ansible.builtin.assert | False |
| Assert Memory (> 4GB) | ansible.builtin.assert | False |
| Assert Architecture (x86_64) | ansible.builtin.assert | False |


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

  Start-->|Task| Check_network_connectivity0[check network connectivity]:::task
  Check_network_connectivity0-->|Task| Fail_if_no_network_connectivity1[fail if no network connectivity<br>When: **preflight network check status is not defined or<br>preflight network check status    200**]:::task
  Fail_if_no_network_connectivity1-->|Task| Get_actual_disk_space_on_root_partition2[get actual disk space on root partition]:::task
  Get_actual_disk_space_on_root_partition2-->|Task| Assert_Disk_Space__Root_Partition___20GB_3[assert disk space  root partition   20gb ]:::task
  Assert_Disk_Space__Root_Partition___20GB_3-->|Task| Assert_Memory____4GB_4[assert memory    4gb ]:::task
  Assert_Memory____4GB_4-->|Task| Assert_Architecture__x86_64_5[assert architecture  x86 64 ]:::task
  Assert_Architecture__x86_64_5-->End
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
