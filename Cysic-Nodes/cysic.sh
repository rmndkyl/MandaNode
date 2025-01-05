#!/bin/bash

# Cysic Node Installation Path
CYSIC_PATH="$HOME/cysic-verifier"

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Try using the 'sudo -i' command to switch to the root user, then run this script again."
    exit 1
fi

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
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
        echo "Node.js is not installed. Installing..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed, version: $(npm -v)"
    else
        echo "npm is not installed. Installing..."
        sudo apt-get install -y npm
    fi
}

# Install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed, version: $(pm2 -v)"
    else
        echo "PM2 is not installed. Installing..."
        npm install pm2@latest -g
    fi
}

# Install Cysic verifier node
function install_cysic_node() {
    install_dependencies
    install_nodejs_and_npm
    install_pm2

    # Create the Cysic verifier directory
    rm -rf $CYSIC_PATH
    mkdir -p $CYSIC_PATH
    cd $CYSIC_PATH

    # Download verifier files
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_linux > $CYSIC_PATH/verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.so > $CYSIC_PATH/libzkp.so
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/verifier_mac > $CYSIC_PATH/verifier
        curl -L https://cysic-verifiers.oss-accelerate.aliyuncs.com/libzkp.dylib > $CYSIC_PATH/libzkp.dylib
    else
        echo "Unsupported operating system."
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

    # Create startup script
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

    # Switch to the Cysic verifier directory
    cd $CYSIC_PATH

    # Start the verifier node using PM2
    pm2 start $CYSIC_PATH/start.sh --name "cysic-verifier"

    echo "Cysic verifier node has been started. You can view logs using 'pm2 logs cysic-verifier'."
}

# View Node Logs
function check_node() {
    pm2 logs cysic-verifier
}

# Uninstall Node
function uninstall_node() {
    pm2 delete cysic-verifier && rm -rf $CYSIC_PATH
    echo "Cysic verifier node has been removed."
}

# Run Node 2.0
function run_node_2.0() {
    read -p "Enter your whitelisted 0x address: " address
    install_nodejs_and_npm
    install_pm2

    wget https://github.com/cysic-labs/phase2_libs/releases/download/v1.0.0/setup_linux.sh
    chmod +x setup_linux.sh
    ./setup_linux.sh "$address"
    cd ~/cysic-verifier
    pm2 start start.sh
}

# Check Node 2.0 Logs
function check_node_2.0() {
    pm2 logs start
}

# Main Menu
function main_menu() {
    clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Cysic Verifier Node Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
 	echo "Please select an operation to perform:"
  	echo "1. Run 2.0 Node"
    	echo "2. View 2.0 Node Logs"
    	echo "3. Remove Node"
    	read -p "Enter your choice (1-2): " OPTION
    	case $OPTION in
    	1) run_node_2.0 ;;
    	2) check_node_2.0 ;;
        3) uninstall_node ;;
    	*) echo "Invalid option." ;;
    	esac
}

# Display Main Menu
main_menu
