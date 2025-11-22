use pc_keyboard::{Keyboard, layouts, ScancodeSet1, DecodedKey, HandleControl};

use x86_64::instructions::{port::Port, interrupts::without_interrupts};
use x86_64::structures::idt::InterruptStackFrame;

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
        KeyboardDriver { keyboard: Mutex::new(Keyboard::new(ScancodeSet1::new(), layouts::Us104Key, HandleControl::MapLettersToUnicode)) }
    }

    fn read_scancode(&self) -> u8 {
        let mut port = Port::new(0x60);
        unsafe { port.read() }
    }

    pub fn handle_scancode(&self, scancode: u8, shell: &mut crate::shell::Shell) {
        let mut kb = self.keyboard.lock();

        if let Ok(Some(event)) = kb.add_byte(scancode) {
            if let Some(key) = kb.process_keyevent(event) {
                match key {
                    DecodedKey::Unicode(c) => { shell.handle_char(c); }
                    DecodedKey::RawKey(_keycode) => {} // Ignore specal keys for now. This prevents queue flooding
                }
            }
        }
    }
}

pub static KEYBOARD: KeyboardDriver = KeyboardDriver::new();

pub fn process_scancodes(shell: &mut crate::shell::Shell) {
    // Process queue with interrupts disabled to prevent contention
    without_interrupts(|| {
        let mut queue = SCANCODE_QUEUE.lock();
        
        while let Some(scancode) = queue.dequeue() {
            drop(queue);  // Release lock before processing
            KEYBOARD.handle_scancode(scancode, shell);
            queue = SCANCODE_QUEUE.lock();  // Re-acquire for next iteration
        }
    });
}

pub extern "x86-interrupt" fn keyboard_interrupt_handler(_stack_frame: InterruptStackFrame) {
    let scancode = KEYBOARD.read_scancode();
    
    // Try to get lock without blocking
    // If can't get lock, drop the scancode (better than hanging)

    if let Some(mut queue) = SCANCODE_QUEUE.try_lock() {
        if queue.enqueue(scancode).is_err() {
            queue.dequeue();
            queue.enqueue(scancode).ok();
        }
    }
    
    send_eoi(1);
}
