#!/bin/bash

# Function to display colorful banner
display_banner() {
    echo -e "\n\033[38;5;39m██╗   ██╗ ██████╗ ██╗      █████╗ ██████╗  █████╗ \033[0m"
    echo -e "\033[38;5;39m██║   ██║██╔═══██╗██║     ██╔══██╗██╔══██╗██╔══██╗\033[0m"
    echo -e "\033[38;5;39m██║   ██║██║   ██║██║     ███████║██████╔╝███████║\033[0m"
    echo -e "\033[38;5;39m╚██╗ ██╔╝██║   ██║██║     ██╔══██║██╔══██╗██╔══██║\033[0m"
    echo -e "\033[38;5;39m ╚████╔╝ ╚██████╔╝███████╗██║  ██║██║  ██║██║  ██║\033[0m"
    echo -e "\033[38;5;39m  ╚═══╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝\033[0m"
    echo -e "\033[38;5;39m                     MINER INSTALLER\033[0m\n"
}

echo "Showing Animation.."
wget -O loader.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
rm -rf loader.sh
wget -O logo.sh https://raw.githubusercontent.com/rmndkyl/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh
sleep 4

# Enhanced color palette
declare -A colors=(
    ["primary"]='\033[38;5;39m'    # Bright blue
    ["success"]='\033[38;5;82m'    # Bright green
    ["warning"]='\033[38;5;214m'   # Bright orange
    ["error"]='\033[38;5;196m'     # Bright red
    ["info"]='\033[38;5;147m'      # Light purple
    ["highlight"]='\033[38;5;226m' # Bright yellow
    ["reset"]='\033[0m'
)

# Enhanced icons
declare -A icons=(
    ["info"]="🔹"
    ["success"]="✨"
    ["warning"]="⚡"
    ["error"]="❌"
    ["progress"]="📦"
    ["system"]="🖥️"
    ["docker"]="🐳"
    ["wallet"]="💰"
)

# Define log file path
LOG_FILE="/var/log/volara_miner.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="$HOME/volara_miner.log"

# Progress bar function
show_progress() {
    local duration=$1
    local width=50
    local progress=0
    local fill_char="▰"
    local empty_char="▱"
    
    while [ $progress -le 100 ]; do
        local fill=$(($progress * $width / 100))
        local empty=$(($width - $fill))
        
        printf "\r${colors[primary]}Progress: ["
        printf "%${fill}s" | tr " " "${fill_char}"
        printf "%${empty}s" | tr " " "${empty_char}"
        printf "] %3d%%${colors[reset]}" $progress
        
        progress=$(($progress + 2))
        sleep $(echo "scale=3; $duration/50" | bc)
    done
    echo
}

# Enhanced logging function
log() {
    local type=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${colors[$type]}${icons[$type]} [$timestamp] $message${colors[reset]}" | tee -a "$LOG_FILE"
}

# Function to check system requirements
check_system_requirements() {
    log "info" "Checking system requirements..."
    
    local min_ram=4000000  # 4GB in KB
    local min_disk=10000000  # 10GB in KB
    
    local available_ram=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local available_disk=$(df / | awk 'NR==2 {print $4}')
    
    if [ $available_ram -lt $min_ram ]; then
        log "warning" "System RAM ($(($available_ram/1024))MB) is below recommended ($(($min_ram/1024))MB)"
    else
        log "success" "RAM check passed: $(($available_ram/1024))MB available"
    fi
    
    if [ $available_disk -lt $min_disk ]; then
        log "warning" "Available disk space ($(($available_disk/1024))MB) is below recommended ($(($min_disk/1024))MB)"
    else
        log "success" "Disk space check passed: $(($available_disk/1024))MB available"
    fi
}

# Function to check dependencies
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        log "error" "$1 is not installed. Please install it before proceeding."
        return 1
    fi
    log "success" "$1 is installed"
    return 0
}

# Function: Update and upgrade system
update_system() {
    log "system" "Updating and upgrading the system..."
    if sudo apt update -y && sudo apt upgrade -y; then
        log "success" "System update completed successfully"
        show_progress 2
    else
        log "error" "System update failed"
        return 1
    fi
}

