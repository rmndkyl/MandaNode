#!/bin/bash

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Script save path
SCRIPT_PATH="$HOME/Autonomys1.sh"

# Check if the script is run as the root user
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Please try using 'sudo -i' to switch to the root user and then run this script again."
    exit 1
fi

# Check if Docker is installed
if command -v docker &> /dev/null; then
    echo "Docker is already installed."
else
    echo "Docker is not installed, proceeding with installation..."

    # Update package list
    apt-get update

    # Install necessary packages to allow apt to use repositories over HTTPS
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

    # Add Docker repository
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    # Update package list
    apt-get update

    # Install Docker
    apt-get install -y docker-ce

    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker

    echo "Docker installation completed."
fi

# Function to check rewards
function check_rewards() {
    echo "Checking reward count:"
    REWARDS_COUNT=$(sudo journalctl -o cat -u subspace-farmer --since="1 hour ago" | grep -i "Successfully signed reward hash" | wc -l)
    echo "Number of rewards successfully signed in the past hour: $REWARDS_COUNT"
    read -p "Press Enter to return to the main menu..."
}

# Function to stop and delete node service
function stop_and_delete_node() {
    if [ -d "subspace" ]; then
        cd subspace
        echo "Stopping and deleting node service..."
        docker compose down
        cd ..
        echo "Node service stopped and deleted."
    else
        echo "Subspace directory not found. Please start the node first."
    fi
    read -p "Press Enter to return to the main menu..."
}

# Function to view logs
function view_logs() {
    # Check if in the subspace directory
    if [ -d "subspace" ]; then
        cd subspace
        echo "Displaying the latest 1000 lines of logs (continuously updating):"
        docker compose logs --tail=1000 -f
        # Return to the main menu
        cd ..
    else
        echo "Subspace directory not found. Please start the node first."
    fi
}

# Function to install and configure Docker Compose
function setup_docker_compose() {
    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed, installing Docker Compose..."
        # Install Docker Compose
        DOCKER_COMPOSE_VERSION="2.20.2"
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    else
        echo "Docker Compose is already installed."
    fi

    # Output Docker Compose version
    echo "Docker Compose version:"
    docker-compose --version

    # Prompt the user to input reward-address and name
    read -p "Please enter the reward-address: " REWARD_ADDRESS
    read -p "Please enter the name: " NAME

    # Create docker-compose.yaml file
    cat <<EOF > docker-compose.yaml
version: '3'
services:
  node:
    image: ghcr.io/autonomys/node:gemini-3h-2024-oct-10
    volumes:
      - node-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30333:30333/tcp"
      - "0.0.0.0:30433:30433/tcp"
    restart: unless-stopped
    command:
      [
        "run",
        "--chain", "gemini-3h",
        "--base-path", "/var/subspace",
        "--listen-on", "/ip4/0.0.0.0/tcp/30333",
        "--dsn-listen-on", "/ip4/0.0.0.0/tcp/30433",
        "--rpc-cors", "all",
        "--rpc-methods", "unsafe",
        "--rpc-listen-on", "0.0.0.0:9944",
        "--farmer",
        "--name", "$NAME"
      ]
    healthcheck:
      timeout: 5s
      interval: 30s
      retries: 60

  farmer:
    depends_on:
      node:
        condition: service_healthy
    image: ghcr.io/autonomys/farmer:gemini-3h-2024-sep-17
    volumes:
      - farmer-data:/var/subspace:rw
    ports:
      - "0.0.0.0:30533:30533/tcp"
    restart: unless-stopped
    command:
      [
        "farm",
        "--node-rpc-url", "ws://node:9944",
        "--listen-on", "/ip4/0.0.0.0/tcp/30533",
        "--reward-address", "$REWARD_ADDRESS",
        "path=/var/subspace,size=120G"
      ]
volumes:
  node-data:
  farmer-data:
EOF

    # Prompt the user to press any key to continue
    read -n 1 -s -r -p "docker-compose.yaml file has been created. Press any key to continue..."

    # Create subspace directory
    mkdir -p subspace

    # Move docker-compose.yaml file to subspace directory
    mv docker-compose.yaml subspace/

    # Enter subspace directory and run docker compose up -d
    cd subspace
    docker compose up -d

    echo "Service has started."

    # Return to the main menu
    cd ..
}

# Main menu function
function main_menu() {
    while true; do
        clear
        echo "██╗░░░░░░█████╗░██╗░░░██╗███████╗██████╗░  ░█████╗░██╗██████╗░██████╗░██████╗░░█████╗░██████╗░"
        echo "██║░░░░░██╔══██╗╚██╗░██╔╝██╔════╝██╔══██╗  ██╔══██╗██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗"
        echo "██║░░░░░███████║░╚████╔╝░█████╗░░██████╔╝  ███████║██║██████╔╝██║░░██║██████╔╝██║░░██║██████╔╝"
        echo "██║░░░░░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══██╗  ██╔══██║██║██╔══██╗██║░░██║██╔══██╗██║░░██║██╔═══╝░"
        echo "███████╗██║░░██║░░░██║░░░███████╗██║░░██║  ██║░░██║██║██║░░██║██████╔╝██║░░██║╚█████╔╝██║░░░░░"
        echo "╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░"
        echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
        echo "============================ Autonomys V1 Node Installation ===================================="
        echo "Node community Telegram channel: https://t.me/layerairdrop"
        echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
        echo "To exit the script, press ctrl + C on your keyboard."
        echo "Please select the operation you want to perform:"
        echo "1. Start node"
        echo "2. View logs"
        echo "3. Check rewards"
        echo "4. Stop and delete node"
        echo "5. Exit script"

        read -p "Please enter an option [1-5]: " option

        case $option in
            1)
                setup_docker_compose
                ;;
            2)
                view_logs
                ;;
            3)
                check_rewards
                ;;
            4)
                stop_and_delete_node
                ;;
            5)
                echo "Exiting script..."
                exit 0
                ;;
            *)
                echo "Invalid option, please enter 1, 2, 3, 4, or 5."
                ;;
        esac
    done
}

# Execute main menu function
main_menu
