#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Cysic Node Installation Path
CYSIC_PATH="$HOME/cysic-verifier"

# Check if script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root."
    echo "Please try using 'sudo -i' to switch to the root user, then run this script again."
    exit 1
fi

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
        echo "Node.js is not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed, version: $(npm -v)"
    else
        echo "npm is not installed, installing..."
        sudo apt-get install -y npm
    fi
}

# Install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed, version: $(pm2 -v)"
    else
        echo "PM2 is not installed, installing..."
        npm install pm2@latest -g
    fi
}

# Install Cysic Verifier Node
function install_cysic_node() {
    install_dependencies
    install_nodejs_and_npm
    install_pm2
    
    # Create Cysic verifier directory
    rm -rf $CYSIC_PATH
    mkdir -p $CYSIC_PATH
    cd $CYSIC_PATH

    # Download verifier program
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_linux > $CYSIC_PATH/verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.so > $CYSIC_PATH/libzkp.so
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_mac > $CYSIC_PATH/verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.dylib > $CYSIC_PATH/libzkp.dylib
    else
        echo "Unsupported operating system"
        exit 1
    fi

    # Set permissions
    chmod +x $CYSIC_PATH/verifier

    # Create configuration file
    read -p "Enter your reward claim address (ERC-20, ETH wallet address): " CLAIM_REWARD_ADDRESS
    cat <<EOF > $CYSIC_PATH/config.yaml
chain:
  endpoint: "testnet-node-1.prover.xyz:9090"
  chain_id: "cysicmint_9000-1"
  gas_coin: "cysic"
  gas_price: 10
claim_reward_address: "$CLAIM_REWARD_ADDRESS"

server:
  cysic_endpoint: "https://api-testnet.prover.xyz"
EOF

    # Create start script
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    cat << EOF > $CYSIC_PATH/start.sh
#!/bin/bash
export LD_LIBRARY_PATH=.:~/miniconda3/lib:$LD_LIBRARY_PATH
export CHAIN_ID=534352
$CYSIC_PATH/verifier
EOF
elif [[ "$OSTYPE" == "darwin"* ]]; then
    cat << EOF > $CYSIC_PATH/start.sh
#!/bin/bash
export DYLD_LIBRARY_PATH=".:~/miniconda3/lib:$DYLD_LIBRARY_PATH"
export CHAIN_ID=534352
$CYSIC_PATH/verifier
EOF
fi
chmod +x $CYSIC_PATH/start.sh

# Change to Cysic verifier directory
cd $CYSIC_PATH

# Start verifier node using PM2
pm2 start $CYSIC_PATH/start.sh --name "cysic-verifier"

    echo "Cysic verifier node has started. You can use 'pm2 logs cysic-verifier' to view the logs."
}

# View node logs
function check_node() {
    pm2 logs cysic-verifier
}

# Uninstall node
function uninstall_node() {
    pm2 delete cysic-verifier && rm -rf $CYSIC_PATH
    echo "Cysic verifier node has been removed."
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
	echo "============================ Cysic Verifier Node Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
    echo "Please choose an option:"
    echo "1. Install Cysic verifier node"
    echo "2. View node logs"
    echo "3. Remove node"
    read -p "Enter your choice (1-3): " OPTION
    case $OPTION in
    1) install_cysic_node ;;
    2) check_node ;;
    3) uninstall_node ;;
    *) echo "Invalid option." ;;
    esac
}

# Display main menu
main_menu
