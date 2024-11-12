#!/bin/bash

# Show animation
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Define text formats
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
SUCCESS_COLOR='\033[1;32m'
ERROR_COLOR='\033[1;31m'
INFO_COLOR='\033[1;36m'
MENU_COLOR='\033[1;34m'
HEADER_COLOR='\033[1;35m'
PROMPT_COLOR='\033[1;33m'
RESET_COLOR='\033[0m'

# Custom status display function with colorful borders
show_message() {
    local message="$1"
    local status="$2"
    local border="====================================================="
    case $status in
        "error")
            echo -e "${ERROR_COLOR}${BOLD}$border\n❌ Error: ${message}\n$border${RESET_COLOR}"
            ;;
        "info")
            echo -e "${INFO_COLOR}${BOLD}$border\nℹ️ Info: ${message}\n$border${RESET_COLOR}"
            ;;
        "success")
            echo -e "${SUCCESS_COLOR}${BOLD}$border\n✅ Success: ${message}\n$border${RESET_COLOR}"
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
}

# Display header
echo -e "${HEADER_COLOR}"
echo "===================================="
echo "       Unichain Deployment Script   "
echo "===================================="
echo -e "${RESET_COLOR}"

# Locate script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Install necessary dependencies
install_dependencies() {
    show_message "Checking and installing necessary dependencies..." "info"
    sudo apt update -y && sudo apt install -y curl wget git sudo

    # Check and install Foundry
    if command -v forge &> /dev/null; then
        show_message "Foundry is already installed, skipping." "success"
    else
        show_message "Foundry not found, installing..." "info"
        curl -L https://foundry.paradigm.xyz | bash
        source "source /root/.bashrc"  # Reload bash profile to apply changes

        # Ensure foundryup is in PATH
        export PATH="$HOME/.foundry/bin:$PATH"
        foundryup  # Run foundryup to install Foundry and Forge
        show_message "Foundry installation completed." "success"
    fi

    # Verify if forge is installed correctly
    if ! command -v forge &> /dev/null; then
        show_message "Forge command not found. Please check Foundry installation." "error"
        exit 1
    else
        show_message "Forge is successfully installed." "success"
    fi
}

# Function to deploy an ERC-20 token
deploy_token() {
    show_message "Starting ERC-20 token deployment..." "info"
    install_dependencies

    # Collect multiple private keys from user input
    read -p "Enter your private keys (separate multiple keys with commas): " PRIVATE_KEYS

    # Generate random token name and symbol if not provided
    RANDOM_TOKEN_NAME="Token_$(openssl rand -hex 3 | tr 'a-f' 'A-F')"
    RANDOM_TOKEN_SYMBOL="SYM_$(openssl rand -hex 2 | tr 'a-f' 'A-F')"
    
    # Ask user for token name and symbol, or use random values if left blank
    read -p "Enter token name (or leave blank for random): " TOKEN_NAME
    TOKEN_NAME="${TOKEN_NAME:-$RANDOM_TOKEN_NAME}"
    
    read -p "Enter token symbol (or leave blank for random): " TOKEN_SYMBOL
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-$RANDOM_TOKEN_SYMBOL}"
    
    # Default supply if not provided
    INITIAL_SUPPLY=1000000
    read -p "Enter the initial supply of tokens (default 1000000): " SUPPLY_INPUT
    INITIAL_SUPPLY="${SUPPLY_INPUT:-$INITIAL_SUPPLY}"

    # Create environment configuration file
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOF > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEYS="$PRIVATE_KEYS"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
INITIAL_SUPPLY="$INITIAL_SUPPLY"
EOF

    # Load environment variables
    source "$SCRIPT_DIR/token_deployment/.env"

    # Set the smart contract name
    CONTRACT_NAME="MyTokenContract"

    # Check and install OpenZeppelin contract library
    if [ -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        show_message "OpenZeppelin contract library already installed, skipping." "success"
    else
        show_message "Installing OpenZeppelin contract library..." "info"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
        show_message "OpenZeppelin contract library installation completed." "success"
    fi

    # Create the ERC-20 token smart contract
    show_message "Creating ERC-20 token contract..." "info"
    mkdir -p "$SCRIPT_DIR/src"
    cat <<EOF > "$SCRIPT_DIR/src/$CONTRACT_NAME.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract $CONTRACT_NAME is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, $INITIAL_SUPPLY * (10 ** decimals()));
    }
}
EOF

    # Compile the smart contract
    show_message "Compiling smart contract..." "info"
    forge build

    if [[ $? -ne 0 ]]; then
        show_message "Contract compilation failed." "error"
        exit 1
    fi

    # Deploy the smart contract for each private key
    IFS=',' read -ra KEY_ARRAY <<< "$PRIVATE_KEYS"
    RPC_URL="https://sepolia.unichain.org"

    for PRIVATE_KEY in "${KEY_ARRAY[@]}"; do
        show_message "Deploying smart contract with private key $PRIVATE_KEY..." "info"
        
        DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/$CONTRACT_NAME.sol:$CONTRACT_NAME" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY" \
            --chain-id 1301)

        if [[ $? -ne 0 ]]; then
            show_message "Contract deployment failed for private key $PRIVATE_KEY." "error"
            continue
        fi

        # Display contract address
        CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
        show_message "Token deployed successfully with private key $PRIVATE_KEY, contract address: https://sepolia.uniscan.xyz/address/$CONTRACT_ADDRESS" "success"
    done

    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "${MENU_COLOR}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${RESET_COLOR}"
        echo -e "${HEADER_COLOR}${BOLD}================ Unichain Contract Deployment =================${RESET_COLOR}"
        echo -e "${MENU_COLOR}Node community Telegram channel: https://t.me/layerairdrop${RESET_COLOR}"
        echo -e "${MENU_COLOR}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${RESET_COLOR}"
        echo -e "${PROMPT_COLOR}1. Deploy ERC-20 Token${RESET_COLOR}"
        echo -e "${PROMPT_COLOR}2. Exit${RESET_COLOR}"
        read -p "Enter an option (1-2): " OPTION

        case $OPTION in
            1) deploy_token ;;
            2) exit 0 ;;
            *) show_message "Invalid option, please try again." "error" ;;
        esac
    done
}

# Start main menu
main_menu
