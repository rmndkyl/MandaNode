#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && ./loader.sh
curl -s https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh | bash
sleep 2

print_message() {
  echo "--------------------------------------------------"
  echo "$1"
  echo "--------------------------------------------------"
}

print_message "Updating package list and installing CMake"
sudo apt update
sudo apt install -y cmake

print_message "Installing build-essential"
sudo apt install -y build-essential

print_message "Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

print_message "Adding RISC-V target for Rust"
rustup target add riscv32i-unknown-none-elf

print_message "Installing Nexus zkVM"
cargo install --git https://github.com/nexus-xyz/nexus-zkvm cargo-nexus --tag 'v0.2.0'

print_message "Creating a new Nexus project"
cargo nexus new nexus-project

print_message "Editing the main.rs file"
cd nexus-project/src

cat > main.rs <<EOL
#![cfg_attr(target_arch = "riscv32", no_std, no_main)]

fn fib(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _ => fib(n - 1) + fib(n - 2),
    }
}

#[nexus_rt::main]
fn main() {
    let n = 7;
    let result = fib(n);
    assert_eq!(result, 13);
}
EOL

print_message "Running your program"
cd ..
cargo nexus run

print_message "Running your program with verbose output"
cargo nexus run -v

print_message "Generating a proof for your program"
cargo nexus prove

print_message "Verifying the proof"
cargo nexus verify

print_message "The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version"
print_message "==============================Nexus zkVM setup and execution complete!===================================="
print_message "Node community Telegram channel: https://t.me/layerairdrop"
print_message "Node community Telegram group: https://t.me/layerairdropdiskusi"
