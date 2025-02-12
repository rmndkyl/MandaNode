#!/bin/bash

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try using 'sudo -i' to switch to the root user, then run this script again."
    exit 1
fi

# Check and install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed."
    else
        echo "Node.js is not installed. Installing..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed."
    else
        echo "npm is not installed. Installing..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed."
    else
        echo "PM2 is not installed. Installing..."
        npm install pm2@latest -g
    fi
}

# Check Go installation
function check_go_installation() {
    if command -v go > /dev/null 2>&1; then
        echo "Go is already installed."
        return 0
    else
        echo "Go is not installed. Installing..."
        return 1
    fi
}

# Install validator function
function install_validator() {
    install_nodejs_and_npm
    install_pm2

    # Check and install curl if not installed
    if ! command -v curl > /dev/null; then
        sudo apt update && sudo apt install curl -y
    fi

    # Update and install necessary packages
    sudo apt update && sudo apt upgrade -y
    sudo apt install git wget build-essential jq make lz4 gcc -y

    # Install Go
    if ! check_go_installation; then
        sudo rm -rf /usr/local/go
        curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
        source $HOME/.bash_profile
        go version
    fi

    # Download binary file
    wget -O 0gchaind https://github.com/0glabs/0g-chain/releases/download/v0.5.0/0gchaind-linux-v0.5.0
    chmod +x $HOME/0gchaind
    mv $HOME/0gchaind $HOME/go/bin
    source ~/.profile

    # Configure 0gchaind
    export MONIKER="My_Node"
    export WALLET_NAME="wallet"

    # Initialize node
    cd $HOME
    0gchaind init $MONIKER --chain-id zgtendermint_16600-2
    0gchaind config chain-id zgtendermint_16600-2
    0gchaind config node tcp://localhost:13457

    # Configure genesis file
    rm ~/.0gchain/config/genesis.json
    wget -O $HOME/.0gchain/config/genesis.json https://server-5.itrocket.net/testnet/og/genesis.json
    0gchaind validate-genesis

    # Configure peers and seeds
    SEEDS="bac83a636b003495b2aa6bb123d1450c2ab1a364@og-testnet-seed.itrocket.net:47656"
    PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,..."
    sed -i "s/persistent_peers = \"\"/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml
    sed -i "s/seeds = \"\"/seeds = \"$SEEDS\"/" $HOME/.0gchain/config/config.toml
    sed -i -e 's/max_num_inbound_peers = 40/max_num_inbound_peers = 100/' -e 's/max_num_outbound_peers = 10/max_num_outbound_peers = 100/' $HOME/.0gchain/config/config.toml
    wget -O $HOME/.0gchain/config/addrbook.json https://server-5.itrocket.net/testnet/og/addrbook.json

    # Configure pruning
    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchain/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchain/config/app.toml
    sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.0gchain/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.0gchain/config/app.toml

    # Configure ports
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:13458\"%; ..." $HOME/.0gchain/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:13417\"%; ..." $HOME/.0gchain/config/app.toml
    source $HOME/.bash_profile

    # Download snapshot
    cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
    rm -rf $HOME/.0gchain/data
    curl -o - -L https://config-t.noders.services/og/data.tar.lz4 | lz4 -d | tar -x -C ~/.0gchain
    mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json

    # Start node process with PM2
    pm2 start 0gchaind -- start --log_output_console --home ~/.0gchain && pm2 save && pm2 startup
    pm2 restart 0gchaind

    echo '====================== Installation complete. Please exit the script and run source $HOME/.bash_profile to load environment variables ==========================='
}

# Check PM2 service status
function check_service_status() {
    pm2 list
}

# View node logs
function view_logs() {
    pm2 logs 0gchaind
}

# Uninstall validator node
function uninstall_validator() {
    echo "Are you sure you want to uninstall the 0gchain validator node? This will delete all related data. [Y/N]"
    read -r -p "Confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Starting uninstallation..."
            pm2 stop 0gchaind && pm2 delete 0gchaind
            rm -rf $HOME/.0gchain $(which 0gchaind)  $HOME/0g-chain
            echo "Uninstallation complete."
            ;;
        *)
            echo "Uninstallation canceled."
            ;;
    esac
}

