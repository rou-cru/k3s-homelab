<!-- DOCSIBLE START -->

# 📃 Role overview

## glances



Description: Install and configure Glances system monitoring with web interface.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: 
- Installs Glances in a Python virtual environment
- Configures systemd service for web interface


**Options**:


  - **glances_state**
    - **Required**: false
    - **Type**: str
    - **Default**: present
  
    - **Description**: Whether Glances should be installed or removed.
  
      - **Choices**:
    
          - present
    
          - absent
    
  
  
  

  - **glances_port**
    - **Required**: false
    - **Type**: int
    - **Default**: 61208
  
    - **Description**: Port for Glances web interface.
  
  
  

  - **glances_bind_address**
    - **Required**: false
    - **Type**: str
    - **Default**: 127.0.0.1
  
    - **Description**: Address to bind Glances web server.
  
  
  

  - **glances_venv_path**
    - **Required**: false
    - **Type**: str
    - **Default**: /opt/glances
  
    - **Description**: Path for Python virtual environment.
  
  
  

  - **glances_packages**
    - **Required**: false
    - **Type**: list
    - **Default**: ['glances[all]']
  
    - **Description**: Glances packages to install with extras.
  
  
  



</details>




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |
|--------------|--------------|-------------|
| [glances_state](defaults/main.yml#L1)   | str | `present` |    
| [glances_port](defaults/main.yml#L2)   | int | `61208` |    
| [glances_bind_address](defaults/main.yml#L3)   | str | `127.0.0.1` |    
| [glances_venv_path](defaults/main.yml#L4)   | str | `/opt/glances` |    
| [glances_packages](defaults/main.yml#L6)   | list | `[]` |    
| [glances_packages.**0**](defaults/main.yml#L7)   | str | `glances[all]` |    





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| [Check hddtemp availability](tasks/main.yml#L1) | ansible.builtin.command | False |
| [Build Glances system package list](tasks/main.yml#L7) | ansible.builtin.set_fact | False |
| [Install system dependencies for Glances and sensors](tasks/main.yml#L16) | ansible.builtin.apt | False |
| [Create directory for Glances venv](tasks/main.yml#L22) | ansible.builtin.file | False |
| [Create Glances virtual environment (uv)](tasks/main.yml#L27) | ansible.builtin.command | False |
| [Install Glances in virtual environment (uv)](tasks/main.yml#L34) | ansible.builtin.command | False |
| [Create Systemd service for Glances Web](tasks/main.yml#L40) | ansible.builtin.template | False |
| [Ensure Glances service is enabled and running](tasks/main.yml#L46) | ansible.builtin.systemd | False |


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

  Start-->|Task| Check_hddtemp_availability0[check hddtemp availability]:::task
  Check_hddtemp_availability0-->|Task| Build_Glances_system_package_list1[build glances system package list]:::task
  Build_Glances_system_package_list1-->|Task| Install_system_dependencies_for_Glances_and_sensors2[install system dependencies for glances and<br>sensors]:::task
  Install_system_dependencies_for_Glances_and_sensors2-->|Task| Create_directory_for_Glances_venv3[create directory for glances venv]:::task
  Create_directory_for_Glances_venv3-->|Task| Create_Glances_virtual_environment__uv_4[create glances virtual environment  uv ]:::task
  Create_Glances_virtual_environment__uv_4-->|Task| Install_Glances_in_virtual_environment__uv_5[install glances in virtual environment  uv ]:::task
  Install_Glances_in_virtual_environment__uv_5-->|Task| Create_Systemd_service_for_Glances_Web6[create systemd service for glances web]:::task
  Create_Systemd_service_for_Glances_Web6-->|Task| Ensure_Glances_service_is_enabled_and_running7[ensure glances service is enabled and running]:::task
  Ensure_Glances_service_is_enabled_and_running7-->End
```





## Author Information
Roura

#### License

MIT

#### Minimum Ansible Version

2.20.0

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
