<!-- DOCSIBLE START -->

# 📃 Role overview

## k3s_common



Description: Common configurations for K3s nodes (server and agent)














### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Ensure K3s config directory exists](tasks/main.yml#L2) | ansible.builtin.file | False | main.yml - K3s Common logic |
| [Ensure registries.d exists](tasks/main.yml#L8) | ansible.builtin.file | False |  |
| [Deploy registries.yaml](tasks/main.yml#L14) | ansible.builtin.template | True |  |
| [Deploy containerd-config.toml](tasks/main.yml#L24) | ansible.builtin.template | True |  |
| [Create containerd scripts dir](tasks/main.yml#L31) | ansible.builtin.file | True |  |
| [Deploy runtime check script](tasks/main.yml#L38) | ansible.builtin.template | True |  |
| [Ensure k3s service override dir](tasks/main.yml#L45) | ansible.builtin.file | True |  |
| [Reload systemd and restart k3s](tasks/main.yml#L52) | ansible.builtin.systemd | True |  |


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

  Start-->|Task| Ensure_K3s_config_directory_exists0[ensure k3s config directory exists]:::task
  Ensure_K3s_config_directory_exists0-->|Task| Ensure_registries_d_exists1[ensure registries d exists]:::task
  Ensure_registries_d_exists1-->|Task| Deploy_registries_yaml2[deploy registries yaml<br>When: **k3s commonregistryauths is defined and k3s<br>commonregistryauths   length   0**]:::task
  Deploy_registries_yaml2-->|Task| Deploy_containerd_config_toml3[deploy containerd config toml<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Deploy_containerd_config_toml3-->|Task| Create_containerd_scripts_dir4[create containerd scripts dir<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Create_containerd_scripts_dir4-->|Task| Deploy_runtime_check_script5[deploy runtime check script<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Deploy_runtime_check_script5-->|Task| Ensure_k3s_service_override_dir6[ensure k3s service override dir<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Ensure_k3s_service_override_dir6-->|Task| Reload_systemd_and_restart_k3s7[reload systemd and restart k3s<br>When: **k3s commoncontainerdadditionalruntimes   default  <br>    length   0**]:::task
  Reload_systemd_and_restart_k3s7-->End
```





## Author Information
rc

### License

MIT

### Minimum Ansible Version

2.14

### Platforms

- **Ubuntu**: ['jammy', 'noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
