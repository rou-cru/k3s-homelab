<!-- DOCSIBLE START -->

# 📃 Role overview

## cert_manager



Description: Install cert-manager on K3s and bootstrap a self-signed CA with ClusterIssuers.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Deploys cert-manager via Helm with CRDs enabled and bootstraps
a self-signed CA with ClusterIssuers for cluster-wide TLS.


**Options**:


  - **certManager_namespace**
    - **Required**: False
    - **Type**: str
    - **Default**: cert-manager
  
    - **Description**: Namespace for cert-manager deployment.
  
  
  

  - **certManager_chartVersion**
    - **Required**: False
    - **Type**: str
    - **Default**: none
  
    - **Description**: cert-manager Helm chart version (omit for latest).
  
  
  

  - **certManager_selfsignedIssuerName**
    - **Required**: False
    - **Type**: str
    - **Default**: selfsigned-issuer
  
    - **Description**: Name for the self-signed ClusterIssuer.
  
  
  

  - **certManager_caCertificateName**
    - **Required**: False
    - **Type**: str
    - **Default**: ca-certificate
  
    - **Description**: Name for the CA Certificate resource.
  
  
  

  - **certManager_caSecretName**
    - **Required**: False
    - **Type**: str
    - **Default**: ca-secret
  
    - **Description**: Secret name for storing the CA certificate.
  
  
  

  - **certManager_caIssuerName**
    - **Required**: False
    - **Type**: str
    - **Default**: ca-issuer
  
    - **Description**: Name for the CA ClusterIssuer.
  
  
  

  - **certManager_prometheusEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable Prometheus ServiceMonitor for metrics.
  
  
  

  - **kubeconfig**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Path to kubeconfig for cluster access.
  
  
  



</details>








### Tasks


#### File: tasks/acme.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Create Cloudflare API token ExternalSecret](tasks/acme.yml#L8) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager,acme | @docsible Sync Cloudflare API token from OCI Vault |
| [Create Let's Encrypt ClusterIssuer](tasks/acme.yml#L) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager,acme | @docsible Create Let's Encrypt production ClusterIssuer with Cloudflare DNS-01 |
| [Create wildcard Certificate for {{ wildcard_domain }}](tasks/acme.yml#L66) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager,acme | @docsible Request wildcard certificate for public exposure |
| [Deploy public Gateway](tasks/acme.yml#L92) | kubernetes.core.k8s | True | cluster,infrastructure,gateway,acme | @docsible Deploy Gateway API public gateway with HTTP/HTTPS listeners |

#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Ensure Jetstack Helm repo](tasks/main.yml#L2) | kubernetes.core.helm_repository | True |  | @docsible Add Jetstack Helm repository |
| [Deploy cert-manager](tasks/main.yml#L10) | kubernetes.core.helm | True | cluster,infrastructure,cert-manager | @docsible Deploy cert-manager with CRDs and resource limits |
| [Wait for cert-manager webhook to be available](tasks/main.yml#L71) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Wait for webhook deployment readiness |
| [Create cert-manager self-signed ClusterIssuer](tasks/main.yml#L87) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Create self-signed CA bootstrap issuer |
| [Create cert-manager CA certificate](tasks/main.yml#L102) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Generate cluster-wide CA certificate |
| [Wait for cert-manager CA secret](tasks/main.yml#L129) | kubernetes.core.k8s_info | True | cluster,infrastructure,cert-manager | @docsible Wait for CA secret generation |
| [Create cert-manager CA ClusterIssuer](tasks/main.yml#L145) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Create CA-based ClusterIssuer for workloads |


## Task Flow Graphs



### Graph for acme.yml

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

  Start-->|Task| Create_Cloudflare_API_token_ExternalSecret0[create cloudflare api token externalsecret<br>When: **not ansible check mode**]:::task
  Create_Cloudflare_API_token_ExternalSecret0-->|Task| Create_Let_s_Encrypt_ClusterIssuer1[create let s encrypt clusterissuer<br>When: **not ansible check mode**]:::task
  Create_Let_s_Encrypt_ClusterIssuer1-->|Task| Create_wildcard_Certificate_for_wildcard_domain2[create wildcard certificate for wildcard domain<br>When: **not ansible check mode**]:::task
  Create_wildcard_Certificate_for_wildcard_domain2-->|Task| Deploy_public_Gateway3[deploy public gateway<br>When: **not ansible check mode**]:::task
  Deploy_public_Gateway3-->End
```


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

  Start-->|Task| Ensure_Jetstack_Helm_repo0[ensure jetstack helm repo<br>When: **not ansible check mode**]:::task
  Ensure_Jetstack_Helm_repo0-->|Task| Deploy_cert_manager1[deploy cert manager<br>When: **not ansible check mode**]:::task
  Deploy_cert_manager1-->|Task| Wait_for_cert_manager_webhook_to_be_available2[wait for cert manager webhook to be available<br>When: **not ansible check mode**]:::task
  Wait_for_cert_manager_webhook_to_be_available2-->|Task| Create_cert_manager_self_signed_ClusterIssuer3[create cert manager self signed clusterissuer<br>When: **not ansible check mode**]:::task
  Create_cert_manager_self_signed_ClusterIssuer3-->|Task| Create_cert_manager_CA_certificate4[create cert manager ca certificate<br>When: **not ansible check mode**]:::task
  Create_cert_manager_CA_certificate4-->|Task| Wait_for_cert_manager_CA_secret5[wait for cert manager ca secret<br>When: **not ansible check mode**]:::task
  Wait_for_cert_manager_CA_secret5-->|Task| Create_cert_manager_CA_ClusterIssuer6[create cert manager ca clusterissuer<br>When: **not ansible check mode**]:::task
  Create_cert_manager_CA_ClusterIssuer6-->End
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
