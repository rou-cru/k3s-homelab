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
  
  
  



</details>








### Tasks


#### File: tasks/advertise_pod_cidr.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Wait for CiliumNode with CiliumInternalIP](tasks/advertise_pod_cidr.yml#L9) | kubernetes.core.k8s_info | True | @docsible Waits for CiliumNode with CiliumInternalIP assigned
Must wait for CiliumInternalIP, not just CiliumNode existence, as IPAM assigns IPs asynchronously |
| [Extract CiliumInternalIP from CiliumNode](tasks/advertise_pod_cidr.yml#L29) | ansible.builtin.set_fact | True | @docsible Parses CiliumInternalIP to determine Pod CIDR
The CiliumInternalIP is used to determine the pod CIDR block assigned to this node.
Cilium assigns a /24 block per node from the cluster pool (10.0.0.0/8). |
| [Calculate pod CIDR from CiliumInternalIP](tasks/advertise_pod_cidr.yml#L43) | ansible.builtin.set_fact | True | @docsible Calculates /24 Pod CIDR from internal IP
Example: If CiliumInternalIP is 10.0.0.5, the pod CIDR is 10.0.0.0/24
Example: If CiliumInternalIP is 10.0.1.8, the pod CIDR is 10.0.1.0/24 |
| [Advertise pod and service CIDR routes via Tailscale](tasks/advertise_pod_cidr.yml#L51) | ansible.builtin.command | True | @docsible Updates Tailscale route advertisement with Pod CIDR and Service CIDR |

#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Check tailscale exists](tasks/main.yml#L14) | ansible.builtin.stat | False | @docsible Check if tailscaled binary is installed at expected path |
| [Check Tailscale status](tasks/main.yml#L21) | ansible.builtin.command | True | @docsible Get tailscale status JSON (only when binary exists) |
| [Determine Tailscale state](tasks/main.yml#L30) | ansible.builtin.set_fact | False | @docsible Parse Tailscale state: installed, daemon_running, is_authenticated |
| [Display detected state](tasks/main.yml#L57) | ansible.builtin.debug | False | @docsible Display parsed state for debugging |
| [Download Tailscale installer](tasks/main.yml#L70) | ansible.builtin.get_url | True | @docsible Download official Tailscale install script |
| [Run Tailscale installer](tasks/main.yml#L81) | ansible.builtin.command | True | @docsible Execute install script (creates /usr/sbin/tailscaled) |
| [Start tailscaled service](tasks/main.yml#L90) | ansible.builtin.systemd | True | @docsible Enable and start tailscaled systemd service |
| [Logout Tailscale (reset state if inconsistent)](tasks/main.yml#L105) | ansible.builtin.command | True | @docsible Logout if backend state is inconsistent (Running but not Online) |
| [Authenticate Tailscale](tasks/main.yml#L112) | ansible.builtin.shell | True | @docsible Authenticate with tailscale up (NO --reset to preserve routes) |
| [Configure accept-dns](tasks/main.yml#L132) | ansible.builtin.command | True | @docsible Configure DNS acceptance from admin console |
| [Configure accept-routes](tasks/main.yml#L140) | ansible.builtin.command | True | @docsible Enable route acceptance for Cilium Native Routing mesh |
| [Configure SSH](tasks/main.yml#L148) | ansible.builtin.command | True | @docsible Enable Tailscale SSH server on the node |
| [Configure exit node advertisement](tasks/main.yml#L156) | ansible.builtin.command | True | @docsible Advertise as exit node if enabled in variables |
| [Disable exit node advertisement](tasks/main.yml#L164) | ansible.builtin.command | True | @docsible Disable exit node advertisement when not enabled |
| [Unset exit node](tasks/main.yml#L173) | ansible.builtin.command | True | @docsible Unset exit node usage when not using an exit node |
| [Configure static routes](tasks/main.yml#L182) | ansible.builtin.command | True | @docsible Advertise static subnet routes from inventory |
| [Clear static routes](tasks/main.yml#L191) | ansible.builtin.command | True | @docsible Clear static routes when none defined |
| [Wait for Tailscale IP](tasks/main.yml#L204) | ansible.builtin.shell | True | @docsible Wait for valid CGNAT IP (100.x.x.x) assignment |
| [Set Tailscale IP fact](tasks/main.yml#L222) | ansible.builtin.set_fact | True | @docsible Set IP_tailscale fact for use by other roles |
| [Set mock IP fact (check mode)](tasks/main.yml#L231) | ansible.builtin.set_fact | True | @docsible Provide mock IP for check mode execution |
| [Validate connectivity](tasks/main.yml#L237) | ansible.builtin.wait_for | True | @docsible Verify SSH connectivity over Tailscale network |
| [Warn connectivity](tasks/main.yml#L249) | ansible.builtin.debug | True | @docsible Warn if Tailscale SSH is not reachable |
| [Apply Tailscale-Cilium routing fix](tasks/main.yml#L261) | ansible.builtin.include_tasks | True | @docsible Apply the Tailscale-Cilium routing fix (Policy Routing).
This prevents packet loss for Pod-to-Host traffic across nodes by prioritizing
routing to Table 52 (Tailscale) over the main table when Cilium fwmarks collide. |

#### File: tasks/routing_fix.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Install routing fix script](tasks/routing_fix.yml#L18) | ansible.builtin.template | False | @docsible Deploy the 'fix-tailscale-cilium-routing.sh' script.
This script is the core logic that:
1. Checks if Tailscale is active and Table 52 exists.
2. Idempotently adds an 'ip rule' for the Pod CIDR (default 10.0.0.0/8).
3. Sets priority to 200 to ensure it is evaluated BEFORE Tailscale's rule 5210. |
| [Install routing fix service](tasks/routing_fix.yml#L30) | ansible.builtin.template | False | @docsible Install the systemd service unit.
Defines a 'Type=oneshot' service that executes the routing script.
It includes 'After=tailscaled.service' to manage dependency order. |
| [Install routing fix timer](tasks/routing_fix.yml#L42) | ansible.builtin.template | False | @docsible Install the systemd timer unit for self-healing.
Configures the service to run periodically (e.g., every 1 min) to re-apply
the rule if Tailscale restarts or flushes the routing table. |
| [Check if systemd-networkd directory exists](tasks/routing_fix.yml#L54) | ansible.builtin.stat | False | Handle systemd-networkd if present (e.g. Ubuntu/Debian modern)
@docsible Detect if systemd-networkd is in use.
Needed because systemd-networkd often deletes "foreign" manual IP rules. |
| [Ensure systemd-networkd directory exists](tasks/routing_fix.yml#L60) | ansible.builtin.file | True | @docsible Ensure configuration directory for networkd overrides exists. |
| [Configure systemd-networkd to ignore foreign rules](tasks/routing_fix.yml#L70) | ansible.builtin.copy | True | @docsible Apply 'ManageForeignRoutes=no' override to systemd-networkd.
This critical setting prevents the OS network manager from removing our
custom policy routing rules during network changes or restarts. |
| [Force systemd daemon reload](tasks/routing_fix.yml#L82) | ansible.builtin.systemd | False | @docsible Reload systemd daemon to recognize new service/timer units. |
| [Enable and start routing fix timer](tasks/routing_fix.yml#L90) | ansible.builtin.systemd | True | @docsible Enable and start the timer (Self-Healing).
The timer is the primary entry point; it will trigger the service immediately
and then periodically. |
| [Ensure routing fix service is enabled](tasks/routing_fix.yml#L99) | ansible.builtin.systemd | True | @docsible Enable the service unit.
Ensures the service can be invoked by the timer or manually. |


## Task Flow Graphs



### Graph for advertise_pod_cidr.yml

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

  Start-->|Task| Wait_for_CiliumNode_with_CiliumInternalIP0[wait for ciliumnode with ciliuminternalip<br>When: **not ansible check mode**]:::task
  Wait_for_CiliumNode_with_CiliumInternalIP0-->|Task| Extract_CiliumInternalIP_from_CiliumNode1[extract ciliuminternalip from ciliumnode<br>When: **not ansible check mode and cilium node result<br>resources   default       length   0**]:::task
  Extract_CiliumInternalIP_from_CiliumNode1-->|Task| Calculate_pod_CIDR_from_CiliumInternalIP2[calculate pod cidr from ciliuminternalip<br>When: **not ansible check mode and  cilium internal ip  <br>default       length   0**]:::task
  Calculate_pod_CIDR_from_CiliumInternalIP2-->|Task| Advertise_pod_and_service_CIDR_routes_via_Tailscale3[advertise pod and service cidr routes via<br>tailscale<br>When: **cilium pod cidr   default       length   0 and<br>not ansible check mode**]:::task
  Advertise_pod_and_service_CIDR_routes_via_Tailscale3-->End
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

  Start-->|Task| Check_tailscale_exists0[check tailscale exists]:::task
  Check_tailscale_exists0-->|Task| Check_Tailscale_status1[check tailscale status<br>When: **tailscale binary check stat exists**]:::task
  Check_Tailscale_status1-->|Task| Determine_Tailscale_state2[determine tailscale state]:::task
  Determine_Tailscale_state2-->|Task| Display_detected_state3[display detected state]:::task
  Display_detected_state3-->|Task| Download_Tailscale_installer4[download tailscale installer<br>When: **not tailscale installed   bool and not ansible<br>check mode**]:::task
  Download_Tailscale_installer4-->|Task| Run_Tailscale_installer5[run tailscale installer<br>When: **not tailscale installed   bool and not ansible<br>check mode**]:::task
  Run_Tailscale_installer5-->|Task| Start_tailscaled_service6[start tailscaled service<br>When: **not tailscale daemon running   bool and not<br>ansible check mode**]:::task
  Start_tailscaled_service6-->|Task| Logout_Tailscale__reset_state_if_inconsistent_7[logout tailscale  reset state if inconsistent <br>When: **tailscale needs logout   bool and not ansible<br>check mode**]:::task
  Logout_Tailscale__reset_state_if_inconsistent_7-->|Task| Authenticate_Tailscale8[authenticate tailscale<br>When: **not tailscale is authenticated   bool and not<br>ansible check mode**]:::task
  Authenticate_Tailscale8-->|Task| Configure_accept_dns9[configure accept dns<br>When: **tailscale is authenticated   bool or  tailscale up<br>is succeeded   default false   and not ansible<br>check mode**]:::task
  Configure_accept_dns9-->|Task| Configure_accept_routes10[configure accept routes<br>When: **tailscale is authenticated   bool or  tailscale up<br>is succeeded   default false   and not ansible<br>check mode**]:::task
  Configure_accept_routes10-->|Task| Configure_SSH11[configure ssh<br>When: **tailscale is authenticated   bool or  tailscale up<br>is succeeded   default false   and not ansible<br>check mode**]:::task
  Configure_SSH11-->|Task| Configure_exit_node_advertisement12[configure exit node advertisement<br>When: **tailscale is authenticated   bool or  tailscale up<br>is succeeded   default false   and not ansible<br>check mode**]:::task
  Configure_exit_node_advertisement12-->|Task| Disable_exit_node_advertisement13[disable exit node advertisement<br>When: **not  tailscale exitnodeenabled   default false   <br>bool  and tailscale is authenticated   bool or <br>tailscale up is succeeded   default false   and<br>not ansible check mode**]:::task
  Disable_exit_node_advertisement13-->|Task| Unset_exit_node14[unset exit node<br>When: **not  tailscale useexitnode   default false    bool<br> and tailscale is authenticated   bool or <br>tailscale up is succeeded   default false   and<br>not ansible check mode**]:::task
  Unset_exit_node14-->|Task| Configure_static_routes15[configure static routes<br>When: **tailscale advertiseroutes   default       length  <br>0 and tailscale is authenticated   bool or <br>tailscale up is succeeded   default false   and<br>not ansible check mode**]:::task
  Configure_static_routes15-->|Task| Clear_static_routes16[clear static routes<br>When: **tailscale advertiseroutes   default       length  <br> 0 and tailscale is authenticated   bool or <br>tailscale up is succeeded   default false   and<br>not ansible check mode**]:::task
  Clear_static_routes16-->|Task| Wait_for_Tailscale_IP17[wait for tailscale ip<br>When: **not ansible check mode**]:::task
  Wait_for_Tailscale_IP17-->|Task| Set_Tailscale_IP_fact18[set tailscale ip fact<br>When: **tailscale ip cmd is not skipped and tailscale ip<br>cmd stdout is defined**]:::task
  Set_Tailscale_IP_fact18-->|Task| Set_mock_IP_fact__check_mode_19[set mock ip fact  check mode <br>When: **ansible check mode**]:::task
  Set_mock_IP_fact__check_mode_19-->|Task| Validate_connectivity20[validate connectivity<br>When: **ip tailscale is defined and ip tailscale   length <br> 0 and not ansible check mode**]:::task
  Validate_connectivity20-->|Task| Warn_connectivity21[warn connectivity<br>When: **tailscale connectivity check failed   default<br>false**]:::task
  Warn_connectivity21-->|Include task| Apply_Tailscale_Cilium_routing_fix_routing_fix_yml_22[apply tailscale cilium routing fix<br>When: **tailscale cilium routing enabled   default false  <br> bool**<br>include_task: routing fix yml]:::includeTasks
  Apply_Tailscale_Cilium_routing_fix_routing_fix_yml_22-->End
```


### Graph for routing_fix.yml

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

  Start-->|Task| Install_routing_fix_script0[install routing fix script]:::task
  Install_routing_fix_script0-->|Task| Install_routing_fix_service1[install routing fix service]:::task
  Install_routing_fix_service1-->|Task| Install_routing_fix_timer2[install routing fix timer]:::task
  Install_routing_fix_timer2-->|Task| Check_if_systemd_networkd_directory_exists3[check if systemd networkd directory exists]:::task
  Check_if_systemd_networkd_directory_exists3-->|Task| Ensure_systemd_networkd_directory_exists4[ensure systemd networkd directory exists<br>When: **networkd conf dir stat exists**]:::task
  Ensure_systemd_networkd_directory_exists4-->|Task| Configure_systemd_networkd_to_ignore_foreign_rules5[configure systemd networkd to ignore foreign rules<br>When: **networkd conf dir stat exists**]:::task
  Configure_systemd_networkd_to_ignore_foreign_rules5-->|Task| Force_systemd_daemon_reload6[force systemd daemon reload]:::task
  Force_systemd_daemon_reload6-->|Task| Enable_and_start_routing_fix_timer7[enable and start routing fix timer<br>When: **not ansible check mode**]:::task
  Enable_and_start_routing_fix_timer7-->|Task| Ensure_routing_fix_service_is_enabled8[ensure routing fix service is enabled<br>When: **not ansible check mode**]:::task
  Ensure_routing_fix_service_is_enabled8-->End
```





## Author Information
rc

### License

MIT

### Minimum Ansible Version

2.20.0

### Platforms

- **Ubuntu**: ['noble']


### Dependencies

No dependencies specified.
<!-- DOCSIBLE END -->
