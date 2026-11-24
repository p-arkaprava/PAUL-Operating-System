# =====================================================================
# Makefile - Paul OS build script (Week 1)
# make build paulos.bin (the kernel)
# make iso build a bootable GRUB ISO
# make run boot the ISO in QEMU (full GRUB path)
# make run-kernel boot the kernel directly in QEMU (fastest)
# make debug start QEMU paused + attach GDB
# make clean delete everything that was built
# =====================================================================
CC := i686-elf-gcc
AS := nasm
QEMU := qemu-system-i386
CFLAGS := -std=gnu99 -ffreestanding -O2 -g -Wall -Wextra
ASFLAGS := -felf32 -g
LDFLAGS := -T linker.ld -ffreestanding -O2 -nostdlib
OBJS := boot.o kernel.o
KERNEL := paulos.bin
ISO := paulos.iso
.PHONY: all iso run run-kernel debug clean
all: $(KERNEL)
# Link: combine object files using our linker script, then verify
$(KERNEL): $(OBJS) linker.ld
	$(CC) $(LDFLAGS) -o $@ $(OBJS) -lgcc
	grub-file --is-x86-multiboot $@ && echo "Multiboot header OK"
# Compile: every .c becomes a .o
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@
# Assemble: every .asm becomes a .o
%.o: %.asm
	$(AS) $(ASFLAGS) $< -o $@
iso: $(ISO)
$(ISO): $(KERNEL) grub.cfg
	mkdir -p isodir/boot/grub
	cp $(KERNEL) isodir/boot/$(KERNEL)
	cp grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o $@ isodir
run: $(ISO)
	$(QEMU) -cdrom $(ISO)
run-kernel: $(KERNEL)
	$(QEMU) -kernel $(KERNEL)
debug: $(KERNEL)
	$(QEMU) -kernel $(KERNEL) -s -S &
	gdb $(KERNEL) -ex "set architecture i386" -ex "target remote localhost:1234" -ex "break kernel_main" -ex "continue"
clean:
	rm -rf *.o $(KERNEL) $(ISO) isodir