# Enhanced Docker installation
install_docker() {
    log "docker" "Starting Docker installation..."
    
    if docker --version &> /dev/null; then
        local docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
        log "success" "Docker is already installed. Version: $docker_version"
        return 0
    fi
    
    log "info" "Removing conflicting packages..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg
    done
    
    # Create temporary directory for Docker installation
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || exit
    
    log "info" "Setting up Docker repository..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    log "progress" "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Clean up
    cd - > /dev/null
    rm -rf "$tmp_dir"
    
    # Verify installation
    if docker --version &> /dev/null; then
        log "success" "Docker installed successfully: $(docker --version)"
        sudo usermod -aG docker $USER
        log "info" "Added current user to docker group"
        show_progress 3
    else
        log "error" "Docker installation failed"
        return 1
    fi
}

# Enhanced miner start function
start_miner() {
    log "info" "Please ensure your Vana network wallet has enough test tokens"
    log "info" "Visit: https://faucet.vana.org/moksha to receive test tokens"
    
    echo -e "${colors[highlight]}Enter your Metamask private key (it will not be shown):${colors[reset]}"
    read -sp "Private Key: " VANA_PRIVATE_KEY
    echo
    
    if [[ -z "$VANA_PRIVATE_KEY" ]]; then
        log "error" "Metamask private key cannot be empty"
        return 1
    fi
    
    export VANA_PRIVATE_KEY
    
    log "progress" "Pulling Volara-Miner Docker image..."
    if timeout 300 docker pull volara/miner; then
        log "success" "Volara-Miner Docker image pulled successfully"
        screen -S volara -m bash -c "docker run -it -e VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY} volara/miner"
        log "info" "Screen session created. Connect using: screen -r volara"
        show_progress 2
    else
        log "error" "Failed to pull Volara-Miner Docker image"
        return 1
    fi
}

# Enhanced log viewing function
view_miner_logs() {
    clear
    log "info" "Displaying Volara-Miner logs..."
    docker ps --filter "ancestor=volara/miner" --format "{{.Names}}" | while read container_name; do
        echo -e "${colors[primary]}Logs from container: $container_name${colors[reset]}"
        docker logs --tail 20 "$container_name"
        echo -e "${colors[primary]}--------------------------------------${colors[reset]}"
    done
}

# Enhanced menu display
show_menu() {
    clear
    display_banner
    
    echo -e "${colors[primary]}═══════════════════════ MAIN MENU ═══════════════════════${colors[reset]}"
    echo -e "${colors[info]}1.${colors[reset]} System Update & Requirements Check"
    echo -e "${colors[info]}2.${colors[reset]} Install Docker"
    echo -e "${colors[info]}3.${colors[reset]} Start Volara Miner"
    echo -e "${colors[info]}4.${colors[reset]} View Miner Logs"
    echo -e "${colors[info]}5.${colors[reset]} Exit"
    echo -e "${colors[primary]}═══════════════════════════════════════════════════════════${colors[reset]}\n"
    echo -e "${colors[primary]}Script by Telegram user @rmndkyl - Free and Open Source${colors[reset]}"
    echo -e "${colors[primary]}Community: https://t.me/layerairdrop | https://t.me/+UgQeEnnWrodiNTI1${colors[reset]}\n"
}

# Main execution loop
main() {
    trap 'echo -e "\n${colors[warning]}Script interrupted by user${colors[reset]}"; exit 1' INT
    
    while true; do
        show_menu
        read -p "Select an option (1-5): " choice
        
        case $choice in
            1)
                update_system
                check_system_requirements
                ;;
            2)
                install_docker
                ;;
            3)
                start_miner
                ;;
            4)
                view_miner_logs
                ;;
            5)
                log "info" "Exiting script"
                exit 0
                ;;
            *)
                log "warning" "Invalid option selected"
                ;;
        esac
        
        echo -e "\n${colors[primary]}Press Enter to continue...${colors[reset]}"
        read
    done
}

# Start script
main
