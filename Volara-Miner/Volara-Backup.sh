#!/bin/bash

# Set strict error handling
set -euo pipefail

# Define constants
readonly CONTAINER_NAME="volara_miner"
readonly DOCKER_IMAGE="volara/miner"
readonly DOCKER_INSTALL_SCRIPT="https://raw.githubusercontent.com/zunxbt/installation/98a351c5ff781415cbb9f1a250a6d2699cb814c7/docker.sh"

# Enhanced ANSI color codes and styles
readonly BOLD='\033[1m'
readonly NORMAL='\033[0m'
readonly PINK='\033[1;35m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly PURPLE='\033[0;35m'
readonly WHITE='\033[1;37m'

# Box drawing characters
readonly TOP_LEFT='╔'
readonly TOP_RIGHT='╗'
readonly BOTTOM_LEFT='╚'
readonly BOTTOM_RIGHT='╝'
readonly HORIZONTAL='═'
readonly VERTICAL='║'

# Logo display function with colored border
display_logo() {
    local logo_width=54
    local padding=4
    local total_width=$((logo_width + padding))
    
    # Print top border
    echo -en "${CYAN}${TOP_LEFT}"
    printf '%*s' "$total_width" | tr ' ' "$HORIZONTAL"
    echo -e "${TOP_RIGHT}${NORMAL}"
    
    # Print logo with side borders
    echo -en "${CYAN}${VERTICAL}${NORMAL}  "
    echo -en "${PURPLE}${BOLD}"
    cat << "EOF"
██╗   ██╗ ██████╗ ██╗      █████╗ ██████╗  █████╗ 
██║   ██║██╔═══██╗██║     ██╔══██╗██╔══██╗██╔══██╗
██║   ██║██║   ██║██║     ███████║██████╔╝███████║
╚██╗ ██╔╝██║   ██║██║     ██╔══██║██╔══██╗██╔══██║
 ╚████╔╝ ╚██████╔╝███████╗██║  ██║██║  ██║██║  ██║
  ╚═══╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
EOF
    echo -en "${NORMAL}"
    echo -e "${CYAN}${VERTICAL}${NORMAL}"
    
    # Print bottom border
    echo -en "${CYAN}${BOTTOM_LEFT}"
    printf '%*s' "$total_width" | tr ' ' "$HORIZONTAL"
    echo -e "${BOTTOM_RIGHT}${NORMAL}"
}

# Enhanced status message function with animations
show() {
    local message=$1
    local type=${2:-"success"}
    local symbol
    local color
    
    case $type in
        "error")
            symbol="❌"
            color="$RED"
            ;;
        "progress")
            symbol="⏳"
            color="$YELLOW"
            ;;
        "info")
            symbol="ℹ️"
            color="$BLUE"
            ;;
        "warning")
            symbol="⚠️"
            color="$YELLOW"
            ;;
        *)
            symbol="✅"
            color="$GREEN"
            ;;
    esac
    
    echo -e "${color}${BOLD}${symbol} ${message}${NORMAL}"
}

# Animated spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${YELLOW}${BOLD}[%c]${NORMAL} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to validate private key format with colored output
validate_private_key() {
    local key=$1
    if [[ ! $key =~ ^0x[a-fA-F0-9]{64}$ ]]; then
        show "Invalid private key format" "error"
        echo -e "${YELLOW}${BOLD}Format should be:${NORMAL}"
        echo -e "${CYAN}• Start with '0x'${NORMAL}"
        echo -e "${CYAN}• Followed by 64 hexadecimal characters${NORMAL}"
        echo -e "${CYAN}Example: ${WHITE}0x1234...abcd${NORMAL}"
        return 1
    fi
    return 0
}

# Enhanced Docker check function
check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        show "Docker is already installed" "success"
        echo -e "${BLUE}${BOLD}Docker version:${NORMAL} ${WHITE}$(docker --version)${NORMAL}"
        return 0
    fi
    return 1
}

# Enhanced Docker installation function
install_docker() {
    show "Installing Docker..." "progress"
    (wget -O - "$DOCKER_INSTALL_SCRIPT" | bash) &
    spinner $!
    if [ $? -eq 0 ]; then
        show "Docker installed successfully" "success"
    else
        show "Failed to install Docker" "error"
        exit 1
    fi
}

# Enhanced container management with progress feedback
manage_container() {
    if ! container_exists; then
        show "Creating new container..." "progress"
        echo -e "${CYAN}${BOLD}Container details:${NORMAL}"
        echo -e "${WHITE}• Name: ${YELLOW}${CONTAINER_NAME}${NORMAL}"
        echo -e "${WHITE}• Image: ${YELLOW}${DOCKER_IMAGE}${NORMAL}"
        echo -e "${WHITE}• Restart Policy: ${YELLOW}unless-stopped${NORMAL}"
        
        sudo docker run -it \
            -e VANA_PRIVATE_KEY="${VANA_PRIVATE_KEY}" \
            --name "${CONTAINER_NAME}" \
            --restart unless-stopped \
            "${DOCKER_IMAGE}"
    elif ! is_container_running; then
        show "Starting existing container..." "progress"
        sudo docker start -i "${CONTAINER_NAME}"
    else
        show "Attaching to running container..." "progress"
        echo -e "${CYAN}${BOLD}Press Ctrl+P, Ctrl+Q to detach${NORMAL}"
        sudo docker attach --sig-proxy=false "${CONTAINER_NAME}"
    fi
}

# Enhanced prompt for user input
prompt_user_input() {
    echo -e "\n${CYAN}${BOLD}╔════ Wallet Configuration ═══╗${NORMAL}"
    while true; do
        echo -en "${WHITE}Enter your burner wallet's private key: ${YELLOW}${BOLD}"
        read -r VANA_PRIVATE_KEY
        echo -en "${NORMAL}"
        if validate_private_key "$VANA_PRIVATE_KEY"; then
            echo -e "${CYAN}${BOLD}╚════════════════════════════╝${NORMAL}\n"
            break
        fi
    done
    export VANA_PRIVATE_KEY
}

# Main execution
main() {
    clear  # Clear screen before starting
    display_logo
    
    echo -e "\n${BLUE}${BOLD}Initializing Volara Miner...${NORMAL}\n"
    
    if ! check_docker_installed; then
        install_docker
    fi
    
    show "Pulling latest Volara image..." "progress"
    (sudo docker pull "$DOCKER_IMAGE") &
    spinner $!
    show "Volara image pulled successfully" "success"
    
    prompt_user_input
    
    show "Initializing container..." "progress"
    manage_container
    
    # Trap SIGINT and SIGTERM with colored message
    trap 'echo -e "\n${YELLOW}${BOLD}⚠️ Detached from container${NORMAL}"; echo -e "${CYAN}To stop it, use: ${WHITE}docker stop ${CONTAINER_NAME}${NORMAL}"; exit' SIGINT SIGTERM
    
    # Keep the script running
    while true; do
        sleep 1
    done
}

# Execute main function with welcome message
echo -e "${GREEN}${BOLD}Welcome to Volara Miner Setup${NORMAL}"
main
