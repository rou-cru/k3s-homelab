<!-- DOCSIBLE START -->

# 📃 Role overview

## gvisor



Description: Install gVisor runsc and register a RuntimeClass for K3s server workloads.










### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [gvisor_version](defaults/main.yml#L5)   | str | `20231204.0` |    false  |  gVisor Version |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>gvisor_version</b></td><td>Version of gVisor runtime to install.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/host.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Install runsc binary](tasks/host.yml#L2) | ansible.builtin.get_url | True |  | Installation of gVisor (runsc) |
| [Add gVisor to additional runtimes list](tasks/host.yml#L13) | ansible.builtin.set_fact | True | a,l,w,a,y,s | Register gVisor as an available runtime for the cluster |

#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| [Install gVisor runtime (host)](tasks/main.yml#L1) | ansible.builtin.include_tasks | False |

#### File: tasks/runtimeclass.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Ensure K3s manifests directory exists](tasks/runtimeclass.yml#L2) | ansible.builtin.file | True | Use K3s auto-deploy manifests directory for the RuntimeClass |
| [Deploy gVisor RuntimeClass manifest](tasks/runtimeclass.yml#L11) | ansible.builtin.copy | True |  |


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

  Start-->|Task| Install_runsc_binary0[install runsc binary<br>When: **k3s server  in group names**]:::task
  Install_runsc_binary0-->|Task| Add_gVisor_to_additional_runtimes_list1[add gvisor to additional runtimes list<br>When: **k3s server  in group names**]:::task
  Add_gVisor_to_additional_runtimes_list1-->End
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

  Start-->|Include task| Install_gVisor_runtime__host__host_yml_0[install gvisor runtime  host <br>include_task: host yml]:::includeTasks
  Install_gVisor_runtime__host__host_yml_0-->End
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

  Start-->|Task| Ensure_K3s_manifests_directory_exists0[ensure k3s manifests directory exists<br>When: **k3s server  in group names**]:::task
  Ensure_K3s_manifests_directory_exists0-->|Task| Deploy_gVisor_RuntimeClass_manifest1[deploy gvisor runtimeclass manifest<br>When: **k3s server  in group names**]:::task
  Deploy_gVisor_RuntimeClass_manifest1-->End
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
