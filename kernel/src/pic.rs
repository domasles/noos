use x86_64::instructions::port::Port;

pub fn send_eoi(irq: u8) {
    unsafe {
        if irq >= 8 { Port::new(0xA0).write(0x20u8); }  // slave EOI
        Port::new(0x20).write(0x20u8);                  // master EOI
    }
}
