# stm32-devenv

A Docker-based development environment for STM32 microcontrollers. It packages
everything needed to build, analyse and debug STM32 firmware, so every
machine uses the same tool versions:

- GNU Arm toolchain (`arm-none-eabi-gcc`, `arm-none-eabi-gdb`)
- CMake and Ninja
- clang-tidy, clang-format, cppcheck (linting and static analysis)

The container builds and debugs your firmware. The ST-Link USB probe stays on
the host: a GDB server runs on Windows, and GDB in the container connects to it
over the network.

## Setup (once per machine)

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
   It enables WSL2 for you; reboot if asked. If it reports that virtualization
   is disabled, enable it in the BIOS/UEFI.
2. Install [VS Code](https://code.visualstudio.com/) and the
   [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   extension.
3. Install [Git for Windows](https://git-scm.com/download/win).

Debug probe setup (ST-Link driver, GDB server) is described in
[Debugging with an ST-Link](#debugging-with-an-st-link).

> Docker Desktop is free for personal use, education and small businesses.
> Larger organisations need a paid subscription.

## Building the image

From the repository root:

```bash
docker build -t stm32-devenv image/
```

`-t stm32-devenv` gives the image a name (a *tag*) so you can refer to it later.
`image/` is the *build context*: the folder Docker builds from. It contains
the `Dockerfile`.

## Using the image in a project

_To be written._

## Debugging with an ST-Link

_To be written._
