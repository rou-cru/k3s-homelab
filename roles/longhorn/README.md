<!-- DOCSIBLE START -->

# 📃 Role overview

## longhorn



Description: Deploy Longhorn distributed storage on K3s














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

### License

MIT

### Minimum Ansible Version

2.14

### Platforms

- **Ubuntu**: ['jammy', 'noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
