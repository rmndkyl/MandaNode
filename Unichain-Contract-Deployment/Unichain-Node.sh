#!/bin/bash

# Define Colors and Bold
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Function to show the menu
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}============================ Unichain Node Automation ====================================${RESET}"
    echo -e "${GREEN}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${RESET}"
    echo -e "${GREEN}Node community Telegram channel: https://t.me/layerairdrop${RESET}"
    echo -e "${GREEN}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${RESET}"
    echo -e "${GREEN}Please select an option:${RESET}"
    echo
    echo -e "${BLUE}1.${RESET} Install node"
    echo -e "${BLUE}2.${RESET} Restart node"
    echo -e "${BLUE}3.${RESET} Check node"
    echo -e "${BLUE}4.${RESET} View operational node logs"
    echo -e "${BLUE}5.${RESET} View execution client logs"
    echo -e "${BLUE}6.${RESET} View Both Logs (Client+Node)"
    echo -e "${BLUE}7.${RESET} Disconnect node"
    echo -e "${RED}0.${RESET} Exit"
    echo
    echo -ne "${YELLOW}Enter your choice [0-7]: ${RESET}"
    read -p " " choice
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed!${RESET}"
        echo -e "${YELLOW}Installing Docker...${RESET}"
        sudo apt update && sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo -e "${GREEN}Docker is installed.${RESET}"
    fi
}

# Install node function
install_node() {
    check_docker

    if docker ps -a --format '{{.Names}}' | grep -q "^unichain-node-execution-client-1$"; then
        echo -e "${GREEN}Node is already installed.${RESET}"
    else
        echo -e "${YELLOW}Installing Unichain node...${RESET}"

        # Install docker-compose if not present
        if ! command -v docker-compose &> /dev/null; then
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        fi

        # Clone repository and configure
        if ! command -v git &> /dev/null; then
            echo -e "${RED}Git is not installed. Please install git to continue.${RESET}"
            return
        fi

        git clone https://github.com/Uniswap/unichain-node
        cd unichain-node || { echo -e "${RED}Failed to enter unichain-node directory.${RESET}"; return; }

        if [[ -f .env.sepolia ]]; then
            sed -i 's|^OP_NODE_L1_ETH_RPC=.*$|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
            sed -i 's|^OP_NODE_L1_BEACON=.*$|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
        else
            echo -e "${RED}.env.sepolia file not found!${RESET}"
            return
        fi

        sudo docker-compose up -d
        echo -e "${GREEN}Node successfully installed.${RESET}"
    fi
    sleep 2
}

# Restart node
restart_node() {
    echo -e "${YELLOW}Restarting node...${RESET}"
    HOMEDIR="$HOME"
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d
    echo -e "${GREEN}Node restarted.${RESET}"
    sleep 2
}

# Check node status
check_node() {
    echo -e "${YELLOW}Checking node status...${RESET}"
    response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
      -H "Content-Type: application/json" http://localhost:8545)
    if [[ -z "$response" ]]; then
        echo -e "${RED}No response from node. Check if it's running correctly.${RESET}"
    else
        echo -e "${GREEN}Node response:${RESET} $response"
    fi
    sleep 2
}

# Check logs for operational node
check_logs_op_node() {
    echo -e "${YELLOW}Retrieving logs for unichain-node-op-node-1...${RESET}"
    sudo docker logs unichain-node-op-node-1
    sleep 2
}

# Check logs for execution client
check_logs_execution_client() {
    echo -e "${YELLOW}Retrieving logs for unichain-node-execution-client-1...${RESET}"
    sudo docker logs unichain-node-execution-client-1
    sleep 2
}

# Check both logs
check_all_logs() {
    echo -e "${YELLOW}Checking Logs from all Unichain Docker...${RESET}"
    cd $HOME/unichain-node && docker-compose logs -f
    sleep 2
}

# Disable or disconnect node
disable_node() {
    echo -e "${YELLOW}Disconnecting node...${RESET}"
    HOMEDIR="$HOME"
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
    echo -e "${GREEN}Node disconnected.${RESET}"
    sleep 2
}

# Exit confirmation
exit_script() {
    echo -ne "${YELLOW}Are you sure you want to exit? [y/n]${RESET} "
    read -p " " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Exiting script...${RESET}"
        exit 0
    fi
}

# Main Loop
while true; do
    show_menu
    case $choice in
        1) install_node ;;
        2) restart_node ;;
        3) check_node ;;
        4) check_logs_op_node ;;
        5) check_logs_execution_client ;;
        6) check_all_logs ;;
        7) disable_node ;;
        0) exit_script ;;
        *) echo -e "${RED}Invalid choice. Please try again.${RESET}"; sleep 2 ;;
    esac
done
