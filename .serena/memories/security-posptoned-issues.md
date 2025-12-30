# Security Issues - Postponed for Future Implementation

## 1. Script Execution from Internet without GPG Verification

### Current Implementation
- `roles/tailscale/tasks/main.yml:2-5`: `curl -fsSL https://tailscale.com/install.sh | sh`
- `roles/k3s_server/tasks/main.yml:14-18`: `curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=... sh -`

### Security Risks
- **Man-in-the-middle attacks**: No GPG signature verification
- **Supply chain compromise**: If upstream server is compromised
- **Arbitrary code execution** as root
- **No guaranteed idempotency**: Script behavior can change

### Recommended Remediation (Future Sprint)
1. Download scripts to temporary files first
2. Verify GPG signatures/checksums
3. Review content before execution
4. Prefer official APT repositories when available

### Priority
⭐⭐⭐⭐⭐ CRITICAL (but postponed per user request)

---

## 2. Secret Exposure in Ansible Logs

### Current Implementation
- `roles/tailscale/tasks/main.yml:16`: Auth key visible in shell command
- `site.yaml:6-7`: Secrets loaded from plaintext file

### Security Risks
- Secrets visible in `-v`, `-vv`, `-vvv` verbose output
- Secrets saved in CI/CD logs
- Secrets in terminal history
- No protection against accidental disclosure

### Recommended Remediation (Future Sprint)
```yaml
- name: Tailscale up
  shell: |
    tailscale up --auth-key="${TS_KEY}" ...
  environment:
    TS_KEY: "{{ tailscale_authkey }}"
  no_log: true  # CRITICAL: Prevents logging
```

Additional improvements:
- Implement Ansible Vault for secrets.yaml encryption
- Use environment variables for sensitive values
- Add `no_log: true` to all tasks handling secrets

### Priority
⭐⭐⭐⭐ HIGH (but postponed per user request)

---

## Status
**POSTPONED** - Documented for future implementation
**Reason**: User prioritizing code structure and maintainability improvements first
**Next Review**: After completion of script extraction and hardcoded values elimination
