#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for a spinner animation
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep "$pid")" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as root.${NC}"
    echo -e "${YELLOW}Please try switching to the root user using 'sudo -i', then run this script again.${NC}"
    exit 1
fi

echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/waku.sh"

# Main menu function
function main_menu() {
    while true; do
        clear
        echo -e "${BLUE}============================ Waku Node Installation ====================================${NC}"
        echo -e "${GREEN}Script and tutorial written by Telegram user @rmndkyl, free and open source.${NC}"
        echo -e "${YELLOW}Do not believe in paid versions!${NC}"
        echo -e "${BLUE}Node community Telegram channel: https://t.me/layerairdrop${NC}"
        echo -e "${BLUE}Node community Telegram group: https://t.me/layerairdropdiskusi${NC}"
        echo "To exit the script, press Ctrl+C on your keyboard."
        echo -e "${BLUE}Please choose an action:${NC}"
        echo "1. Install Node"
        echo "2. Fix Errors (currently unavailable, official script has issues)"
        echo "3. Update Script"
        echo "4. Install Multiple Nodes"
        echo "5. Exit"
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
                install_multiple_nodes
                ;;
            5)
                echo -e "${GREEN}Exiting the script, thank you for using it!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice, please try again.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Function to check if a port is available and prompt for a new port if needed
function check_port_and_update_grafana() {
    local default_port=3000

    # Check if port 3000 is already in use
    if lsof -i:"$default_port" >/dev/null; then
        echo -e "${YELLOW}Port $default_port is already in use.${NC}"

        # Prompt for an alternate port
        read -rp "Enter an alternative port for Grafana: " new_port

        # Update the port in docker-compose.yml
        sed -i "s|$default_port:3000|$new_port:3000|g" docker-compose.yml

        echo -e "${GREEN}Updated Grafana to use port $new_port instead of $default_port.${NC}"
    else
        echo -e "${GREEN}Port $default_port is available. Proceeding with the default port.${NC}"
    fi
}

# Function to install multiple nodes
function install_multiple_nodes() {
    # Check nwaku-compose directory and create a new one if necessary
    base_dir="$HOME/nwaku-compose"
    new_dir="$base_dir"
    counter=1

    while [ -d "$new_dir" ]; do
        new_dir="${base_dir}${counter}"
        ((counter++))
    done

    echo "Cloning nwaku-compose project into $new_dir ..."
    git clone https://github.com/waku-org/nwaku-compose "$new_dir" || {
        echo "Failed to clone nwaku-compose, please check the error."
        exit 1
    }

    # Enter the newly created nwaku-compose directory
    cd "$new_dir" || {
        echo "Failed to enter the nwaku-compose directory, please check the error."
        exit 1
    }

    echo "Successfully entered the nwaku-compose directory."

    # Copy .env.example to .env
    cp .env.example .env
    echo "Successfully copied .env.example to .env."

    # Get user input and update the .env file
    read -rp "Enter your Infura project key: " infura_key
    read -rp "Enter your testnet private key (without 0x at the start): " testnet_private_key
    read -rp "Enter your keystore password: " keystore_password

    # Use sed to replace placeholders in .env file
    sed -i "s|<key>|$infura_key|g" .env
    sed -i "s|<YOUR_TESTNET_PRIVATE_KEY_HERE>|$testnet_private_key|g" .env
    sed -i "s|my_secure_keystore_password|$keystore_password|g" .env

    echo ".env file has been updated."

    # Get user input for ports
    read -rp "Enter the first port: " port1
    read -rp "Enter the second port: " port2

    # Update ports in docker-compose.yml
    sed -i "s|^\s*- [0-9]*:|  - $port1:|g" docker-compose.yml
    sed -i "s|^\s*- [0-9]*:|  - $port2:|g" docker-compose.yml

    echo "Ports in docker-compose.yml have been updated."

    # Run the register_rln.sh script
    echo "Running the register_rln.sh script..."
    ./register_rln.sh

    echo "register_rln.sh script completed."
	
	# Check Port
	check_port_and_update_grafana

    # Start Docker Compose services
    echo "Starting Docker Compose services..."
    docker-compose up -d || { echo "Failed to start Docker Compose services, please check the error."; exit 1; }

    echo "Docker Compose services started successfully."
    read -rp "Press Enter to return to the menu."
}

