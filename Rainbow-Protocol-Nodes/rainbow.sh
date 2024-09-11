#!/bin/bash

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
    echo "1. Check and Install Docker"
    echo "2. Install Rainbow Node"
    echo "3. Start Node"
    echo "4. Check Principal ID and Private Key (keep it safely)"
    echo "5. Check Node Status"
    echo "6. View Logs"
    echo "7. Restart Node"
    echo "8. Stop Node"
    echo "9. Update Node"
    echo "10. Exit"

    read -p "Choose an option [1-10]: " choice
    case $choice in
        1) check_install_docker ;;
        2) install_rainbow_node ;;
        3) start_node ;;
        4) check_principal_id_and_private_key ;;
        5) check_node_status ;;
        6) view_logs ;;
        7) restart_node ;;
        8) stop_node ;;
        9) update_node ;;
        10) exit 0 ;;
        *) echo "Invalid choice. Please choose again." && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

check_install_docker() {
    echo "Checking Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Installing Docker..."
        sudo apt update && sudo apt install -y docker.io
    else
        echo "Docker is already installed."
    fi
    docker --version
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

install_rainbow_node() {
    echo "Installing Rainbow Node..."
    cd $HOME
    git clone https://github.com/rainbowprotocol-xyz/rbo_indexer_testnet.git
    cd rbo_indexer_testnet
    wget https://github.com/rainbowprotocol-xyz/rbo_indexer_testnet/releases/download/v0.0.1-alpha/rbo_worker
    chmod +x rbo_worker
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

start_node() {
    echo "Starting Rainbow Node..."
    ./rbo_worker worker --rpc http://127.0.0.1:5000 --password $BTC_RPC_PASS --username $BTC_RPC_USER --start_height 42000
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

check_principal_id_and_private_key() {
    echo "Checking Principal ID and Private Key..."
    cat rbo_indexer_testnet/identity/principal.json
    cat rbo_indexer_testnet/identity/private_key.pem
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

check_node_status() {
    echo "Checking Node Status..."
    docker ps
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

view_logs() {
    echo "Viewing Logs..."
    docker logs $(docker ps -q)  # Assuming there's only one container running
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

restart_node() {
    echo "Restarting Node..."
    docker restart $(docker ps -q)  # Assuming there's only one container running
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

stop_node() {
    echo "Stopping Node..."
    docker stop $(docker ps -q)  # Assuming there's only one container running
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

update_node() {
    echo "Updating Node..."
    cd rbo_indexer_testnet
    git pull origin main
    wget https://github.com/rainbowprotocol-xyz/rbo_indexer_testnet/releases/download/v0.0.1-alpha/rbo_worker -O rbo_worker
    chmod +x rbo_worker
    read -n 1 -s -r -p "Press any key to continue..." && main_menu
}

main_menu
