#!/bin/bash
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
OUTPUT="network_report.txt"

if [ -z "$INTERFACE" ]; then
    echo "Error: Could not detect primary network interface."
    exit 1
fi

echo "=== NETWORK DIAGNOSTIC REPORT ===" > $OUTPUT
echo "Timestamp: $(date)" >> $OUTPUT
echo "Interface: $INTERFACE" >> $OUTPUT

echo -e "\n--- 1. BASIC SETTINGS (ethtool) ---" >> $OUTPUT
ethtool $INTERFACE >> $OUTPUT 2>&1

echo -e "\n--- 2. DRIVER INFO (ethtool -i) ---" >> $OUTPUT
ethtool -i $INTERFACE >> $OUTPUT 2>&1

echo -e "\n--- 3. ENERGY EFFICIENT ETHERNET (EEE) ---" >> $OUTPUT
ethtool --show-eee $INTERFACE >> $OUTPUT 2>&1

echo -e "\n--- 4. LINK STATISTICS (ip -s link) ---" >> $OUTPUT
ip -s link show $INTERFACE >> $OUTPUT 2>&1

echo -e "\n--- 5. EXTENDED STATISTICS (ethtool -S) ---" >> $OUTPUT
ethtool -S $INTERFACE | grep -iE "drop|fail|error|reset|miss|discard" >> $OUTPUT 2>&1

echo -e "\n--- 6. RING BUFFER SETTINGS (ethtool -g) ---" >> $OUTPUT
ethtool -g $INTERFACE >> $OUTPUT 2>&1

echo -e "\n--- 7. PCI DEVICE DETAILS (lspci) ---" >> $OUTPUT
lspci -vv -s $(lspci | grep -i ethernet | awk '{print $1}') >> $OUTPUT 2>&1

echo "Report generated at: $OUTPUT"
chmod 644 $OUTPUT
