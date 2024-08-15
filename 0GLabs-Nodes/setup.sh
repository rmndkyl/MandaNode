#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Check if the script is being run as the root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root privileges."
    echo "Please try switching to the root user using the 'sudo -i' command, then run this script again."
    exit 1
fi

# Check and install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed"
    else
        echo "Node.js is not installed, installing now..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed"
    else
        echo "npm is not installed, installing now..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed"
    else
        echo "PM2 is not installed, installing now..."
        npm install pm2@latest -g
    fi
}

# Check Go installation
function check_go_installation() {
    if command -v go > /dev/null 2>&1; then
        echo "Go environment is already installed"
        return 0
    else
        echo "Go environment is not installed, installing now..."
        return 1
    fi
}

# Node installation function
function install_node() {

    install_nodejs_and_npm
    install_pm2

    # Check if curl is installed, if not install it
    if ! command -v curl > /dev/null; then
        sudo apt update && sudo apt install curl git -y
    fi

    # Update and install necessary software
    sudo apt update && sudo apt upgrade -y
    sudo apt install git wget build-essential jq make lz4 gcc liblz4-tool -y

    # Install Go
    if ! check_go_installation; then
        sudo rm -rf /usr/local/go
        curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
        echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
        source $HOME/.bash_profile
        go version
    fi

    # Install all binaries
    git clone -b v0.3.1 https://github.com/0glabs/0g-chain.git
    cd 0g-chain
    make install
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
    wget -P ~/.0gchain/config https://public-snapshot-storage-develop.s3.ap-southeast-1.amazonaws.com/zerog/zgtendermint_16600-2/genesis.json
    0gchaind validate-genesis

    # Configure node
    SEEDS="8f21742ea5487da6e0697ba7d7b36961d3599567@og-testnet-seed.itrocket.net:47656"
    PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,9dbb76298d1625ebcc47d08fa7e7911967b63b61@45.159.221.57:26656,a2caf26a86a4989e26943e496173e7b22831c88a@198.7.116.141:12656,0ae19691f97f5797694c253bc06c79c8b58ea2a8@85.190.242.81:26656,c0d35052a7612d992f721b25f186a5d1f569405e@195.201.194.188:26656,8bd2797c8ece0f099a1c31f98e5648d192d8cd54@38.242.146.162:26656,c85eaa1b3cbe4d7fb19138e5a5dc4111491e6e03@115.78.229.59:10156,fa08f548e8d34b6c72ed9e7495a59ae6be656da8@109.199.97.178:12656,ffdf7a8cc6dbbd22e25b1590f61da149349bdc2e@135.181.229.206:26656,56ee4c337848a70a43887531b5f1ca211bac1a34@185.187.170.125:26656"
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
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:13458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:13457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:13460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:13456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":13466\"%" $HOME/.0gchain/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:13417\"%; s%^address = \":8080\"%address = \":13480\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:13490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:13491\"%; s%:8545%:13445%; s%:8546%:13446%; s%:6065%:13465%" $HOME/.0gchain/config/app.toml
    source $HOME/.bash_profile

    # Download snapshot
    cp $HOME/.0gchain/data/priv_validator_state.json $HOME/.0gchain/priv_validator_state.json.backup
    rm -rf $HOME/.0gchain/data
    curl -L https://snapshots.dadunode.com/0gchain/0gchain_latest_tar.lz4 | tar -I lz4 -xf - -C $HOME/.0gchain/data
    mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json

    # Start the node process using PM2
    pm2 start 0gchaind -- start --log_output_console --home ~/.0gchain && pm2 save && pm2 startup
    pm2 restart 0gchaind

    echo '====================== Installation completed. Please execute "source $HOME/.bash_profile" after exiting the script to load the environment variables ==========================='
}

# Check the status of PM2 services
function check_service_status() {
    pm2 list
}

# View node logs
function view_logs() {
    pm2 logs 0gchaind
}

# Uninstall the node
function uninstall_node() {
    echo "Are you sure you want to uninstall the 0gchain node program? This will delete all related data. [Y/N]"
    read -r -p "Please confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Starting to uninstall the node program..."
            pm2 stop 0gchaind && pm2 delete 0gchaind
            rm -rf $HOME/.0gchain $HOME/0gchain $(which 0gchaind) && rm -rf 0g-chain
            echo "Node program uninstallation complete."
            ;;
        *)
            echo "Uninstallation operation canceled."
            ;;
    esac
}

