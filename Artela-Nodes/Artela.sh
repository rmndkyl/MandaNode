#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root."
    echo "Please try using 'sudo -i' to switch to the root user, then run this script again."
    exit 1
fi

# Check and install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed"
    else
        echo "Node.js is not installed, installing..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed"
    else
        echo "npm is not installed, installing..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed"
    else
        echo "PM2 is not installed, installing..."
        npm install pm2@latest -g
    fi
}

# Function to automatically set aliases
function check_and_set_alias() {
    local alias_name="art"
    local shell_rc="$HOME/.bashrc"

    # For Zsh users, use .zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # Check if the alias is already set
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "Setting alias '$alias_name' to $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # Remind the user to activate the alias
        echo "Alias '$alias_name' is set. Please run 'source $shell_rc' to activate the alias, or reopen the terminal."
    else
        # If the alias is already set, provide a hint
        echo "Alias '$alias_name' is already set in $shell_rc."
        echo "If the alias does not work, try running 'source $shell_rc' or reopen the terminal."
    fi
}

# Node installation function
function install_node() {
    install_nodejs_and_npm
    install_pm2

    # Set variable
    read -r -p "Please enter the node name you want to set: " NODE_MONIKER
    export NODE_MONIKER=$NODE_MONIKER

    # Update and install necessary software
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev lz4 snapd

    # Install Go
    sudo rm -rf /usr/local/go
    curl -L https://go.dev/dl/go1.22.0.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
    source $HOME/.bash_profile
    go version

    # Install all binaries
    cd $HOME
    git clone https://github.com/artela-network/artela
    cd artela
    git checkout v0.4.7-rc7-fix-execution 
    make install
    
    cd $HOME
    wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7-fix-execution/artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
    tar -xvf artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
    mkdir libs
    mv $HOME/libaspect_wasm_instrument.so $HOME/libs/
    mv $HOME/artelad /usr/local/bin/
    echo 'export LD_LIBRARY_PATH=$HOME/libs:$LD_LIBRARY_PATH' >> ~/.bash_profile
    source ~/.bash_profile
    

    # Configure artelad
    artelad config chain-id artela_11822-1
    artelad init "$NODE_MONIKER" --chain-id artela_11822-1
    artelad config node tcp://localhost:3457

    # Get initial files and address book
    curl -L https://snapshots.dadunode.com/artela/genesis.json > $HOME/.artelad/config/genesis.json
    curl -L https://snapshots.dadunode.com/artela/addrbook.json > $HOME/.artelad/config/addrbook.json

    # Configure the node
    SEEDS=""
    PEERS="ca8bce647088a12bc030971fbcce88ea7ffdac50@84.247.153.99:26656,a3501b87757ad6515d73e99c6d60987130b74185@85.239.235.104:3456,2c62fb73027022e0e4dcbdb5b54a9b9219c9b0c1@51.255.228.103:26687,fbe01325237dc6338c90ddee0134f3af0378141b@158.220.88.66:3456,fde2881b06a44246a893f37ecb710020e8b973d1@158.220.84.64:3456,12d057b98ecf7a24d0979c0fba2f341d28973005@116.202.162.188:10656,9e2fbfc4b32a1b013e53f3fc9b45638f4cddee36@47.254.66.177:26656,92d95c7133275573af25a2454283ebf26966b188@167.235.178.134:27856,2dd98f91eaea966b023edbc88aa23c7dfa1f733a@158.220.99.30:26680"
    sed -i 's|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.artelad/config/config.toml

    # Configure pruning
    sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.artelad/config/app.toml
    sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.artelad/config/app.toml
    sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"0\"/" $HOME/.artelad/config/app.toml
    sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.artelad/config/app.toml
    sed -i -e 's/max_num_inbound_peers = 40/max_num_inbound_peers = 100/' -e 's/max_num_outbound_peers = 10/max_num_outbound_peers = 100/' $HOME/.artelad/config/config.toml

    # Configure ports
    node_address="tcp://localhost:3457"
    sed -i -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:3458\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:3457\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:3460\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:3456\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":3466\"%" $HOME/.artelad/config/config.toml
    sed -i -e "s%^address = \"tcp://localhost:1317\"%address = \"tcp://0.0.0.0:3417\"%; s%^address = \":8080\"%address = \":3480\"%; s%^address = \"localhost:9090\"%address = \"0.0.0.0:3490\"%; s%^address = \"localhost:9091\"%address = \"0.0.0.0:3491\"%; s%:8545%:3445%; s%:8546%:3446%; s%:6065%:3465%" $HOME/.artelad/config/app.toml
    echo "export Artela_RPC_PORT=$node_address" >> $HOME/.bash_profile
    source $HOME/.bash_profile

    # Reset node
    artelad tendermint unsafe-reset-all --home $HOME/.artelad

    # Create a service
    sudo tee /etc/systemd/system/artelad.service > /dev/null <<EOF
[Unit]
Description=Artela Node
After=network-online.target

[Service]
User=$USER
ExecStart=$(which artelad) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

    # Register and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable artelad
    sudo systemctl start artelad

    echo "Node setup completed."
}

