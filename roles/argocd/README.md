<!-- DOCSIBLE START -->

# 📃 Role overview

## argocd



Description: Deploy ArgoCD on K3s via Helm (expects External Secrets and an OCI ClusterSecretStore named oci-vault for admin password).






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Installs ArgoCD via Helm and configures admin password
via External Secrets OCI Vault integration.


**Options**:


  - **argocd_namespace**
    - **Required**: False
    - **Type**: str
    - **Default**: argocd
  
    - **Description**: Namespace for ArgoCD deployment.
  
  
  

  - **argocd_chartVersion**
    - **Required**: False
    - **Type**: str
    - **Default**: none
  
    - **Description**: ArgoCD Helm chart version (omit for latest).
  
  
  

  - **argocd_installCrds**
    - **Required**: False
    - **Type**: bool
    - **Default**: True
  
    - **Description**: Install ArgoCD CRDs.
  
  
  

  - **argocd_dexEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable Dex for SSO integration.
  
  
  

  - **argocd_haEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable high availability mode.
  
  
  

  - **argocd_serviceMonitorEnabled**
    - **Required**: False
    - **Type**: bool
    - **Default**: False
  
    - **Description**: Enable Prometheus ServiceMonitor.
  
  
  

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
| [Ensure ArgoCD Helm repo](tasks/main.yml#L2) | kubernetes.core.helm_repository | True |  | @docsible Registers ArgoCD Helm repository |
| [Create argocd namespace](tasks/main.yml#L9) | kubernetes.core.k8s | True |  | @docsible Creates argocd namespace |
| [Deploy ArgoCD](tasks/main.yml#L17) | kubernetes.core.helm | True | gitops | @docsible Installs ArgoCD via Helm |
| [Create ArgoCD Admin Password ExternalSecret](tasks/main.yml#L34) | kubernetes.core.k8s | True | gitops | @docsible Syncs Admin Password from Vault (ExternalSecret) |
| [Wait for argocd-secret to have admin.password](tasks/main.yml#L45) | kubernetes.core.k8s_info | True | gitops | @docsible Waits for Admin Password Secret sync |
| [Find ArgoCD project manifests](tasks/main.yml#L62) | ansible.builtin.find | False | gitops | @docsible Discovers ArgoCD project manifests in remote bootstrap directory |
| [Find ArgoCD ApplicationSet manifests](tasks/main.yml#L71) | ansible.builtin.find | False | gitops | @docsible Discovers ArgoCD ApplicationSet manifests in remote bootstrap directory |
| [Apply ArgoCD projects](tasks/main.yml#L80) | kubernetes.core.k8s | True | gitops | @docsible Applies ArgoCD AppProjects from bootstrap manifests |
| [Apply ArgoCD ApplicationSets](tasks/main.yml#L92) | kubernetes.core.k8s | True | gitops | @docsible Applies ArgoCD ApplicationSets from bootstrap manifests |
| [Restart ArgoCD Server to pick up new password](tasks/main.yml#L104) | kubernetes.core.k8s | True | gitops | @docsible Restarts ArgoCD server to apply updated admin password |


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

  Start-->|Task| Ensure_ArgoCD_Helm_repo0[ensure argocd helm repo<br>When: **not ansible check mode**]:::task
  Ensure_ArgoCD_Helm_repo0-->|Task| Create_argocd_namespace1[create argocd namespace<br>When: **not ansible check mode**]:::task
  Create_argocd_namespace1-->|Task| Deploy_ArgoCD2[deploy argocd<br>When: **not ansible check mode**]:::task
  Deploy_ArgoCD2-->|Task| Create_ArgoCD_Admin_Password_ExternalSecret3[create argocd admin password externalsecret<br>When: **not ansible check mode**]:::task
  Create_ArgoCD_Admin_Password_ExternalSecret3-->|Task| Wait_for_argocd_secret_to_have_admin_password4[wait for argocd secret to have admin password<br>When: **argocd es created changed and not ansible check<br>mode**]:::task
  Wait_for_argocd_secret_to_have_admin_password4-->|Task| Find_ArgoCD_project_manifests5[find argocd project manifests]:::task
  Find_ArgoCD_project_manifests5-->|Task| Find_ArgoCD_ApplicationSet_manifests6[find argocd applicationset manifests]:::task
  Find_ArgoCD_ApplicationSet_manifests6-->|Task| Apply_ArgoCD_projects7[apply argocd projects<br>When: **not ansible check mode**]:::task
  Apply_ArgoCD_projects7-->|Task| Apply_ArgoCD_ApplicationSets8[apply argocd applicationsets<br>When: **not ansible check mode**]:::task
  Apply_ArgoCD_ApplicationSets8-->|Task| Restart_ArgoCD_Server_to_pick_up_new_password9[restart argocd server to pick up new password<br>When: **argocd es created changed and not ansible check<br>mode**]:::task
  Restart_ArgoCD_Server_to_pick_up_new_password9-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.14

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
