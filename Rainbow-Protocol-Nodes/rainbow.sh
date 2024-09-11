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

# Show animation and logo
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

# Check if Docker and Docker Compose are installed
check_and_install_docker() {
    log "info" "Checking if Docker is installed..."
    if ! command -v docker &> /dev/null; then
        log "info" "Docker is not installed. Installing Docker..."
        apt-get update -y
        apt-get install -y docker.io
        systemctl start docker
        systemctl enable docker
    else
        log "info" "Docker is already installed."
    fi

    log "info" "Checking if Docker Compose is installed..."
    if ! command -v docker-compose &> /dev/null; then
        log "info" "Docker Compose is not installed. Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/v2.2.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        log "info" "Docker Compose is already installed."
    fi
}

# Install Rainbow Protocol nodes
install_nodes() {
    log "info" "Installing Rainbow Protocol node..."
    check_and_install_docker

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
        echo "2. Install Docker and Docker Compose"
        echo "3. Install Rainbow Protocol Nodes"
        echo "4. Create Wallet"
        echo "5. View Logs"
        echo "6. Restart Nodes"
        echo "7. Update Nodes"
        echo "8. Exit"
		echo "======================================================================================="
        read -p "Choose an option (1-8): " choice

        case $choice in
            1)
                check_and_install_ufw
                ;;
            2)
                check_and_install_docker
                ;;
            3)
                install_nodes
                ;;
            4)
                create_wallet
                ;;
            5)
                view_logs
                ;;
            6)
                restart_nodes
                ;;
            7)
                update_nodes
                ;;
            8)
                log "info" "Exiting script."
                exit 0
                ;;
            *)
                log "error" "Invalid option. Please choose a number between 1 and 8." && read -n 1 -s -r -p "Press any key to continue..." && main_menu
                ;;
        esac
    done
}

# Start by showing the main menu
main_menu
