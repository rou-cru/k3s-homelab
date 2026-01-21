<!-- DOCSIBLE START -->

# 📃 Role overview

## longhorn



Description: Deploy Longhorn distributed storage on K3s










### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [longhorn_chart_version](defaults/main.yml#L7)   | str | `1.7.2` |    false  |  Longhorn Chart Version |
| [longhorn_default_replica_count](defaults/main.yml#L13)   | int | `1` |    false  |  Default Replica Count |
| [longhorn_data_locality](defaults/main.yml#L19)   | str | `best-effort` |    false  |  Data Locality |
| [longhorn_storage_over_provisioning](defaults/main.yml#L25)   | int | `100` |    false  |  Storage Over Provisioning |
| [longhorn_storage_minimal_available](defaults/main.yml#L31)   | int | `25` |    false  |  Storage Minimal Available |
| [longhorn_default_class](defaults/main.yml#L37)   | bool | `True` |    false  |  Default Storage Class |
| [longhorn_backup_target](defaults/main.yml#L43)   | str |  |    false  |  Backup Target |
| [longhorn_backup_credential_secret](defaults/main.yml#L49)   | str |  |    false  |  Backup Target Credential Secret |
| [longhorn_guaranteed_engine_manager_cpu](defaults/main.yml#L55)   | int | `12` |    false  |  Guaranteed Engine Manager CPU |
| [longhorn_guaranteed_replica_manager_cpu](defaults/main.yml#L61)   | int | `12` |    false  |  Guaranteed Replica Manager CPU |
| [longhorn_priority_class](defaults/main.yml#L67)   | str | `priority-ops-critical` |    false  |  Priority Class |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>longhorn_chart_version</b></td><td>Version of Longhorn Helm chart to install.</td></tr>
<tr><td><b>longhorn_default_replica_count</b></td><td>Default number of replicas for volumes.</td></tr>
<tr><td><b>longhorn_data_locality</b></td><td>Data locality setting (disabled, best-effort, strict-local).</td></tr>
<tr><td><b>longhorn_storage_over_provisioning</b></td><td>Percentage of storage over-provisioning allowed.</td></tr>
<tr><td><b>longhorn_storage_minimal_available</b></td><td>Minimum percentage of storage that must remain available.</td></tr>
<tr><td><b>longhorn_default_class</b></td><td>Whether to set Longhorn as the default StorageClass.</td></tr>
<tr><td><b>longhorn_backup_target</b></td><td>Backup target URL (e.g., s3://bucket or nfs://server/path).</td></tr>
<tr><td><b>longhorn_backup_credential_secret</b></td><td>Name of the secret containing backup credentials.</td></tr>
<tr><td><b>longhorn_guaranteed_engine_manager_cpu</b></td><td>CPU allocation for engine manager.</td></tr>
<tr><td><b>longhorn_guaranteed_replica_manager_cpu</b></td><td>CPU allocation for replica manager.</td></tr>
<tr><td><b>longhorn_priority_class</b></td><td>PriorityClass for Longhorn components.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install Longhorn dependencies](tasks/main.yml#L6) | ansible.builtin.apt | False | Install iscsi tools (required by Longhorn) |
| [Enable iscsid service](tasks/main.yml#L14) | ansible.builtin.systemd | False | Enable and start iscsid service |
| [Add Longhorn Helm repository](tasks/main.yml#L21) | kubernetes.core.helm_repository | False | Add Longhorn Helm repository |
| [Create longhorn-system namespace](tasks/main.yml#L28) | kubernetes.core.k8s | False | Create longhorn-system namespace |
| [Deploy Longhorn](tasks/main.yml#L41) | kubernetes.core.helm | False | Deploy Longhorn |
| [Wait for Longhorn manager](tasks/main.yml#L70) | kubernetes.core.k8s_info | True | Wait for Longhorn to be ready |
| [Display Longhorn status](tasks/main.yml#L86) | ansible.builtin.debug | False | Display post-installation info |


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

  Start-->|Task| Install_Longhorn_dependencies0[install longhorn dependencies]:::task
  Install_Longhorn_dependencies0-->|Task| Enable_iscsid_service1[enable iscsid service]:::task
  Enable_iscsid_service1-->|Task| Add_Longhorn_Helm_repository2[add longhorn helm repository]:::task
  Add_Longhorn_Helm_repository2-->|Task| Create_longhorn_system_namespace3[create longhorn system namespace]:::task
  Create_longhorn_system_namespace3-->|Task| Deploy_Longhorn4[deploy longhorn]:::task
  Deploy_Longhorn4-->|Task| Wait_for_Longhorn_manager5[wait for longhorn manager<br>When: **not ansible check mode**]:::task
  Wait_for_Longhorn_manager5-->|Task| Display_Longhorn_status6[display longhorn status]:::task
  Display_Longhorn_status6-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.14

#### Platforms

- **Ubuntu**: ['jammy', 'noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
