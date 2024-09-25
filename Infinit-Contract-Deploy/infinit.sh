#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/infinit.sh"

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Main menu function
function main_menu() {
    while true; do
        clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Infinit Contract Deployment ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl+c"
        echo "Please select an action to perform:"
        echo "1) Deploy Contract"
        echo "2) Exit"

        read -p "Enter your choice: " choice

        case $choice in
            1)
                deploy_contract
                ;;
            2)
                echo "Exiting script..."
                exit 0
                ;;
            *)
                echo "Invalid choice, please try again"
                ;;
        esac
        read -n 1 -s -r -p "Press any key to continue..."
    done
}

# Check and install command
function check_install() {
    command -v "$1" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "$1 is not installed, installing..."
        eval "$2"
    else
        echo "$1 is already installed"
    fi
}

# Deploy Contract
function deploy_contract() {
    export NVM_DIR="$HOME/.nvm"
    
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        source "$NVM_DIR/nvm.sh"
    fi

    # Check and install Node.js
    if ! command -v node &> /dev/null; then
        nvm install 22
        nvm alias default 22
        nvm use default
    fi

    # Check and install Bun
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        source "$HOME/.bashrc"  # Ensure environment variables are loaded
        export PATH="$HOME/.bun/bin:$PATH"  # Update PATH
    fi

    # Check if Bun exists
    if ! command -v bun &> /dev/null; then
        echo "Bun is not installed, installation may have failed, please check the installation steps"
        exit 1
    fi

    # Set up Bun project
    mkdir -p infinit && cd infinit || exit
    bun init -y
    bun add @infinit-xyz/cli

    echo "Initializing Infinit CLI and generating account..."
    bunx infinit init
    bunx infinit account generate
    echo

    read -p "What is your wallet address (enter the address from the steps above): " WALLET
    echo
    read -p "What is your account ID (enter the ID from the steps above): " ACCOUNT_ID
    echo

    echo "Copy this private key and save it somewhere, this is the private key for this wallet"
    echo
    bunx infinit account export $ACCOUNT_ID

    sleep 5
    echo
    # Remove old deployUniswapV3Action script if exists
    rm -rf src/scripts/deployUniswapV3Action.script.ts

    cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Replace with actual params
const params: Param = {
  // Native currency label (e.g., ETH)
  "nativeCurrencyLabel": 'ETH',

  // Address of the owner of the proxy admin
  "proxyAdminOwner": '$WALLET',

  // Address of the owner of factory
  "factoryOwner": '$WALLET',

  // Address of the wrapped native token (e.g., WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Signer configuration
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

    echo "Executing UniswapV3 Action script..."
    bunx infinit script execute deployUniswapV3Action.script.ts

    read -p "Press any key to return to the main menu..."
}

# Start main menu
main_menu
