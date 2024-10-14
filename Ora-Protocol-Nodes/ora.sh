#!/bin/bash

# Showing Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script needs to be run as root."
    echo "Please try switching to the root user using 'sudo -i', and then run the script again."
    exit 1
fi

# Script save path
SCRIPT_PATH="$HOME/ora.sh"

# Check and install Docker
function check_and_install_docker() {
    # Update package list and upgrade installed packages
    sudo apt update -y && sudo apt upgrade -y

    # Install required dependencies
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
    libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev \
    build-essential pkg-config ncdu tar clang bsdmainutils lsb-release \
    libssl-dev libreadline-dev libffi-dev jq gcc screen unzip lz4

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed, installing Docker..."
        
        # Install Docker
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update -y
        sudo apt install -y docker-ce

        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker

        echo "Docker installation complete!"
    else
        echo "Docker is already installed, skipping installation."
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose is not installed, installing Docker Compose..."
        
        # Get the latest version number and install Docker Compose
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose

        echo "Docker Compose installation complete!"
    else
        echo "Docker Compose is already installed, skipping installation."
    fi

    # Display Docker Compose version
    docker-compose --version

    # Add the current user to the Docker group
    if ! getent group docker > /dev/null; then
        echo "Creating Docker group..."
        sudo groupadd docker
    fi

    echo "Adding user $USER to the Docker group..."
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker

    # Notify user to restart shell for Docker group changes to take effect
    echo "Please log out and log back in to apply Docker group changes."
}

# Check and install curl
function check_and_install_curl() {
    if ! command -v curl &> /dev/null; then
        echo "Curl not detected, installing..."
        sudo apt update && sudo apt install -y curl
        echo "Curl has been installed."
    else
        echo "Curl is already installed."
    fi
}

# Node installation function
function install_node() {
    check_and_install_curl
    check_and_install_docker

    mkdir -p tora && cd tora

    # Create docker-compose.yml file
    cat <<EOF > docker-compose.yml
services:
  confirm:
    image: oraprotocol/tora:confirm
    container_name: ora-tora
    depends_on:
      - redis
      - openlm
    command: 
      - "--confirm"
    env_file:
      - .env
    environment:
      REDIS_HOST: 'redis'
      REDIS_PORT: 6379
      CONFIRM_MODEL_SERVER_13: 'http://openlm:5000/'
    networks:
      - private_network
  redis:
    image: oraprotocol/redis:latest
    container_name: ora-redis
    restart: always
    networks:
      - private_network
  openlm:
    image: oraprotocol/openlm:latest
    container_name: ora-openlm
    restart: always
    networks:
      - private_network
  diun:
    image: crazymax/diun:latest
    container_name: diun
    command: serve
    volumes:
      - "./data:/data"
      - "/var/run/docker.sock:/var/run/docker.sock"
    environment:
      - "TZ=Asia/Shanghai"
      - "LOG_LEVEL=info"
      - "LOG_JSON=false"
      - "DIUN_WATCH_WORKERS=5"
      - "DIUN_WATCH_JITTER=30"
      - "DIUN_WATCH_SCHEDULE=0 0 * * *"
      - "DIUN_PROVIDERS_DOCKER=true"
      - "DIUN_PROVIDERS_DOCKER_WATCHBYDEFAULT=true"
    restart: always

networks:
  private_network:
    driver: bridge
EOF

    # Prompt the user to input environment variable values
    read -p "Please enter your private key (needs to start with 0X, corresponding wallet should have Sepolia testnet ETH tokens): " PRIV_KEY
    read -p "Please enter your Ethereum mainnet Alchemy WSS URL: " MAINNET_WSS
    read -p "Please enter your Ethereum mainnet Alchemy HTTP URL: " MAINNET_HTTP
    read -p "Please enter your Sepolia Ethereum Alchemy WSS URL: " SEPOLIA_WSS
    read -p "Please enter your Sepolia Ethereum Alchemy HTTP URL: " SEPOLIA_HTTP

    # Create .env file
    cat <<EOF > .env
############### Sensitive config ###############

PRIV_KEY="$PRIV_KEY"

############### General config ###############

TORA_ENV=production

MAINNET_WSS="$MAINNET_WSS"
MAINNET_HTTP="$MAINNET_HTTP"
SEPOLIA_WSS="$SEPOLIA_WSS"
SEPOLIA_HTTP="$SEPOLIA_HTTP"

REDIS_TTL=86400000

############### App specific config ###############

CONFIRM_CHAINS='["sepolia"]'
CONFIRM_MODELS='[13]'

CONFIRM_USE_CROSSCHECK=true
CONFIRM_CC_POLLING_INTERVAL=3000
CONFIRM_CC_BATCH_BLOCKS_COUNT=300

CONFIRM_TASK_TTL=2592000000
CONFIRM_TASK_DONE_TTL=2592000000
CONFIRM_CC_TTL=2592000000
EOF

    sudo sysctl vm.overcommit_memory=1
    echo "Starting Docker containers (this may take 5-10 minutes)..."
    sudo docker compose up -d
}

# Function to view Docker logs
function check_docker_logs() {
    echo "Viewing ORA Docker container logs..."
    docker logs -f ora-tora
}

# Function to delete Docker container
function delete_docker_container() {
    echo "Deleting ORA Docker container..."
    cd $HOME/tora
    docker compose down
    cd $HOME
    rm -rf tora
    echo "ORA Docker container has been deleted."
}

# Main menu
function main_menu() {
    clear
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
	echo "============================ Ora Protocol Node Automation ================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
	echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
    	echo "Please select the operation to perform:"
    	echo "1. Install ORA node"
    	echo "2. View Docker logs"
    	echo "3. Delete ORA Docker container"
    	read -p "Please enter an option (1-3): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_docker_logs ;;
    3) delete_docker_container ;;
    *) echo "Invalid option." ;;
    esac
}

# Display main menu
main_menu
