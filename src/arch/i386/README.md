# src/arch/i386 — x86 (32-bit) specific code (Phase 2–3)

Everything that depends on the Intel CPU lives here, so the rest of the kernel stays portable.

**Will contain:**
- `gdt.c` / `gdt_flush.asm` — Global Descriptor Table (segments, privilege levels)
- `idt.c` / `isr.asm` — Interrupt Descriptor Table + interrupt stubs
- `paging.c` — page directory / page tables, CR3 (Phase 3)
- `tss.c` — Task State Segment for user mode (Phase 5)
- `switch.asm` — context switch (Phase 4)

**Book:** Ch 1.2 (interrupts), Ch 9.6 (Intel 32/64-bit architecture)
**Ref:** Intel SDM Vol 3, OSDev "GDT", "IDT"
