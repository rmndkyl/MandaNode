#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 2

#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i' and then run this script again."
    exit 1
fi

# Check and install Node.js and npm
function install_nodejs_and_npm() {
    if command -v node > /dev/null 2>&1; then
        echo "Node.js is already installed."
    else
        echo "Node.js is not installed, installing now..."
        curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    if command -v npm > /dev/null 2>&1; then
        echo "npm is already installed."
    else
        echo "npm is not installed, installing now..."
        sudo apt-get install -y npm
    fi
}

# Check and install PM2
function install_pm2() {
    if command -v pm2 > /dev/null 2>&1; then
        echo "PM2 is already installed."
    else
        echo "PM2 is not installed, installing now..."
        npm install pm2@latest -g
    fi
}

# Automatically set up a shortcut alias
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
        echo "Setting up alias '$alias_name' in $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # Inform the user to activate the alias
        echo "Alias '$alias_name' has been set. Please run 'source $shell_rc' to activate the alias, or reopen the terminal."
    else
        # If the alias is already set, provide a reminder
        echo "Alias '$alias_name' is already set in $shell_rc."
        echo "If the alias doesn't work, try running 'source $shell_rc' or reopen the terminal."
    fi
}

# Node installation function
function install_node() {
    install_nodejs_and_npm
    install_pm2

    # Set variables
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
    git checkout v0.4.8-rc8
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

    # Get genesis file and address book
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

    pm2 start artelad -- start && pm2 save && pm2 startup
    
    # Download snapshot
    artelad tendermint unsafe-reset-all --home $HOME/.artelad --keep-addr-book
    curl -L https://snapshots.dadunode.com/artela/artela_latest_tar.lz4 | tar -I lz4 -xf - -C $HOME/.artelad/data

    # Start the node process with PM2
    pm2 restart artelad

    echo '====================== Installation complete. Please exit the script and run source $HOME/.bash_profile to load environment variables ==========================='
    
}

# Check Artela service status
function check_service_status() {
    pm2 list
}

# View Artela node logs
function view_logs() {
    pm2 logs artelad
}

# Uninstall node function
function uninstall_node() {
    echo "Are you sure you want to uninstall the Artela node program? This will delete all related data. [Y/N]"
    read -r -p "Please confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY]) 
            echo "Starting the uninstallation of the node program..."
            pm2 stop artelad && pm2 delete artelad
            rm -rf $HOME/.artelad $HOME/artela $(which artelad)
            echo "Node program uninstalled successfully."
            ;;
        *)
            echo "Uninstallation operation canceled."
            ;;
    esac
}

# Create wallet
function add_wallet() {
    artelad keys add wallet
}

# Import wallet
function import_wallet() {
    artelad keys add wallet --recover
}

# Check balances
function check_balances() {
    read -p "Please enter the wallet address: " wallet_address
    artelad query bank balances "$wallet_address"
}

# Check node sync status
function check_sync_status() {
    artelad status | jq .SyncInfo
}

# Function to add validator (dummy function for demonstration)
function add_validator() {
    read -p "Please enter your wallet name: " wallet_name
    read -p "Please enter the name you want to set for the validator: " validator_name
    
    artelad tx staking create-validator \
    --amount="1art" \
    --pubkey=$(artelad tendermint show-validator) \
    --moniker="$validator_name" \
    --commission-rate="0.10" \
    --commission-max-rate="0.20" \
    --commission-max-change-rate="0.01" \
    --min-self-delegation="1" \
    --gas="200000" \
    --chain-id="artela_11822-1" \
    --from="$wallet_name"
}

# Function to delegate to self validator (dummy function for demonstration)
function delegate_self_validator() {
    read -p "Please enter the amount of tokens to delegate: " amount
    read -p "Please enter the wallet name: " wallet_name
    artelad tx staking delegate $(artelad keys show $wallet_name --bech val -a) ${amount}art --from $wallet_name --chain-id=artela_11822-1 --gas=300000
}

# Function to export validator private key (dummy function for demonstration)
function export_priv_validator_key() {
    echo "====================Please backup the following content to your own notepad or Excel spreadsheet==========================================="
    cat ~/.artelad/config/priv_validator_key.json
}

# Function to update the script (dummy function for demonstration)
function update_script() {
    SCRIPT_PATH="./Artela.sh"  # Define the script path
    SCRIPT_URL="https://raw.githubusercontent.com/a3165458/Artela/main/Artela.sh"
    
    # Backup the original script
    cp $SCRIPT_PATH "${SCRIPT_PATH}.bak"
    
    # Download the new script and check if successful
    if curl -o $SCRIPT_PATH $SCRIPT_URL; then
        chmod +x $SCRIPT_PATH
        echo "Script has been updated. Please exit the script and run 'bash Artela.sh' to restart this script."
    else
        echo "Update failed. Restoring the original script."
        mv "${SCRIPT_PATH}.bak" $SCRIPT_PATH
    fi
}

function update_node() {

    pm2 delete artelad

    mv ~/.artelad ~/artelad_back_up
    rsync -av --exclude "data" ~/artelad_back_up/* ~/.artelad
    cd && rm -rf artela
    git clone https://github.com/artela-network/artela
    cd artela
    LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
    git checkout $LATEST_TAG
    make install

    cd $HOME
    wget https://github.com/artela-network/artela/releases/download/v0.4.7-rc7-fix-execution/artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
    tar -xvf artelad_0.4.7_rc7_fix_execution_Linux_amd64.tar.gz
    mkdir libs
    mv $HOME/libaspect_wasm_instrument.so $HOME/libs/
    mv $HOME/artelad /usr/local/bin/
    echo 'export LD_LIBRARY_PATH=$HOME/libs:$LD_LIBRARY_PATH' >> ~/.bash_profile
    source ~/.bash_profile

    pm2 start artelad -- start && pm2 save && pm2 startup

    echo "Updated to version $LATEST_TAG on $(date)" >> ~/artela_update_log.txt

}

# Main Menu
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
        echo "To exit the script, press ctrl+c."
        echo "Please choose an option:"
        echo "1. Install Node"
        echo "2. Create Wallet"
        echo "3. Import Wallet"
        echo "4. Check Wallet Balance"
        echo "5. Check Node Sync Status"
        echo "6. Check Service Status"
        echo "7. View Logs"
        echo "8. Uninstall Node"
        echo "9. Set Alias"
        echo "10. Create Validator"
        echo "11. Delegate to Yourself"
        echo "12. Backup Validator Private Key"
        echo "13. Update This Script"
        echo "14. Upgrade Node Software"
        read -p "Enter option (1-14): " OPTION

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
        14) update_node ;;
        *) echo "Invalid option." ;;
        esac
        echo "Press any key to return to the main menu..."
        read -n 1
    done
}

# Show Main Menu
main_menu
