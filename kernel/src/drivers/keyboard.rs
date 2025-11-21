use x86_64::structures::idt::InterruptStackFrame;
use x86_64::instructions::port::Port;

use crate::pic::send_eoi;

pub struct Keyboard;

impl Keyboard {
    pub const fn new() -> Self {
        Keyboard
    }

    fn read_scancode(&self) -> u8 {
        let mut port = Port::new(0x60);
        unsafe { port.read() }
    }
}

static KEYBOARD: Keyboard = Keyboard::new();

pub extern "x86-interrupt" fn keyboard_interrupt_handler(_stack_frame: InterruptStackFrame) {
    let scancode = KEYBOARD.read_scancode();
    crate::println!("Keyboard scancode: {}", scancode);
    send_eoi(1);
}
