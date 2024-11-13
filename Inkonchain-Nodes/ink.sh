#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Required TCP and UDP ports
TCP_PORTS=(8545 8546 30303 9222 7300 6060)
UDP_PORTS=(30303)
# Alternative Ports for TCP and UDP
ALT_TCP_PORTS=(8550 8552 30304 9223 7301 6061)
ALT_UDP_PORTS=(30304)

# Check if ports are available
check_ports() {
    echo -e "${CYAN}Checking port availability...${NC}"
    for i in "${!TCP_PORTS[@]}"; do
        port=${TCP_PORTS[$i]}
        alt_port=${ALT_TCP_PORTS[$i]}

        if sudo lsof -iTCP:$port -sTCP:LISTEN &>/dev/null; then
            echo -e "${YELLOW}⚠️  TCP Port $port is in use. Switching to alternative port $alt_port.${NC}"
            TCP_PORTS[$i]=$alt_port
        else
            echo -e "${GREEN}✅ TCP Port $port is available.${NC}"
        fi
    done

    for i in "${!UDP_PORTS[@]}"; do
        port=${UDP_PORTS[$i]}
        alt_port=${ALT_UDP_PORTS[$i]}

        if sudo lsof -iUDP:$port &>/dev/null; then
            echo -e "${YELLOW}⚠️  UDP Port $port is in use. Switching to alternative port $alt_port.${NC}"
            UDP_PORTS[$i]=$alt_port
        else
            echo -e "${GREEN}✅ UDP Port $port is available.${NC}"
        fi
    done
}

# Install prerequisites and Docker if not already installed
install_dependencies() {
    echo -e "${CYAN}Installing prerequisites...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install screen -y
    screen -S InkNode -d -m
    echo -e "${GREEN}Prerequisites installed.${NC}"

    if ! command -v docker &> /dev/null; then
        echo -e "${CYAN}Installing Docker...${NC}"
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        docker --version
        echo -e "${GREEN}Docker installed successfully.${NC}"
    else
        echo -e "${YELLOW}Docker is already installed. Skipping installation.${NC}"
    fi
}

# Install and Configure Ink Node
setup_ink_node() {
    echo -e "${CYAN}Installing Ink Node...${NC}"
    mkdir -p "$HOME/InkNode" && cd "$HOME/InkNode"
    if git clone https://github.com/inkonchain/node; then
        cd node

        # Write .env.ink-sepolia file with updated L1 RPC URLs
        cat <<EOL > .env.ink-sepolia
L1_RPC_URL="https://ethereum-sepolia-rpc.publicnode.com"
L1_BEACON_URL="https://ethereum-sepolia-beacon-api.publicnode.com"
EOL

        # Update entrypoint.sh with available ports
        sed -i "s/8551/${TCP_PORTS[0]}/g" "$HOME/InkNode/node/op-node/entrypoint.sh"
        sed -i "s/30303/${TCP_PORTS[2]}/g" "$HOME/InkNode/node/op-node/entrypoint.sh"
        sed -i "s/30303/${UDP_PORTS[0]}/g" "$HOME/InkNode/node/op-node/entrypoint.sh"

        echo -e "${GREEN}Ink Node installed and ports configured.${NC}"
    else
        echo -e "${RED}Failed to clone Ink Node repository.${NC}"
    fi
}

# Run and Manage Ink Node
manage_ink_node() {
    echo -e "${CYAN}Starting Ink Node...${NC}"
    cd "$HOME/InkNode/node"
    if ./setup.sh && docker compose up -d; then
        echo -e "${GREEN}Ink Node is running.${NC}"
    else
        echo -e "${RED}Failed to start Ink Node.${NC}"
    fi

    echo -e "${CYAN}Verifying Sync Status...${NC}"
    curl -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' http://localhost:9545 | jq

    echo -e "${CYAN}Comparing local and remote block numbers...${NC}"
    local_block=$(curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
        | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')
    remote_block=$(curl -s -X POST https://rpc-gel-sepolia.inkonchain.com/ -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
        | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')
    echo -e "${GREEN}Local finalized block: $local_block${NC}"
    echo -e "${GREEN}Remote finalized block: $remote_block${NC}"
}

# Restart, Shutdown, or Delete Node
node_maintenance() {
    echo -e "${CYAN}Node Maintenance Options${NC}"
    echo "1. Restart Node"
    echo "2. Shutdown Node"
    echo "3. Delete Node"
    read -p "Choose an option: " choice
    case $choice in
        1)
            echo -e "${CYAN}Restarting the node...${NC}"
            cd "$HOME/InkNode/node"
            sudo docker-compose down && sudo docker-compose up -d
            echo -e "${GREEN}Node restarted.${NC}"
            ;;
        2)
            echo -e "${CYAN}Shutting down the node...${NC}"
            sudo docker-compose -f "$HOME/unichain-node/docker-compose.yml" down
            echo -e "${GREEN}Node shut down.${NC}"
            ;;
        3)
            echo -e "${RED}Deleting Ink Node...${NC}"
            rm -rf "$HOME/InkNode/"
            echo -e "${GREEN}Ink Node deleted.${NC}"
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
}

# Main menu function
main_menu() {
    while true; do
		echo -e "${GREEN}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${RESET}"
        echo -e "${CYAN}----------------------------------${NC}"
        echo -e "${CYAN}       Ink Node Setup Menu        ${NC}"
        echo -e "${CYAN}----------------------------------${NC}"
		echo -e "${GREEN}Node community Telegram channel: https://t.me/layerairdrop${RESET}"
		echo -e "${GREEN}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${RESET}"
		echo -e "${GREEN}Please select an option:${RESET}"
        echo -e "1. Check Port Availability"
        echo -e "2. Install Dependencies (Prerequisites and Docker)"
        echo -e "3. Install and Configure Ink Node"
        echo -e "4. Run and Manage Ink Node"
        echo -e "5. Node Maintenance (Restart, Shutdown, Delete)"
        echo -e "6. Exit"
        echo -e "${CYAN}----------------------------------${NC}"
        read -p "Choose an option: " choice

        case $choice in
            1) check_ports ;;
            2) install_dependencies ;;
            3) setup_ink_node ;;
            4) manage_ink_node ;;
            5) node_maintenance ;;
            6) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
    done
}

main_menu
