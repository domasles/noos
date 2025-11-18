bits 64

global lidt

lidt:
    lidt [rcx]
    ret
