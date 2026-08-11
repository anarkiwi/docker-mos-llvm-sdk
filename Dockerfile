# syntax=docker/dockerfile:1

# Pinned upstream release, updated by .github/workflows/upstream-bump.yml.
# The image release version is derived from LLVM_MOS_VERSION.
ARG LLVM_MOS_VERSION=v23.0.1
ARG LLVM_MOS_SHA256=bd76dd5a826b83e438bf55dbdd512d65d4600ba80fda919dca633cad76f023cc

FROM debian:trixie-slim AS fetch
ARG LLVM_MOS_VERSION
ARG LLVM_MOS_SHA256
ARG TARGETARCH
SHELL ["/bin/sh", "-eux", "-c"]
RUN test "${TARGETARCH:-amd64}" = amd64 \
    || { echo "llvm-mos-sdk ships linux binaries for amd64 only"; exit 1; }
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl xz-utils \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/sdk.tar.xz \
      "https://github.com/llvm-mos/llvm-mos-sdk/releases/download/${LLVM_MOS_VERSION}/llvm-mos-linux.tar.xz" \
    && printf '%s  /tmp/sdk.tar.xz\n' "${LLVM_MOS_SHA256}" > /tmp/sdk.sha256 \
    && sha256sum -c /tmp/sdk.sha256 \
    && tar -xJf /tmp/sdk.tar.xz -C /usr/local \
    && rm /tmp/sdk.tar.xz /tmp/sdk.sha256 \
    && test -x /usr/local/llvm-mos/bin/mos-c64-clang

FROM debian:trixie-slim
ARG LLVM_MOS_VERSION
SHELL ["/bin/sh", "-eux", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends libstdc++6 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=fetch /usr/local/llvm-mos /usr/local/llvm-mos
ENV PATH=/usr/local/llvm-mos/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV LLVM_MOS_VERSION=${LLVM_MOS_VERSION}
WORKDIR /work
CMD ["mos-clang", "--version"]

LABEL org.opencontainers.image.title="llvm-mos SDK" \
      org.opencontainers.image.description="llvm-mos SDK 6502 cross compiler toolchain" \
      org.opencontainers.image.version="${LLVM_MOS_VERSION}" \
      org.opencontainers.image.source="https://github.com/anarkiwi/docker-mos-llvm-sdk" \
      org.opencontainers.image.url="https://github.com/llvm-mos/llvm-mos-sdk" \
      org.opencontainers.image.licenses="Apache-2.0 WITH LLVM-exception"
