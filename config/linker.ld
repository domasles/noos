PHDRS {
    rodata PT_LOAD FLAGS(4);    /* read-only */
    text PT_LOAD FLAGS(5);      /* read + execute */
    data PT_LOAD FLAGS(6);      /* read + write */
}

ENTRY(_start)

SECTIONS {
    . = 1M;

    .boot : AT(0x100000) {
        KEEP(*(.multiboot_header))
    } :text

    .text : AT(ADDR(.text)) {
        *(.text .text.*)
    } :text

    .rodata : AT(ADDR(.rodata)) {
        *(.rodata .rodata.*)
    } :rodata

    .data : AT(ADDR(.data)) {
        *(.data .data.*)
    } :data

    .bss : AT(ADDR(.bss)) {
        *(.bss .bss.*)
    } :data

    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
    }
}
