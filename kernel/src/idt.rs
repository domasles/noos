use core::mem::size_of;

#[repr(C, packed)]
struct IdtEntry {
    offset_low: u16,   // Lower 16 bits of handler address
    selector: u16,     // Code segment selector (from GDT)
    ist: u8,           // Interrupt Stack Table offset (0 for now)
    flags: u8,         // Type and attributes
    offset_mid: u16,   // Middle 16 bits of handler address
    offset_high: u32,  // Upper 32 bits of handler address
    reserved: u32,     // Must be zero
}

impl IdtEntry {
    const fn missing() -> Self {
        Self {
            offset_low: 0,
            selector: 0,
            ist: 0,
            flags: 0,
            offset_mid: 0,
            offset_high: 0,
            reserved: 0,
        }
    }
}

#[repr(C, packed)]
struct IdtPointer {
    limit: u16,  // Size of IDT - 1
    base: u64,   // Address of IDT
}

static IDT: [IdtEntry; 256] = [const { IdtEntry::missing() }; 256];

unsafe extern "C" { unsafe fn lidt(idt_pointer: &IdtPointer); }

pub fn init_idt() {
    let idt_pointer = IdtPointer {
        limit: (size_of::<[IdtEntry; 256]>() - 1) as u16,
        base: &IDT as *const _ as u64,
    };

    unsafe {
        lidt(&idt_pointer);
    }
}
