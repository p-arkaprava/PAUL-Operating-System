# Paul OS

A small operating system built from scratch, one concept at a time, as a learning project.

The theory comes from *Operating System Concepts* (Silberschatz, Galvin, Gagne, 10th ed.). Every topic I read gets implemented in real code that boots on x86 hardware (emulated with QEMU), because building something is the best way to see why it matters.

> **Status:** Phase 0 ✅ done · Phase 1 🚧 in progress. **Paul OS boots!** GRUB loads the kernel, which prints to the screen.
> **Goal:** first working prototype in 60 days, then keep improving it.
> **Last updated:** 24 Nov 2026 (see the [Changelog](#6-changelog))

---

## Table of Contents

1. [Installation](#1-installation)
   - [1.1 Install WSL2 + Ubuntu](#11-install-wsl2--ubuntu-windows)
   - [1.2 Install build packages](#12-install-build-packages)
   - [1.3 Build the i686-elf cross-compiler](#13-build-the-i686-elf-cross-compiler)
   - [1.4 Test QEMU](#14-test-qemu)
   - [1.5 Set up VS Code](#15-set-up-vs-code)
   - [1.6 Set up Git](#16-set-up-git)
   - [1.7 Verify everything](#17-verify-everything)
2. [Project Structure](#2-project-structure)
3. [Roadmap](#3-roadmap)
4. [Building & Running](#4-building--running)
5. [Resources](#5-resources)
6. [Changelog](#6-changelog)

---

## 1. Installation

**Target platform:** Windows 10/11 with WSL2 (Ubuntu 24.04). All building happens inside Linux.

**Time needed:** about 1–1.5 hours, most of it waiting for the compiler to build.

**Where the code lives:** the working copy is the clone **inside Ubuntu** at `~/PaulOS`, on the Linux filesystem, because builds there are much faster than on `/mnt/c/...`. From Windows you can open it at `\\wsl$\Ubuntu-24.04\home\arkaparkap\PaulOS`.

| Tool | Purpose |
|---|---|
| WSL2 + Ubuntu | Linux environment on Windows |
| `build-essential`, `make`, `git` | Build system and version control |
| `nasm` | Assembler for boot code and interrupt stubs |
| `i686-elf-gcc` / `i686-elf-ld` | **Cross-compiler** that builds code for bare metal (no OS underneath) |
| `qemu-system-i386` | Emulator to run Paul OS safely |
| `gdb` | Step-by-step kernel debugging |
| `grub-mkrescue`, `xorriso`, `mtools` | Package the kernel into a bootable ISO |
| VS Code | Editor (connects into WSL) |

> **Shortcut:** once Ubuntu is installed (step 1.1), the scripts in `scripts/` automate steps 1.2, 1.3 and 1.7:
> ```bash
> cd ~/PaulOS
> bash scripts/install-deps.sh
> bash scripts/build-cross-compiler.sh
> bash scripts/check-env.sh
> ```
> The manual steps below explain what each script does.

### 1.1 Install WSL2 + Ubuntu (Windows)

1. Open **PowerShell as Administrator**.
2. Install Ubuntu:
   ```powershell
   wsl --install -d Ubuntu-24.04
   ```
3. **Restart** the PC. Ubuntu opens after the restart. Create a Linux username and password (you'll need the password for `sudo`).
   - **Nothing shows on screen while you type the password**, not even `*`. That's normal. If the two entries don't match it simply asks again, so don't press Ctrl+C.
   - If you did interrupt it, the distro is left without a user. Since it's still empty, just reinstall: `wsl --unregister Ubuntu-24.04`, then `wsl --install -d Ubuntu-24.04`.
4. Check that it's running as WSL **version 2**:
   ```powershell
   wsl -l -v
   ```
   If VERSION shows `1`, run `wsl --set-version Ubuntu-24.04 2`.

> **Which window?** `wsl ...` commands only work in **PowerShell** (`PS C:\...>`). Everything else in this README runs in the **Ubuntu** terminal (`user@PC:~$`). Typing `wsl` in PowerShell drops you into Ubuntu.

> If you get a "virtualization not enabled" error, enable **Intel VT-x / AMD-V (SVM)** in the BIOS.

### 1.2 Install build packages

From here on, every command runs in the **Ubuntu terminal**.

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y build-essential nasm qemu-system-x86 gdb git wget \
  grub-pc-bin grub-common xorriso mtools \
  bison flex libgmp3-dev libmpc-dev libmpfr-dev libisl-dev texinfo
```

The last line (`bison` … `texinfo`) is only needed to build the cross-compiler.

### 1.3 Build the i686-elf cross-compiler

**Why do we need it?** Ubuntu's `gcc` produces programs that expect Linux underneath them (its C library, its system calls, its program format). A kernel *is* the thing underneath, so it needs a compiler that targets **bare-metal i686** with no OS assumptions.

```bash
# 1. Environment
export PREFIX="$HOME/opt/cross"
export TARGET=i686-elf
export PATH="$PREFIX/bin:$PATH"

# 2. Download sources
mkdir -p ~/src && cd ~/src
wget https://ftp.gnu.org/gnu/binutils/binutils-2.45.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz
tar xf binutils-2.45.tar.xz
tar xf gcc-15.2.0.tar.xz

# 3. Build binutils (assembler + linker)
mkdir -p build-binutils && cd build-binutils
../binutils-2.45/configure --target=$TARGET --prefix="$PREFIX" \
  --with-sysroot --disable-nls --disable-werror
make -j$(nproc) && make install

# 4. Build GCC (C only, no standard library)
cd ~/src && mkdir -p build-gcc && cd build-gcc
../gcc-15.2.0/configure --target=$TARGET --prefix="$PREFIX" \
  --disable-nls --enable-languages=c --without-headers
make -j$(nproc) all-gcc
make -j$(nproc) all-target-libgcc
make install-gcc
make install-target-libgcc

# 5. Make the PATH setting permanent
echo 'export PATH="$HOME/opt/cross/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 6. Verify
i686-elf-gcc --version          # i686-elf-gcc (GCC) 15.2.0
i686-elf-gcc -dumpmachine       # i686-elf
```

✅ **Built and verified on 24 Nov 2026:** binutils 2.45 + GCC 15.2.0, installed in `~/opt/cross`. A test `uint32_t add(a, b)` compiles to 32-bit code that reads its arguments at `[ebp+0x8]` / `[ebp+0xc]`. The i686-elf compiler keeps the `ebp` frame pointer even at `-O2`, which makes GDB backtraces easy.

Once this works, `rm -rf ~/src` frees about 2 GB.

### 1.4 Test QEMU

```bash
qemu-system-i386
```

A window should open showing **SeaBIOS → "No bootable device"**. That's the expected result: the emulator works and just has no OS yet. Close the window.


- No window? Run `wsl --update` in PowerShell, then restart Ubuntu.
- Fallback: `qemu-system-i386 -display curses` (quit with `Esc`, `2`, then type `quit`).

### 1.5 Set up VS Code

1. Install [VS Code](https://code.visualstudio.com/) on Windows.
2. Open the project **through WSL** so VS Code uses the Linux toolchain:
   ```bash
   cd ~/PaulOS
   code .
   ```
   The bottom-left corner should say **WSL: Ubuntu-24.04**, and the bottom-right should say **LF** (not CRLF).
   Set **Settings → Files: Eol → `\n`** so Windows line endings never sneak in.
3. VS Code will suggest the recommended extensions listed in `.vscode/extensions.json`. Accept them:
   - **WSL** (`ms-vscode-remote.remote-wsl`)
   - **C/C++** (`ms-vscode.cpptools`)
   - **x86 and x86_64 Assembly** (`13xforever.language-x86-64-assembly`)
   - **Makefile Tools** (`ms-vscode.makefile-tools`)
4. IntelliSense is already set up to use the cross-compiler in `.vscode/c_cpp_properties.json`.

> **Note on file location:** the active clone is `~/PaulOS` inside Ubuntu. The older copy at `C:\Users\arkap\PaulOS` is not used for building any more. Commit and push from **one** place only (the WSL clone) so the two copies never conflict.

### 1.6 Set up Git

```bash
git config --global user.name "Arkaprava Paul"
git config --global user.email "p.Arkaprava@iitg.ac.in"
git config --global core.autocrlf input   # keep LF line endings (shell scripts break with CRLF)
git config --global credential.helper \
  "/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe"   # reuse Windows GitHub login
```

### 1.7 Verify everything

```bash
bash scripts/check-env.sh
```

Every line should show ✅. Fixes for common problems are in [`docs/troubleshooting.md`](docs/troubleshooting.md).

---

## 2. Project Structure

```
PaulOS/
├── readme.md               ← you are here
├── Makefile                ← build / iso / run / debug / clean      ✅ Week 1
├── boot.asm                ← Multiboot header, stack, _start        ✅ Week 1
├── kernel.c                ← kernel_main + VGA text driver          ✅ Week 1
├── linker.ld               ← loads the kernel at 1 MiB              ✅ Week 1
├── grub.cfg                ← GRUB menu entry                        ✅ Week 1
├── .gitignore / .gitattributes
├── .vscode/                ← editor config (IntelliSense → cross-compiler)
├── scripts/                ← setup & helper scripts
│   ├── install-deps.sh         apt packages
│   ├── build-cross-compiler.sh builds i686-elf-gcc
│   └── check-env.sh            verifies the toolchain
├── docs/
│   ├── roadmap.md          ← 60-day plan, phase checklists, book chapters
│   ├── troubleshooting.md
│   └── journal/            ← daily learning notes
├── src/                    ← the kernel (one codebase that grows phase by phase)
│   ├── boot/               multiboot header, entry point, linker script   (Phase 1)
│   ├── kernel/             kernel_main, panic, core logic                 (Phase 1+)
│   ├── arch/i386/          GDT, IDT, ISRs, paging: x86-specific code      (Phase 2–3)
│   ├── drivers/            VGA, serial, PIC, PIT timer, keyboard          (Phase 1–2)
│   ├── mm/                 physical allocator, virtual memory, heap       (Phase 3)
│   ├── proc/               processes, scheduler, context switch           (Phase 4)
│   ├── fs/                 in-memory filesystem                           (Phase 6)
│   ├── lib/                kernel libc: string, kprintf                   (Phase 1+)
│   └── include/            shared headers
├── user/                   ← user-space programs and the shell            (Phase 5–6)
└── build/                  ← build output (ignored by git)
```

Each folder under `src/` has its own README describing what goes there and which textbook chapter it relates to.

> **Current state:** the Week 1 kernel files sit at the repo root to keep the first build simple. In Week 2 they move into the `src/` tree (`boot.asm` + `linker.ld` → `src/boot/`, `kernel.c` → `src/kernel/`, the VGA code → `src/drivers/`) and the Makefile is updated to match.

---

## 3. Roadmap

| Phase | Days | Milestone | Book chapters |
|---|---|---|---|
| 0 ✅ | 1–3 | Toolchain installed, QEMU runs | — |
| 1 🚧 | 4–7 | Boot via GRUB, "Hello, Paul OS" on screen + serial | Ch 1.2, 2.5, 2.9 |
| 2 | 8–17 | GDT, IDT, exceptions, timer & keyboard interrupts | Ch 1.2, 1.4, 12.1–12.4 |
| 3 | 18–30 | Physical page allocator, paging, kernel heap | Ch 9.1–9.4, 9.6, 10.1, 10.8 |
| 4 | 31–42 | Processes, context switch, round-robin scheduler | Ch 3.1–3.3, 5.1–5.3, 6.1–6.6 |
| 5 | 43–52 | User mode, system calls, ELF loading | Ch 2.3, 2.5 |
| 6 | 53–60 | In-memory filesystem + mini shell → **v0.1** 🎉 | Ch 13.1–13.3, 14.1–14.4 |

Detailed checklists are in [`docs/roadmap.md`](docs/roadmap.md).

---

## 4. Building & Running

Requires the i686-elf cross-compiler on your PATH plus `nasm`, the GRUB tools, `xorriso` and QEMU (see [Installation](#1-installation)). Run everything from `~/PaulOS` in Ubuntu.

```bash
make             # assemble boot.asm, compile kernel.c, link paulos.bin, verify the Multiboot header
make iso         # build paulos.iso (GRUB + kernel) with grub-mkrescue
make run         # boot the ISO in QEMU: SeaBIOS → GRUB menu → Paul OS
make run-kernel  # boot the kernel directly with QEMU's built-in Multiboot loader (fastest)
make debug       # QEMU paused (-s -S) + GDB attached, breakpoint at kernel_main
make clean       # remove *.o, paulos.bin, paulos.iso, isodir/
```

**Build pipeline**

```
boot.asm  --nasm -felf32-------------------------------->  boot.o
kernel.c  --i686-elf-gcc -c -ffreestanding -O2---------->  kernel.o
boot.o + kernel.o + linker.ld + libgcc --i686-elf-gcc -T  ->  paulos.bin   (ELF32, loaded at 1 MiB)
paulos.bin + grub.cfg --grub-mkrescue------------------->  paulos.iso
```

**What you should see:**

```
Hello from Paul OS!
Loaded by a Multiboot bootloader. Magic = 0x2BADB002  [OK]
Multiboot info structure at 0x000.....

Week 1 complete. CPU halting.
```

> **Makefile gotchas (hit on day 1):** recipe lines must start with a real **TAB**, otherwise you get `*** missing separator`. Lines must end in LF: `cat -A Makefile` shows `^I` for a tab and `^M` for a stray CR, and `sed -i 's/\r$//' Makefile` strips the CRs. Text copied from a PDF loses tabs and can split long lines, so check both.

---

## 5. Resources

- 📘 *Operating System Concepts*, 10th ed. (Silberschatz et al.): theory
- 🌐 [OSDev Wiki](https://wiki.osdev.org/): practical how-to for every step
- 📗 [xv6 book & source](https://pdos.csail.mit.edu/6.1810/): a small, readable real OS to compare against
- 📙 [OSTEP: Operating Systems: Three Easy Pieces](https://pages.cs.wisc.edu/~remzi/OSTEP/): free and hands-on
- 📕 Intel SDM Vol. 3: GDT, IDT, paging hardware reference

---

## 6. Changelog

### 24 Nov 2026: Day 1 (Week 1, days 1–5 done in one sitting)
**Environment**
- Installed WSL2 + Ubuntu 24.04. Working clone moved to `~/PaulOS` on the Linux filesystem.
- Installed nasm, QEMU, GDB, the GRUB tools, xorriso and mtools. QEMU smoke test showed SeaBIOS → "No bootable device".
- Built the **i686-elf cross-compiler**: binutils 2.45 + GCC 15.2.0 (C only, with libgcc) in `~/opt/cross`.

**Kernel**
- `boot.asm`: Multiboot 1 header (magic `0x1BADB002`, flags `0x3`, checksum `0xE4524FFB`), 16 KiB stack in `.bss`, and `_start`, which passes EAX (magic) and EBX (Multiboot info) to `kernel_main` using cdecl, then halts with a `cli`/`hlt` loop.
- `kernel.c`: freestanding C kernel with a VGA text-mode driver at `0xB8000` (colours, newline, line wrap, hex printing). It checks the boot magic `0x2BADB002`.
- `linker.ld`: kernel loaded at 1 MiB with 4 KiB-aligned `.text` / `.rodata` / `.data` / `.bss`, and the Multiboot header placed first.
- `grub.cfg` + `grub-mkrescue` → bootable `paulos.iso`.
- `Makefile` with `all`, `iso`, `run`, `run-kernel`, `debug` and `clean`.
- ✅ **First boot:** `paulos.bin` passes `grub-file --is-x86-multiboot` and boots in QEMU both directly (`-kernel`) and through GRUB (`-cdrom`).

**Learned / inspected**
- `readelf` / `nm` / `objdump` on `boot.o`: the header bytes `02b0ad1b 03000000 fb4f52e4` are stored little-endian; `.bss` is NOBITS; `kernel_main` shows as `U` until link time; and `mov esp, 0x4000` / `call` hold placeholders until the linker applies the relocations.
- `objdump` on `kernel.o`: GCC inlined the VGA helpers, computed `row * 80` as `(row*5) << 4`, used `cmove` for the row wrap, and passed `static` function arguments in registers. The real screen write is `mov WORD PTR [edi+0xb8000], cx`.

**Problems fixed**
- WSL user setup was interrupted with Ctrl+C → reinstalled the distro (password input is invisible by design).
- Ran `wsl` in Ubuntu and `sudo apt` in PowerShell → each command belongs to its own window.
- `Makefile: *** missing separator` → the PDF copy had dropped the TABs and split a long line. Restored the TABs and joined the line.
- `^M` at the end of lines (CRLF) → stripped with `sed -i 's/\r$//'`, and set VS Code's EOL to `\n`.

**Next:** Day 6 (QEMU monitor, GDB session, the break-it-on-purpose experiments) → Week 2: GDT, serial port, scrolling, `kprintf`.

---

*A learning repo: the code evolves as I learn. Stay tuned 😁*
