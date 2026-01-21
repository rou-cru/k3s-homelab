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


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Install runsc binary](tasks/main.yml#L2) | ansible.builtin.get_url | False |  | Installation of gVisor (runsc) |
| [Add gVisor to additional runtimes list](tasks/main.yml#L12) | ansible.builtin.set_fact | False | a,l,w,a,y,s | Register gVisor as an available runtime for the cluster |
| [Ensure K3s manifests directory exists](tasks/main.yml#L18) | ansible.builtin.file | False |  | Use K3s auto-deploy manifests directory for the RuntimeClass |
| [Deploy gVisor RuntimeClass manifest](tasks/main.yml#L26) | ansible.builtin.copy | False |  |  |


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

  Start-->|Task| Install_runsc_binary0[install runsc binary]:::task
  Install_runsc_binary0-->|Task| Add_gVisor_to_additional_runtimes_list1[add gvisor to additional runtimes list]:::task
  Add_gVisor_to_additional_runtimes_list1-->|Task| Ensure_K3s_manifests_directory_exists2[ensure k3s manifests directory exists]:::task
  Ensure_K3s_manifests_directory_exists2-->|Task| Deploy_gVisor_RuntimeClass_manifest3[deploy gvisor runtimeclass manifest]:::task
  Deploy_gVisor_RuntimeClass_manifest3-->End
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

- **k3s_server**
  
  

<!-- DOCSIBLE END -->
