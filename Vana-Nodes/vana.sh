#!/bin/bash

# DLP Validator installation path
DLP_PATH="$HOME/vana-dlp-chatgpt"

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with root privileges."
    echo "Try using 'sudo -i' to switch to the root user, then rerun this script."
    exit 1
fi

# Install necessary dependencies
function install_dependencies() {
    echo "Installing necessary dependencies..."
    apt update && apt upgrade -y
    apt install -y curl wget jq make gcc nano git software-properties-common
}

# Install Python 3.11 and Poetry
function install_python_and_poetry() {
    echo "Installing Python 3.11..."
    add-apt-repository ppa:deadsnakes/ppa -y
    apt update
    apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

    echo "Verifying Python version..."
    python3.11 --version

    echo "Installing Poetry..."
    curl -sSL https://install.python-poetry.org | python3 -

    echo 'export PATH="$HOME/.local/bin:$PATH"' >> $HOME/.bash_profile
    source $HOME/.bash_profile

    echo "Verifying Poetry installation..."
    poetry --version
}

# Install Node.js and npm
function install_nodejs_and_npm() {
    echo "Checking if Node.js is installed..."
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed, version: $(node -v)"
    else
        echo "Node.js is not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi

    echo "Checking if npm is installed..."
    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed, version: $(npm -v)"
    else
        echo "npm is not installed, installing..."
        apt-get install -y npm
    fi
}

# Install PM2
function install_pm2() {
    echo "Checking if PM2 is installed..."
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed, version: $(pm2 -v)"
    else
        echo "PM2 is not installed, installing..."
        npm install pm2@latest -g
    fi
}

# Clone Vana DLP ChatGPT repository and install dependencies
function clone_and_install_repos() {
    echo "Cloning Vana DLP ChatGPT repository..."
    rm -rf $DLP_PATH
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git $DLP_PATH
    cd $DLP_PATH
    cp .env.example .env

    echo "Creating and activating Python virtual environment..."
    python3.11 -m venv myenv
    source myenv/bin/activate

    echo "Installing Poetry dependencies..."
    pip install poetry
    poetry install

    echo "Installing Vana CLI..."
    pip install vana
}

# Create wallet
function create_wallet() {
    echo "Creating wallet..."
    vanacli wallet create --wallet.name default --wallet.hotkey default

    echo "Please ensure that you have added the Vana Moksha Testnet network in MetaMask."
    echo "Follow these manual steps:"
    echo "1. RPC URL: https://rpc.moksha.vana.org"
    echo "2. Chain ID: 14800"
    echo "3. Network name: Vana Moksha Testnet"
    echo "4. Currency: VANA"
    echo "5. Block Explorer: https://moksha.vanascan.io"
}

# Export private keys
function export_private_keys() {
    echo "Exporting Coldkey private key..."
    ./vanacli wallet export_private_key --wallet.name default --wallet.coldkey default

    echo "Exporting Hotkey private key..."
    ./vanacli wallet export_private_key --wallet.name default --wallet.hotkey default

    # Confirm backup
    read -p "Have you backed up your private keys? (y/n) " backup_confirmed
    if [ "$backup_confirmed" != "y" ]; then
        echo "Please back up your mnemonic before continuing with the script."
        exit 1
    fi
}

# Generate encryption keys
function generate_encryption_keys() {
    echo "Generating encryption keys..."
    cd $DLP_PATH
    ./keygen.sh
}

# Write the public key to the .env file
function write_public_key_to_env() {
    PUBLIC_KEY_FILE="$DLP_PATH/public_key_base64.asc"
    ENV_FILE="$DLP_PATH/.env"

    # Check if the public key file exists
    if [ ! -f "$PUBLIC_KEY_FILE" ]; then
        echo "Public key file does not exist: $PUBLIC_KEY_FILE"
        exit 1
    fi

    # Read the public key content
    PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

    # Write the public key to the .env file
    echo "PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64=\"$PUBLIC_KEY\"" >> "$ENV_FILE"

    echo "Public key successfully written to the .env file."
}

# Deploy DLP smart contract
function deploy_smart_contracts() {
    echo "Cloning the DLP smart contract repository..."
    cd $HOME
    rm -rf vana-dlp-smart-contracts
    git clone https://github.com/Josephtran102/vana-dlp-smart-contracts
    cd vana-dlp-smart-contracts

    echo "Installing Yarn..."
    npm install -g yarn
    echo "Verifying Yarn version..."
    yarn --version

    echo "Installing smart contract dependencies..."
    yarn install

    echo "Copy and edit the .env file..."
    cp .env.example .env
    nano .env  # Manually edit the .env file, filling in contract-related information

    echo "Deploying smart contract to the Moksha testnet..."
    npx hardhat deploy --network moksha --tags DLPDeploy
}

