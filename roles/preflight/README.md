<!-- DOCSIBLE START -->

# 📃 Role overview

## preflight



Description: Pre-flight checks to ensure minimum system requirements are met.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

### Key: main

**Description**: Performs pre-flight checks:
- Network connectivity to get.k3s.io
- Root partition disk space (> 20GB)
- System memory (> 4GB)
- Architecture (x86_64 only)


**Options**:




</details>










### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| [Check connectivity](tasks/main.yml#L2) | ansible.builtin.uri | False |
| [Fail on disconnect](tasks/main.yml#L11) | ansible.builtin.fail | True |
| [Check disk space](tasks/main.yml#L15) | ansible.builtin.shell | False |
| [Assert disk space](tasks/main.yml#L21) | ansible.builtin.assert | False |
| [Assert memory](tasks/main.yml#L29) | ansible.builtin.assert | False |
| [Assert architecture](tasks/main.yml#L34) | ansible.builtin.assert | False |


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

  Start-->|Task| Check_connectivity0[check connectivity]:::task
  Check_connectivity0-->|Task| Fail_on_disconnect1[fail on disconnect<br>When: **preflight network check status is not defined or<br>preflight network check status    200**]:::task
  Fail_on_disconnect1-->|Task| Check_disk_space2[check disk space]:::task
  Check_disk_space2-->|Task| Assert_disk_space3[assert disk space]:::task
  Assert_disk_space3-->|Task| Assert_memory4[assert memory]:::task
  Assert_memory4-->|Task| Assert_architecture5[assert architecture]:::task
  Assert_architecture5-->End
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
