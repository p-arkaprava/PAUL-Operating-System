#!/usr/bin/env bash
# Paul OS — verify the development environment is ready
export PATH="$HOME/opt/cross/bin:$PATH"

fail=0
check() {
  local name="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf "  ✅ %-22s %s\n" "$name" "$("$cmd" --version 2>&1 | head -1)"
  else
    printf "  ❌ %-22s not found\n" "$name"
    fail=1
  fi
}

echo "Paul OS environment check"
echo "-------------------------"
check "Cross C compiler"   i686-elf-gcc
check "Cross linker"       i686-elf-ld
check "Assembler"          nasm
check "Make"               make
check "Emulator"           qemu-system-i386
check "Debugger"           gdb
check "ISO builder"        grub-mkrescue
check "xorriso"            xorriso
check "Git"                git

if command -v grub-file >/dev/null 2>&1; then
  printf "  ✅ %-22s present\n" "grub-file"
else
  printf "  ❌ %-22s not found (install grub-common)\n" "grub-file"; fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "All good — ready to build Paul OS 🚀"
else
  echo "Some tools are missing. See docs/troubleshooting.md"
  exit 1
fi
