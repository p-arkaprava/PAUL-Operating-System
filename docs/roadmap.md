# Paul OS — 60-Day Roadmap (v0.1 prototype)

Every phase ends with something **visible in QEMU**. Tick the boxes as you go, and tag each finished phase in git (`git tag phase-1`).

Book = *Operating System Concepts*, 10th ed.

---

## Phase 0 — Environment (Days 1–3)
**Goal:** toolchain installed and verified.



- [ ] WSL2 + Ubuntu 24.04 installed
- [ ] `scripts/install-deps.sh` run
- [ ] Cross-compiler built (`i686-elf-gcc --version` works)
- [ ] QEMU opens a SeaBIOS window
- [ ] VS Code opens the repo in WSL mode
- [ ] `scripts/check-env.sh` shows all ✅

**Read:** Book Ch 1.1–1.4 (what an OS does, interrupts, dual-mode operation)

---

## Phase 1 — Boot & Hello World (Days 4–7)
**Goal:** GRUB loads Paul OS, which prints "Hello, Paul OS" on screen and to the serial port.

- [ ] Multiboot header + `_start` entry in assembly (`src/boot/`)
- [ ] Linker script (load the kernel at 1 MiB)
- [ ] `kernel_main()` in C
- [ ] VGA text-mode driver (write to `0xB8000`, colors, scrolling)
- [ ] Serial (COM1) driver, used for logging to the terminal
- [ ] `kprintf()` with `%d %x %s %c`
- [ ] `Makefile` with `make`, `make run`, `make debug`
- [ ] Boot from ISO with `grub-mkrescue`
- [ ] Attach GDB to QEMU and step through `kernel_main`

**Read:** Ch 2.5 (linkers & loaders), 2.9 (building & booting), 2.10 (debugging)
**Ref:** OSDev "Bare Bones", "Multiboot", "Printing to Screen", "Serial Ports"

---

## Phase 2 — CPU Tables & Interrupts (Days 8–17)
**Goal:** the kernel handles exceptions, timer ticks and keystrokes.

- [ ] GDT (flat segments: kernel code/data, later user code/data + TSS)
- [ ] IDT with 256 entries
- [ ] ISR stubs in assembly for exceptions 0–31 (print a message, then panic)
- [ ] Remap the 8259 PIC (IRQs → vectors 32–47)
- [ ] PIT timer at 100 Hz with a tick counter
- [ ] PS/2 keyboard driver (scancode → ASCII, typed text echoes on screen)
- [ ] `kernel_panic()` that dumps registers
- [ ] Test: divide by zero triggers the handler

**Read:** Ch 1.2.1 (interrupts), 1.4 (dual-mode, timer), 12.1–12.4 (I/O hardware, interrupts, drivers)
**Ref:** OSDev "GDT Tutorial", "Interrupt Descriptor Table", "8259 PIC", "PIT", "PS/2 Keyboard"; Intel SDM Vol 3 ch. 3 & 6

---

## Phase 3 — Memory Management (Days 18–30)
**Goal:** the kernel knows what RAM exists, runs with paging enabled, and has `kmalloc`/`kfree`.

- [ ] Parse the Multiboot memory map
- [ ] Physical memory manager (bitmap of 4 KiB frames): `pmm_alloc()` / `pmm_free()`
- [ ] Page directory + page tables, identity-map the kernel, enable paging (CR0, CR3)
- [ ] Page-fault handler that prints the faulting address (CR2)
- [ ] Map / unmap pages: `vmm_map(virt, phys, flags)`
- [ ] Kernel heap: `kmalloc()` / `kfree()` (start with a simple linked-list allocator)
- [ ] *(Stretch)* move the kernel to the higher half (`0xC0000000`)

**Read:** Ch 9.1–9.4 (paging, page tables), 9.6 (Intel 32/64-bit paging), 10.1 (virtual memory), 10.8 (allocating kernel memory)
**Ref:** OSDev "Page Frame Allocation", "Paging", "Setting Up Paging"

---

## Phase 4 — Processes & Scheduling (Days 31–42)
**Goal:** several kernel tasks take turns running, switched by the timer.

- [ ] Process control block (`struct process`: pid, state, registers, stack, page directory)
- [ ] Context switch in assembly (save/restore registers + stack pointer)
- [ ] Create kernel threads (`proc_create(func)`)
- [ ] Round-robin scheduler driven by the timer IRQ
- [ ] Process states: READY / RUNNING / BLOCKED / ZOMBIE
- [ ] `sleep()` and `yield()`
- [ ] Spinlock/lock by disabling interrupts; a simple mutex
- [ ] Test: tasks A, B and C print interleaved output

**Read:** Ch 3.1–3.3 (process concept, scheduling, operations), 5.1–5.3 (CPU scheduling, round robin), 6.1–6.6 (critical sections, locks, semaphores)
**Ref:** OSDev "Kernel Multitasking", "Context Switching"; xv6 book ch. 7

---

## Phase 5 — User Mode & System Calls (Days 43–52)
**Goal:** programs run in ring 3 and can only reach the kernel through system calls.

- [ ] TSS set up (kernel stack used on ring 3 → ring 0 transitions)
- [ ] Jump to user mode (`iret` trick)
- [ ] Separate address space per process
- [ ] System-call gate on `int 0x80`
- [ ] Syscalls: `write`, `exit`, `getpid`, `yield`, `sleep`
- [ ] Minimal ELF loader
- [ ] Tiny user-space library (`user/lib`) wrapping the syscalls
- [ ] Test: a user program that touches kernel memory gets killed

**Read:** Ch 2.1–2.3 (OS services, system calls), 2.5 (loaders), 1.4.1 (dual-mode)
**Ref:** OSDev "Getting to Ring 3", "System Calls", "ELF"; xv6 book ch. 4

---

## Phase 6 — Filesystem & Shell (Days 53–60) → **v0.1** 🎉
**Goal:** boot into a shell, list files, and run programs.

- [ ] Load an initrd (ramdisk) as a GRUB module
- [ ] Simple in-memory filesystem (tar-format initrd or a custom flat format)
- [ ] File syscalls: `open`, `read`, `close`, `readdir`
- [ ] `exec` (load an ELF from the filesystem)
- [ ] Shell: `help`, `ls`, `cat`, `echo`, `clear`, `ps`, run programs
- [ ] Clean up, document, `git tag v0.1`

**Read:** Ch 13.1–13.3 (file concept, access methods, directories), 14.1–14.4 (FS structure, operations, allocation)
**Ref:** OSDev "Initrd", "USTAR"; xv6 book ch. 8

---

## After v0.1 — ideas for v0.2+
- Real disk driver (ATA/PIO) + FAT12/16 or ext2 (Ch 11, 14, 15)
- `fork()` with copy-on-write (Ch 3.3, 10.3)
- Demand paging + page replacement (Ch 10.2–10.4)
- Better scheduler: priorities, MLFQ (Ch 5.3)
- Pipes / IPC (Ch 3.4–3.7)
- Multicore SMP (Ch 5.5, 6.4)
- Port to x86_64 or RISC-V
