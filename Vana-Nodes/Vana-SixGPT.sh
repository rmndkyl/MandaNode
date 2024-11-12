#!/bin/bash

# Color codes for enhanced readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Showing Logo
echo -e "${GREEN}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/Vana-SixGPT.sh"

# Check if the script is run as the root user
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script requires root user permissions to run.${NC}"
    echo "Please try switching to the root user using the 'sudo -i' command and run this script again."
    exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}============================ Vana SixGPT Installation ====================================${NC}"
        echo -e "${YELLOW}Node community Telegram channel:${NC} https://t.me/layerairdrop"
        echo -e "${YELLOW}Node community Telegram group:${NC} https://t.me/+UgQeEnnWrodiNTI1"
        echo -e "${GREEN}Script and tutorial by Telegram user @rmndkyl, free and open source, do not believe in paid versions${NC}"
        echo "To exit the script, press ctrl + C."
        echo -e "${GREEN}Please choose the operation you want to perform:${NC}"
        echo -e "1) Start Node"
        echo -e "2) View Logs"
        echo -e "3) Restart Node"
        echo -e "4) Delete Node"
        echo -e "5) Exit"
        
        read -p "Please enter the number of your choice: " choice
        
        case $choice in
            1)
                start_node
                ;;
            2)
                view_logs
                ;;
            3) 
                restart_node
                ;;
            4)
                delete_node
                ;;
            5)
                echo -e "${GREEN}Exiting the script.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice, please try again.${NC}"
                read -p "Press any key to continue..."
                ;;
        esac
    done
}

# Function to start the node
function start_node() {
    # Update package list and upgrade installed packages
    echo -e "${YELLOW}Updating packages...${NC}"
    sudo apt update -y && sudo apt upgrade -y

    # Install required dependencies
    echo -e "${YELLOW}Installing required dependencies...${NC}"
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker is not installed, installing Docker...${NC}"
        
        # Install Docker
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y
        sudo apt install -y docker-ce

        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker

        echo -e "${GREEN}Docker installation complete!${NC}"
    else
        echo -e "${GREEN}Docker is already installed, skipping installation.${NC}"
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose is not installed, installing Docker Compose...${NC}"
        
        # Get the latest version number and install Docker Compose
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo -e "${GREEN}Docker Compose installation complete!${NC}"
    else
        echo -e "${GREEN}Docker Compose is already installed, skipping installation.${NC}"
    fi

    # Display Docker Compose version
    docker-compose --version

    # Add the current user to the Docker group
    if ! getent group docker > /dev/null; then
        echo -e "${YELLOW}Creating Docker group...${NC}"
        sudo groupadd docker
    fi

    echo -e "${YELLOW}Adding user $USER to the Docker group...${NC}"
    sudo usermod -aG docker $USER

    # Create directory and set environment variables
    mkdir -p ~/sixgpt
    cd ~/sixgpt

    # Prompt user for private key and select network
    read -p "Please enter your private key (your_private_key): " PRIVATE_KEY
    export VANA_PRIVATE_KEY=$PRIVATE_KEY

    # Select network
    echo -e "${BLUE}Please select a network:${NC}"
    echo -e "${YELLOW}1) satori (UNAVAILABLE!)"
    echo -e "2) moksha (CHOOSE THIS!)${NC}"
    read -p "Please enter the number of your choice: " NETWORK_CHOICE

    case $NETWORK_CHOICE in
        1)
            export VANA_NETWORK="satori"
            ;;
        2)
            export VANA_NETWORK="moksha"
            ;;
        *)
            echo -e "${RED}Invalid choice, defaulting to moksha.${NC}"
            export VANA_NETWORK="moksha"
            ;;
    esac

    echo -e "${GREEN}Selected network: $VANA_NETWORK${NC}"

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
      - OLLAMA_API_URL=http://ollama:11434/api
    restart: always

volumes:
  ollama:
EOL

    # Start Docker Compose
    echo -e "${GREEN}Starting Docker Compose...${NC}"
    docker-compose up -d
    echo -e "${GREEN}Docker Compose has started!${NC}"
    echo -e "${GREEN}All operations completed! Please log out and back in to apply group changes.${NC}"

    read -p "Press any key to return to the main menu..."
}

# Function to view logs
function view_logs() {
    echo -e "${YELLOW}Viewing Docker Compose logs...${NC}"
    cd $HOME/sixgpt && docker-compose logs -f
    read -p "Press any key to return to the main menu..."
}

# Function to restart the node
function restart_node() {
    echo -e "${YELLOW}Entering /root/sixgpt directory...${NC}"
    cd /root/sixgpt || { echo -e "${RED}Directory does not exist!${NC}"; return; }

    echo -e "${GREEN}Restarting all Docker Compose services...${NC}"
    docker-compose restart
    echo -e "${GREEN}All Docker Compose services have been restarted!${NC}"
    
    read -p "Press any key to return to the main menu..."
}

# Function to delete the node
function delete_node() {
    echo -e "${YELLOW}Entering /root/sixgpt directory...${NC}"
    cd /root/sixgpt || { echo -e "${RED}Directory does not exist!${NC}"; return; }

    echo -e "${RED}Stopping all Docker Compose services...${NC}"
    docker-compose down
    echo -e "${GREEN}All Docker Compose services have been stopped!${NC}"
    
    read -p "Press any key to return to the main menu..."
}

# Call the main menu function to start the script
main_menu
