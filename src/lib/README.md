# src/lib — Kernel library (Phase 1+)

The kernel cannot use the normal C library (glibc needs an OS underneath it), so we write our own minimal versions.

**Will contain:**
- `string.c` — `memset`, `memcpy`, `strlen`, `strcmp`, …
- `kprintf.c` — formatted printing to VGA + serial