# Create a wallet
function add_wallet() {
    read -p "Please enter the wallet name you want to set: " wallet_name
    0gchaind keys add $wallet_name --eth
}

# Import a wallet
function import_wallet() {
    read -p "Please enter the wallet name you want to set: " wallet_name
    0gchaind keys add $wallet_name --recover --eth
}

# Check balance
function check_balances() {
    echo "Please confirm the sync to the latest block before checking the balance."
    read -p "Please enter the wallet address: " wallet_address
    0gchaind query bank balances "$wallet_address"
}

# Check node sync status
function check_sync_status() {
    0gchaind status | jq .sync_info
}

# Create a validator
function add_validator() {

    read -p "Please enter your wallet name: " wallet_name
    read -p "Please enter the name you want to set for the validator: " validator_name
    read -p "Please enter the details for your validator (e.g., 'Capital Group'): " details

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

# Install the storage node
function install_storage_node() {

    sudo apt-get update
    sudo apt-get install clang cmake build-essential git screen cargo -y

    # Install Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    source $HOME/.bash_profile

    # Clone the repository
    git clone -b v0.4.2 https://github.com/0glabs/0g-storage-node.git

    # Navigate to the directory and build
    cd 0g-storage-node
    git submodule update --init

    # Build the code
    echo "Preparing to build. This step will take some time. Please do not disconnect the SSH connection. Wait for the 'Finish' message to indicate completion."
    cargo build --release

    # Edit the configuration
    read -p "Please enter the EVM wallet private key you want to import, without the '0x': " miner_key
    read -p "Please enter the device's IP address (enter 127.0.0.1 for local machine): " public_address
    read -p "Please enter the JSON-RPC to use: " json_rpc
    sed -i '
    s|# network_enr_address = ""|network_enr_address = "'$public_address'"|
    s|# blockchain_rpc_endpoint = ".*"|blockchain_rpc_endpoint = "'$json_rpc'"|
    s|# miner_key = ""|miner_key = "'$miner_key'"|
    ' $HOME/0g-storage-node/run/config-testnet-turbo.toml

    # Start the node
    cd ~/0g-storage-node/run
    screen -dmS zgs_node_session $HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml

    echo '====================== Installation completed. Use the command "screen -ls" to check ==========================='
}

# Install storage key-value node
function install_storage_kv() {

    # Clone the repository
    git clone https://github.com/0glabs/0g-storage-kv.git

    # Navigate to the directory and build
    cd 0g-storage-kv
    git submodule update --init

    # Build the code
    cargo build --release

    # Run in the background
    cd run

    echo "Please enter the RPC node information: "
    read blockchain_rpc_endpoint

    cat > config.toml <<EOF
stream_ids = ["000000000000000000000000000000000000000000000000000000000000f2bd", "000000000000000000000000000000000000000000000000000000000000f009", "00000000000000000000000000"]

db_dir = "db"
kv_db_dir = "kv.DB"

rpc_enabled = true
rpc_listen_address = "127.0.0.1:6789"
zgs_node_urls = "http://127.0.0.1:5678"

log_config_file = "log_config"

blockchain_rpc_endpoint = "$blockchain_rpc_endpoint"
log_contract_address = "0x22C1CaF8cbb671F220789184fda68BfD7eaA2eE1"
log_sync_start_block_number = 670000

EOF

    echo "Configuration successfully written to config.toml file"
    screen -dmS storage_kv ../target/release/zgs_kv --config config.toml

}

# Delegate tokens to your own validator
function delegate_self_validator() {
    read -p "Please enter the amount of tokens to delegate (unit is ua0gi, e.g., if you have 1,000,000 ua0gi, leave some for yourself and enter 900,000): " math
    read -p "Please enter your wallet name: " wallet_name
    0gchaind tx staking delegate $(0gchaind keys show $wallet_name --bech val -a) ${math}ua0gi --from $wallet_name --gas=auto --gas-adjustment=1.4 -y

}

# View storage node logs
function check_storage_logs() {
    tail -f "$(find ~/0g-storage-node/run/log/ -type f -printf '%T+ %p\n' | sort -r | head -n 1 | cut -d' ' -f2-)"
}

# Filter error logs
function check_storage_error() {
    tail -f -n50 ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d) | grep ERROR
}

