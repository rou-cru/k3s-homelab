#!/bin/sh
set -eu

: "${MINING_POOL_HOST:?MINING_POOL_HOST is required}"
: "${MINING_POOL_PORT:?MINING_POOL_PORT is required}"
: "${MINING_ALGO:?MINING_ALGO is required}"
: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
: "${MINING_WORKER_NAME:?MINING_WORKER_NAME is required}"
: "${MINING_POOL_SCHEME:=stratum+tcp}"
: "${POOL_TYPE:?POOL_TYPE is required}"

algo_flag=""
case "${MINING_ALGO:-}" in
  rx/0|randomx) algo_flag="--randomx" ;;
  xelishashv3|xelishash|xelis) algo_flag="--xel" ;;
  *) algo_flag="" ;;
esac

pool_url="${MINING_POOL_SCHEME}://${MINING_POOL_HOST}:${MINING_POOL_PORT}"

case "${POOL_TYPE}" in
  unmineable)
    : "${MINING_COIN:?MINING_COIN is required for POOL_TYPE=unmineable}"
    : "${REFERRAL_CODE:?REFERRAL_CODE is required for POOL_TYPE=unmineable}"
    user="${MINING_COIN}:${WALLET_ADDRESS}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"
    ;;
  kryptex)
    user="${WALLET_ADDRESS}.${MINING_WORKER_NAME}"
    ;;
  *)
    echo "Unsupported POOL_TYPE: ${POOL_TYPE}" >&2
    exit 1
    ;;
esac

dev_fee="${DEV_FEE:-1.0}"

set -- /usr/local/bin/tnn-miner-cpu \
  --broadcast \
  --daemon-address "${pool_url}" \
  --port "${MINING_POOL_PORT}" \
  --wallet "${user}" \
  --password "${MINING_PASS:-x}" \
  --worker-name "${MINING_WORKER_NAME}" \
  --dev-fee "${dev_fee}" \
  --ignore-wallet \
  ${algo_flag}

if [ -n "${MINING_THREADS:-}" ]; then
  set -- "$@" --threads "${MINING_THREADS}"
fi

if ! echo "${pool_url}" | grep -qi "stratum"; then
  set -- "$@" --stratum
fi

if [ "${algo_flag}" = "--randomx" ]; then
  set -- "$@" --rx-hugepages
fi

if [ -n "${CPU_AFFINITY_MASK:-}" ]; then
  set -- "$@" --no-lock
  exec taskset "${CPU_AFFINITY_MASK}" "$@"
fi

exec "$@"
