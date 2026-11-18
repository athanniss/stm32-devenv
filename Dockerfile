# Base image: the Linux userland (C library, shell, apt) the tools run on.
# Pinned to a release tag so everyone starts from the same Ubuntu version.
FROM ubuntu:26.04

# Tell apt it cannot ask questions (there is no one to answer them during a
# build). ARG only applies while building; it is not set in the final container.
ARG DEBIAN_FRONTEND=noninteractive

# -----------------------------------------------------------------------------
# Arm GNU toolchain
# -----------------------------------------------------------------------------
# Version and its published SHA-256 checksum. To upgrade, change both.
# Versions and checksums: https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads
ARG ARM_TOOLCHAIN_VERSION=15.2.rel1
ARG ARM_TOOLCHAIN_SHA256=597893282ac8c6ab1a4073977f2362990184599643b4c5ee34870a8215783a16

# Download, verify, extract and install the Arm toolchain.
# Delete the archive and the download tools before continuing.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      xz-utils \
 && curl -fsSL -o /tmp/toolchain.tar.xz \
      "https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_TOOLCHAIN_VERSION}/binrel/arm-gnu-toolchain-${ARM_TOOLCHAIN_VERSION}-x86_64-arm-none-eabi.tar.xz" \
 && echo "${ARM_TOOLCHAIN_SHA256}  /tmp/toolchain.tar.xz" | sha256sum -c - \
 && mkdir -p /opt/arm-gnu-toolchain \
 && tar -xJf /tmp/toolchain.tar.xz -C /opt/arm-gnu-toolchain --strip-components=1 \
 && rm /tmp/toolchain.tar.xz \
 && apt-get purge -y --auto-remove curl xz-utils \
 && rm -rf /var/lib/apt/lists/*

# Put the toolchain's programs on the PATH.
ENV PATH="/opt/arm-gnu-toolchain/bin:${PATH}"

# -----------------------------------------------------------------------------
# Tools from Ubuntu's package repository
# -----------------------------------------------------------------------------
# update + install + cleanup are in one RUN so they end up in one layer, and
# the downloaded package lists never get stored in the image.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      tzdata \
      git \
      cmake \
      ninja-build \
      python3 \
      clang-tidy \
      clang-format \
      clangd \
      cppcheck \
 && rm -rf /var/lib/apt/lists/*

# Smoke test: fail the build right away if the compiler or debugger can't start
# (for example because a shared library is missing).
RUN arm-none-eabi-gcc --version \
 && arm-none-eabi-gdb --version
