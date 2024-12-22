#!/bin/bash

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Set strict error handling
set -euo pipefail
IFS=$'\n\t'

# Define constants
readonly VERSION="v1.1.8"
readonly MINING_CLI_URL="https://github.com/InternetMaximalism/intmax2-mining-cli/releases/download/${VERSION}/mining-cli-x86_64-unknown-linux-musl.zip"
readonly FOLDER_NAME="intmax-mining"
readonly SCREEN_SESSION="intmax-miner"

# Color definitions
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r BLUE='\033[0;34m'
declare -r CYAN='\033[0;36m'
declare -r RESET='\033[0m'

# Icons/Emojis
declare -r INFO="🛠️"
declare -r CHECK="✅"
declare -r CROSS="❌"

# Helper functions
log_info() {
    echo -e "${CYAN}${INFO} ${YELLOW}$1${RESET}\n"
}

log_success() {
    echo -e "${GREEN}${CHECK} $1${RESET}\n"
}

log_error() {
    echo -e "${RED}${CROSS} $1${RESET}\n"
}

install_package() {
    local package=$1
    if ! command -v "$package" &> /dev/null; then
        log_error "$package not found. Installing $package..."
        sudo apt install "$package" -y
    else
        log_success "$package is already installed."
    fi
}

# Cleanup function
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "An error occurred. Cleaning up..."
        # Add cleanup actions here if needed
    fi
    exit $exit_code
}

# Set cleanup trap
trap cleanup EXIT

# Main installation process
main() {
    # Create and setup directory
    log_info "Creating directory $FOLDER_NAME if it doesn't exist..."
    mkdir -p "$FOLDER_NAME"
    chmod 755 "$FOLDER_NAME"
    cd "$FOLDER_NAME" || exit 1

    # Update system
    log_info "Updating and upgrading system..."
    sudo apt update -y && sudo apt upgrade -y
    log_success "System has been updated."

    # Install required packages
    for package in wget unzip screen; do
        install_package "$package"
    done

    # Download and extract mining-cli
    log_info "Downloading mining-cli..."
    wget -q --show-progress "$MINING_CLI_URL"
    
    log_info "Extracting mining-cli..."
    unzip -o mining-cli-x86_64-unknown-linux-musl.zip
    chmod +x mining-cli
    rm mining-cli-x86_64-unknown-linux-musl.zip

    # Check if screen session already exists
    if screen -list | grep -q "$SCREEN_SESSION"; then
        log_error "Screen session '$SCREEN_SESSION' already exists. Please check existing session or terminate it."
        exit 1
    fi

    # Start mining-cli in screen session
    log_info "Starting mining-cli in screen session '$SCREEN_SESSION'..."
    screen -dm -S "$SCREEN_SESSION" ./mining-cli
    log_success "Mining-cli is running in screen session '$SCREEN_SESSION'"
    
    # Display instructions
    echo -e "\n${CYAN}=== Instructions ===${RESET}"
    echo -e "To attach to the mining session: ${GREEN}screen -r $SCREEN_SESSION${RESET}"
    echo -e "To detach from the session: ${GREEN}Ctrl+A, then press D${RESET}"
    echo -e "To terminate the session: ${GREEN}screen -X -S $SCREEN_SESSION quit${RESET}\n"

    log_info "Created by Layer Airdrop ID. Join us on Telegram: ${BLUE}https://t.me/layerairdrop${RESET}"
}

# Execute main function
main