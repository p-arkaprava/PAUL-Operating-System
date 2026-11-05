# src/boot — Boot code (Phase 1)

Where the CPU enters Paul OS after GRUB hands over control.

**Will contain:**
- `boot.asm` — Multiboot header, sets up a stack, calls `kernel_main`
- `linker.ld` — memory layout of the kernel (loaded at 1 MiB)
- `grub.cfg` — GRUB menu entry

**Book:** Ch 2.5 (Linkers and Loaders), Ch 2.9 (Building and Booting an OS)
**Ref:** OSDev "Bare Bones", "Multiboot"
