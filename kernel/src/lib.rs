#![no_std]
#![no_main]

#![feature(abi_x86_interrupt)]

pub mod drivers;

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main() -> ! {
    drivers::vga::clear_screen();

    drivers::vga::print_string("Kernel initialized successfully!\n");
    drivers::vga::print_string("Welcome to NoOS!\n");

    loop {
        unsafe { core::arch::asm!("hlt") }
    }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    drivers::vga::print_string("\n\nKERNEL PANIC!\n");

    if let Some(location) = info.location() {
        drivers::vga::print_string("Location: ");
        drivers::vga::print_string(location.file());
        drivers::vga::print_string("\n");
    }
    
    loop {
        unsafe { core::arch::asm!("hlt") }
    }
}
