#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/Nesa.sh"

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Main menu function
function main_menu() {
    while true; do
        clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Nesa Node Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/layerairdropdiskusi"
        echo "To exit the script, press ctrl+c on your keyboard."
        echo "Please choose an action to perform:"
        echo "1) Install node"
        echo "2) Get node status URL"
        echo "3) Get node information (Private Key)"
        echo "4) Exit"
        read -p "Please enter an option [1-4]: " choice

        case $choice in
            1)
                install_node
                ;;
            2)
                get_node_status_url
                ;;
            3)
                get_node_info
                ;;
            4)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid option, please choose again."
                ;;
        esac
    done
}

# Get node status URL function
function get_node_status_url() {
    if [ -f "$HOME/.nesa/identity/node_id.id" ]; then
        PUB_KEY=$(cat $HOME/.nesa/identity/node_id.id)
        echo "Node status URL: https://node.nesa.ai/nodes/$PUB_KEY"
    else
        echo "Node identity file not found. Please check if $HOME/.nesa/identity/node_id.id exists."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Get node information function
function get_node_info() {
    ENV_FILE="/root/.nesa/env/agent.env"

    if [ -f "$ENV_FILE" ]; then
        echo "Fetching node information:"
        echo "========================================"
        grep '^LETSENCRYPT_EMAIL=' $ENV_FILE | cut -d '=' -f2
        grep '^NODE_HOSTNAME=' $ENV_FILE | cut -d '=' -f2
        grep '^NODE_PRIV_KEY=' $ENV_FILE | cut -d '=' -f2
    else
        echo "Environment file not found. Please check if $ENV_FILE exists."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Install node function
function install_node() {
    # Update system and install curl
    echo "Updating system and installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed, installing Docker..."
        
        # Add Docker's GPG key
        echo "Adding Docker's GPG key..."
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add Docker repository to APT sources
        echo "Adding Docker repository..."
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Start Docker service
        echo "Starting Docker service..."
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "Docker is already installed."
    fi

    # Add user to Docker group
    if ! getent group docker > /dev/null; then
        echo "Creating Docker group..."
        sudo groupadd docker
    fi

    echo "Adding user $USER to the Docker group..."
    sudo usermod -aG docker $USER
    
    # Check if NVIDIA GPU driver is installed
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA driver is not installed, installing the latest NVIDIA driver."

        # Add NVIDIA official PPA
        sudo add-apt-repository ppa:graphics-drivers/ppa
        sudo apt-get update

        # Install the latest NVIDIA driver
        sudo apt-get install -y nvidia-driver-$(ubuntu-drivers devices | grep recommended | awk '{print $3}')
    else
        echo "NVIDIA driver is already installed."
    fi

    # Install gum (if not already installed)
    if ! command -v gum &> /dev/null; then
        echo "gum is not installed, installing gum."
        # Download and install gum
        curl -fsSL https://github.com/charmbracelet/gum/releases/download/v0.18.0/gum_0.18.0_linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin
    else
        echo "gum is already installed."
    fi

    # Install jq (if not already installed)
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed, installing jq."
        sudo apt-get install -y jq
    else
        echo "jq is already installed."
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed, installing Docker Compose."
        
        # Get the latest version
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        
        # Set executable permissions
        chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose is already installed."
    fi

    # Verify installation
    docker-compose --version

    # Configure the node
    echo "Configuring the node..."
    read -p "Please choose a unique name for your node: " NODE_NAME

    PS3="Please select the node type: "
    NODE_TYPE_OPTIONS=("Validator" "Miner" "Exit")
    select NODE_TYPE in "${NODE_TYPE_OPTIONS[@]}"
    do
        case $NODE_TYPE in
            "Validator")
                read -p "Validator's Private Key: " PRIVATE_KEY
                echo "Node Name: $NODE_NAME"
                echo "Node Type: Validator"
                echo "Validator's Private Key: $PRIVATE_KEY"
                break
                ;;
            "Miner")
                PS3="Please select the miner type: "
                MINER_TYPE_OPTIONS=("Distributed Miner" "Non-Distributed Miner" "Exit")
                select MINER_TYPE in "${MINER_TYPE_OPTIONS[@]}"
                do
                    case $MINER_TYPE in
                        "Distributed Miner")
                            PS3="Please select swarm action: "
                            SWARM_ACTION_OPTIONS=("Join existing swarm" "Start a new swarm" "Exit")
                            select SWARM_ACTION in "${SWARM_ACTION_OPTIONS[@]}"
                            do
                                case $SWARM_ACTION in
                                    "Start a new swarm")
                                        read -p "Which model would you like to run? (meta-llama/Llama-2-13b-Chat-Hf): " MODEL
                                        echo "Node Name: $NODE_NAME"
                                        echo "Node Type: Miner"
                                        echo "Miner Type: Distributed Miner"
                                        echo "Swarm Action: Start a new swarm"
                                        echo "Model: $MODEL"
                                        break
                                        ;;
                                    "Join existing swarm")
                                        echo "Logic for joining an existing swarm is not yet implemented."
                                        echo "Node Name: $NODE_NAME"
                                        echo "Node Type: Miner"
                                        echo "Miner Type: Distributed Miner"
                                        echo "Swarm Action: Join existing swarm"
                                        break
                                        ;;
                                    "Exit")
                                        exit 1
                                        ;;
                                    *)
                                        echo "Invalid option $REPLY"
                                        ;;
                                esac
                            done
                            break
                            ;;
                        "Non-Distributed Miner")
                            read -p "Which model would you like to run? (meta-llama/Llama-2-13b-Chat-Hf): " MODEL
                            echo "Node Name: $NODE_NAME"
                            echo "Node Type: Miner"
                            echo "Miner Type: Non-Distributed Miner"
                            echo "Model: $MODEL"
                            break
                            ;;
                        "Exit")
                            exit 1
                            ;;
                        *)
                            echo "Invalid option $REPLY"
                            ;;
                    esac
                done
                break
                ;;
            "Exit")
                exit 1
                ;;
            *)
                echo "Invalid option $REPLY"
                ;;
        esac
    done

    # Run remote script for all operating systems
    echo "Running remote initialization script..."
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)

    # Try to start docker-compose
    echo "Attempting to start Docker Compose containers..."
    cd /root/.nesa/docker
    if sudo docker-compose up -d; then
        echo "Docker Compose containers started successfully."
    else
        echo "Failed to start Docker Compose containers. Please check the configuration and logs."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Run main menu
main_menu
