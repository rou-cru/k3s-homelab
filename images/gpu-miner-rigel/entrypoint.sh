#!/bin/bash
set -eu

: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
: "${MINING_WORKER_NAME:?MINING_WORKER_NAME is required}"
: "${MINING_POOL_HOST:?MINING_POOL_HOST is required}"
: "${MINING_POOL_PORT:?MINING_POOL_PORT is required}"
: "${MINING_ALGO:?MINING_ALGO is required}"
: "${MINING_PASS:=x}"
: "${MINING_POOL_SCHEME:=stratum+ssl}"
: "${POOL_TYPE:=kryptex}"
: "${GPU_POWER_LIMIT:=70}"
: "${GPU_CORE_OFFSET:=0}"
: "${GPU_MEM_OFFSET:=500}"
: "${GPU_TEMP_CORE_MIN:=55}"
: "${GPU_TEMP_CORE_MAX:=75}"
: "${GPU_TEMP_MEM_MIN:=70}"
: "${GPU_TEMP_MEM_MAX:=82}"

if [ "${POOL_TYPE}" = "custom" ]; then
  if [ -z "${RIGEL_CMD:-}" ]; then
    echo "RIGEL_CMD is required when POOL_TYPE=custom" >&2
    exit 1
  fi
  echo "Using custom rigel command from RIGEL_CMD"
  exec /bin/sh -c "${RIGEL_CMD}"
fi

POOL_URL="${MINING_POOL_SCHEME}://${MINING_POOL_HOST}:${MINING_POOL_PORT}"

RIGEL_ALGO=$(echo "${MINING_ALGO}" | tr '[:upper:]' '[:lower:]')
case "${POOL_TYPE}" in
  unmineable)
    : "${MINING_COIN:?MINING_COIN is required for POOL_TYPE=unmineable}"
    : "${REFERRAL_CODE:?REFERRAL_CODE is required for POOL_TYPE=unmineable}"
    MINER_USER="${MINING_COIN}:${WALLET_ADDRESS}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"
    ;;
  kryptex)
    MINER_USER="${WALLET_ADDRESS}.${MINING_WORKER_NAME}"
    ;;
  *)
    echo "Unsupported POOL_TYPE: ${POOL_TYPE}" >&2
    exit 1
    ;;
esac

echo "Starting Rigel (${RIGEL_ALGO})..."
echo "Pool: ${POOL_URL}"
echo "User: ...${WALLET_ADDRESS: -4}.${MINING_WORKER_NAME}"
echo "Worker: ${MINING_WORKER_NAME}"
echo "Power: ${GPU_POWER_LIMIT}W | Core: ${GPU_CORE_OFFSET} | Mem: ${GPU_MEM_OFFSET}"

set -- rigel \
  -a "${RIGEL_ALGO}" \
  -o "${POOL_URL}" \
  -u "${MINER_USER}" \
  -p "${MINING_PASS}" \
  --api-bind 0.0.0.0:4067 \
  --no-tui \
  --no-color

case "${MINING_POOL_SCHEME}" in
  stratum+ssl|stratum+tls) set -- "$@" --no-strict-ssl ;;
esac

set -- "$@" \
  --cclock "${GPU_CORE_OFFSET}" \
  --mclock "${GPU_MEM_OFFSET}" \
  --temp-limit "tc[${GPU_TEMP_CORE_MIN}-${GPU_TEMP_CORE_MAX}]tm[${GPU_TEMP_MEM_MIN}-${GPU_TEMP_MEM_MAX}]"

exec "$@"
