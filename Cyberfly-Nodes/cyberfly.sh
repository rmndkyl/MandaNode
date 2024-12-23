#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Show Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Error handling
set -e
trap 'echo -e "${RED}Error: Script failed on line $LINENO${NC}"; exit 1' ERR

# Get IP address
myIP=$(curl -s ifconfig.me)

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run with sudo privileges${NC}"
   exit 1
fi

# Header function with colors
function myHeader() {
    clear
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}=             ${GREEN}Cyberfly's Testnet Auto Installer${BLUE}            =${NC}"
    echo -e "${BLUE}=                    ${YELLOW}Created by : rmndkyl${BLUE}                  =${NC}"
    echo -e "${BLUE}=             ${YELLOW}Github : https://github.com/rmndkyl${BLUE}          =${NC}"
    echo -e "${BLUE}=                 ${GREEN}Your OS info : $(uname -s) $(uname -m)${BLUE}              =${NC}"
    echo -e "${BLUE}=                 ${GREEN}IP Address : ${myIP}${BLUE}               =${NC}"
    echo -e "${BLUE}============================================================${NC}\n"
}

# Check system requirements
function checkRequirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check Docker
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${YELLOW}Docker is not found. Installing docker...${NC}"
        apt update
        apt install -y docker docker.io
        systemctl start docker
        systemctl enable docker
    else
        echo -e "${GREEN}Docker is already installed${NC}"
    fi
    
    # Check Git
    if ! command -v git >/dev/null 2>&1; then
        echo -e "${YELLOW}Git is not found. Installing git...${NC}"
        apt install -y git
    fi
}

# Input validation function
function validateInput() {
    local input=$1
    local type=$2
    
    case $type in
        "address")
            if [[ ! $input =~ ^k: ]]; then
                echo -e "${RED}Invalid Kadena address format. Address must start with 'k:'${NC}"
                return 1
            fi
            ;;
        "privatekey")
            if [[ ${#input} -lt 64 ]]; then
                echo -e "${RED}Private key seems too short. Please verify your input${NC}"
                return 1
            fi
            ;;
    esac
    return 0
}

# Main installation function
function installNode() {
    local kadenaAddr=$1
    local privKey=$2
    
    echo -e "${YELLOW}Starting installation...${NC}"
    
    # Configure firewall
    echo -e "${YELLOW}Configuring firewall...${NC}"
    ufw allow 31000
    
    # Clone and setup repository
    echo -e "${YELLOW}Cloning repository...${NC}"
    git clone https://github.com/rmndkyl/cyberfly-node-docker.git
    cd cyberfly-node-docker
    git pull
    
    # Start node
    echo -e "${YELLOW}Starting Cyberfly node...${NC}"
    chmod +x start_node.sh
    ./start_node.sh "$kadenaAddr" "$privKey"
}

# Main execution
myHeader
checkRequirements

# Get Kadena address
while true; do
    read -p "$(echo -e ${GREEN}"Submit your kadena address: "${NC})" kadenaAddr
    if [[ -n $kadenaAddr ]] && validateInput "$kadenaAddr" "address"; then
        break
    fi
    echo -e "${RED}Please enter a valid Kadena address${NC}"
done

# Get private key
while true; do
    read -s -p "$(echo -e ${GREEN}"Submit your kadena private key: "${NC})" privKey
    echo
    if [[ -n $privKey ]] && validateInput "$privKey" "privatekey"; then
        break
    fi
    echo -e "${RED}Please enter a valid private key${NC}"
done

# Install node
installNode "$kadenaAddr" "$privKey"

# Display completion message
myHeader
echo -e "${GREEN}Installation Complete ✅${NC}"
echo -e "${YELLOW}GO TO ${BLUE}https://node.cyberfly.io${YELLOW} or ${BLUE}http://${myIP}:31000${YELLOW} to claim the faucet${NC}"
echo -e "${YELLOW}GO TO ${BLUE}http://${myIP}:31000${YELLOW} for doing the task!${NC}"