# Create wallet
function add_wallet() {
    read -p "Enter the wallet name you want to set: " wallet_name
    0gchaind keys add $wallet_name --eth
}

# Import wallet
function import_wallet() {
    read -p "Enter the wallet name you want to set: " wallet_name
    0gchaind keys add $wallet_name --recover --eth
}

# Check balance
function check_balances() {
    echo "Please ensure synchronization to the latest block before checking balance."
    read -p "Enter wallet address: " wallet_address
    0gchaind query bank balances "$wallet_address"
}

# Check node sync status
function check_sync_status() {
    0gchaind status | jq .sync_info
}

# Create validator
function add_validator() {

    read -p "Enter your wallet name: " wallet_name
    read -p "Enter the validator name you want to set: " validator_name
    read -p "Enter your validator details (e.g., 'Capital Corp'): " details

    0gchaind tx staking create-validator \
    --amount=1000000ua0gi \
    --pubkey=$(0gchaind tendermint show-validator) \
    --moniker=$validator_name \
    --chain-id=zgtendermint_16600-2 \
    --commission-rate=0.05 \
    --commission-max-rate=0.10 \
    --commission-max-change-rate=0.01 \
    --min-self-delegation=1 \
    --from=$wallet_name \
    --identity="" \
    --website="" \
    --details="$details" \
    --gas=auto \
    --gas-adjustment=1.4
}

# Delegate to Own Validator
function delegate_self_validator() {
    read -p "Enter the amount of tokens to stake (unit: ua0gi, e.g., if you have 1,000,000 ua0gi, keep some for yourself and enter 900,000): " math
    read -p "Enter your wallet name: " wallet_name
    0gchaind tx staking delegate $(0gchaind keys show $wallet_name --bech val -a) ${math}ua0gi --from $wallet_name --gas=auto --gas-adjustment=1.4 -y
}

# Install Storage Node
function install_storage_node() {
    sudo apt-get update
    sudo apt-get install clang cmake build-essential git screen openssl pkg-config libssl-dev -y

    # Install Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    source $HOME/.bash_profile

    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Clone Repository
    git clone -b v0.8.4 https://github.com/0glabs/0g-storage-node.git

    # Navigate to Directory and Build
    cd 0g-storage-node
    git checkout 40d4355
    git submodule update --init

    # Build the Code
    echo "Preparing to build. This process may take some time. Please keep SSH open. Wait for 'Finish' to indicate completion."
    cargo build --release

    # Edit Configuration
    read -p "Enter your EVM wallet private key (without '0x'): " miner_key
    read -p "Enter JSON-RPC URL (Official: https://evmrpc-testnet.0g.ai): " json_rpc
    sed -i '
    s|# blockchain_rpc_endpoint = ".*"|blockchain_rpc_endpoint = "'$json_rpc'"|
    s|# miner_key = ""|miner_key = "'$miner_key'"|
    ' $HOME/0g-storage-node/run/config-testnet-turbo.toml

    # Start the Storage Node
    cd ~/0g-storage-node/run
    screen -dmS zgs_node_session $HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml

    echo '====================== Installation complete. Use screen -ls to check the session. ==========================='
}

# Check Storage Node Sync Status
function check_storage_status() {
    while true; do
    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    logSyncHeight=$(echo $response | jq '.result.logSyncHeight')
    connectedPeers=$(echo $response | jq '.result.connectedPeers')
    echo -e "Block: \033[32m$logSyncHeight\033[0m, Peers: \033[34m$connectedPeers\033[0m"
    sleep 5;
    done
}

# View Storage Node Logs
function check_storage_logs() {
    tail -f -n50 ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
}

# Filter Error Logs
function check_storage_error() {
    tail -f -n50 ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) | grep ERROR
}

# Restart Storage Node
function restart_storage() {
    # Stop Existing Process
    screen -S zgs_node_session -X quit
    # Start the Node
    cd ~/0g-storage-node/run
    screen -dmS zgs_node_session $HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml
    echo '====================== Restarted successfully. Use screen -r zgs_node_session to check. ==========================='
}

