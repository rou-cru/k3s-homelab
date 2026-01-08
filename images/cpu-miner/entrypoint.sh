#!/bin/sh
set -e

# Defaults
POOL="${POOL:-rx.unmineable.com:3333}"
ALGO="${ALGO:-rx/0}"
COIN="${COIN:-AVAX}"
WORKER_NAME="${WORKER_NAME:-cpu-miner}"
# Threads default: auto (XMRig detects), but we allow override
THREADS="${MINING_THREADS}" 

if [ -z "$WALLET_ADDRESS" ]; then
    echo "Error: WALLET_ADDRESS is required"
    exit 1
fi

if [ -z "$REFERRAL_CODE" ]; then
    echo "Warning: No REFERRAL_CODE set"
    USER_ARG="${COIN}:${WALLET_ADDRESS}.${WORKER_NAME}"
else
    USER_ARG="${COIN}:${WALLET_ADDRESS}.${WORKER_NAME}#${REFERRAL_CODE}"
fi

echo "Starting XMRig..."
echo "Pool: $POOL"
echo "Algo: $ALGO"
echo "User: $USER_ARG"

ARGS="-o $POOL -a $ALGO -u $USER_ARG -p x -k --donate-level=0"

if [ ! -z "$THREADS" ]; then
    ARGS="$ARGS --threads=$THREADS"
fi

if [ ! -z "$CPU_AFFINITY_MASK" ]; then
    # Convert hex mask to decimal or list for --cpu-affinity if needed
    # But XMRig supports hex mask directly via config or --cpu-affinity
    # We pass it through directly assuming the user knows the format
    ARGS="$ARGS --cpu-affinity=$CPU_AFFINITY_MASK"
fi

exec xmrig $ARGS
