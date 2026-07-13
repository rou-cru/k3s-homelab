<!-- DOCSIBLE START -->

# 📃 Role overview

## external_secrets



Description: Install External Secrets Operator and configure an OCI Vault-backed ClusterSecretStore (requires cert-manager).






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

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
| [Ensure External Secrets Helm repo](tasks/main.yml#L2) | kubernetes.core.helm_repository | True |  | @docsible Registers External Secrets Helm repository |
| [Create external-secrets namespace](tasks/main.yml#L9) | kubernetes.core.k8s | True |  | @docsible Creates namespace for External Secrets |
| [Deploy External Secrets Operator](tasks/main.yml#L17) | kubernetes.core.helm | True | infra | @docsible Installs External Secrets Operator via Helm |
| [Wait for external-secrets webhook CA bundle](tasks/main.yml#L34) | kubernetes.core.k8s_info | True | infra | @docsible Waits for Webhook CA Bundle Injection |
| [Wait for external-secrets webhook to be ready](tasks/main.yml#L55) | kubernetes.core.k8s | True | infra | @docsible Waits for Webhook Deployment Readiness |
| [Create OCI Auth Secret](tasks/main.yml#L71) | kubernetes.core.k8s | True | infra | @docsible Creates Secret for OCI/GCP Vault Authentication |
| [Create OCI ClusterSecretStore](tasks/main.yml#L82) | kubernetes.core.k8s | True | infra | @docsible Configures ClusterSecretStore (Vault Backend) |


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

  Start-->|Task| Ensure_External_Secrets_Helm_repo0[ensure external secrets helm repo<br>When: **not ansible check mode**]:::task
  Ensure_External_Secrets_Helm_repo0-->|Task| Create_external_secrets_namespace1[create external secrets namespace<br>When: **not ansible check mode**]:::task
  Create_external_secrets_namespace1-->|Task| Deploy_External_Secrets_Operator2[deploy external secrets operator<br>When: **not ansible check mode**]:::task
  Deploy_External_Secrets_Operator2-->|Task| Wait_for_external_secrets_webhook_CA_bundle3[wait for external secrets webhook ca bundle<br>When: **not ansible check mode**]:::task
  Wait_for_external_secrets_webhook_CA_bundle3-->|Task| Wait_for_external_secrets_webhook_to_be_ready4[wait for external secrets webhook to be ready<br>When: **not ansible check mode**]:::task
  Wait_for_external_secrets_webhook_to_be_ready4-->|Task| Create_OCI_Auth_Secret5[create oci auth secret<br>When: **not ansible check mode**]:::task
  Create_OCI_Auth_Secret5-->|Task| Create_OCI_ClusterSecretStore6[create oci clustersecretstore<br>When: **not ansible check mode**]:::task
  Create_OCI_ClusterSecretStore6-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.20.0

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
