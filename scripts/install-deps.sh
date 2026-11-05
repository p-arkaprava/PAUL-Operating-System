#!/usr/bin/env bash
# Paul OS — install all apt packages needed for development (Ubuntu / WSL2)
set -euo pipefail

echo "==> Updating package lists..."
sudo apt update

echo "==> Installing build tools, emulator, debugger, ISO tools..."
sudo apt install -y \
  build-essential nasm qemu-system-x86 gdb git wget \
  grub-pc-bin grub-common xorriso mtools

echo "==> Installing cross-compiler build dependencies..."
sudo apt install -y \
  bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo

echo "==> Done. Next: bash scripts/build-cross-compiler.sh"
