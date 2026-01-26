<!-- DOCSIBLE START -->

# 📃 Role overview

## preflight



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




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [preflight_min_ram_mb](defaults/main.yml#L8)   | int | `2048` |    false  |  Minimum RAM |
| [preflight_min_disk_gb](defaults/main.yml#L14)   | int | `20` |    false  |  Minimum Disk Space |



<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>preflight_min_ram_mb</b></td><td>Minimum RAM required in MB.</td></tr>
<tr><td><b>preflight_min_disk_gb</b></td><td>Minimum Disk space on / required in GB.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Set system hostname](tasks/main.yml#L2) | ansible.builtin.hostname | True | Verify network connectivity to K3s download endpoint |
| [Check connectivity](tasks/main.yml#L7) | ansible.builtin.uri | False |  |
| [Fail on disconnect](tasks/main.yml#L17) | ansible.builtin.fail | True | Abort if network is unreachable |
| [Check disk space](tasks/main.yml#L22) | ansible.builtin.shell | False | Check available disk space on root filesystem |
| [Assert disk space](tasks/main.yml#L29) | ansible.builtin.assert | False | Validate disk space meets minimum requirements |
| [Assert memory](tasks/main.yml#L40) | ansible.builtin.assert | False | Validate system memory meets minimum requirements |
| [Assert architecture](tasks/main.yml#L48) | ansible.builtin.assert | False | Validate system architecture is supported |


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
