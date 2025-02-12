#!/bin/bash

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Check if the script is run with root user privileges
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run with root user permissions."
    echo "Please try using the 'sudo -i' command to switch to the root user, then run this script again."
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

# Check Go environment
function check_go_installation() {
    if command -v go > /dev/null 2>&1; then
        echo "Go environment is already installed"
        return 0
    else
        echo "Go environment is not installed, installing..."
        return 1
    fi
}

# Validator node installation function
function install_validator() {

    install_nodejs_and_npm
    install_pm2

    # Check if curl is installed, install if not
    if ! command -v curl > /dev/null; then
        sudo apt update && sudo apt install curl -y
    fi

    # Update and install necessary software
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

    # Download binary
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

    # Configure node
    SEEDS="bac83a636b003495b2aa6bb123d1450c2ab1a364@og-testnet-seed.itrocket.net:47656"
    PEERS="80fa309afab4a35323018ac70a40a446d3ae9caf@og-testnet-peer.itrocket.net:11656,407e52882cd3e9027c3979742c38f4d655334ee1@185.239.208.65:12656,3b8df79c5322dcb2d25aa8d10f886461fcbb93a5@161.97.89.237:12656,1dd9da1053e932e7c287c94191c418212c96da96@157.173.125.137:26656,1469b5aba1c6401bc191fa5a6fabbc6e02720add@62.171.156.121:12656,af4fe9d510848eb952110da4b03b7ca696d46a3a@84.247.191.112:12656,c30554e3c291acacf327c717beb5c01fc7acf9c1@109.123.253.9:12656,80aead3e238fca6805c37be8b780c99b0e934daf@77.237.246.197:12656,8db25df522e76176b00ab184df972b86bf72cd22@161.97.103.44:12656,e142f3cb55585a1987faa01f5c70de51aa82dd13@31.220.81.231:12656,4a77eb8103ada3687be7038ab722b611acc832be@158.220.111.17:12656,6e9edc59c3a6495bf5769c23fc37dc9756e258d3@161.97.110.78:12656,4ebff8cc1d7fb899643228d367b8e5395b6cb4ca@62.171.189.13:12656,492453098ed9c42e214d5bd3d4bb84113c92571c@89.116.27.67:12656,0f835342124117a4a5f0177c049bf57802de959c@5.252.54.96:47656,c3674c176cf70b8832930bd0c01d57cd1df292ac@161.97.78.57:12656"
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
    curl -o - -L https://config-t.noders.services/og/data.tar.lz4 | lz4 -d | tar -x -C ~/.0gchain
    mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json

    # Start node process with PM2
    pm2 start 0gchaind -- start --log_output_console --home ~/.0gchain && pm2 save && pm2 startup
    pm2 restart 0gchaind

    echo '====================== Installation complete, please exit the script and execute source $HOME/.bash_profile to load environment variables ==========================='

}

# Check PM2 service status
function check_service_status() {
    pm2 list
}

# Validator node log query
function view_logs() {
    pm2 logs 0gchaind
}

# Node uninstallation function
function uninstall_validator() {
    echo "Are you sure you want to uninstall the 0gchain validator node program? This will delete all related data. [Y/N]"
    read -r -p "Please confirm: " response

    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Starting node program uninstallation..."
            pm2 stop 0gchaind && pm2 delete 0gchaind
            rm -rf $HOME/.0gchain $(which 0gchaind)  $HOME/0g-chain
            echo "Node program uninstallation completed."
            ;;
        *)
            echo "Uninstallation cancelled."
            ;;
    esac
}

# Create wallet
function add_wallet() {
    read -p "Please enter the wallet name you want to set: " wallet_name
    0gchaind keys add $wallet_name --eth
}

# Import wallet
function import_wallet() {
    read -p "Please enter the wallet name you want to set: " wallet_name
    0gchaind keys add $wallet_name --recover --eth
}

# Check balance
function check_balances() {
    echo "Please ensure synchronization to the latest block before checking balance"
    read -p "Please enter wallet address: " wallet_address
    0gchaind query bank balances "$wallet_address"
}

# Check node sync status
function check_sync_status() {
    0gchaind status | jq .sync_info
}

# Create validator
function add_validator() {

    read -p "Please enter your wallet name: " wallet_name
    read -p "Please enter the name you want to set for your validator: " validator_name
    read -p "Please enter your validator details (e.g., 'Dumb Capital'): " details


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

# Self-delegate to validator
function delegate_self_validator() {
    read -p "Please enter the number of tokens to stake (in ua0gai, for example, if you have 1000000 ua0gai, leave some water for yourself, enter 900000): " math
    read -p "Please enter wallet name: " wallet_name
    0gchaind tx staking delegate $(0gchaind keys show $wallet_name --bech val -a) ${math}ua0gi --from $wallet_name   --gas=auto --gas-adjustment=1.4 -y

}

# Unjail validator
function unjail_validator() {
    read -p "Please enter your wallet name: " wallet_name
    0gchaind tx slashing unjail --from $wallet_name --chain-id zgtendermint_16600-2 --gas=auto --gas-adjustment=1.4
}

# Withdraw validator rewards
function withdraw_rewards() {
    read -p "Please enter your wallet name: " wallet_name
    0gchaind tx distribution withdraw-rewards $(0gchaind keys show $wallet_name --bech val -a) --from $wallet_name --commission --chain-id zgtendermint_16600-2 --gas=auto --gas-adjustment=1.4 -y
}

# Edit validator information
function edit_validator() {
    read -p "Please enter wallet name: " wallet_name
    read -p "Please enter new moniker (validator name): " new_moniker
    read -p "Please enter new details: " new_details

    0gchaind tx staking edit-validator \
    --new-moniker="$new_moniker" \
    --details="$new_details" \
    --from=$wallet_name \
    --chain-id=zgtendermint_16600-2 \
    --gas=auto \
    --gas-adjustment=1.4
}

# Main menu
function main_menu() {
    while true; do
        clear
        echo "================================="
        echo "0G Chain Node Management Menu"
        echo "================================="
        echo "0. Install Validator Node"
        echo "1. Check Service Status"
        echo "2. View Node Logs"
        echo "3. Uninstall Node"
        echo "4. Create New Wallet"
        echo "5. Import Wallet"
        echo "6. Check Wallet Balance"
        echo "7. Check Node Sync Status"
        echo "8. Create Validator"
        echo "9. Self-Delegate to Validator"
        echo "10. Unjail Validator"
        echo "11. Withdraw Validator Rewards"
        echo "12. Edit Validator Information"
        echo "13. Exit"
        echo "================================="
        read -p "Please enter your choice (0-13): " choice

        case $choice in
            0) install_validator ;;
            1) check_service_status ;;
            2) view_logs ;;
            3) uninstall_validator ;;
            4) add_wallet ;;
            5) import_wallet ;;
            6) check_balances ;;
            7) check_sync_status ;;
            8) add_validator ;;
            9) delegate_self_validator ;;
            10) unjail_validator ;;
            11) withdraw_rewards ;;
            12) edit_validator ;;
            13) exit 0 ;;
            *) 
                echo "Invalid option, please try again."
                sleep 2
                ;;
        esac
    done
}

# Community group information
function community_group() {
    clear
    echo "============================"
    echo "0G Community Groups"
    echo "============================"
    echo "Telegram Community: https://t.me/layerairdrop"
    echo "Discord Group: https://discord.gg/0glabs"
    echo "Twitter/X: https://twitter.com/0G_labs"
    echo "============================"
    read -p "Press Enter to return to main menu"
}

# Script startup
main_menu
