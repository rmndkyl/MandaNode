#!/bin/bash

log() {
    local level=$1
    local message=$2
    echo "[$level] $message"
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i', then run this script again."
    exit 1
fi

# Show animation and logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

main_menu() {
    clear
    echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
    echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
    echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
    echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
    echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
    echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Rainbow Node Installation ===================================="
    echo "Node community Telegram channel: https://t.me/+U3vHFLDNC5JjN2Jl"
    echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    echo "1. Update system, install dependencies, and Docker"
    echo "2. Install and setup Bitcoin Core"
    echo "3. Setup Rainbow Worker, create systemd service, and configure iptables"
    echo "4. Enable and start Rainbow service"
    echo "5. View Rainbow logs"
    echo "6. Get Principal ID"
    echo "7. View private key"
    echo "0. Exit"
    echo -n "Choose an option: "
    read -r choice

    case $choice in
        1) update_and_install ;;
        2) install_and_setup_bitcoin_core ;;
        3) setup_rainbow_worker_and_configure ;;
        4) enable_and_start_rainbow_service ;;
        5) view_logs ;;
        6) get_principal_id ;;
        7) view_private_key ;;
        0) exit 0 ;;
        *) echo "Invalid choice. Please choose again." && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

update_and_install() {
    echo "Updating system, installing dependencies, and Docker..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y
    
    echo "Installing Docker..."
    sudo apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    docker --version
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

install_and_setup_bitcoin_core() {
    echo "Installing and setting up Bitcoin Core..."
    if [ -d "/root/project/run_btc_testnet4" ]; then
        echo "Directory /root/project/run_btc_testnet4 already exists. Removing it..."
        sudo rm -rf /root/project/run_btc_testnet4
        if [ $? -ne 0 ]; then
            echo "Failed to remove the existing directory. Exiting."
            exit 1
        fi
    fi

    mkdir -p /root/project/run_btc_testnet4/data
    git clone https://github.com/rainbowprotocol-xyz/btc_testnet4 /root/project/run_btc_testnet4
    cd /root/project/run_btc_testnet4 || exit

    if [ ! -f "docker-compose.yml" ]; then
        echo "Docker-compose file not found! Creating a default one..."
        cat << EOF > docker-compose.yml
version: '3'
services:
  bitcoind:
    image: ruimarinho/bitcoin-core:22.0
    container_name: bitcoind
    volumes:
      - /root/project/run_btc_testnet4/data:/root/.bitcoin
    command:
      -printtoconsole
      -testnet=1
      -rpcuser=demo
      -rpcpassword=demo
      -rpcport=6000
    ports:
      - "6000:6000"
    environment:
      - BITCOIN_MAX_CONNECTIONS=20
      - BITCOIN_ZMQPUBRAWBLOCK=tcp://0.0.0.0:28332
EOF
    fi

    docker-compose up -d

    echo "Waiting for Bitcoin Core to start..."
    sleep 30  # Increased sleep time to ensure the container is running

    # Check if the container is running
    if [ "$(docker inspect -f '{{.State.Running}}' bitcoind)" != "true" ]; then
        echo "Error: Docker container bitcoind is not running."
        docker-compose logs bitcoind  # View logs for more details
        exit 1
    fi

    echo "Setting up Bitcoin Core wallet..."
    docker exec bitcoind /bin/bash -c "bitcoin-cli -testnet=1 -rpcuser=demo -rpcpassword=demo -rpcport=6000 unloadwallet test || true"
    sleep 5
    docker exec bitcoind /bin/bash -c "bitcoin-cli -testnet=1 -rpcuser=demo -rpcpassword=demo -rpcport=6000 createwallet test && bitcoin-cli -testnet=1 -rpcuser=demo -rpcpassword=demo -rpcport=6000 loadwallet test && bitcoin-cli -testnet=1 -rpcuser=demo -rpcpassword=demo -rpcport=6000 getnewaddress"
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

setup_rainbow_worker_and_configure() {
    echo "Setting up Rainbow Worker, creating systemd service, and configuring iptables..."
    cd $HOME || exit
    git clone https://github.com/rainbowprotocol-xyz/rbo_indexer_testnet.git && cd rbo_indexer_testnet || exit
    wget -O rbo_worker https://github.com/rainbowprotocol-xyz/rbo_indexer_testnet/releases/download/v0.0.1-alpha/rbo_worker
    if [ $? -ne 0 ]; then
        echo "Failed to download rbo_worker. Exiting."
        exit 1
    fi

    chmod +x rbo_worker

    cat << EOF | sudo tee /etc/systemd/system/rainbow.service
[Unit]
Description=Rainbow Worker Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/rbo_indexer_testnet
ExecStart=/root/rbo_indexer_testnet/rbo_worker worker --rpc http://127.0.0.1:6000 --password demo --username demo --start_height 42000
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    echo "Configuring iptables..."
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 2375 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 2376 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 6000 -j ACCEPT  
    sudo sh -c "iptables-save > /etc/iptables/rules.v4"
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

enable_and_start_rainbow_service() {
    echo "Enabling and starting Rainbow service..."
    sudo systemctl daemon-reload
    sudo systemctl enable rainbow
    sudo systemctl start rainbow
    echo "===== Installation Complete ====="
    echo "Rainbow Worker Service is now running."
    echo "You can check the status with: sudo systemctl status rainbow"
    echo "And view logs with: sudo journalctl -u rainbow -f"
    echo "===== Important Information ====="
    echo "Please register your principal ID at: https://testnet.rainbowprotocol.xyz/explorer"
    echo "To get your principal ID, use the following command after a few minutes:"
    echo "cat /root/rbo_indexer_testnet/identity/principal.json"
    echo "===== Installation and setup process is complete ====="
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

view_logs() {
    echo "Viewing Rainbow logs..."
    sudo journalctl -u rainbow -f
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

get_principal_id() {
    echo "Getting Principal ID..."
    if [ -f "/root/rbo_indexer_testnet/identity/principal.json" ]; then
        cat /root/rbo_indexer_testnet/identity/principal.json
        echo "Please register your principal ID at: https://testnet.rainbowprotocol.xyz/explorer"
    else
        echo "Principal ID file not found."
    fi
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

view_private_key() {
    echo "Viewing private key..."
    if [ -f "rbo_indexer_testnet/identity/private_key.pem" ]; then
        cat rbo_indexer_testnet/identity/private_key.pem
        echo "Please make sure to store your private key securely."
    else
        echo "Private key file not found."
    fi
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Start the main menu
main_menu
