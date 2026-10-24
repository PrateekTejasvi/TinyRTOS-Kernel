OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x80000000, LENGTH = 128M
}

SECTIONS
{
    .text : {
        *(.text.init)            /* boot code first, so _start lands at 0x80000000 */
        *(.text .text.*)
    } > RAM

    .rodata : { *(.rodata .rodata.*) } > RAM
    .data   : { *(.data .data.*) }     > RAM

    .bss : {
        . = ALIGN(4);
        __bss_start = .;
        *(.bss .bss.*) *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > RAM

    .stack (NOLOAD) : ALIGN(16) {
        __stack_bottom = .;
        . += 4096;               /* boot stack size is set to 4kb can be changed later*/
        __stack_top = .;
    } > RAM
}
