%include "boot/src/pic/keyboard.asm"

bits 64
remap_pic:
    mov al, 0x11  ; ICW1: start init
    out 0x20, al  ; Master
    out 0xA0, al  ; Slave

    mov al, 0x20  ; ICW2: master offset 0x20
    out 0x21, al
    mov al, 0x28  ; ICW2: slave offset 0x28
    out 0xA1, al

    mov al, 0x04  ; ICW3: tell master about slave at IRQ2
    out 0x21, al
    mov al, 0x02  ; ICW3: tell slave its cascade identity
    out 0xA1, al

    ; ICW4: 8086 mode
    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; Mask all IRQs
    mov al, 0xFF
    out 0x21, al
    mov al, 0xFF
    out 0xA1, al

    call unmask_keyboard
    ret
