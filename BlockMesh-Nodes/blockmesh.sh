#!/bin/bash

# Script save path
SCRIPT_PATH="$HOME/blockmesh.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No color

# Log file for debugging
LOG_FILE="blockmesh_install.log"
exec > >(tee -a $LOG_FILE) 2>&1

# Spinner function for progress indication
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo "    "
}

# Display a banner
banner() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "        BlockMesh CLI Installer        "
    echo "========================================"
    echo -e "${NC}"
}

# Cleanup temporary files on exit
cleanup() {
    echo -e "${YELLOW}Cleaning up temporary files...${NC}"
    rm -f loader.sh logo.sh blockmesh-cli.tar.gz
}
trap cleanup EXIT

# Display a logo
echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -f loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -f logo.sh
sleep 4

# Check if the script is run as the root user
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as the root user.${NC}"
    echo -e "${YELLOW}Please use 'sudo -i' to switch to the root user and re-run this script.${NC}"
    exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        banner
        echo -e "${BLUE}Script and tutorial by Telegram @rmndkyl, free and open source.${NC}"
        echo -e "${BLUE}================================================================${NC}"
        echo -e "${BLUE}Node community Telegram channel: https://t.me/layerairdrop${NC}"
        echo -e "${BLUE}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${NC}"
        echo -e "${GREEN}1. Deploy Node${NC}"
        echo -e "${GREEN}2. View Logs${NC}"
        echo -e "${GREEN}3. Deploy Old Version VPS Node${NC}"
        echo -e "${RED}4. Exit${NC}"
        read -p "Enter your choice (1-4): " option

        case $option in
            1) deploy_node ;;
            2) view_logs ;;
            3) deploy_community_node ;;
            4) echo -e "${GREEN}Exiting the script.${NC}" && exit 0 ;;
            *) echo -e "${RED}Invalid option, please try again.${NC}" ;;
        esac
    done
}

# Deploy Node
function deploy_node() {
    echo -e "${YELLOW}Updating the system...${NC}"
    sudo apt update -y && sudo apt upgrade -y & spinner $!

    # Clean up old files
    rm -rf blockmesh-cli.tar.gz target

    # Check and handle existing container
    if [ "$(docker ps -aq -f name=blockmesh-cli-container)" ]; then
        echo -e "${YELLOW}Detected existing 'blockmesh-cli-container'. Stopping and removing...${NC}"
        docker stop blockmesh-cli-container & spinner $!
        docker rm blockmesh-cli-container & spinner $!
        echo -e "${GREEN}Container stopped and removed.${NC}"
    fi

    # Install Docker if not already installed
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Installing Docker...${NC}"
        apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io & spinner $!
    else
        echo -e "${GREEN}Docker is already installed. Skipping installation...${NC}"
    fi

    # Install Docker Compose
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # Create target directory for extraction
    mkdir -p target/release

    # Download and extract the latest BlockMesh CLI
    echo -e "${YELLOW}Downloading and extracting BlockMesh CLI...${NC}"
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.403/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

    # Verify the extraction result
    if [[ ! -f target/release/blockmesh-cli ]]; then
        echo -e "${RED}Error: 'blockmesh-cli' executable not found in 'target/release'. Exiting...${NC}"
        exit 1
    fi

    # Prompt for email and password
    read -p "Enter your BlockMesh email: " email
    while [[ -z "$email" ]]; do
        echo -e "${RED}Email cannot be empty. Please try again.${NC}"
        read -p "Enter your BlockMesh email: " email
    done

    read -s -p "Enter your BlockMesh password: " password
    echo

    # Use BlockMesh CLI to create a Docker container
    echo -e "${YELLOW}Creating Docker container for BlockMesh CLI...${NC}"
    docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

    read -p "Press any key to return to the main menu..."
}

# View Logs
function view_logs() {
    echo -e "${YELLOW}Viewing logs for the blockmesh-cli-container:${NC}"
    docker logs --tail 100 blockmesh-cli-container

    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: No container found with the name blockmesh-cli-container.${NC}"
    fi

    read -p "Press any key to return to the main menu..."
}

# Deploy Community VPS Node
function deploy_community_node() {
    echo -e "${YELLOW}Deploying Community VPS Node...${NC}"

    mkdir -p target/release
    echo -e "${YELLOW}Downloading the Community-Optimized BlockMesh CLI...${NC}"
    curl -L https://github.com/sdohuajia/Blockmesh/raw/refs/heads/main/target/release/blockmesh-cli -o target/release/blockmesh-cli
    chmod +x target/release/blockmesh-cli

    if [[ ! -f target/release/blockmesh-cli ]]; then
        echo -e "${RED}Error: VPS CLI download failed. Please check your network connection and try again...${NC}"
        exit 1
    fi

    read -p "Enter your BlockMesh email: " email
    while [[ -z "$email" ]]; do
        echo -e "${RED}Email cannot be empty. Please try again.${NC}"
        read -p "Enter your BlockMesh email: " email
    done

    read -s -p "Enter your BlockMesh password: " password
    echo

    echo -e "${YELLOW}Starting the Community VPS Node...${NC}"
    docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"

    read -p "Node deployment complete. Press any key to return to the main menu..."
}

# Start the Main Menu
main_menu
