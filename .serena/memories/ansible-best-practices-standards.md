# Ansible Best Practices & Standards

## Module Usage Recommendations

### RFKill Module
**Current Implementation:**
- `roles/common/tasks/hardware_tuning.yml`: Uses `ansible.builtin.shell` to run `rfkill block wifi` and `rfkill block bluetooth`

**Recommended Improvement:**
- Use `community.general.rfkill` module instead of shell commands for better idempotency and error handling

**Benefits:**
- Proper Ansible module behavior
- Better error handling
- More idempotent operations
- Native Ansible integration

## Idempotency Considerations

### Tailscale Configuration
**Current Issue:**
- `tailscale up` command runs every time unless `creates` or `changed_when` is perfectly tuned
- Current check `creates: /var/lib/tailscale/tailscaled.state` is decent but doesn't handle re-configuration

**Recommendation:**
- Implement more sophisticated idempotency checks for configuration changes

## Quality Standards

### FQCN (Fully Qualified Collection Names)
- **Current Status:** Mostly used (`ansible.builtin.*`) which is good
- **Example:** `community.general.pam_limits` used correctly
- **Best Practice:** Continue using FQCN for all modules to ensure clarity and prevent conflicts

### Error Handling
- **Current Status:** Preflight checks use explicit `fail` tasks, which is good for user experience
- **Best Practice:** Maintain explicit error handling for critical validation tasks

### Reboot Strategy
- **Current Status:** The "Consolidated Reboot" pattern in `common` is effective and avoids multiple reboots during provisioning
- **Best Practice:** Continue using consolidated reboot patterns when multiple reboots would otherwise be required