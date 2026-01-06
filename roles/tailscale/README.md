<!-- DOCSIBLE START -->

# 📃 Role overview

## tailscale



Description: Installs and configures Tailscale VPN client.






<details>
<summary><b>🧩 Argument Specifications in meta/argument_specs</b></summary>

#### Key: main

**Description**: Installs Tailscale, connects to the tailnet using an auth key, and configures
settings like DNS acceptance and SSH access.


**Options**:


  - **tailscale_authkey**
    - **Required**: True
    - **Type**: str
    - **Default**: none
  
    - **Description**: Tailscale authentication key (tskey-auth-...).
  
  
  

  - **tailscale_hostname_prefix**
    - **Required**: False
    - **Type**: str
    - **Default**: k3s
  
    - **Description**: Prefix for the generated Tailscale hostname (e.g., k3s-hostname).
  
  
  

  - **tailscale_tags**
    - **Required**: False
    - **Type**: str
    - **Default**: 
  
    - **Description**: Comma-separated list of ACL tags to advertise (e.g., tag:k3s).
  
  
  

  - **tailscale_accept_dns**
    - **Required**: False
    - **Type**: str
    - **Default**: true
  
    - **Description**: Whether to accept DNS configuration from the tailnet ("true"/"false").
  
      - **Choices**:
    
          - true
    
          - false
    
  
  
  

  - **tailscale_ssh**
    - **Required**: False
    - **Type**: str
    - **Default**: true
  
    - **Description**: Whether to enable Tailscale SSH ("true"/"false").
  
      - **Choices**:
    
          - true
    
          - false
    
  
  
  



</details>




### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [tailscale_hostname_prefix](defaults/main.yml#L6)   | str | `k3s` |    false  |  Hostname Prefix |
| [tailscale_tags](defaults/main.yml#L12)   | str |  |    false  |  ACL Tags |
| [tailscale_accept_dns](defaults/main.yml#L18)   | str | `true` |    false  |  Accept DNS |
| [tailscale_ssh](defaults/main.yml#L24)   | str | `true` |    false  |  Enable SSH |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>tailscale_hostname_prefix</b></td><td>Prefix for the generated Tailscale hostname (e.g., k3s-hostname).</td></tr>
<tr><td><b>tailscale_tags</b></td><td>Comma-separated list of ACL tags to advertise (e.g., tag:k3s).</td></tr>
<tr><td><b>tailscale_accept_dns</b></td><td>Whether to accept DNS configuration from the tailnet ("true"/"false").</td></tr>
<tr><td><b>tailscale_ssh</b></td><td>Whether to enable Tailscale SSH ("true"/"false").</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| [Install Tailscale](tasks/main.yml#L2) | ansible.builtin.shell | False |
| [Start tailscaled](tasks/main.yml#L9) | ansible.builtin.systemd | False |
| [Check status](tasks/main.yml#L15) | ansible.builtin.command | False |
| [Determine state](tasks/main.yml#L22) | ansible.builtin.set_fact | False |
| [Configure Tailscale](tasks/main.yml#L32) | ansible.builtin.shell | True |
| [Wait for IP](tasks/main.yml#L49) | ansible.builtin.shell | False |
| [Set IP fact](tasks/main.yml#L63) | ansible.builtin.set_fact | False |
| [Validate connectivity](tasks/main.yml#L69) | ansible.builtin.wait_for | False |
| [Warn connectivity](tasks/main.yml#L77) | ansible.builtin.debug | True |


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

  Start-->|Task| Install_Tailscale0[install tailscale]:::task
  Install_Tailscale0-->|Task| Start_tailscaled1[start tailscaled]:::task
  Start_tailscaled1-->|Task| Check_status2[check status]:::task
  Check_status2-->|Task| Determine_state3[determine state]:::task
  Determine_state3-->|Task| Configure_Tailscale4[configure tailscale<br>When: **not tailscale is running   bool**]:::task
  Configure_Tailscale4-->|Task| Wait_for_IP5[wait for ip]:::task
  Wait_for_IP5-->|Task| Set_IP_fact6[set ip fact]:::task
  Set_IP_fact6-->|Task| Validate_connectivity7[validate connectivity]:::task
  Validate_connectivity7-->|Task| Warn_connectivity8[warn connectivity<br>When: **tailscale connectivity check failed   default<br>false**]:::task
  Warn_connectivity8-->End
```





## Author Information
Roura

#### License

MIT

#### Minimum Ansible Version

2.20.0

#### Platforms

- **Ubuntu**: ['noble']


#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
