#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/vana.sh"

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Function to install Git
function install_git() {
    if ! git --version &> /dev/null; then
        echo "Git is not installed. Installing Git..."
        sudo apt update && sudo apt install -y git
    else
        echo "Git is installed: $(git --version)"
    fi
}

# Function to install Python
function install_python() {
    if ! python3 --version &> /dev/null; then
        echo "Python is not installed. Installing Python..."
        sudo apt update && sudo apt install -y python3 python3-pip
    fi
}

# Function to install Node.js and npm
function install_node() {
    if ! node --version &> /dev/null; then
        echo "Node.js is not installed. Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs
    fi

    if ! npm --version &> /dev/null; then
        echo "npm is not installed. Installing npm..."
        sudo apt install -y npm
    fi
}

# Function to install nvm
function install_nvm() {
    if ! command -v nvm &> /dev/null; then
        echo "nvm is not installed. Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
}

# Function to use Node.js 18
function use_node_18() {
    nvm install 18
    nvm use 18
}

# Function to clone Git repository and enter the directory
function clone_and_enter_repo() {
    echo "Cloning repository vana-dlp-chatgpt..."
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git
    cd vana-dlp-chatgpt || { echo "Unable to enter directory, script terminated"; exit 1; }
}

# Function to install project dependencies
function install_dependencies() {
    cp .env.example .env
    echo "Installing vana with pip..."
    apt install python3-pip
    pip3 install vana || { echo "Dependency installation failed, script terminated"; exit 1; }
}

# Function to run key generation
function run_keygen() {
    echo "Creating default wallet..."
    vanacli wallet create --wallet.name default --wallet.hotkey default

    echo "Running key generation..."
    ./keygen.sh
    echo "Please enter your name, email, and key duration."
}

# Function to deploy the DLP smart contract
function deploy_dlp_contract() {
    cd .. || { echo "Unable to return to the previous directory, script terminated"; exit 1; }
    echo "Cloning DLP smart contract repository..."
    git clone https://github.com/vana-com/vana-dlp-smart-contracts.git
    cd vana-dlp-smart-contracts || { echo "Unable to enter directory, script terminated"; exit 1; }

    echo "Installing dependencies..."
    sudo apt install -y cmdtest
    npm install --global yarn

    # Prompt user to input information and import it into the .env file
    read -p "Please enter your cold key private key (DEPLOYER_PRIVATE_KEY=0x...): " deployer_private_key
    read -p "Please enter your cold key address (OWNER_ADDRESS=0x...): " owner_address
    read -p "Please enter DLP name (DLP_NAME=...): " dlp_name
    read -p "Please enter DLP token name (DLP_TOKEN_NAME=...): " dlp_token_name
    read -p "Please enter DLP token symbol (DLP_TOKEN_SYMBOL=...): " dlp_token_symbol

    # Import into the .env file
    echo "DEPLOYER_PRIVATE_KEY=${deployer_private_key}" >> .env
    echo "OWNER_ADDRESS=${owner_address}" >> .env
    echo "DLP_NAME=${dlp_name}" >> .env
    echo "DLP_TOKEN_NAME=${dlp_token_name}" >> .env
    echo "DLP_TOKEN_SYMBOL=${dlp_token_symbol}" >> .env

    echo "Information has been saved to the .env file."
}

# Initialize npm and install Hardhat function
function setup_hardhat() {
    npm init -y
    npm install --save-dev hardhat
    nvm install 18
    nvm use 18
    npm install --save-dev hardhat
    npx hardhat

    # Prompt user to input cold key private key
    read -p "Please enter your cold key private key to configure accounts: [\"0xYourColdKeyPrivateKey\"]: " cold_key

    # Update hardhat.config.js file
    echo "module.exports = {
        solidity: \"^0.8.0\",
        networks: {
            hardhat: {
                accounts: [\"$cold_key\"]
            }
        }
    };" > hardhat.config.js

    echo "Hardhat configuration is complete."
}

# Deploy contract and prompt user to save addresses function
function deploy_and_save_addresses() {
    echo "Deploying contract..."
    npx hardhat deploy --network satori --tags DLPDeploy

    echo "Please save the deployment addresses of DataLiquidityPool and DataLiquidityPoolToken."
    echo "Press any key to return to the main menu..."
    read -n 1 -s
}

# Start validator node function
function start_validator_node() {
    cd ~/vana-dlp-chatgpt || { echo "Unable to enter directory, script terminated"; exit 1; }

    read -rp "Please enter DataLiquidityPool address (DLP_SATORI_CONTRACT=0x...): " dlp_satori_contract
    read -rp "Please enter DataLiquidityPoolToken address (DLP_TOKEN_SATORI_CONTRACT=0x...): " dlp_token_satori_contract
    read -rp "Please enter Wallet Public Key (PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64): " public_key

    # Add to .env file
    echo "DLP_SATORI_CONTRACT=${dlp_satori_contract}" >> .env
    echo "DLP_TOKEN_SATORI_CONTRACT=${dlp_token_satori_contract}" >> .env
    echo "PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64=${public_key}" >> .env

    echo "Installing Poetry..."
    sudo apt install -y python3-poetry

    echo "Registering validator node..."
    ./vanacli dlp register_validator --stake_amount 10

    echo "Starting validator node..."
    poetry run python -m chatgpt.nodes.validator

    echo "Validator node configuration is complete."
    echo "Press any key to return to the main menu..."
    read -n 1 -s
}

# Deploy environment function
function deploy_environment() {
    install_git
    install_python
    install_node
    install_nvm
    use_node_18
    clone_and_enter_repo
    install_dependencies
    run_keygen
    deploy_dlp_contract
    setup_hardhat
    deploy_and_save_addresses
}

# Main menu function
function main_menu() {
    while true; do
        clear
		echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
		echo "============================ Vana Node Installation ===================================="
		echo "Node community Telegram channel: https://t.me/layerairdrop"
		echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press Ctrl+C on the keyboard"
        echo "Please select the operation to perform:"
        echo "1) Deploy environment"
        echo "2) Start validator node"
        echo "0) Exit"
        echo "================================================================"
        read -rp "Enter your choice: " choice

        case $choice in
            1)
                deploy_environment
                ;;
            2)
                start_validator_node
                ;;
            0)
                echo "Exiting script"
                exit 0
                ;;
            *)
                echo "Invalid choice, please enter again"
                ;;
        esac
    done
}

# Start main menu
main_menu