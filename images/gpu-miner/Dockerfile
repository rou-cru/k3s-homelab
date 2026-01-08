FROM nvidia/cuda:12.2.0-base-ubuntu22.04

ARG LOLMINER_VERSION=1.84

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN wget https://github.com/Lolliedieb/lolMiner-releases/releases/download/${LOLMINER_VERSION}/lolMiner_v${LOLMINER_VERSION}_Lin64.tar.gz -O - | tar -xz \
    && mv lolMiner_v${LOLMINER_VERSION}_Lin64/lolMiner /usr/local/bin/lolMiner \
    && rm -rf lolMiner_v${LOLMINER_VERSION}_Lin64

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

