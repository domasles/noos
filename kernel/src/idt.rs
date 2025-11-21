use x86_64::structures::idt::InterruptDescriptorTable;
use lazy_static::lazy_static;

use crate::drivers::keyboard::keyboard_interrupt_handler;

lazy_static! {
    static ref IDT: InterruptDescriptorTable = {
        let mut idt = InterruptDescriptorTable::new();
        idt[0x21].set_handler_fn(keyboard_interrupt_handler);
        idt
    };
}

pub fn init() {
    IDT.load();
}
