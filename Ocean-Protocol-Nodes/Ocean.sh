#!/bin/bash

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Path to save the script
SCRIPT_PATH="$HOME/Ocean.sh"

# Check if the script is run as root user
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root."
    echo "Please try using 'sudo -i' to switch to the root user, then run this script again."
    exit 1
fi

# Check and install Docker and Docker Compose
function install_docker_and_compose() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed, installing Docker..."

        # Install Docker and dependencies
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "Docker is already installed, skipping installation."
    fi

    # Check Docker status
    echo "Docker status:"
    sudo systemctl status docker --no-pager

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed, installing Docker Compose..."
        DOCKER_COMPOSE_VERSION="2.20.2"
        sudo curl -L "https://github.com/docker/compose/releases/download/v$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose is already installed, skipping installation."
    fi

    # Output Docker Compose version
    echo "Docker Compose version:"
    docker-compose --version
}

# Set up and start the node
function setup_and_start_node() {
    # Create directory and navigate into it
    mkdir -p ocean
    cd ocean || { echo "Unable to enter directory"; exit 1; }

    # Download the node script and grant execute permission
    curl -fsSL -O https://raw.githubusercontent.com/rmndkyl/MandaNode/refs/heads/main/Ocean-Protocol-Nodes/ocean-node-quickstart.sh
    chmod +x ocean-node-quickstart.sh && sed -i 's/\r$//' ocean-node-quickstart.sh

    # Instructions for the user
    echo "About to run the node script. Please follow these steps:"
    echo "1. During installation, choose 'Y' and press Enter."
    echo "2. Enter your EVM wallet's private key, making sure to add the '0x' prefix."
    echo "3. Enter the EVM wallet address corresponding to the private key."
    echo "4. Press Enter 5 times in a row."
    echo "5. Enter the server's IP address."

    # Execute the node script
    ./ocean-node-quickstart.sh

    # Start the node
    echo "Starting the node..."
    docker-compose up -d

    echo "Node setup complete!"
}

function view_logs() {
    echo "Viewing Docker logs..."
    if [ -d "/root/ocean" ]; then
        cd /root/ocean && docker-compose logs -f || { echo "Unable to view Docker logs"; exit 1; }
    else
        echo "Please start the node first, the directory '/root/ocean' does not exist."
    fi
}

# Function to delete the node
function delete_node() {
    echo "Deleting node and Docker containers..."
    if [ -d "/root/ocean" ]; then
        cd /root/ocean || { echo "Unable to access directory"; exit 1; }
        
        # Stop and remove containers, networks, and volumes
        docker-compose down -v
        cd ..
        
        # Remove the ocean directory
        rm -rf /root/ocean
        echo "Node and associated files have been deleted successfully."
    else
        echo "No node found. The directory '/root/ocean' does not exist."
    fi
}

# Main menu function
function main_menu() {
    while true; do
        clear
		echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
		echo "============================ Ocean Nodes Manager ================================="
		echo "Node community Telegram channel: https://t.me/layerairdrop"
		echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press Ctrl + C on your keyboard."
        echo "Please select an action to perform:"
        echo "1. Start Node"
        echo "2. View Logs"
        echo "3. Delete Node"
        echo "4. Exit"
        echo -n "Enter an option (1/2/3/4): "
        read -r choice

        case $choice in
            1)
                echo "Starting the node..."
                install_docker_and_compose
                setup_and_start_node
                read -p "Operation complete. Press any key to return to the main menu." -n1 -s
                ;;
            2)
                view_logs
                read -p "Press any key to return to the main menu." -n1 -s
                ;;
            3)
                delete_node
                read -p "Node deletion complete. Press any key to return to the main menu." -n1 -s
                ;;
            4)
                echo "Exiting script."
                exit 0
                ;;
            *)
                echo "Invalid option, please choose 1, 2, 3, or 4."
                ;;
        esac
    done
}

# Run the main menu
main_menu
