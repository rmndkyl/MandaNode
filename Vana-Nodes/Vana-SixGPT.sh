#!/bin/bash

# Enhanced color codes with more variety
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
ORANGE='\033[38;5;208m'
NC='\033[0m' # No color

# Script save path
SCRIPT_PATH="$HOME/Vana-SixGPT.sh"

# Function for creating fancy headers
print_header() {
    local text="$1"
    local width=80
    local padding=$(( (width - ${#text}) / 2 ))
    echo
    echo -e "${CYAN}═══${NC}${PURPLE}$(printf '═%.0s' $(seq $padding))${NC}${WHITE} $text ${NC}${PURPLE}$(printf '═%.0s' $(seq $padding))${NC}${CYAN}═══${NC}"
    echo
}

# Function for status messages
print_status() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${2}${1}${NC}"
}

# Enhanced error handling function
handle_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Progress bar function
show_progress() {
    local duration=$1
    local progress=0
    while [ $progress -le 100 ]; do
        echo -ne "${CYAN}Progress: ${GREEN}["
        for ((i=0; i<=progress; i+=2)); do
            echo -ne "="
        done
        for ((i=progress; i<100; i+=2)); do
            echo -ne " "
        done
        echo -ne "] ${progress}%\r${NC}"
        progress=$((progress + 2))
        sleep $duration
    done
    echo
}

# Function to check system requirements
check_system_requirements() {
    print_status "Checking system requirements..." "${BLUE}"
    
    # Check CPU cores
    local cpu_cores=$(nproc)
    if [ "$cpu_cores" -lt 2 ]; then
        handle_error "Minimum 2 CPU cores required. Found: $cpu_cores"
    fi
    
    # Check RAM
    local total_ram=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$total_ram" -lt 4000 ]; then
        handle_error "Minimum 4GB RAM required. Found: $total_ram MB"
    fi
    
    # Check disk space
    local free_space=$(df -m / | awk 'NR==2 {print $4}')
    if [ "$free_space" -lt 20000 ]; then
        handle_error "Minimum 20GB free space required. Found: $free_space MB"
    fi
    
    print_status "System requirements met! ✓" "${GREEN}"
}

# Enhanced logo display function
show_logo() {
    print_header "Vana SixGPT Installer"
    echo -e "${GREEN}Initializing...${NC}"
    for i in {1..3}; do
        echo -ne "${ORANGE}■${NC}"
        sleep 0.2
    done
    echo -e "\n"
    
    # Download and display custom logo animations
    wget -q -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
    rm -rf loader.sh
    wget -q -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
    rm -rf logo.sh
    sleep 2
}

# Check root user
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  Error: Root privileges are required!      ║${NC}"
        echo -e "${RED}║  Please run: sudo -i                       ║${NC}"
        echo -e "${RED}║  Then run the script again                 ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Enhanced main menu function
function main_menu() {
    while true; do
        clear
        print_header "Vana SixGPT Installation"
        echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC} ${YELLOW}Community Links:${NC}                           ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} Telegram channel: ${WHITE}t.me/layerairdrop${NC}        ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC} Telegram group: ${WHITE}t.me/+UgQeEnnWrodiNTI1${NC}     ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${PURPLE}▣ Available Options:${NC}"
        echo -e "${WHITE}1)${NC} ${GREEN}Start Node${NC}    ${CYAN}│${NC} ${WHITE}2)${NC} ${GREEN}View Logs${NC}"
        echo -e "${WHITE}3)${NC} ${GREEN}Restart Node${NC}  ${CYAN}│${NC} ${WHITE}4)${NC} ${GREEN}Delete Node${NC}"
        echo -e "${WHITE}5)${NC} ${GREEN}Exit${NC}"
        echo
        echo -e "${YELLOW}Press Ctrl+C to exit at any time${NC}"
        echo
        read -p "$(echo -e ${CYAN}Please select an option [1-5]:${NC} )" choice
        
        case $choice in
            1) start_node ;;
            2) view_logs ;;
            3) restart_node ;;
            4) delete_node ;;
            5) 
                print_status "Exiting script. Goodbye!" "${GREEN}"
                exit 0 
                ;;
            *) 
                print_status "Invalid option. Please try again." "${RED}"
                sleep 2 
                ;;
        esac
    done
}

