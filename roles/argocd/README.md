<!-- DOCSIBLE START -->

# 📃 Role overview

## argocd



Description: Deploy ArgoCD on K3s via Helm (expects External Secrets and an OCI ClusterSecretStore named oci-vault for admin password).














### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Check if Helm is installed](tasks/main.yml#L2) | ansible.builtin.command | False |  | @docsible Check Helm availability |
| [Ensure ArgoCD Helm repo](tasks/main.yml#L9) | kubernetes.core.helm_repository | True |  | @docsible Add ArgoCD Helm repository |
| [Deploy ArgoCD](tasks/main.yml#L18) | kubernetes.core.helm | True | apps,argocd | @docsible Deploy ArgoCD via Helm |
| [Create ArgoCD Admin Password ExternalSecret](tasks/main.yml#L143) | kubernetes.core.k8s | True | apps,argocd,secrets | @docsible Create ExternalSecret for admin password |
| [Wait for argocd-secret to have admin.password](tasks/main.yml#L176) | kubernetes.core.k8s_info | True | apps,argocd,secrets | @docsible Wait for admin password secret |
| [Restart ArgoCD Server to pick up new password](tasks/main.yml#L197) | kubernetes.core.k8s | True | apps,argocd,secrets | @docsible Restart ArgoCD server for password update |


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
  Check_if_Helm_is_installed0-->|Task| Ensure_ArgoCD_Helm_repo1[ensure argocd helm repo<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Ensure_ArgoCD_Helm_repo1-->|Task| Deploy_ArgoCD2[deploy argocd<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Deploy_ArgoCD2-->|Task| Create_ArgoCD_Admin_Password_ExternalSecret3[create argocd admin password externalsecret<br>When: **helm binary check rc    0 and not ansible check<br>mode**]:::task
  Create_ArgoCD_Admin_Password_ExternalSecret3-->|Task| Wait_for_argocd_secret_to_have_admin_password4[wait for argocd secret to have admin password<br>When: **helm binary check rc    0 and argocd es created<br>changed and not ansible check mode**]:::task
  Wait_for_argocd_secret_to_have_admin_password4-->|Task| Restart_ArgoCD_Server_to_pick_up_new_password5[restart argocd server to pick up new password<br>When: **helm binary check rc    0 and argocd es created<br>changed and not ansible check mode**]:::task
  Restart_ArgoCD_Server_to_pick_up_new_password5-->End
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

- **external_secrets**
  
  

<!-- DOCSIBLE END -->
