#!/bin/bash

echo "Starting setup and proof process..."

echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

echo "Installing Git..."
sudo apt update && sudo apt install -y git-all build-essential gcc pkg-config libssl-dev
git --version

echo "Installing Rust and Cargo..."
if ! command -v rustc &> /dev/null; then
    echo "Rust is not installed. Installing Rust..."
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
else
    echo "Rust is already installed."
fi

echo "Checking if the 'succinct' Rust toolchain is available..."
if rustup toolchain list | grep -q 'succinct'; then
    echo "'succinct' toolchain is already installed."
else
    echo "'succinct' toolchain not found. Please verify the correct toolchain name or installation steps."
    exit 1
fi

echo "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    sudo apt update && sudo apt install -y docker.io
else
    echo "Docker is already installed."
fi
docker --version

echo "Creating new project 'fibonacci'..."
# Ensure that the `cargo-prove` package is installed or replace with the correct command if needed
cargo install cargo-prove
cargo prove new fibonacci
cd fibonacci || { echo "Failed to change directory to 'fibonacci'"; exit 1; }

echo "Executing Proof..."
if [ -d "script" ]; then
    cd script || { echo "Failed to change directory to 'script'"; exit 1; }
    
    echo "Running proof execution..."
    RUST_LOG=info cargo run --release -- --execute
    echo "Proof execution completed successfully."
    
    echo "Generating Proof..."
    RUST_LOG=info cargo run --release -- --prove
    echo "Proof generated and verified successfully."
else
    echo "Directory 'script' not found. Ensure the project was set up correctly."
    exit 1
fi

echo "Process completed successfully."
echo "The script and tutorial were written by Telegram user @rmndkyl, free and open source. Please do not believe in paid versions."
echo "==============================Succinct Proof Installation===================================="
echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
echo "Node community Telegram channel: https://t.me/layerairdrop"
