.section .text.init
.globl _start
_start:
    # TODO 1: load sp with the address of __stack_top.
    la sp, __stack_top
    # TODO 2 (optional): read the mhartid CSR and park any hart != 0.
1:  wfi
    j 1b
