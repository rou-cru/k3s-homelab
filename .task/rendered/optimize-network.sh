#!/bin/bash
set -euo pipefail

# Managed by Ansible - Network Optimization Script
# Optimizes network interface for stability and performance

INTERFACE="eth0"

if [ -z "$INTERFACE" ]; then
	logger -t network-optimization -p info "No interface detected. Exiting."
	exit 0
fi

logger -t network-optimization -p info "Optimizing interface: $INTERFACE"

# 1. Disable Energy Efficient Ethernet (EEE)
if ethtool --show-eee "$INTERFACE" 2>/dev/null | grep -q "EEE is enabled"; then
	ethtool --set-eee "$INTERFACE" eee off
	logger -t network-optimization -p info "EEE disabled"
else
	logger -t network-optimization -p info "EEE already disabled or not supported"
fi

# Verify EEE is actually disabled
if ethtool --show-eee "$INTERFACE" 2>/dev/null | grep -q "EEE is enabled"; then
	logger -t network-optimization -p warning "EEE still enabled after disable attempt"
else
	logger -t network-optimization -p info "EEE successfully disabled"
fi

# 2. Disable Wake-on-LAN (Power Saving)
if ethtool -s "$INTERFACE" wol d 2>/dev/null; then
	logger -t network-optimization -p info "Wake-on-LAN disabled"
else
	logger -t network-optimization -p info "Wake-on-LAN disable not supported or already disabled"
fi

# 3. Maximize Ring Buffers (Crucial for 1Gbps/2.5Gbps stability)
# Try to set to target size or use hardware maximum
MAX_RX=$(ethtool -g "$INTERFACE" | grep -m1 "RX:" | awk '{print $2}')
MAX_TX=$(ethtool -g "$INTERFACE" | grep -m1 "TX:" | awk '{print $2}')

# If we can read the maximums, apply them. Otherwise try safe value.
if [ -n "$MAX_RX" ] && [ "$MAX_RX" -gt 256 ]; then
	if ethtool -G "$INTERFACE" rx "$MAX_RX" tx "$MAX_TX" 2>/dev/null; then
		CURRENT_RX=$(ethtool -g "$INTERFACE" 2>/dev/null | grep -A 4 "Current hardware settings:" | grep "RX:" | awk '{print $2}')
		CURRENT_TX=$(ethtool -g "$INTERFACE" 2>/dev/null | grep -A 4 "Current hardware settings:" | grep "TX:" | awk '{print $2}')
		logger -t network-optimization -p info "Ring buffers set: RX=${CURRENT_RX}/${MAX_RX}, TX=${CURRENT_TX}/${MAX_TX}"
	else
		logger -t network-optimization -p err "Failed to set ring buffers"
	fi
else
	logger -t network-optimization -p info "Ring buffers already optimal or undetectable"
fi
