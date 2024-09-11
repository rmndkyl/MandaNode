#!/bin/bash

# Function to log messages
log() {
    level=$1
    message=$2
    echo "[$level] $message"
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i', then run this script again."
    exit 1
fi

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if UFW is installed and set up the firewall
check_and_install_ufw() {
    log "info" "Checking if UFW is installed..."
    if ! command -v ufw &> /dev/null; then
        log "info" "UFW is not installed. Installing UFW..."
        apt-get update -y && apt-get install ufw -y
    else
        log "info" "UFW is already installed."
    fi

    log "info" "Allowing necessary ports (22, 5000)..."
    ufw allow 22/tcp
    ufw allow 5000/tcp
    ufw --force enable
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Install Rainbow Protocol nodes
install_nodes() {
    log "info" "Installing Rainbow Protocol node..."

    log "info" "Prompting for Bitcoin Core username and password"
    read -p "Enter your Bitcoin Core username: " BTC_USERNAME
    read -p "Enter your Bitcoin Core password: " BTC_PASSWORD
    echo

    log "info" "Setting up directories and cloning the repository"
    mkdir -p /root/project/run_btc_testnet4/data
    cd /root/project/run_btc_testnet4
    git clone https://github.com/mocacinno/btc_testnet4
    cd btc_testnet4
    git switch bci_node

    log "info" "Editing docker-compose.yml with VPS IP, username, and password"
    VPS_IP=$(hostname -I | awk '{print $1}')
    sed -i "s/<replace_with_vps_ip>/$VPS_IP/g" docker-compose.yml
    sed -i "s/<replace_with_username>/$BTC_USERNAME/g" docker-compose.yml
    sed -i "s/<replace_with_password>/$BTC_PASSWORD/g" docker-compose.yml

    log "info" "Starting Bitcoin Core with Docker Compose"
    docker-compose up -d
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Create a new wallet for Bitcoin Core
create_wallet() {
    log "info" "Creating a new wallet in Bitcoin Core..."

    # Check if the bitcoind container is running
    if [ "$(docker ps -q -f name=bitcoind)" ]; then
        docker exec -it bitcoind /bin/bash <<EOF
        bitcoin-cli -testnet4 -rpcuser=$BTC_USERNAME -rpcpassword=$BTC_PASSWORD -rpcport=5000 createwallet yourwalletname
        exit
EOF
        log "info" "Wallet created successfully."
    else
        log "error" "Bitcoin Core container 'bitcoind' not found or not running."
        log "info" "Make sure the node is installed and running before creating a wallet."
    fi
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# View logs of the Bitcoin Core and the indexer
view_logs() {
    log "info" "Viewing Bitcoin Core logs:"
    docker logs bitcoind
    log "info" "To view indexer logs, check the output in your terminal."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Restart Rainbow Protocol nodes
restart_nodes() {
    log "info" "Restarting Rainbow Protocol node..."
    docker-compose down
    docker-compose up -d
    log "info" "Node restarted successfully."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Update Rainbow Protocol nodes
update_nodes() {
    log "info" "Updating Rainbow Protocol node..."
    cd /root/project/run_btc_testnet4
    git pull
    docker-compose down
    docker-compose up -d
    log "info" "Node updated successfully."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Main menu function
main_menu() {
    while true; do
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
        echo "1. Check and Install UFW"
        echo "2. Install Rainbow Protocol Nodes"
        echo "3. Create Wallet"
        echo "4. View Logs"
        echo "5. Restart Nodes"
        echo "6. Update Nodes"
        echo "7. Exit"
		echo "==========================================================================================="
        read -p "Choose an option (1-7): " choice

        case $choice in
            1)
                check_and_install_ufw
                ;;
            2)
                install_nodes
                ;;
            3)
                create_wallet
                ;;
            4)
                view_logs
                ;;
            5)
                restart_nodes
                ;;
            6)
                update_nodes
                ;;
            7)
                log "info" "Exiting script."
                exit 0
                ;;
            *)
                log "error" "Invalid option. Please choose a number between 1 and 7." 
                read -n 1 -s -r -p "Press any key to continue..."
                ;;
        esac
    done
}

# Start by showing the main menu
main_menu
