#!/bin/bash

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

# Script save path
SCRIPT_PATH="$HOME/ElixirV3.sh"

# Check and install Docker
function check_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not detected, installing..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        echo "Docker installed."
    else
        echo "Docker is already installed."
    fi
}

# Node installation function
function install_node() {
    check_and_install_docker

    # Prompt the user to input environment variable values
    read -p "Please enter the IP address of the validator node device: " ip_address
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
    docker pull elixirprotocol/validator:v3

    # Prompt the user to select the platform
    read -p "Are you running on Apple/ARM architecture? (y/n): " is_arm

    if [[ "$is_arm" == "y" ]]; then
        # Running on Apple/ARM architecture
        docker run -it -d \
          --env-file validator.env \
          --name elixir \
          --platform linux/amd64 \
          elixirprotocol/validator:v3
    else
        # Default run
        docker run -it -d \
          --env-file validator.env \
          --name elixir \
          elixirprotocol/validator:v3
    fi
}

# View Docker logs function
function check_docker_logs() {
    echo "Viewing logs of the Elixir Docker container..."
    docker logs -f elixir
}

# Delete Docker container function
function delete_docker_container() {
    echo "Deleting the Elixir Docker container..."
    docker stop elixir
    docker rm elixir
    echo "Elixir Docker container has been deleted."
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
   	read -p "Please enter an option (1-3): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_docker_logs ;;
    3) delete_docker_container ;;
    *) echo "Invalid option." ;;
    esac
}

# Display the main menu
main_menu
