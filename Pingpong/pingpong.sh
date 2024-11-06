#!/bin/bash

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 2

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script must be run as root.${NC}"
    echo "Please try using the 'sudo -i' command to switch to the root user, and then run this script again."
    exit 1
fi

# Node installation function
function install_node() {
    echo -e "${GREEN}Updating system packages...${NC}"
    sudo apt update && sudo apt install -y screen ca-certificates curl gnupg lsb-release

    # Check if Docker is installed
    if ! command -v docker &> /dev/null
    then
        echo -e "${YELLOW}Docker not detected, installing...${NC}"
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi

    # Get the running file
    read -p "Please enter your key device id: " your_device_id
    keyid="$your_device_id"

    # Download the PINGPONG program
    if ! wget -O PINGPONG https://pingpong-build.s3.ap-southeast-1.amazonaws.com/linux/latest/PINGPONG; then
        echo -e "${RED}Failed to download PINGPONG, please check your network connection or the URL.${NC}"
        exit 1
    fi

    chmod +x ./PINGPONG
    screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
    echo -e "${GREEN}The node has started, use ${CYAN}screen -r pingpong${GREEN} to view logs or use script function 2${NC}"
}

function check_service_status() {
    screen -r pingpong
}

function reboot_pingpong() {
    read -p "Please enter your key device id: " your_device_id
    keyid="$your_device_id"
    screen -dmS pingpong bash -c "./PINGPONG --key \"$keyid\""
}

function start_pingpong_service() {
    local service_name=$1
    local private_key_name=$2
    read -p "Please enter your ${private_key_name} private key: " service_key
    keyid="$service_key"
    screen -dmS $service_name bash -c "./PINGPONG config set --$service_name=$keyid && ./PINGPONG start --depins=$service_name"
}

function start_0g_pingpong() {
    start_pingpong_service "pingpong-0g" "0g"
}

function start_aioz() {
    start_pingpong_service "pingpong-aioz" "aioz"
}

function start_grass() {
    start_pingpong_service "pingpong-grass" "grass"
}

# Main menu
function main_menu() {
    clear
    echo -e "${CYAN}Script by Telegram user @rmndkyl - Free and Open Source${NC}"
    echo "========================================================"
    echo -e "${YELLOW}Node community channel: https://t.me/layerairdrop${NC}"
    echo -e "${YELLOW}Group discussion: https://t.me/+UgQeEnnWrodiNTI1${NC}"
    echo -e "${GREEN}Please choose an operation:${NC}"
    echo -e "  ${CYAN}1)${NC} Install node"
    echo -e "  ${CYAN}2)${NC} View node logs"
    echo -e "  ${CYAN}3)${NC} Restart pingpong"
    echo -e "  ${CYAN}4)${NC} Start pingpong-0g"
    echo -e "  ${CYAN}5)${NC} Start pingpong-aioz"
    echo -e "  ${CYAN}6)${NC} Start pingpong-grass"
    read -p "Please enter an option (1-6): " OPTION

    case $OPTION in
        1) install_node ;;
        2) check_service_status ;;
        3) reboot_pingpong ;;
        4) start_0g_pingpong ;;
        5) start_aioz ;;
        6) start_grass ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
}

# Display the main menu
main_menu
