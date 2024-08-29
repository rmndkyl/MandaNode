#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using the 'sudo -i' command, and then run this script again."
    exit 1
fi

# Showing Animation
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Install necessary dependencies
function install_dependencies() {
    apt update && apt upgrade -y
    apt install curl wget jq make gcc nano -y
}

# Install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed, version: $(node -v)"
    else
        echo "Node.js is not installed, installing now..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed, version: $(npm -v)"
    else
        echo "npm is not installed, installing now..."
        sudo apt-get install -y npm
    fi
}

# Install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed, version: $(pm2 -v)"
    else
        echo "PM2 is not installed, installing now..."
        npm install pm2@latest -g
    fi
}

# Install Story Node
function install_story_node() {
    install_dependencies
    install_nodejs_and_npm
    install_pm2  # Ensure PM2 is installed

    echo "Starting Story node installation..."

    # Download the execution client and consensus client
    echo "Downloading the execution client and consensus client..."
    wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.2-ea9f0d2.tar.gz
    wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.9.11-2a25df1.tar.gz

    # Extract the downloaded files
    tar -xzf geth-linux-amd64-0.9.2-ea9f0d2.tar.gz
    tar -xzf story-linux-amd64-0.9.11-2a25df1.tar.gz

    echo "Default data directories are set to:"
    echo "Story data root: ${STORY_DATA_ROOT}"
    echo "Geth data root: ${GETH_DATA_ROOT}"

    # Execution client setup
    echo "Setting up the execution client..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo xattr -rd com.apple.quarantine ./geth
    fi

    # Run the execution client with PM2
    cp /root/geth-linux-amd64-0.9.2-ea9f0d2/geth /usr/local/bin
    pm2 start /usr/local/bin/geth --name story-geth -- --iliad --syncmode full

    # Consensus client setup
    echo "Setting up the consensus client..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo xattr -rd com.apple.quarantine ./story
    fi

    # Initialize the consensus client
    cp /root/story-linux-amd64-0.9.11-2a25df1/story /usr/local/bin
    /usr/local/bin/story init --network iliad

    # Run the consensus client with PM2
    pm2 start /usr/local/bin/story --name story-client -- run

    echo "Story node installation completed!"
}

# Clear state function
function clear_state() {
    echo "Clearing state and reinitializing the node..."
    rm -rf ${GETH_DATA_ROOT} && pm2 start /usr/local/bin/geth --name story-geth -- --iliad --syncmode full
    rm -rf ${STORY_DATA_ROOT} && /usr/local/bin/story init --network iliad && pm2 start /usr/local/bin/story --name story-client -- run
}

# Check node status function
function check_status() {
    echo "Checking Geth status..."
    pm2 logs story-geth
    pm2 logs story-client
}

# Check .env file and read the private key
function check_env_file() {
    if [ -f ".env" ]; then
        # Read the PRIVATE_KEY from the .env file
        source .env
        echo ".env file loaded, private key is: ${PRIVATE_KEY}"
    else
        # If .env file does not exist, prompt the user to input the private key
        read -p "Please enter your ETH wallet private key (without the 0x prefix): " PRIVATE_KEY
        # Create the .env file
        echo "# ~/story/.env" > .env
        echo "PRIVATE_KEY=${PRIVATE_KEY}" >> .env
        echo ".env file has been created, contents are as follows:"
        cat .env
        echo "Please ensure the account has received IP funding (you can refer to the tutorial for funding)."
    fi
}

# Function to set up the validator
function setup_validator() {
    echo "Setting up the validator..."
    # Check .env file and read the private key
    check_env_file

    # Prompt the user to perform validator operations
    echo "You can perform the following validator operations:"
    echo "1. Export validator key"
    echo "2. Create a new validator"
    echo "3. Stake to an existing validator"
    echo "4. Unstake"
    echo "5. Stake on behalf of another delegator"
    echo "6. Unstake on behalf of another delegator"
    echo "7. Add operator"
    echo "8. Remove operator"
    echo "9. Set withdrawal address"
    read -p "Please enter an option (1-9): " OPTION

    case $OPTION in
    1) export_validator_key ;;
    2) create_validator ;;
    3) stake_to_validator ;;
    4) unstake_from_validator ;;
    5) stake_on_behalf ;;
    6) unstake_on_behalf ;;
    7) add_operator ;;
    8) remove_operator ;;
    9) set_withdrawal_address ;;
    *) echo "Invalid option." ;;
    esac
}

# Export validator key
function export_validator_key() {
    echo "Exporting validator key..."
    /usr/local/bin/story validator export
}

