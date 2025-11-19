bits 64

global lidt
global hlt

lidt:
    lidt [rdi]
    ret

hlt:
    hlt
    ret
