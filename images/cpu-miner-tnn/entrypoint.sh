#!/bin/sh
set -eu

: "${POOL:?POOL is required}"
: "${COIN:?COIN is required}"
: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
: "${WORKER_NAME:?WORKER_NAME is required}"
: "${REFERRAL_CODE:?REFERRAL_CODE is required}"

algo_flag=""
case "${ALGO:-}" in
  rx/0|randomx) algo_flag="--randomx" ;;
  xelishashv3|xelishash|xelis) algo_flag="--xel" ;;
  *) algo_flag="" ;;
esac

pool_url="${POOL}"
# Strip scheme for host/port extraction
pool_no_scheme="${pool_url#*://}"
# Split host and port
pool_host="${pool_no_scheme%%:*}"
pool_port="${pool_no_scheme##*:}"

if echo "${pool_url}" | grep -qi "unmineable"; then
  user="${COIN}:${WALLET_ADDRESS}.${WORKER_NAME}#${REFERRAL_CODE}"
else
  user="${WALLET_ADDRESS}.${WORKER_NAME}"
fi

dev_fee="${DEV_FEE:-1.0}"

set -- /usr/local/bin/tnn-miner-cpu \
  --broadcast \
  --daemon-address "${pool_url}" \
  --port "${pool_port}" \
  --wallet "${user}" \
  --password "${MINING_PASS:-x}" \
  --worker-name "${WORKER_NAME}" \
  --dev-fee "${dev_fee}" \
  --ignore-wallet \
  ${algo_flag}

if [ -n "${MINING_THREADS:-}" ]; then
  set -- "$@" --threads "${MINING_THREADS}"
fi

if ! echo "${pool_url}" | grep -qi "stratum"; then
  set -- "$@" --stratum
fi

if [ -n "${algo_flag}" ]; then
  set -- "$@" --rx-hugepages
fi

if [ -n "${CPU_AFFINITY_MASK:-}" ]; then
  set -- "$@" --no-lock
  exec taskset "${CPU_AFFINITY_MASK}" "$@"
fi

exec "$@"
