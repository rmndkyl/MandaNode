#!/bin/bash

LOG_FILE="/var/log/hyperlane_setup.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Display a logo
echo "Showing Animation..."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

log() {
    echo -e "$1"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') $1" >> $LOG_FILE
}

error_exit() {
    log "${RED}Error: $1${NC}"
    exit 1
}

if [ "$EUID" -ne 0 ]; then
    log "${RED}Please run this script with root privileges!${NC}"
    exit 1
fi

# Check if the log path is writable
if [ ! -w "$(dirname "$LOG_FILE")" ]; then
    error_exit "Log path is not writable. Please check permissions or adjust the path: $(dirname "$LOG_FILE")"
fi

# Set global variables
DB_DIR="/opt/hyperlane_db_base"

# Ensure the directory exists and has appropriate permissions
if [ ! -d "$DB_DIR" ]; then
    mkdir -p "$DB_DIR" && chmod -R 777 "$DB_DIR" || error_exit "Failed to create database directory: $DB_DIR"
    log "${GREEN}Database directory created: $DB_DIR${NC}"
else
    log "${GREEN}Database directory already exists: $DB_DIR${NC}"
fi

# Check system requirements
check_requirements() {
    log "${YELLOW}Checking system requirements...${NC}"
    CPU=$(grep -c ^processor /proc/cpuinfo)
    RAM=$(free -m | awk '/Mem:/ { print $2 }')
    DISK=$(df -h / | awk '/\// { print $4 }' | sed 's/G//g')

    log "CPU cores: $CPU"
    log "Available memory: ${RAM}MB"
    log "Available disk space: ${DISK}GB"

    if [ "$CPU" -lt 2 ]; then
        error_exit "Insufficient CPU cores (at least 2 cores required)"
    fi

    if [ "$RAM" -lt 2000 ]; then
        error_exit "Insufficient memory (at least 2GB required)"
    fi

    if [ "${DISK%.*}" -lt 20 ]; then
        error_exit "Insufficient disk space (at least 20GB required)"
    fi

    log "${GREEN}System requirements met.${NC}"
}

# Install Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "${YELLOW}Installing Docker...${NC}"
        sudo apt-get update
        sudo apt-get install -y docker.io || error_exit "Failed to install Docker"
        sudo systemctl start docker || error_exit "Failed to start Docker service"
        sudo systemctl enable docker || error_exit "Failed to enable Docker at startup"
        log "${GREEN}Docker successfully installed and started!${NC}"
    else
        log "${GREEN}Docker is already installed. Skipping this step.${NC}"
    fi
}

# Install Node.js and NVM
install_nvm_and_node() {
    if ! command -v nvm &> /dev/null; then
        log "${YELLOW}Installing NVM...${NC}"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash || error_exit "Failed to install NVM"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        log "${GREEN}NVM successfully installed!${NC}"
    else
        log "${GREEN}NVM is already installed. Skipping this step.${NC}"
    fi

    if ! command -v node &> /dev/null; then
        log "${YELLOW}Installing Node.js v20...${NC}"
        nvm install 20 || error_exit "Failed to install Node.js"
        log "${GREEN}Node.js successfully installed!${NC}"
    else
        log "${GREEN}Node.js is already installed. Skipping this step.${NC}"
    fi
}

# Install Foundry
install_foundry() {
    if ! command -v foundryup &> /dev/null; then
        log "${YELLOW}Installing Foundry...${NC}"
        curl -L https://foundry.paradigm.xyz | bash || error_exit "Failed to install Foundry"
        source ~/.bashrc
        foundryup || error_exit "Failed to initialize Foundry"
        log "${GREEN}Foundry successfully installed!${NC}"
    else
        log "${GREEN}Foundry is already installed. Skipping this step.${NC}"
    fi
}

