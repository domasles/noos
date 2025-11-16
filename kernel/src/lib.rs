#![no_std]
#![no_main]

#![feature(abi_x86_interrupt)]

pub mod multiboot_info;
pub mod drivers;

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(multiboot_info: u64) -> ! {
    multiboot_info::load_boot_info(multiboot_info);

    drivers::vga::clear_screen();
    drivers::vga::print_string("Kernel initialized successfully!\n");

    if multiboot_info::debug_mode_enabled() { drivers::vga::print_string("Debug mode enabled\n"); }
    if multiboot_info::release_mode_enabled() { drivers::vga::print_string("Release mode enabled\n"); }

    drivers::vga::print_string("Welcome to NoOS!\n");

    loop { unsafe { core::arch::asm!("hlt") } }
}

#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    drivers::vga::print_string("\n\nKERNEL PANIC!\n");

    if let Some(location) = info.location() {
        drivers::vga::print_string("Location: ");
        drivers::vga::print_string(location.file());
        drivers::vga::print_string("\n");
    }
    
    loop { unsafe { core::arch::asm!("hlt") } }
}
