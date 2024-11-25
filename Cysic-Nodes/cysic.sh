#!/bin/bash

# Cysic Node Installation Path
CYSIC_PATH="$HOME/cysic-verifier"

# Color definitions
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Function to display a success message
function success_msg() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

# Function to display a warning message
function warning_msg() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

# Function to display an error message
function error_msg() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# Function to display an informational message
function info_msg() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

# Check if the script is running as root
function check_root() {
    if [ "$(id -u)" != "0" ]; then
        error_msg "This script must be run as root."
        echo "Try using the 'sudo -i' command to switch to the root user, then run this script again."
        exit 1
    fi
}

# Show animations
function show_animation_and_logo() {
    info_msg "Showing animation..."
    wget -q -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
    rm -f loader.sh
    wget -q -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
    rm -f logo.sh
    sleep 4
}

# Install necessary dependencies
function install_dependencies() {
    info_msg "Installing necessary dependencies..."
    apt update && apt upgrade -y
    apt install -y curl wget jq make gcc nano || error_msg "Failed to install some dependencies."
    success_msg "Dependencies installed successfully."
}

# Install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        success_msg "Node.js is already installed, version: $(node -v)"
    else
        info_msg "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs || error_msg "Failed to install Node.js."
    fi
    if command -v npm > /dev/null 2>&1; then
        success_msg "npm is already installed, version: $(npm -v)"
    else
        info_msg "Installing npm..."
        apt install -y npm || error_msg "Failed to install npm."
    fi
}

# Install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        success_msg "PM2 is already installed, version: $(pm2 -v)"
    else
        info_msg "Installing PM2..."
        npm install pm2@latest -g || error_msg "Failed to install PM2."
    fi
}

# Input validation for wallet address
function validate_address() {
    if [[ $1 =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Install Cysic verifier node
function install_cysic_node() {
    install_dependencies
    install_nodejs_and_npm
    install_pm2

    # Create the Cysic verifier directory
    rm -rf "$CYSIC_PATH"
    mkdir -p "$CYSIC_PATH"
    cd "$CYSIC_PATH"

    # Download verifier files
    info_msg "Downloading verifier files..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_linux -o verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.so -o libzkp.so
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_mac -o verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.dylib -o libzkp.dylib
    else
        error_msg "Unsupported operating system."
        exit 1
    fi

    # Set permissions
    chmod +x verifier

    # Create configuration file
    while true; do
        read -p "Enter your reward claim address (ERC-20, ETH wallet address): " CLAIM_REWARD_ADDRESS
        if validate_address "$CLAIM_REWARD_ADDRESS"; then
            break
        else
            warning_msg "Invalid address. Please try again."
        fi
    done

    cat <<EOF > config.yaml
chain:
  endpoint: "testnet-node-1.prover.xyz:9090"
  chain_id: "cysicmint_9000-1"
  gas_coin: "cysic"
  gas_price: 10
claim_reward_address: "$CLAIM_REWARD_ADDRESS"

server:
  cysic_endpoint: "https://api-testnet.prover.xyz"
EOF

    success_msg "Configuration file created successfully."

    # Start the verifier node using PM2
    pm2 start ./verifier --name "cysic-verifier"
    success_msg "Cysic verifier node has been started. Use 'pm2 logs cysic-verifier' to view logs."
}

# Main Menu
function main_menu() {
    clear
    echo -e "${CYAN}============================ Cysic Verifier Node Installation ====================================${RESET}"
    echo -e "${CYAN}Node Community Telegram:${RESET} https://t.me/layerairdrop"
    echo -e "${CYAN}Node Discussion Group:${RESET} https://t.me/layerairdropdiskusi"
    echo "1. Install Cysic 1.0 Verifier Node"
    echo "2. View Node Logs"
    echo "3. Remove Node"
    echo "4. Exit"
    read -p "Enter your choice: " OPTION
    case $OPTION in
    1) install_cysic_node ;;
    2) pm2 logs cysic-verifier ;;
    3) pm2 delete cysic-verifier && rm -rf "$CYSIC_PATH" && success_msg "Cysic verifier node removed." ;;
    4) exit ;;
    *) warning_msg "Invalid option. Please try again." ;;
    esac
}

# Run script
check_root
show_animation_and_logo
main_menu
