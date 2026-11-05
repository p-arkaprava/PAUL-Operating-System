# Troubleshooting

### `wsl --install` says virtualization is not enabled
Enable **Intel VT-x** (or **AMD SVM**) in the BIOS/UEFI settings. On a Dell G15, press F2 at boot and look under *Virtualization Support*. Also make sure the "Virtual Machine Platform" Windows feature is on.

### `bash: scripts/xyz.sh: /usr/bin/env: 'bash\r': No such file or directory`
The script has Windows (CRLF) line endings. Fix it with:
```bash
sudo apt install -y dos2unix && dos2unix scripts/*.sh
git config --global core.autocrlf input
```

### `i686-elf-gcc: command not found`
The cross-compiler isn't on your PATH. Run `source ~/.bashrc`, or check that `~/opt/cross/bin` exists. If it doesn't, the build didn't finish: re-run `bash scripts/build-cross-compiler.sh`.

### GCC build fails with "configure: error: Building GCC requires GMP/MPFR/MPC"
Run `bash scripts/install-deps.sh` again (it installs `libgmp3-dev libmpc-dev libmpfr-dev`), then delete `~/src/build-gcc` and rebuild.

### GCC build gets killed (out of memory)
WSL is running low on RAM. Build with fewer parallel jobs (`make -j2`), or raise WSL's memory limit in `C:\Users\arkap\.wslconfig`:
```ini
[wsl2]
memory=8GB
```
Then run `wsl --shutdown` in PowerShell and reopen Ubuntu.

### QEMU window doesn't appear
- Run `wsl --update` in PowerShell, then `wsl --shutdown`, then reopen Ubuntu (WSLg needs to be up to date).
- Fallback: `qemu-system-i386 -display curses` or `-nographic` (serial only).

### `grub-mkrescue` produces an ISO that won't boot / errors about `xorriso`
Make sure both `grub-pc-bin` and `xorriso` are installed: `sudo apt install -y grub-pc-bin xorriso mtools`.

### Builds are slow
The repo is on the Windows drive (`/mnt/c/...`). Clone it into the Linux filesystem instead (`git clone ... ~/paul-os`) and work from there.

### VS Code shows red squiggles on `#include` / can't find the compiler
Make sure the folder was opened **in WSL mode** (bottom-left corner says *WSL: Ubuntu-24.04*). `${env:HOME}` in `c_cpp_properties.json` only resolves to your Linux home in that mode.
