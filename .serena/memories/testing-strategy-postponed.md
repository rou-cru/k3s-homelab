# Testing Strategy - Postponed for Future Implementation

## Current Status
**POSTPONED** - No testing environment available for validation before production deployment

## Risks of No-Test Deployment

### Critical Risks
1. **Script Extraction Failures**
   - Bash scripts with Jinja2 templating may break if extracted incorrectly
   - Systemd unit files may have syntax errors not caught by `--check`
   - Variable interpolation errors only visible at runtime

2. **Parametrization Errors**
   - Hardcoded values replaced with variables may have type mismatches
   - Calculated values (e.g., nvidia-utils version) may fail regex parsing
   - Default values may not match current behavior

3. **Validation Logic Bugs**
   - Assert conditions may be too strict and fail on valid configs
   - Pre-flight checks may block legitimate deployments
   - Dependency validation may have false positives

4. **Reboot Consolidation Issues**
   - Kernel/driver dependency ordering may break
   - Services may not start correctly after consolidated reboot
   - System may enter unbootable state

### Current Mitigation
- Using `ansible-playbook --syntax-check` (validates YAML syntax only)
- Using `ansible-playbook --check` (dry-run, but doesn't validate bash/systemd)
- Git commits after each iteration for rollback capability
- **NOT SUFFICIENT FOR PRODUCTION SAFETY**

---

## Recommended Testing Strategy (Future Sprint)

### Phase 1: Local Testing Environment

#### Option 1: Multipass VM (Recommended)
```bash
# Create test VM matching production
multipass launch 22.04 --name k3s-test --memory 4G --disk 20G --cpus 2

# Configure SSH access
multipass exec k3s-test -- sudo useradd -m -s /bin/bash ubuntu
multipass exec k3s-test -- sudo usermod -aG sudo ubuntu
multipass exec k3s-test -- sudo bash -c 'echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu'

# Get VM IP and add to inventory
multipass info k3s-test | grep IPv4

# Test inventory
cat > inventory.test.ini <<EOF
[k3s_server]
k3s-test ansible_host=<VM_IP> gpu_setup=false

[all:vars]
ansible_user=ubuntu
ansible_become=true
EOF

# Run playbook against test VM
ansible-playbook -i inventory.test.ini site.yaml --check
ansible-playbook -i inventory.test.ini site.yaml
```

**Benefits:**
- Real Ubuntu 22.04 environment
- Safe to break/rebuild
- Fast iteration cycles
- Can simulate GPU setup with mock hardware

**Time investment:** ~30 min setup, reusable for all future changes

---

#### Option 2: Molecule (Advanced)
```bash
# Install Molecule
pip install molecule molecule-plugins[docker]

# Initialize for each role
cd roles/common
molecule init scenario --driver-name docker

# Configure molecule.yml
cat > molecule/default/molecule.yml <<EOF
driver:
  name: docker
platforms:
  - name: ubuntu-22.04
    image: ubuntu:22.04
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
provisioner:
  name: ansible
verifier:
  name: ansible
EOF

# Test role
molecule test
```

**Benefits:**
- Automated testing per role
- Idempotency validation built-in
- Can integrate with CI/CD
- Industry standard for Ansible testing

**Time investment:** ~2-3h initial setup per role

---

#### Option 3: Docker Container (Quick & Dirty)
```bash
# Run systemd-enabled Ubuntu container
docker run -d --name ansible-test --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  ubuntu/systemd:22.04

# Install SSH server
docker exec ansible-test apt-get update
docker exec ansible-test apt-get install -y openssh-server sudo python3

# Configure ansible user
docker exec ansible-test useradd -m -s /bin/bash ubuntu
docker exec ansible-test bash -c 'echo "ubuntu:test123" | chpasswd'
docker exec ansible-test usermod -aG sudo ubuntu

# Test
ansible-playbook -i container-inventory.ini site.yaml
```

**Benefits:**
- Faster than VM (seconds to start)
- Easy cleanup
- Good for quick validation

**Limitations:**
- No real hardware (GPU, networking quirks)
- Systemd may behave differently than real VM

---

### Phase 2: Validation Strategy

#### Pre-Deployment Checks
1. **Syntax Validation:**
   ```bash
   ansible-playbook site.yaml --syntax-check
   ansible-lint site.yaml  # Requires: pip install ansible-lint
   ```

2. **Bash Script Validation:**
   ```bash
   shellcheck roles/*/files/*.sh
   shellcheck roles/*/templates/*.sh.j2  # With Jinja2 stripped
   ```

3. **Dry Run:**
   ```bash
   ansible-playbook site.yaml --check --diff
   ```

#### Post-Deployment Validation
1. **Service Health:**
   ```bash
   # On target host
   systemctl status k3s
   systemctl status tailscaled
   k3s kubectl get nodes -o wide
   k3s kubectl get pods -A
   ```

2. **Network Validation:**
   ```bash
   tailscale status
   k3s kubectl -n kube-system rollout status ds/cilium
   ```

3. **GPU Validation (if applicable):**
   ```bash
   nvidia-smi
   k3s kubectl get nodes -o json | jq '.items[].status.capacity'
   ```

---

### Phase 3: CI/CD Integration (Future)

#### GitHub Actions Example
```yaml
name: Ansible Validation
on: [pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: |
          pip install ansible ansible-lint
          apt-get install shellcheck
      - name: Lint Ansible
        run: ansible-lint site.yaml
      - name: Lint Bash scripts
        run: shellcheck roles/*/files/*.sh

  molecule:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Molecule
        run: pip install molecule molecule-plugins[docker]
      - name: Test roles
        run: |
          cd roles/common && molecule test
          cd roles/tailscale && molecule test
```

---

## Immediate Action Items (Before Production Deployment)

### Critical (DO BEFORE IMPLEMENTING REFACTOR)
- [ ] Create Multipass test VM or Docker container
- [ ] Validate current playbook works in test environment
- [ ] Document rollback procedure (snapshots, git revert steps)

### High Priority (AFTER Refactor Implementation)
- [ ] Run full playbook in test environment
- [ ] Validate all services start correctly
- [ ] Test idempotency (run playbook twice, second run should have minimal changes)
- [ ] Verify reboot scenarios (test consolidated vs sequential)

### Medium Priority (Future Sprint)
- [ ] Set up Molecule testing framework
- [ ] Create CI/CD pipeline with automated tests
- [ ] Document testing procedures in CLAUDE.md

---

## Decision Record

**Date:** 2025-12-30
**Decision:** Postpone testing setup to proceed with refactoring
**Rationale:** Time constraints, production deployment will be manual with careful monitoring
**Accepted Risks:**
- First real validation happens in production
- Rollback may be required if issues found
- Downtime possible during deployment

**Mitigation:**
- Git commits after each iteration for granular rollback
- Syntax checking before deployment
- Manual validation of each service post-deployment
- Scheduled maintenance window for deployment

**Review Date:** After refactoring completion, before next major change
