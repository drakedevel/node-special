ARG LLVM_VERSION=18

FROM docker.io/library/debian:12-slim as source
ARG LLVM_VERSION
ARG NODE_VERSION
RUN apt-get update && apt-get -y --no-install-recommends install ca-certificates curl && \
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key -o /etc/apt/keyrings/apt.llvm.org.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/apt.llvm.org.asc] http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-${LLVM_VERSION} main" >> /etc/apt/sources.list && \
    apt-get update && apt-get -y --no-install-recommends install \
    "clang-${LLVM_VERSION}" \
    make \
    ninja-build \
    python3 \
    python3-pip \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/download/release/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.xz" && \
    tar xf /tmp/node.tar.xz --strip-components=1 && \
    rm /tmp/node.tar.xz

FROM source as build
ARG CONFIG_FLAGS
ARG LLVM_VERSION
RUN CC=clang-${LLVM_VERSION} CXX=clang++-${LLVM_VERSION} \
    CFLAGS=-ffile-prefix-map=../..="$(pwd)" CXXFLAGS=-ffile-prefix-map=../..="$(pwd)" \
    ./configure --ninja $CONFIG_FLAGS && \
    make install DESTDIR=/out && \
    bindir=/out/usr/local/bin && \
    mkdir "${bindir}/.debug" && \
    objcopy --compress-debug-sections --only-keep-debug "${bindir}/node" "${bindir}/.debug/node.debug" && \
    objcopy --strip-unneeded --add-gnu-debuglink="${bindir}/.debug/node.debug" "${bindir}/node" && \
    if [ -f out/Debug/node ]; then \
    install out/Debug/node /out/usr/local/bin/node-debug && \
    objcopy --compress-debug-sections --only-keep-debug "${bindir}/node-debug" "${bindir}/.debug/node-debug.debug" && \
    objcopy --strip-unneeded --add-gnu-debuglink="${bindir}/.debug/node-debug.debug" "${bindir}/node-debug"; \
    fi

FROM docker.io/library/debian:12-slim as base
ARG CONFIG_FLAGS
ARG LLVM_VERSION
RUN apt-get update && apt-get -y --no-install-recommends install libatomic1 && \
    if echo "$CONFIG_FLAGS" | grep -E -q 'enable-(a|ub)san'; then \
    apt-get -y --no-install-recommends install ca-certificates curl && \
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key -o /etc/apt/keyrings/apt.llvm.org.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/apt.llvm.org.asc] http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-${LLVM_VERSION} main" >> /etc/apt/sources.list && \
    apt-get update && apt-get -y --no-install-recommends install llvm-${LLVM_VERSION} && \
    apt-get -y --purge remove ca-certificates curl && \
    rm /etc/apt/keyrings/apt.llvm.org.asc /etc/apt/sources.list; \
    fi && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build /out /

FROM base as withsrc
COPY --from=source /build /build
