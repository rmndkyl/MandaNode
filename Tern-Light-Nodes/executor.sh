#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# LOGO
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 2

# Function to print colored text
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Function to display spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to check command status
check_status() {
    if [ $1 -eq 0 ]; then
        print_color "$GREEN" "✓ Success: $2"
    else
        print_color "$RED" "✗ Error: $2"
        exit 1
    fi
}

# Display welcome banner
clear
print_color "$CYAN" "
╔════════════════════════════════════════════╗
║     Welcome to t3rn Executor Setup         ║
║        by Layer Airdrop Team               ║
╚════════════════════════════════════════════╝"

# Initialize workspace
print_color "$YELLOW" "\n[1/6] Initializing workspace..."
cd $HOME
rm -rf executor
sudo apt -q update && sudo apt -qy upgrade &
show_spinner $!
check_status $? "System update completed"

# Download and extract executor
print_color "$YELLOW" "\n[2/6] Downloading Executor binary..."
EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.27.0/executor-linux-v0.27.0.tar.gz"
EXECUTOR_FILE="executor-linux-v0.27.0.tar.gz"

curl -L -o $EXECUTOR_FILE $EXECUTOR_URL
check_status $? "Binary download"

print_color "$YELLOW" "\n[3/6] Extracting binary..."
tar -xzvf $EXECUTOR_FILE
check_status $? "Binary extraction"
rm -rf $EXECUTOR_FILE
cd executor/executor/bin

# Configuration
print_color "$YELLOW" "\n[4/6] Setting up configuration..."

# Node Environment
while true; do
    read -p "$(print_color "$BLUE" "Enter Node Environment (testnet/mainnet) [default: testnet]: ")" NODE_ENV
    NODE_ENV=${NODE_ENV:-testnet}
    if [[ "$NODE_ENV" =~ ^(testnet|mainnet)$ ]]; then
        break
    else
        print_color "$RED" "Invalid input. Please enter 'testnet' or 'mainnet'"
    fi
done
export NODE_ENV=$NODE_ENV

# Log settings
export LOG_LEVEL=debug
export LOG_PRETTY=false
print_color "$GREEN" "Log settings configured: LOG_LEVEL=$LOG_LEVEL, LOG_PRETTY=$LOG_PRETTY"

# Private Key
while true; do
    read -s -p "$(print_color "$BLUE" "Enter your Private Key from Metamask: ")" PRIVATE_KEY_LOCAL
    echo
    if [[ ${#PRIVATE_KEY_LOCAL} -eq 64 || ${#PRIVATE_KEY_LOCAL} -eq 66 ]]; then
        break
    else
        print_color "$RED" "Invalid private key length. Please try again."
    fi
done
export PRIVATE_KEY_LOCAL=$PRIVATE_KEY_LOCAL

# Network Configuration
print_color "$YELLOW" "\n[5/6] Configuring networks..."
read -p "$(print_color "$BLUE" "Enter networks (comma-separated) [default: arbitrum-sepolia,base-sepolia]: ")" ENABLED_NETWORKS
ENABLED_NETWORKS=${ENABLED_NETWORKS:-arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn}
export ENABLED_NETWORKS=$ENABLED_NETWORKS

# RPC Configuration
read -p "$(print_color "$BLUE" "Configure custom RPC URLs? (y/n): ")" SET_RPC
if [[ "$SET_RPC" =~ ^[Yy]$ ]]; then
    for NETWORK in $(echo $ENABLED_NETWORKS | tr "," "\n"); do
        read -p "Enter RPC URLs for $NETWORK (comma-separated): " RPC_URLS
        export EXECUTOR_${NETWORK^^}_RPC_URLS=$RPC_URLS
        print_color "$GREEN" "✓ RPC URLs set for $NETWORK"
    done
else
    print_color "$BLUE" "Using default RPC URLs"
fi

# Start Executor
print_color "$YELLOW" "\n[6/6] Starting Executor..."
print_color "$PURPLE" "\nExecutor initialization complete! Starting service..."
./executor

# Cleanup
rm -f executor.sh
print_color "$GREEN" "\n✨ Setup complete! The Executor is now running."
print_color "$CYAN" "Subscribe: https://t.me/layerairdrop"
