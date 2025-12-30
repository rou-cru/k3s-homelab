# Reboot Strategy Analysis - K3s Homelab

## Research Summary (2025-12-30)

### Critical Findings from NVIDIA/Ubuntu Documentation

#### 1. HWE Kernel Upgrade Reboot Requirement
**Source:** Ubuntu documentation, NVIDIA installation guides

**CRITICAL:** After HWE kernel installation, you **MUST reboot BEFORE installing NVIDIA drivers**

**Reason:**
- New kernel is not active until reboot
- NVIDIA driver DKMS modules compile against the **running** kernel
- Installing NVIDIA driver before rebooting = driver compiled against OLD kernel
- Result: Module version mismatch, driver fails to load

**Confirmed workflow:**
```
1. Install HWE kernel packages
2. REBOOT (to activate new kernel)
3. Install NVIDIA drivers (DKMS builds against new kernel)
4. REBOOT (to load NVIDIA kernel modules)
```

#### 2. Nouveau Blacklist Requirement
**Source:** NVIDIA official documentation

**CRITICAL:** Nouveau blacklist + initramfs update requires reboot

**Workflow:**
```
1. Blacklist nouveau in /etc/modprobe.d/
2. Update initramfs (regenerate boot image)
3. REBOOT (to boot with nouveau disabled)
4. Install NVIDIA proprietary driver
5. REBOOT (to load NVIDIA modules)
```

**Potential optimization:**
- If HWE kernel is already installed, nouveau blacklist can happen before HWE kernel reboot
- This consolidates 2 reboots into 1: (HWE kernel + nouveau blacklist) → REBOOT → NVIDIA install → REBOOT

---

## Current Implementation Analysis

### Current Reboot Points in Playbook

1. **roles/common/tasks/main.yml:26-31**
   - Trigger: HWE kernel package installation
   - Condition: `base_packages_install.changed and ("linux-image" in ... or "linux-headers" in ...)`
   - **Status:** ✅ REQUIRED - Cannot be consolidated

2. **roles/common/tasks/rog_hardware.yml:43-48**
   - Trigger: r8168 driver install OR r8169 blacklist OR GRUB changes
   - Condition: `r8168_install.changed or r8169_blacklist.changed or grub_aspm.changed`
   - **Status:** ⚠️ POTENTIALLY CONSOLIDABLE with HWE kernel reboot

3. **roles/nvidia_gpu/tasks/main.yml:77-85**
   - Trigger: NVIDIA driver install OR nouveau blacklist
   - Condition: `driver_install.changed or blacklist_nouveau.changed`
   - **Status:** ✅ REQUIRED - Cannot be consolidated with previous reboots

### Reboot Consolidation Analysis

#### Scenario 1: Clean Install (No Previous Kernel/Drivers)
**Current behavior:**
1. Common role installs HWE kernel → REBOOT 1
2. RoG hardware role installs r8168 driver + modifies GRUB → REBOOT 2
3. NVIDIA GPU role blacklists nouveau + installs driver → REBOOT 3

**Total: 3 reboots (~15 minutes of reboot time)**

#### Scenario 2: With Consolidation
**Optimized behavior:**
1. Common + RoG roles install HWE kernel, r8168, GRUB changes, nouveau blacklist → REBOOT 1
2. NVIDIA GPU role installs driver → REBOOT 2

**Total: 2 reboots (~10 minutes of reboot time)**

**Savings: ~5 minutes, 1 less reboot**

#### Scenario 3: Idempotent Run (Everything Already Installed)
**Current behavior:** 0 reboots ✅
**Optimized behavior:** 0 reboots ✅

**No regression**

---

## Recommended Reboot Strategy

### Strategy A: Conditional Batching (RECOMMENDED)

**Implementation:**
1. Track reboot requirements across roles using facts
2. Defer reboot until end of "preparation phase"
3. Execute 1 consolidated reboot after: common + rog_hardware + nouveau blacklist
4. Execute 2nd reboot after NVIDIA driver installation (required by kernel module loading)

**Benefits:**
- Reduces reboots from 3 → 2 in clean install
- Maintains correct dependency order (kernel active before driver compile)
- Idempotent runs still have 0 reboots
- Safe and technically sound

