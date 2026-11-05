# Paul OS

A small operating system built from scratch, one concept at a time, as a learning project.

The theory comes from *Operating System Concepts* (Silberschatz, Galvin, Gagne, 10th ed.). Every topic I read gets implemented in real code that boots on x86 hardware (emulated with QEMU), because building something is the best way to see why it matters.

> **Status:** Phase 0: setting up the toolchain
> **Goal:** first working prototype in 60 days, then keep improving it.

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

---

## 1. Installation

**Target platform:** Windows 10/11 with WSL2 (Ubuntu 24.04). All building happens inside Linux.

**Time needed:** about 1–1.5 hours, most of it waiting for the compiler to build.

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
> cd /mnt/c/Users/arkap/PaulOS
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
4. Check that it's running as WSL **version 2**:
   ```powershell
   wsl -l -v
   ```
   If VERSION shows `1`, run `wsl --set-version Ubuntu-24.04 2`.

> If you get a "virtualization not enabled" error, enable **Intel VT-x / AMD-V (SVM)** in the BIOS.

### 1.2 Install build packages

From here on, every command runs in the **Ubuntu terminal**.

```bash
sudo apt update && sudo apt upgrade -y

sudo apt install -y build-essential nasm qemu-system-x86 gdb git wget \
  grub-pc-bin grub-common xorriso mtools \
  bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo
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
wget https://ftp.gnu.org/gnu/binutils/binutils-2.42.tar.xz
wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
tar xf binutils-2.42.tar.xz
tar xf gcc-13.2.0.tar.xz

# 3. Build binutils (assembler + linker)
mkdir -p build-binutils && cd build-binutils
../binutils-2.42/configure --target=$TARGET --prefix="$PREFIX" \
  --with-sysroot --disable-nls --disable-werror
make -j$(nproc) && make install

# 4. Build GCC (C only, no standard library)
cd ~/src && mkdir -p build-gcc && cd build-gcc
../gcc-13.2.0/configure --target=$TARGET --prefix="$PREFIX" \
  --disable-nls --enable-languages=c --without-headers
make -j$(nproc) all-gcc
make -j$(nproc) all-target-libgcc
make install-gcc
make install-target-libgcc

# 5. Make the PATH setting permanent
echo 'export PATH="$HOME/opt/cross/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 6. Verify
i686-elf-gcc --version
```

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
   cd /mnt/c/Users/arkap/PaulOS
   code .
   ```
   The bottom-left corner should say **WSL: Ubuntu-24.04**.
3. VS Code will suggest the recommended extensions listed in `.vscode/extensions.json`. Accept them:
   - **WSL** (`ms-vscode-remote.remote-wsl`)
   - **C/C++** (`ms-vscode.cpptools`)
   - **x86 and x86_64 Assembly** (`13xforever.language-x86-64-assembly`)
   - **Makefile Tools** (`ms-vscode.makefile-tools`)
4. IntelliSense is already set up to use the cross-compiler in `.vscode/c_cpp_properties.json`.

> **Note on file location:** this repo lives on the Windows drive (`C:\Users\arkap\PaulOS` = `/mnt/c/Users/arkap/PaulOS` in WSL). That's slower than the Linux filesystem, but fine for a kernel this size. If builds ever feel slow, clone the repo into `~/paul-os` inside Ubuntu.

### 1.6 Set up Git

```bash
git config --global user.name "Arkaprava Paul"
git config --global user.email "p.Arkaprava@iitg.ac.in"
git config --global core.autocrlf input   # keep LF line endings (shell scripts break with CRLF)
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

---

## 3. Roadmap

| Phase | Days | Milestone | Book chapters |
|---|---|---|---|
| 0 | 1–3 | Toolchain installed, QEMU runs | — |
| 1 | 4–7 | Boot via GRUB, "Hello, Paul OS" on screen + serial | Ch 1.2, 2.5, 2.9 |
| 2 | 8–17 | GDT, IDT, exceptions, timer & keyboard interrupts | Ch 1.2, 1.4, 12.1–12.4 |
| 3 | 18–30 | Physical page allocator, paging, kernel heap | Ch 9.1–9.4, 9.6, 10.1, 10.8 |
| 4 | 31–42 | Processes, context switch, round-robin scheduler | Ch 3.1–3.3, 5.1–5.3, 6.1–6.6 |
| 5 | 43–52 | User mode, system calls, ELF loading | Ch 2.3, 2.5 |
| 6 | 53–60 | In-memory filesystem + mini shell → **v0.1** 🎉 | Ch 13.1–13.3, 14.1–14.4 |

Detailed checklists are in [`docs/roadmap.md`](docs/roadmap.md).

---

## 4. Building & Running

*Coming in Phase 1.* Once it's ready:

```bash
make            # build the kernel + bootable ISO
make run        # boot in QEMU
make debug      # boot paused, waiting for GDB
make clean
```

---

## 5. Resources

- 📘 *Operating System Concepts*, 10th ed. (Silberschatz et al.): theory
- 🌐 [OSDev Wiki](https://wiki.osdev.org/): practical how-to for every step
- 📗 [xv6 book & source](https://pdos.csail.mit.edu/6.1810/): a small, readable real OS to compare against
- 📙 [OSTEP: Operating Systems: Three Easy Pieces](https://pages.cs.wisc.edu/~remzi/OSTEP/): free and hands-on
- 📕 Intel SDM Vol. 3: GDT, IDT, paging hardware reference

---

*A learning repo: the code evolves as I learn. Stay tuned 😁*
