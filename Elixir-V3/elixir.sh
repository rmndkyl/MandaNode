#!/bin/bash

# Set color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as root.${NC}"
    echo "Please try using the 'sudo -i' command to switch to the root user, then run this script again."
    exit 1
fi

# Showing Logo
echo -e "${CYAN}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh 
sleep 4

# System update and dependency installation
echo -e "${BLUE}Updating and upgrading system...${NC}"
apt update && apt upgrade -y

echo -e "${BLUE}Installing dependencies...${NC}"
apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

# Check for existing Docker installation
if dpkg -l | grep -q 'docker'; then
    echo -e "${YELLOW}Docker is already installed. Skipping removal of existing Docker packages.${NC}"
else
    echo -e "${YELLOW}Removing conflicting Docker packages if any...${NC}"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
        apt-get remove -y $pkg || true  
    done
fi

# Add Docker GPG key and repository
echo -e "${BLUE}Adding Docker GPG key and repository...${NC}"
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
else
    echo -e "${YELLOW}Docker GPG key already exists. Skipping download.${NC}"
fi
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
echo -e "${BLUE}Installing Docker...${NC}"
apt update -y && apt upgrade -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation
echo -e "${GREEN}Docker version: $(docker --version)${NC}"

# Script save path
SCRIPT_PATH="$HOME/ElixirV3.sh"

# Node installation function
function install_node() {
    default_ip="localhost"
    read -p "Enter the IP address of the validator node device [default: ${default_ip}]: " ip_address
    ip_address=${ip_address:-$default_ip}
    read -p "Enter the display name of the validator node: " validator_name
    read -p "Enter the reward address of the validator node: " safe_public_address
    read -p "Enter the signer's private key, without 0x: " private_key

    cat <<EOF > validator.env
ENV=testnet-3
STRATEGY_EXECUTOR_IP_ADDRESS=${ip_address}
STRATEGY_EXECUTOR_DISPLAY_NAME=${validator_name}
STRATEGY_EXECUTOR_BENEFICIARY=${safe_public_address}
SIGNER_PRIVATE_KEY=${private_key}
EOF

    echo -e "${GREEN}Environment variables have been saved to validator.env.${NC}"

    echo -e "${BLUE}Pulling Elixir Validator Docker image...${NC}"
    docker pull elixirprotocol/validator:v3

    read -p "Are you running on Apple/ARM architecture? (y/n): " is_arm

    if [[ "$is_arm" == "y" ]]; then
        echo -e "${CYAN}Running on Apple/ARM architecture...${NC}"
        docker run -d \
          --env-file validator.env \
          --name elixir \
          --platform linux/amd64 \
          --restart unless-stopped \
          -p 17690:17690 \
          elixirprotocol/validator:v3
    else
        echo -e "${CYAN}Running on standard architecture...${NC}"
        docker run -d \
          --env-file validator.env \
          --name elixir \
          --restart unless-stopped \
          -p 17690:17690 \
          elixirprotocol/validator:v3
    fi
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# View Docker logs function
function check_docker_logs() {
    echo -e "${BLUE}Viewing logs of the Elixir Docker container...${NC}"
    docker logs -f elixir
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Delete Docker container function
function delete_docker_container() {
    echo -e "${RED}Deleting the Elixir Docker container...${NC}"
    docker stop elixir && docker rm elixir && echo -e "${GREEN}Elixir Docker container has been deleted.${NC}"
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Validator Health Status function
function check_validator_health() {
    echo -e "${BLUE}Checking Validator Health Status...${NC}"
    curl 127.0.0.1:17690/health | jq
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Main menu
function main_menu() {
    clear
    echo -e "${YELLOW}Script by Telegram user @rmndkyl, free and open source. Do not believe in paid versions.${NC}"
    echo -e "${CYAN}============================ Elixir V3 Node Installation ====================================${NC}"
    echo -e "${CYAN}Node community Telegram channel: https://t.me/layerairdrop${NC}"
    echo -e "${CYAN}Node community Telegram group: https://t.me/layerairdropdiskusi${NC}"
    echo -e "${GREEN}Please select an option:${NC}"
    echo -e "${YELLOW}1.${NC} Install Elixir V3 Node"
    echo -e "${YELLOW}2.${NC} View Docker Logs"
    echo -e "${YELLOW}3.${NC} Delete Elixir Docker Container"
    echo -e "${YELLOW}4.${NC} Check Validator Health Status"
    read -p "Please enter an option (1-4): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_docker_logs ;;
    3) delete_docker_container ;;
    4) check_validator_health ;;
    *) echo -e "${RED}Invalid choice. Please choose again.${NC}" && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

# Display the main menu
main_menu
