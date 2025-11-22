section .text
bits 32

global setup_page_tables

setup_page_tables:
    ; Map P4[0] -> P3
    mov eax, p3_table
    or eax, 0b11         ; Present + writable
    mov [p4_table], eax

    ; Map P3[0] -> P2
    mov eax, p2_table
    or eax, 0b11         ; Present + writable
    mov [p3_table], eax

    ; Map P2 entries (identity map first 2MB with 2MB pages)
    mov ecx, 0

.map_p2_table:
    mov eax, 0x200000   ; 2MB
    mul ecx
    or eax, 0b10000011  ; Present + writable + huge page
    mov [p2_table + ecx * 8], eax
    inc ecx
    cmp ecx, 512
    jne .map_p2_table

    ret
