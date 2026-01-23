<!-- DOCSIBLE START -->

# 📃 Role overview

## akash



Description: Deploy Akash Provider stack on K3s cluster










### Defaults

**These are static variables with lower priority**

#### File: defaults/main.yml

| Var          | Type         | Value       |Required    | Title       |
|--------------|--------------|-------------|------------|-------------|
| [akash_node_moniker](defaults/main.yml#L7)   | str | `homelab-provider` |    true  |  Akash Node Moniker |
| [akash_wallet_address](defaults/main.yml#L13)   | str |  |    true  |  Akash Wallet Address |
| [akash_keyring_backend](defaults/main.yml#L19)   | str | `os` |    false  |  Akash Keyring Backend |
| [akash_chain_id](defaults/main.yml#L25)   | str | `akashnet-2` |    false  |  Akash Chain ID |
| [akash_node_rpc](defaults/main.yml#L31)   | str | `https://rpc.akashnet.net:443` |    false  |  Akash RPC Node |
| [akash_provider_domain](defaults/main.yml#L37)   | str |  |    true  |  Provider Domain |
| [akash_bid_price_script](defaults/main.yml#L43)   | str |  |    false  |  Provider Bid Price Script |
| [akash_provider_attributes](defaults/main.yml#L49)   | list | `[]` |    false  |  Provider Attributes |
| [akash_provider_attributes.**0**](defaults/main.yml#L55)   | dict | `{}` |    false  |  Attribute Item |
| [akash_provider_attributes.0.**key**](defaults/main.yml#L55)   | str | `host` |    false  |  Attribute Item |
| [akash_provider_attributes.0.**value**](defaults/main.yml#L60)   | str | `akash` |    false  |  Attribute Value |
| [akash_provider_attributes.**1**](defaults/main.yml#L66)   | dict | `{}` |    false  |  Attribute Item |
| [akash_provider_attributes.1.**key**](defaults/main.yml#L66)   | str | `tier` |    false  |  Attribute Item |
| [akash_provider_attributes.1.**value**](defaults/main.yml#L71)   | str | `community` |    false  |  Attribute Value |
| [akash_provider_attributes.**2**](defaults/main.yml#L76)   | dict | `{}` |    false  |  Attribute Item |
| [akash_provider_attributes.2.**key**](defaults/main.yml#L76)   | str | `organization` |    false  |  Attribute Item |
| [akash_provider_attributes.2.**value**](defaults/main.yml#L81)   | str | `homelab` |    false  |  Attribute Value |
| [akash_gpu_vendor](defaults/main.yml#L87)   | str | `nvidia` |    false  |  GPU Vendor |
| [akash_gpu_model](defaults/main.yml#L93)   | str | `rtx4070` |    false  |  GPU Model |
| [akash_ingress_nginx_version](defaults/main.yml#L99)   | str | `4.11.3` |    false  |  Ingress Nginx Chart Version |
| [akash_hostname_operator_version](defaults/main.yml#L105)   | str | `1.0.0` |    false  |  Hostname Operator Chart Version |
| [akash_inventory_operator_version](defaults/main.yml#L111)   | str | `1.0.0` |    false  |  Inventory Operator Chart Version |
| [akash_provider_version](defaults/main.yml#L117)   | str | `6.0.0` |    false  |  Provider Chart Version |
| [akash_gpu_enabled](defaults/main.yml#L123)   | bool | `True` |    false  |  Enable GPU Support |
<details>
<summary><b>🖇️ Full descriptions for vars in defaults/main.yml</b></summary>
<br>
<table>
<th>Var</th><th>Description</th>
<tr><td><b>akash_node_moniker</b></td><td>Provider display name on the Akash network.</td></tr>
<tr><td><b>akash_wallet_address</b></td><td>Provider wallet address for receiving payments.</td></tr>
<tr><td><b>akash_keyring_backend</b></td><td>Keyring backend for wallet management.</td></tr>
<tr><td><b>akash_chain_id</b></td><td>Akash network chain ID.</td></tr>
<tr><td><b>akash_node_rpc</b></td><td>RPC endpoint for Akash network.</td></tr>
<tr><td><b>akash_provider_domain</b></td><td>Public domain for provider endpoints.</td></tr>
<tr><td><b>akash_bid_price_script</b></td><td>Path to bid pricing script.</td></tr>
<tr><td><b>akash_provider_attributes</b></td><td>Provider attributes for marketplace; list of {key,value} entries (e.g., host=akash, tier=community).</td></tr>
<tr><td><b>akash_provider_attributes.0</b></td><td>Provider attribute key/value pair (key is namespaced attribute, value is string).</td></tr>
<tr><td><b>akash_provider_attributes.0.key</b></td><td>Provider attribute key/value pair (key is namespaced attribute, value is string).</td></tr>
<tr><td><b>akash_provider_attributes.0.value</b></td><td>Provider attribute value (string).</td></tr>
<tr><td><b>akash_provider_attributes.1</b></td><td>Provider attribute key/value pair (key is namespaced attribute, value is string).</td></tr>
<tr><td><b>akash_provider_attributes.1.key</b></td><td>Provider attribute key/value pair (key is namespaced attribute, value is string).</td></tr>
<tr><td><b>akash_provider_attributes.1.value</b></td><td>Provider attribute value (string).</td></tr>
<tr><td><b>akash_provider_attributes.2</b></td><td>Provider attribute key/value pair (key is namespaced attribute, value is string).</td></tr>
<tr><td><b>akash_provider_attributes.2.key</b></td><td>Provider attribute key/value pair (key is namespaced attribute, value is string).</td></tr>
<tr><td><b>akash_provider_attributes.2.value</b></td><td>Provider attribute value (string).</td></tr>
<tr><td><b>akash_gpu_vendor</b></td><td>GPU vendor for GPU-enabled providers.</td></tr>
<tr><td><b>akash_gpu_model</b></td><td>GPU model name for attributes.</td></tr>
<tr><td><b>akash_ingress_nginx_version</b></td><td>Version of ingress-nginx Helm chart.</td></tr>
<tr><td><b>akash_hostname_operator_version</b></td><td>Version of akash-hostname-operator Helm chart.</td></tr>
<tr><td><b>akash_inventory_operator_version</b></td><td>Version of akash-inventory-operator Helm chart.</td></tr>
<tr><td><b>akash_provider_version</b></td><td>Version of akash-provider Helm chart.</td></tr>
<tr><td><b>akash_gpu_enabled</b></td><td>Whether to advertise GPU capabilities.</td></tr>
</table>
<br>
</details>





### Tasks


#### File: tasks/main.yml

| Name | Module | Has Conditions | Comments |
| ---- | ------ | -------------- | -------- |
| [Validate Akash configuration](tasks/main.yml#L6) | ansible.builtin.assert | False | Validate required variables |
| [Add Akash Helm repository](tasks/main.yml#L14) | kubernetes.core.helm_repository | False | Add Akash Helm repository |
| [Add Ingress Nginx Helm repository](tasks/main.yml#L21) | kubernetes.core.helm_repository | False | Add Ingress Nginx Helm repository |
| [Create akash-services namespace](tasks/main.yml#L28) | kubernetes.core.k8s | False | Create akash-services namespace |
| [Deploy Ingress Nginx for Akash](tasks/main.yml#L42) | kubernetes.core.helm | False | Deploy Ingress Nginx for Akash |
| [Deploy Akash Hostname Operator](tasks/main.yml#L74) | kubernetes.core.helm | False | Deploy Akash Hostname Operator |
| [Deploy Akash Inventory Operator](tasks/main.yml#L84) | kubernetes.core.helm | False | Deploy Akash Inventory Operator |
| [Build provider attributes](tasks/main.yml#L94) | ansible.builtin.set_fact | False | Build provider attributes |
| [Deploy Akash Provider](tasks/main.yml#L108) | kubernetes.core.helm | True | Deploy Akash Provider |
| [Display Akash setup instructions](tasks/main.yml#L139) | ansible.builtin.debug | False | Display post-installation instructions |


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

  Start-->|Task| Validate_Akash_configuration0[validate akash configuration]:::task
  Validate_Akash_configuration0-->|Task| Add_Akash_Helm_repository1[add akash helm repository]:::task
  Add_Akash_Helm_repository1-->|Task| Add_Ingress_Nginx_Helm_repository2[add ingress nginx helm repository]:::task
  Add_Ingress_Nginx_Helm_repository2-->|Task| Create_akash_services_namespace3[create akash services namespace]:::task
  Create_akash_services_namespace3-->|Task| Deploy_Ingress_Nginx_for_Akash4[deploy ingress nginx for akash]:::task
  Deploy_Ingress_Nginx_for_Akash4-->|Task| Deploy_Akash_Hostname_Operator5[deploy akash hostname operator]:::task
  Deploy_Akash_Hostname_Operator5-->|Task| Deploy_Akash_Inventory_Operator6[deploy akash inventory operator]:::task
  Deploy_Akash_Inventory_Operator6-->|Task| Build_provider_attributes7[build provider attributes]:::task
  Build_provider_attributes7-->|Task| Deploy_Akash_Provider8[deploy akash provider<br>When: **akash wallet address   length   0**]:::task
  Deploy_Akash_Provider8-->|Task| Display_Akash_setup_instructions9[display akash setup instructions]:::task
  Display_Akash_setup_instructions9-->End
```





## Author Information
rc

#### License

MIT

#### Minimum Ansible Version

2.14

#### Platforms

- **Ubuntu**: ['jammy', 'noble']


#### Dependencies

- **gvisor**
  
  

<!-- DOCSIBLE END -->
