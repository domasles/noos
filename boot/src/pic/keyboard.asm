bits 64

unmask_keyboard:
    mov al, 0xFD
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al

    ret