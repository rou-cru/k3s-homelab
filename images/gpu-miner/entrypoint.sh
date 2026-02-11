#!/bin/bash
set -e

: "${MINING_POOL_HOST:?MINING_POOL_HOST is required}"
: "${MINING_POOL_PORT:?MINING_POOL_PORT is required}"
: "${MINING_ALGO:?MINING_ALGO is required}"
: "${MINING_WORKER_NAME:?MINING_WORKER_NAME is required}"
: "${POOL_TYPE:?POOL_TYPE is required}"
: "${MINING_POOL_SCHEME:=stratum+tcp}"

if [[ -z "$WALLET_ADDRESS" ]]; then
    echo "Error: WALLET_ADDRESS is required" >&2
    exit 1
fi

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

echo "Starting lolMiner..."
echo "Algorithm: ${MINING_ALGO}"
echo "Pool: ${MINING_POOL_HOST}:${MINING_POOL_PORT}"

exec lolMiner \
    --algo "${MINING_ALGO}" \
    --pool "${MINING_POOL_SCHEME}://${MINING_POOL_HOST}:${MINING_POOL_PORT}" \
    --user "$USER_ARG" \
    --pass "${MINING_PASS:-x}" \
    --apiport 4067 \
    --nocolor
