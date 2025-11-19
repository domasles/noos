%include "boot/src/utils/print.asm"
%include "boot/src/multiboot2.asm"
%include "boot/src/long_mode.asm"
%include "boot/src/extern.asm"
%include "boot/src/paging.asm"
%include "boot/src/gdt.asm"

section .bss
align 4096

p4_table: resb 4096
p3_table: resb 4096
p2_table: resb 4096
stack_bottom: resb 16384  ; 16 KiB stack
stack_top:

section .text
bits 32
global _start
extern kernel_main

_start:
    mov esp, stack_top  ; Setup stack
    mov edi, ebx        ; Save multiboot info

    call check_long_mode
    call setup_page_tables
    call enable_paging

    lgdt [gdt64.pointer]            ; Load GDT
    jmp gdt64.code:long_mode_start  ; Jump to long mode

bits 64
long_mode_start:
    ; Load null segment selectors
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov edi, edi
    call kernel_main  ; Call the Rust entry point
    cli               ; If we return, hang

.hang:
    hlt
    jmp .hang
