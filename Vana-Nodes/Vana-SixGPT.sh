#!/bin/bash

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/Vana-SixGPT.sh"

# Check if the script is run as the root user
if [ "$(id -u)" != "0" ]; then
    echo "This script requires root user permissions to run."
    echo "Please try switching to the root user using the 'sudo -i' command and run this script again."
    exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Vana SixGPT Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl + C."
        echo "Please choose the operation you want to perform:"
        echo "1) Start Node"
        echo "2) View Logs"
        echo "3) Delete Node"
        echo "4) Exit"
        
        read -p "Please enter the number of your choice: " choice
        
        case $choice in
            1)
                start_node
                ;;
            2)
                view_logs
                ;;
            3)
                delete_node
                ;;
            4)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid choice, please try again."
                read -p "Press any key to continue..."
                ;;
        esac
    done
}

# Function to start the node
function start_node() {
    # Update package list and upgrade installed packages
    sudo apt update -y && sudo apt upgrade -y

    # Install required dependencies
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed, installing Docker..."
        
        # Install Docker
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y
        sudo apt install -y docker-ce

        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker

        echo "Docker installation complete!"
    else
        echo "Docker is already installed, skipping installation."
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed, installing Docker Compose..."
        
        # Get the latest version number and install Docker Compose
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo "Docker Compose installation complete!"
    else
        echo "Docker Compose is already installed, skipping installation."
    fi

    # Display Docker Compose version
    docker-compose --version

    # Add the current user to the Docker group
    if ! getent group docker > /dev/null; then
        echo "Creating Docker group..."
        sudo groupadd docker
    fi

    echo "Adding user $USER to the Docker group..."
    sudo usermod -aG docker $USER

    # Create directory and set environment variables
    mkdir -p ~/sixgpt
    cd ~/sixgpt

    # Prompt user for private key and select network
    read -p "Please enter your private key (your_private_key): " PRIVATE_KEY
    export VANA_PRIVATE_KEY=$PRIVATE_KEY

    # Select network
    echo "Please select a network (enter number 1 or 2):"
    echo "1) satori"
    echo "2) moksha"
    read -p "Please enter the number of your choice: " NETWORK_CHOICE

    case $NETWORK_CHOICE in
        1)
            export VANA_NETWORK="satori"
            ;;
        2)
            export VANA_NETWORK="moksha"
            ;;
        *)
            echo "Invalid choice, defaulting to satori."
            export VANA_NETWORK="satori"
            ;;
    esac

    echo "Selected network: $VANA_NETWORK"

    # Create docker-compose.yml file
    cat <<EOL > docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11439:11434"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped
 
  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3000:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=\${VANA_PRIVATE_KEY}
      - VANA_NETWORK=\${VANA_NETWORK}
    restart: always

volumes:
  ollama:
EOL

    # Start Docker Compose
    echo "Starting Docker Compose..."
    docker-compose up -d
    echo "Docker Compose has started!"
    echo "All operations completed! Please log out and back in to apply group changes."

    read -p "Press any key to return to the main menu..."
}

# Function to view logs
function view_logs() {
    echo "Viewing Docker Compose logs..."
    cd $HOME/sixgpt && docker-compose logs -f
    read -p "Press any key to return to the main menu..."
}

# Function to delete the node
function delete_node() {
    echo "Entering /root/sixgpt directory..."
    cd /root/sixgpt || { echo "Directory does not exist!"; return; }

    echo "Stopping all Docker Compose services..."
    docker-compose down
    echo "All Docker Compose services have been stopped!"
    
    read -p "Press any key to return to the main menu..."
}

# Call the main menu function to start the script
main_menu
