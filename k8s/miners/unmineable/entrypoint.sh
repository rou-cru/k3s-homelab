#!/bin/sh

set -e

# ==============================================================================
# COLORS VARIABLES
# ==============================================================================

GREEN="\\033[0;92m"
YELLOW="\\033[0;93m"
PURPLE="\\033[0;95m"
CYAN="\\033[0;96m"
NC="\\033[0;97m"

# ==============================================================================
# MINING VARIABLES
# ==============================================================================

CPU_LIMIT_ENABLE="${CPU_LIMIT_ENABLE:-true}"
CPU_LIMIT_PERCENT="${CPU_LIMIT_PERCENT:-100}"
CPU_LIMIT=$(($(nproc) * $CPU_LIMIT_PERCENT))

POOL="${MINING_POOL:-rx.unmineable.com:3333}"
COIN="${COIN:-SHIB}"
REFERRAL_CODE="${REFERRAL_CODE:-18ps-7t5s}"
WALLET_ADDRESS="${WALLET_ADDRESS:-0xb3FEb8873EBE00FA21c7A08F4688d8402487799E}"
WORKER_NAME="${WORKER_NAME:-dockerworker}"
XMRIG_CONFIG_FILE="/usr/src/mining/config/xmrig.json"

# ==============================================================================
# FUNCTIONS
# ==============================================================================

Status() {
  echo -e "${CYAN}[INFO]${NC}: $1"
}

if [[ "$MINING_AUTO_CONFIG" == "true" ]]; then
  Status "Starting miner with config..."
  exec xmrig -c "$XMRIG_CONFIG_FILE" "$@"
else
  Status "Starting miner with cli parameters..."
  
  # Construct arguments based on Env Vars
  ARGS="-o $POOL -a rx/0 -k -u $COIN:$WALLET_ADDRESS.$WORKER_NAME#$REFERRAL_CODE -p x --donate-level=0"
  
  if [ -n "$MINING_THREADS" ]; then
    Status "Threads manually set to: $MINING_THREADS"
    ARGS="$ARGS --threads=$MINING_THREADS"
  fi

  # Exec replaces the shell with xmrig (PID 1)
  # -c points to our read-only ConfigMap for low-level settings
  exec xmrig -c "$XMRIG_CONFIG_FILE" $ARGS
fi

if [[ "$CPU_LIMIT_ENABLE" == "true" ]]; then
  Status "Enable CPU Limit..."
  cpulimit -l $CPU_LIMIT -p $(pidof xmrig) -z
else
  Status "Disable CPU Limit..."
fi
