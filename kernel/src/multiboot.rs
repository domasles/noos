use multiboot2::{BootInformation, BootInformationHeader};
use spin::Once;

static BOOT_INFO: Once<BootInformation> = Once::new();

pub fn load_boot_info(multiboot_info: u64) {
    let info = unsafe { BootInformation::load(multiboot_info as *const BootInformationHeader) }.unwrap();
    BOOT_INFO.call_once(|| info);
}

pub fn get_command_line<'a>() -> Option<&'a str> {
    BOOT_INFO.get().and_then(|info| {
        info.command_line_tag().map(|tag| tag.cmdline().unwrap_or("Invalid UTF-8"))
    })
}

pub fn has_command_line() -> bool {
    get_command_line().is_some()
}

pub fn mode_enabled(mode: &str) -> bool {
    get_command_line().map(|s| s.contains(mode)).unwrap_or(false)
}

pub fn debug_mode_enabled() -> bool {
    mode_enabled("mode=debug")
}

pub fn release_mode_enabled() -> bool {
    mode_enabled("mode=release")
}
