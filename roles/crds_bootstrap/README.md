<!-- DOCSIBLE START -->

# 📃 Role overview

## crds_bootstrap



Description: Bootstrap cluster-wide CRDs (Gateway API and Prometheus Operator) for add-on charts.














### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install Gateway API CRDs](tasks/main.yml#L2) | kubernetes.core.k8s | False | Install Gateway API CRDs |
| [Wait for Gateway API CRDs to be established](tasks/main.yml#L9) | kubernetes.core.k8s_info | False |  |
| [Add Prometheus Community Helm repo](tasks/main.yml#L22) | kubernetes.core.helm_repository | False | Install Prometheus Operator CRDs via Helm |
| [Install Prometheus Operator CRDs](tasks/main.yml#L28) | kubernetes.core.helm | False |  |


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

  Start-->|Task| Install_Gateway_API_CRDs0[install gateway api crds]:::task
  Install_Gateway_API_CRDs0-->|Task| Wait_for_Gateway_API_CRDs_to_be_established1[wait for gateway api crds to be established]:::task
  Wait_for_Gateway_API_CRDs_to_be_established1-->|Task| Add_Prometheus_Community_Helm_repo2[add prometheus community helm repo]:::task
  Add_Prometheus_Community_Helm_repo2-->|Task| Install_Prometheus_Operator_CRDs3[install prometheus operator crds]:::task
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