# Restart storage node
function restart_storage() {
    # Exit the current process
    screen -S zgs_node_session -X quit
    # Start
    cd ~/0g-storage-node/run
    screen -dmS zgs_node_session $HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config-testnet-turbo.toml
    echo '====================== Successfully started. Use "screen -r zgs_node_session" to check ==========================='

}

# Change log level
function change_storage_log_level() {
    echo "DEBUG(1) > INFO(2) > WARN(3) > ERROR(4)"
    echo "DEBUG log files are the largest, ERROR log files are the smallest"
    read -p "Please select the log level (1-4): " level
    case "$level" in
        1)
            echo "debug,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
        2)
            echo "info,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
        3)
            echo "warn,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
        4)
            echo "error,hyper=info,h2=info" > $HOME/0g-storage-node/run/log_config ;;
    esac
    echo "Change complete. Please restart the storage node."
}

# Calculate log file disk usage
function storage_logs_disk_usage(){
    du -sh ~/0g-storage-node/run/log/
    du -sh ~/0g-storage-node/run/log/*
}

# Delete storage node logs
function delete_storage_logs(){
    echo "Are you sure you want to delete the storage node logs? [Y/N]"
    read -r -p "Please confirm: " response
        case "$response" in
        [yY][eE][sS]|[yY])
            rm -r ~/0g-storage-node/run/log/*
            echo "Deletion complete. Please restart the storage node."
            ;;
        *)
            echo "Operation canceled."
            ;;
    esac

}

# Convert ETH Address
function transfer_EIP() {
    read -p "Please enter your wallet name: " wallet_name
    echo "0x$(0gchaind debug addr $(0gchaind keys show $wallet_name -a) | grep hex | awk '{print $3}')"
}

# Export Validator Key
function export_priv_validator_key() {
    echo "====================Please backup the entire content below to your notebook or Excel file==========================================="
    cat ~/.0gchain/config/priv_validator_key.json
}

# Uninstall Storage Node
function uninstall_storage_node() {
    echo "Are you sure you want to uninstall the 0g AI storage node? This will delete all related data. [Y/N]"
    read -r -p "Please confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Starting to uninstall the node..."
            rm -rf $HOME/0g-storage-node
            echo "Node uninstallation complete."
            ;;
        *)
            echo "Uninstallation operation canceled."
            ;;
    esac
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
        echo "Script updated. Please exit and rerun this script with 'bash 0g.sh'."
    else
        echo "Update failed. Restoring the original script."
        mv "${SCRIPT_PATH}.bak" $SCRIPT_PATH
    fi
}

# Main Menu
function main_menu() {
    while true; do
        clear
        echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
        echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
        echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
        echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
        echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
        echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ 0GLabs Node Installation ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press ctrl + c."
        echo "Please select an operation to execute:"
        echo "1. Install Node"
        echo "2. Create Wallet"
        echo "3. Import Wallet"
        echo "4. Check Wallet Balance"
        echo "5. Check Node Sync Status"
        echo "6. Check Current Service Status"
        echo "7. View Logs"
        echo "8. Uninstall 0gchain Validator Node"
        echo "9. Create Validator"
        echo "10. Delegate Tokens to Your Validator"
        echo "11. Convert ETH Address"
        echo "=======================Storage Node Features================================"
        echo "12. Install Storage Node"
        echo "13. View Storage Node Logs"
        echo "14. Filter Error Logs"
        echo "15. Restart Storage Node"
        echo "16. Uninstall Storage Node"
        echo "17. Change Log Level"
        echo "18. Check Log File Disk Usage"
        echo "19. Delete Storage Node Logs"
        echo "=======================Backup Features================================"
        echo "21. Backup Validator Private Key"
        echo "======================================================="
        echo "20. Update This Script"
        read -p "Please enter an option (1-21): " OPTION

        case $OPTION in
        1) install_node ;;
        2) add_wallet ;;
        3) import_wallet ;;
        4) check_balances ;;
        5) check_sync_status ;;
        6) check_service_status ;;
        7) view_logs ;;
        8) uninstall_node ;;
        9) add_validator ;;
        10) delegate_self_validator ;;
        11) transfer_EIP ;;
        12) install_storage_node ;;
        13) check_storage_logs ;;
        14) check_storage_error;;
        15) restart_storage ;;
        16) uninstall_storage_node ;;
        17) change_storage_log_level ;;
        18) storage_logs_disk_usage ;;
        19) delete_storage_logs ;;
        20) update_script ;;
        21) export_priv_validator_key ;;
        *) echo "Invalid option." ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display Main Menu
main_menu