# Create a new validator
function create_validator() {
    read -p "Please enter the stake amount (in IP): " AMOUNT_TO_STAKE_IN_IP
    AMOUNT_TO_STAKE_IN_WEI=$((AMOUNT_TO_STAKE_IN_IP * 1000000000000000000))
    /usr/local/bin/story validator create --stake ${AMOUNT_TO_STAKE_IN_WEI}
}

# Stake to an existing validator
function stake_to_validator() {
    read -p "Please enter the validator public key (Base64 format): " VALIDATOR_PUB_KEY_IN_BASE64
    read -p "Please enter the stake amount (in IP): " AMOUNT_TO_STAKE_IN_IP
    AMOUNT_TO_STAKE_IN_WEI=$((AMOUNT_TO_STAKE_IN_IP * 1000000000000000000))
    /usr/local/bin/story validator stake --validator-pubkey ${VALIDATOR_PUB_KEY_IN_BASE64} --stake ${AMOUNT_TO_STAKE_IN_WEI}
}

# Unstake
function unstake_from_validator() {
    read -p "Please enter the validator public key (Base64 format): " VALIDATOR_PUB_KEY_IN_BASE64
    read -p "Please enter the unstake amount (in IP): " AMOUNT_TO_UNSTAKE_IN_IP
    AMOUNT_TO_UNSTAKE_IN_WEI=$((AMOUNT_TO_UNSTAKE_IN_IP * 1000000000000000000))
    /usr/local/bin/story validator unstake --validator-pubkey ${VALIDATOR_PUB_KEY_IN_BASE64} --unstake ${AMOUNT_TO_UNSTAKE_IN_WEI}
}

# Stake on behalf of another delegator
function stake_on_behalf() {
    read -p "Please enter the delegator public key (Base64 format): " DELEGATOR_PUB_KEY_IN_BASE64
    read -p "Please enter the validator public key (Base64 format): " VALIDATOR_PUB_KEY_IN_BASE64
    read -p "Please enter the stake amount (in IP): " AMOUNT_TO_STAKE_IN_IP
    AMOUNT_TO_STAKE_IN_WEI=$((AMOUNT_TO_STAKE_IN_IP * 1000000000000000000))
    /usr/local/bin/story validator stake-on-behalf --delegator-pubkey ${DELEGATOR_PUB_KEY_IN_BASE64} --validator-pubkey ${VALIDATOR_PUB_KEY_IN_BASE64} --stake ${AMOUNT_TO_STAKE_IN_WEI}
}

# Unstake on behalf of another delegator
function unstake_on_behalf() {
    read -p "Please enter the delegator public key (Base64 format): " DELEGATOR_PUB_KEY_IN_BASE64
    read -p "Please enter the validator public key (Base64 format): " VALIDATOR_PUB_KEY_IN_BASE64
    read -p "Please enter the unstake amount (in IP): " AMOUNT_TO_UNSTAKE_IN_IP
    AMOUNT_TO_UNSTAKE_IN_WEI=$((AMOUNT_TO_UNSTAKE_IN_IP * 1000000000000000000))
    /usr/local/bin/story validator unstake-on-behalf --delegator-pubkey ${DELEGATOR_PUB_KEY_IN_BASE64} --validator-pubkey ${VALIDATOR_PUB_KEY_IN_BASE64} --unstake ${AMOUNT_TO_UNSTAKE_IN_WEI}
}

# Add operator
function add_operator() {
    read -p "Please enter the operator's EVM address: " OPERATOR_EVM_ADDRESS
    /usr/local/bin/story validator add-operator --operator ${OPERATOR_EVM_ADDRESS}
}

# Remove operator
function remove_operator() {
    read -p "Please enter the operator's EVM address: " OPERATOR_EVM_ADDRESS
    /usr/local/bin/story validator remove-operator --operator ${OPERATOR_EVM_ADDRESS}
}

# Set withdrawal address
function set_withdrawal_address() {
    read -p "Please enter the new withdrawal address: " NEW_WITHDRAWAL_ADDRESS
    /usr/local/bin/story validator set-withdrawal-address --address ${NEW_WITHDRAWAL_ADDRESS}
}

# Main menu
function main_menu() {
    clear
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Nubit Node Installation ===================================="
    echo "Node community Telegram channel: https://t.me/layerairdrop"
    echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
    echo "Please select an operation to execute:"
    echo "1. Install Story Node"
    echo "2. Clear state and reinitialize"
    echo "3. Check node status"
    echo "4. Set up validator"
    echo "5. Exit"
    read -p "Please enter an option (1-5): " OPTION

    case $OPTION in
    1) install_story_node ;;
    2) clear_state ;;
    3) check_status ;;
    4) setup_validator ;;
    5) exit 0 ;;
    *) echo "Invalid option." ;;
    esac
}

# Display the main menu
check_env_file  # Check .env file before the main menu
main_menu