# Function to add wallet (dummy function for demonstration)
function add_wallet() {
    echo "Adding wallet..."
}

# Function to import wallet (dummy function for demonstration)
function import_wallet() {
    echo "Importing wallet..."
}

# Function to check balances (dummy function for demonstration)
function check_balances() {
    echo "Checking wallet balance..."
}

# Function to check sync status (dummy function for demonstration)
function check_sync_status() {
    echo "Checking node synchronization status..."
}

# Function to check service status (dummy function for demonstration)
function check_service_status() {
    echo "Checking current service status..."
}

# Function to view logs (dummy function for demonstration)
function view_logs() {
    echo "Viewing logs..."
}

# Function to uninstall node (dummy function for demonstration)
function uninstall_node() {
    echo "Uninstalling node..."
}

# Function to add validator (dummy function for demonstration)
function add_validator() {
    echo "Creating a validator..."
}

# Function to delegate to self validator (dummy function for demonstration)
function delegate_self_validator() {
    echo "Pledging to yourself..."
}

# Function to export validator private key (dummy function for demonstration)
function export_priv_validator_key() {
    echo "Backing up the validator private key..."
}

# Function to update the script (dummy function for demonstration)
function update_script() {
    echo "Updating the script..."
}

# Main menu function
function main_menu() {
    while true; do
        clear
        echo ██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░
        echo ██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗
        echo ██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝
        echo ██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░
        echo ███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░
        echo ╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░
        echo "The script and tutorial were written by Telegram user @rmndkyl, free and open source, please do not believe in the paid version"
        echo "==============================Artela node installation===================================="
        echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "To exit the script, press ctrl c on the keyboard to exit"
        echo "Please select the action to perform:"
        echo "1. Install node"
        echo "2. Create a wallet"
        echo "3. Import wallet"
        echo "4. Check the wallet address balance"
        echo "5. Check the node synchronization status"
        echo "6. View the current service status"
        echo "7. Run log query"
        echo "8. Uninstall node"
        echo "9. Set shortcut keys"
        echo "10. Create a validator"
        echo "11. Pledge to yourself"
        echo "12. Backup the validator private key"
        echo "13. Update this script"
        read -p "Please enter option (1-13): " OPTION

        case $OPTION in
        1) install_node ;;
        2) add_wallet ;;
        3) import_wallet ;;
        4) check_balances ;;
        5) check_sync_status ;;
        6) check_service_status ;;
        7) view_logs ;;
        8) uninstall_node ;;
        9) check_and_set_alias ;;
        10) add_validator ;;
        11) delegate_self_validator ;;
        12) export_priv_validator_key ;;
        13) update_script ;;
        *) echo "Invalid option." ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Display the main menu
main_menu
