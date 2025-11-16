section .text
bits 32

global error_message
global print_error

print_error:
    mov edi, 0xB8000  ; VGA text mode buffer

.print_loop:
    lodsb         ; Load byte from string to AL, increment ESI
    cmp al, 0
    je .hang
    mov ah, 0x04  ; White on black
    stosw
    jmp .print_loop

.hang:
    hlt
    jmp .hang

error_message:
    db "CPU does not support long mode!", 0
