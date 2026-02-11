<!-- DOCSIBLE START -->

# 📃 Role overview

## gateway



Description: Deploys Kubernetes Gateway API resources including namespace, ReferenceGrant, and public Gateway.














### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Tags | Comments |
| ---- | ------ | -------------- | -----| -------- |
| [Create networking namespace](tasks/main.yml#L2) | kubernetes.core.k8s | True | infra,networking | @docsible Creates 'networking' namespace (Privileged for Gateway) |
| [Deploy public Gateway](tasks/main.yml#L19) | kubernetes.core.k8s | True | infra,networking | @docsible Deploys Public Gateway (Static Manifest) |
| [Deploy Cloudflare Origin CA ExternalSecret](tasks/main.yml#L28) | kubernetes.core.k8s | True | infra,networking | @docsible Deploys Cloudflare Origin CA ExternalSecret |


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

  Start-->|Task| Create_networking_namespace0[create networking namespace<br>When: **not ansible check mode**]:::task
  Create_networking_namespace0-->|Task| Deploy_public_Gateway1[deploy public gateway<br>When: **not ansible check mode**]:::task
  Deploy_public_Gateway1-->|Task| Deploy_Cloudflare_Origin_CA_ExternalSecret2[deploy cloudflare origin ca externalsecret<br>When: **not ansible check mode**]:::task
  Deploy_Cloudflare_Origin_CA_ExternalSecret2-->End
```





## Author Information
rc

### License

MIT

### Minimum Ansible Version

2.14

### Platforms

- **Ubuntu**: ['noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
