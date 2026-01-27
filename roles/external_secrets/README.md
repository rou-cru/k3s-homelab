<!-- DOCSIBLE START -->

# 📃 Role overview

## external_secrets



Description: Install External Secrets Operator and configure an OCI Vault-backed ClusterSecretStore (requires cert-manager).






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Deploys External Secrets Operator and configures an OCI Vault-backed
ClusterSecretStore for external secret management.


**Options**:


  - **externalSecrets_namespace**
    - **Required**: False
    - **Type**: str
    - **Default**: external-secrets
  
    - **Description**: Namespace for External Secrets Operator.
  
  
  

  - **externalSecrets_chartVersion**
    - **Required**: False
    - **Type**: str
    - **Default**: none
  
    - **Description**: Helm chart version (omit for latest).
  
  
  

  - **externalSecrets_webhookIssuerName**
    - **Required**: False
    - **Type**: str
    - **Default**: selfsigned-issuer
  
    - **Description**: ClusterIssuer for webhook certificates.
  
  
  

  - **externalSecrets_serviceMonitorEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable Prometheus ServiceMonitor.
  
  
  

  - **externalSecrets_grafanaDashboardEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable Grafana dashboard ConfigMap.
  
  
  

  - **kubeconfig**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Path to kubeconfig for cluster access.
  
  
  

  - **oci_configFile**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Path to OCI CLI configuration file.
  
  
  



</details>








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Check if Helm is installed](tasks/main.yml#L2) | ansible.builtin.stat | False |  | @docsible Verify Helm CLI availability |
| [Ensure External Secrets Helm repo](tasks/main.yml#L9) | kubernetes.core.helm_repository | True |  | @docsible Add External Secrets Helm repository |
| [Deploy External Secrets Operator](tasks/main.yml#L18) | kubernetes.core.helm | True | cluster,infrastructure,external-secrets | @docsible Deploy External Secrets Operator via Helm |
| [Wait for external-secrets webhook CA bundle](tasks/main.yml#L80) | kubernetes.core.k8s_info | True | cluster,infrastructure,external-secrets | @docsible Wait for webhook CA bundle population |
| [Wait for external-secrets webhook to be ready](tasks/main.yml#L104) | kubernetes.core.k8s | True | cluster,infrastructure,external-secrets | @docsible Wait for webhook deployment readiness |
| [Create OCI Auth Secret](tasks/main.yml#L123) | kubernetes.core.k8s | True | cluster,infrastructure,external-secrets,oci | @docsible Create OCI Vault authentication secret |
| [Create OCI ClusterSecretStore](tasks/main.yml#L147) | kubernetes.core.k8s | True | cluster,infrastructure,external-secrets,oci | @docsible Create OCI Vault ClusterSecretStore |


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
  Check_if_Helm_is_installed0-->|Task| Ensure_External_Secrets_Helm_repo1[ensure external secrets helm repo<br>When: **helm binary check stat exists and not ansible<br>check mode**]:::task
  Ensure_External_Secrets_Helm_repo1-->|Task| Deploy_External_Secrets_Operator2[deploy external secrets operator<br>When: **helm binary check stat exists and not ansible<br>check mode**]:::task
  Deploy_External_Secrets_Operator2-->|Task| Wait_for_external_secrets_webhook_CA_bundle3[wait for external secrets webhook ca bundle<br>When: **helm binary check stat exists and not ansible<br>check mode**]:::task
  Wait_for_external_secrets_webhook_CA_bundle3-->|Task| Wait_for_external_secrets_webhook_to_be_ready4[wait for external secrets webhook to be ready<br>When: **helm binary check stat exists and not ansible<br>check mode**]:::task
  Wait_for_external_secrets_webhook_to_be_ready4-->|Task| Create_OCI_Auth_Secret5[create oci auth secret<br>When: **helm binary check stat exists and not ansible<br>check mode**]:::task
  Create_OCI_Auth_Secret5-->|Task| Create_OCI_ClusterSecretStore6[create oci clustersecretstore<br>When: **helm binary check stat exists and not ansible<br>check mode**]:::task
  Create_OCI_ClusterSecretStore6-->End
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
