# Refactor Meta-Analysis Requirements

## Script Hardening Requirements

### apply-rog-tweaks.sh.j2

**Input Validation (add at script start):**
```bash
# Validate battery_charge_threshold range (0-100)
if ! [[ "$BATTERY_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$BATTERY_THRESHOLD" -lt 0 ] || [ "$BATTERY_THRESHOLD" -gt 100 ]; then
    logger -t rog-tweaks -p err "Invalid battery threshold: ${BATTERY_THRESHOLD}. Must be 0-100."
    exit 1
fi

# Validate thermal_policy (0, 1, or 2)
if ! [[ "$THERMAL_MODE" =~ ^[0-2]$ ]]; then
    logger -t rog-tweaks -p err "Invalid thermal policy: ${THERMAL_MODE}. Must be 0, 1, or 2."
    exit 1
fi
```

**Post-Write Validation:**
```bash
# Battery threshold
if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
    echo "$BATTERY_THRESHOLD" > "$BAT_PATH/charge_control_end_threshold"
    CURRENT=$(cat "$BAT_PATH/charge_control_end_threshold" 2>/dev/null)
    if [ "$CURRENT" = "$BATTERY_THRESHOLD" ]; then
        logger -t rog-tweaks -p info "Battery threshold set to ${BATTERY_THRESHOLD}%"
    else
        logger -t rog-tweaks -p warning "Battery threshold write failed: current=${CURRENT}, expected=${BATTERY_THRESHOLD}"
    fi
fi

# Thermal policy
if [ -f "$THERMAL_POLICY_PATH" ]; then
    echo "$THERMAL_MODE" > "$THERMAL_POLICY_PATH"
    CURRENT=$(cat "$THERMAL_POLICY_PATH" 2>/dev/null)
    if [ "$CURRENT" = "$THERMAL_MODE" ]; then
        logger -t rog-tweaks -p info "Thermal policy set to ${THERMAL_MODE}"
    else
        logger -t rog-tweaks -p warning "Thermal policy write failed: current=${CURRENT}, expected=${THERMAL_MODE}"
    fi
fi
```

**Replace all `echo` with `logger`:**
- `echo "message"` → `logger -t rog-tweaks -p info "message"`

### optimize-network.sh.j2

**Post-Execution Validation:**
```bash
# EEE disable verification
if ethtool --show-eee "$INTERFACE" 2>/dev/null | grep -q "EEE is enabled"; then
    logger -t network-optimization -p warning "EEE still enabled after disable attempt"
else
    logger -t network-optimization -p info "EEE successfully disabled"
fi

# Ring buffer verification
CURRENT_RX=$(ethtool -g "$INTERFACE" 2>/dev/null | grep -A 4 "Current hardware settings:" | grep "RX:" | awk '{print $2}')
logger -t network-optimization -p info "Ring buffers: RX=${CURRENT_RX}, TX=${CURRENT_TX}"
```

**Replace all `echo` with `logger`:**
- `echo "message"` → `logger -t network-optimization -p info "message"`

## Static Analysis Tooling

**Devbox packages (via `devbox add`):**
```bash
devbox add shellcheck@latest shfmt@latest yamllint@latest yamlfmt@latest \
           ansible-lint@latest j2lint@latest go-task@latest
```

**Task-based pipeline (Taskfile.yml):**
- Orchestrate validation steps
- Task runner replaces monolithic bash scripts
- Declarative task definitions with dependencies

**Template rendering:**
```bash
ansible localhost -m template \
    -a "src=roles/$role/templates/script.sh.j2 dest=/tmp/rendered.sh" \
    -e @"roles/$role/defaults/main.yml" \
    --connection=local
bash -n /tmp/rendered.sh
shellcheck /tmp/rendered.sh
```

**Validation coverage:**
- YAML: yamllint + yamlfmt (autofix)
- Ansible: ansible-lint --fix (autofix)
- Jinja2: j2lint (lint only)
- Bash (rendered): bash -n + shellcheck + shfmt (autofix formatting)
- Systemd: systemd-analyze verify (system tool)

## Justification

- **Post-write validation:** Current scripts assume writes succeed; kernel may silently ignore values
- **Structured logging:** Enable `journalctl -t <tag>` filtering for debugging
- **Input validation:** Prevent invalid Ansible variables from causing silent failures
- **Error levels:** Use `-p info|warning|err` for proper log severity
