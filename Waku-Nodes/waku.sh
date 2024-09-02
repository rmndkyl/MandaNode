#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try switching to the root user using 'sudo -i', then run this script again."
    exit 1
fi

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/Waku.sh"

# Main menu function
function main_menu() {
    while true; do
        clear
		echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
		echo "============================ Nesa Node Installation ===================================="
		echo "Node community Telegram channel: https://t.me/layerairdrop"
		echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press Ctrl+C on your keyboard."
        echo "Please choose an action:"
        echo "1. Install Node"
        echo "2. Fix Errors (currently unavailable, official script has issues)"
        echo "3. Update Script"
        echo "4. Exit"
        read -rp "Please enter your choice: " choice

        case $choice in
            1)
                install_node
                ;;
            2)
                fix_errors
                ;;
            3)
                update_script
                ;;
            4)
                echo "Exiting the script, thank you for using it!"
                exit 0
                ;;
            *)
                echo "Invalid choice, please try again."
                sleep 2
                ;;
        esac
    done
}

# Function to install node tools
function install_node_tools() {
    # Update package sources and upgrade system software
    sudo apt update && sudo apt upgrade -y

    # Install necessary software and tools
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev
}

# Function to install Docker
function install_docker() {
    # Install Docker
    sudo apt install -y docker.io

    # Check if docker-compose is installed, if not, install it
    if ! command -v docker-compose &> /dev/null; then
        echo "docker-compose is not installed, installing docker-compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker-compose --version  # Should display docker-compose version 1.29.2
        if command -v docker-compose &> /dev/null; then
            echo "docker-compose installed successfully."
        else
            echo "docker-compose installation failed, please check the error."
            exit 1
        fi
    else
        echo "docker-compose is already installed."
    fi
}

# Function to install the node
function install_node() {
    # Install node tools
    install_node_tools

    # Install Docker
    install_docker

    # Clone or update the nwaku-compose project
    if [ -d "nwaku-compose" ]; then
        echo "Updating nwaku-compose project..."
        cd nwaku-compose || { echo "Failed to enter nwaku-compose directory, please check the error."; exit 1; }
        git stash push --include-untracked
        git pull origin master
        cd ..
    else
        echo "Cloning nwaku-compose project..."
        git clone https://github.com/waku-org/nwaku-compose
    fi

    # Enter the nwaku-compose directory
    cd nwaku-compose || {
        echo "Failed to enter nwaku-compose directory, please check the error."
        exit 1
    }

    echo "Successfully entered the nwaku-compose directory."

    # Copy .env.example to .env
    cp .env.example .env

    echo "Successfully copied .env.example to .env."

    # Edit the .env file using nano
    echo "Now editing the .env file. After editing, press Ctrl+X to save and exit."
    nano .env

    echo ".env file editing complete."

    # Run the register_rln.sh script
    echo "Running the register_rln.sh script..."
    ./register_rln.sh

    echo "register_rln.sh script completed."

    # Start Docker Compose services
    echo "Starting Docker Compose services..."
    docker-compose up -d || { echo "Failed to start Docker Compose services, please check the error."; exit 1; }

    echo "Docker Compose services started successfully."
    read -rp "Press Enter to return to the menu."
}

# Function to fix errors
function fix_errors() {
    # Stop Docker Compose services
    docker-compose down

    # Enter the nwaku-compose directory
    cd nwaku-compose || { echo "Failed to enter the nwaku-compose directory, please check the error."; exit 1; }

    # Perform git stash and git pull operations
    git stash push --include-untracked
    git pull origin master

    # Delete keystore and rln_tree directories
    rm -rf keystore rln_tree

    # Edit the .env file
    echo "Please modify the ETH_CLIENT_ADDRESS in the .env file to RLN_RELAY_ETH_CLIENT_ADDRESS."
    nano -i .env

    # Start Docker Compose
    docker-compose up -d || { echo "Failed to start Docker Compose, please check the error."; exit 1; }

    echo "Error fixing completed."
    read -rp "Press Enter to return to the menu."
}

# Function to update the script
function update_script() {
    echo "Updating the nwaku-compose project..."
    
    # Enter the nwaku-compose directory
    cd nwaku-compose || { echo "Failed to enter the nwaku-compose directory, please check the error."; exit 1; }
    
    # Stop Docker Compose services
    docker-compose down
    
    # Update the project
    git pull origin master
    
    # Restart Docker Compose services
    docker-compose up -d || { echo "Failed to start Docker Compose, please check the error."; exit 1; }
    
    echo "Script update completed."
    read -rp "Press Enter to return to the menu."
}

# Start the main program
main_menu