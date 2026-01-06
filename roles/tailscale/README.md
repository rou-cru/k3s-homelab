<!-- DOCSIBLE START -->

# 📃 Role overview

## tailscale





| Field                | Value           |
|--------------------- |-----------------|
| Readme update        | 2026/01/05 |








### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |
|--------------|--------------|-------------|
| [tailscale_hostname_prefix](defaults/main.yml#L4)   | str | `k3s` |    
| [tailscale_tags](defaults/main.yml#L5)   | str |  |    
| [tailscale_accept_dns](defaults/main.yml#L6)   | str | `true` |    
| [tailscale_ssh](defaults/main.yml#L7)   | str | `true` |    





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions |
| ---- | ------ | -------------- |
| Install Tailscale | ansible.builtin.shell | False |
| Enable and start tailscaled | ansible.builtin.systemd | False |
| Check Tailscale status (JSON) | ansible.builtin.command | False |
| Determine Tailscale state | ansible.builtin.set_fact | False |
| Configure Tailscale (Up) | ansible.builtin.shell | True |
| Wait for valid Tailscale IPv4 (100.x.y.z) | ansible.builtin.shell | False |
| Set tailscale_ip fact | ansible.builtin.set_fact | False |
| Validate Tailscale IP is reachable | ansible.builtin.wait_for | False |
| Warn if Tailscale connectivity issues | ansible.builtin.debug | True |


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
  Install_Tailscale0-->|Task| Enable_and_start_tailscaled1[enable and start tailscaled]:::task
  Enable_and_start_tailscaled1-->|Task| Check_Tailscale_status__JSON_2[check tailscale status  json ]:::task
  Check_Tailscale_status__JSON_2-->|Task| Determine_Tailscale_state3[determine tailscale state]:::task
  Determine_Tailscale_state3-->|Task| Configure_Tailscale__Up_4[configure tailscale  up <br>When: **not tailscale is running   bool**]:::task
  Configure_Tailscale__Up_4-->|Task| Wait_for_valid_Tailscale_IPv4__100_x_y_z_5[wait for valid tailscale ipv4  100 x y z ]:::task
  Wait_for_valid_Tailscale_IPv4__100_x_y_z_5-->|Task| Set_tailscale_ip_fact6[set tailscale ip fact]:::task
  Set_tailscale_ip_fact6-->|Task| Validate_Tailscale_IP_is_reachable7[validate tailscale ip is reachable]:::task
  Validate_Tailscale_IP_is_reachable7-->|Task| Warn_if_Tailscale_connectivity_issues8[warn if tailscale connectivity issues<br>When: **tailscale connectivity check failed   default<br>false**]:::task
  Warn_if_Tailscale_connectivity_issues8-->End
```







#### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
