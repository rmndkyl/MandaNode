#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Success message function
success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Info message function
info_msg() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Warning message function
warning_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    handle_error "This script must be run as root. Please use sudo ./install_nexus.sh"
fi

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        success_msg "$1"
    else
        handle_error "$2"
    fi
}

# Create necessary directories
mkdir -p ~/.nexus || handle_error "Failed to create .nexus directory"

# Display logo with enhanced visuals
echo -e "${PURPLE}=================================${NC}"
info_msg "Initializing Nexus Installation..."
echo -e "${PURPLE}=================================${NC}"

# Download and execute loader animation
info_msg "Loading animation..."
wget -q -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && \
chmod +x loader.sh && \
sed -i 's/\r$//' loader.sh && \
./loader.sh
check_status "Animation loaded successfully" "Failed to load animation"
rm -rf loader.sh

# Download and execute logo
wget -q -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && \
chmod +x logo.sh && \
sed -i 's/\r$//' logo.sh && \
./logo.sh
rm -rf logo.sh
sleep 2

# Update system packages
info_msg "Updating system packages..."
sudo apt update && sudo apt upgrade -y
check_status "System packages updated successfully" "Failed to update system packages"

# Install required packages
declare -a packages=("protobuf-compiler" "libssl-dev" "pkg-config" "openssl" "build-essential")

for package in "${packages[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package"; then
        info_msg "Installing $package..."
        sudo apt install -y "$package"
        check_status "$package installed successfully" "Failed to install $package"
    else
        success_msg "$package is already installed"
    fi
done

# Install Rust and Cargo with comprehensive checks
info_msg "Checking Rust and Cargo installation..."
if ! command -v cargo &> /dev/null; then
    warning_msg "Cargo not found. Installing Rust and Cargo..."
    # Check for build-essential again before Rust installation
    if ! dpkg -l | grep -q "^ii  build-essential"; then
        info_msg "Installing build-essential..."
        sudo apt install -y build-essential
        check_status "build-essential installed successfully" "Failed to install build-essential"
    fi

    # Rust installation with non-interactive mode and default options
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source Rust environment
    source $HOME/.cargo/env
    
    # Verify Rust installation
    if command -v cargo &> /dev/null; then
        success_msg "Rust and Cargo installed successfully"
    else
        handle_error "Failed to install Rust and Cargo"
    fi
else
    success_msg "Cargo is already installed"
fi

# Prover ID setup with validation
while true; do
    echo -e "${BLUE}Please enter your Prover ID:${NC} "
    read -r PROVER_ID
    
    # Basic validation - check if input is not empty and contains only alphanumeric characters
    if [[ -z "$PROVER_ID" ]]; then
        warning_msg "Prover ID cannot be empty. Please try again."
        continue
    elif ! [[ "$PROVER_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        warning_msg "Prover ID contains invalid characters. Please use only letters, numbers, underscores, and hyphens."
        continue
    fi
    
    echo "$PROVER_ID" > ~/.nexus/prover-id
    success_msg "Prover ID saved successfully"
    break
done

# Install Nexus CLI
info_msg "Installing Nexus CLI..."
curl -sSf https://cli.nexus.xyz/ | sh
check_status "Nexus CLI installed successfully" "Failed to install Nexus CLI"

echo -e "\n${PURPLE}=================================${NC}"
success_msg "Installation completed successfully!"
echo -e "${PURPLE}=================================${NC}"

# Display next steps
echo -e "\n${CYAN}Next steps:${NC}"
echo -e "1. Run ${GREEN}'source ~/.bashrc'${NC} to update your environment"
echo -e "2. Verify installation with ${GREEN}'nexus --version'${NC}"
echo -e "3. Configure your settings using ${GREEN}'nexus config'${NC}\n"
