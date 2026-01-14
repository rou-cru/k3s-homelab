#!/bin/sh
set -e

: "${MINING_POOL_HOST:?MINING_POOL_HOST is required}"
: "${MINING_POOL_PORT:?MINING_POOL_PORT is required}"
: "${MINING_ALGO:?MINING_ALGO is required}"
: "${MINING_WORKER_NAME:?MINING_WORKER_NAME is required}"
: "${POOL_TYPE:?POOL_TYPE is required}"
: "${MINING_POOL_SCHEME:=stratum+tcp}"
THREADS="${MINING_THREADS}"

: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
case "${POOL_TYPE}" in
    unmineable)
        : "${MINING_COIN:?MINING_COIN is required for POOL_TYPE=unmineable}"
        : "${REFERRAL_CODE:?REFERRAL_CODE is required for POOL_TYPE=unmineable}"
        USER_ARG="${MINING_COIN}:${WALLET_ADDRESS}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"
        ;;
    kryptex)
        USER_ARG="${WALLET_ADDRESS}.${MINING_WORKER_NAME}"
        ;;
    *)
        echo "Unsupported POOL_TYPE: ${POOL_TYPE}" >&2
        exit 1
        ;;
esac

echo "Starting XMRig..."
echo "Pool: ${MINING_POOL_HOST}:${MINING_POOL_PORT}"
echo "Algo: ${MINING_ALGO}"

ARGS="-o ${MINING_POOL_SCHEME}://${MINING_POOL_HOST}:${MINING_POOL_PORT} -a ${MINING_ALGO} -u ${USER_ARG} -p ${MINING_PASS:-x} -k --donate-level=0"

if [ -n "$THREADS" ]; then
    ARGS="$ARGS --threads=$THREADS"
fi

if [ -n "$CPU_AFFINITY_MASK" ]; then
    # Convert hex mask to decimal or list for --cpu-affinity if needed
    # But XMRig supports hex mask directly via config or --cpu-affinity
    # We pass it through directly assuming the user knows the format
    ARGS="$ARGS --cpu-affinity=$CPU_AFFINITY_MASK"
fi

exec xmrig $ARGS
