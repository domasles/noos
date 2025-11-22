use pc_keyboard::{Keyboard, layouts, ScancodeSet1, DecodedKey, HandleControl};

use x86_64::structures::idt::InterruptStackFrame;
use x86_64::instructions::port::Port;

use heapless::spsc::Queue;
use spin::Mutex;

use crate::pic::send_eoi;

lazy_static::lazy_static! {
    pub static ref SCANCODE_QUEUE: Mutex<Queue<u8, 1024>> = Mutex::new(Queue::new());
}

pub struct KeyboardDriver {
    keyboard: Mutex<Keyboard<layouts::Us104Key, ScancodeSet1>>,
}

impl KeyboardDriver {
    pub const fn new() -> Self {
        KeyboardDriver { keyboard: Mutex::new(Keyboard::new(ScancodeSet1::new(), layouts::Us104Key, HandleControl::Ignore)) }
    }

    fn read_scancode(&self) -> u8 {
        let mut port = Port::new(0x60);
        unsafe { port.read() }
    }

    pub fn handle_scancode(&self, scancode: u8) {
        let mut kb = self.keyboard.lock();

        if let Ok(Some(event)) = kb.add_byte(scancode) {
            if let Some(key) = kb.process_keyevent(event) {
                match key {
                    DecodedKey::Unicode(c) => {
                        if c == '\u{8}' { crate::drivers::vga::_backspace(); }
                        else { crate::print!("{}", c); }
                    }

                    DecodedKey::RawKey(_) => {}  // Ignore raw keys for now
                }
            }
        }
    }
}

pub static KEYBOARD: KeyboardDriver = KeyboardDriver::new();

pub fn process_scancodes() {
    let mut queue = SCANCODE_QUEUE.lock();
    while let Some(scancode) = queue.dequeue() {
        KEYBOARD.handle_scancode(scancode);
    }
}

pub extern "x86-interrupt" fn keyboard_interrupt_handler(_stack_frame: InterruptStackFrame) {
    let scancode = KEYBOARD.read_scancode();
    let mut queue = SCANCODE_QUEUE.lock();

    queue.enqueue(scancode).ok();
    send_eoi(1);
}
