FROM nvidia/cuda:12.2.0-base-ubuntu22.04

ARG LOLMINER_VERSION=1.98a
ARG LOLMINER_SHA256

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download and Verify Checksum (Security Hardening)
RUN wget -q -O miner.tar.gz "https://github.com/Lolliedieb/lolMiner-releases/releases/download/${LOLMINER_VERSION}/lolMiner_v${LOLMINER_VERSION}_Lin64.tar.gz" \
    && echo "${LOLMINER_SHA256}  miner.tar.gz" | sha256sum -c - \
    && tar -xzf miner.tar.gz \
    && mv "${LOLMINER_VERSION}/lolMiner" /usr/local/bin/lolMiner \
    && rm -rf "${LOLMINER_VERSION}" miner.tar.gz

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]