#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
ITALIC='\033[3m'
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

# Validate Sepolia RPC URL
validate_sepolia_url() {
    local url=$1
    echo -e "${GRAY}Validating RPC endpoint... ${ITALIC}(checking chain ID)${NC}"
    local chain_id=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        "$url" | grep -o '"result":"0x[^"]*"' | cut -d'"' -f4)
    if [ "$chain_id" = "0xaa36a7" ]; then
        echo -e "${GREEN}↳ Valid Sepolia RPC endpoint detected ✅${NC}\n"
        return 0
    else
        echo -e "${RED}↳ Invalid chain ID. Expected Sepolia (0xaa36a7) ❌${NC}\n"
        return 1
    fi
}

# Validate Beacon API endpoint
validate_beacon_api() {
    local url=$1
    echo -e "${GRAY}Validating Beacon API support... ${ITALIC}(checking /eth/v1/node/version)${NC}"
    local response=$(curl -s -f "${url}/eth/v1/node/version" -H 'accept: application/json')
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}↳ Beacon API support confirmed ✅${NC}\n"
        return 0
    else
        echo -e "${RED}↳ Beacon API not supported on this endpoint ❌${NC}\n"
        return 1
    fi
}

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

        # Configure L1 URLs with validation
        echo -e "\n${WHITE}Configuring Ink Sepolia Node Setup! 🚀${NC}\n"
        if [ -f .env ] && grep -q "L1_RPC_URL" .env; then
            existing_url=$(grep "L1_RPC_URL" .env | cut -d'=' -f2)
            echo -e "${GRAY}Found existing configuration in${NC} ${WHITE}.env${NC}${GRAY}. Validating...${NC}\n"
            if validate_sepolia_url "$existing_url" && validate_beacon_api "$existing_url"; then
                echo -e "${GREEN}Existing configuration is valid ✨${NC}\n"
            else
                echo -e "${RED}Existing configuration is invalid. Let's reconfigure it ⚠️${NC}\n"
                rm .env
            fi
        fi

        if [ ! -f .env ] || ! grep -q "L1_RPC_URL" .env; then
            echo -e "${WHITE}We need to configure your Sepolia L1 URL.${NC}"
            echo -e "${GRAY}Please provide a URL that supports both:${NC}"
            echo -e "${GRAY}  • JSON-RPC (for regular Ethereum calls)${NC}"
            echo -e "${GRAY}  • Beacon API (for consensus layer interaction)${NC}\n"
            while true; do
                echo -e "${WHITE}Enter your Sepolia L1 URL:${NC}"
                echo -n "Url: "
                read rpc_url
                echo ""
                rpc_url=${rpc_url%/}
                if ! validate_sepolia_url "$rpc_url"; then
                    echo -e "${RED}Please provide a valid Sepolia L1 URL and try again ❌${NC}\n"
                    continue
                fi
                if ! validate_beacon_api "$rpc_url"; then
                    echo -e "${RED}Please provide a URL with Beacon API support and try again ❌${NC}\n"
                    continue
                fi
                echo "L1_RPC_URL=$rpc_url" > .env
                echo "L1_BEACON_URL=$rpc_url" >> .env
                echo -e "${GREEN}Success! Your Sepolia L1 URL has been configured ✨${NC}"
                echo -e "${GRAY}Configuration saved to${NC} ${WHITE}.env${NC} ${GRAY}file 📝${NC}\n"
                break
            done
        fi

        # Update entrypoint.sh with available ports
        sed -i "s/8551/${TCP_PORTS[0]}/g" "$HOME/InkNode/node/op-node/entrypoint.sh"
        sed -i "s/30303/${TCP_PORTS[2]}/g" "$HOME/InkNode/node/op-node/entrypoint.sh"
        sed -i "s/30303/${UDP_PORTS[0]}/g" "$HOME/InkNode/node/op-node/entrypoint.sh"

        # Create var directory structure with proper permissions
        echo -e "${GRAY}Creating var/secrets directory structure...${NC}"
        mkdir -p var/secrets
        if [ $? -eq 0 ]; then
            chmod 777 var
            chmod 777 var/secrets
            echo -e "${GREEN}↳ Directory structure created with proper permissions ✅${NC}\n"
        else
            echo -e "${RED}↳ Error creating directory structure ❌${NC}\n"
            exit 1
        fi

        # Generate JWT secret
        echo -e "${GRAY}Generating secret for the engine API secure communication...${NC}"
        openssl rand -hex 32 > var/secrets/jwt.txt
        if [ $? -eq 0 ]; then
            chmod 666 var/secrets/jwt.txt
            echo -e "${GREEN}↳ Secret generated and saved with proper permissions 🔑${NC}\n"
        else
            echo -e "${RED}↳ Error generating secret ❌${NC}\n"
            exit 1
        fi

        echo -e "${GREEN}Ink Node installed and configured.${NC}"
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

# Main menu function
main_menu() {
    while true; do
        echo -e "${GREEN}Script and tutorial written by Telegram user @rmndkyl, free and open source, do not believe in paid versions${NC}"
        echo -e "${CYAN}----------------------------------${NC}"
        echo -e "${CYAN}       Ink Node Setup Menu        ${NC}"
        echo -e "${CYAN}----------------------------------${NC}"
        echo -e "${GREEN}Node community Telegram channel: https://t.me/layerairdrop${NC}"
        echo -e "${GREEN}Node community Telegram group: https://t.me/+UgQeEnnWrodiNTI1${NC}"
        echo -e "${GREEN}Please select an option:${NC}"
        echo -e "1. Check Port Availability"
        echo -e "2. Install Dependencies (Prerequisites and Docker)"
        echo -e "3. Install and Configure Ink Node"
        echo -e "4. Run and Manage Ink Node"
        echo -e "5. Node Maintenance (Restart, Shutdown, Delete)"
        echo -e "6. Check Logs for node-op-geth"
        echo -e "7. Check Logs for node-op-node"
        echo -e "8. Backup Your Generated Wallet"
        echo -e "9. Exit"
        echo -e "${CYAN}----------------------------------${NC}"
        read -p "Choose an option: " choice

        case $choice in
            1) check_ports ;;
            2) install_dependencies ;;
            3) setup_ink_node ;;
            4) manage_ink_node ;;
            5) node_maintenance ;;
            6) 
                echo -e "${CYAN}Checking logs for node-op-geth...${NC}"
                docker logs -f node-op-geth-1
                ;;
            7) 
                echo -e "${CYAN}Checking logs for node-op-node...${NC}"
                docker logs -f node-op-node-1
                ;;
            8) 
                echo -e "${CYAN}Displaying generated wallet backup...${NC}"
                cat ~/InkNode/node/var/secrets/jwt.txt
                ;;
            9) exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
    done
}

main_menu
