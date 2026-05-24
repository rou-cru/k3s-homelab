<!-- DOCSIBLE START -->

# 📃 Role overview

## k3s_runtime_discovery




















### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Check for runsc binary](tasks/main.yml#L4) | ansible.builtin.stat | False | @docsible Checks whether gVisor runsc binary is installed |
| [Check for nvidia-container-runtime](tasks/main.yml#L10) | ansible.builtin.stat | False | @docsible Checks whether NVIDIA container runtime is installed |
| [Build containerd runtime list](tasks/main.yml#L16) | ansible.builtin.set_fact | False | @docsible Builds base list of detected containerd runtimes |
| [Update containerd runtime list](tasks/main.yml#L21) | ansible.builtin.set_fact | False | @docsible Merges detected runtimes into k3s_commonContainerdAdditionalRuntimes |


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

  Start-->|Task| Check_for_runsc_binary0[check for runsc binary]:::task
  Check_for_runsc_binary0-->|Task| Check_for_nvidia_container_runtime1[check for nvidia container runtime]:::task
  Check_for_nvidia_container_runtime1-->|Task| Build_containerd_runtime_list2[build containerd runtime list]:::task
  Build_containerd_runtime_list2-->|Task| Update_containerd_runtime_list3[update containerd runtime list]:::task
  Update_containerd_runtime_list3-->End
```







#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
