#!/bin/bash

# Showing Logo
echo "Showing Logo..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Install necessary dependencies (for Debian/Ubuntu)
apt update
apt install -y pkg-config libssl-dev

# Non-interactive installation of Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Load Rust environment variables
source "$HOME/.cargo/env"

# Verify Rust installation
if ! command -v cargo &> /dev/null; then
echo "Error: Rust/Cargo not installed correctly."
exit 1
fi

# Install soundnessup
curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash

# Ensure PATH includes Cargo's bin directory
export PATH="$HOME/.cargo/bin:$PATH"

# Debug: Check PATH and binary
echo "Current PATH: $PATH"
ls -l "$HOME/.cargo/bin/soundnessup" || echo "Warning: soundnessup binary not found."

# Verify soundnessup command
if ! command -v soundnessup &> /dev/null; then
echo "Error: soundnessup command not found, please check installation."
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