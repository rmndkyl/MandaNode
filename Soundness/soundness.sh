#!/bin/bash

# Showing Logo
echo "Showing Logo..."
sudo apt update
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Install necessary dependencies (for Debian/Ubuntu)
sudo apt update
sudo apt install -y pkg-config libssl-dev

# Uninstall existing Rust installation if needed
if command -v rustc &> /dev/null; then
    echo "Existing Rust installation detected. Attempting to uninstall..."
    rustup self uninstall -y
fi

# Non-interactive installation of Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Explicitly source Rust environment variables
source "$HOME/.cargo/env"

# Verify Rust installation
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust/Cargo not installed correctly."
    exit 1
fi

# Debug: Show Rust version
rustc --version
cargo --version

# Install soundnessup with verbose output
echo "Installing soundnessup..."
curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash -x

# Ensure PATH includes Cargo's bin directory
export PATH="$HOME/.cargo/bin:$PATH"

# Debug: Check PATH and look for soundnessup
echo "Current PATH: $PATH"
echo "Searching for soundnessup..."
find / -name soundnessup 2>/dev/null

# Source shell configuration
source "$HOME/.bashrc"
source "$HOME/.cargo/env"

# Verify soundnessup command
if ! command -v soundnessup &> /dev/null; then
    echo "Error: soundnessup command not found, trying manual installation."
    # Manual download and installation attempt
    wget https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/soundnessup
    chmod +x soundnessup
    sudo mv soundnessup /usr/local/bin/
fi

# Retry verification
if ! command -v soundnessup &> /dev/null; then
    echo "Error: soundnessup command still not found."
    exit 1
fi

# Install and update CLI environment
soundnessup install
soundnessup update

# Verify soundness-cli command
if ! command -v soundness-cli &> /dev/null; then
    echo "Error: soundness-cli command not found, please check 'soundnessup install' completion."
    exit 1
fi

# Generate key pair
soundness-cli generate-key --name my-key
