section .note.GNU-stack note  ; Mark the stack as non-executable, no data is needed here
section .multiboot_header

header_start:
    ; Multiboot2 header
    dd 0xe85250d6                 ; magic number (multiboot 2)
    dd 0                          ; architecture 0 (protected mode i386)
    dd header_end - header_start  ; header length

    ; checksum
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start))

    ; required end tag
    dw 0  ; type
    dw 0  ; flags
    dd 8  ; size

header_end:

section .bss
align 4096

p4_table: resb 4096
p3_table: resb 4096
p2_table: resb 4096
stack_bottom: resb 16384  ; 16 KiB stack
stack_top:

section .rodata

gdt64:
    dq 0                                      ; zero entry

.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)  ; code segment

.pointer:
    dw $ - gdt64 - 1
    dq gdt64

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

check_long_mode:
    ; Check for CPUID
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je .no_long_mode
    
    ; Check for extended CPUID
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode
    
    ; Check for long mode support
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode
    ret

.no_long_mode:
    mov esi, error_message
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

setup_page_tables:
    ; Map P4[0] -> P3
    mov eax, p3_table
    or eax, 0b11         ; present + writable
    mov [p4_table], eax
    
    ; Map P3[0] -> P2
    mov eax, p2_table
    or eax, 0b11         ; present + writable
    mov [p3_table], eax
    
    ; Map P2 entries (identity map first 2MB with 2MB pages)
    mov ecx, 0

.map_p2_table:
    mov eax, 0x200000   ; 2MB
    mul ecx
    or eax, 0b10000011  ; present + writable + huge page
    mov [p2_table + ecx * 8], eax
    inc ecx
    cmp ecx, 512
    jne .map_p2_table

    ret

enable_paging:
    ; Load P4 to cr3
    mov eax, p4_table
    mov cr3, eax
    
    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    
    ; Enable long mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    
    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

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
