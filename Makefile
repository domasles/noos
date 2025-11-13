OS_NAME := $(shell lsb_release -si 2>/dev/null)
ARCH := $(shell uname -m)

ifeq ($(OS_NAME),Ubuntu)
else
$(error This Makefile must be run on Ubuntu. Detected OS: $(OS_NAME))
endif

ifeq ($(ARCH),x86_64)
else
$(warning Warning: Non-x86_64 architecture detected: $(ARCH))
endif

.PHONY: all build iso run clean help setup

# Load Rust environment if available
SHELL := /bin/bash
export PATH := $(HOME)/.cargo/bin:$(PATH)

# Configuration
GRUB_MKRESCUE := grub-mkrescue
QEMU := qemu-system-x86_64
CARGO := cargo
NASM := nasm
LD := ld

REQUIRED_TOOLS := $(GRUB_MKRESCUE) $(QEMU) $(CARGO) $(NASM) $(LD)

# Directories
CONFIG_DIR := config
KERNEL_DIR := kernel
BUILD_DIR := build
BOOT_DIR := boot

KERNEL_BUILD := $(BUILD_DIR)/kernel
ISO_BUILD := $(BUILD_DIR)/iso

# Outputs
MULTIBOOT_OBJ := $(KERNEL_BUILD)/multiboot.o
KERNEL_BIN := $(KERNEL_BUILD)/kernel.bin
ISO_FILE := $(ISO_BUILD)/noos.iso

# Build settings
LD_FLAGS := -m elf_x86_64 -n -T $(CONFIG_DIR)/linker.ld
CARGO_FLAGS := --release
NASM_FLAGS := -f elf64

# Colors (ANSI escape codes)
YELLOW := $(shell printf "\033[33m")
GREEN := $(shell printf "\033[32m")
CYAN := $(shell printf "\033[36m")
RESET := $(shell printf "\033[0m")

# Colors for output
define print_green
	@echo "✓ $(1)"
endef

define print_yellow
	@echo "→ $(1)"
endef

all: precheck build iso

precheck:
	@echo "Checking required tools..."
	$(foreach tool,$(REQUIRED_TOOLS),$(call check_tool,$(tool)))

help:
	@echo "NoOS - Rust Operating System"
	@echo ""
	@echo "Available targets:"
	@echo "  make build    - Build the kernel"
	@echo "  make iso      - Create bootable ISO"
	@echo "  make run      - Build and run in QEMU"
	@echo "  make clean    - Clean build artifacts"
	@echo "  make setup    - Install required dependencies (Ubuntu/Debian)"
	@echo ""

setup:
	@if ! sudo -v >/dev/null 2>&1; then \
		echo "Error: You must have sudo privileges to run setup."; \
		exit 1; \
	fi

	@echo "Installing required dependencies..."
	@sudo apt update
	@sudo apt install -y build-essential nasm grub-pc-bin grub-common xorriso mtools qemu-system-x86

	@if ! command -v rustup &> /dev/null; then \
		echo "Installing Rust..."; \
		curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; \
		. "$$HOME/.cargo/env"; \
	fi

	@. "$$HOME/.cargo/env" && rustup install nightly && rustup default nightly
	@. "$$HOME/.cargo/env" && rustup component add rust-src llvm-tools-preview
	@. "$$HOME/.cargo/env" && rustup target add x86_64-unknown-none

	@echo "✓ Setup complete!"

build: kernel iso

kernel: $(KERNEL_BIN)

$(ISO_FILE): $(KERNEL_BIN) | $(ISO_BUILD)/boot/grub
	@printf "$(YELLOW)→ [4/4] Creating ISO...$(RESET)\n"
	@cp $(KERNEL_BIN) $(ISO_BUILD)/boot/kernel.bin
	@cp $(BOOT_DIR)/grub.cfg $(ISO_BUILD)/boot/grub/grub.cfg
	@$(GRUB_MKRESCUE) --verbose -o $@ $(ISO_BUILD) 2>&1 | grep -v "cannot find a device" || true
	@printf "$(GREEN)✓ ISO built: $(RESET)$(CYAN)$(ISO_FILE)$(RESET)\n"

iso: kernel $(ISO_FILE)

run: iso
	@printf "\n"
	@printf "$(CYAN)==========================\n"
	@printf "   Running NoOS in QEMU   \n"
	@printf "==========================$(RESET)\n"
	@$(QEMU) -cdrom $(ISO_FILE) -serial stdio -display gtk -m 128M

clean:
	@printf "$(YELLOW)Cleaning...$(RESET)\n"
	@rm -rf $(BUILD_DIR)
	@if command -v cargo &> /dev/null; then cd $(KERNEL_DIR) && $(CARGO) clean; fi
	@printf "$(GREEN)✓ Clean complete$(RESET)\n"

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(KERNEL_BUILD):
	@mkdir -p $(KERNEL_BUILD)

$(ISO_BUILD)/boot/grub:
	@mkdir -p $(ISO_BUILD)/boot/grub

$(MULTIBOOT_OBJ): $(BOOT_DIR)/multiboot_header.asm | $(KERNEL_BUILD)
	@printf "$(YELLOW)→ [1/3] Assembling bootloader...$(RESET)\n"
	@$(NASM) $(NASM_FLAGS) $< -o $@

$(KERNEL_BIN): $(MULTIBOOT_OBJ)
	@printf "$(YELLOW)→ [2/3] Building Rust kernel...$(RESET)\n"
	@cd $(KERNEL_DIR) && $(CARGO) build $(CARGO_FLAGS)
	@printf "$(YELLOW)→ [3/3] Linking kernel...$(RESET)\n"
	@$(LD) $(LD_FLAGS) -o $@ $< $(KERNEL_DIR)/target/x86_64-unknown-none/release/libnoos_kernel.a
	@printf "$(GREEN)✓ Kernel built: $(RESET)$(CYAN)$(KERNEL_BIN)$(RESET)\n"

define check_tool
	@command -v $(1) >/dev/null 2>&1 || { \
		echo "Error: $(1) not found. Please install it (try 'make setup')."; \
		exit 1; \
	}

	@rustup show >/dev/null 2>&1 || { echo "Rust not installed! Run 'make setup'."; exit 1; }
	@rustup toolchain list | grep nightly >/dev/null || { echo "Rust nightly not found! Run 'make setup'."; exit 1; }
	@rustup target list --installed | grep x86_64-unknown-none >/dev/null || { echo "Target 'x86_64-unknown-none' missing! Run 'make setup'."; exit 1; }
endef
