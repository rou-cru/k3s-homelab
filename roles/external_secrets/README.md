<!-- DOCSIBLE START -->

# 📃 Role overview

## external_secrets














### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [oci_config_file](defaults/main.yml#L5)   | str | `{{ playbook_dir }}/.oci` |    false  |  OCI Configuration File |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>oci_config_file</b></td><td>Path to Oracle Cloud Infrastructure configuration file.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags |
| ---- | ------ | -------------- | -----|
| [Check if Helm is installed](tasks/main.yml#L1) | ansible.builtin.command | False |  |
| [Ensure External Secrets Helm repo](tasks/main.yml#L7) | kubernetes.core.helm_repository | True |  |
| [Deploy External Secrets Operator](tasks/main.yml#L13) | kubernetes.core.helm | True | cluster,infrastructure,external-secrets |
| [Wait for external-secrets webhook CA bundle](tasks/main.yml#L70) | kubernetes.core.k8s_info | True | cluster,infrastructure,external-secrets |
| [Wait for external-secrets webhook to be ready](tasks/main.yml#L91) | kubernetes.core.k8s | True | cluster,infrastructure,external-secrets |
| [Create OCI Auth Secret](tasks/main.yml#L107) | kubernetes.core.k8s | True | cluster,infrastructure,external-secrets,oci |
| [Create OCI ClusterSecretStore](tasks/main.yml#L128) | kubernetes.core.k8s | True | cluster,infrastructure,external-secrets,oci |


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
  Check_if_Helm_is_installed0-->|Task| Ensure_External_Secrets_Helm_repo1[ensure external secrets helm repo<br>When: **helm binary check rc    0**]:::task
  Ensure_External_Secrets_Helm_repo1-->|Task| Deploy_External_Secrets_Operator2[deploy external secrets operator<br>When: **helm binary check rc    0**]:::task
  Deploy_External_Secrets_Operator2-->|Task| Wait_for_external_secrets_webhook_CA_bundle3[wait for external secrets webhook ca bundle<br>When: **helm binary check rc    0**]:::task
  Wait_for_external_secrets_webhook_CA_bundle3-->|Task| Wait_for_external_secrets_webhook_to_be_ready4[wait for external secrets webhook to be ready<br>When: **helm binary check rc    0**]:::task
  Wait_for_external_secrets_webhook_to_be_ready4-->|Task| Create_OCI_Auth_Secret5[create oci auth secret<br>When: **helm binary check rc    0**]:::task
  Create_OCI_Auth_Secret5-->|Task| Create_OCI_ClusterSecretStore6[create oci clustersecretstore<br>When: **helm binary check rc    0**]:::task
  Create_OCI_ClusterSecretStore6-->End
```







#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
