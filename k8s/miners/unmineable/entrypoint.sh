#!/bin/bash

set -e

# ==============================================================================
# COLORS VARIABLES
# ==============================================================================

CYAN="\033[0;96m"
NC="\033[0;97m"

# ==============================================================================
# MINING VARIABLES
# ==============================================================================

POOL="${POOL:-${MINING_POOL:-stratum+ssl://rx.unmineable.com:443}}"
COIN="${COIN:-SHIB}"
ALGO="${ALGO:-rx/0}"
REFERRAL_CODE="${REFERRAL_CODE:-18ps-7t5s}"
: "${WALLET_ADDRESS:?WALLET_ADDRESS environment variable is required}"
WORKER_NAME="${WORKER_NAME:-dockerworker}"
XMRIG_CONFIG_FILE="/usr/src/mining/config/xmrig.json"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

Status() {
  echo -e "${CYAN}[INFO]${NC}: $1"
}

# Only replace config file if it exists (for robustness)
if [ -f "$XMRIG_CONFIG_FILE" ]; then
    sed -i "s|POOL|$POOL|g" "$XMRIG_CONFIG_FILE"
    sed -i "s|COIN|$COIN|g" "$XMRIG_CONFIG_FILE"
    sed -i "s|WALLET_ADDRESS|$WALLET_ADDRESS|g" "$XMRIG_CONFIG_FILE"
    sed -i "s|WORKER_NAME|$WORKER_NAME|g" "$XMRIG_CONFIG_FILE"
    sed -i "s|REFERRAL_CODE|$REFERRAL_CODE|g" "$XMRIG_CONFIG_FILE"
fi

THREADS_ARGS=""
AFFINITY_ARGS=""
if [ -n "${MINING_THREADS:-}" ]; then
  Status "Threads manually set to: $MINING_THREADS"
  THREADS_ARGS="--threads=$MINING_THREADS"
fi
if [ -n "${CPU_AFFINITY_MASK:-}" ]; then
  Status "CPU affinity mask set to: $CPU_AFFINITY_MASK"
  AFFINITY_ARGS="--cpu-affinity=$CPU_AFFINITY_MASK"
fi

# Sanitize wallet from logs
LOG_USER="${COIN}:...${WORKER_NAME}#${REFERRAL_CODE}"

if [[ "${MINING_AUTO_CONFIG:-false}" == "true" ]]; then
  Status "Starting miner with config..."
  exec xmrig -c "$XMRIG_CONFIG_FILE" $THREADS_ARGS $AFFINITY_ARGS "$@"
else
  Status "Starting miner with cli parameters..."
  # Use array for cleaner argument handling if shifting to bash arrays, 
  # but here keeping simple string expansion for now to match style, 
  # noting that exec handles arguments better.
  exec xmrig -o "$POOL" -a "$ALGO" -k \
    -u "$COIN:$WALLET_ADDRESS.$WORKER_NAME#$REFERRAL_CODE" \
    -p x $THREADS_ARGS $AFFINITY_ARGS "$@"
fi