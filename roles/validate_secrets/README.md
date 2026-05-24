<!-- DOCSIBLE START -->

# 📃 Role overview

## validate_secrets



Description: Shared pre-flight validation role for hardware and system readiness checks.
















### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate Tailscale AuthKey presence](tasks/main.yml#L4) | ansible.builtin.assert | True | @docsible Asserts tailscale_authkey is defined and not a placeholder value |
| [Validate k3s_server group exists](tasks/main.yml#L16) | ansible.builtin.assert | True | @docsible Ensures k3s_server inventory group exists when required |


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

  Start-->|Task| Validate_Tailscale_AuthKey_presence0[validate tailscale authkey presence<br>When: **validatetailscaleauth   default true    bool**]:::task
  Validate_Tailscale_AuthKey_presence0-->|Task| Validate_k3s_server_group_exists1[validate k3s server group exists<br>When: **validatek3sservergroup   default false    bool**]:::task
  Validate_k3s_server_group_exists1-->End
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
