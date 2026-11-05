# src/drivers — Device drivers (Phase 1–2)

**Will contain:**
- `vga.c` — text-mode screen (`0xB8000`)
- `serial.c` — COM1 serial port, used for debug logging
- `pic.c` — 8259 Programmable Interrupt Controller
- `pit.c` — Programmable Interval Timer (scheduler tick)
- `keyboard.c` — PS/2 keyboard
- `ports.h` — `inb` / `outb` I/O port helpers

**Book:** Ch 12.1–12.4 (I/O Systems: hardware, interrupts, driver interface)