**Implementation approach:**
```yaml
# roles/common/tasks/main.yml
- name: Install HWE kernel
  apt: ...
  register: kernel_install

- set_fact:
    reboot_required_phase1: true
  when: kernel_install.changed

# roles/common/tasks/rog_hardware.yml
- name: Install r8168 / blacklist r8169
  ...
  register: network_driver_install

- set_fact:
    reboot_required_phase1: true
  when: network_driver_install.changed

# roles/nvidia_gpu/tasks/main.yml
- name: Blacklist nouveau
  ...
  register: nouveau_blacklist

- set_fact:
    reboot_required_phase1: true
  when: nouveau_blacklist.changed

# site.yaml (after common, tailscale, before k3s)
- name: Consolidated Phase 1 Reboot
  reboot:
    msg: "Rebooting to load new kernel and drivers"
  when: reboot_required_phase1 | default(false)

# After NVIDIA driver install
- name: Phase 2 Reboot (NVIDIA modules)
  reboot:
    msg: "Rebooting to load NVIDIA drivers"
  when: driver_install.changed
```

---

### Strategy B: Sequential Reboots (CURRENT IMPLEMENTATION)

**Status:** ✅ WORKS, but suboptimal

**Pros:**
- Simple to understand
- Each role is self-contained
- Easy to debug (clear cause-effect)

**Cons:**
- 3 reboots on clean install (unnecessary wait time)
- Each reboot adds ~5 minutes overhead

**Verdict:** Keep as fallback if Strategy A has issues

---

### Strategy C: Full Consolidation (REJECTED)

**Attempt:** Single reboot at end of playbook

**Why REJECTED:**
- ❌ Violates kernel → driver dependency
- ❌ NVIDIA driver would compile against old kernel
- ❌ High risk of module mismatch errors
- ❌ Not technically sound per NVIDIA docs

**Verdict:** DO NOT IMPLEMENT

---

## Implementation Decision

### Chosen Strategy: **Strategy A (Conditional Batching)**

**Phases:**
1. **Phase 1 Reboot** (after common + rog_hardware roles)
   - Loads: New HWE kernel, r8168 driver, nouveau blacklist
   - Condition: Any of the above changed

2. **Phase 2 Reboot** (after nvidia_gpu role)
   - Loads: NVIDIA kernel modules
   - Condition: NVIDIA driver installed

**Expected behavior:**
- Clean install: 2 reboots (down from 3)
- Idempotent run: 0 reboots (same as current)
- Technically correct per NVIDIA/Ubuntu docs

### Integration Points

**In site.yaml:**
```yaml
roles:
  - common
  - rog_hardware  # Sets reboot_required_phase1 if needed

# NEW: Consolidated reboot point
- name: Phase 1 System Reboot
  hosts: k3s_server
  become: true
  tasks:
    - name: Reboot for kernel/driver changes
      reboot:
        msg: "Rebooting to activate new kernel and drivers"
        reboot_timeout: 600
      when: reboot_required_phase1 | default(false)

roles (continued):
  - tailscale
  - k3s_server
  - nvidia_gpu  # Will reboot separately if driver installed
  - cilium
```

---

## Testing Checklist

Before deploying to production:
- [ ] Verify Phase 1 reboot happens after common+rog when HWE kernel changes
- [ ] Verify Phase 2 reboot happens after NVIDIA driver install
- [ ] Verify idempotent run has 0 reboots
- [ ] Verify nouveau is blacklisted before NVIDIA driver install
- [ ] Verify NVIDIA driver compiles against correct kernel version
- [ ] Verify GPU is detected after final reboot: `nvidia-smi`

---

## Rollback Plan

If consolidated reboot causes issues:
1. Revert to Strategy B (sequential reboots)
2. Git revert to previous commit
3. Each role handles its own reboot independently

**Rollback complexity:** LOW (single git revert)

---

## References

- NVIDIA Driver Installation Guide: https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/
- Ubuntu NVIDIA Drivers: https://ubuntu.com/server/docs/nvidia-drivers-installation
- HWE Kernel Installation: https://wiki.ubuntu.com/Kernel/LTSEnablementStack
- Ansible Reboot Module: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/reboot_module.html
