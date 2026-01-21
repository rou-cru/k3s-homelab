<!-- DOCSIBLE START -->

# 📃 Role overview

## crds_bootstrap














### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       | Title       |
|--------------|--------------|-------------|-------------|
| [gateway_api_version](defaults/main.yml#L4)   | str | `v1.2.0` |     Gateway API Version |
| [prometheus_operator_crds_version](defaults/main.yml#L9)   | str | `26.0.0` |     Prometheus Operator CRDs Chart Version |
| [prometheus_operator_crds_namespace](defaults/main.yml#L14)   | str | `monitoring` |     Prometheus Operator CRDs Namespace |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>gateway_api_version</b></td><td>Version tag for Gateway API standard install manifest.</td></tr>
<tr><td><b>prometheus_operator_crds_version</b></td><td>Version of the prometheus-operator-crds Helm chart.</td></tr>
<tr><td><b>prometheus_operator_crds_namespace</b></td><td>Namespace where CRDs chart metadata will be installed (CRDs are global).</td></tr>
</table>
<br>
</details>





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







#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
