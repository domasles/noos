use heapless::{String as ArrayString, Vec};

use crate::drivers::vga::_backspace;

pub struct Shell {
    buffer: ArrayString<256>,
}

impl Shell {
    pub const fn new() -> Self {
        Shell { buffer: ArrayString::new() }
    }

    pub fn handle_char(&mut self, c: char) {
        match c {
            '\n' => self.execute_command(),
            '\u{8}' => self.handle_backspace(),
            c if c.is_ascii() && !c.is_control() => self.insert_char(c),
            _ => {}  // Ignore other special characters
        }
    }

    fn insert_char(&mut self, c: char) {
        if self.buffer.push(c).is_ok() { crate::print!("{}", c); }
    }

    fn handle_backspace(&mut self) {
        if self.buffer.pop().is_some() { _backspace(); }
    }

    fn execute_command(&mut self) {
        crate::println!();
        let input = self.buffer.trim();

        if !input.is_empty() {
            if let Some(cmd) = Command::parse(input) { execute(&cmd); }
        }

        // Reset buffer and show new prompt
        self.buffer.clear();
        self.show_prompt();
    }

    /// Display the shell prompt
    pub fn show_prompt(&self) {
        crate::print!("> ");
    }
}

// Represents a parsed command with program name and arguments
pub struct Command<'a> {
    pub program: &'a str,
    pub args: Vec<&'a str, 16>,
}

impl<'a> Command<'a> {
    // Parse input string into command and arguments
    pub fn parse(input: &'a str) -> Option<Self> {
        let mut parts = input.split_whitespace();
        let program = parts.next()?;
        let mut args = Vec::new();

        for arg in parts {
            args.push(arg).ok()?;  // Return None if exceeding capacity
        }

        Some(Command { program, args })
    }
}

fn execute(cmd: &Command) {
    // For now, always report "command not found"
    crate::println!("Command not found: {}", cmd.program);
}
