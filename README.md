# NoOS

**NoOS** literally stands for **"No Operating System"**.

It's an attempt to make a 64-bit operating system kernel written in **Rust** with **GRUB2** bootloader support.

## Why NoOS?

**Focus**: Understanding low-level system architecture through hands-on kernel development.

**Purpose**: This project exists to demystify operating system internals by building one from scratch. No frameworks, no abstractions - just you, Rust, and the hardware. It's designed for developers who want to understand what happens between pressing the power button and running user programs.

## Key Features

### Kernel Foundation
- **64-bit Long Mode**: Full x86_64 support with proper long mode transition from Multiboot2's 32-bit entry
- **GRUB2 Bootloader**: Multiboot2-compliant bootloader integration
- **VGA Text Driver**: 80x25 color text mode with thread-safe output via spinlocks
- **Memory Safety**: Leveraging Rust's ownership system for kernel-level safety guarantees
- **Panic Handler**: Custom panic implementation with error display

### Architecture
- **No Standard Library**: Pure `no_std` Rust - no heap, no filesystem, no OS dependencies
- **Manual Memory Management**: Direct hardware interaction without runtime overhead
- **Page Table Setup**: Identity-mapped first 1GB with 2MB huge pages
- **Custom Linker Script**: Precise memory layout control for kernel sections

## Quick Start

### Prerequisites
- **Linux** or **WSL2** on Windows
- **CMake 3.16+** not required - pure Makefile-based build system
- **Git** for repository management

### Setup
```bash
# Clone repository
git clone https://github.com/domasles/NoOS.git
cd NoOS

# Install dependencies and Rust toolchain (in a Linux shell environment)
make setup
```

This installs:
- Build tools: `build-essential`, `nasm`, `grub-pc-bin`, `xorriso`, `mtools`
- QEMU: `qemu-system-x86`
- Rust: `nightly` toolchain with `rust-src`, `llvm-tools-preview`
- Target: `x86_64-unknown-none`

### Build and Run
```bash
# Build kernel binary
make kernel

# Create bootable ISO
make iso

# Build and launch in QEMU
make run

# Clean build artifacts
make clean
```

## Daily Development Workflow

### Command Line (Primary Method)
```bash
# Quick development cycle
make clean && make run

# Build only kernel
make kernel

# Build only ISO
make iso

# View available commands
make help
```

## Project Structure

### Kernel Organization
```
kernel/
├── src/
│   ├── lib.rs              # Kernel entry point and panic handler
│   ├── drivers/
│   │   ├── mod.rs          # Driver module exports
│   │   └── vga.rs          # VGA text mode driver with color support
│   ├── arch/               # Architecture-specific code (placeholder)
│   └── memory/             # Memory management (placeholder)
├── .cargo/
│   └── config.toml         # Build configuration for no_std target
├── Cargo.toml              # Dependencies: spin, lazy_static
└── rust-toolchain.toml     # Ensures nightly with required components
```

### Boot Infrastructure
```
boot/
├── multiboot_header.asm    # Multiboot2 header + 32->64 bit transition
└── grub.cfg                # GRUB menu configuration
```

### Build Configuration
```
config/
└── linker.ld               # Custom linker script (kernel @ 1MB)
```

### Build System
```
Makefile                    # Complete build automation with colored output
build/
├── kernel/
│   ├── multiboot.o         # Assembled bootloader
│   └── kernel.bin          # Final linked kernel
└── iso/
    └── NoOS.iso            # Bootable ISO image
```

## Boot Process

### Stage 1: GRUB to Multiboot Header
1. BIOS/UEFI loads GRUB from disk
2. GRUB reads `boot/grub.cfg` and presents menu
3. GRUB scans `kernel.bin` for Multiboot2 magic number (`0xe85250d6`)
4. GRUB loads kernel to 1MB physical address
5. GRUB jumps to `_start` in **32-bit protected mode**

### Stage 2: Long Mode Transition (Assembly)
1. **CPU Check**: Verify 64-bit support via CPUID
2. **Page Tables**: Set up P4/P3/P2 tables, identity map first 1GB with 2MB pages
3. **Enable PAE**: Set CR4.PAE bit
4. **Enable Long Mode**: Set EFER.LME bit
5. **Enable Paging**: Set CR0.PG bit
6. **Load GDT**: 64-bit code/data descriptors
7. **Far Jump**: Switch to 64-bit code segment
8. **Call Rust**: Jump to `kernel_main()`

### Stage 3: Kernel Initialization (Rust)
1. Clear VGA screen (remove GRUB menu artifacts)
2. Initialize VGA writer with spinlock protection
3. Print welcome message
4. Enter infinite `hlt` loop

