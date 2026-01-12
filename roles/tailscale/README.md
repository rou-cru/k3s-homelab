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
| [tailscale_tags](defaults/main.yml#L11)   | str |  |    false  |  ACL Tags |
| [tailscale_accept_dns](defaults/main.yml#L16)   | str | `true` |    false  |  Accept DNS |
| [tailscale_ssh](defaults/main.yml#L21)   | str | `true` |    false  |  Enable SSH |
| [tailscale_install_script_checksum](defaults/main.yml#L27)   | str | `7fab06250c94a527d5f74002d9fb45ac9fc702c72f7901a959571112c75048f1` |    false  |  Tailscale install script checksum |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>tailscale_hostname_prefix</b></td><td>Prefix for the generated Tailscale hostname (e.g., k3s-hostname).</td></tr>
<tr><td><b>tailscale_tags</b></td><td>Comma-separated list of ACL tags to advertise (e.g., tag:k3s).</td></tr>
<tr><td><b>tailscale_accept_dns</b></td><td>Whether to accept DNS configuration from the tailnet ("true"/"false").</td></tr>
<tr><td><b>tailscale_ssh</b></td><td>Whether to enable Tailscale SSH ("true"/"false").</td></tr>
<tr><td><b>tailscale_install_script_checksum</b></td><td>SHA256 for https://tailscale.com/install.sh (pin to avoid supply-chain drift).</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| [Install Tailscale](tasks/main.yml#L2) | ansible.builtin.get_url | False |
| [Run Tailscale installer](tasks/main.yml#L9) | ansible.builtin.command | False |
| [Start tailscaled](tasks/main.yml#L13) | ansible.builtin.systemd | False |
| [Check status](tasks/main.yml#L19) | ansible.builtin.command | False |
| [Determine state](tasks/main.yml#L25) | ansible.builtin.set_fact | False |
| [Configure Tailscale](tasks/main.yml#L34) | ansible.builtin.shell | True |
| [Wait for IP](tasks/main.yml#L49) | ansible.builtin.shell | False |
| [Set IP fact](tasks/main.yml#L64) | ansible.builtin.set_fact | False |
| [Validate connectivity](tasks/main.yml#L68) | ansible.builtin.wait_for | False |
| [Warn connectivity](tasks/main.yml#L75) | ansible.builtin.debug | True |


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
  Install_Tailscale0-->|Task| Run_Tailscale_installer1[run tailscale installer]:::task
  Run_Tailscale_installer1-->|Task| Start_tailscaled2[start tailscaled]:::task
  Start_tailscaled2-->|Task| Check_status3[check status]:::task
  Check_status3-->|Task| Determine_state4[determine state]:::task
  Determine_state4-->|Task| Configure_Tailscale5[configure tailscale<br>When: **not tailscale is running   bool**]:::task
  Configure_Tailscale5-->|Task| Wait_for_IP6[wait for ip]:::task
  Wait_for_IP6-->|Task| Set_IP_fact7[set ip fact]:::task
  Set_IP_fact7-->|Task| Validate_connectivity8[validate connectivity]:::task
  Validate_connectivity8-->|Task| Warn_connectivity9[warn connectivity<br>When: **tailscale connectivity check failed   default<br>false**]:::task
  Warn_connectivity9-->End
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
