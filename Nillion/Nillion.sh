#!/bin/bash

# Define colors for better readability
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"  # No Color

# Script save path
SCRIPT_PATH="$HOME/Nillion.sh"

echo -e "${BLUE}Showing Animation...${NC}"
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Ensure the script is run as root
if [ "$(id -u)" -ne "0" ]; then
  echo -e "${RED}Please run this script as root or with sudo${NC}"
  exit 1
fi

# Main menu function
function main_menu() {
    while true; do
        clear
        echo -e "${YELLOW}Script and tutorial by @rmndkyl on Telegram. Open-source; do not pay for this!${NC}"
        echo -e "${BLUE}====================== Nillion Verifier Setup ======================${NC}"
        echo -e "${GREEN}Node community channel: https://t.me/layerairdrop${NC}"
        echo -e "${GREEN}Node community group: https://t.me/+UgQeEnnWrodiNTI1${NC}"
        echo -e "${YELLOW}To exit the script, press Ctrl+C.${NC}"
        echo -e "${GREEN}Select an option:${NC}"
        echo -e "1) Install Node"
        echo -e "2) Query Logs (use docker ps to check ID first)"
        echo -e "3) Delete Node"
        echo -e "4) Change RPC and Restart Node"
        echo -e "5) View public_key and account_id"
        echo -e "6) Migrate Validator (for users before 9.24)"
        echo -e "7) Exit"

        read -p "Enter an option (1-7): " choice

        case $choice in
            1) install_node ;;
            2) query_logs ;;
            3) delete_node ;;
            4) change_rpc ;;
            5) view_credentials ;;
            6) migrate_validator ;;
            7) echo -e "${BLUE}Exiting script.${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option, please enter a number between 1 and 7.${NC}" ;;
        esac
    done
}

# Migrate Validator function
function migrate_validator() {
    echo -e "${YELLOW}Stopping and removing Docker container nillion_verifier...${NC}"
    docker stop nillion_verifier && docker rm nillion_verifier

    echo -e "${BLUE}Migrating Validator...${NC}"
    
    # Create a new screen session and run the Docker command inside it
    screen -S Nillion -dm bash -c "docker run -v ./nillion/accuser:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint 'https://nillion-testnet-rpc.polkachu.com'"

    echo -e "${GREEN}Validator is running in screen session 'Nillion'. Use Ctrl+A+D to detach, and 'screen -r Nillion' to view.${NC}"
}

# Install Node function
function install_node() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker is already installed.${NC}"
    else
        echo -e "${YELLOW}Docker not found, installing...${NC}"
        apt-get update
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        apt-get update
        apt-get install -y docker-ce
        systemctl start docker
        systemctl enable docker
        echo -e "${GREEN}Docker installation completed.${NC}"
    fi

    echo -e "${YELLOW}Pulling Docker image nillion/verifier:v1.0.1...${NC}"
    docker pull nillion/verifier:v1.0.1

    echo -e "${YELLOW}Installing jq...${NC}"
    apt-get install -y jq
    echo -e "${GREEN}jq installed.${NC}"

    echo -e "${BLUE}Initializing configuration...${NC}"
    mkdir -p nillion/verifier
    docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 initialise
    echo -e "${GREEN}Initialization completed.${NC}"

    echo -e "${YELLOW}Please save the account_id and public_key located in ~/nillion/verifier for future use.${NC}"
    read -p "Press any key to continue..."

    selected_rpc_url="https://nillion-testnet-rpc.polkachu.com"
    echo -e "${BLUE}Checking sync status from $selected_rpc_url...${NC}"
    sync_info=$(curl -s "$selected_rpc_url/status" | jq .result.sync_info)
    echo -e "${YELLOW}Sync status:${NC}"
    echo "$sync_info"

    read -p "Is the node synchronized? (yes/no): " sync_status
    if [ "$sync_status" = "yes" ]; then
        echo -e "${GREEN}Starting node...${NC}"
        docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "$selected_rpc_url"
        echo -e "${GREEN}Node is running.${NC}"
    else
        echo -e "${RED}Node is not synchronized. Exiting.${NC}"
        exit 1
    fi

    read -p "Press any key to return to the main menu..."
}

# Query Logs function
function query_logs() {
    echo -e "${YELLOW}Please enter the container ID for log query (use 'docker ps' to check ID):${NC}"
    read -p "Container ID: " container_id

    if [ "$(docker ps -q -f id=$container_id)" ]; then
        echo -e "${BLUE}Querying logs for container ID $container_id...${NC}"
        docker logs -f $container_id --tail 100
    else
        echo -e "${RED}No running container found with ID $container_id.${NC}"
    fi

    read -p "Press any key to return to the main menu..."
}

# Delete Node function
function delete_node() {
    echo -e "${YELLOW}Backing up /root/nillion/verifier directory...${NC}"
    tar -czf /root/nillion/verifier_backup_$(date +%F).tar.gz /root/nillion/verifier && echo -e "${GREEN}Backup completed.${NC}"

    echo -e "${YELLOW}Stopping and removing Docker container nillion_verifier...${NC}"
    docker stop nillion_verifier && docker rm nillion_verifier && echo -e "${GREEN}Node has been deleted successfully.${NC}"

    read -p "Press any key to return to the main menu..."
}

# Change RPC function
function change_rpc() {
    echo -e "${BLUE}Select the RPC link to use:${NC}"
    echo -e "1) ${YELLOW}https://testnet-nillion-rpc.lavenderfive.com${NC}"
    echo -e "2) ${YELLOW}https://nillion-testnet-rpc.polkachu.com${NC}"
    echo -e "3) ${YELLOW}https://nillion-testnet.rpc.kjnodes.com${NC}"

    read -p "Enter a number (1-3): " choice

    case $choice in
        1)
            new_rpc_url="https://testnet-nillion-rpc.lavenderfive.com"
            ;;
        2)
            new_rpc_url="https://nillion-testnet-rpc.polkachu.com"
            ;;
        3)
            new_rpc_url="https://nillion-testnet.rpc.kjnodes.com"
            ;;
        *)
            echo -e "${RED}Invalid choice, please try again.${NC}"
            return
            ;;
    esac

    echo -e "${YELLOW}Stopping and removing existing Docker container nillion_verifier...${NC}"
    docker stop nillion_verifier && docker rm nillion_verifier

    echo -e "${BLUE}Starting a new Docker container with the updated RPC URL...${NC}"
    docker run -v ./nillion/verifier:/var/tmp nillion/verifier:v1.0.1 verify --rpc-endpoint "$new_rpc_url" && echo -e "${GREEN}Node has been updated to use RPC: $new_rpc_url.${NC}"
    
    read -p "Press any key to return to the main menu..."
}

# View Credentials function
function view_credentials() {
    echo -e "${BLUE}Credentials are saved in the /root/nillion/verifier/credentials.json file.${NC}"
    
    if [ -f /root/nillion/verifier/credentials.json ]; then
        echo -e "${YELLOW}Credential Information:${NC}"
        cat /root/nillion/verifier/credentials.json
        echo -e "${YELLOW}--------------------------${NC}"
    else
        echo -e "${RED}Credentials file not found! Ensure that the node is properly initialized.${NC}"
    fi

    read -p "Press any key to return to the main menu..."
}

# Start Main Menu
main_menu