## Architecture Details

### Memory Layout at Runtime
```
0x0000_0000  - BIOS & IVT
0x000B_8000  - VGA Text Buffer (0xb8000)
0x0010_0000  - Kernel Entry Point (1MB)
               ├── Multiboot2 header
               ├── Page tables (P4/P3/P2)
               ├── Code (.text)
               ├── Constants (.rodata)
               ├── Global variables (.data/.bss)
               └── Stack (16KiB)
```

### VGA Driver Implementation
- **Buffer**: 80x25 characters at `0xb8000`
- **Format**: 2 bytes per char (ASCII + color attribute)
- **Thread Safety**: `Mutex<Writer>` with spin locks
- **Scrolling**: Row-by-row copy on line overflow
- **Colors**: 16 foreground/background color combinations

## Build Configuration

### Platform Support Status
- **Linux**: Fully supported and tested
- **Windows**: Via WSL2 (tested on Ubuntu 24.04+)
- **macOS**: Not tested, should work with Homebrew dependencies

### Rust Configuration
```toml
# kernel/.cargo/config.toml
[build]
target = "x86_64-unknown-none"  # Freestanding 64-bit

[target.x86_64-unknown-none]
rustflags = ["-C", "link-arg=-T../config/linker.ld"]

[unstable]
build-std = ["core", "compiler_builtins"]  # Rebuild stdlib for bare metal
```

### Dependencies
- **spin 0.10.0**: Spinlock-based mutex (no OS scheduler required)
- **lazy_static 1.5.0**: Static initialization with runtime setup

**Zero external dependencies beyond Rust crates**: All system tools (NASM, GRUB, ld) are standard Linux utilities.

## Troubleshooting

### Common Issues

**Build fails with linker errors**:
```bash
# Ensure all dependencies are installed
make setup
```

**Making ISO fails**:
- Sometimes an error, stating that `grub-mkrescue: error: 'xorriso' invocation failed` can occur (especially after editing ASM files). In this case it's best to perform a clean build:

```bash
make clean build
```

**QEMU shows only GRUB prompt**:
- Check that `boot/grub.cfg` has correct kernel path
- Verify kernel.bin is being copied to ISO: `ls -lh build/iso/boot/`

**Kernel boots but no output**:
- VGA address might be wrong (should be `0xb8000`)
- Check that `kernel_main()` is actually being called (add `hlt` at start to verify)

**WSL-specific issues**:
```bash
# Ensure cargo is in PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Run from Windows filesystem can be slow, use Linux filesystem
cd ~ && git clone https://github.com/domasles/NoOS.git
```

### Performance Tips
- **Use release mode** by default (already configured in Makefile)
- **Parallel builds**: Make already uses optimal settings
- **Faster rebuilds**: `make clean` only when changing dependencies

## Best Practices

### Kernel Development
- **Test frequently**: Run `make run` after every feature addition
- **Use volatile operations**: All hardware I/O must use `ptr::write_volatile`/`read_volatile`
- **No panics in production**: Kernel panics are unrecoverable, validate early
- **Minimal dependencies**: Every crate adds complexity, prefer `core` implementations

### Code Organization
- **Separate concerns**: Drivers in `drivers/`, arch code in `arch/`, memory in `memory/` and so on
- **Document hardware access**: Comment all magic numbers and hardware addresses
- **Use Rust idioms**: Leverage ownership, match, and error types even in kernel code

### Development Workflow
1. **Make small commits** with descriptive messages
2. **Test in QEMU** before real hardware
3. **Read disassembly** when debugging: `objdump -d build/kernel/kernel.bin`
4. **Check logs**: QEMU provides debug output with `-d int,cpu_reset`

## Next Steps

### Planned Features
- **Interrupt Handling**: IDT setup, keyboard driver, timer
- **Memory Management**: Heap allocator, virtual memory manager
- **Multitasking**: Process scheduler, context switching
- **Filesystem**: Simple ramdisk or ext2 support
- **System Calls**: User space support

### Learning Resources
- [OSDev Wiki](https://wiki.osdev.org/) - Comprehensive OS development reference
- [Writing an OS in Rust](https://os.phil-opp.com/) - Step-by-step Rust OS tutorial
- [Intel 64 Manual](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html) - x86_64 architecture reference
- [Multiboot2 Specification](https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html) - Bootloader protocol

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

---

**Happy coding!**

*I hope this serves as a great checkpoint to kernel development in Rust everyone can share, use and learn from!*
