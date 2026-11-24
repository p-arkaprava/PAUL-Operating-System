/* linker.ld - tells the linker WHERE each part of Paul OS goes in memory */
ENTRY(_start) /* first instruction to run (in boot.asm) */
SECTIONS
{
/* Load the kernel at 1 MiB. Everything below 1 MiB is BIOS data,

video memory and ROM on a PC, so 0x100000 is the first safe spot. */
. = 1M;
/* Code. The Multiboot header MUST come first so that it lands
inside the first 8 KiB of the file, where GRUB looks for it. */
.text BLOCK(4K) : ALIGN(4K)
{
*(.multiboot)
*(.text*)
}
/* Read-only data: string literals, const tables */
.rodata BLOCK(4K) : ALIGN(4K)
{
*(.rodata*)
}
/* Initialised read-write data: globals with an initial value */
.data BLOCK(4K) : ALIGN(4K)
{
*(.data*)
}
/* Zero-initialised data and our stack (takes no space in the file) */
.bss BLOCK(4K) : ALIGN(4K)
{
*(COMMON)
*(.bss*)
}
}
