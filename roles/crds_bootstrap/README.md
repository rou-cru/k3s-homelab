<!-- DOCSIBLE START -->

# 📃 Role overview

## crds_bootstrap



Description: Bootstrap cluster-wide CRDs (Gateway API and Prometheus Operator) for add-on charts.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Installs Gateway API standard CRDs and Prometheus Operator CRDs
required by various Helm charts and operators.


**Options**:


  - **gateway_apiVersion**
    - **Required**: False
    - **Type**: str
    - **Default**: v1.2.0
  
    - **Description**: Gateway API CRDs version to install.
  
  
  

  - **prometheus_operatorCrdsNamespace**
    - **Required**: False
    - **Type**: str
    - **Default**: monitoring
  
    - **Description**: Namespace for Prometheus Operator CRDs.
  
  
  

  - **prometheus_operatorCrdsVersion**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Prometheus Operator CRDs Helm chart version.
  
  
  

  - **kubeconfig**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Path to kubeconfig for cluster access.
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Install Gateway API CRDs](tasks/main.yml#L2) | kubernetes.core.k8s | True | cluster,infrastructure | @docsible Install Gateway API standard CRDs |
| [Wait for Gateway API CRDs to be established](tasks/main.yml#L12) | kubernetes.core.k8s_info | True | cluster,infrastructure | @docsible Wait for Gateway CRDs to be established |
| [Add Prometheus Community Helm repo](tasks/main.yml#L27) | kubernetes.core.helm_repository | True | cluster,infrastructure | @docsible Add Prometheus Community Helm repository |
| [Install Prometheus Operator CRDs](tasks/main.yml#L36) | kubernetes.core.helm | True | cluster,infrastructure | @docsible Install Prometheus Operator CRDs via Helm |


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

  Start-->|Task| Install_Gateway_API_CRDs0[install gateway api crds<br>When: **not ansible check mode**]:::task
  Install_Gateway_API_CRDs0-->|Task| Wait_for_Gateway_API_CRDs_to_be_established1[wait for gateway api crds to be established<br>When: **not ansible check mode**]:::task
  Wait_for_Gateway_API_CRDs_to_be_established1-->|Task| Add_Prometheus_Community_Helm_repo2[add prometheus community helm repo<br>When: **not ansible check mode**]:::task
  Add_Prometheus_Community_Helm_repo2-->|Task| Install_Prometheus_Operator_CRDs3[install prometheus operator crds<br>When: **not ansible check mode**]:::task
  Install_Prometheus_Operator_CRDs3-->End
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
