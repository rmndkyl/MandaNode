#!/bin/bash

GREEN='\033[0;32m'
RESET='\033[0m'

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
sleep 4

show_menu() {
    clear
	echo -e "${GREEN}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${RESET}"
    echo -e "${GREEN}${BOLD}============================ Unichain Node Automation ====================================${RESET}"
    echo -e "${GREEN}Node community Telegram channel: https://t.me/layerairdrop${RESET}"
    echo -e "${GREEN}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${RESET}"
    echo -e "${GREEN}Please select an option:${RESET}"
    echo
    echo -e "${GREEN}1.${RESET} Install node"
    echo -e "${GREEN}2.${RESET} Restart node"
    echo -e "${GREEN}3.${RESET} Check node"
    echo -e "${GREEN}4.${RESET} View operational node logs"
    echo -e "${GREEN}5.${RESET} View execution client logs"
    echo -e "${GREEN}6.${RESET} Disconnect node"
    echo -e "${GREEN}0.${RESET} Exit"
    echo
    echo -e "${GREEN}Enter your choice [0-6]: ${RESET}"
    read -p " " choice
}

install_node() {
    if docker ps -a --format '{{.Names}}' | grep -q "^unichain-node-execution-client-1$"; then
        echo -e "${GREEN}1. Node is already installed.${RESET}"
    else
        echo -e "${GREEN}1. Installing node...${RESET}"
        sudo apt update && sudo apt upgrade -y
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker

        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose

        git clone https://github.com/Uniswap/unichain-node
        cd unichain-node || { echo -e "${GREEN}Failed to enter unichain-node directory.${RESET}"; return; }

        if [[ -f .env.sepolia ]]; then
            sed -i 's|^OP_NODE_L1_ETH_RPC=.*$|OP_NODE_L1_ETH_RPC=https://ethereum-sepolia-rpc.publicnode.com|' .env.sepolia
            sed -i 's|^OP_NODE_L1_BEACON=.*$|OP_NODE_L1_BEACON=https://ethereum-sepolia-beacon-api.publicnode.com|' .env.sepolia
        else
            echo -e "${GREEN}.env.sepolia file not found!${RESET}"
            return
        fi

        sudo docker-compose up -d

        echo -e "${GREEN}1. Node successfully installed.${RESET}"
    fi
    echo
    read -p "Press Enter to return to the main menu..."
}

restart_node() {
    echo -e "${GREEN}2. Restarting node...${RESET}"
    HOMEDIR="$HOME"
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" up -d
    echo -e "${GREEN}2. Node restarted.${RESET}"
    echo
    read -p "Press Enter to return to the main menu..."
}

check_node() {
    echo -e "${GREEN}3. Checking node status...${RESET}"
    response=$(curl -s -d '{"id":1,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false]}' \
      -H "Content-Type: application/json" http://localhost:8545)
    echo -e "${GREEN}Response: ${RESET}$response"
    echo
    read -p "Press Enter to return to the main menu..."
}

check_logs_op_node() {
    echo -e "${GREEN}4. Retrieving logs for unichain-node-op-node-1...${RESET}"
    sudo docker logs unichain-node-op-node-1
    echo
    read -p "Press Enter to return to the main menu..."
}

check_logs_execution_client() {
    echo -e "${GREEN}5. Retrieving logs for unichain-node-execution-client-1...${RESET}"
    sudo docker logs unichain-node-execution-client-1
    echo
    read -p "Press Enter to return to the main menu..."
}

disable_node() {
    echo -e "${GREEN}6. Disconnecting node...${RESET}"
    HOMEDIR="$HOME"
    sudo docker-compose -f "${HOMEDIR}/unichain-node/docker-compose.yml" down
    echo -e "${GREEN}6. Node disconnected.${RESET}"
    echo
    read -p "Press Enter to return to the main menu..."
}

while true; do
    show_menu
    case $choice in
        1)
            install_node
            ;;
        2)
            restart_node
            ;;
        3)
            check_node
            ;;
        4)
            check_logs_op_node
            ;;
        5)
            check_logs_execution_client
            ;;
        6)
            disable_node
            ;;
        0)
            echo -e "${GREEN}Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${GREEN}Invalid choice. Please try again.${RESET}"
            echo
            read -p "Press Enter to continue..."
            ;;
    esac
done