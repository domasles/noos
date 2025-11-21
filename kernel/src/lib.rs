#![no_std]
#![no_main]

#![feature(abi_x86_interrupt)]

pub mod multiboot;
pub mod drivers;
pub mod idt;
pub mod pic;

use core::panic::PanicInfo;

use crate::drivers::keyboard::process_scancodes;

unsafe extern "C" { unsafe fn hlt(); }

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(multiboot_info: u64) -> ! {
    crate::clearscr!();

    multiboot::load_boot_info(multiboot_info);
    idt::init();

    if multiboot::debug_mode_enabled() { crate::println!("Debug mode enabled"); }
    if multiboot::release_mode_enabled() { crate::println!("Release mode enabled"); }

    crate::println!("Kernel initialized successfully!");
    crate::println!("Welcome to NoOS!");

    loop {
        process_scancodes();
        unsafe { hlt() }
    }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    crate::println!("KERNEL PANIC!");

    if let Some(location) = info.location() {
        crate::println!("Location: {}:{}", location.file(), location.line());
    }

    loop { unsafe { hlt() } }
}