# Install Hyperlane
install_hyperlane() {
    if ! command -v hyperlane &> /dev/null; then
        log "${YELLOW}Installing Hyperlane CLI...${NC}"
        npm install -g @hyperlane-xyz/cli || error_exit "Failed to install Hyperlane CLI"
        log "${GREEN}Hyperlane CLI successfully installed!${NC}"
    else
        log "${GREEN}Hyperlane CLI is already installed. Skipping this step.${NC}"
    fi

    if ! docker images | grep -q 'gcr.io/abacus-labs-dev/hyperlane-agent'; then
        log "${YELLOW}Pulling Hyperlane image...${NC}"
        docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 || error_exit "Failed to pull Hyperlane image"
        log "${GREEN}Hyperlane image successfully pulled!${NC}"
    else
        log "${GREEN}Hyperlane image already exists. Skipping this step.${NC}"
    fi
}

# Configure and Start Validator
configure_and_start_validator() {
    log "${YELLOW}Configuring and starting the Validator...${NC}"
    
    read -p "Enter Validator Name: " VALIDATOR_NAME
    
    while true; do
        read -s -p "Enter Private Key (format: 0x followed by 64 hex characters): " PRIVATE_KEY
        echo ""
        if [[ ! $PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            log "${RED}Invalid Private Key format! Ensure it starts with '0x' and is followed by 64 hex characters.${NC}"
        else
            break
        fi
    done
    
    read -p "Enter RPC URL: " RPC_URL

    CONTAINER_NAME="hyperlane"

    if docker ps -a --format '{{.Names}}' | grep -q "^hyperlane$"; then
        log "${YELLOW}An existing container named 'hyperlane' was found.${NC}"
        read -p "Do you want to remove the old container and continue? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            docker rm -f hyperlane || error_exit "Failed to remove the old container."
            log "${GREEN}Old container removed. Proceeding to start a new container.${NC}"
        else
            read -p "Enter a new container name: " NEW_CONTAINER_NAME
            if [[ -z "$NEW_CONTAINER_NAME" ]]; then
                error_exit "Container name cannot be empty!"
            fi
            CONTAINER_NAME=$NEW_CONTAINER_NAME
        fi
    fi

    docker run -d \
        -it \
        --name "$CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db_base \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db_base \
        --originChainName base \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.folder base \
        --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
        --validator.key "$PRIVATE_KEY" \
        --chains.base.signer.key "$PRIVATE_KEY" \
        --chains.base.customRpcUrls "$RPC_URL" || error_exit "Failed to start the Validator"

    log "${GREEN}Validator configured and started! Container name: $CONTAINER_NAME${NC}"
}

# View Logs
view_logs() {
    log "${YELLOW}Viewing runtime logs...${NC}"
    if docker ps -a --format '{{.Names}}' | grep -q "^hyperlane$"; then
        docker logs -f hyperlane || error_exit "Failed to view logs"
    else
        error_exit "The 'hyperlane' container does not exist. Ensure it has been started!"
    fi
}

# Main Menu
main_menu() {
    while true; do
        echo -e "${YELLOW}"
	echo "Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions"
 	echo "============================ Hyperlane Installation ===================================="
	echo "Node community Telegram channel: https://t.me/layerairdrop"
 	echo "Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1"
	echo "Please Select an Option(1-6):"
        echo "1) Check System Requirements"
        echo "2) Install All Dependencies (Docker, Node.js, Foundry)"
        echo "3) Install Hyperlane"
        echo "4) Configure and Start Validator"
        echo "5) View Runtime Logs"
        echo "6) Complete All Steps Automatically"
        echo "0) Exit"
        echo "================================================================="
        echo -e "${NC}"
        read -p "Enter your choice: " choice
        case $choice in
            1) check_requirements ;;
            2) install_docker && install_nvm_and_node && install_foundry ;;
            3) install_hyperlane ;;
            4) configure_and_start_validator ;;
            5) view_logs ;;
            6) 
                check_requirements
                install_docker
                install_nvm_and_node
                install_foundry
                install_hyperlane
                configure_and_start_validator
                view_logs
                ;;
            0) exit 0 ;;
            *) log "${RED}Invalid option, please try again!${NC}" ;;
        esac
    done
}

main_menu
