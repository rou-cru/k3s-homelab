#!/bin/bash
set -e

# Defaults
POOL="${MINING_POOL:-autolykos.unmineable.com}"
PORT="${MINING_PORT:-3333}"
ALGO="${MINING_ALGO:-AUTOLYKOS2}"
COIN="${MINING_COIN:-AVAX}"
WORKER="${MINING_WORKER_NAME:-gpu-miner}"

if [ -z "$WALLET_ADDRESS" ]; then
    echo "Error: WALLET_ADDRESS is required"
    exit 1
fi

if [ -z "$REFERRAL_CODE" ]; then
    USER_ARG="${COIN}:${WALLET_ADDRESS}.${WORKER}"
else
    USER_ARG="${COIN}:${WALLET_ADDRESS}.${WORKER}#${REFERRAL_CODE}"
fi

echo "Starting lolMiner..."
echo "Algorithm: $ALGO"
echo "Pool: $POOL:$PORT"
echo "User: $USER_ARG"

exec lolMiner \
    --algo "$ALGO" \
    --pool "$POOL:$PORT" \
    --user "$USER_ARG" \
    --pass x \
    --apiport 4067 \
    --nocolor
