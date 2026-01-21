<!-- DOCSIBLE START -->

# 📃 Role overview

## cert_manager














### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [cert_manager_namespace](defaults/main.yml#L5)   | str | `cert-manager` |    false  |  Namespace |
| [cert_manager_chart_version](defaults/main.yml#L10)   | str |  |    false  |  Chart Version |
| [cert_manager_selfsigned_issuer_name](defaults/main.yml#L15)   | str | `homelab-selfsigned-issuer` |    false  |  Self-Signed Issuer Name |
| [cert_manager_ca_certificate_name](defaults/main.yml#L20)   | str | `homelab-ca` |    false  |  CA Certificate Name |
| [cert_manager_ca_secret_name](defaults/main.yml#L25)   | str | `homelab-ca-secret` |    false  |  CA Secret Name |
| [cert_manager_ca_issuer_name](defaults/main.yml#L30)   | str | `homelab-ca-issuer` |    false  |  CA Issuer Name |
| [cert_manager_prometheus_enabled](defaults/main.yml#L35)   | bool | `False` |    false  |  Prometheus Monitoring |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>cert_manager_namespace</b></td><td>Kubernetes namespace where cert-manager will be installed.</td></tr>
<tr><td><b>cert_manager_chart_version</b></td><td>cert-manager Helm chart version (empty for latest).</td></tr>
<tr><td><b>cert_manager_selfsigned_issuer_name</b></td><td>Name for the self-signed certificate issuer.</td></tr>
<tr><td><b>cert_manager_ca_certificate_name</b></td><td>Name for the cluster CA certificate resource.</td></tr>
<tr><td><b>cert_manager_ca_secret_name</b></td><td>Name for the CA private key secret.</td></tr>
<tr><td><b>cert_manager_ca_issuer_name</b></td><td>Name for the cluster CA certificate issuer.</td></tr>
<tr><td><b>cert_manager_prometheus_enabled</b></td><td>Enable Prometheus monitoring integration for cert-manager.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags |
| ---- | ------ | -------------- | -----|
| [Check if Helm is installed](tasks/main.yml#L1) | ansible.builtin.command | False |  |
| [Ensure Jetstack Helm repo](tasks/main.yml#L7) | kubernetes.core.helm_repository | True |  |
| [Deploy cert-manager](tasks/main.yml#L13) | kubernetes.core.helm | True | cluster,infrastructure,cert-manager |
| [Wait for cert-manager webhook to be available](tasks/main.yml#L74) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager |
| [Create cert-manager self-signed ClusterIssuer](tasks/main.yml#L90) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager |
| [Create cert-manager CA certificate](tasks/main.yml#L105) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager |
| [Wait for cert-manager CA secret](tasks/main.yml#L130) | kubernetes.core.k8s_info | True | cluster,infrastructure,cert-manager |
| [Create cert-manager CA ClusterIssuer](tasks/main.yml#L146) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager |


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

  Start-->|Task| Check_if_Helm_is_installed0[check if helm is installed]:::task
  Check_if_Helm_is_installed0-->|Task| Ensure_Jetstack_Helm_repo1[ensure jetstack helm repo<br>When: **helm binary check rc    0**]:::task
  Ensure_Jetstack_Helm_repo1-->|Task| Deploy_cert_manager2[deploy cert manager<br>When: **helm binary check rc    0**]:::task
  Deploy_cert_manager2-->|Task| Wait_for_cert_manager_webhook_to_be_available3[wait for cert manager webhook to be available<br>When: **helm binary check rc    0**]:::task
  Wait_for_cert_manager_webhook_to_be_available3-->|Task| Create_cert_manager_self_signed_ClusterIssuer4[create cert manager self signed clusterissuer<br>When: **helm binary check rc    0**]:::task
  Create_cert_manager_self_signed_ClusterIssuer4-->|Task| Create_cert_manager_CA_certificate5[create cert manager ca certificate<br>When: **helm binary check rc    0**]:::task
  Create_cert_manager_CA_certificate5-->|Task| Wait_for_cert_manager_CA_secret6[wait for cert manager ca secret<br>When: **helm binary check rc    0**]:::task
  Wait_for_cert_manager_CA_secret6-->|Task| Create_cert_manager_CA_ClusterIssuer7[create cert manager ca clusterissuer<br>When: **helm binary check rc    0**]:::task
  Create_cert_manager_CA_ClusterIssuer7-->End
```







#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
