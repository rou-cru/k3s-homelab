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


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Check if Helm is installed](tasks/main.yml#L2) | ansible.builtin.command | False |  | @docsible Verify Helm CLI availability |
| [Ensure Jetstack Helm repo](tasks/main.yml#L9) | kubernetes.core.helm_repository | True |  | @docsible Add Jetstack Helm repository |
| [Deploy cert-manager](tasks/main.yml#L18) | kubernetes.core.helm | True | cluster,infrastructure,cert-manager | @docsible Deploy cert-manager with CRDs and resource limits |
| [Wait for cert-manager webhook to be available](tasks/main.yml#L82) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Wait for webhook deployment readiness |
| [Create cert-manager self-signed ClusterIssuer](tasks/main.yml#L101) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Create self-signed CA bootstrap issuer |
| [Create cert-manager CA certificate](tasks/main.yml#L119) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Generate cluster-wide CA certificate |
| [Wait for cert-manager CA secret](tasks/main.yml#L147) | kubernetes.core.k8s_info | True | cluster,infrastructure,cert-manager | @docsible Wait for CA secret generation |
| [Create cert-manager CA ClusterIssuer](tasks/main.yml#L166) | kubernetes.core.k8s | True | cluster,infrastructure,cert-manager | @docsible Create CA-based ClusterIssuer for workloads |


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
  Check_if_Helm_is_installed0-->|Task| Ensure_Jetstack_Helm_repo1[ensure jetstack helm repo<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Ensure_Jetstack_Helm_repo1-->|Task| Deploy_cert_manager2[deploy cert manager<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Deploy_cert_manager2-->|Task| Wait_for_cert_manager_webhook_to_be_available3[wait for cert manager webhook to be available<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Wait_for_cert_manager_webhook_to_be_available3-->|Task| Create_cert_manager_self_signed_ClusterIssuer4[create cert manager self signed clusterissuer<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Create_cert_manager_self_signed_ClusterIssuer4-->|Task| Create_cert_manager_CA_certificate5[create cert manager ca certificate<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Create_cert_manager_CA_certificate5-->|Task| Wait_for_cert_manager_CA_secret6[wait for cert manager ca secret<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Wait_for_cert_manager_CA_secret6-->|Task| Create_cert_manager_CA_ClusterIssuer7[create cert manager ca clusterissuer<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Create_cert_manager_CA_ClusterIssuer7-->End
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
