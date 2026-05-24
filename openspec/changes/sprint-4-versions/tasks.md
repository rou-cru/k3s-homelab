# Tasks: Sprint 4 - Fijado y Upgrade de Versiones

## Phase 1: Core Variables Update

### Task 1.1: Update group_vars/all.yml with all versions
**Agent**: sdd-apply
**Files**: `group_vars/all.yml`
**Instructions**:
1. Update `k3s_version` from "v1.35.0+k3s1" to "v1.35.3+k3s1"
2. Update `cilium_chartVersion` from "1.19.0" to "1.19.3"
3. Update `gateway_apiVersion` from "v1.2.0" to "v1.5.1"
4. Update `prometheus_operatorCrdsVersion` from "26.0.0" to "28.0.1"
5. Update `gvisor_version` from "20231204.0" to "20260413.0"
6. Add new variable `certManager_chartVersion: "v1.20.2"` after line 156
7. Add new variable `argocd_chartVersion: "9.4.17"` after line 172
8. Add new variable `externalSecrets_chartVersion: "2.3.0"` (find appropriate location near other chart versions)

**Verification**:
- Run `yamllint group_vars/all.yml` - should pass
- Run `ansible-playbook --check site.yml` - should not fail on undefined variables

---

### Task 1.2: Update NVIDIA version in k3s_server group vars
**Agent**: sdd-apply
**Files**: `group_vars/k3s_server.yml`
**Instructions**:
1. Update `nvidia_devicePluginVersion` from "0.14.3" to "0.19.0" (line 21)

**Verification**:
- yamllint passes
- Variable is properly defined

---

## Phase 2: argument_specs Synchronization

### Task 2.1: Update k3s_server argument_specs
**Agent**: sdd-apply
**Files**: `roles/k3s_server/meta/argument_specs.yml`
**Instructions**:
1. Update default of `k3s_serverVersion` from "v1.35.0+k3s1" to "v1.35.3+k3s1" (line 13)
2. Update description to reflect new version if mentioned

**Verification**:
- yamllint passes

---

### Task 2.2: Update k3s_agent argument_specs
**Agent**: sdd-apply
**Files**: `roles/k3s_agent/meta/argument_specs.yml`
**Instructions**:
1. Update default of `k3s_agentVersion` from "v1.35.0+k3s1" to "v1.35.3+k3s1" (line 13)

**Verification**:
- yamllint passes

---

### Task 2.3: Fix Cilium argument_specs inconsistency
**Agent**: sdd-apply
**Files**: `roles/cilium/meta/argument_specs.yml`
**Instructions**:
1. Update default of `cilium_chartVersion` from "1.18.5" to "1.19.3" (line 11)

**Verification**:
- yamllint passes
- Default now matches group_vars/all.yml

---

### Task 2.4: Update crds_bootstrap argument_specs
**Agent**: sdd-apply
**Files**: `roles/crds_bootstrap/meta/argument_specs.yml`
**Instructions**:
1. Update default of `gateway_apiVersion` from "v1.2.0" to "v1.5.1" (line 13)
2. Consider adding default for `prometheus_operatorCrdsVersion`: "28.0.1" (currently required but no default)

**Verification**:
- yamllint passes

---

### Task 2.5: Add nvidia_gpu argument_specs
**Agent**: sdd-apply
**Files**: `roles/nvidia_gpu/meta/argument_specs.yml`
**Instructions**:
1. Add argument_specs entry for `nvidia_devicePluginVersion` with default "0.19.0"
2. Reference other meta/argument_specs.yml for format

**Verification**:
- File created with proper YAML structure
- yamllint passes

---

## Phase 3: Task and Configuration Updates

### Task 3.1: Update crds_bootstrap tasks for server-side apply
**Agent**: sdd-apply
**Files**: `roles/crds_bootstrap/tasks/main.yml`
**Instructions**:
1. Find the Gateway API CRD application task (around line 6-7)
2. Change `state: present` to `state: apply`
3. Add `server_side_apply: true` to the task parameters
4. Verify the change applies to Gateway API CRDs specifically

**Verification**:
- yamllint passes
- Ansible syntax check passes

---

### Task 3.2: Update NVIDIA values.yaml
**Agent**: sdd-apply
**Files**: `k8s/bootstrap/nvidia/values.yaml`
**Instructions**:
1. Add `enableNodeFeatureApi: true` under the appropriate section
2. Add `gfd.sleepInterval: infinite` (or appropriate configuration for v0.19.0)
3. Reference NVIDIA device plugin v0.19.0 documentation for correct values.yaml structure

**Verification**:
- yamllint passes
- File structure is valid YAML

---

### Task 3.3: Fix Taskfile.yml Cilium hardcoding
**Agent**: sdd-apply
**Files**: `Taskfile.yml`
**Instructions**:
1. Find the Cilium task around line 127
2. Replace hardcoded `--version 1.19.0` with `--version {{.cilium_chartVersion}}` or appropriate variable syntax
3. Ensure the variable reference matches Taskfile syntax (likely `.cilium_chartVersion` if defined in vars)

**Note**: Taskfile uses different variable syntax than Ansible. Check how other tasks reference variables.

**Verification**:
- Taskfile.yml is valid YAML
- `task --list` works without errors

---

## Phase 4: Documentation Updates

### Task 4.1: Update k3s_server README
**Agent**: sdd-apply
**Files**: `roles/k3s_server/README.md`
**Instructions**:
1. Find all occurrences of "v1.35.0+k3s1" (should be 3 per PENDING_SPRINTS.md)
2. Replace with "v1.35.3+k3s1"

**Verification**:
- All version references updated
- grep for "v1.35.0" returns no results

---

### Task 4.2: Update k3s_agent README
**Agent**: sdd-apply
**Files**: `roles/k3s_agent/README.md`
**Instructions**:
1. Find the occurrence of "v1.35.0+k3s1" (should be 1 per PENDING_SPRINTS.md)
2. Replace with "v1.35.3+k3s1"

**Verification**:
- Version reference updated

---

## Phase 5: Prometheus Stack Update

### Task 5.1: Update kube-prometheus-stack kustomization
**Agent**: sdd-apply
**Files**: `k8s/gitops/observability/kube-prometheus-stack/kustomization.yaml`
**Instructions**:
1. Update version from "72.6.2" to "83.6.0" (line 8)

**Verification**:
- yamllint passes

---

## Final Verification Tasks

### Task 6.1: Run full validation
**Agent**: sdd-verify
**Instructions**:
1. Run `task validate` to check all files
2. Run `ansible-playbook --check site.yml` for syntax validation
3. Verify no undefined variable errors
4. Create verification report

**Acceptance Criteria**:
- All yamllint checks pass
- Ansible syntax check passes
- No hardcoded versions remain (except where intentional)
- All argument_specs defaults match group_vars

---

## Task Dependencies

```
Phase 1 (Variables)
    │
    ├──→ Phase 2 (argument_specs)
    │       │
    │       ├──→ Phase 3 (Tasks/Configs)
    │       │       │
    │       │       ├──→ Phase 4 (Docs)
    │       │       │       │
    │       │       │       └──→ Phase 5 (Prometheus)
    │       │       │               │
    │       │       │               └──→ Phase 6 (Verification)
```

Tasks within each phase can run in parallel.
Phases must run sequentially.
