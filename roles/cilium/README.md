<!-- DOCSIBLE START -->

# 📃 Role overview

## cilium





| Field                | Value           |
|--------------------- |-----------------|
| Readme update        | 2026/01/05 |








### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |
|--------------|--------------|-------------|
| [cilium_version](defaults/main.yml#L2)   | str | `1.18.5` |    
| [cilium_chart_repo](defaults/main.yml#L3)   | str | `https://helm.cilium.io/` |    
| [cilium_chart_name](defaults/main.yml#L4)   | str | `cilium` |    
| [cilium_namespace](defaults/main.yml#L5)   | str | `kube-system` |    
| [cilium_rollout_timeout](defaults/main.yml#L6)   | int | `300` |    
| [cilium_wait_retries](defaults/main.yml#L7)   | int | `60` |    
| [cilium_wait_delay](defaults/main.yml#L8)   | int | `5` |    





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| Create temporary values file | ansible.builtin.tempfile | False |
| Template Cilium values file | ansible.builtin.template | False |
| Install Cilium via Helm | kubernetes.core.helm | False |
| Wait for Cilium DaemonSet to be created | ansible.builtin.command | False |
| Wait for cilium pods | ansible.builtin.command | False |
| Remove temporary values file | ansible.builtin.file | False |


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

  Start-->|Task| Create_temporary_values_file0[create temporary values file]:::task
  Create_temporary_values_file0-->|Task| Template_Cilium_values_file1[template cilium values file]:::task
  Template_Cilium_values_file1-->|Task| Install_Cilium_via_Helm2[install cilium via helm]:::task
  Install_Cilium_via_Helm2-->|Task| Wait_for_Cilium_DaemonSet_to_be_created3[wait for cilium daemonset to be created]:::task
  Wait_for_Cilium_DaemonSet_to_be_created3-->|Task| Wait_for_cilium_pods4[wait for cilium pods]:::task
  Wait_for_cilium_pods4-->|Task| Remove_temporary_values_file5[remove temporary values file]:::task
  Remove_temporary_values_file5-->End
```







#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
