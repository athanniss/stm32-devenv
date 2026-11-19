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
#   gcc, g++           native compilers, for unit tests that run on the PC
#   python3-pip        installs a project's Python packages (see the
#                      postCreateCommand in the label below)
#   python-is-python3  makes "python" run python3, as scripts and tasks expect
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      tzdata \
      git \
      cmake \
      ninja-build \
      gcc \
      g++ \
      python3 \
      python3-pip \
      python-is-python3 \
      clang-tidy \
      clang-format \
      clangd \
      cppcheck \
 && rm -rf /var/lib/apt/lists/*

# Smoke test: fail the build right away if the compiler or debugger can't start
# (for example because a shared library is missing).
RUN arm-none-eabi-gcc --version && arm-none-eabi-gdb --version

# Make CMake write compile_commands.json for every project (clangd, clang-tidy
# and cppcheck read it). Works from VS Code and from the command line.
ENV CMAKE_EXPORT_COMPILE_COMMANDS=ON

# -----------------------------------------------------------------------------
# VS Code Dev Containers configuration
# -----------------------------------------------------------------------------
# Dev Containers reads this label and merges it with the project's
# devcontainer.json (the project's file wins on conflicts).
# The value must be valid JSON, so comments go here, not inside it.
# remoteUser: VS Code and its terminals run as the normal "ubuntu" user
#   (uid 1000, part of the Ubuntu base image) instead of root. On Linux hosts,
#   Dev Containers changes its uid to match yours, so files created in the
#   project (build/, ...) belong to you, not root.
# postCreateCommand: runs once, when a container is created for a project.
#   git-safe-directory   the project folder is mounted from the host and owned
#                        by another user id, which git refuses ("dubious
#                        ownership") unless the folder is marked as safe
#   python-requirements  if the project has .devcontainer/requirements.txt,
#                        install those Python packages for the ubuntu user
# Extensions installed inside the container on first start:
#   clangd        code navigation, completion, live clang-tidy warnings
#   CMake Tools   configure and build with CubeMX's CMakePresets.json
#   Cortex-Debug  debugging over GDB, peripheral registers from the SVD
# Settings:
#   clangd.path       use the clangd installed in this image (no download prompt)
#   --query-driver    allow clangd to ask arm-none-eabi-gcc for its built-in
#                     include paths and target, so <stdint.h> etc. are found
#   --completion-style=detailed  one completion entry per overload, with full
#                     signature
#   --pch-storage=memory  keep clangd's precompiled headers in RAM (faster)
#   C_Cpp.intelliSenseEngine  disable Microsoft C/C++ IntelliSense, in case
#                     another extension installs it; it conflicts with clangd
#   cmake.configureOnOpen     configure the project when it is opened, so
#                             compile_commands.json exists right away
#   cmake.copyCompileCommands copy compile_commands.json from the active
#                             build folder (e.g. build/Debug) to the project
#                             root, where clangd looks for it
# Kept last: changing it only rebuilds this step.
LABEL devcontainer.metadata='[{ \
  "remoteUser": "ubuntu", \
  "postCreateCommand": { \
    "git-safe-directory": "git config --global --add safe.directory ${containerWorkspaceFolder}", \
    "python-requirements": "if [ -f .devcontainer/requirements.txt ]; then pip install --user --break-system-packages -r .devcontainer/requirements.txt; fi" \
  }, \
  "customizations": { \
    "vscode": { \
      "extensions": [ \
        "llvm-vs-code-extensions.vscode-clangd", \
        "ms-vscode.cmake-tools", \
        "marus25.cortex-debug" \
      ], \
      "settings": { \
        "clangd.path": "/usr/bin/clangd", \
        "clangd.arguments": [ \
          "--query-driver=/opt/arm-gnu-toolchain/bin/arm-none-eabi-*", \
          "--completion-style=detailed", \
          "--pch-storage=memory" \
        ], \
        "C_Cpp.intelliSenseEngine": "disabled", \
        "cmake.configureOnOpen": true, \
        "cmake.copyCompileCommands": "${workspaceFolder}/compile_commands.json" \
      } \
    } \
  } \
}]'
