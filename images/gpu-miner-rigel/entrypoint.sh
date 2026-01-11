#!/bin/bash
set -eu

: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
: "${MINING_WORKER_NAME:?MINING_WORKER_NAME is required}"
: "${MINING_POOL:?MINING_POOL is required}"
: "${MINING_PORT:?MINING_PORT is required}"
: "${MINING_COIN:?MINING_COIN is required}"
: "${REFERRAL_CODE:?REFERRAL_CODE is required}"
: "${MINING_PASS:=x}"
: "${GPU_POWER_LIMIT:=70}"
: "${GPU_CORE_OFFSET:=0}"
: "${GPU_MEM_OFFSET:=500}"
: "${GPU_TEMP_CORE_MIN:=55}"
: "${GPU_TEMP_CORE_MAX:=75}"
: "${GPU_TEMP_MEM_MIN:=70}"
: "${GPU_TEMP_MEM_MAX:=82}"

RIGEL_ALGO=$(echo "${MINING_ALGO}" | tr '[:upper:]' '[:lower:]')
UNMINEABLE_USER="${MINING_COIN}:${WALLET_ADDRESS}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"

echo "Starting Rigel (${RIGEL_ALGO}) for Unmineable..."
echo "Pool: ${MINING_POOL}:${MINING_PORT}"
echo "User: ${MINING_COIN}:...${WALLET_ADDRESS: -4}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"
echo "Worker: ${MINING_WORKER_NAME}"
echo "Power: ${GPU_POWER_LIMIT}W | Core: ${GPU_CORE_OFFSET:+${GPU_CORE_OFFSET}} | Mem: ${GPU_MEM_OFFSET:+${GPU_MEM_OFFSET}}"

POOL_URL="stratum+ssl://${MINING_POOL}:${MINING_PORT}"

exec rigel \
  -a "${RIGEL_ALGO}" \
  -o "${POOL_URL}" \
  -u "${UNMINEABLE_USER}" \
  -p "${MINING_PASS}" \
  --api-bind 0.0.0.0:4067 \
  --no-tui \
  --no-color \
  --no-strict-ssl \
  --cclock "${GPU_CORE_OFFSET}" \
  --mclock "${GPU_MEM_OFFSET}" \
  --temp-limit "tc[${GPU_TEMP_CORE_MIN}-${GPU_TEMP_CORE_MAX}]tm[${GPU_TEMP_MEM_MIN}-${GPU_TEMP_MEM_MAX}]"
