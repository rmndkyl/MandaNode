#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Display a logo
echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -f loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -f logo.sh
sleep 4

# Print start message
echo "Starting installation of dependencies and Nexus script..."

# Install necessary system dependencies (including OpenSSL, pkg-config, and gcc)
echo "Installing necessary system dependencies..."
sudo apt update
sudo apt install -y libssl-dev pkg-config gcc

# Install the latest Protocol Buffers
echo "Installing the latest protobuf..."
sudo apt remove -y protobuf-compiler  # Remove any existing version
wget https://github.com/protocolbuffers/protobuf/releases/download/v25.3/protoc-25.3-linux-x86_64.zip
unzip protoc-25.3-linux-x86_64.zip -d /usr/local
sudo ln -sf /usr/local/bin/protoc /usr/bin/protoc
protoc --version  # Verify installation

# Restart critical services
echo "Restarting affected services..."
sudo systemctl restart ssh.service
sudo systemctl restart systemd-journald.service
sudo systemctl restart systemd-logind.service
sudo systemctl restart systemd-resolved.service
sudo systemctl restart systemd-timesyncd.service

# Install Rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Source cargo environment variables
source "$HOME/.cargo/env"
# Add riscv32i target
rustup target add riscv32i-unknown-none-elf

# Prompt user to enter Node ID and save it
echo "Please enter Node ID:"
read NODE_ID
mkdir -p ~/.nexus
echo "$NODE_ID" > ~/.nexus/node-id

# Install Nexus script
echo "Installing Nexus script..."
curl https://cli.nexus.xyz | sh

echo "Installation complete! Please follow the instructions to configure the Node ID."

# Keep the terminal open to allow the user to continue
exec $SHELL
