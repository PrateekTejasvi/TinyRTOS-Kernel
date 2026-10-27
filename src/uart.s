.global uart_put_char
.global uart_get_char

.equ UART_BASE_ADDRESS ,0x10000000
.equ LINE_STATUS_REGISTER, 0x5

uart_init:
    li t0 , UART_BASE_ADDRESS


uart_get_char:
    .cfi_startproc
    .cfi_endproc
uart_put_char:
    .cfi_startproc
    .cfi_endproc
.end