# Enhanced start_node function
function start_node() {
    check_system_requirements
    print_header "Starting Node Installation"
    
    # Update system packages
    print_status "Updating system packages..." "${BLUE}"
    {
        sudo apt update -y && sudo apt upgrade -y
    } | while read -r line; do
        echo -ne "${CYAN}▶${NC} $line\r"
    done
    echo

    # Install dependencies with progress indication
    print_status "Installing required dependencies..." "${YELLOW}"
    local dependencies=(
        "ca-certificates" "zlib1g-dev" "libncurses5-dev" "libgdbm-dev"
        "libnss3-dev" "tmux" "iptables" "curl" "nvme-cli" "git" "wget" "make"
        "jq" "libleveldb-dev" "build-essential" "pkg-config" "ncdu" "tar"
        "clang" "bsdmainutils" "lsb-release" "libssl-dev" "libreadline-dev"
        "libffi-dev" "jq" "gcc" "screen" "unzip" "lz4"
    )
    
    total=${#dependencies[@]}
    current=0
    
    for dep in "${dependencies[@]}"; do
        current=$((current + 1))
        progress=$((current * 100 / total))
        echo -ne "${CYAN}Installing dependencies: [${GREEN}${progress}%${CYAN}]${NC}\r"
        sudo apt install -y "$dep" >/dev/null 2>&1
    done
    echo

    # Docker installation
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..." "${YELLOW}"
        {
            sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt update -y
            sudo apt install -y docker-ce
            sudo systemctl start docker
            sudo systemctl enable docker
        } | while read -r line; do
            echo -ne "${CYAN}▶${NC} $line\r"
        done
        print_status "Docker installation complete! ✓" "${GREEN}"
    else
        print_status "Docker already installed ✓" "${GREEN}"
    fi

    # Docker Compose installation
    if ! command -v docker-compose &> /dev/null; then
        print_status "Installing Docker Compose..." "${YELLOW}"
        VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
        sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        print_status "Docker Compose installation complete! ✓" "${GREEN}"
    else
        print_status "Docker Compose already installed ✓" "${GREEN}"
    fi

    # Setup Docker group
    if ! getent group docker > /dev/null; then
        print_status "Creating Docker group..." "${YELLOW}"
        sudo groupadd docker
    fi
    print_status "Adding user to Docker group..." "${YELLOW}"
    sudo usermod -aG docker $USER

    # Create directory and set environment
    mkdir -p ~/sixgpt
    cd ~/sixgpt

    # Get user input
    echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Node Configuration${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    
    read -p "$(echo -e ${YELLOW}Enter your private key:${NC} )" PRIVATE_KEY
    export VANA_PRIVATE_KEY=$PRIVATE_KEY

    echo -e "\n${BLUE}Select network:${NC}"
    echo -e "${YELLOW}1) satori (UNAVAILABLE!)${NC}"
    echo -e "${GREEN}2) moksha (RECOMMENDED!)${NC}"
    read -p "$(echo -e ${CYAN}Enter choice [1-2]:${NC} )" NETWORK_CHOICE

    case $NETWORK_CHOICE in
        1)
            export VANA_NETWORK="satori"
            ;;
        2)
            export VANA_NETWORK="moksha"
            ;;
        *)
            print_status "Invalid choice, defaulting to moksha" "${YELLOW}"
            export VANA_NETWORK="moksha"
            ;;
    esac

    print_status "Selected network: $VANA_NETWORK" "${GREEN}"

    # Create docker-compose.yml
    print_status "Creating Docker Compose configuration..." "${YELLOW}"
    cat <<EOL > docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11439:11434"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
 
  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3000:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY}
      - VANA_NETWORK=${VANA_NETWORK}
      - OLLAMA_API_URL=http://ollama:11434/api
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  ollama:
EOL

    # Start services
    print_status "Starting Docker Compose services..." "${YELLOW}"
    docker-compose up -d
    
    print_status "Installation completed successfully! ✓" "${GREEN}"
    echo -e "${YELLOW}Note: Please log out and back in to apply group changes.${NC}"
    read -p "$(echo -e ${CYAN}Press any key to continue...${NC})"
}

# Enhanced view_logs function
function view_logs() {
    print_header "Node Logs"
    if [ -d "$HOME/sixgpt" ]; then
        cd $HOME/sixgpt
        print_status "Displaying logs... (Press Ctrl+C to exit)" "${YELLOW}"
        docker-compose logs -f
    else
        print_status "Node directory not found! Please start the node first." "${RED}"
        sleep 3
    fi
}

# Enhanced restart_node function
function restart_node() {
    print_header "Restarting Node"
    if [ -d "$HOME/sixgpt" ]; then
        cd $HOME/sixgpt
        print_status "Restarting services..." "${YELLOW}"
        docker-compose restart
        print_status "Services restarted successfully! ✓" "${GREEN}"
    else
        print_status "Node directory not found! Please start the node first." "${RED}"
    fi
    sleep 3
}

# Enhanced delete_node function
function delete_node() {
    print_header "Deleting Node"
    if [ -d "$HOME/sixgpt" ]; then
        cd $HOME/sixgpt
        echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  Warning: This will delete all node data!  ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
        read -p "$(echo -e ${YELLOW}Are you sure you want to continue? [y/N]:${NC} )" confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            print_status "Stopping and removing services..." "${YELLOW}"
            docker-compose down -v
            cd ..
            rm -rf sixgpt
            print_status "Node deleted successfully! ✓" "${GREEN}"
        else
            print_status "Deletion cancelled." "${YELLOW}"
        fi
    else
        print_status "Node directory not found! Nothing to delete." "${RED}"
    fi
    sleep 3
}

# Script entry point
trap 'echo -e "${RED}Script interrupted.${NC}"; exit 1' INT
check_root
show_logo
main_menu
