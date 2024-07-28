FROM docker.io/library/debian:12-slim as source
ARG NODE_VERSION
RUN apt-get update && apt-get -y install \
    build-essential \
    clang \
    curl \
    ninja-build \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.xz" && \
    tar xf /tmp/node.tar.xz --strip-components=1 && \
    rm /tmp/node.tar.xz

FROM source as build
RUN CC=clang CXX=clang++ ./configure --ninja --debug --enable-asan && \
    make install DESTDIR=/out && \
    mv /out/usr/local/bin/node /out/usr/local/bin/node.release && \
    install out/Debug/node /out/usr/local/bin

FROM docker.io/library/debian:12-slim
RUN apt-get update && apt-get -y --no-install-recommends install libatomic1 llvm-14 && rm -rf /var/lib/apt/lists/*
COPY --from=source /build /build
COPY --from=build /out /
