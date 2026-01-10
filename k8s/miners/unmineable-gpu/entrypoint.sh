#!/bin/bash
set -eu

: "${WALLET_ADDRESS:?WALLET_ADDRESS is required}"
: "${MINING_WORKER_NAME:?MINING_WORKER_NAME is required}"
: "${MINING_POOL:?MINING_POOL is required}"
: "${MINING_PORT:?MINING_PORT is required}"
: "${MINING_COIN:?MINING_COIN is required}"
: "${REFERRAL_CODE:?REFERRAL_CODE is required}"
: "${MINING_PASS:=x}"

LOLMINER_VERSION="1.98a"
LOLMINER_URL="https://github.com/Lolliedieb/lolMiner-releases/releases/download/${LOLMINER_VERSION}/lolMiner_v${LOLMINER_VERSION}_Lin64.tar.gz"
MINER_DIR="/tmp/lolminer"

# Unmineable format: COIN:WALLET.WORKER#REFERRAL
UNMINEABLE_USER="${MINING_COIN}:${WALLET_ADDRESS}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"

echo "Downloading LolMiner v${LOLMINER_VERSION}..."
apt-get update -qq && apt-get install -y -qq wget tar >/dev/null 2>&1

mkdir -p "${MINER_DIR}"
wget -q -O /tmp/miner.tar.gz "${LOLMINER_URL}"
tar -xzf /tmp/miner.tar.gz -C "${MINER_DIR}"

# Find binary
MINER_BIN=$(find "${MINER_DIR}" -name "lolMiner" -type f | head -n 1)

if [ -z "$MINER_BIN" ]; then
  echo "Error: lolMiner binary not found"
  ls -R "${MINER_DIR}"
  exit 1
fi

chmod +x "${MINER_BIN}"
rm /tmp/miner.tar.gz

echo "Starting LolMiner (${MINING_ALGO}) for Unmineable..."
echo "Pool: ${MINING_POOL}:${MINING_PORT}"
# Redact wallet address from logs for security
echo "User: ${MINING_COIN}:...${WALLET_ADDRESS: -4}.${MINING_WORKER_NAME}#${REFERRAL_CODE}"
echo "Worker: ${MINING_WORKER_NAME}"

exec "${MINER_BIN}" \
  --algo "${MINING_ALGO}" \
  --pool "${MINING_POOL}:${MINING_PORT}" \
  --user "${UNMINEABLE_USER}" \
  --pass "${MINING_PASS}" \
  --apiport 4067 \
  --nocolor