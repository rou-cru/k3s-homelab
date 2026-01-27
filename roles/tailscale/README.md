<!-- DOCSIBLE START -->

# 📃 Role overview

## tailscale



Description: Installs and configures Tailscale VPN client.






<details>
<summary><b> Argument Specifications in meta/argument_specs</b></summary>

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








### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install Tailscale](tasks/main.yml#L2) | ansible.builtin.get_url | True | Download Tailscale installation script with checksum verification |
| [Run Tailscale installer](tasks/main.yml#L11) | ansible.builtin.command | True | Execute Tailscale installation script if not already installed |
| [Start tailscaled](tasks/main.yml#L17) | ansible.builtin.systemd | True | Enable and start Tailscale daemon service |
| [Check status](tasks/main.yml#L26) | ansible.builtin.command | False | Check current Tailscale connection status in JSON format
Determines if Tailscale daemon is running and connected to control plane |
| [Determine state](tasks/main.yml#L34) | ansible.builtin.set_fact | False | Determine if Tailscale is actively running and connected
Parses JSON output to check BackendState=Running indicating active connection |
| [Configure Tailscale](tasks/main.yml#L46) | ansible.builtin.shell | True | Configure Tailscale with authentication and custom settings
Runs only if not connected, ensures idempotency by checking tailscale_is_running state |
| [Enable exit node advertisement](tasks/main.yml#L68) | ansible.builtin.command | True | Configure exit node if enabled (idempotent even when already running)
Updates exit node advertisement without disrupting active connection |
| [Advertise routes](tasks/main.yml#L79) | ansible.builtin.command | True | Advertise routes if specified (idempotent even when already running)
Updates subnet routes without requiring reconnect |
| [Wait for IP](tasks/main.yml#L88) | ansible.builtin.shell | True | Wait for Tailscale to assign valid 100.x.x.x IP address |
| [Set IP fact](tasks/main.yml#L106) | ansible.builtin.set_fact | True | Store Tailscale IP address as ansible fact for other roles |
| [Validate connectivity](tasks/main.yml#L112) | ansible.builtin.wait_for | True | Test SSH connectivity through Tailscale network |
| [Warn connectivity](tasks/main.yml#L121) | ansible.builtin.debug | True | Display warning if Tailscale connectivity test fails
Non-blocking warning - connectivity may work even if initial test fails |
| [Exit node approval reminder](tasks/main.yml#L126) | ansible.builtin.debug | True | Remind user to approve exit node in admin console |


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

  Start-->|Task| Install_Tailscale0[install tailscale<br>When: **not ansible check mode**]:::task
  Install_Tailscale0-->|Task| Run_Tailscale_installer1[run tailscale installer<br>When: **not ansible check mode**]:::task
  Run_Tailscale_installer1-->|Task| Start_tailscaled2[start tailscaled<br>When: **not ansible check mode**]:::task
  Start_tailscaled2-->|Task| Check_status3[check status]:::task
  Check_status3-->|Task| Determine_state4[determine state]:::task
  Determine_state4-->|Task| Configure_Tailscale5[configure tailscale<br>When: **not tailscale is running   bool and not ansible<br>check mode**]:::task
  Configure_Tailscale5-->|Task| Enable_exit_node_advertisement6[enable exit node advertisement<br>When: **tailscale exit node enabled   bool and tailscale<br>is running   bool and not ansible check mode**]:::task
  Enable_exit_node_advertisement6-->|Task| Advertise_routes7[advertise routes<br>When: **tailscale advertise routes   length   0 and<br>tailscale is running   bool and not ansible check<br>mode**]:::task
  Advertise_routes7-->|Task| Wait_for_IP8[wait for ip<br>When: **tailscale status json rc    0 and not ansible<br>check mode**]:::task
  Wait_for_IP8-->|Task| Set_IP_fact9[set ip fact<br>When: **tailscale ip cmd is not skipped**]:::task
  Set_IP_fact9-->|Task| Validate_connectivity10[validate connectivity<br>When: **tailscale ip is defined and tailscale ip   length <br> 0**]:::task
  Validate_connectivity10-->|Task| Warn_connectivity11[warn connectivity<br>When: **tailscale connectivity check failed   default<br>false**]:::task
  Warn_connectivity11-->|Task| Exit_node_approval_reminder12[exit node approval reminder<br>When: **tailscale exit node enabled   bool**]:::task
  Exit_node_approval_reminder12-->End
```





## Author Information
Roura

### License

MIT

### Minimum Ansible Version

2.20.0

### Platforms

- **Ubuntu**: ['noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