# Delete Storage Node Logs
function delete_storage_logs() {
    echo "Are you sure you want to delete storage node logs? [Y/N]"
    read -r -p "Confirm: " response
    case "$response" in
        [yY][eE][sS]|[yY])
            rm -r ~/0g-storage-node/run/log/*
            echo "Logs deleted. Please restart the storage node."
            ;;
        *)
            echo "Operation canceled."
            ;;
    esac
}

# Uninstall Storage Node
function uninstall_storage_node() {
    echo "Are you sure you want to uninstall the 0G AI storage node? This will delete all related data. [Y/N]"
    read -r -p "Confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Starting to uninstall the storage node..."
            rm -rf $HOME/0g-storage-node
            echo "Storage node uninstalled successfully."
            ;;
        *)
            echo "Uninstallation canceled."
            ;;
    esac
}

# Convert ETH Address
function transfer_EIP() {
    read -p "Enter your wallet name: " wallet_name
    echo "0x$(0gchaind debug addr $(0gchaind keys show $wallet_name -a) | grep hex | awk '{print $3}')"
}

# Export Validator Key
function export_priv_validator_key() {
    echo "==================== Please back up the following content to your notes or an Excel file ==========================="
    cat ~/.0gchain/config/priv_validator_key.json
}

# Update Script
function update_script() {
    SCRIPT_PATH="./0g.sh"  # Define script path
    SCRIPT_URL="https://raw.githubusercontent.com/a3165458/0g.ai/main/0g.sh"

    # Backup the original script
    cp $SCRIPT_PATH "${SCRIPT_PATH}.bak"

    # Download the new script and check if successful
    if curl -o $SCRIPT_PATH $SCRIPT_URL; then
        chmod +x $SCRIPT_PATH
        echo "Script updated. Please exit and run 'bash 0g.sh' to restart the script."
    else
        echo "Update failed. Restoring the original script."
        mv "${SCRIPT_PATH}.bak" $SCRIPT_PATH
    fi
}

# Main Menu
function main_menu() {
    while true; do
        clear
        echo "This script and tutorial were written by Telegram Channel @layerairdrop and maintained by @layerairdrop. It is free and open-source. Do not trust paid services."
        echo "======================= 0G AI Node Installation ================================"
        echo "======================= Validator Node Functions =============================="
        echo "Node Community Telegram Group: https://t.me/layerairdrop"
        echo "To exit the script, press Ctrl + C."
        echo "Select an action:"
        echo "======================= Validator Node ================================"
        echo "1. Install Validator Node"
        echo "2. Create Wallet"
        echo "3. Import Wallet"
        echo "4. Check Wallet Balance"
        echo "5. Check Node Sync Status"
        echo "6. Check Current Service Status"
        echo "7. View Logs"
        echo "8. Uninstall Validator Node"
        echo "9. Create Validator"
        echo "10. Delegate Tokens to Own Validator Address"
        echo "11. Convert ETH Address"
        echo "======================= Storage Node ================================"
        echo "12. Install Storage Node"
        echo "13. Check Storage Node Sync Status"
        echo "14. View Storage Node Logs"
        echo "15. Filter Error Logs"
        echo "16. Restart Storage Node"
        echo "17. Uninstall Storage Node"
        echo "18. Delete Storage Node Logs"
        echo "======================= Backup Functions ================================"
        echo "19. Backup Validator Private Key"
        echo "======================================================="
        echo "20. Update This Script"
        read -p "Enter an option (1-20): " OPTION

        case $OPTION in
        1) install_validator ;;
        2) add_wallet ;;
        3) import_wallet ;;
        4) check_balances ;;
        5) check_sync_status ;;
        6) check_service_status ;;
        7) view_logs ;;
        8) uninstall_validator ;;
        9) add_validator ;;
        10) delegate_self_validator ;;
        11) transfer_EIP ;;
        12) install_storage_node ;;
        13) check_storage_status ;;
        14) check_storage_logs ;;
        15) check_storage_error ;;
        16) restart_storage ;;
        17) uninstall_storage_node ;;
        18) delete_storage_logs ;;
        19) export_priv_validator_key ;;
        20) update_script ;;

        *) echo "Invalid option." ;;
        esac
        
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display Main Menu
main_menu
