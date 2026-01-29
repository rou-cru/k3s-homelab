FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04

ARG RIGEL_VERSION
ARG RIGEL_SHA256

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN wget -q -O rigel.tar.gz "https://github.com/rigelminer/rigel/releases/download/${RIGEL_VERSION}/rigel-${RIGEL_VERSION}-linux.tar.gz" \
    && echo "${RIGEL_SHA256}  rigel.tar.gz" | sha256sum -c - \
    && tar -xzf rigel.tar.gz \
    && mv "rigel-${RIGEL_VERSION}-linux/rigel" /usr/local/bin/rigel \
    && chmod +x /usr/local/bin/rigel \
    && rm -rf rigel.tar.gz rigel-${RIGEL_VERSION}-linux

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