# Register the validator
function register_validator() {
    cd $HOME
    cd vana-dlp-chatgpt
    echo "Registering the validator..."
    ./vanacli dlp register_validator --stake_amount 10

    # Get Hotkey address
    read -p "Please enter your Hotkey wallet address: " HOTKEY_ADDRESS

    echo "Approving the validator..."
    ./vanacli dlp approve_validator --validator_address="$HOTKEY_ADDRESS"
}

# Create .env file
function create_env_file() {
    echo "Creating .env file..."
    read -p "Enter the DLP contract address: " DLP_CONTRACT
    read -p "Enter the DLP Token contract address: " DLP_TOKEN_CONTRACT
    read -p "Enter the OpenAI API Key: " OPENAI_API_KEY

    cat <<EOF > $DLP_PATH/.env
# The network to use, currently Vana Moksha testnet
OD_CHAIN_NETWORK=moksha
OD_CHAIN_NETWORK_ENDPOINT=https://rpc.moksha.vana.org

# Optional: OpenAI API key for additional data quality check
OPENAI_API_KEY="$OPENAI_API_KEY"

# Optional: Your own DLP smart contract address once deployed to the network, useful for local testing
DLP_MOKSHA_CONTRACT="$DLP_CONTRACT"

# Optional: Your own DLP token contract address once deployed to the network, useful for local testing
DLP_TOKEN_MOKSHA_CONTRACT="$DLP_TOKEN_CONTRACT"
EOF
}

# Create PM2 config file
function create_pm2_config() {
    echo "Creating PM2 config file..."
    cat <<EOF > $DLP_PATH/ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'vana-validator',
      script: '$HOME/.local/bin/poetry',
      args: 'run python -m chatgpt.nodes.validator',
      cwd: '$DLP_PATH',
      interpreter: 'none', // Specify "none" to avoid PM2 using the default Node.js interpreter
      env: {
        PATH: '/root/.local/bin:/usr/local/bin:/usr/bin:/bin:/root/vana-dlp-chatgpt/myenv/bin',
        PYTHONPATH: '/root/vana-dlp-chatgpt',
        OD_CHAIN_NETWORK: 'moksha',
        OD_CHAIN_NETWORK_ENDPOINT: 'https://rpc.moksha.vana.org',
        OPENAI_API_KEY: '$OPENAI_API_KEY',
        DLP_MOKSHA_CONTRACT: '$DLP_CONTRACT',
        DLP_TOKEN_MOKSHA_CONTRACT: '$DLP_TOKEN_CONTRACT',
        PRIVATE_FILE_ENCRYPTION_PUBLIC_KEY_BASE64: '$PUBLIC_KEY'
      },
      restart_delay: 10000, // Restart delay in milliseconds
      max_restarts: 10, // Maximum number of restarts
      autorestart: true,
      watch: false,
      // Additional configurations can be added as needed
    },
  ],
};
EOF
}

# Start DLP Validator node using PM2
function start_validator() {
    echo "Starting DLP Validator node using PM2..."
    pm2 start $DLP_PATH/ecosystem.config.js

    echo "Setting PM2 to start on boot..."
    pm2 startup systemd -u root --hp /root
    pm2 save

    echo "DLP Validator node started. You can view logs using 'pm2 logs vana-validator'."
}

# Install DLP Validator node
function install_dlp_node() {
    install_dependencies
    install_python_and_poetry
    install_nodejs_and_npm
    install_pm2
    clone_and_install_repos
    create_wallet
    export_private_keys
    generate_encryption_keys
    write_public_key_to_env 
    deploy_smart_contracts
    create_env_file
    register_validator
    create_pm2_config
    start_validator
}

# View node logs
function check_node() {
    pm2 logs vana-validator
}

# Uninstall node
function uninstall_node() {
    echo "Uninstalling DLP Validator node..."
    pm2 delete vana-validator
    rm -rf $DLP_PATH
    echo "DLP Validator node has been removed."
}

# Main menu
function main_menu() {
    clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Vana Node Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "Please choose an action:"
    echo "1. Install DLP Validator node"
    echo "2. View node logs"
    echo "3. Delete node"
    read -p "Please enter your option (1-3): " OPTION
    case $OPTION in
    1) install_dlp_node ;;
    2) check_node ;;
    3) uninstall_node ;;
    *) echo "Invalid option." ;;
    esac
}

# Show main menu
main_menu
