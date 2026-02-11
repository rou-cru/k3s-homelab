<!-- DOCSIBLE START -->

# 📃 Role overview

## cilium



Description: Installs and configures Cilium CNI for K3s clusters.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Deploys Cilium CNI using Helm, managing values templating and rollout verification.


**Options**:


  - **cilium_chartVersion**
    - **Required**: False
    - **Type**: str
    - **Default**: 1.18.5
  
    - **Description**: Version of the Cilium Helm chart to install.
  
  
  

  - **cilium_chartName**
    - **Required**: False
    - **Type**: str
    - **Default**: cilium
  
    - **Description**: Name of the chart in the repository (e.g., cilium/cilium).
  
  
  

  - **cilium_namespace**
    - **Required**: False
    - **Type**: str
    - **Default**: kube-system
  
    - **Description**: Kubernetes namespace where Cilium should be installed.
  
  
  

  - **cilium_rolloutTimeout**
    - **Required**: False
    - **Type**: int
    - **Default**: 300
  
    - **Description**: Timeout (seconds) for waiting for Cilium pods rollout.
  
  
  

  - **cilium_waitRetries**
    - **Required**: False
    - **Type**: int
    - **Default**: 60
  
    - **Description**: Number of retries when checking for DaemonSet creation.
  
  
  

  - **cilium_waitDelay**
    - **Required**: False
    - **Type**: int
    - **Default**: 5
  
    - **Description**: Delay (seconds) between DaemonSet existence checks.
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Ensure Cilium Helm repo](tasks/main.yml#L2) | kubernetes.core.helm_repository | True | @docsible Registers Cilium Helm repository |
| [Install Cilium via Helm](tasks/main.yml#L10) | kubernetes.core.helm | True | @docsible Installs Cilium (values.yaml + dynamic overrides) |
| [Wait for Cilium DaemonSet to be created](tasks/main.yml#L25) | kubernetes.core.k8s_info | True | @docsible Waits for Cilium DaemonSet existence |
| [Wait for cilium pods](tasks/main.yml#L38) | kubernetes.core.k8s_info | True | @docsible Waits for full Cilium DaemonSet rollout |


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

  Start-->|Task| Ensure_Cilium_Helm_repo0[ensure cilium helm repo<br>When: **not ansible check mode**]:::task
  Ensure_Cilium_Helm_repo0-->|Task| Install_Cilium_via_Helm1[install cilium via helm<br>When: **not ansible check mode**]:::task
  Install_Cilium_via_Helm1-->|Task| Wait_for_Cilium_DaemonSet_to_be_created2[wait for cilium daemonset to be created<br>When: **not ansible check mode**]:::task
  Wait_for_Cilium_DaemonSet_to_be_created2-->|Task| Wait_for_cilium_pods3[wait for cilium pods<br>When: **not ansible check mode**]:::task
  Wait_for_cilium_pods3-->End
```





## Author Information
rc

### License

MIT

### Minimum Ansible Version

2.20.0

### Platforms

- **Ubuntu**: ['noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
