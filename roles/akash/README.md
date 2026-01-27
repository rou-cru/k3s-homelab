<!-- DOCSIBLE START -->

# 📃 Role overview

## akash



Description: Deploy Akash Provider stack on K3s cluster














### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate Akash configuration](tasks/main.yml#L6) | ansible.builtin.assert | False | Validate required variables |
| [Add Akash Helm repository](tasks/main.yml#L14) | kubernetes.core.helm_repository | False | Add Akash Helm repository |
| [Add Ingress Nginx Helm repository](tasks/main.yml#L21) | kubernetes.core.helm_repository | False | Add Ingress Nginx Helm repository |
| [Create akash-services namespace](tasks/main.yml#L28) | kubernetes.core.k8s | False | Create akash-services namespace |
| [Deploy Ingress Nginx for Akash](tasks/main.yml#L42) | kubernetes.core.helm | False | Deploy Ingress Nginx for Akash |
| [Deploy Akash Hostname Operator](tasks/main.yml#L74) | kubernetes.core.helm | False | Deploy Akash Hostname Operator |
| [Deploy Akash Inventory Operator](tasks/main.yml#L84) | kubernetes.core.helm | False | Deploy Akash Inventory Operator |
| [Build provider attributes](tasks/main.yml#L94) | ansible.builtin.set_fact | False | Build provider attributes |
| [Deploy Akash Provider](tasks/main.yml#L108) | kubernetes.core.helm | True | Deploy Akash Provider |
| [Display Akash setup instructions](tasks/main.yml#L139) | ansible.builtin.debug | False | Display post-installation instructions |


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

  Start-->|Task| Validate_Akash_configuration0[validate akash configuration]:::task
  Validate_Akash_configuration0-->|Task| Add_Akash_Helm_repository1[add akash helm repository]:::task
  Add_Akash_Helm_repository1-->|Task| Add_Ingress_Nginx_Helm_repository2[add ingress nginx helm repository]:::task
  Add_Ingress_Nginx_Helm_repository2-->|Task| Create_akash_services_namespace3[create akash services namespace]:::task
  Create_akash_services_namespace3-->|Task| Deploy_Ingress_Nginx_for_Akash4[deploy ingress nginx for akash]:::task
  Deploy_Ingress_Nginx_for_Akash4-->|Task| Deploy_Akash_Hostname_Operator5[deploy akash hostname operator]:::task
  Deploy_Akash_Hostname_Operator5-->|Task| Deploy_Akash_Inventory_Operator6[deploy akash inventory operator]:::task
  Deploy_Akash_Inventory_Operator6-->|Task| Build_provider_attributes7[build provider attributes]:::task
  Build_provider_attributes7-->|Task| Deploy_Akash_Provider8[deploy akash provider<br>When: **akash wallet address   length   0**]:::task
  Deploy_Akash_Provider8-->|Task| Display_Akash_setup_instructions9[display akash setup instructions]:::task
  Display_Akash_setup_instructions9-->End
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

- **gvisor**
  
  

<!-- DOCSIBLE END -->