# Function to install node tools
function install_node_tools() {
    echo -e "${BLUE}Updating package sources and upgrading system software...${NC}"
    sudo apt update && sudo apt upgrade -y & spinner
    echo -e "${GREEN}System updated successfully.${NC}"

    echo -e "${BLUE}Installing necessary software and tools...${NC}"
    sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev & spinner
    echo -e "${GREEN}Node tools installed successfully.${NC}"
}

# Function to install Docker
function install_docker() {
    echo -e "${BLUE}Installing Docker...${NC}"
    sudo apt install -y docker.io & spinner

    # Check if docker-compose is installed, if not, install it
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}docker-compose is not installed, installing docker-compose...${NC}"
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker-compose --version
        if command -v docker-compose &> /dev/null; then
            echo -e "${GREEN}docker-compose installed successfully.${NC}"
        else
            echo -e "${RED}docker-compose installation failed, please check the error.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}docker-compose is already installed.${NC}"
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
        echo -e "${BLUE}Updating nwaku-compose project...${NC}"
        cd nwaku-compose || { echo -e "${RED}Failed to enter nwaku-compose directory, please check the error.${NC}"; exit 1; }
        git stash push --include-untracked
        git pull origin master
        cd ..
    else
        echo -e "${BLUE}Cloning nwaku-compose project...${NC}"
        git clone https://github.com/waku-org/nwaku-compose
    fi

    # Enter the nwaku-compose directory
    cd nwaku-compose || {
        echo -e "${RED}Failed to enter nwaku-compose directory, please check the error.${NC}"
        exit 1
    }

    echo -e "${GREEN}Successfully entered the nwaku-compose directory.${NC}"

    # Copy .env.example to .env
    cp .env.example .env
    echo -e "${GREEN}Successfully copied .env.example to .env.${NC}"

    # Edit the .env file using nano
    echo -e "${BLUE}Now editing the .env file. After editing, press Ctrl+X to save and exit.${NC}"
    nano .env
    echo -e "${GREEN}.env file editing complete.${NC}"

    # Run the register_rln.sh script
    echo -e "${BLUE}Running the register_rln.sh script...${NC}"
    ./register_rln.sh
    echo -e "${GREEN}register_rln.sh script completed.${NC}"
	
	# Check Port
	check_port_and_update_grafana

    # Start Docker Compose services
    echo -e "${BLUE}Starting Docker Compose services...${NC}"
    docker-compose up -d || { echo -e "${RED}Failed to start Docker Compose services, please check the error.${NC}"; exit 1; }
    echo -e "${GREEN}Docker Compose services started successfully.${NC}"
    read -rp "Press Enter to return to the menu."
}

# Function to fix errors
function fix_errors() {
    echo -e "${BLUE}Stopping Docker Compose services...${NC}"
    docker-compose down

    cd nwaku-compose || { echo -e "${RED}Failed to enter the nwaku-compose directory, please check the error.${NC}"; exit 1; }

    echo -e "${BLUE}Performing git stash and git pull operations...${NC}"
    git stash push --include-untracked
    git pull origin master

    echo -e "${YELLOW}Deleting keystore and rln_tree directories...${NC}"
    rm -rf keystore rln_tree

    echo -e "${BLUE}Please modify the ETH_CLIENT_ADDRESS in the .env file to RLN_RELAY_ETH_CLIENT_ADDRESS.${NC}"
    nano -i .env

    echo -e "${BLUE}Starting Docker Compose...${NC}"
    docker-compose up -d || { echo -e "${RED}Failed to start Docker Compose, please check the error.${NC}"; exit 1; }
    echo -e "${GREEN}Error fixing completed.${NC}"
    read -rp "Press Enter to return to the menu."
}

# Function to update the script
function update_script() {
    echo -e "${BLUE}Updating the nwaku-compose project...${NC}"
    
    cd nwaku-compose || { echo -e "${RED}Failed to enter the nwaku-compose directory, please check the error.${NC}"; exit 1; }
    
    echo -e "${BLUE}Stopping Docker Compose services...${NC}"
    docker-compose down
    
    echo -e "${BLUE}Updating the project...${NC}"
    git pull origin master
    
    echo -e "${BLUE}Restarting Docker Compose services...${NC}"
    docker-compose up -d || { echo -e "${RED}Failed to start Docker Compose, please check the error.${NC}"; exit 1; }
    
    echo -e "${GREEN}Script update completed.${NC}"
    read -rp "Press Enter to return to the menu."
}

# Start the main program
main_menu
