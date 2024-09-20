#!/bin/bash

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/ora.sh"

# Main menu function
main_menu() {
    while true; do
        clear
		echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
		echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
		echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
		echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
		echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
		echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
		echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
		echo "============================ Ora Protocol Node Automation ================================="
		echo "Node community Telegram channel: https://t.me/layerairdrop"
		echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl + C to quit"
        echo "Please choose an action:"
        echo "1) Deploy Environment"
        echo "2) Start Node"
        echo "3) View Logs"
        echo "4) Exit"
        read -p "Select an option: " choice

        case $choice in
            1)
                deploy_environment
                ;;
            2)
                start_node
                ;;
            3)
                view_logs
                ;;
            *)
                exit 0
                ;;
        esac
    done
}

# Deploy environment function
deploy_environment() {
    # Update and upgrade the system
    echo "Updating system packages..."
    sudo apt update -y && sudo apt upgrade -y

    # Install necessary dependencies
    echo "Installing necessary dependencies..."
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev build-essential pkg-config ncdu tar clang bsdmainutils lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4

    # Check if Docker is installed
    if ! command -v docker &> /dev/null
    then
        echo "Docker not installed, installing Docker..."

        # Add Docker's GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # Set up Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Update package list
        sudo apt-get update

        # Install Docker
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io

        # Check Docker version
        docker version
    else
        echo "Docker is already installed."
        docker version
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null
    then
        echo "Docker Compose not installed, installing the latest version..."

        # Get the latest Docker Compose version
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

        # Download and install Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/download/${VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

        # Give execution permission
        sudo chmod +x /usr/local/bin/docker-compose

        # Check Docker Compose version
        docker-compose --version
    else
        echo "Docker Compose is already installed."
        docker-compose --version
    fi

    # Add user to Docker group
    echo "Configuring Docker user group..."
    if ! getent group docker > /dev/null; then
        sudo groupadd docker
    fi
    sudo usermod -aG docker $USER
    newgrp docker

    # Clone Tora Docker Compose repository
    echo "Cloning Tora Docker Compose repository..."
    git clone https://github.com/ora-io/tora-docker-compose
    cd tora-docker-compose

    # Copy .env file
    echo "Configuring .env file..."
    cp .env.example .env

    # Prompt user for private key and other information
    echo "Please provide the following information:"

    read -p "Enter your Privkey: " PRIVKEY
    read -p "Enter WSS Main: " WSS_MAIN
    read -p "Enter HTTPS Main: " HTTPS_MAIN
    read -p "Enter Sepholia WSS: " SEPHOLIA_WSS
    read -p "Enter Sepholia HTTPS: " SEPHOLIA_HTTPS

    # Write user input into .env file
    sed -i "s/PRIVATE_KEY=.*/PRIVATE_KEY=$PRIVKEY/" .env
    sed -i "s/WSS_MAIN=.*/WSS_MAIN=$WSS_MAIN/" .env
    sed -i "s/HTTPS_MAIN=.*/HTTPS_MAIN=$HTTPS_MAIN/" .env
    sed -i "s/SEPHOLIA_WSS=.*/SEPHOLIA_WSS=$SEPHOLIA_WSS/" .env
    sed -i "s/SEPHOLIA_HTTPS=.*/SEPHOLIA_HTTPS=$SEPHOLIA_HTTPS/" .env

    echo ".env file has been successfully configured!"
    echo "Environment deployment complete, press any key to return to the main menu..."
    read -n 1 -s
}

# Start node function
start_node() {
    # Prompt the user to input the vm.overcommit_memory parameter value, default is 2
    read -p "Enter the value for vm.overcommit_memory (default is 2): " overcommit_value
    overcommit_value=${overcommit_value:-2}

    # Set kernel parameter
    echo "Setting vm.overcommit_memory to $overcommit_value..."
    sudo sysctl vm.overcommit_memory=$overcommit_value

    # Start the node
    echo "Starting node..."
    cd tora-docker-compose
    docker compose up

    echo "Node has started, press any key to return to the main menu..."
    read -n 1 -s
}

# View logs function
view_logs() {
    # View Docker Compose logs
    echo "Viewing Tora Docker Compose logs..."
    cd tora-docker-compose
    docker compose logs -f

    echo "Log viewing complete, press any key to return to the main menu..."
    read -n 1 -s
}

# Run the main menu
main_menu