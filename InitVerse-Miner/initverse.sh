#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
WALLET_ADDRESS=""
WORKER_NAME="Worker001"
CPU_CORES=$(nproc)
MINING_SOFTWARE_URL="https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64"
FULL_NODE_URL="https://github.com/Project-InitVerse/ini-chain/archive/refs/tags/v1.0.0.tar.gz"
POOL_ADDRESS="pool-core-testnet.inichain.com:32672"
RESTART_INTERVAL=3600  # 1 hour in seconds

# Show Logo
echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Function to print colored header
print_header() {
    echo -e "${PURPLE}=================================================${NC}"
    echo -e "${CYAN}             InitVerse Mining Setup${NC}"
    echo -e "${PURPLE}=================================================${NC}"
}

# Function to validate wallet address
validate_wallet() {
    if [[ ! $1 =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        echo -e "${RED}Invalid wallet address format${NC}"
        return 1
    fi
    return 0
}

# Function to run mining command with auto-restart
run_with_restart() {
    local cmd="$1"
    while true; do
        echo -e "${GREEN}Starting mining process...${NC}"
        echo -e "${BLUE}$cmd${NC}"
        eval "$cmd"
        
        # Calculate next restart time
        next_restart=$(date -d "+1 hour" +"%H:%M:%S")
        echo -e "${YELLOW}Mining process will restart at $next_restart${NC}"
        
        # Sleep for the specified interval
        sleep $RESTART_INTERVAL
        
        echo -e "${YELLOW}Restarting mining process...${NC}"
        # Kill any remaining mining processes
        pkill -f iniminer-linux-x64
    done
}

# Function to set up mining pool
setup_pool_mining() {
    echo -e "${YELLOW}Setting up Pool Mining...${NC}"
    
    # Get wallet address if not already set
    while [ -z "$WALLET_ADDRESS" ] || ! validate_wallet "$WALLET_ADDRESS"; do
        echo -e "${CYAN}Enter your wallet address (0x...):${NC}"
        read WALLET_ADDRESS
    done
    
    # Get worker name
    echo -e "${CYAN}Enter worker name (default: Worker001):${NC}"
    read input_worker
    WORKER_NAME=${input_worker:-$WORKER_NAME}
    
    # Create directory and download mining software
    mkdir -p ini-miner && cd ini-miner
    
    # Download and extract mining software
    echo -e "${YELLOW}Downloading mining software...${NC}"
    wget "$MINING_SOFTWARE_URL" -O iniminer-linux-x64
    chmod +x iniminer-linux-x64
    
    # Check if executable exists
    if [ ! -f "./iniminer-linux-x64" ]; then
        echo -e "${RED}Error: Mining software not found${NC}"
        return 1
    fi
    
    # Set up mining command
    MINING_CMD="./iniminer-linux-x64 --pool stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@${POOL_ADDRESS}"
    
    # Get number of CPU cores to use
    echo -e "${CYAN}Enter number of CPU cores to use (1-${CPU_CORES}, default: 1):${NC}"
    read cores
    cores=${cores:-1}
    
    for ((i=0; i<cores; i++)); do
        MINING_CMD+=" --cpu-devices $i"
    done
    
    # Start mining with auto-restart
    run_with_restart "$MINING_CMD"
}

# Function to set up solo mining
setup_solo_mining() {
    echo -e "${YELLOW}Setting up Solo Mining...${NC}"
    
    # Get wallet address if not already set
    while [ -z "$WALLET_ADDRESS" ] || ! validate_wallet "$WALLET_ADDRESS"; do
        echo -e "${CYAN}Enter your wallet address (0x...):${NC}"
        read WALLET_ADDRESS
    done
    
    # Download and set up full node
    echo -e "${YELLOW}Downloading full node...${NC}"
    wget "$FULL_NODE_URL" -O ini-chain.tar.gz
    tar -xzf ini-chain.tar.gz
    
    # Download Geth
    wget https://github.com/Project-InitVerse/ini-chain/releases/download/v1.0.0/geth-linux-x64
    chmod +x geth-linux-x64
    
    # Start node
    echo -e "${GREEN}Starting full node...${NC}"
    ./geth-linux-x64 --datadir data --http.api="eth,admin,miner,net,web3,personal" --allow-insecure-unlock --testnet console &
    
    # Wait for node to start
    sleep 10
    
    # Set up mining command
    MINING_CMD="geth attach http://localhost:8545 --exec 'miner.setEtherbase(\"$WALLET_ADDRESS\"); miner.start()'"
    
    # Start mining with auto-restart
    run_with_restart "$MINING_CMD"
}

# Rest of the script remains the same...
check_requirements() {
    # Previous implementation
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check CPU
    echo -e "${CYAN}CPU Information:${NC}"
    lscpu | grep "Model name"
    echo -e "Available cores: ${GREEN}$CPU_CORES${NC}"
    
    # Check RAM
    total_ram=$(free -h | awk '/^Mem:/{print $2}')
    echo -e "Total RAM: ${GREEN}$total_ram${NC}"
    
    # Check disk space
    disk_space=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "Available disk space: ${GREEN}$disk_space${NC}"
    
    # Check for required software
    echo -e "\n${CYAN}Checking required software:${NC}"
    for cmd in wget tar gzip; do
        if command -v $cmd >/dev/null 2>&1; then
            echo -e "$cmd: ${GREEN}Installed${NC}"
        else
            echo -e "$cmd: ${RED}Not installed${NC}"
        fi
    done
}

# Main menu function
main_menu() {
    while true; do
        clear
        print_header
        echo -e "${CYAN}1. Setup Pool Mining${NC}"
        echo -e "${CYAN}2. Setup Solo Mining${NC}"
        echo -e "${CYAN}3. Check System Requirements${NC}"
        echo -e "${CYAN}4. Exit${NC}"
        echo -e "${PURPLE}=================================================${NC}"
        echo -e "${YELLOW}Please select an option (1-4):${NC}"
        read choice
        
        case $choice in
            1) setup_pool_mining ;;
            2) setup_solo_mining ;;
            3) check_requirements ;;
            4) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 2 ;;
        esac
        
        if [ "$choice" != "4" ]; then
            echo -e "\n${YELLOW}Press Enter to return to main menu...${NC}"
            read
        fi
    done
}

# Start the script
main_menu
