/* =====================================================================
* kernel.c - Paul OS, Week 1
* A freestanding C kernel: no libc, no OS underneath us.
* We print to the screen by writing straight into VGA text memory.
* ===================================================================== */
#include <stdbool.h> /* bool, true, false - provided by GCC itself */
#include <stddef.h> /* size_t, NULL - provided by GCC itself */
#include <stdint.h> /* uint8_t, uint16_t - provided by GCC itself */
/* Safety checks: refuse to build with the wrong compiler. */
#if defined(__linux__)
#error "You are not using a cross-compiler! Use i686-elf-gcc."
#endif
#if !defined(__i386__)
#error "Paul OS (Week 1) must be compiled with an ix86-elf compiler."
#endif
#define MULTIBOOT_BOOTLOADER_MAGIC 0x2BADB002
/* ---------------- VGA text mode ------------------------------------ */
/* 16 hardware colours. Foreground uses all 16, background (bits 4-7). */
enum vga_color {
VGA_COLOR_BLACK = 0, VGA_COLOR_BLUE = 1,
VGA_COLOR_GREEN = 2, VGA_COLOR_CYAN = 3,
VGA_COLOR_RED = 4, VGA_COLOR_MAGENTA = 5,
VGA_COLOR_BROWN = 6, VGA_COLOR_LIGHT_GREY = 7,
VGA_COLOR_DARK_GREY = 8, VGA_COLOR_LIGHT_BLUE = 9,
VGA_COLOR_LIGHT_GREEN = 10, VGA_COLOR_LIGHT_CYAN = 11,
VGA_COLOR_LIGHT_RED = 12, VGA_COLOR_LIGHT_MAGENTA = 13,
VGA_COLOR_LIGHT_BROWN = 14, VGA_COLOR_WHITE = 15,
};

/* Attribute byte: high nibble = background, low nibble = foreground */
static inline uint8_t vga_entry_color(enum vga_color fg, enum vga_color bg)
{
return (uint8_t)(fg | bg << 4);
}
/* One screen cell = 16 bits: [attribute byte][ASCII byte] */
static inline uint16_t vga_entry(unsigned char ch, uint8_t color)
{
return (uint16_t)ch | (uint16_t)color << 8;
}
#define VGA_WIDTH 80
#define VGA_HEIGHT 25
/* The text buffer lives at physical address 0xB8000. 'volatile' tells

* the compiler every write matters (it is hardware, not normal RAM). */
static volatile uint16_t *const VGA_MEMORY = (volatile uint16_t *)0xB8000;
static size_t terminal_row;
static size_t terminal_column;
static uint8_t terminal_color;
/* No libc, so we write our own strlen. */
static size_t kstrlen(const char *str)
{
size_t len = 0;
while (str[len])
len++;
return len;
}
static void terminal_initialize(void)
{
terminal_row = 0;
terminal_column = 0;
terminal_color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);
for (size_t y = 0; y < VGA_HEIGHT; y++)
for (size_t x = 0; x < VGA_WIDTH; x++)
VGA_MEMORY[y * VGA_WIDTH + x] = vga_entry(' ', terminal_color);
}
static void terminal_setcolor(uint8_t color)
{
terminal_color = color;
}
static void terminal_putentryat(char c, uint8_t color, size_t x, size_t y)
{
VGA_MEMORY[y * VGA_WIDTH + x] = vga_entry((unsigned char)c, color);
}
static void terminal_newline(void)
{
terminal_column = 0;
if (++terminal_row == VGA_HEIGHT)
terminal_row = 0; /* wrap to top; real scrolling = Week 2 */
}
static void terminal_putchar(char c)
{
if (c == '\n') {
terminal_newline();
return;
}
terminal_putentryat(c, terminal_color, terminal_column, terminal_row);
if (++terminal_column == VGA_WIDTH)
terminal_newline();
}
static void terminal_write(const char *data, size_t size)
{
for (size_t i = 0; i < size; i++)
terminal_putchar(data[i]);
}
static void terminal_writestring(const char *data)
{
terminal_write(data, kstrlen(data));
}
/* Print a 32-bit value as 0xXXXXXXXX (no printf yet!). */
static void terminal_writehex(uint32_t value)
{
const char *digits = "0123456789ABCDEF";
terminal_writestring("0x");
for (int shift = 28; shift >= 0; shift -= 4)
terminal_putchar(digits[(value >> shift) & 0xF]);
}
/* ---------------- Entry point from boot.asm ------------------------ */
void kernel_main(uint32_t magic, uint32_t mbi_addr)
{
terminal_initialize();
terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_CYAN, VGA_COLOR_BLACK));
terminal_writestring("Hello from Paul OS!\n");
terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK));
terminal_writestring("Loaded by a Multiboot bootloader. Magic = ");
terminal_writehex(magic);
if (magic == MULTIBOOT_BOOTLOADER_MAGIC) {
terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK));
terminal_writestring(" [OK]\n");
} else {
terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_RED, VGA_COLOR_BLACK));
terminal_writestring(" [NOT MULTIBOOT!]\n");
}
terminal_setcolor(vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK));
terminal_writestring("Multiboot info structure at ");
terminal_writehex(mbi_addr);
terminal_writestring("\n\nWeek 1 complete. CPU halting.\n");
}
