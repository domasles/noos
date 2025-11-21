#![allow(dead_code)]

use x86_64::instructions::port::Port;

pub const COM1: u16 = 0x3F8;

pub struct SerialPort {
    data: Port<u8>,
    line_status: Port<u8>,
}

impl SerialPort {
    pub fn new(port: u16) -> Self {
        Self {
            data: Port::new(port),
            line_status: Port::new(port + 5),
        }
    }

    pub fn write_byte(&mut self, byte: u8) {
        while !self.transmitter_ready() {}
        unsafe { self.data.write(byte); }
    }

    fn transmitter_ready(&mut self) -> bool {
        let status = unsafe { self.line_status.read() };
        (status & 0x20) != 0
    }
}
