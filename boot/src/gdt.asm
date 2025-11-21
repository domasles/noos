section .rodata

gdt64:
    dq 0  ; Zero entry

.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)  ; Code segment

.pointer:
    dw $ - gdt64 - 1
    dq gdt64
