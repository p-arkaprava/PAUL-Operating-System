; =====================================================================
; boot.asm - Paul OS entry point (Week 1)
; GRUB loads us in 32-bit protected mode. This file:
; 1. contains the Multiboot header so GRUB recognises the kernel
; 2. reserves a 16 KiB stack (C code needs a stack)
; 3. jumps into C (kernel_main) and halts forever if it returns
; =====================================================================
; ---- Multiboot (version 1) header constants -------------------------
MBALIGN equ 1 << 0 ; bit 0: load modules on 4 KiB page boundaries
MEMINFO equ 1 << 1 ; bit 1: please give us a memory map
MBFLAGS equ MBALIGN | MEMINFO ; = 0x00000003
MAGIC equ 0x1BADB002 ; the number GRUB searches for
CHECKSUM equ -(MAGIC + MBFLAGS) ; MAGIC + FLAGS + CHECKSUM must be 0
; ---- The header itself: 3 x 32-bit words, 4-byte aligned ------------
section .multiboot
align 4
dd MAGIC
dd MBFLAGS
dd CHECKSUM
; ---- Stack: 16 KiB of uninitialised memory --------------------------
section .bss
align 16
stack_bottom:
resb 16384 ; reserve 16 KiB (no bytes stored in the file)
stack_top: ; x86 stacks grow DOWN, so we start at the top
; ---- Code -----------------------------------------------------------
section .text
global _start ; linker.ld says ENTRY(_start)
extern kernel_main ; defined in kernel.c
_start:
mov esp, stack_top ; 1. set up the stack pointer
; 2. Call kernel_main(magic, mbi) using the cdecl convention:
; arguments are pushed RIGHT-TO-LEFT, so the 2nd one goes first.
; The extra 8 bytes keep ESP 16-byte aligned at the CALL (i386 ABI).
sub esp, 8
push ebx ; arg 2: physical address of Multiboot info
push eax ; arg 1: magic value 0x2BADB002 from GRUB
call kernel_main
; 3. kernel_main should never return. If it does, stop the CPU.
cli ; disable maskable interrupts
.hang:
hlt ; sleep until an interrupt (none will come)
jmp .hang ; ...but an NMI could wake us, so loop
