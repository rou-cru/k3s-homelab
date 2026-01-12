FROM ubuntu:24.04 AS builder

ARG TNN_REF=dev
ARG LLVM_VER=20

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common \
      git \
      wget \
      build-essential \
      libssl-dev \
      libudns-dev \
      libc++-dev \
      libsodium-dev \
      libnuma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install CMake from Kitware (gets latest version)
RUN curl -fsSL https://apt.kitware.com/kitware-archive.sh | bash \
    && apt-get update \
    && apt-get install -y --no-install-recommends cmake \
    && rm -rf /var/lib/apt/lists/*

# Install LLVM/Clang 20
RUN curl -fsSL https://apt.llvm.org/llvm.sh -o /tmp/llvm.sh \
    && chmod +x /tmp/llvm.sh \
    && /tmp/llvm.sh ${LLVM_VER} \
    && rm -f /tmp/llvm.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      clang-${LLVM_VER} \
      lld-${LLVM_VER} \
      llvm-${LLVM_VER} \
      llvm-${LLVM_VER}-tools \
    && rm -rf /var/lib/apt/lists/*

# Set Clang 20 as default
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-${LLVM_VER} 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-${LLVM_VER} 100 \
    && update-alternatives --install /usr/bin/ld.lld ld.lld /usr/bin/ld.lld-${LLVM_VER} 100

# Clone tnn-miner
RUN git clone --depth 1 --branch ${TNN_REF} https://github.com/Tritonn204/tnn-miner.git /src

WORKDIR /src

# Disable Dev Fee by preventing the dev worker thread from starting
RUN sed -i 's|boost::thread DEVWORK(getWork_v2, &devMiningProfile);|// boost::thread DEVWORK(getWork_v2, &devMiningProfile);|' src/core/miner.cpp \
    && sed -i 's|DEVWORK.interrupt();|// DEVWORK.interrupt();|' src/core/miner.cpp \
    && sed -i 's|devMiningProfile.setDev(vm.count("testnet"));|// devMiningProfile.setDev(vm.count("testnet"));|' src/core/miner.cpp

# Build with optimizations for native CPU
# CPM will download Boost automatically if not found
RUN mkdir -p build \
    && cd build \
    && cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_C_FLAGS="-march=native -mtune=native" \
      -DCMAKE_CXX_FLAGS="-march=native -mtune=native" \
      -DUSE_GCC=OFF \
      -DWITH_HIP=OFF \
    && make -j "$(nproc)"

FROM ubuntu:24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      ca-certificates \
      libstdc++6 \
      libgcc-s1 \
      libssl3t64 \
      libsodium23 \
      libudns0 \
      util-linux \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /src/build/bin/tnn-miner-cpu /usr/local/bin/tnn-miner-cpu
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/tnn-miner-cpu

WORKDIR /var/lib/tnn-miner

ENTRYPOINT ["/entrypoint.sh"]
