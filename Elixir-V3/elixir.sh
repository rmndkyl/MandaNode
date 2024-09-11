#!/bin/bash

set -e

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try using the 'sudo -i' command to switch to the root user, then run this script again."
    exit 1
fi

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# System update and dependency installation
echo "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y

# Check for existing Docker installation
if dpkg -l | grep -q 'docker'; then
    echo "Docker is already installed. Skipping removal of existing Docker packages."
else
    echo "Removing conflicting Docker packages if any..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg || true  
    done
fi

# Add Docker GPG key and repository
echo "Adding Docker GPG key and repository..."
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
else
    echo "Docker GPG key already exists. Skipping download."
fi
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
echo "Installing Docker..."
sudo apt update -y && sudo apt upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Verify Docker installation
docker --version

# Script save path
SCRIPT_PATH="$HOME/ElixirV3.sh"

# Node installation function
function install_node() {
    # Get default IP address (localhost)
    default_ip="localhost"

    # Prompt the user to input environment variable values
    read -p "Please enter the IP address of the validator node device [default: ${default_ip}]: " ip_address
    ip_address=${ip_address:-$default_ip}
    read -p "Please enter the display name of the validator node: " validator_name
    read -p "Please enter the reward address of the validator node: " safe_public_address
    read -p "Please enter the signer's private key, without 0x: " private_key

    # Save environment variables to the validator.env file
    cat <<EOF > validator.env
ENV=testnet-3
STRATEGY_EXECUTOR_IP_ADDRESS=${ip_address}
STRATEGY_EXECUTOR_DISPLAY_NAME=${validator_name}
STRATEGY_EXECUTOR_BENEFICIARY=${safe_public_address}
SIGNER_PRIVATE_KEY=${private_key}
EOF

    echo "Environment variables have been set and saved to the validator.env file."

    # Pull the Docker image
    echo "Pulling Elixir Validator Docker image..."
    docker pull elixirprotocol/validator:v3

    # Prompt the user to select the platform
    read -p "Are you running on Apple/ARM architecture? (y/n): " is_arm

    if [[ "$is_arm" == "y" ]]; then
        # Running on Apple/ARM architecture
        echo "Running on Apple/ARM architecture..."
        docker run -d \
          --env-file validator.env \
          --name elixir \
          --platform linux/amd64 \
          --restart unless-stopped \
          -p 17690:17690 \
          elixirprotocol/validator:v3
    else
        # Default run
        echo "Running on standard architecture..."
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
    echo "Viewing logs of the Elixir Docker container..."
    docker logs -f elixir
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Delete Docker container function
function delete_docker_container() {
    echo "Deleting the Elixir Docker container..."
    docker stop elixir
    docker rm elixir
    echo "Elixir Docker container has been deleted."
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Validator Health Status function
function check_validator_health() {
    echo "Checking Validator Health Status..."
    curl 127.0.0.1:17690/health | jq
    read -n 1 -s -r -p "Press any key to continue..."
    main_menu
}

# Main menu
function main_menu() {
    clear
    echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
    echo "============================ Elixir V3 Node Installation ===================================="
    echo "Node community Telegram channel: https://t.me/layerairdrop"
    echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
    echo "Please select the operation you want to perform:"
    echo "1. Install Elixir V3 Node"
    echo "2. View Docker Logs"
    echo "3. Delete Elixir Docker Container"
    echo "4. Check Validator Health Status"
    read -p "Please enter an option (1-4): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_docker_logs ;;
    3) delete_docker_container ;;
    4) check_validator_health ;;
    *) echo "Invalid choice. Please choose again." && read -n 1 -s -r -p "Press any key to continue..." && main_menu ;;
    esac
}

# Display the main menu
main_menu
