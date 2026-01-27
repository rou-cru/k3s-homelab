<!-- DOCSIBLE START -->

# 📃 Role overview

## akash



Description: Deploy Akash Provider stack on K3s cluster






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Installs and configures Akash Network provider on K3s,
including hostname operator, inventory operator, and ingress controller.


**Options**:


  - **akash_walletAddress**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Akash wallet address for provider payments.
  
  
  

  - **akash_providerDomain**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Domain for provider endpoints.
  
  
  

  - **akash_nodeMoniker**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Provider node moniker (name).
  
  
  

  - **akash_chainId**
    - **Required**: False
    - **Type**: str
    - **Default**: akashnet-2
  
    - **Description**: Akash network chain ID.
  
  
  

  - **akash_nodeRpc**
    - **Required**: False
    - **Type**: str
    - **Default**: https://rpc.akashnet.net:443
  
    - **Description**: Akash RPC endpoint.
  
  
  

  - **akash_keyringBackend**
    - **Required**: False
    - **Type**: str
    - **Default**: file
  
    - **Description**: Keyring backend for wallet storage.
  
  
  

  - **akash_gpuEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable GPU support in provider attributes.
  
  
  

  - **akash_gpuVendor**
    - **Required**: False
    - **Type**: str
    - **Default**: nvidia
  
    - **Description**: GPU vendor for provider attributes.
  
  
  

  - **akash_gpuModel**
    - **Required**: False
    - **Type**: str
    - **Default**: rtx3060
  
    - **Description**: GPU model for provider attributes.
  
  
  

  - **akash_providerAttributes**
    - **Required**: False
    - **Type**: list
    - **Default**: []
  
    - **Description**: List of provider attribute objects.
  
  
  

  - **akash_ingressNginxVersion**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Ingress NGINX Helm chart version.
  
  
  

  - **akash_hostnameOperatorVersion**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Hostname operator Helm chart version.
  
  
  

  - **akash_inventoryOperatorVersion**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Inventory operator Helm chart version.
  
  
  

  - **akash_providerVersion**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Provider Helm chart version.
  
  
  

  - **kubeconfig**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Path to kubeconfig for cluster access.
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate Akash configuration](tasks/main.yml#L3) | ansible.builtin.assert | False | @docsible Validate required Akash configuration variables |
| [Add Akash Helm repository](tasks/main.yml#L11) | kubernetes.core.helm_repository | False | @docsible Add Akash Network Helm repository |
| [Add Ingress Nginx Helm repository](tasks/main.yml#L18) | kubernetes.core.helm_repository | False | @docsible Add Ingress NGINX Helm repository |
| [Create akash-services namespace](tasks/main.yml#L25) | kubernetes.core.k8s | False | @docsible Create dedicated namespace with restricted pod security |
| [Deploy Ingress Nginx for Akash](tasks/main.yml#L39) | kubernetes.core.helm | False | @docsible Deploy Ingress NGINX controller for Akash workloads |
| [Deploy Akash Hostname Operator](tasks/main.yml#L71) | kubernetes.core.helm | False | @docsible Deploy hostname operator for custom domains |
| [Deploy Akash Inventory Operator](tasks/main.yml#L81) | kubernetes.core.helm | False | @docsible Deploy inventory operator for resource tracking |
| [Build provider attributes](tasks/main.yml#L91) | ansible.builtin.set_fact | False | @docsible Build provider attributes including GPU if enabled |
| [Deploy Akash Provider](tasks/main.yml#L105) | kubernetes.core.helm | True | @docsible Deploy Akash provider with bidding configuration |
| [Display Akash setup instructions](tasks/main.yml#L136) | ansible.builtin.debug | False | @docsible Display deployment status and next steps |


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
  Build_provider_attributes7-->|Task| Deploy_Akash_Provider8[deploy akash provider<br>When: **akash walletaddress   length   0**]:::task
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
