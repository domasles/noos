unsafe extern "C" {
    unsafe fn inb(port: u16) -> u8;        // Read a byte from the specified port
    unsafe fn outb(port: u16, value: u8);  // Write a byte to the specified port
}

const COM1: u16 = 0x3F8;  // COM1 port address (IBM legacy)

pub fn write_byte(byte: u8) {
    unsafe {
        while !transmitter_ready() {}
        outb(COM1, byte);
    }
}

fn transmitter_ready() -> bool {
    unsafe { (inb(COM1 + 5) & 0x20) != 0 }
}
