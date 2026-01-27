<!-- DOCSIBLE START -->

# 📃 Role overview

## preflight



Description: Pre-flight checks to ensure minimum system requirements are met.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

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
| [Set system hostname](tasks/main.yml#L2) | ansible.builtin.hostname | True | @docsible Set system hostname |
| [Check connectivity](tasks/main.yml#L8) | ansible.builtin.uri | False | @docsible Verify network connectivity to K3s download endpoint |
| [Fail on disconnect](tasks/main.yml#L18) | ansible.builtin.fail | True | @docsible Fail if network is unreachable |
| [Check disk space](tasks/main.yml#L23) | ansible.builtin.shell | False | @docsible Check available disk space on root filesystem |
| [Assert disk space](tasks/main.yml#L30) | ansible.builtin.assert | False | @docsible Validate minimum disk space requirement |
| [Assert memory](tasks/main.yml#L41) | ansible.builtin.assert | False | @docsible Validate minimum memory requirement |
| [Assert architecture](tasks/main.yml#L49) | ansible.builtin.assert | False | @docsible Validate x86_64 architecture |


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
  Set_system_hostname0-->|Task| Check_connectivity1[check connectivity]:::task
  Check_connectivity1-->|Task| Fail_on_disconnect2[fail on disconnect<br>When: **preflight network check status is not defined or<br>preflight network check status    200**]:::task
  Fail_on_disconnect2-->|Task| Check_disk_space3[check disk space]:::task
  Check_disk_space3-->|Task| Assert_disk_space4[assert disk space]:::task
  Assert_disk_space4-->|Task| Assert_memory5[assert memory]:::task
  Assert_memory5-->|Task| Assert_architecture6[assert architecture]:::task
  Assert_architecture6-->End
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
