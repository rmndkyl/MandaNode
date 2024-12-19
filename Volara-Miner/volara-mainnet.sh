#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Showing Logo
echo "Showing Animation..."
sudo apt install -y wget curl  # Ensure wget and curl are installed
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Script banner
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo '╔════════════════════════════════════════════╗'
    echo '║             Volara Miner                   ║'
    echo '║          Created by @rmndkyl               ║'
    echo '╚════════════════════════════════════════════╝'
    echo -e "${NC}"
}

# Enhanced logging function
log() {
    local message=$1
    local type=${2:-"info"}
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $type in
        "error")
            echo -e "${timestamp} ${RED}${BOLD}[ERROR]${NC} ❌ $message"
            ;;
        "warning")
            echo -e "${timestamp} ${YELLOW}${BOLD}[WARN]${NC} ⚠️  $message"
            ;;
        "success")
            echo -e "${timestamp} ${GREEN}${BOLD}[SUCCESS]${NC} ✅ $message"
            ;;
        "info")
            echo -e "${timestamp} ${BLUE}${BOLD}[INFO]${NC} ℹ️  $message"
            ;;
        "progress")
            echo -e "${timestamp} ${CYAN}${BOLD}[PROGRESS]${NC} ⏳ $message"
            ;;
    esac
}

# Configuration
CONTAINER_NAME="volara_miner"
CONFIG_FILE="$HOME/.volara_config"

# Load configuration if exists
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        return 0
    fi
    return 1
}

# Save configuration
save_config() {
    echo "VANA_PRIVATE_KEY='${VANA_PRIVATE_KEY}'" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
}

# Check Docker installation
check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        log "Docker is already installed" "success"
        return 0
    else
        log "Docker is not installed" "warning"
        return 1
    fi
}

# Install Docker
install_docker() {
    log "Installing Docker..." "progress"
    source <(wget -O - "https://raw.githubusercontent.com/zunxbt/installation/98a351c5ff781415cbb9f1a250a6d2699cb814c7/docker.sh")
    log "Docker installation completed" "success"
}

# Pull Volara image with progress
pull_volara_image() {
    log "Pulling Volara image..." "progress"
    if sudo docker pull volara/miner; then
        log "Volara image pulled successfully" "success"
    else
        log "Failed to pull Volara image" "error"
        exit 1
    fi
}

# Container management functions
container_exists() {
    sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

is_container_running() {
    sudo docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Interactive prompt for user input
prompt_user_input() {
    if ! load_config; then
        echo -e "${YELLOW}${BOLD}"
        echo "Please provide your burner wallet's private key:"
        echo -e "${NC}"
        read -sp "Private key: " VANA_PRIVATE_KEY
        echo
        save_config
    fi
}

# Container management
manage_container() {
    if ! container_exists; then
        log "Creating new container..." "progress"
        sudo docker run -it -e VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY} --name ${CONTAINER_NAME} volara/miner
    elif ! is_container_running; then
        log "Starting existing container..." "progress"
        sudo docker start -i ${CONTAINER_NAME}
    else
        log "Attaching to running container..." "info"
        sudo docker attach --sig-proxy=false ${CONTAINER_NAME}
    fi
}

# Cleanup function
cleanup() {
    log "Detaching from container gracefully..." "info"
    echo -e "${YELLOW}To stop the container, use: ${WHITE}docker stop ${CONTAINER_NAME}${NC}"
    exit 0
}

# Main execution
main() {
    print_banner
    
    if ! check_docker_installed; then
        install_docker
    fi
    
    pull_volara_image
    prompt_user_input
    
    # Set up trap for cleanup
    trap cleanup SIGINT SIGTERM
    
    log "Initializing container..." "progress"
    manage_container
    
    # Keep the script running
    while true; do
        sleep 1
    done
}

# Execute main function
main
