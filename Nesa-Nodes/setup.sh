#!/bin/bash

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
        echo "To exit the script, press ctrl+c on the keyboard."
        echo "Please choose an option:"
        echo "1) Install Node"
        echo "2) Get Node Status URL"
        echo "3) Exit"
        read -p "Enter your choice [1-3]: " choice

        case $choice in
            1)
                install_node
                ;;
            2)
                get_node_status_url
                ;;
            3)
                echo "Exiting the script."
                exit 0
                ;;
            *)
                echo "Invalid option, please try again."
                ;;
        esac
    done
}

# Function to get the Node Status URL
function get_node_status_url() {
    if [ -f "$HOME/.nesa/identity/node_id.id" ]; then
        PUB_KEY=$(cat $HOME/.nesa/identity/node_id.id)
        echo "Node Status URL: https://node.nesa.ai/nodes/$PUB_KEY"
    else
        echo "Node identity file not found. Please make sure $HOME/.nesa/identity/node_id.id exists."
    fi

    # Wait for the user to press any key to return to the main menu
    read -p "Press any key to return to the main menu..."
}

# Function to install the Node
function install_node() {
    # Update the system and install curl
    echo "Updating the system and installing curl..."
    sudo apt-get update
    sudo apt-get install -y curl

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

    # Check if NVIDIA GPU drivers are installed
    if ! command -v nvidia-smi &> /dev/null
    then
        echo "NVIDIA drivers are not installed. Installing the latest version of NVIDIA drivers."

        # Add NVIDIA official PPA
        sudo add-apt-repository ppa:graphics-drivers/ppa
        sudo apt-get update

        # Install the latest version of NVIDIA drivers
        sudo apt-get install -y nvidia-driver-$(ubuntu-drivers devices | grep recommended | awk '{print $3}')
    else
        echo "NVIDIA drivers are already installed."
    fi

    # Install gum (if not already installed)
    if ! command -v gum &> /dev/null
    then
        echo "gum is not installed. Installing gum."
        # Download and install gum
        curl -fsSL https://github.com/charmbracelet/gum/releases/download/v0.18.0/gum_0.18.0_linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin
    else
        echo "gum is already installed."
    fi

# Install jq (if not already installed)
if ! command -v jq &> /dev/null
then
    echo "jq is not installed. Installing jq."
    sudo apt-get install -y jq
else
    echo "jq is already installed."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose is not installed. Installing Docker Compose."
    # Install Docker Compose
    DOCKER_COMPOSE_VERSION="v2.18.1"  # Adjust the version as needed
    sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose is already installed."
fi

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
                        PS3="Please select a swarm action: "
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

# Run the remote script for all OS
echo "Running remote initialization script..."
bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)

# Try to start Docker Compose
echo "Attempting to start Docker Compose containers..."
if sudo docker-compose up -d; then
    echo "Docker Compose containers started successfully."
else
    echo "Failed to start Docker Compose containers. Please check the configuration and logs."
fi

# Wait for the user to press any key to return to the main menu
read -p "Press any key to return to the main menu..."
}

# Run the main menu
main_menu
