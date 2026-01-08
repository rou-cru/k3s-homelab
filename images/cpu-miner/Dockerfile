FROM alpine:3.19 AS builder

ARG XMRIG_VERSION=6.25.0
ARG BUILD_TYPE=generic

RUN apk add --no-cache \
    git \
    make \
    cmake \
    libstdc++ \
    gcc \
    g++ \
    automake \
    libtool \
    autoconf \
    linux-headers \
    libuv-dev \
    openssl-dev \
    hwloc-dev

WORKDIR /build
# Clone specific tag
RUN git clone --depth 1 --branch v${XMRIG_VERSION} https://github.com/xmrig/xmrig.git .

# Modificar el nivel de donación a 0% en el código fuente
RUN sed -i 's/kDefaultDonateLevel = 1/kDefaultDonateLevel = 0/' src/donate.h \
    && sed -i 's/kMinimumDonateLevel = 1/kMinimumDonateLevel = 0/' src/donate.h

RUN mkdir build && cd build \
    && if [ "$BUILD_TYPE" = "native" ]; then \
         export CFLAGS="-march=native -O3"; \
         export CXXFLAGS="-march=native -O3"; \
         echo "Building with native optimizations ($CFLAGS)"; \
       else \
         export CFLAGS="-O3"; \
         export CXXFLAGS="-O3"; \
         echo "Building generic portable version"; \
       fi \
    && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_HTTP=ON \
    -DWITH_OPENCL=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_NVML=OFF \
    -DWITH_HWLOC=ON \
    -DXMRIG_DEPS=OFF \
    -DCMAKE_C_FLAGS="$CFLAGS" \
    -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
    && make -j$(nproc)

FROM alpine:3.19

# Runtime dependencies
RUN apk add --no-cache \
    libuv \
    libssl3 \
    hwloc \
    libstdc++

COPY --from=builder /build/build/xmrig /usr/local/bin/xmrig
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
