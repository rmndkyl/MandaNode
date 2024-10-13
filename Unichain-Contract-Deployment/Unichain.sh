#!/bin/bash

# Define text formats
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
SUCCESS_COLOR='\033[1;32m'
ERROR_COLOR='\033[1;31m'
INFO_COLOR='\033[1;36m'
MENU_COLOR='\033[1;34m'

# Custom status display function
show_message() {
    local message="$1"
    local status="$2"
    case $status in
        "error")
            echo -e "${ERROR_COLOR}${BOLD}❌ Error: ${message}${NORMAL}"
            ;;
        "info")
            echo -e "${INFO_COLOR}${BOLD}ℹ️ Info: ${message}${NORMAL}"
            ;;
        "success")
            echo -e "${SUCCESS_COLOR}${BOLD}✅ Success: ${message}${NORMAL}"
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
}

# Locate script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Install necessary dependencies
install_dependencies() {
    show_message "Checking and installing necessary dependencies..." "info"
    apt update -y && apt install -y curl wget git

    # Check and install Foundry
    if command -v forge &> /dev/null; then
        show_message "Foundry is already installed, skipping." "success"
    else
        show_message "Foundry not found, installing..." "info"
        curl -L https://foundry.paradigm.xyz | bash
        source ~/.bashrc
        foundryup
        show_message "Foundry installation completed." "success"
    fi
}

# Function to deploy an ERC-20 token
deploy_token() {
    show_message "Starting ERC-20 token deployment..." "info"
    install_dependencies

    # Collect user input
    read -p "Enter your private key: " PRIVATE_KEY
    read -p "Enter token name (e.g., MyToken): " TOKEN_NAME
    read -p "Enter token symbol (e.g., MTK): " TOKEN_SYMBOL
    read -p "Enter the initial supply of tokens (e.g., 1000000): " INITIAL_SUPPLY

    # Create environment configuration file
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOF > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
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

    # Deploy the smart contract
    show_message "Deploying smart contract..." "info"

    # Use the Unichain Sepolia testnet's RPC URL
    RPC_URL="https://sepolia.unichain.org"

    DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/$CONTRACT_NAME.sol:$CONTRACT_NAME" \
        --rpc-url "$RPC_URL" \
        --private-key "$PRIVATE_KEY" \
        --chain-id 1301)

    if [[ $? -ne 0 ]]; then
        show_message "Contract deployment failed." "error"
        exit 1
    fi

    # Display contract address
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
    show_message "Token deployed successfully, contract address: https://sepolia.uniscan.xyz/address/$CONTRACT_ADDRESS" "success"

    read -n 1 -s -r -p "Press any key to return to the main menu..."
    main_menu
}

# Main menu
main_menu() {
    while true; do
        clear
        echo -e "{MENU_COLOR}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${NORMAL}"
	    echo -e "${MENU_COLOR}${BOLD}============================ Unichain Contract Deployment ====================================${NORMAL}"
	    echo -e "{MENU_COLOR}Node community Telegram channel: https://t.me/layerairdrop${NORMAL}p"
	    echo -e "{MENU_COLOR}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${NORMAL}"
        echo -e "${MENU_COLOR}1. Deploy ERC-20 Token${NORMAL}"
        echo -e "${MENU_COLOR}2. Exit${NORMAL}"
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
