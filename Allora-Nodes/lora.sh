#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Function to print colored header
print_header() {
    echo -e "${PURPLE}=============================================${NC}"
    echo -e "${CYAN}          Allora Node Installation Script${NC}"
    echo -e "${PURPLE}=============================================${NC}"
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed${NC}"
        return 1
    fi
    return 0
}

# Function to check prerequisites
check_prerequisites() {
    local prerequisites=("docker" "go" "python3")
    local missing=0
    
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    for cmd in "${prerequisites[@]}"; do
        if ! check_command $cmd; then
            missing=1
        else
            echo -e "${GREEN}✓ $cmd is installed${NC}"
        fi
    done
    
    if [ $missing -eq 1 ]; then
        echo -e "${RED}Please install missing prerequisites before continuing.${NC}"
        return 1
    fi
    return 0
}

# Function to install system dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing system dependencies...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev \
        libnss3-dev curl git wget make jq build-essential pkg-config lsb-release \
        libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 python3 python3-pip
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Dependencies installed successfully${NC}"
    else
        echo -e "${RED}Error installing dependencies${NC}"
        return 1
    fi
}

# Function to install Allora CLI
install_allora_cli() {
    echo -e "${YELLOW}Installing Allora CLI...${NC}"
    git clone https://github.com/allora-network/allora-chain.git
    cd allora-chain && make all
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Allora CLI installed successfully${NC}"
        allorad version
    else
        echo -e "${RED}Error installing Allora CLI${NC}"
        return 1
    fi
}

# Function to install and configure worker
install_worker() {
    echo -e "${YELLOW}Installing Worker...${NC}"
    cd $HOME
    git clone https://github.com/allora-network/basic-coin-prediction-node
    cd basic-coin-prediction-node
    
    echo -e "${CYAN}Please enter your wallet mnemonic phrase:${NC}"
    read -s wallet_phrase
    
    # Create config.json with user's wallet phrase
    cat > config.json << EOF
{
    "wallet": {
        "addressKeyName": "testkey",
        "addressRestoreMnemonic": "${wallet_phrase}",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-testnet-rpc.polkachu.com/",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8000/inference/{Token}",
                "Token": "ETH"
            }
        }
    ]
}
EOF
    
    chmod +x init.config
    ./init.config
}

# Function to start worker
start_worker() {
    echo -e "${YELLOW}Starting Worker...${NC}"
    docker compose up -d --build
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Worker started successfully${NC}"
    else
        echo -e "${RED}Error starting worker${NC}"
        return 1
    fi
}

# Function to display logs
show_logs() {
    while true; do
        echo -e "${CYAN}Select log type:${NC}"
        echo -e "1) Worker logs"
        echo -e "2) Inference logs"
        echo -e "3) Return to main menu"
        read -p "Enter your choice: " log_choice
        
        case $log_choice in
            1) docker logs -f --tail=20 worker ;;
            2) docker compose logs -f inference ;;
            3) return ;;
            *) echo -e "${RED}Invalid choice${NC}" ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        clear
        print_header
        echo -e "${CYAN}Please select an option:${NC}"
        echo -e "1) Check Prerequisites"
        echo -e "2) Install System Dependencies"
        echo -e "3) Install Allora CLI"
        echo -e "4) Install Worker"
        echo -e "5) Start Worker"
        echo -e "6) Show Logs"
        echo -e "7) Exit"
        
        read -p "Enter your choice: " choice
        
        case $choice in
            1) check_prerequisites ;;
            2) install_dependencies ;;
            3) install_allora_cli ;;
            4) install_worker ;;
            5) start_worker ;;
            6) show_logs ;;
            7) 
                echo -e "${GREEN}Thank you for using Allora Node Installation Script${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 2
                ;;
        esac
        
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Start the script
main_menu
