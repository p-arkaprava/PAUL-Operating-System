#!/usr/bin/env bash
# Paul OS — build the i686-elf cross-compiler (binutils + gcc)
# Takes ~20-40 minutes. Safe to re-run: skips steps that are already done.
set -euo pipefail

BINUTILS_VERSION="2.42"
GCC_VERSION="13.2.0"

export PREFIX="$HOME/opt/cross"
export TARGET="i686-elf"
export PATH="$PREFIX/bin:$PATH"
SRC="$HOME/src"
JOBS="$(nproc)"

mkdir -p "$SRC"
cd "$SRC"

# ---------- Download ----------
if [ ! -d "binutils-$BINUTILS_VERSION" ]; then
  echo "==> Downloading binutils $BINUTILS_VERSION..."
  wget -nc "https://ftp.gnu.org/gnu/binutils/binutils-$BINUTILS_VERSION.tar.xz"
  tar xf "binutils-$BINUTILS_VERSION.tar.xz"
fi

if [ ! -d "gcc-$GCC_VERSION" ]; then
  echo "==> Downloading gcc $GCC_VERSION..."
  wget -nc "https://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.xz"
  tar xf "gcc-$GCC_VERSION.tar.xz"
fi

# ---------- binutils ----------
if ! command -v "$TARGET-ld" >/dev/null 2>&1; then
  echo "==> Building binutils..."
  mkdir -p build-binutils && cd build-binutils
  "../binutils-$BINUTILS_VERSION/configure" --target="$TARGET" --prefix="$PREFIX" \
    --with-sysroot --disable-nls --disable-werror
  make -j"$JOBS"
  make install
  cd "$SRC"
else
  echo "==> binutils already installed, skipping."
fi

# ---------- gcc ----------
if ! command -v "$TARGET-gcc" >/dev/null 2>&1; then
  echo "==> Building gcc (this is the long part)..."
  mkdir -p build-gcc && cd build-gcc
  "../gcc-$GCC_VERSION/configure" --target="$TARGET" --prefix="$PREFIX" \
    --disable-nls --enable-languages=c --without-headers
  make -j"$JOBS" all-gcc
  make -j"$JOBS" all-target-libgcc
  make install-gcc
  make install-target-libgcc
  cd "$SRC"
else
  echo "==> gcc already installed, skipping."
fi

# ---------- PATH ----------
LINE='export PATH="$HOME/opt/cross/bin:$PATH"'
if ! grep -qF "$LINE" "$HOME/.bashrc"; then
  echo "$LINE" >> "$HOME/.bashrc"
  echo "==> Added cross-compiler to PATH in ~/.bashrc"
fi

echo
"$TARGET-gcc" --version | head -1
echo "==> Done! Run: source ~/.bashrc   (or open a new terminal)"
echo "    Optional: rm -rf ~/src   to free ~2 GB"
