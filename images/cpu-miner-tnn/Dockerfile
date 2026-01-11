FROM ubuntu:24.04 AS builder

ARG TNN_REF=dev
ARG CMAKE_VERSION=3.30.5

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      build-essential \
      clang \
      lld \
      libc++-dev \
      libssl-dev \
      libudns-dev \
      libsodium-dev \
      libboost1.83-all-dev \
      tar \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/cmake.tar.gz \
      "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" \
    && mkdir -p /opt/cmake \
    && tar -xzf /tmp/cmake.tar.gz -C /opt/cmake --strip-components=1 \
    && rm -f /tmp/cmake.tar.gz

ENV PATH=/opt/cmake/bin:$PATH

RUN git clone --depth 1 --branch ${TNN_REF} https://github.com/Tritonn204/tnn-miner.git /src

WORKDIR /src

RUN mkdir -p build \
    && cd build \
    && cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DUSE_GCC=OFF \
      -DWITH_HIP=OFF \
      -DBUILD_STATIC=ON \
    && cmake --build . -j "$(nproc)"

FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      libstdc++6 \
      libgcc-s1 \
      libssl3 \
      libsodium23 \
      libudns0 \
      util-linux \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/build/tnn-miner-cpu /usr/local/bin/tnn-miner-cpu
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/tnn-miner-cpu

WORKDIR /var/lib/tnn-miner

ENTRYPOINT ["/entrypoint.sh"]
